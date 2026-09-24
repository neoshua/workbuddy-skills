#!/usr/bin/env bash
# 一键安装 WorkBuddy 技能 github-sandbox-push 到本机
set -e
REPO_API="https://api.github.com/repos/neoshua/workbuddy-skills"
DEF_BRANCH=$(curl -fsSL "$REPO_API" | python3 -c "import sys,json;print(json.load(sys.stdin).get('default_branch','main'))" 2>/dev/null || echo main)
RAW="https://raw.githubusercontent.com/neoshua/workbuddy-skills/$DEF_BRANCH"
SKILL_DIR="$HOME/.codebuddy/skills/github-sandbox-push"
echo "安装 github-sandbox-push -> $SKILL_DIR (分支 $DEF_BRANCH)"
mkdir -p "$SKILL_DIR/references"
curl -fsSL "$RAW/github-sandbox-push/SKILL.md" -o "$SKILL_DIR/SKILL.md"
curl -fsSL "$RAW/github-sandbox-push/references/android-build-release.yml" -o "$SKILL_DIR/references/android-build-release.yml"
echo "✅ 安装完成。重启 WorkBuddy（或新建会话）后技能即可用。"
