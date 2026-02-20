[English](../deployment-automation.md) | **中文**

# 部署自动化

SiteFactory 提供三种部署自动化方式，根据需求选择：

| 方式 | 适用场景 | 配置量 | 基础设施 |
|------|---------|--------|---------|
| **一键脚本** | 本地快速部署 | 无 | 本机 |
| **GitHub Actions** | 推送自动部署、定时任务 | 配置 Secrets | 免费（GitHub） |
| **n8n 工作流** | 可视化自动化、复杂流水线 | Docker | 自托管 |

## 方式一：一键脚本（推荐）

从想法到上线最快的方式，一条命令搞定全部：

### Fork 工具站

```bash
./scripts/launch-site.sh fork https://github.com/user/repo my-tool "我的工具" "一个有用的工具"
```

### 创建 Hugo 内容站

```bash
./scripts/launch-site.sh hugo my-blog "我的博客" "分享技术心得" zh
```

### 执行过程（6 个阶段）

| 阶段 | 操作 | 耗时 |
|------|------|------|
| 1/6 | 创建站点（Fork 或 Hugo 模板） | 5-30 秒 |
| 2/6 | 部署到 Vercel（生产环境） | 15-60 秒 |
| 3/6 | 通过 NameSilo API 配置 DNS | 2-5 秒 |
| 4/6 | 验证 DNS 传播（轮询） | 0-120 秒 |
| 5/6 | HTTP 健康检查（验证站点存活） | 0-60 秒 |
| 6/6 | Lighthouse 审计（可选） | 10-30 秒 |

### 选项

| 参数 | 效果 |
|------|------|
| `--skip-verify` | 跳过 4-6 阶段（DNS、HTTP、Lighthouse 检查） |

### 环境变量

| 变量 | 效果 |
|------|------|
| `SF_JSON_OUTPUT=true` | 输出机器可读的 JSON 摘要 |

### 示例输出

```
[INFO]  === SiteFactory Launch: wifi-qr (fork) ===

[STEP]  Phase 1/6: Creating site...
[OK]    Site created: sites/wifi-qr

[STEP]  Phase 2/6: Deploying to production...
[OK]    Deployed: https://wifi-qr-xxx.vercel.app

[STEP]  Phase 3/6: Setting up DNS...
[OK]    CNAME record created

[STEP]  Phase 4/6: Verifying DNS propagation...
[OK]    DNS verified: wifi-qr.search123.top

[STEP]  Phase 5/6: Verifying site is live...
[OK]    Site is live: https://wifi-qr.search123.top

[STEP]  Phase 6/6: Running Lighthouse audit...
[OK]    Lighthouse audit complete

[OK]    === Launch complete! (47s) ===

  +------------------------------------------+
  | Site:    wifi-qr
  | Type:    fork
  | URL:     https://wifi-qr.search123.top
  | DNS:     verified
  | HTTP:    live
  | Time:    47s
  +------------------------------------------+

  Next steps:
    1. Submit sitemap to Google Search Console
    2. Wait 1-2 weeks, then apply for AdSense
    3. Monitor: ./scripts/lighthouse-check.sh wifi-qr
```

## 单独脚本增强

### deploy.sh

```bash
# 标准部署
./scripts/deploy.sh my-site

# 预览部署（非生产）
./scripts/deploy.sh my-site --preview

# 部署后自动健康检查
./scripts/deploy.sh my-site --verify

# 参数顺序任意
./scripts/deploy.sh my-site --verify --preview
```

### dns-setup.sh

```bash
# 仅创建 CNAME 记录
./scripts/dns-setup.sh my-site

# 创建 CNAME 并轮询等待 DNS 生效
./scripts/dns-setup.sh my-site --verify
```

## 方式二：GitHub Actions

在 GitHub 基础设施上运行的自动化工作流（免费）。

### 配置：添加 GitHub Secrets

