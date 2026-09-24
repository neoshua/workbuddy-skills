# workbuddy-skills

本仓库存放 WorkBuddy 自定义技能（SKILL），目前收录：

## github-sandbox-push

在沙箱 / 受限网络环境下与 GitHub 交互的避坑流程技能。覆盖：

- 推送代码到 GitHub（绕过 DNS 劫持、GnuTLS 长连接中断、经典 PAT 用法）
- 通过 GitHub Actions 自动构建并把 APK 发布到固定 latest Release（附件在服务端生成，规避沙箱 uploads 上传被掐）
- 规避 .gitignore 吞掉 *.apk、Actions 中文文件名被截断、第三方 setup-android action 强迁 Node24 整段 skipped
- 固定 1.x 版本号方案（主版本人工升，次版本随构建递增）

### 目录结构

github-sandbox-push/
  SKILL.md                      完整流程 + 陷阱速查表（自包含）
  references/android-build-release.yml  已验证通过的 Android CI 工作流，可直接复用

### 在电脑端安装 / 使用

技能本质就是文件夹 + Markdown，无需编译、无需特殊安装命令：

1. 把 github-sandbox-push/ 整个文件夹复制到本机 WorkBuddy 的技能目录：
   - macOS / Linux：~/.codebuddy/skills/github-sandbox-push/
   - Windows：%USERPROFILE%\.codebuddy\skills\github-sandbox-push\
2. 重启 WorkBuddy（或新建会话），技能即自动可用。
3. 之后只要说「推到 GitHub」「发布 Release」「跑构建」之类，助手会按 SKILL.md 的流程走，不会再踩上面的坑。

说明：本仓库的技能当前安装在云端沙箱；要在一台具体的电脑上使用，按上面复制文件夹即可。仓库里的文件就是技能源，和安装后的文件一致。
