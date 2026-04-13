#!/bin/bash

set -e

# 1. 提示用户输入目标目录路径
read -p "请输入目标文件目录路径 (例如: /Users/xxx/claude_workspace): " TARGET_DIR

# 2. 如果目录不存在，则创建
if [ ! -d "$TARGET_DIR" ]; then
    echo "目录不存在，正在创建: $TARGET_DIR"
    mkdir -p "$TARGET_DIR"
fi

# 进入目录
cd "$TARGET_DIR" || exit
echo "已进入工作目录: $(pwd)"

# 3. 写入 Dockerfile
cat << 'EOF' > Dockerfile
FROM docker.1ms.run/node:24-bookworm-slim

RUN apt-get update && apt-get install -y git # && rm -rf /var/lib/apt/lists/*

# 全局安装 Claude Code
RUN npm install -g @anthropic-ai/claude-code

RUN apt-get install -y curl vim

# 创建一个非 root 用户
RUN useradd -m -u 1001 claudeuser
USER claudeuser

RUN echo '{"hasCompletedOnboarding": true}' > /home/claudeuser/.claude.json

WORKDIR /home/claudeuser/project

RUN echo "alias cc='claude --dangerously-skip-permissions'" >> /home/claudeuser/.bashrc

# 切模型api
RUN echo "alias glm='ln -sf /home/claudeuser/.claude/glm.json /home/claudeuser/.claude/settings.json'" >> /home/claudeuser/.bashrc
RUN echo "alias kimi='ln -sf /home/claudeuser/.claude/kimi.json /home/claudeuser/.claude/settings.json'" >> /home/claudeuser/.bashrc
RUN echo "alias openrouter='ln -sf /home/claudeuser/.claude/openrouter.json /home/claudeuser/.claude/settings.json'" >> /home/claudeuser/.bashrc

CMD ["/bin/bash"]
EOF

# 4. 写入 README.md
cat << 'EOF' > README.md
## 构建镜像

```bash
docker build -t claude-code .
```

## 启动

```bash
docker run -it \
  --name cc \
  -v "$(pwd)/claude_config/.claude.json:/home/claudeuser/.claude.json" \
  -v "$(pwd)/claude_config/.claude:/home/claudeuser/.claude" \
  claude-code
```

## 切换模型

`glm`、`kimi`

## 启动claude code

```bash
cc
```

EOF

# 5. 创建文件夹架构
mkdir -p claude_config/.claude

# 6. 写入 claude_config/.claude.json
cat << 'EOF' > claude_config/.claude.json
{
  "hasCompletedOnboarding": true
}
EOF

# 7. 写入 glm.json
cat << 'EOF' > claude_config/.claude/glm.json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<your_api_key>",
    "ANTHROPIC_BASE_URL": "https://open.bigmodel.cn/api/anthropic",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-5-turbo",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5.1",
    "CLAUDE_CODE_SUBAGENT_MODEL": "glm-5.1",
    "ENABLE_TOOL_SEARCH": 0,
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": 1,
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  },
  "skipDangerousModePermissionPrompt": true
}
EOF

# 8. 写入 kimi.json
cat << 'EOF' > claude_config/.claude/kimi.json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<your_api_key>",
    "ANTHROPIC_BASE_URL": "https://api.moonshot.cn/anthropic",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "kimi-k2-turbo-preview",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "kimi-k2-0905-preview",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "kimi-k2.5",
    "CLAUDE_CODE_SUBAGENT_MODEL": "kimi-k2.5",
    "ENABLE_TOOL_SEARCH": 0,
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": 1,
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  },
  "skipDangerousModePermissionPrompt": true
}
EOF

# 9. 写入 openrouter.json
cat << 'EOF' > claude_config/.claude/openrouter.json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<your_api_key>",
    "ANTHROPIC_BASE_URL": "https://openrouter.ai/api",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "nvidia/nemotron-3-super-120b-a12b:free",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "nvidia/nemotron-3-super-120b-a12b:free",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "nvidia/nemotron-3-super-120b-a12b:free",
    "CLAUDE_CODE_SUBAGENT_MODEL": "nvidia/nemotron-3-super-120b-a12b:free",
    "ENABLE_TOOL_SEARCH": 0,
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": 1,
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  },
  "skipDangerousModePermissionPrompt": true
}
EOF

# 10. 写入 baidu.json
# https://console.bce.baidu.com/qianfan/resource/subscribe
cat << 'EOF' > claude_config/.claude/baidu.json
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "<your_api_key>",
    "ANTHROPIC_BASE_URL": "https://qianfan.baidubce.com/anthropic/coding",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "minimax-m2.5",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "kimi-k2.5",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-5",
    "CLAUDE_CODE_SUBAGENT_MODEL": "glm-5",
    "ENABLE_TOOL_SEARCH": 0,
    "CLAUDE_CODE_DISABLE_EXPERIMENTAL_BETAS": 1,
    "API_TIMEOUT_MS": "3000000",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": 1
  },
  "skipDangerousModePermissionPrompt": true
}
EOF

# 11. 修改文件夹权限
chmod -R 777 claude_config

echo "----------------------------------------"
echo "任务完成！所有文件已生成在: $TARGET_DIR"
echo "提示: 别忘了在 glm.json 和 kimi.json 中填入你的 API Key。"
echo "启动命令请见README.md"