进入仓库 **Settings → Secrets and variables → Actions → New repository secret**，添加：

| Secret 名称 | 值 | 在哪里找 |
|-------------|-----|---------|
| `SF_DOMAIN` | 你的域名（如 `search123.top`） | `config.yaml` → `domain.name` |
| `SF_VERCEL_TOKEN` | Vercel API 令牌 | `config.yaml` → `vercel.token` |
| `SF_NAMESILO_API_KEY` | NameSilo API 密钥 | `config.yaml` → `domain.namesilo_api_key` |
| `SF_ADSENSE_PUB_ID` | AdSense 发布者 ID | `config.yaml` → `adsense.publisher_id` |
| `SF_GA_ID` | Google Analytics ID | `config.yaml` → `analytics.google_analytics_id` |
| `SF_AI_API_KEY` | 所选 AI 服务的 API 密钥 | `config.yaml` → `ai.providers.<provider>.api_key` |

> **注意：** `SF_AI_API_KEY` 是所有 AI 服务共用的。触发内容生成时可以选择 provider（claude、openai、deepseek、gemini、moonshot、zhipu），密钥需要与所选 provider 匹配。

### 可用工作流

#### 自动部署（`deploy.yml`）

**触发：** 推送到 main 分支的 `sites/` 目录，或手动触发。

- 自动检测哪些站点有变更
- 仅部署有变更的站点（多站点并行部署）
- 自动配置 DNS

**手动触发：** 进入 Actions → "Deploy Sites" → "Run workflow" → 输入站点名称。

#### 健康检查（`health-check.yml`）

**触发：** 每 6 小时（cron），或手动触发。

- 检查所有已部署站点的 HTTP 状态
- 在工作流摘要中生成健康报告
- 有站点宕机时发出警告

#### 内容生成（`content-generation.yml`）

**触发：** 仅手动触发。

进入 Actions → "Generate Content" → "Run workflow"，填写：
- **Site name：** 目标 Hugo 站点（必须已存在）
- **Topic：** 文章主题
- **Keywords：** SEO 关键词，逗号分隔（可选）
- **Word count：** 目标字数（默认 1200）
- **AI provider：** 选择 claude、openai、deepseek、gemini、moonshot、zhipu（默认 claude）
- **Model name：** 留空使用 provider 默认模型，或指定模型（如 `deepseek-chat`）

工作流自动生成文章、提交到 git、推送 —— 推送会自动触发部署工作流。

## 方式三：n8n 工作流（可选）

适合可视化工作流自动化，需要运行 n8n 实例。

### 快速配置

```bash
# 用 Docker 启动 n8n
docker run -d --name n8n \
  -p 5678:5678 \
  -v ~/.n8n:/home/node/.n8n \
  -v /path/to/SiteFactory:/data/SiteFactory \
  -e SF_PROJECT_ROOT=/data/SiteFactory \
  -e SF_DOMAIN=search123.top \
  n8nio/n8n
```

### 导入工作流

1. 打开 http://localhost:5678
2. 进入 Workflows → Import from file
3. 依次导入 `n8n/workflows/` 下的 JSON 文件：
   - `new-site-pipeline.json` — Webhook 触发：创建 + 部署站点
   - `content-generation.json` — Webhook 触发：AI 内容生成
   - `monitoring-report.json` — 定时：每日监控报告
   - `site-health-check.json` — 定时：每 6 小时健康检查
4. 激活每个工作流

详见 [n8n/README.md](../n8n/README.md)。

## 选择哪种方式

| 场景 | 推荐 |
|------|------|
| 建前几个站点 | 一键脚本 |
| 通过 git 推送定期更新内容 | GitHub Actions（自动部署） |
| 每日 AI 生成内容 | GitHub Actions（内容工作流） |
| 10+ 站点需要监控 | GitHub Actions（健康检查） |
| 复杂的多步骤自动化 | n8n |
| 需要可视化编辑工作流 | n8n |
