[English](../fork-guide.md) | **中文**

# Fork 指南：怎么找项目、评估、改造

核心理念：**能抄就不写** —— GitHub 上有成千上万现成的小工具，干嘛要自己写？

## 整体流程

```
搜索 GitHub → 评估兼容性 → 一键 Fork → 部署上线 → 赚钱
              (check-repo.sh)  (fork-site.sh)  (deploy.sh)
```

## 第一步：找项目

### GitHub 搜索技巧

**按工具类型搜索**：

```
# 在 GitHub 搜索框里输入
calculator html css language:HTML
converter tool html language:JavaScript
weather app html css
password generator html javascript
color picker tool html

# 按星标数筛选（星越多质量越好）
calculator html stars:>10
qr code generator html stars:>20

# 排除前端框架（我们要纯 HTML 的）
calculator html NOT react NOT vue NOT angular
```

**按分类浏览**：

- https://github.com/topics/calculator
- https://github.com/topics/converter
- https://github.com/topics/generator
- https://github.com/topics/tools

**用 Google 搜索**：

```
site:github.com "html" "css" calculator open source
site:github.com "MIT license" weather tool html
```

### 高价值分类

| 分类 | 示例 | 为什么值钱 |
|------|------|-----------|
| **计算器** | BMI、贷款、房贷、小费、年龄 | 用户搜索精确 → 广告点击率高 |
| **转换器** | 单位、汇率、时区、温度 | 回头客多，日常使用 |
| **生成器** | 密码、二维码、UUID、调色板 | SEO 关键词强，搜索量稳定 |
| **数据查询** | 天气、IP、汇率 | 每天都有人搜 |
| **参考工具** | 元素周期表、快捷键、ASCII 表 | 内容丰富，用户停留时间长 |
| **文本工具** | 字数统计、大小写转换、Markdown 预览 | 程序员/写手常用 |
| **CSS 工具** | 渐变生成器、Flexbox 可视化、阴影生成器 | 开发者受众，广告单价高 |

### 一眼排除的信号

看到下面这些，直接跳过别浪费时间：

| 信号 | 说明 |
|------|------|
| 有 `server.js` / `app.py` / `main.go` | 有后端，不是纯前端 |
| 有 `docker-compose.yml` | 多服务架构，太复杂 |
| 有 `requirements.txt` / `Gemfile` / `go.mod` | 非前端依赖 |
| `.env` 里有 `DATABASE_URL` / `REDIS_URL` | 需要数据库 |
| package.json 里有 `next` / `nuxt` | 需要 Node 服务器运行 |
| package.json 里有 `express` / `koa` / `fastify` | 后端框架 |
| 有登录/注册页面 | 需要后端认证 |
| `.env.example` 里有一堆 API Key | 配置太复杂 |

## 第二步：自动评估

### 运行检查脚本

```bash
./scripts/check-repo.sh https://github.com/user/project
```

脚本检查 7 个方面，给出 100 分制评分：

| 检查项 | 满分 | 评分标准 |
|--------|------|---------|
| 许可证 | 20 | MIT/Apache/BSD = 20, 未知 = 5, GPL = 0 |
| 后端文件 | 20 | 没有后端文件 = 20 |
| 服务端依赖 | 15 | 没有 express/koa/next = 15 |
| 数据库引用 | 15 | 没有 DB_URL/mongodb = 15 |
| index.html | 10 | 在根目录 = 10, 在子目录 = 5 |
| 文件数量 | 10 | JS 文件 <20 个 = 10, >20 = 5 |
| API 调用 | 10 | 调用公开 API = 10, 内部 /api/ = 0 |

**结果解读**：
- 70+ 且无严重问题 → **COMPATIBLE（兼容）** → 直接 Fork
- 40-69 或有 1 个问题 → **NEEDS REVIEW（需人工检查）** → 手动看看
- <40 或多个问题 → **INCOMPATIBLE（不兼容）** → 放弃

### 手动检查清单

对于 "NEEDS REVIEW" 的项目，额外看一下：

```
☐ README 里的安装说明简单还是复杂？
☐ 有在线 Demo 吗？能打开吗？
☐ 文件结构里能找到 index.html 吗？
☐ package.json 的 "start" 命令是不是启动服务器？
☐ JS 里的 API 调用是调自建后端（/api/）还是公开 API？
☐ 许可证文本确认允许商用和修改？
☐ HTML/CSS/JS 文件总量可控？
```

## 第三步：一键 Fork 改造

```bash
./scripts/fork-site.sh <GitHub链接> <站点名> ["标题"] ["描述"]
```

例子：

```bash
./scripts/fork-site.sh https://github.com/user/bmi-calculator bmi-calc "BMI 计算器" "在线计算你的身体质量指数"
```

### 脚本自动完成的事情

1. **注入 AdSense** —— 在所有 HTML 的 `<head>` 里加入自动广告代码
2. **注入 Analytics** —— 加入 Google Analytics 统计代码
3. **注入 SEO 标签** —— 添加 meta description 和 Open Graph 标签
4. **添加隐私政策** —— 从 `_shared/` 复制隐私政策页面
5. **添加关于页面** —— 从 `_shared/` 复制关于页面
6. **创建 ads.txt** —— AdSense 要求的广告验证文件
7. **添加致谢** —— 在 README 里注明原始项目来源

### Fork 后的微调

```bash
# 1. 预览效果
open sites/bmi-calc/index.html

# 2. 确认广告代码注入成功
grep "adsbygoogle" sites/bmi-calc/index.html

# 3. 如果想改标题或品牌
nano sites/bmi-calc/index.html

# 4. 部署上线
./scripts/deploy.sh bmi-calc
```

## 第四步：Fork 站的 SEO 优化

Fork 来的站点不是为 SEO 设计的，需要额外优化：

### 必须做

- [ ] 标题包含核心关键词（如 "免费 BMI 计算器 - 在线计算身体质量指数"）
- [ ] Meta description 包含关键词和行动号召（150-160 字符）
- [ ] H1 标题匹配页面用途
- [ ] 页面加载速度快（没有不必要的 JS 库）

### 建议做

- [ ] 添加"使用说明"板块（更多文字内容 = 对 SEO 更好）
- [ ] 添加 FAQ 板块
- [ ] 在你的各个站点之间添加内部链接
- [ ] 制作多语言版本

## 实战建议

### 量大力量大

SiteFactory 的核心是数量。单个站赚得少，但加起来就多了：

```
50 个站 × 每天 $0.10 = $5/天 = $150/月 ≈ ¥1100/月
```

### 分散投资

不要把所有站都做成一类。建议分配：
- 30% 计算器/转换器
- 30% 生成器/工具
- 20% 数据查询
- 20% 参考指南

### 避免踩坑

| 坑 | 后果 |
|----|------|
| 同一个项目 Fork 两次 | Google 惩罚重复内容 |
| 不查许可证就抄 | 法律风险 |
| 放着坏掉的功能不管 | 用户跑了，SEO 变差 |
| 广告放太多 | 违反 AdSense 政策 |
| 没有隐私政策 | AdSense 审核不通过 |
| 不测试手机版 | 60% 以上流量来自手机 |

### 什么项目不值得 Fork

- 需要复杂构建步骤的（你搞不定的）
- 依赖私有 API（随时可能关闭）
- 里面硬编码了你拿不到的 API Key
- 界面太丑，改起来比重写还麻烦
- GitHub 星标 < 5 个（可能有 bug）
