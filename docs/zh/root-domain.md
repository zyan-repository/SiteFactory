[English](../root-domain.md) | **中文**

# 主域名管理

## 为什么需要主域名

Google AdSense 通过访问 `https://yourdomain.com/` 来验证你的站点。如果你只部署到子域名（如 `wifi-qr.yourdomain.com`），主域名没有内容，AdSense 验证就会失败。

**解决方案：** 将一个站点分配到主域名，使其同时在以下地址提供服务：
- `https://search123.top`（主域名 — 用于 AdSense 验证）
- `https://wifi-qr.search123.top`（子域名 — 始终可用）

## 工作原理

### 架构

```
search123.top          → A 记录  → 76.76.21.21（Vercel IP）
www.search123.top      → CNAME  → cname.vercel-dns.com（重定向到主域名）
wifi-qr.search123.top  → CNAME  → cname.vercel-dns.com
other-site.search123.top → CNAME → cname.vercel-dns.com
```

- **主域名** 使用 A 记录（根据 DNS RFC，裸域名不能使用 CNAME）
- **www** 使用 CNAME；Vercel 自动将 `www` 重定向到主域名
- **子域名** 和以前一样使用 CNAME
- 同一时间只有**一个站点**可以占据主域名
- 主域名分配状态记录在 `root-domain.yaml` 中

### 跟踪文件

项目根目录的 `root-domain.yaml` 记录当前哪个站点占据主域名：

```yaml
current_site: wifi-qr
assigned_at: "2026-02-19"
```

此文件提交到 git，以便 CI/CD 工作流和健康检查知道当前分配情况。

## 使用方法

### 切换主域名站点

使用 `swap-root.sh` 将主域名切换到不同的站点：

```bash
# 将 wifi-qr 分配到主域名
./scripts/swap-root.sh wifi-qr

# 带验证的分配
./scripts/swap-root.sh wifi-qr --verify

# 之后切换到其他站点
./scripts/swap-root.sh my-calculator --verify
```

脚本会执行以下步骤：
1. 从旧的 Vercel 项目移除主域名绑定
2. 将主域名添加到新的 Vercel 项目
3. 确保 DNS A 记录和 www CNAME 存在
4. 更新 `root-domain.yaml`
5. 可选：验证 HTTP 可访问性

**重要：** 旧站点保留其子域名，只有主域名绑定会移动。

### 部署时绑定主域名

部署时使用 `--root` 参数，或在 `site.yaml` 中设置 `root_domain: true`：

```bash
# 显式参数
./scripts/deploy.sh wifi-qr --root
./scripts/dns-setup.sh wifi-qr --root

# 或在 site.yaml 中设置（deploy.sh 自动检测）
# site.yaml:
#   root_domain: true
./scripts/deploy.sh wifi-qr
```

`launch-site.sh` 一键流程也支持 `--root`：

```bash
./scripts/launch-site.sh fork https://github.com/user/repo my-tool "My Tool" --root
```

### 默认行为

**所有部署默认只部署到子域名。** 主域名需要显式启用：
- 在 deploy/dns/launch 脚本中使用 `--root` 参数
- 在站点的 `site.yaml` 中设置 `root_domain: true`

## DNS 详情

| 记录 | 类型 | Host | 值 | 用途 |
|------|------|------|---|------|
| 裸域名 | A | *（空）* | `76.76.21.21` | 主域名指向 Vercel |
| www | CNAME | `www` | `cname.vercel-dns.com` | www 重定向到主域名 |
| 子域名 | CNAME | `{site-name}` | `cname.vercel-dns.com` | 站点子域名 |

- A 记录和 www CNAME 只需创建一次，切换时不需要修改
- 切换时只有 Vercel 项目绑定发生变化
- DNS 传播只在首次设置时需要等待（后续切换在 Vercel 端即时生效）

## 手动操作（备用方案）

如果脚本执行失败，可以手动配置：

```bash
# 1. 在 Vercel 项目中添加主域名
npx vercel domains add search123.top wifi-qr --token $SF_VERCEL_TOKEN
npx vercel domains add www.search123.top wifi-qr --token $SF_VERCEL_TOKEN

# 2. 在 NameSilo 添加 DNS 记录（如果还没有）
# A 记录：Host=（空），Type=A，Value=76.76.21.21，TTL=3600
# CNAME：Host=www，Type=CNAME，Value=cname.vercel-dns.com，TTL=3600

# 3. 验证
curl -sI https://search123.top
dig A search123.top
```

## 常见问题排查

| 问题 | 解决方案 |
|------|---------|
| AdSense 仍然无法验证 | DNS 传播可能需要 48 小时。检查 `dig A search123.top` |
| Vercel 提示"域名已被使用" | 先从旧项目移除：`npx vercel domains rm search123.top old-project --yes` |
| 主域名显示错误的站点 | 运行 `./scripts/swap-root.sh correct-site --verify` |
| www 没有重定向 | 检查 CNAME：`dig CNAME www.search123.top` 应显示 `cname.vercel-dns.com` |
| A 记录解析到错误 IP | NameSilo 的默认停放记录可能冲突。`swap-root.sh` 会自动清理旧记录，如需手动处理：NameSilo 控制面板 → DNS 管理 → 删除不指向 `76.76.21.21` 的 A 记录 |
| 修改 DNS 后仍解析到旧 IP | 旧记录可能缓存最多 1 小时（TTL=3600）。用 `dig @8.8.8.8 A search123.top` 通过 Google DNS 检查传播状态 |
| 根域名切换静默失败（Hugo 站点） | Hugo 站点的 Vercel 项目名可能是 "public" 而非站点名。检查：`npx vercel domains inspect search123.top`。修复：用更新后的 `deploy.sh` 重新部署，或手动 `npx vercel link --project <站点名> --yes --cwd sites/<名称>/public/` |
