# deepseek-harness-docker

<p align="center">
  <a href="https://github.com/gleikeen/deepseek-harness-docker"><img alt="GitHub repo" src="https://img.shields.io/badge/github-gleikeen%2Fdeepseek--harness--docker-181717?style=flat-square&logo=github"></a>
  <a href="https://github.com/gleikeen/deepseek-harness-docker/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/gleikeen/deepseek-harness-docker?style=flat-square"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/gleikeen/deepseek-harness-docker?style=flat-square"></a>
</p>

把 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（`dsh`）**一键打包成 Docker**，并接入微信（个人微信）输入 / 输出。微信侧由 [dsh-wechat-bridge](https://github.com/gleikeen/dsh-wechat-bridge) 插件提供（基于腾讯 iLink Bot API）。

> 欢迎 Star ⭐、Fork、提 Issue / PR。一条 `docker compose up` 就拥有自己的微信 AI 助手。

## ✨ 特性

- **完整 dsh 能力**：镜像内是 `dsh-base` 全套——bash / 文件 / web 搜索 / 子代理 / todo 等工具、沙箱与审批策略、会话持久化，全部从微信可达。
- **一键部署**：`docker compose up -d`，扫码登录一次即可长期运行。
- **持久化**：会话、peer→session 映射、context_token 都存在 volume 里，重启不丢。
- **多模式**：`setup`（扫码登录）/ `weixin`（默认跑 bot）/ `web`（Web UI）三种模式。

## 架构

```
微信 (个人号) ──iLink Bot API──▶ dsh-wechat-bridge 插件 ──▶ ctx.agents (dsh Agent)
        ◀────── sendmessage ──────  (assistant/message 文本回传)
```

- 一个微信好友（DM）↔ 一个持久化 Agent，重启后仍记得对话（dsh session 持久化）。
- 二维码登录、长轮询收消息、`context_token` 回显，全部在插件里，运行时零第三方依赖。

## 快速开始

### 1. 构建镜像

```sh
docker compose build
# 或手动：docker build -t dsh-weixin --build-arg DSH_VERSION=0.1.0-rc.6 --build-arg BRIDGE_REF=master .
```

> 构建需要网络（git + npm registry）。建议把 `BRIDGE_REF` 固定为具体 tag、`DSH_VERSION` 固定为某个已发布的 dsh 版本，以获得可复现构建。

### 2. 扫码登录（一次性）

```sh
cp .env.example .env
docker compose run --rm weixin setup
```

终端会渲染二维码（或打印链接），用微信扫码并确认。把打印的 `WEIXIN_ACCOUNT_ID` / `WEIXIN_TOKEN` / `WEIXIN_BASE_URL` 填进 `.env`，同时填 `DEEPSEEK_API_KEY`。

### 3. 启动

```sh
docker compose up -d
docker compose logs -f weixin
```

在微信里给对应的 bot 身份发消息即可对话。

## 环境变量

| 变量 | 必填 | 默认 | 说明 |
|---|---|---|---|
| `WEIXIN_ACCOUNT_ID` | ✅ | — | iLink bot 身份（扫码得到） |
| `WEIXIN_TOKEN` | ✅ | — | iLink bot token（扫码得到） |
| `WEIXIN_BASE_URL` | — | `https://ilinkai.weixin.qq.com` | iLink API 源 |
| `DEEPSEEK_API_KEY` | ✅ | — | 模型 key（同 Web UI 的 DeepSeek 官方适配器） |
| `WEIXIN_DM_POLICY` | — | `open` | `open` 或 `allowlist` |
| `WEIXIN_ALLOWED_USERS` | — | 空 | 逗号分隔的允许 user_id |
| `WEIXIN_WORKSPACE` | — | `/workspace` | Agent 工作目录（容器内路径） |
| `WEIXIN_PROVIDER` / `WEIXIN_MODEL` | — | 继承默认 | 覆盖模型选择 |

## 持久化

- `dsh-home` volume：dsh 会话日志、peer→session 映射、context_token。
- `./workspace`：Agent 的工作目录；挂载你的项目目录即可让 bot 直接操作代码。

## 其他模式

```sh
docker compose run --rm weixin web     # 起 Web UI（端口 3080）
```

## 已知限制

- **仅文本**：iLink 加密媒体 CDN（图片 / 文件 / 语音）未实现。
- **群消息不可达**：QR 登录连接的是 iLink bot 身份，腾讯通常不投递普通微信群事件。
- **非官方协议**：iLink Bot API 是个人微信的非官方接口，仅建议个人使用，自行评估合规风险。

## 状态

- 插件（`dsh-wechat-bridge`）已本地验证：`tsc` 类型检查通过、构建通过、iLink 协议请求 / 响应形状已用 mock server 对齐 hermes 的 `weixin.py`。
- 安装链路已用真实 dsh 验证：`dsh plugin --profile weixin add file:<bridge>` → `--dump-config` 出现 `wechat-bridge` 行 → 启动时插件正确挂载并在缺凭据时按预期报错。
- `Dockerfile` 走 npm 发布的 `@deepseek-ai/dsh`（官方文档路径）+ 源码构建插件，尚未在 CI 里跑过完整 `docker build`。如构建失败，优先检查 `BRIDGE_REF` 是否指向含 `package.json` 的有效 tag、`DSH_VERSION` 是否存在于 npm。

## 贡献

欢迎任何形式的贡献：Bug 报告、功能建议、PR。开 Issue 前请先搜索是否已有同类问题。

## 致谢

- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（MIT）——镜像所打包的 agent 框架。
- [dsh-wechat-bridge](https://github.com/gleikeen/dsh-wechat-bridge)（MIT）——微信接入插件。

## 许可证

[MIT](LICENSE) © 2026 gleikeen
