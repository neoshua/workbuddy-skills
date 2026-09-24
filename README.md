# workbuddy-skills

WorkBuddy 自定义技能集合。目前收录：

## github-sandbox-push

在沙箱 / 受限网络环境下与 GitHub 交互的避坑流程技能（推送代码、通过 CI 发布 APK 等）。

目录结构（每个技能一个独立文件夹）：

```
workbuddy-skills/
├── README.md
├── install.sh          # macOS / Linux 一键安装
├── install.ps1         # Windows 一键安装
└── github-sandbox-push/
    ├── SKILL.md                       # 完整流程 + 陷阱速查表（自包含）
    └── references/
        └── android-build-release.yml  # 已验证通过的 Android CI 工作流
```

## 一键安装（推荐）

**macOS / Linux：**
```bash
curl -fsSL https://raw.githubusercontent.com/neoshua/workbuddy-skills/main/install.sh | bash
```

**Windows（PowerShell）：**
```powershell
Invoke-RestMethod -Uri https://raw.githubusercontent.com/neoshua/workbuddy-skills/main/install.ps1 | Invoke-Expression
```

脚本会把 `github-sandbox-push/` 下载到本机 WorkBuddy 技能目录：
- macOS / Linux：`~/.codebuddy/skills/github-sandbox-push/`
- Windows：`%USERPROFILE%\.codebuddy\skills\github-sandbox-push\`

安装后**重启 WorkBuddy**（或新建会话），技能即自动可用。之后说「推到 GitHub」「发布 Release」「跑构建」之类，助手会按 SKILL.md 的流程走，不再踩坑。

## 手动安装

把 `github-sandbox-push/` 整个文件夹复制到上面那个技能目录即可，无需编译、无需特殊命令。

> 说明：本仓库即技能源。云端沙箱里的安装与电脑端相互独立，按上面任一种方式装到本机即可。
