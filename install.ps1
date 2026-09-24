# 一键安装 WorkBuddy 技能 github-sandbox-push 到本机
$info = Invoke-RestMethod -Uri "https://api.github.com/repos/neoshua/workbuddy-skills"
$defBranch = $info.default_branch
if (-not $defBranch) { $defBranch = "main" }
$raw = "https://raw.githubusercontent.com/neoshua/workbuddy-skills/$defBranch"
$skillDir = "$env:USERPROFILE\.codebuddy\skills\github-sandbox-push"
Write-Host "安装 github-sandbox-push -> $skillDir (分支 $defBranch)"
New-Item -ItemType Directory -Force -Path "$skillDir\references" | Out-Null
Invoke-WebRequest -Uri "$raw/github-sandbox-push/SKILL.md" -OutFile "$skillDir\SKILL.md"
Invoke-WebRequest -Uri "$raw/github-sandbox-push/references/android-build-release.yml" -OutFile "$skillDir\references\android-build-release.yml"
Write-Host "✅ 安装完成。重启 WorkBuddy（或新建会话）后技能即可用。"
