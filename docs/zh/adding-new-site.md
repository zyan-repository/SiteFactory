[English](../adding-new-site.md) | **中文**

# 添加新站点

## 一键启动（推荐）

从想法到上线最快的方式，一条命令全搞定：

```bash
# Fork 一个工具站（一条命令完成所有步骤）
./scripts/launch-site.sh fork https://github.com/user/repo my-tool "我的工具"

# 创建 Hugo 内容站（一条命令完成所有步骤）
./scripts/launch-site.sh hugo my-blog "我的博客" "分享技术心得"
```

这一条命令会自动完成：创建站点 → 生成 OG 图片 → 部署到 Vercel → 配置 DNS → 验证 DNS 传播 → 检查站点存活 → 运行 Lighthouse 审计。Hugo 站点还会自动生成内容计划和种子文章。详见 [部署自动化](deployment-automation.md)。

如果你想分步操作，请继续往下看。

---

SiteFactory 支持两种站点，根据你的目标选择：

| 目标 | 类型 | 命令 | 需要构建？ |
|------|------|------|-----------|
| 博客/文章/SEO 内容 | Hugo | `new-site.sh` | 是 |
| 工具/小应用/Fork 项目 | Static | `fork-site.sh` | 否 |

## 方式 A：Hugo 内容站

### 创建

```bash
./scripts/new-site.sh <站点名> "<标题>" "<描述>" [语言]
```

例子：

```bash
./scripts/new-site.sh cooking-tips "美食小贴士" "简单好做的家常菜谱" zh
```

脚本会自动完成：
1. 复制 `sites/_template/` 脚手架（hugo.toml + 内容结构）到 `sites/cooking-tips/`
2. 替换 `hugo.toml` 中的标题、描述、域名、AdSense ID、Analytics ID
3. 生成品牌 OG 图片（`og-default.png`）用于社交分享
4. 创建 `site.yaml`（标记为 `type: hugo`）
5. 注册到 `themes/sitefactory/data/sites.yaml` 实现跨站导航
6. 验证站点能成功构建

> **注意：** Hugo 站点的布局、CSS 和 i18n 字符串全部继承自共享主题 `themes/sitefactory/`。你不需要复制模板或样式表——它们会自动传播。

### 本地预览

```bash
hugo server -s sites/cooking-tips
# 打开浏览器访问 http://localhost:1313
```

### 添加文章

用 Hugo 命令创建新文章：

```bash
hugo new -s sites/cooking-tips posts/first-recipe.md
```

或者直接在 `sites/cooking-tips/content/posts/` 目录下创建文件：

```markdown
---
title: "10 道新手也能做的意大利面"
date: 2026-02-19
description: "简单的意大利面食谱，30 分钟内搞定。"
tags: ["意大利面", "新手", "快手菜"]
---

你的内容写在这里。为了 SEO 效果好，建议每篇 800+ 字。
```

### 内容要求（通过 AdSense 审核必须达到）

- 最少 15 个不同页面/文章
- 每篇至少 300 字（推荐 800+）
- 必须是原创内容（不能从别的网站复制）
- 有隐私政策页面（模板已包含）
- 有关于页面（模板已包含）
- 有联系方式页面（模板已包含）

### 部署

```bash
./scripts/deploy.sh cooking-tips
```

## 方式 B：Fork 工具站

### 1. 找项目

在 GitHub 上搜索有用的小工具：

```
site:github.com calculator html css
site:github.com converter tool html
site:github.com weather app html css javascript
```

适合 Fork 的类型：计算器、转换器、生成器、查询工具、参考页面。

详细搜索技巧见 [Fork 指南](fork-guide.md)。

### 2. 检查兼容性

```bash
./scripts/check-repo.sh https://github.com/evgeni/qifi
```

脚本会检查：
- 许可证（必须是 MIT / Apache / BSD）
- 有没有后端代码
- 有没有数据库依赖
- package.json 里有没有服务端框架
- 有没有 index.html

**看懂结果：**
- 分数 70+ 且没有红色标记 → **COMPATIBLE（兼容）** → 直接 Fork
- 分数 40-69 或有 1 个黄色警告 → **NEEDS REVIEW（需人工检查）** → 看 [Fork 指南](fork-guide.md) 里的手动检查清单
- 分数 <40 或有红色标记 → **INCOMPATIBLE（不兼容）** → 放弃这个项目

**什么是"红色标记"（严重问题）？**
- 许可证是 GPL、AGPL 或找不到 —— 不能商用
- 检测到后端文件（server.js、app.py）—— 需要服务器才能跑
- 发现数据库依赖 —— 需要数据库，我们提供不了

### 3. Fork 改造

```bash
./scripts/fork-site.sh https://github.com/evgeni/qifi wifi-qr "WiFi 二维码生成器" "生成二维码分享你的 WiFi 密码"
```

脚本自动完成：
1. 运行兼容性检查（不通过则终止）
2. 克隆仓库到 `sites/wifi-qr/`
3. 删除 `.git` 目录
4. 在所有 HTML 文件中注入 AdSense 广告代码、Google Analytics 和 SEO meta 标签
5. 复制隐私政策和关于页面（语言感知，包含主域名回链）
6. 生成品牌 OG 图片（`og-default.png`）
7. 创建 `ads.txt`
8. 创建 `site.yaml`（标记为 `type: static`）
9. 在 README 中添加原项目致谢
10. 注册到 `themes/sitefactory/data/sites.yaml` 实现跨站导航

