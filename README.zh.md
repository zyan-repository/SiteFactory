[English](README.md) | **中文**

# SiteFactory — 网页工厂

**批量生产，海量回报。**

静态网站批量生产系统 —— 一个域名的成本，建 100 个站点。从 GitHub 抄现成的开源项目，或者用 Hugo 生成内容站，自动部署到 Vercel，挂 AdSense 广告赚钱。

```
想法 → 抄/生成 → 部署 → 赚钱
       (2分钟)   (自动)  (躺赚)
```

## 为什么用 SiteFactory？

| | 传统方式 | SiteFactory |
|---|---|---|
| 每月建站数 | 1-2 个 | **50+ 个** |
| 每站成本 | ¥35-350/月 | **¥0** |
| 建站时间 | 几小时 | **< 2 分钟** |
| 技术要求 | 需要会编程 | **不需要** |
| 月总成本 | ¥350-3500 | **< ¥15** |

## 零基础入门指南

> 以下步骤假设你完全不懂电脑，会一步一步手把手教你。

### 第一步：打开终端

- **Mac**：按 `Command + 空格`，输入 `终端` 或 `Terminal`，回车
- **Windows**：按 `Win + R`，输入 `cmd`，回车（推荐用 WSL，参考 [WSL 安装指南](https://learn.microsoft.com/zh-cn/windows/wsl/install)）

### 第二步：安装必要工具

**macOS 用户**在终端里复制粘贴以下命令：

```bash
# 安装 Homebrew（Mac 的软件包管理器，如果已经装了可以跳过）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 安装项目所需的工具
brew install hugo yq jq node git
```

**Ubuntu/Debian 用户：**

```bash
sudo apt-get install hugo yq jq nodejs git
```

**Windows 用户：** 请先安装 [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install)，然后按照 Linux 说明操作。

> 安装过程中可能会让你输入电脑密码（输入时屏幕不会显示），输完按回车就行。

### 第三步：下载项目

```bash
git clone https://github.com/zyan-repository/SiteFactory.git
cd SiteFactory
```

### 第四步：首次配置

```bash
./scripts/setup.sh
```

第一次运行会自动生成 `config.yaml` 配置文件，并提示你填写各项凭证。

### 第五步：填写凭证

用任意文本编辑器打开 `config.yaml`：

```bash
open config.yaml    # Mac 用默认编辑器打开
# 或者
nano config.yaml    # 在终端里编辑（Ctrl+O 保存，Ctrl+X 退出）
```

必须填写的内容：

| 配置项 | 去哪里获取 | 怎么操作 | 值长什么样 |
|--------|-----------|---------|-----------|
| `domain.name` | [NameSilo](https://www.namesilo.com/) | 搜索域名 → 加购物车 → 付款（任何后缀均可：.com/.net/.top 等） | `mysite.com`（不带 https://） |
| `domain.namesilo_api_key` | [API 管理页](https://www.namesilo.com/account/api-manager) | 点击 **"Generate"** → 复制出现的字符串 | 约 20-30 个字母数字，如 `a1b2c3...` |
| `vercel.token` | [令牌页](https://vercel.com/account/tokens) | 点击 **"Create"** → 范围选 "Full Account" → **立即复制**（只显示一次！） | 约 24+ 个字符，如 `pZGwk...` |

> 每一步的详细图文教程见 [配置指南](docs/zh/setup-guide.md)，保证不用查任何资料就能跟着做。

可选配置（不填也能用，以后再补）：

| 配置项 | 用途 | 什么时候需要 |
|--------|------|-------------|
| `adsense.publisher_id` | AdSense 广告收入 | 等站点有内容后申请 AdSense，审核通过后再填（详见第十步） |
| `analytics.google_analytics_id` | 流量统计 | 推荐尽早配置，但不影响部署 |
| `ai.api_key` | AI 自动生成文章 | 想用 AI 写文章时再配 |
| `monitoring.uptimerobot_api_key` | 监控站点是否在线 | 站点多了以后再配 |

> **中国大陆用户注意**：Google 系列服务（AdSense、Analytics、Search Console）可能需要特殊网络环境才能访问。

### 第六步：验证配置

填完后再次运行：

```bash
./scripts/setup.sh
```

全部显示绿色对勾 ✓ 就说明配置成功了。

### 第七步：创建你的第一个站点

**推荐：用 Hugo 创建内容站 + AI 自动生成内容（最快满足 AdSense 要求）**

如果你在第五步配置了 AI API Key，Hugo 建站时会**自动生成种子文章、首页内容和关于页面**，加上模板自带的隐私政策、联系页和服务条款，**一条命令就满足 AdSense 对内容和合规页面的要求**：

```bash
# 推荐：创建 Hugo 站 + 部署 + DNS + 绑定主域名，一步到位
./scripts/launch-site.sh hugo adsense-home "我的首页" "搜索工具和实用资讯" --root
```

> 加了 `--root` 参数，这个站会同时部署到 `https://你的域名.com` 和 `https://adsense-home.你的域名.com`。AdSense 验证需要主域名有内容，所以第一个站建议就绑到主域名。

**也可以 Fork 工具站：**

```bash
# Fork 一个 GitHub 上现成的小工具
./scripts/launch-site.sh fork https://github.com/evgeni/qifi wifi-qr "WiFi 二维码生成器"
```

或者分步操作（手动控制每个环节）：

```bash
# 1. 创建站点
./scripts/new-site.sh adsense-home "我的首页" "搜索工具和实用资讯"

# 2. 部署到 Vercel + 绑定主域名
./scripts/deploy.sh adsense-home --root

# 3. 设置 DNS
./scripts/dns-setup.sh adsense-home --root
```

> DNS 生效需要最多 48 小时，耐心等待。生效后访问 `https://你的域名.com` 就能看到你的站点了。
>
> 怎么查 DNS 有没有生效？打开 [dnschecker.org](https://dnschecker.org/)，输入你的域名，记录类型选 A，如果结果显示 `76.76.21.21` 就说明生效了。

### 第八步：补充内容到 15 篇以上

如果第五步配置了 AI API Key，建站时已经自动生成了种子文章（默认 5 篇）。你只需要**继续补充到 15 篇以上**：

```bash
# 用 AI 继续生成文章
./scripts/generate-content.sh adsense-home "实用搜索技巧"
./scripts/generate-content.sh adsense-home "在线工具推荐"

# 或者手动创建文章
nano sites/adsense-home/content/posts/my-article.md
```

**Hugo 模板已自动包含以下 AdSense 必需页面**（无需手动创建）：
- 隐私政策（privacy-policy.md）
- 关于页面（about.md）
- 联系页面（contact.md）
- 服务条款（terms.md）

每篇文章建议 **300+ 字**（800+ 字效果更好）。补完文章后重新部署：

```bash
./scripts/deploy.sh adsense-home --root
```

> 没配 AI？也没关系，手动写或用任何 AI 工具生成文章，放到 `sites/站点名/content/posts/` 目录即可。详细的内容策略见 [内容策略](docs/zh/content-strategy.md)。

### 第九步：提交到 Google

让 Google 知道你的站点存在，加快收录速度：

1. 打开 [Google Search Console](https://search.google.com/search-console)
2. 点击左上角下拉菜单 → **"添加资源"**
3. 选择 **"网址前缀"** → 输入 `https://你的域名.com` → 点击 **"继续"**
4. 选择 **HTML 标记** 验证方式，把验证码填入 `config.yaml` 的 `google_search_console_verification` 字段
5. 重新部署站点：`./scripts/deploy-all.sh`
6. 回到 Search Console 点击 **"验证"**
7. 验证成功后，在左侧菜单点击 **"站点地图"** → 输入 `sitemap.xml` → 点击 **"提交"**

> **自动提交：** 如果在 `config.yaml` 中配置了 Service Account 密钥，每次部署会自动提交 sitemap，无需手动操作。详见[配置教程](docs/zh/setup-guide.md)。

> Google 收录通常需要几天到 2 周。可以在 Search Console 的「网页」页面查看收录进度。

### 第十步：申请 AdSense

> 确保站点已有足够内容（每站 15+ 页）、已绑定主域名（第七步）、已提交 Google 收录（第九步）。

1. 打开 [adsense.google.com](https://adsense.google.com/)
2. 点击 **"开始使用"**，用 Google 账号登录
3. 填写你的网站地址（`https://你的域名.com`）和国家
4. 按 Google 的提示完成注册
5. 等待审核（通常 **2-4 周**）
6. 审核通过后，获取发布者 ID（地址栏里的 `pub-数字`，前面加 `ca-`）
7. 填入 `config.yaml` 的 `adsense.publisher_id`，把 `enabled` 改成 `true`
8. 重新部署：`./scripts/deploy-all.sh` —— 广告自动出现！

> 如果被拒绝了也不要慌，常见原因和解决方法见 [内容策略](docs/zh/content-strategy.md)。

### 完成！

恭喜，你已经完成了从零到赚钱的全部流程。接下来可以：

- **扩大规模** —— 创建更多站点，详见 [添加新站点](docs/zh/adding-new-site.md)
- **找更多项目来 Fork** —— 详见 [Fork 指南](docs/zh/fork-guide.md)
- **优化内容和 SEO** —— 详见 [内容策略](docs/zh/content-strategy.md)
- **设置自动化** —— 详见 [部署自动化](docs/zh/deployment-automation.md)

---

## Fork 部署（进阶 · 适合有 GitHub 经验的用户）

> **新手请跳过这一节。** 以上 10 步教程已经是完整流程。下面是给想 Fork 本项目到自己 GitHub 账号的用户看的，适合有 Git/GitHub 使用经验的人。

想把 SiteFactory 复制一份到自己的 GitHub 账号？Fork 本项目即可 —— 完整的自动化流水线开箱即用，还能随时同步上游的脚本和模板更新。

### 第一步：Fork 仓库

在 GitHub 仓库页面点击 **Fork** 按钮，获得你自己的副本（GitHub Actions 自动启用）。

### 第二步：配置 GitHub Secrets

进入**你的 Fork 仓库** → Settings → Secrets and variables → Actions，添加以下密钥：

| Secret 名称 | 值 |
|-------------|-----|
| `SF_DOMAIN` | 你的域名（如 `mysite.com`） |
| `SF_VERCEL_TOKEN` | Vercel API 令牌 |
| `SF_NAMESILO_API_KEY` | NameSilo API 密钥 |
| `SF_ADSENSE_PUB_ID` | AdSense 发布者 ID |
| `SF_GA_ID` | Google Analytics 衡量 ID |
| `SF_AI_API_KEY` | AI 服务的 API 密钥（用于内容生成） |
| `SF_AI_PROVIDER` | AI 服务商名称（`claude`、`deepseek`、`openai`、`gemini`、`moonshot`、`zhipu`），默认 `claude` — **必须与 `SF_AI_API_KEY` 的服务商匹配** |
| `SF_VERCEL_TEAM_ID` | *（可选）* Vercel 团队/组织 ID，用于团队部署 |
| `SF_CONTENT_SCHEDULE` | *（可选）* 内容生成频率：`daily`、`2x-week`、`weekly`（默认）、`biweekly` |
| `SF_GSC_KEY_JSON` | *（可选）* Google Search Console 服务账号 JSON 密钥内容（部署时自动提交 sitemap） |

### 第三步：本地配置

```bash
git clone https://github.com/你的用户名/SiteFactory.git
cd SiteFactory
./scripts/setup.sh        # 创建 config.yaml，检查工具
nano config.yaml           # 填写你的凭证
```

### 第四步：部署和创建站点

仓库自带示例站点（如 `wifi-qr`），可以直接部署：

```bash
# 直接部署仓库自带的示例站点 — 无需重新创建
./scripts/deploy.sh wifi-qr
./scripts/dns-setup.sh wifi-qr
```

添加自己的新站点：

```bash
# Fork 新的工具站（使用新名称，不要和 sites/ 下已有的重名）
./scripts/launch-site.sh fork https://github.com/user/repo my-tool "我的工具"

# 或创建 Hugo 内容站
./scripts/launch-site.sh hugo my-blog "我的博客" "分享技术心得"
```

推送即可触发 GitHub Actions 自动部署：

```bash
git add sites/
git push
```

任何对 `sites/` 或 `themes/` 目录的推送都会自动触发 GitHub Actions 部署。主题变更会自动重建所有 Hugo 站点。

### 第五步：同步上游更新

添加原始仓库为 `upstream`，随时拉取脚本改进、模板更新和 CI 修复：

```bash
# 一次性设置
git remote add upstream https://github.com/zyan-repository/SiteFactory.git

# 需要时同步
git fetch upstream
git merge upstream/main
```

**为什么不会冲突：** 你的站点使用独立的目录名（如 `sites/my-tool/`），上游对脚本、模板和 CI 的更新可以干净合并。只有 `SITES.md` 和 `root-domain.yaml` 可能需要手动处理 —— 这些文件每个站点只占一行，很容易解决。

> 完整的 CI/CD 配置详情见 [部署自动化](docs/zh/deployment-automation.md)。

## 工作原理

### 两条路线建站

**路线 A：抄（Fork）** —— 在 GitHub 上找现成的小工具（计算器、转换器、天气查询等），一条命令搞定改造和部署。

**路线 B：生成（Hugo）** —— 用模板生成一个 SEO 优化的博客站，可以用 AI 自动生成文章内容。

两种站点都会自动配置：
- AdSense 广告（自动放置）
- Google Analytics 统计
- SEO 优化（标题、描述、结构化数据、sitemap）
- 隐私政策页面（AdSense 必须有）
- SSL 证书（Vercel 自动处理）

### 项目结构

```
SiteFactory/
├── config.yaml              # 你的凭证配置（不会上传到 git）
├── SITES.md                 # 所有已集成站点的清单
├── content-plans/           # AI 内容生成计划和主题列表
├── themes/
│   └── sitefactory/         # 共享 Hugo 主题（所有 Hugo 站继承）
│       ├── layouts/         # 模板（baseof、single、list、partials）
│       ├── assets/css/      # 样式表（main.css）
│       ├── i18n/            # UI 翻译（en、zh、ja）
│       ├── static/          # 共享静态文件（og-default.png）
│       └── data/sites.yaml  # 跨站注册表（驱动页脚导航）
├── sites/
│   ├── _template/           # Hugo 站点脚手架（hugo.toml + 内容结构）
│   ├── _shared/             # Fork 站共用页面（en/zh/ja 三语版）
│   ├── my-blog/             # Hugo 内容站（type: hugo）
│   └── my-tool/             # Fork 的工具站（type: static）
├── scripts/                 # 自动化脚本（建站、部署、监控）
├── dashboard/               # 监控面板
└── docs/                    # 文档
```

### 站点类型

每个站点目录下都有一个 `site.yaml`，告诉系统怎么处理它：

```yaml
# Hugo 内容站（需要构建）
type: hugo
name: my-blog
source: template

# Fork 的静态站（直接部署）
type: static
name: wifi-qr
source: https://github.com/evgeni/qifi
license: MIT
```

## "能抄就不写"哲学

为什么要从零开发？GitHub 上有成千上万现成的小工具可以直接用！

### 适合抄的项目类型

| 类别 | 例子 | AdSense 价值 |
|------|------|-------------|
| 计算器 | BMI、贷款、房贷、小费 | 高（搜索意图精确）|
| 转换器 | 单位、汇率、时区、颜色 | 高（回头客多）|
| 生成器 | 密码、二维码、UUID、渐变色 | 高（SEO 关键词精准）|
| 数据查询 | 天气、IP 查询、汇率 | 高（日常流量大）|
| 参考工具 | 元素周期表、快捷键、Emoji 列表 | 中（用户停留时间长）|

### 怎么判断一个项目能不能抄？

运行 `./scripts/check-repo.sh <链接>` 自动检查，或者手动看：

- 许可证必须是 MIT / Apache / BSD（允许商用）
- 不能有后端代码（没有 server.js、app.py 这类文件）
- 不能有数据库（没有 DATABASE_URL）
- 能直接用浏览器打开 index.html
- 不需要登录注册

详细指南见 [Fork 指南](docs/zh/fork-guide.md)。

## 成本分析

| 资源 | 方案 | 费用 |
|------|------|------|
| 网站托管（Vercel） | 免费版（100GB/月流量） | 免费 |
| 域名（NameSilo） | 1 个域名 + 无限子域名 | 约 ¥65/年 |
| SSL 证书 | Vercel 自动配置 | 免费 |
| CDN 加速 | Vercel 全球节点 | 免费 |
| 监控（UptimeRobot） | 50 个监控点 | 免费 |
| 统计（Google Analytics） | 无限制 | 免费 |

**月总成本：约 ¥5.5**（域名 ¥65/年，其余全免费）

收益预估：哪怕每天只赚 ¥3.5（$0.50），一个月就是 ¥105，**投资回报率 20 倍**。

## 脚本速查表

| 脚本 | 用途 |
|------|------|
| `launch-site.sh <fork\|hugo> ...` | **一键启动：创建 + 部署 + DNS + 验证** |
| `setup.sh` | 首次配置，验证所有凭证 |
| `new-site.sh <名字> <标题> <描述>` | 创建 Hugo 内容站 |
| `fork-site.sh <链接> <名字> [标题]` | Fork 改造 GitHub 项目 |
| `check-repo.sh <链接>` | 检查 GitHub 项目兼容性 |
| `deploy.sh <名字> [--preview] [--verify] [--root]` | 部署单个站点到 Vercel |
| `deploy-all.sh` | 部署所有站点 |
| `build-all.sh` | 构建所有 Hugo 站点 |
| `dns-setup.sh <名字> [--verify] [--root]` | 通过 NameSilo API 添加 DNS 记录 |
| `swap-root.sh <名字> [--verify]` | 切换主域名绑定的站点 |
| `generate-content.sh <名字> <主题>` | AI 生成 SEO 文章 |
| `generate-content-plan.sh <名字>` | AI 生成内容计划 |
| `generate-seed-content.sh <名字>` | AI 生成种子文章 |
| `update-sites.sh [名字]` | 重新注入 Fork 站的广告/SEO/合规页面 |
| `generate-dashboard.sh` | 生成监控面板 |
| `lighthouse-check.sh <名字\|--all>` | 运行 Lighthouse 性能审计 |

## 监控面板

自动生成的单页 HTML 文件，展示所有站点的状态和运行情况。

```bash
# 生成/更新面板
./scripts/generate-dashboard.sh

# 打开查看
open dashboard/index.html
```

## 文档

| 文档 | 说明 |
|------|------|
| [配置指南](docs/zh/setup-guide.md) | 手把手首次配置教程 |
| [添加新站点](docs/zh/adding-new-site.md) | Hugo 和 Fork 两种建站方式 |
| [Fork 指南](docs/zh/fork-guide.md) | 怎么找项目、评估、改造 |
| [内容策略](docs/zh/content-strategy.md) | AdSense 审批技巧和 SEO 策略 |
| [贡献站点](docs/zh/contributing-sites.md) | 如何向项目提交新的工具站点 |
| [部署自动化](docs/zh/deployment-automation.md) | 一键部署、GitHub Actions |
| [主域名管理](docs/zh/root-domain.md) | AdSense 验证、主域名切换 |
| [自动内容生成](docs/zh/automated-content.md) | AI 内容生成流水线、定时任务 |
| [站点清单](SITES.zh.md) | 所有已集成站点的来源和用途 |

## 技术栈

| 组件 | 技术 | 为什么选它 |
|------|------|-----------|
| 内容站 | Hugo | 最快的静态网站生成器（<1ms/页） |
| 工具站 | 纯 HTML/CSS/JS | 零构建，直接从 GitHub 抄 |
| 托管 | Vercel 免费版 | 免费、100GB 流量、自动 SSL |
| 域名 | NameSilo | ~$9/年，有 REST API 管理 DNS |
| 自动化 | GitHub Actions | 自动部署、健康检查、内容生成 |
| AI 内容 | Claude / OpenAI / Gemini / DeepSeek | SEO 优化的文章自动生成 |
| 监控 | UptimeRobot | 免费 50 个监控点 |
| 广告 | Google AdSense | 一个标签自动放置广告 |

## 常见问题

### 完全不懂编程能用吗？

能。你只需要会：
1. 打开终端（Terminal）
2. 复制粘贴命令
3. 编辑一个配置文件（填入你的账号信息）

### 需要花多少钱？

域名约 ¥65/年（~$9），其他全免费。月成本约 ¥5.5。

### 多久能开始赚钱？

1. **第 1-2 小时**：搭建环境 + 创建 Hugo 站点 + AI 生成内容 + 部署上线 + 提交 Google（配了 AI API Key 的话，建站时自动生成种子内容）
2. **当天或第二天**：补充文章到 15 篇以上，申请 AdSense
3. **接下来 2-4 周**：等待 AdSense 审核，期间继续添加站点和内容
4. **审核通过后**：立即开始有广告收入

> **唯一的等待是 AdSense 审核。** 搭建环境到提交 AdSense 申请可以在 1-2 小时内完成。推荐第五步就配好 AI API Key，建站时自动生成内容，省去手动写文章的时间。

### AdSense 审核通不过怎么办？

常见原因和解决方法见 [内容策略](docs/zh/content-strategy.md)。核心要求：每站至少 15 页原创内容，每页 300+ 字，有隐私政策页面。

## 许可证

MIT
