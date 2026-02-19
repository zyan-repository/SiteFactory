[English](../fork-guide.md) | **中文**

# Fork 指南：怎么找项目、评估、改造

核心理念：**能抄就不写** —— GitHub 上有成千上万现成的小工具，干嘛要自己写？

## 名词解释

如果你不太懂技术，这里解释一下本文用到的术语：

| 术语 | 什么意思 |
|------|---------|
| **前端** | 网站在浏览器里运行的部分（HTML、CSS、JavaScript 文件）。我们要的就是这种。 |
| **后端** | 在服务器上运行的代码（Node.js、Python 等）。我们用不了，因为免费托管不支持运行服务器。 |
| **API** | 代码向服务器请求数据的方式。"公开 API"= 谁都能用（可以用）。"内部 API"= 项目自己搭的服务器（不行）。 |
| **SSR** | 服务端渲染——页面在服务器上生成后才发给浏览器。需要一个运行中的服务器，Vercel 免费版不支持。 |
| **静态网站** | 由纯文件（HTML、CSS、JS）组成的网站，不需要服务器来生成页面。这就是我们要的。 |
| **package.json** | JavaScript 项目的依赖清单。我们要看这个文件里有没有服务端相关的东西。 |
| **许可证（License）** | 代码的使用条款。MIT/Apache/BSD = 可以商用。GPL = 有限制，别碰。没有许可证 = 默认不允许使用，跳过。 |

## 整体流程

```
搜索 GitHub → 评估兼容性 → 一键 Fork → 部署上线 → 赚钱
              (check-repo.sh)  (fork-site.sh)  (deploy.sh)
```

## 第一步：找项目

### GitHub 搜索技巧

**按工具类型搜索**（在 [GitHub 搜索框](https://github.com/search) 里输入）：

```
# 在 GitHub 搜索框里输入
calculator html css language:HTML
converter tool html language:JavaScript
weather app html css
password generator html javascript
color picker tool html

# 按星标数筛选（星越多 = 越多人觉得好用）
calculator html stars:>10
qr code generator html stars:>20

# 排除前端框架（我们要纯 HTML 的，不要复杂框架）
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

| 信号 | 通俗解释 | 为什么不行 |
|------|---------|-----------|
| 有 `server.js` / `app.py` / `main.go` | 项目有需要在服务器上运行的代码 | 我们只能托管静态文件，没法跑服务器 |
| 有 `docker-compose.yml` | 项目要同时运行好几个服务 | 太复杂了，我们搞不定 |
| 有 `requirements.txt` / `Gemfile` / `go.mod` | 项目需要安装 Python/Ruby/Go | 我们只要纯 HTML/CSS/JS |
| `.env` 里有 `DATABASE_URL` / `REDIS_URL` | 项目要连数据库存数据 | 静态网站没法连数据库 |
| package.json 里有 `next` / `nuxt` | 用了一种需要服务器来渲染页面的框架 | 需要 Node.js 服务器才能跑 |
| package.json 里有 `express` / `koa` / `fastify` | 用了后端 Web 框架 | 我们只要在浏览器里跑的代码 |
| 有登录/注册页面 | 项目需要用户账号系统 | 用户账号需要后端服务器支持 |
| `.env.example` 里有一堆 API Key | 配置太复杂，依赖很多外部服务 | 太多东西会出问题 |

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
- 40-69 或有 1 个问题 → **NEEDS REVIEW（需人工检查）** → 手动看看（见下面的清单）
- <40 或多个问题 → **INCOMPATIBLE（不兼容）** → 放弃这个项目

**什么算"严重问题"（红色标记）？**
- 许可证是 GPL、AGPL 或"未找到许可证"——意味着不能商用
- 检测到后端文件（server.js、app.py 等）——项目需要服务器才能跑
- 发现数据库依赖——项目需要数据库，我们提供不了

如果分数 70+ 但有**警告**（黄色文字，不是红色），通常可以继续。看一下警告的具体内容——常见的警告如 "JS 文件较多" 或 "未识别的许可证格式" 一般没问题。

### 手动检查清单

对于 "NEEDS REVIEW" 的项目，打开 GitHub 页面额外看一下：

```
☐ README 里的安装说明简单吗？（只要 "打开 index.html" = 好）
☐ 有在线 Demo 链接吗？能在浏览器里直接打开用吗？
☐ 文件列表里能找到 index.html 吗？
☐ package.json 的 "start" 命令是不是启动服务器？（坏："node server.js"，好：没有 start 命令）
☐ JS 里的 API 调用是调自建后端（代码里有 "/api/"）还是公开 API（代码里有 "https://api.xxx.com"）？
☐ 许可证文本里写了 "MIT" 或 "Apache" 或 "BSD"？
☐ HTML/CSS/JS 文件总共不超过 30 个？（可控 = 好）
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

### Fork 后的检查和调整

**1. 预览效果：**
```bash
open sites/bmi-calc/index.html
```

**2. 确认广告代码注入成功：**
```bash
grep "adsbygoogle" sites/bmi-calc/index.html
# 如果输出了包含 "adsbygoogle" 的一行，说明注入成功
# 如果没有输出，重新运行 fork-site.sh 或检查错误日志
```

**3. 修改标题**（在 `sites/bmi-calc/index.html` 里）：
1. 用任意文本编辑器打开这个文件
2. 搜索 `<title>` 标签（在文件靠前的 `<head>` 区域里）
3. 把 `<title>` 和 `</title>` 之间的文字改成你想要的标题
4. 同时找到 `<meta property="og:title"`，把 `content` 的值也改成一样的

**4. 修改描述**（同一个文件）：
1. 找到 `<meta name="description" content="...">`
2. 把 `content` 里的文字改成你的描述（建议 150-160 字符）
3. 同时更新 `<meta property="og:description" content="...">` 保持一致

**5. 部署上线：**
```bash
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
乐观预估：50 个站 × $0.10/天 = $5/天 = $150/月 ≈ ¥1100/月
现实预估：50 个站 × $0.03/天 = $1.50/天 = $45/月 ≈ ¥330/月
保底预估：50 个站 × $0.01/天 = $0.50/天 = $15/月 ≈ ¥110/月
```

**说实话：**
- 新站前 1-3 个月大概率是 $0 收入（还没有流量）
- 收入取决于领域、流量和访客来自哪里
- 来自美国/英国/澳洲的流量，每次点击收入是发展中国家的 5-10 倍
- $0.10/天 是可以达到的，但不是白送的——需要持续做内容和 SEO
- 把 SiteFactory 当长期项目，不是快速赚钱的方法

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
| 不查许可证就抄 | 法律风险——可能被要求下架 |
| 放着坏掉的功能不管 | 用户秒退，SEO 排名下降 |
| 广告放太多 | 违反 AdSense 政策——可能封号 |
| 没有隐私政策 | AdSense 审核不通过 |
| 不测试手机版 | 60% 以上流量来自手机——手机上坏了 = 损失大量访客 |

### 什么项目不值得 Fork

- 需要复杂构建步骤的（比如要跑 `npm run build` 加复杂的 webpack 配置）
- 依赖私有 API（随时可能关闭或开始收费）
- 里面硬编码了你拿不到的 API Key
- 界面太丑，改起来超过 30 分钟的
- GitHub 星标 < 5 个（可能有 bug 或已经没人维护了）