### 4. 检查和自定义

**预览效果：**
```bash
open sites/wifi-qr/index.html
```

**确认广告代码注入成功：**
```bash
grep "adsbygoogle" sites/wifi-qr/index.html
# 如果输出了包含 "adsbygoogle" 的一行，说明注入成功
# 如果没有输出，重新运行 fork-site.sh 或检查错误日志
```

**修改标题**（在 `sites/wifi-qr/index.html` 里）：
1. 用任意文本编辑器打开这个文件（VS Code、nano、记事本等）
2. 搜索 `<title>` 标签（在文件靠前的 `<head>` 区域里）
3. 把 `<title>` 和 `</title>` 之间的文字改成你想要的标题
4. 同时找到 `<meta property="og:title"`，把 `content` 的值也改成一样的

**修改描述**（同一个文件）：
1. 找到 `<meta name="description" content="...">`
2. 把 `content` 里的文字改成你的描述（建议 150-160 字符）
3. 同时更新 `<meta property="og:description" content="...">` 保持一致

**在导航栏添加隐私政策链接**（可选但推荐）：
- fork 脚本已经在站点目录下添加了 `privacy-policy.html` 和 `about.html`
- 在 `index.html` 里找到导航区域（通常是 `<nav>` 标签或包含链接的 `<ul>`）
- 加上链接：`<a href="privacy-policy.html">隐私政策</a>` 和 `<a href="about.html">关于</a>`

### 5. 部署

```bash
./scripts/deploy.sh wifi-qr
```

## 部署后要做的事

### 设置 DNS

```bash
./scripts/dns-setup.sh <站点名>
```

这会创建一条 CNAME 记录，把 `<站点名>.你的域名.com` 指向 `cname.vercel-dns.com`。

**怎么看 DNS 是不是生效了：**
1. 打开 [https://dnschecker.org/](https://dnschecker.org/)
2. 输入 `<站点名>.你的域名.com`，记录类型选 "CNAME"，点搜索
3. 如果结果显示 `cname.vercel-dns.com` → DNS 已生效
4. 如果什么都没有 → 再等几个小时重新检查（DNS 最多需要 48 小时）

### 提交到 Google Search Console

1. 打开 [Google Search Console](https://search.google.com/search-console)
2. 点击左上角下拉菜单 → **"添加资源"**
3. 选择右边的 **"网址前缀"**
4. 输入你的站点地址：`https://<站点名>.你的域名.com`
5. 点击 **"继续"**
6. 验证方式选 **"DNS 记录"**：
   - Google 会显示一个 TXT 记录值（一长串以 `google-site-verification=` 开头的字符）
   - 登录 [NameSilo 域名管理](https://www.namesilo.com/account/domain-manager) → 点击你的域名 → DNS 记录
   - 添加一条 TXT 记录：Host 留空（或填 `@`），Value 粘贴 Google 给的那串字符，TTL 填 `3600`
   - 回到 Search Console 点击 **"验证"**
   - 如果显示失败，等 15-30 分钟让 DNS 生效，再试一次
7. 验证成功后，点击左侧 **"站点地图"**
8. 输入站点地图地址：`https://<站点名>.你的域名.com/sitemap.xml`
9. 点击 **"提交"**
10. Google 会在几天内开始抓取你的站点。你可以在左侧 **"网页"** 里查看收录进度。

### 添加监控

如果你配置了 UptimeRobot，下次运行以下命令时监控面板会自动检测到新站点：

```bash
./scripts/generate-dashboard.sh
```

### 检查性能

```bash
./scripts/lighthouse-check.sh <站点名>
```

目标分数：Performance 90+、SEO 95+、Accessibility 85+、Best Practices 90+。

**这些分数代表什么：**
- **Performance（90+）：** 页面加载速度。低于 90 通常是图片太大或 JavaScript 太多。解决：压缩图片、删掉没用的脚本。
- **SEO（95+）：** 搜索引擎能不能正确读取你的网站。低于 95 通常是缺少 meta 标签或标题结构有问题。解决：确保每个页面都有 `<title>`、`<meta description>` 和一个 `<h1>`。
- **Accessibility（85+）：** 网站对残障人士的友好程度（屏幕阅读器等）。低于 85 通常是图片缺少 alt 文字或颜色对比度不够。解决：给所有 `<img>` 标签加上 `alt` 属性。
- **Best Practices（90+）：** Web 开发的通用质量标准。低于 90 通常是用了过时的 API 或有安全隐患。解决：查看 Lighthouse 输出里的具体警告。

如果任何分数低于目标，Lighthouse 输出会列出具体问题和修复建议。

## 管理站点

### 查看所有站点

```bash
ls sites/ | grep -v _template | grep -v _shared
```

### 删除站点

```bash
# 删除本地文件
rm -rf sites/<站点名>

# 如果已经部署了，也从 Vercel 删除：
npx vercel rm <站点名> --token YOUR_TOKEN --yes
```

> **注意：** 从 Vercel 删除后，站点就不能在线访问了。DNS 记录还会留着但指向空——你可以不管它，或者去 NameSilo 手动删掉。

### 更新站点内容

Hugo 站 —— 编辑内容后重新部署：

```bash
# 编辑
nano sites/my-blog/content/posts/new-post.md

# 重新部署
./scripts/deploy.sh my-blog
```

Fork 站 —— 直接修改文件后重新部署：

```bash
nano sites/wifi-qr/index.html
./scripts/deploy.sh wifi-qr
```
