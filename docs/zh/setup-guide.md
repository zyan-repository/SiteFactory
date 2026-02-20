[English](../setup-guide.md) | **中文**

# 配置指南

从零开始配置 SiteFactory，完全不需要编程基础。

## 你需要准备什么

开始之前，注册以下账号并获取凭证：

| 项目 | 在哪里获取 | 费用 | 难度 |
|------|-----------|------|------|
| 域名 | [NameSilo](https://www.namesilo.com/) | ~$9/年 | 搜索你想要的域名 → 加购物车 → 付款 |
| NameSilo API Key | [API 管理页](https://www.namesilo.com/account/api-manager) | 免费 | 点击"Generate"按钮 |
| Vercel 账号 | [vercel.com](https://vercel.com/) | 免费 | 用 GitHub 账号直接登录 |
| Vercel Token | [令牌页](https://vercel.com/account/tokens) | 免费 | 点击"Create" → 复制令牌 |
| Google AdSense | [adsense.google.com](https://adsense.google.com/) | 免费 | 注册后获取发布者 ID |
| Google Analytics | [analytics.google.com](https://analytics.google.com/) | 免费 | 创建媒体资源 → 获取衡量 ID |
| UptimeRobot（可选） | [uptimerobot.com](https://uptimerobot.com/) | 免费 | 注册后在设置里找 API Key |
| AI API Key（可选） | 见下方支持列表 | 按量付费 | 用于 AI 自动生成文章（支持 OpenAI/Claude/Gemini/DeepSeek/Kimi/GLM） |

> 如果你还没有 GitHub 账号，先去 [github.com](https://github.com/) 注册一个（免费的），后面的 Vercel 需要用 GitHub 登录。

**还没有全部准备好？** 没关系——下面会一步一步教你怎么获取每个凭证。可选项（UptimeRobot、Claude API）可以以后再配。

> **中国大陆用户注意**：Google 系列服务（AdSense、Analytics、Search Console）可能需要特殊网络环境才能访问。请确保你能正常打开这些网站再进行配置。

## 每个凭证怎么获取

> 以下操作说明基于 2026 年 2 月的页面布局。如果网站改版了，相同的信息还在——找设置/账号之类的入口就行。

### 1. 域名（NameSilo）

域名就是你网站的地址（比如 `mysite.com`），需要花钱买一个。

**操作步骤：**
1. 打开 [https://www.namesilo.com/domain/search-domains](https://www.namesilo.com/domain/search-domains)
2. 在搜索框里输入你想要的域名（比如 `techtools`）
3. 点击 **"Search"** 搜索
4. 在结果里找一个显示 "Available"（可用）的 `.com` 域名
5. 点击旁边的 **"Add"** 加入购物车
6. 点击右上角 **购物车图标** → **"Checkout"** 去结账
7. 注册 NameSilo 账号（或登录已有账号）
8. 付款（支持 PayPal 或信用卡，`.com` 大约 $8.99/年 ≈ ¥65/年）
9. 买完后，你的域名会出现在 [域名管理页](https://www.namesilo.com/account/domain-manager)

**填到 config.yaml 里的格式：** 只写域名本身，不要加 `https://` 或 `www.`

| 正确 | 错误 |
|------|------|
| `mysite.com` | `https://mysite.com` |
| `techtools.net` | `www.techtools.net` |

> **建议：** 选 `.com` 后缀（SEO 效果最好）。域名里不要用连字符（-）。越短越好记越好。

### 2. NameSilo API Key

API Key 是一串密码，让 SiteFactory 的脚本能自动帮你管理域名的 DNS 记录（就是让域名指向你的网站）。

**操作步骤：**
1. 登录 NameSilo
2. 打开 [https://www.namesilo.com/account/api-manager](https://www.namesilo.com/account/api-manager)
3. 如果页面显示 "You have not generated any API keys"，点击 **"Generate"** 按钮
4. **不要勾选** "Generate key for read-only access"（SiteFactory 需要写入 DNS 记录，read-only 权限不够）
5. 页面上会出现一串字符——这就是你的 API Key
6. **立即复制保存**到 config.yaml（之后可能看不到完整内容了）

**长什么样：** 大约 20-30 个字母和数字混合的字符串，比如 `a1b2c3d4e5f6g7h8i9j0k`

> **安全提醒：** 这个 Key 能操控你域名的所有设置，绝对不要分享给别人或提交到 git。

### 3. Vercel 账号 + Token

Vercel 是一个免费的网站托管服务，你的所有站点都会部署在上面。

**前提——需要 GitHub 账号：**
1. 如果你还没有 GitHub 账号，去 [https://github.com/signup](https://github.com/signup) 注册一个（免费的）

**注册 Vercel 账号：**
1. 打开 [https://vercel.com/](https://vercel.com/)
2. 点击 **"Sign Up"**
3. 选择 **"Continue with GitHub"**（用 GitHub 登录）
4. 授权 Vercel 访问你的 GitHub 账号
5. 完成，你现在有了一个 Vercel 免费账号（Hobby 计划）

**创建 Vercel Token（令牌）：**
1. 打开 [https://vercel.com/account/tokens](https://vercel.com/account/tokens)
2. 点击 **"Create"**
3. 填写表单：
   - **Token Name（名称）：** 随便填（比如 "SiteFactory"）
   - **Scope（范围）：** 选 **"Full Account"**（给令牌部署权限）
   - **Expiration（有效期）：** 选 "No Expiration"（永不过期）或任何你喜欢的时长
4. 点击 **"Create Token"**
5. 页面上出现一串字符——**立即复制！** 这个令牌只显示这一次，关掉页面就看不到了。如果忘了复制，重新创建一个新的就行。

**长什么样：** 大约 24 个字符以上的字符串，比如 `pZGwkE1JaBcDeFgHiJkLmN`

### 4. AdSense 发布者 ID（Publisher ID）

AdSense 是 Google 的广告联盟，访客看到或点击你网站上的广告时你就能赚钱。你需要注册并获取发布者 ID。

**注册步骤：**
1. 打开 [https://adsense.google.com/](https://adsense.google.com/)
2. 用 Google 账号（Gmail）登录
3. 如果是第一次，点击 **"开始使用"** 并按步骤填写（提供你的网站地址和国家）
4. Google 会审核你的申请——这需要几天到几周

**获取发布者 ID（有了 AdSense 账号之后）：**

**方法一——从浏览器地址栏获取（最快）：**
1. 登录 [https://adsense.google.com/](https://adsense.google.com/)
2. 看浏览器地址栏里的 URL
3. URL 里会包含类似 `.../pub-5531531271065052/...` 的数字
4. 在这串数字前面加上 `ca-`，就是你的完整发布者 ID：**`ca-pub-5531531271065052`**

**方法二——从设置页面获取：**
1. 登录 AdSense
2. 点击左侧菜单的 **齿轮图标**（设置）
3. 点击 **"账号"** → **"账号信息"**
4. 找到 **"发布商 ID"** 一行，显示 `pub-XXXXXXXXXXXXXXXX`
5. 在 config.yaml 里填写时，前面加 `ca-`：**`ca-pub-XXXXXXXXXXXXXXXX`**

**长什么样：** 固定格式，`ca-pub-` 后面跟 16 位数字。例如：`ca-pub-5531531271065052`

> **还没有通过审核？** 没关系。在 config.yaml 里把 `publisher_id` 保持为示例值，把 `adsense.enabled` 改成 `false`。等审核通过后再回来填真实的 ID。通过审核的技巧见[内容策略](content-strategy.md)。

### 5. Google Analytics 衡量 ID（Measurement ID）

Google Analytics 用来追踪你的网站有多少访客、访客从哪来。

**首次创建 Google Analytics 媒体资源：**
1. 打开 [https://analytics.google.com/](https://analytics.google.com/)
2. 用 Google 账号登录
3. 点击 **"开始衡量"**（或 "创建账号"）
4. **账号名称：** 随便填（比如 "SiteFactory"）
5. 点击 **"下一步"**
6. **媒体资源名称：** 随便填（比如 "我的站点"）
7. 选择你的时区和货币
8. 点击 **"下一步"** → 跳过商家详情 → 点击 **"创建"**
9. 同意服务条款
10. 在"选择平台"页面，选 **"网站"**
11. **网站网址：** 填你在第 1 步买的域名，格式为 `https://你的域名.com`（网站现在还没上线没关系，GA 只是用这个地址来创建追踪 ID，不会检查网站是否可访问）
12. **数据流名称：** 随便填（比如 "主站"）
13. 点击 **"创建数据流"**
14. **衡量 ID** 显示在数据流详情页面的右上角——以 `G-` 开头

> **还没买域名？或者想晚点再配？** 没关系。在 config.yaml 里把 `google_analytics_id` 保持为示例值 `"G-XXXXXXXXXX"` 即可。等站点部署上线后再回来创建数据流、填入真实的衡量 ID。

**已经有 Google Analytics 账号但还没创建数据流：**
1. 点击左下角 **齿轮图标**（管理）
2. 在"媒体资源"列下，点击 **"数据流"**
3. 如果页面显示"开始收集数据"并让你选择平台——说明你还没创建数据流，点击 **"网站"** 然后按上面第 11-14 步操作
4. 如果已经有数据流，点击它——**衡量 ID** 在右上角

**长什么样：** `G-` 后面跟 10 个大写字母或数字。例如：`G-A1B2C3D4E5`

### 6. Google Search Console 验证码（可选——以后再配也行）

Google Search Console 让你提交网站地图，让 Google 更快收录你的页面。

**操作步骤：**
1. 打开 [https://search.google.com/search-console](https://search.google.com/search-console)
2. 点击左上角下拉菜单 → **"添加资源"**
3. 选择右边的 **"网址前缀"**
4. 输入你的网址：`https://你的域名.com`
5. 点击 **"继续"**
6. 选择 **"HTML 标记"** 验证方式
7. Google 会显示一个 meta 标签，类似 `<meta name="google-site-verification" content="AbCdEf123456789..." />`
8. 只复制 `content="..."` 里面的那串字符——这就是你的验证码

**长什么样：** 大约 43 个字母数字混合的字符串

> **注意：** 验证需要你的站点已经上线且 DNS 已生效。如果现在验证不了，等站点部署好了再回来做这一步。

### 7. UptimeRobot API Key（可选）

UptimeRobot 用来监控你的网站是不是在线，如果挂了会发邮件提醒你。

**操作步骤：**
1. 打开 [https://uptimerobot.com/](https://uptimerobot.com/) 注册免费账号
2. 登录
3. 点击右上角 **头像图标**
4. 点击 **"My Settings"**（我的设置）
5. 往下滚动找到 **"API Settings"** 板块
6. 找到 **"Main API Key"** → 点击 **"Show/Create"**
7. 复制显示的 Key

**长什么样：** 以 `u` 开头，后面跟大约 39 个字符。例如：`u1234567-abcdef1234567890abcdef12`

### 8. AI API Key（可选 — 支持多家模型）

只有你想用 AI 自动生成博客文章时才需要。支持以下任意一家，选一个填 API Key 即可：

| 提供商 | 获取地址 | API Key 格式 |
|--------|---------|-------------|
| OpenAI | [platform.openai.com/api-keys](https://platform.openai.com/api-keys) | `sk-...` |
| Claude (Anthropic) | [console.anthropic.com](https://console.anthropic.com/) → API Keys | `sk-ant-...` |
| Gemini (Google) | [aistudio.google.com/apikey](https://aistudio.google.com/apikey) | `AIza...` |
| DeepSeek | [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys) | `sk-...` |
| Moonshot (Kimi) | [platform.moonshot.cn/console/api-keys](https://platform.moonshot.cn/console/api-keys) | `sk-...` |
| Zhipu (GLM) | [open.bigmodel.cn/usercenter/apikeys](https://open.bigmodel.cn/usercenter/apikeys) | 字母数字串 |

**配置方法：** 在 `config.yaml` 中设置 `ai.provider` 为你选择的提供商，然后在对应的 `ai.providers.{provider}.api_key` 里填入 Key。

> 生成一篇文章大约 $0.01-0.05。DeepSeek 和 GLM 最便宜。

---

## 第一步：安装工具

### Mac 用户

打开终端（按 `Command + 空格`，输入 `Terminal`，回车），然后逐行执行：

### macOS

```bash
# 安装 Homebrew（Mac 的软件包管理器）
# 如果提示"Already installed"说明已经装了，跳过即可
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装需要的工具
brew install hugo yq jq node git
```

### Ubuntu/Debian

```bash
sudo apt-get install hugo yq jq nodejs git
```

### Windows

请先安装 [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install)，然后按照 Ubuntu 说明操作。

> 安装时如果让你输入密码，输入你的登录密码（输入时屏幕不会显示任何字符，这是正常的），输完按回车。

### 验证安装

```bash
hugo version    # 应该显示 Hugo 版本号
node --version  # 应该显示 v开头的版本号
git --version   # 应该显示 git version 开头
```

如果某个命令提示 "command not found"，重新运行 `brew install <工具名>`。

## 第二步：下载项目

```bash
# 下载项目代码
git clone https://github.com/yourname/SiteFactory.git

# 进入项目目录
cd SiteFactory
```

## 第三步：运行初始配置

```bash
./scripts/setup.sh
```

第一次运行会：
1. 检查所有工具是否安装好
2. 自动创建 `config.yaml` 配置文件
3. 提示你去编辑配置文件

## 第四步：填写配置

用文本编辑器打开 `config.yaml`：

```bash
# Mac 用默认程序打开
open config.yaml

# 或者在终端里编辑（适合习惯命令行的人）
nano config.yaml
```

文件里每个字段都有注释告诉你去哪拿值。把 `YOUR_xxx` 和 `XXXX` 替换成你自己的值：

```yaml
domain:
  name: "mysite.com"                    # ← 你买的域名（上面第 1 节）
  namesilo_api_key: "abc123def456"      # ← NameSilo API Key（上面第 2 节）

vercel:
  token: "your-vercel-token"            # ← Vercel Token（上面第 3 节）

adsense:
  publisher_id: "ca-pub-1234567890"     # ← AdSense 发布者 ID（上面第 4 节）
  enabled: true                         # ← 还没通过审核的话改成 false

analytics:
  google_analytics_id: "G-XXXXXXXXXX"   # ← Analytics 衡量 ID（上面第 5 节）
```

> **用 `nano` 编辑的话：** 按 `Ctrl + O` 保存，`Ctrl + X` 退出。

### 凭证速查表

| config.yaml 字段 | 去哪里拿 | 格式 | 示例 |
|------------------|---------|------|------|
| `domain.name` | [NameSilo 域名管理](https://www.namesilo.com/account/domain-manager) | `example.com`（不带 https://） | `mysite.com` |
| `domain.namesilo_api_key` | [NameSilo API 管理](https://www.namesilo.com/account/api-manager) → Generate | 约 20-30 个字母数字 | `a1b2c3d4e5f6...` |
| `vercel.token` | [Vercel 令牌页](https://vercel.com/account/tokens) → Create | 约 24+ 个字符 | `pZGwkE1J...` |
| `adsense.publisher_id` | [AdSense](https://adsense.google.com/) → 地址栏或设置→账号信息 | `ca-pub-` + 16 位数字 | `ca-pub-5531531271065052` |
| `analytics.google_analytics_id` | [GA](https://analytics.google.com/) → 新账号点"开始衡量"创建；已有账号点齿轮 → 数据流 | `G-` + 10 个字符 | `G-A1B2C3D4E5` |
| `analytics.google_search_console_verification` | [Search Console](https://search.google.com/search-console) → 添加资源 → HTML 标记 | 约 43 个字符 | `AbCdEf123...` |

## 第五步：验证配置

```bash
./scripts/setup.sh
```

重新运行后，会逐项检查你的凭证是否正确。全部绿色 ✓ 就 OK 了。

如果有红色 ✗：

| 错误 | 怎么解决 |
|------|---------|
| ✗ adsense.publisher_id not set | 按[上面第 4 节](#4-adsense-发布者-idpublisher-id)操作，或者先把 `enabled` 改成 `false` 跳过 |
| ✗ Vercel token invalid | 去[令牌页](https://vercel.com/account/tokens)删掉旧的，重新创建一个 |
| ✗ NameSilo API key error | 去 [API 管理页](https://www.namesilo.com/account/api-manager)确认 Key 是否正确，域名是否在你的账户下 |
| ✗ 某个值还显示 "XXXX" | 你忘了替换某个占位符——打开 config.yaml 找到它填上真实值 |

## 第六步：创建第一个站点

### 方式 A：从 GitHub Fork 一个工具站

```bash
# 先检查项目兼容性
./scripts/check-repo.sh https://github.com/evgeni/qifi

# 如果显示 COMPATIBLE，就可以 fork
./scripts/fork-site.sh https://github.com/evgeni/qifi wifi-qr "WiFi 二维码生成器"
```

在浏览器里预览：

```bash
open sites/wifi-qr/index.html
```

### 方式 B：创建一个 Hugo 博客站

```bash
./scripts/new-site.sh my-blog "我的技术博客" "分享编程技巧和教程"
```

本地预览：

```bash
hugo server -s sites/my-blog
# 打开浏览器访问 http://localhost:1313
```

## 第七步：部署上线

```bash
# 部署站点到 Vercel
./scripts/deploy.sh wifi-qr

# 添加 DNS 记录（让域名指向你的站点）
./scripts/dns-setup.sh wifi-qr
```

完成后你的站点会在 `https://wifi-qr.mysite.com` 上线（DNS 生效需要几小时到 48 小时）。

**怎么看 DNS 是不是生效了：**
- 打开 [https://dnschecker.org/](https://dnschecker.org/)
- 输入 `wifi-qr.你的域名.com`，记录类型选 "CNAME"，点搜索
- 如果结果显示 `cname.vercel-dns.com`，说明 DNS 已生效
- 如果什么都没有或显示错误，再等几个小时重新检查

## 第八步：申请 AdSense（等站点运行 1-2 周后）

1. 先给站点添加足够的内容（至少 15 页，每页 300+ 字）
2. 确保隐私政策和关于页面存在（模板已自动包含）
3. 等 Google 收录你的站点（通常 1-2 周）
4. 去 [adsense.google.com](https://adsense.google.com/) 申请
5. 审核通过后，把真实的 `publisher_id` 填入 config.yaml，`enabled` 改成 `true`
6. 重新部署所有站点：`./scripts/deploy-all.sh`——广告会自动出现

详细技巧见 [内容策略](content-strategy.md)。

## 常见问题

### "command not found: hugo"

Hugo 可能不在系统路径里。试试：

```bash
# 查看 Hugo 的安装位置
which hugo || find /usr -name hugo 2>/dev/null

# macOS (Homebrew)：如果 Hugo 在 /opt/homebrew/bin
echo 'export PATH="/opt/homebrew/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc

# Linux：重新安装
sudo apt-get install hugo  # Ubuntu/Debian
sudo dnf install hugo      # Fedora
```

### Vercel Token 无效

1. 去 [vercel.com/account/tokens](https://vercel.com/account/tokens)
2. 删掉旧的 Token
3. 重新创建：Name 随便填，Scope 选 **"Full Account"**，Expiration 选你喜欢的
4. **立即复制**新 Token（只显示一次）
5. 更新 `config.yaml`

### NameSilo API Key 不工作

1. 去 [API 管理页](https://www.namesilo.com/account/api-manager) 确认 Key 是否还在且有效
2. 去 [域名管理页](https://www.namesilo.com/account/domain-manager) 确认域名在你的账户下
3. 如果 Key 不行了，重新 Generate 一个新的，更新 config.yaml

### Hugo 构建失败

```bash
# 查看详细错误
hugo -s sites/my-blog --verbose

# 清理缓存后重试
rm -rf sites/my-blog/resources
hugo -s sites/my-blog --gc --minify
```

### 还没有 AdSense 账号

可以先跳过，配好其他东西：
1. config.yaml 里 `publisher_id` 保持示例值不动
2. 把 `adsense.enabled` 改成 `false`
3. 先部署站点、添加内容、等 1-2 周
4. 去申请 AdSense（详见[内容策略](content-strategy.md)）
5. 通过后填入真实 publisher_id，`enabled` 改成 `true`
6. 重新部署所有站点：`./scripts/deploy-all.sh`

### DNS 超过 48 小时还没生效

1. 打开 [https://dnschecker.org/](https://dnschecker.org/) 查看传播状态
2. 输入 `你的站点.你的域名.com`，记录类型选 "CNAME"，点搜索
3. 如果没有结果：去 [NameSilo 域名管理](https://www.namesilo.com/account/domain-manager) → 点击你的域名 → DNS 记录，确认 CNAME 记录存在
4. CNAME 记录的值应该是 `cname.vercel-dns.com`——如果指向了别的地方，改过来
5. 如果都对但还是不行，再等等——极少数情况下 DNS 传播确实会超过 48 小时

### 忘记了 Vercel Token

Vercel Token 创建后无法再次查看。直接创建一个新的就行：
1. 去 [vercel.com/account/tokens](https://vercel.com/account/tokens)
2. 点击 **"Create"** 创建新 Token
3. 更新 config.yaml 里的 token 值
4. （可选）删掉旧的 Token

### config.yaml 格式错误

YAML 格式对空格很敏感：
- 使用空格缩进，**绝对不要用 Tab 键**
- 冒号后面必须有一个空格：`key: value`（不是 `key:value`）
- 值如果有特殊字符要用英文引号包裹（注意是英文引号 `""`，不是中文引号 `""`）

```yaml
# ✅ 正确
domain:
  name: "mysite.com"

# ❌ 错误（冒号后没有空格）
domain:
  name:"mysite.com"

# ❌ 错误（用了中文引号）
domain:
  name: "mysite.com"

# ❌ 错误（用了 Tab 缩进——看不出来但会报错）
domain:
	name: "mysite.com"
```

## 下一步

- 创建更多站点 → [添加新站点](adding-new-site.md)
- 找适合 Fork 的项目 → [Fork 指南](fork-guide.md)
- 通过 AdSense 审核 → [内容策略](content-strategy.md)
- 设置自动化 → [部署自动化](deployment-automation.md)
