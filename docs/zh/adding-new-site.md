[English](../adding-new-site.md) | **中文**

# 添加新站点

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
1. 复制 `sites/_template/` 到 `sites/cooking-tips/`
2. 替换标题、描述、域名、AdSense ID、Analytics ID
3. 创建 `site.yaml`（标记为 `type: hugo`）
4. 验证站点能成功构建

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
./scripts/check-repo.sh https://github.com/user/cool-tool
```

脚本会检查：
- 许可证（必须是 MIT / Apache / BSD）
- 有没有后端代码
- 有没有数据库依赖
- package.json 里有没有服务端框架
- 有没有 index.html

得分 70+ 且没有严重问题 = 可以 Fork。

### 3. Fork 改造

```bash
./scripts/fork-site.sh https://github.com/user/cool-tool cool-tool "好用的工具" "一个好用的在线工具"
```

脚本自动完成：
1. 运行兼容性检查（不通过则终止）
2. 克隆仓库到 `sites/cool-tool/`
3. 删除 `.git` 目录
4. 在所有 HTML 文件中注入 AdSense 广告代码
5. 注入 Google Analytics 统计代码
6. 添加 SEO meta 标签
7. 复制隐私政策和关于页面
8. 创建 `ads.txt`
9. 创建 `site.yaml`（标记为 `type: static`）
10. 在 README 中添加原项目致谢

### 4. 检查和自定义

```bash
# 预览
open sites/cool-tool/index.html

# 检查广告代码是否注入成功
grep "adsbygoogle" sites/cool-tool/index.html
```

你可能还想：
- 修改标题和描述
- 在导航栏添加隐私政策链接
- 调整颜色或品牌
- 添加更多 SEO 标签

### 5. 部署

```bash
./scripts/deploy.sh cool-tool
```

## 部署后要做的事

### 设置 DNS

```bash
./scripts/dns-setup.sh <站点名>
```

### 提交到 Google

1. 打开 [Google Search Console](https://search.google.com/search-console)
2. 添加网站：`https://<站点名>.你的域名.com`
3. 验证所有权（DNS 验证最简单）
4. 提交 sitemap：`https://<站点名>.你的域名.com/sitemap.xml`

### 检查性能

```bash
./scripts/lighthouse-check.sh <站点名>
```

目标分数：Performance 90+、SEO 95+、Accessibility 85+、Best Practices 90+。

## 管理站点

### 查看所有站点

```bash
ls sites/ | grep -v _template | grep -v _shared
```

### 删除站点

```bash
rm -rf sites/<站点名>
```

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
nano sites/cool-tool/index.html
./scripts/deploy.sh cool-tool
```
