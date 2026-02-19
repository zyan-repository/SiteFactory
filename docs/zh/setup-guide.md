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
| Claude API（可选） | [console.anthropic.com](https://console.anthropic.com/) | 按量付费 | 用于 AI 自动生成文章 |

> 如果你还没有 GitHub 账号，先去 [github.com](https://github.com/) 注册一个（免费的），后面的 Vercel 需要用 GitHub 登录。

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

文件内容大概长这样，把 `YOUR_xxx` 替换成你自己的值：

```yaml
domain:
  name: "mysite.com"                    # ← 改成你在 NameSilo 买的域名
  namesilo_api_key: "abc123def456"      # ← 改成你的 NameSilo API Key

vercel:
  token: "your-vercel-token"            # ← 改成你的 Vercel Token

adsense:
  publisher_id: "ca-pub-1234567890"     # ← 改成你的 AdSense 发布者 ID
  enabled: true

analytics:
  google_analytics_id: "G-XXXXXXXXXX"   # ← 改成你的 Analytics 衡量 ID
```

> 保存文件：如果用 `nano` 编辑，按 `Ctrl + O` 保存，`Ctrl + X` 退出。

## 第五步：验证配置

```bash
./scripts/setup.sh
```

重新运行后，会逐项检查你的凭证是否正确。全部绿色 ✓ 就OK了。

如果有红色 ✗：
- 检查对应的值有没有打错（特别是开头结尾不要有多余的空格）
- 确认 API Key / Token 没有过期
- 参考下面的"常见问题"

## 第六步：创建第一个站点

### 方式 A：从 GitHub Fork 一个工具站

```bash
# 先检查项目兼容性
./scripts/check-repo.sh https://github.com/user/cool-tool

# 如果显示 COMPATIBLE，就可以 fork
./scripts/fork-site.sh https://github.com/user/cool-tool cool-tool "好用的工具"
```

在浏览器里预览：

```bash
open sites/cool-tool/index.html
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
./scripts/deploy.sh cool-tool

# 添加 DNS 记录（让域名指向你的站点）
./scripts/dns-setup.sh cool-tool
```

完成后你的站点会在 `https://cool-tool.mysite.com` 上线（DNS 生效需要几小时到 48 小时）。

## 第八步：申请 AdSense（等站点运行 1-2 周后）

1. 先给站点添加足够的内容（至少 15 页，每页 300+ 字）
2. 确保隐私政策和关于页面存在（模板已自动包含）
3. 等 Google 收录你的站点（通常 1-2 周）
4. 去 [adsense.google.com](https://adsense.google.com/) 申请
5. 审核通过后广告自动展示

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
2. 删掉旧的，重新创建一个新的
3. 选择 "Full Account" 权限范围
4. 更新 `config.yaml`

### NameSilo API Key 不工作

1. 确认域名在你的 NameSilo 账户下
2. 去 [API 管理页](https://www.namesilo.com/account/api-manager) 检查 Key 是否有效
3. 确保 Key 有 DNS 管理权限

### Hugo 构建失败

```bash
# 查看详细错误
hugo -s sites/my-blog --verbose

# 清理缓存后重试
rm -rf sites/my-blog/resources
hugo -s sites/my-blog --gc --minify
```

### config.yaml 格式错误

YAML 格式对空格很敏感：
- 使用空格缩进，不要用 Tab
- 冒号后面必须有一个空格
- 值如果有特殊字符要用引号包裹

```yaml
# ✅ 正确
domain:
  name: "mysite.com"

# ❌ 错误（冒号后没有空格）
domain:
  name:"mysite.com"
```

## 下一步

- 创建更多站点 → [添加新站点](adding-new-site.md)
- 找适合 Fork 的项目 → [Fork 指南](fork-guide.md)
- 通过 AdSense 审核 → [内容策略](content-strategy.md)
- 设置自动化 → [n8n 使用说明](../../n8n/README.md)
