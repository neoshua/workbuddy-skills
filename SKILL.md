---
name: github-sandbox-push
description: 在 WorkBuddy 沙箱环境中与 GitHub 交互（git push、Release 发布、Actions 验证、版本号管理）的标准流程与避坑手册。当用户要求把代码推送到 GitHub、把 APK/构建产物发布到 Release 供直接下载、用 GitHub Actions 自动构建发布、或通过 API 核对运行/产物状态时使用。它固化了本环境特有的陷阱：github.com 与 uploads.github.com 的 DNS 劫持、GnuTLS 长连接被掐断、.gitignore 吞掉二进制、GitHub Actions runner 默认 locale 截断中文文件名、以及易失败的第三方 Action，并给出经实战验证的规避方案，避免重复踩坑。
---

# GitHub 沙箱推送与发布

## Overview

本技能用于**在 WorkBuddy 沙箱里安全地操作 GitHub**。沙箱网络对 GitHub 域名做了 DNS 劫持，且会在长连接上掐断 TLS，直接 `git push` 或在沙箱里 `curl` 上传发布附件会反复失败。本技能提供一套已验证可跑通的流程，照做即可，不必再试错。

适用场景：
- 把本地仓库推送到 GitHub（私有/公开）
- 把构建产物（APK 等）发布到 Release 供用户直接下载
- 用 GitHub Actions 自动构建并发布
- 通过 API 验证运行 / 产物 / Release 状态
- 管理"1.x"这类递增版本号

## 环境陷阱速查表

| 现象 | 根因 | 正确做法 |
|------|------|----------|
| `github.com` 解析到 `198.18.0.29`、curl 返回 000 | 沙箱 DNS 被劫持 | 写 `/etc/hosts` 指向真实 IP（见步骤 1） |
| `GnuTLS recv error (-110)` / `SSL_ERROR_SYSCALL` | 长连接 TLS 被掐 | `git config http.version HTTP/1.1` + 重试（见步骤 2） |
| 推送报 401 / 无权限 | 用了 `x-access-token:` 形式（仅限 GitHub App / 精细令牌） | 经典 PAT 用 `https://TOKEN@github.com/...` |
| Release 附件上传 301 / SSL 失败 | `uploads.github.com` 也被劫持，沙箱无真实 IP | **不要在沙箱上传附件**；改用步骤 4 的 CI 方案 |
| `git add dist/xxx.apk` 后仓库里没有该文件 | `.gitignore` 忽略了 `dist/`、`*.apk` | `git add -f` 强制加入 |
| Release 附件名变成 `-v1.0.apk`（中文丢了） | Actions runner 默认 locale 非 UTF-8，中文名当参数被截断 | 发布前 `cp` 成 ASCII 文件名 |
| 工作流某步直接失败、后续全 skipped | 第三方 Action（如 `android-actions/setup-android@v3`）被强迁 Node 24 易挂 | 用 runner 预装能力，别用该 action |

## 步骤 1：推送前修复 DNS（每次会话都要做）

沙箱休眠后 `/etc/hosts` 会被重置，先确认并补回真实 IP：

```bash
grep -q "140.82.112.4 github.com" /etc/hosts || printf "140.82.112.4 github.com\n140.82.112.5 api.github.com\n" >> /etc/hosts
getent hosts github.com   # 应返回 140.82.112.4，而非 198.18.0.29
```

> 不要尝试给 `uploads.github.com` 配 IP——沙箱里拿不到它的真实 IP（外部 DoH 也被掐），上传附件必然失败。发布附件请走步骤 4 的 CI 方案。

## 步骤 2：鉴权与推送（HTTP/1.1 + 重试）

```bash
cd /path/to/repo
git config user.email "you@example.com"
git config user.name "Your Name"
git config http.version HTTP/1.1          # 关键：规避 GnuTLS 长连接中断
git add -A
git commit -m "描述"
URL="https://<TOKEN>@github.com/<owner>/<repo>.git"
for i in 1 2 3 4 5 6; do
  if git push "$URL" main 2>&1 | tail -3; then
    if git ls-remote "$URL" main 2>/dev/null | grep -q "$(git rev-parse HEAD)"; then
      echo "✅ 推送成功"; break
    fi
  fi
  sleep 3
done
```

要点：
- 经典 PAT 直接作为 URL 的**用户名**：`https://ghp_xxx@github.com/...`。
- 若推送偶发失败，重试通常即过（TLS 中断是间歇的）。
- 只读校验用 API：`curl -H "Authorization: token <TOKEN>" https://api.github.com/...`（注意是 `token ` 而非 `Bearer `）。

## 步骤 3：把二进制提交进仓库（如需在文件页直接下载）

