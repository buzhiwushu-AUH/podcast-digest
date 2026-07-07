# podcast-digest · 播客摘要小助手

自动追你订阅的小宇宙播客，把每期节目**转成文字 → 用 AI 出摘要 → 发到你邮箱**。来不及听，也能看完。

```mermaid
flowchart LR
    A["🎙️ 小宇宙播客<br/>(你订阅的节目)"] --> B["📝 Deepgram<br/>音频转文字"]
    B --> C["🤖 AI 大脑<br/>Claude / GLM / K
    C --> D["📧 Resend<br/>发到你邮箱"]
```

> 看不到图？流程就是一句话：**播客 → 转文字( (Resend)**。

---

## ⚠️ 开跑前，你要先准备这些（缺一不可）

这不是一个"下载就能用"的软件——它要**借用几个 面这几把「钥匙」（APIkey），再往下走。它们都是**去官网注册账号、复制一串 key**，不用在电脑上装东西。

| 你要准备 | 干嘛用的 | 去哪拿 |
|---|---|---|
| **① Deepgram 的 key** | 把播客音频转成文字 | deepgram.com 注册后拿 API key |
| **② Resend 的 key** | 把摘要发到你邮箱 | r 一次要绑一个发信邮箱/域名，按它引导走） |
| **③ AI 大脑的 key** | 生成摘要 | 看你用哪家：Claude / OpenAI / GLM / Kimi 等，各自官网拿 |

> 💡 **第 ③ 把可以省掉**——如果你电脑上已经装了 Claude Code，用本地模式就不用额外的 AI key
了。怎么弄见文末【最省事那条路】。

> 这几家都有**免费额度**，个人试用一般够用； 为准。

另外你电脑上要有：`bash`、`curl`、`python3`

---

## 🚀 上手步骤（照着一步步来）

**第 1 步：把项目下载到本地**
```bash
git clone <你的仓库地址> podcast-digest
cd podcast-digest
```

**第 2 步：复制两个配置文件（把「示例」变成
```bash
cp config.example.sh config.sh
cp channels.tsv.example channels.tsv
```

**第 3 步：让脚本可以运行**
```bash
chmod +x digest.sh fetch_transcript.sh
```

**第 4 步：填 key —— 打开 `config.sh`，把这几项填上**
- `DEEPGRAM_KEY`　→ 你的 Deepgram key
- `RESEND_KEY`　　→ 你的 Resend key
- `RECIPIENT_EMAIL`→ 摘要发到哪个邮箱（你自
- `FROM_EMAIL`　　→ 用哪个邮箱发出（在 Resend 里配好的那个）
- `LLM_BACKEND`　→ 选 AI 大脑：`claude`(默认ai` / `gemini` / `ollama`
  （用 GLM、Kimi、DeepSeek 这类国产模型？选 `openai`，再按注释填对应的 key 和接口地址。）

**第 5 步：告诉它追哪些播客 —— 打开 `channels.tsv`，一行一个**

格式（用 Tab 键分隔，不是空格）：
```
节目名称      播客ID  plain
```
> **怎么找播客 ID？** 在 xiaoyuzhoufm.com 打开那档节目，网址里 `xiaoyuzhoufm.com/podcast/<这串就是ID>`。

**第 6 步：第一次先「打底」（把已有节目标记为已读，避免一上来发一大堆旧的）**
```bash
./digest.sh --seed
```

**第 7 步：正式跑！**
```bash
./digest.sh
```
之后有新节目，再跑一次这条命令就会处理并发邮

---

## 🛠️ 常用命令速查

| 我想…… | 命令 |
|---|---|
| 第一次打底（标记旧节目为已读） | `./digest
| 正常跑一遍（处理新节目、发邮件） | `./digest.sh` |
| 强制处理某一档（测试用） | `./digest.sh --
| 只想拿某一期的文字稿 | `./fetch_transcript.sh <单集网址>` |

---

## 😌 最省事那条路：本地 Claude，少配一把 key

如果你电脑上**已经装了 Claude Code**，那 AI 那把 key（第 ③ 把）可以完全省掉：

1. 在 `config.sh` 里把 `LLM_BACKEND` 设成 `claude`（这也是默认值）。
2. 剩下只要备 **Deepgram + Resend** 两把 key

这是新手阻力最小的走法——想省事就走这条。

---

## ⏰ 想让它每天自动跑（macOS）

```bash
cp launchd/com.podcast-digest.plist.example ~/Library/LaunchAgents/com.podcast-digest.plist
```
然后编辑这个 plist 文件，把里面的 `__REPO__` 和 `__HOME__` 换成你的真实路径，再启用：
```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.podcast-digest.plist
