[English](../contributing-sites.md) | **中文**

# 贡献站点到 SiteFactory

想要添加一个实用的工具站点到 SiteFactory？本指南说明具体流程。

## 流程概览

```
找到项目 → check-repo.sh → fork-site.sh → 验证 → 提 PR
```

**目标**：从找到项目到提交 PR，< 10 分钟。

## 准入要求

站点被接受前必须满足：

| 要求 | 详情 |
|------|------|
| 许可证 | 仅限 MIT、Apache 2.0 或 BSD |
| 类型 | 纯前端（HTML + CSS + JS） |
| 无后端 | 无 server.js、无数据库、无登录认证 |
| 离线可用 | 在浏览器打开 `index.html` 即可正常使用 |
| check-repo.sh 评分 | 70+（COMPATIBLE） |

## 操作步骤

### 1. 找到项目

搜索策略和高价值分类详见 [Fork 指南](fork-guide.md)。

**推荐贡献的分类：**

| 分类 | 示例 | SEO 价值 |
|------|------|----------|
| 计算器 | BMI、贷款、房贷、小费 | 高 — 精准搜索意图 |
| 转换器 | 单位、货币、时区 | 高 — 回访率高 |
| 生成器 | 密码、QR 码、UUID | 高 — 关键词强 |
| 文本工具 | 字数统计、Markdown 预览 | 中 — 开发者受众 |
| 参考手册 | 元素周期表、ASCII 表 | 中 — 长停留时间 |

### 2. 评估

```bash
./scripts/check-repo.sh <github-url>
```

只有结果为 **COMPATIBLE**（评分 70+）才可继续。

### 3. Fork 并适配

```bash
./scripts/fork-site.sh <github-url> <site-name> "<标题>" "<描述>"
```

**命名规则：**
- `site-name` 必须是小写字母加连字符：`bmi-calculator`、`color-picker`
- `标题` 应包含主要关键词，有利于 SEO
- `描述` 建议 150-160 个字符，包含行动号召

### 4. 本地验证

在浏览器中打开站点：

```bash
open sites/<site-name>/index.html
```

**检查清单：**

- [ ] 页面加载正常，功能可用
- [ ] 无样式缺失或资源 404（检查浏览器控制台）
- [ ] `<head>` 中存在 AdSense 脚本（查看源码，搜索 "adsbygoogle"）
- [ ] `<head>` 中存在 Analytics 脚本（搜索 "googletagmanager"）
- [ ] 页面底部可见隐私政策链接
- [ ] `site.yaml` 存在且元数据正确
- [ ] `ads.txt` 存在
- [ ] `privacy-policy.html` 和 `about.html` 存在
- [ ] 移动端布局正常（将浏览器缩到 375px 宽度测试）

### 5. Fork 后定制

脚本无法自动完成的事项：

- **更新 `<title>`** — 包含主要关键词，利于 SEO
- **移除原项目链接** — CNAME 文件、原始域名引用
- **修正 canonical URL** — 应指向实际部署域名
- **测试所有功能** — 确保按钮、输入、输出都正常

如果脚本注入不完美（如非标准 HTML 结构），可以手动编辑 HTML 或使用 code agent 修复。

### 6. 更新站点清单

在项目根目录的 [SITES.md](../SITES.md) 中添加你的站点：

```markdown
| my-tool | static | [user/repo](https://github.com/user/repo) | MIT | 简要描述 |
```

这是**必须的** — 不更新 SITES.md 的 PR 会被拒绝。

### 7. 提交 PR

**一个站点一个 PR。** 包含完整的 `sites/<site-name>/` 目录和 SITES.md 更新。

PR 标题格式：
```
feat(sites): add <site-name> - <简要描述>
```

示例：
```
feat(sites): add bmi-calculator - BMI calculator forked from user/repo
```

PR 正文应包含：
- 源 GitHub URL
- 许可证类型
- check-repo.sh 评分
- 站点截图（可选但推荐）

## 不接受的项目类型

| 类型 | 原因 |
|------|------|
| GPL/AGPL 项目 | 许可证不允许商用 |
| 需要 API Key 的项目 | 维护成本高，随时可能失效 |
| SPA 框架（React、Vue、Angular） | 需要构建步骤，注入不生效 |
| 有登录/认证的项目 | 需要后端服务器 |
| 重复分类 | 已有 2 个 BMI 计算器就不要再提第 3 个 |
| 废弃项目 | 最后一次提交超过 2 年，可能有问题 |

## site.yaml 参考

每个 fork 站点会自动生成 `site.yaml`：

```yaml
type: static          # fork 站点固定为 "static"
name: bmi-calculator  # 目录名，kebab-case
title: "BMI Calculator"
description: "Calculate your BMI instantly"
source: https://github.com/user/repo   # 原始仓库 URL
license: MIT          # MIT、Apache-2.0 或 BSD
language: en          # 主要语言
created: 2026-02-19   # Fork 日期
```

## 常见问题

### 脚本注入失败

如果 `fork-site.sh` 报错或注入代码没有出现：

1. 检查 HTML 文件是否有标准的 `</head>` 和 `</body>` 标签
2. 纯 JS 渲染的单页应用无法使用注入方式
3. 可以手动从 `sites/_shared/` 复制 AdSense/Analytics 代码片段

### Submodule 依赖缺失

如果 fork 的项目使用 git submodules 且资源缺失：

fork 脚本使用 `--recurse-submodules` 来克隆子模块依赖。如果文件仍然缺失，检查项目是否需要构建步骤来编译资源（如 SCSS 转 CSS）。这类项目可能需要手动处理。

### 站点显示异常

检查浏览器控制台（F12）的错误：
- 404 错误 = 文件缺失，检查文件路径
- CORS 错误 = 站点调用了阻止跨域请求的外部 API
- JS 错误 = 可能缺少依赖或需要构建步骤
