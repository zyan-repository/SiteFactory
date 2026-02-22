[English](../automated-content.md) | **中文**

# 自动内容生成管道

SiteFactory 如何为 Hugo 站点自动生成和发布 SEO 优化的内容。

## 概述

自动内容管道由三个层次组成：

1. **内容计划** — AI 根据站点主题生成 25 个文章话题
2. **智能初始化** — 新站上线时自带 5 篇种子文章 + 首页内容
3. **定时生成** — GitHub Actions 定时任务按配置频率自动生成文章

内容计划存储在 `content-plans/`（不在 `sites/` 下），保持站点目录干净，将 AI 依赖功能与核心站点结构分离。

## 架构

```
SiteFactory/
├── config.yaml                    # 全局默认值（content.default_schedule 等）
├── content-plans/                 # AI 内容计划（独立于 sites/）
│   ├── home-coffee-brewing.yaml   # 每站一个：主题列表、频率、最后生成时间
│   └── tech-tips.yaml
├── sites/
│   └── home-coffee-brewing/       # 纯净的站点文件
│       ├── site.yaml              # 核心元数据（无 AI 相关字段）
│       ├── hugo.toml
│       └── content/posts/         # 生成的文章放在这里
└── .github/workflows/
    └── scheduled-content.yml      # 每日定时任务，读取 content-plans/
```

## 工作流程

### 建站流程

创建新 Hugo 站点时：

```bash
./scripts/launch-site.sh hugo home-coffee-brewing \
  "Home Coffee Brewing Guide" \
  "Master the art of brewing perfect coffee at home"
```

如果 AI 已配置，以下步骤自动执行：

1. 复制并配置模板 → `sites/home-coffee-brewing/`
2. `generate-content-plan.sh` → 创建 `content-plans/home-coffee-brewing.yaml`（25 个主题）
3. `generate-seed-content.sh` → 生成首页介绍、关于页面和 5 篇文章
4. Hugo 构建验证
5. 部署到 Vercel

未配置 AI 时，站点仍可正常创建——只是没有自动生成的内容。

### 内容计划文件（`content-plans/{site}.yaml`）

```yaml
site: home-coffee-brewing
niche: "home coffee brewing guide"
publishing_schedule: "weekly"
last_generated: "2026-02-19"
target_keywords:
  - "home coffee brewing"
  - "pour over coffee"
topics:
  - title: "Best Pour-Over Technique for Beginners"
    keywords: "pour over coffee, pour over technique"
    status: published
  - title: "French Press vs AeroPress: Complete Comparison"
    keywords: "french press vs aeropress"
    status: pending
```

主题状态流转：`pending` → `in_progress` → `published`

### 定时生成

`scheduled-content.yml` GitHub Actions 工作流每天 UTC 09:00 执行：

1. 扫描 `content-plans/*.yaml` 中的待处理主题
2. 检查 `publishing_schedule` 与 `last_generated` 判断是否到期
3. 为每个符合条件的站点生成一篇文章
4. 提交并推送（触发 `deploy.yml` 自动部署）

## 配置

### 三级优先级（从高到低）

| 级别 | 位置 | 示例 |
|------|------|------|
| **单站覆盖** | `content-plans/{site}.yaml` → `publishing_schedule` | `"daily"` |
| **GitHub Secret** | `SF_CONTENT_SCHEDULE` | `"2x-week"` |
| **全局默认** | `config.yaml` → `content.default_schedule` | `"weekly"` |

### config.yaml（全局默认值）

```yaml
content:
  default_schedule: "weekly"       # daily | 2x-week | weekly | biweekly
  default_topic_count: 25          # 每个内容计划的主题数
  default_seed_articles: 5         # 建站时生成的种子文章数
```

### GitHub Secrets（CI 使用）

| Secret | 必需 | 说明 |
|--------|------|------|
| `SF_AI_API_KEY` | 是 | AI 提供商 API 密钥 |
| `SF_AI_PROVIDER` | 否 | 提供商名称（默认：claude） |
| `SF_CONTENT_SCHEDULE` | 否 | CI 中的全局频率覆盖 |
| `SF_DOMAIN` | 是 | 基础域名 |
| `SF_ADSENSE_PUB_ID` | 否 | AdSense 发布商 ID |
| `SF_GA_ID` | 否 | Google Analytics ID |

### AI 提供商

```yaml
ai:
  provider: "claude"  # 或 openai, deepseek, gemini, moonshot, zhipu
  providers:
    claude:
      api_key: "sk-ant-..."
      model: "claude-sonnet-4-6"
```

## 脚本说明

| 脚本 | 用途 |
|------|------|
| `generate-content-plan.sh` | 生成/刷新内容计划 → `content-plans/{site}.yaml` |
| `generate-seed-content.sh` | 生成首页、关于页面和种子文章 |
| `generate-content.sh` | 生成单篇文章（手动或计划模式） |

### generate-content-plan.sh

```bash
./scripts/generate-content-plan.sh <站点名> [主题数量] [发布频率]

# 示例：
./scripts/generate-content-plan.sh home-coffee-brewing          # 使用 config.yaml 默认值
./scripts/generate-content-plan.sh home-coffee-brewing 30 daily  # 覆盖：30 个主题，每日更新
```

### generate-seed-content.sh

```bash
./scripts/generate-seed-content.sh <站点名> [文章数量]

# 示例：
./scripts/generate-seed-content.sh home-coffee-brewing     # 使用 config.yaml 默认值（5）
./scripts/generate-seed-content.sh home-coffee-brewing 3   # 覆盖：3 篇文章
```

### generate-content.sh（增强版）

```bash
# 手动模式（原有功能）：
./scripts/generate-content.sh home-coffee-brewing "Best Espresso Machines" "espresso,budget"

# 计划模式（新增）：自动从 content-plans/ 取下一个待处理主题
./scripts/generate-content.sh home-coffee-brewing
```

## 发布频率选项

| 频率 | 说明 | AI 成本（5 个站） |
|------|------|-------------------|
| `daily` | 每天 | ~$9/月 |
| `2x-week` | 每 3 天 | ~$6/月 |
| `weekly` | 每 7 天（默认） | ~$1.7/月 |
| `biweekly` | 每 14 天 | ~$0.9/月 |

## 手动触发工作流

从 GitHub Actions 界面：

- **Scheduled Content Generation** → Run workflow
  - `site_name`：指定站点（留空 = 所有符合条件的站点）
  - `force`：忽略发布频率限制，立即生成

## 刷新内容计划

当所有主题都已发布时：

```bash
./scripts/generate-content-plan.sh home-coffee-brewing 25
```

这将生成 25 个新主题。已发布的文章不受影响。
