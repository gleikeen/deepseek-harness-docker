# deepseek-harness-docker

<p align="center">
  <a href="https://github.com/gleikeen/deepseek-harness-docker"><img alt="GitHub repo" src="https://img.shields.io/badge/github-gleikeen%2Fdeepseek--harness--docker-181717?style=flat-square&logo=github"></a>
  <a href="https://github.com/gleikeen/deepseek-harness-docker/stargazers"><img alt="GitHub stars" src="https://img.shields.io/github/stars/gleikeen/deepseek-harness-docker?style=flat-square"></a>
  <a href="LICENSE"><img alt="License" src="https://img.shields.io/github/license/gleikeen/deepseek-harness-docker?style=flat-square"></a>
</p>

把 [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（`dsh`）**一键打包成 Docker**，并接入微信（个人微信）输入 / 输出。微信侧由 [dsh-wechat-bridge](https://github.com/gleikeen/dsh-wechat-bridge) 插件提供（基于腾讯 iLink Bot API）。

> 欢迎 Star ⭐、Fork、提 Issue / PR。

## ✨ 特性

- **完整 dsh 能力**：镜像内是 `dsh-base` 全套——bash / 文件 / web 搜索 / 子代理 / todo 等工具、沙箱与审批策略、会话持久化，全部从微信可达。
- **一条命令部署**：`docker compose up -d`，扫码一次即可长期运行。
- **持久化**：会话、peer→session 映射、context_token 都存 volume，重启不丢。
- **多模式**：`setup` 扫码 / `weixin` 跑 bot / `headless` 一次性任务 / `web` / `shell`。

## 快速开始（3 步）

### 第 1 步：构建镜像

```sh
cd deepseek-harness-docker
cp .env.example .env
docker compose build
```

> 构建需要网络（git + npm registry）。

### 第 2 步：扫码登录微信（一次性）

```sh
docker compose run --rm weixin setup
```

终端会渲染一个二维码（或打印一个链接），**用微信扫一扫**，手机确认登录。成功后终端打印：

```
WEIXIN_ACCOUNT_ID=xxxx@im.bot
WEIXIN_TOKEN=xxxx
WEIXIN_BASE_URL=https://ilinkai.weixin.qq.com
```

把这三行值填进 `.env` 对应字段（下面「配置微信」有详细说明）。

### 第 3 步：填 API Key 并启动

在 `.env` 里填 `DEEPSEEK_API_KEY`（获取方式见「配置 API Key」），然后：

```sh
docker compose up -d
docker compose logs -f weixin
```

看到日志里出现 `wechat-bridge: connected account=...` 就成功了。在微信里给对应的 bot 身份发消息即可对话。

---

## 配置详解

### 1. 配置微信

微信凭据只能通过**扫码**获得，流程如下：

1. `docker compose run --rm weixin setup` —— 打印二维码。
2. 微信扫二维码 → 手机确认 → 得到 `account_id / token / base_url`。
3. 把值写进 `.env`：

```dotenv
WEIXIN_ACCOUNT_ID=xxxx@im.bot
WEIXIN_TOKEN=xxxx
WEIXIN_BASE_URL=https://ilinkai.weixin.qq.com
```

4. `docker compose up -d`（重启容器生效）。

> 凭据长期有效；若某天 bot 不响应且日志报 `errcode=-14`（会话过期），重新跑一次 `setup` 扫码即可。

### 2. 配置 API Key

**推荐：环境变量方式（Docker 原生，无需浏览器）**

1. 打开 <https://platform.deepseek.com> → 右上角 **API Keys** → **创建 API Key**。
2. 复制 `sk-...` 开头的那串。
3. 填进 `.env`：

```dotenv
DEEPSEEK_API_KEY=sk-xxxxxxxx
```

微信 bot 和 `headless` 模式都会读它，填完 `docker compose up -d` 生效。

**另一种：网页界面方式（本地，非 Docker）**

dsh 自带网页界面，可以在浏览器里填 key 和聊天。但它**只在本地 `127.0.0.1` 监听**（见下），所以是给本机用的，不是给 Docker 容器映射端口用的：

```sh
npx @deepseek-ai/dsh web
# 浏览器打开 http://127.0.0.1:3080 → Settings → Models → 填入 API Key
```

### 3. Web 页面怎么打开

**先说结论：dsh 的 Web UI 不能安全地映射到宿主机端口。**

原因：dsh 的网页界面等于**远程执行代码**的能力（agent 有 bash / 文件读写工具）。dsh 作者**故意**只让它监听 `127.0.0.1`，并禁止 `--host 0.0.0.0`：

```
error: --host 0.0.0.0 is intentionally not supported yet for safety:
it would expose remote code execution to the network
```

所以正确的用法是：

| 需求 | 做法 |
|---|---|
| 只想让微信 bot 跑起来 | 不用开网页，填 `.env` 的 `DEEPSEEK_API_KEY` 即可 |
| 想在浏览器里聊天 / 图形化配模型 | 在**宿主机**上跑 `npx @deepseek-ai/dsh web`，开 `http://127.0.0.1:3080` |
| 想跑一次性任务 | 用 `headless` 模式（见下） |

> 如果你确实要把 Web UI 暴露到局域网，需自行 patch webserver 的 `host: 0.0.0.0`——**强烈不建议**，等于把能执行任意命令的 agent 暴露给整个网络。

### 4. CLI 方式

容器里可以用 dsh 的 CLI 跑一次性任务或交互式操作：

```sh
# 一次性任务（headless）：给个任务，打印结果后退出
docker compose run --rm weixin headless "用一句话总结这个仓库是干什么的"

# 进入容器 shell，手动执行任意 dsh 命令
docker compose exec weixin sh
dsh --version
dsh --profile headless "跑一下单测"
```

其它常用命令：

```sh
docker compose exec weixin dsh --version        # 查看版本
docker compose exec weixin dsh plugin list       # 查看插件
docker compose exec weixin ls /workspace         # 查看挂载的工作目录
```

## 环境变量

| 变量 | 必填 | 默认 | 说明 |
|---|---|---|---|
| `DEEPSEEK_API_KEY` | ✅ | — | 模型 key，<https://platform.deepseek.com> 获取 |
| `WEIXIN_ACCOUNT_ID` | ✅ | — | iLink bot 身份（`setup` 扫码得到） |
| `WEIXIN_TOKEN` | ✅ | — | iLink bot token（`setup` 扫码得到） |
| `WEIXIN_BASE_URL` | — | `https://ilinkai.weixin.qq.com` | iLink API 源 |
| `WEIXIN_DM_POLICY` | — | `open` | `open`=任何人都能私聊；`allowlist`=仅白名单 |
| `WEIXIN_ALLOWED_USERS` | — | 空 | `allowlist` 时生效，逗号分隔的 user_id |
| `WEIXIN_WORKSPACE` | — | `/workspace` | Agent 工作目录（容器内路径） |
| `WEIXIN_PROVIDER` / `WEIXIN_MODEL` | — | 继承默认 | 覆盖模型选择 |

## 持久化

- `dsh-home` volume：dsh 会话日志、peer→session 映射、context_token。
- `./workspace`：Agent 工作目录；挂载你的项目目录即可让 bot 直接操作代码（改 `docker-compose.yml` 里的 `./workspace` 路径）。

## 常见问题

| 现象 | 处理 |
|---|---|
| 启动报 `WEIXIN_ACCOUNT_ID and WEIXIN_TOKEN are required` | `.env` 没填或填错，重跑 `setup` 扫码 |
| 二维码过期 / 扫不上 | 重跑 `docker compose run --rm weixin setup`，二维码会自动刷新 3 次 |
| bot 不回复 | 看日志：`docker compose logs -f weixin`；检查 `DEEPSEEK_API_KEY` 是否有效 |
| 只想特定人能聊 | `.env` 设 `WEIXIN_DM_POLICY=allowlist` + `WEIXIN_ALLOWED_USERS=user_id`（user_id 从日志里对方的 `from_user_id` 取） |
| 群消息收不到 | iLink bot 身份通常收不到普通微信群事件，属平台限制，非本仓库问题 |

## 已知限制

- **仅文本**：iLink 加密媒体 CDN（图片 / 文件 / 语音）未实现。
- **群消息不可达**：QR 登录连接的是 iLink bot 身份，腾讯通常不投递普通微信群事件。
- **非官方协议**：iLink Bot API 是个人微信的非官方接口，仅建议个人使用，自行评估合规风险。

## 贡献

欢迎任何形式的贡献：Bug 报告、功能建议、PR。开 Issue 前请先搜索是否已有同类问题。

## 致谢

- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness)（MIT）
- [dsh-wechat-bridge](https://github.com/gleikeen/dsh-wechat-bridge)（MIT）

## 许可证

[MIT](LICENSE) © 2026 gleikeen