如果 `.gitignore` 忽略了 `*.apk` / `dist/`，普通 `git add` 会被静默忽略：

```bash
git add -f dist/your-app.apk      # -f 强制加入被忽略的文件
git commit -m "chore: 入库 APK 便于直接下载"
git push "$URL" main
```

之后用户在仓库文件页（登录后）点文件 → Download 即可。

## 步骤 4：发布 Release 附件（必须用 CI，不要在沙箱 curl）

沙箱无法访问 `uploads.github.com`，所以**附件由 GitHub Actions 在工作流里用 `gh` CLI 发布**（runner 有正常 DNS）。在 `.github/workflows/*.yml` 末尾加：

```yaml
permissions:
  contents: write
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      # ... 你的构建步骤，产出 dist/your-app.apk ...
      - name: 发布到 Release (latest)
        env:
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        run: |
          SRC="$(ls dist/*.apk | head -n1)"
          APK="dist/your-app.apk"          # 务必 ASCII 名，避免中文被截断
          cp "$SRC" "$APK"
          gh release delete latest --yes || true
          git push origin :refs/tags/latest || true
          gh release create latest "$APK" \
            --title "最新构建" \
            --notes "由 CI 在提交 ${{ github.sha }} 自动构建。" \
            --prerelease
```

发布后用户从 `https://github.com/<owner>/<repo>/releases/tag/latest` 登录下载（私有仓库必须登录）。

### 版本号方案（1.x）

主版本固定，次版本随构建递增；升大版本由人工触发：

```yaml
        run: |
          MAJOR=1
          MINOR_BASE=8                    # 升 2 时改为当时构建号，使次版本从 1 重算
          RUN="${{ github.run_number }}"
          VER="${MAJOR}.$(( RUN - MINOR_BASE ))"
          APK="dist/your-app-v${VER}.apk"
          cp "$(ls dist/*.apk | head -n1)" "$APK"
          gh release delete latest --yes || true
          git push origin :refs/tags/latest || true
          gh release create latest "$APK" --title "最新构建 v${VER}" --prerelease
```

## 步骤 5：用 API 验证结果

```bash
TOKEN=<TOKEN>
# 最近一次运行
curl -sS -H "Authorization: token $TOKEN" "https://api.github.com/repos/<owner>/<repo>/actions/runs?per_page=1" \
  | python3 -c "import sys,json;r=json.load(sys.stdin)['workflow_runs'][0];print(r['id'],r['head_sha'][:7],r['status'],r['conclusion'])"
# 某次运行的产物
curl -sS -H "Authorization: token $TOKEN" "https://api.github.com/repos/<owner>/<repo>/actions/runs/<RUN_ID>/artifacts" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);[print(a['name'],round(a['size_in_bytes']/1024,1),'KB') for a in d.get('artifacts',[])]"
# latest Release 附件
curl -sS -H "Authorization: token $TOKEN" "https://api.github.com/repos/<owner>/<repo>/releases/tags/latest" \
  | python3 -c "import sys,json;d=json.load(sys.stdin);[print(a['name']) for a in d.get('assets',[])]"
```

轮询某次运行直到完成：

```bash
TOKEN=<TOKEN>; SHA=<目标提交前7位>
for i in $(seq 1 40); do
  OUT=$(curl -sS -H "Authorization: token $TOKEN" "https://api.github.com/repos/<owner>/<repo>/actions/runs?per_page=1" \
    | python3 -c "import sys,json;r=json.load(sys.stdin)['workflow_runs'][0];print(r['id'],r['head_sha'][:7],r['status'],r['conclusion'] or '-')" 2>/dev/null)
  echo "[$i] $OUT"
  if [ "$(echo "$OUT"|awk '{print $2}')" = "$SHA" ] && [ "$(echo "$OUT"|awk '{print $3}')" = "completed" ]; then break; fi
  sleep 15
done
```

## 常见错误速修

- **`fatal: unable to access ... GnuTLS recv error`** → 加 `git config http.version HTTP/1.1` 并重试。
- **push 401** → 确认用的是经典 PAT 且作为 URL 用户名；不是 `x-access-token:`。
- **Release 里没有附件** → 你在沙箱 curl 上传了：删掉空 Release，改由 CI 发布（步骤 4）。
- **附件名中文丢失** → 发布前 `cp` 成 ASCII 名。
- **工作流整段 skipped** → 某个第三方 Action（如 `android-actions/setup-android`）在 setup 阶段失败，改用 runner 预装能力。
- **仓库里找不到提交的 APK** → `.gitignore` 忽略了，用 `git add -f`。

## 参考

- `references/android-build-release.yml`：本项目（Android APK）已验证通过的完整工作流，含预装 SDK 探测 + 构建签名 + 发布 `latest` Release + 1.x 版本号，可直接复用。
