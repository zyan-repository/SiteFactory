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
git clone https://github.com/yourname/SiteFactory.git
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

需要填写的内容：

| 配置项 | 去哪里获取 | 怎么操作 | 值长什么样 |
|--------|-----------|---------|-----------|
| `domain.name` | [NameSilo](https://www.namesilo.com/) | 搜索域名 → 加购物车 → 付款（约 $9/年） | `mysite.com`（不带 https://） |
| `domain.namesilo_api_key` | [API 管理页](https://www.namesilo.com/account/api-manager) | 点击 **"Generate"** → 复制出现的字符串 | 约 20-30 个字母数字，如 `a1b2c3...` |
| `vercel.token` | [令牌页](https://vercel.com/account/tokens) | 点击 **"Create"** → 范围选 "Full Account" → **立即复制**（只显示一次！） | 约 24+ 个字符，如 `pZGwk...` |
| `adsense.publisher_id` | [AdSense](https://adsense.google.com/) | 登录后看**地址栏** URL 里的 `pub-数字`，前面加 `ca-`；或者：设置 → 账号信息 | `ca-pub-5531531271065052` |
| `analytics.google_analytics_id` | [Analytics](https://analytics.google.com/) | **新账号：** 点击"开始衡量" → 创建账号和媒体资源 → 创建数据流 → 获取衡量 ID；**已有账号：** 左下角齿轮 → 数据流 → 右上角**衡量 ID** | `G-A1B2C3D4E5` |

> 每一步的详细图文教程见 [配置指南](docs/zh/setup-guide.md)，保证不用查任何资料就能跟着做。

可选配置（不填也能用）：

| 配置项 | 用途 |
|--------|------|
| `claude.api_key` | AI 自动生成文章（需要 Claude API） |
| `monitoring.uptimerobot_api_key` | 监控站点是否在线 |

> **中国大陆用户注意**：Google 系列服务（AdSense、Analytics、Search Console）可能需要特殊网络环境才能访问。

### 第六步：验证配置

填完后再次运行：

```bash
./scripts/setup.sh
```

全部显示绿色对勾 ✓ 就说明配置成功了。

### 第七步：创建你的第一个站点

**方法 A：从 GitHub 抄一个工具站**

```bash
# 先检查这个项目能不能用
./scripts/check-repo.sh https://github.com/evgeni/qifi

# 通过检查后，一键 fork 改造
./scripts/fork-site.sh https://github.com/evgeni/qifi wifi-qr "WiFi 二维码生成器"

# 部署上线
./scripts/deploy.sh wifi-qr
```

**方法 B：创建一个 Hugo 内容站（博客）**

```bash
# 从模板创建
./scripts/new-site.sh my-blog "我的博客" "分享技术心得"

# 部署上线
./scripts/deploy.sh my-blog
```

### 第八步：设置域名

```bash
./scripts/dns-setup.sh my-tool
```

这会自动添加 DNS 记录：`my-tool.你的域名.com` → Vercel 服务器。

> DNS 生效需要最多 48 小时，耐心等待。生效后访问 `https://my-tool.你的域名.com` 就能看到你的站点了。

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
├── sites/
│   ├── _template/           # Hugo 站点模板
│   ├── _shared/             # Fork 站共用文件（隐私政策、关于页面）
│   ├── my-blog/             # Hugo 内容站（type: hugo）
│   └── my-tool/             # Fork 的工具站（type: static）
├── scripts/                 # 自动化脚本（建站、部署、监控）
├── n8n/                     # n8n 自动化工作流
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
| `setup.sh` | 首次配置，验证所有凭证 |
| `new-site.sh <名字> <标题> <描述>` | 创建 Hugo 内容站 |
| `fork-site.sh <链接> <名字> [标题]` | Fork 改造 GitHub 项目 |
| `check-repo.sh <链接>` | 检查 GitHub 项目兼容性 |
| `deploy.sh <名字>` | 部署单个站点到 Vercel |
| `deploy-all.sh` | 部署所有站点 |
| `build-all.sh` | 构建所有 Hugo 站点 |
| `dns-setup.sh <名字>` | 通过 NameSilo API 添加 DNS 记录 |
| `generate-dashboard.sh` | 生成监控面板 |
| `lighthouse-check.sh <名字\|--all>` | 运行 Lighthouse 性能审计 |

## n8n 自动化工作流

把 `n8n/workflows/` 里的 JSON 文件导入你的 n8n 实例：

| 工作流 | 触发方式 | 功能 |
|--------|---------|------|
| `new-site-pipeline` | Webhook | 自动创建并部署新站点 |
| `content-generation` | 定时（每天） | AI 自动生成 SEO 优化文章 |
| `monitoring-report` | 定时（每6小时） | 更新监控面板 |
| `site-health-check` | 定时（每天） | 检查所有站点的 DNS、SSL、可访问性 |

详见 [n8n/README.md](n8n/README.md)。

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
| [站点清单](SITES.zh.md) | 所有已集成站点的来源和用途 |

## 技术栈

| 组件 | 技术 | 为什么选它 |
|------|------|-----------|
| 内容站 | Hugo | 最快的静态网站生成器（<1ms/页） |
| 工具站 | 纯 HTML/CSS/JS | 零构建，直接从 GitHub 抄 |
| 托管 | Vercel 免费版 | 免费、100GB 流量、自动 SSL |
| 域名 | NameSilo | ~$9/年，有 REST API 管理 DNS |
| 自动化 | n8n（自托管） | 可视化工作流，400+ 集成 |
| AI 内容 | Claude API（通过 n8n） | SEO 优化的文章自动生成 |
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

1. 第 1 周：搭建环境，创建前 3 个站点
2. 第 2 周：添加内容（每站至少 15 页）
3. 第 3 周：提交 Google 收录
4. 第 4 周：申请 AdSense
5. 第 5-6 周：等待 AdSense 审核
6. 第 7 周起：开始有广告收入，持续添加站点

### AdSense 审核通不过怎么办？

常见原因和解决方法见 [内容策略](docs/zh/content-strategy.md)。核心要求：每站至少 15 页原创内容，每页 300+ 字，有隐私政策页面。

## 许可证

MIT
