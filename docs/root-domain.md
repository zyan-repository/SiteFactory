**English** | [中文](zh/root-domain.md)

# Root Domain Management

## Why Root Domain Matters

Google AdSense verifies your site by visiting `https://yourdomain.com/`. If you only deploy to subdomains (e.g., `wifi-qr.yourdomain.com`), the root domain has no content and AdSense verification will fail.

**Solution:** Assign one site to the root domain so it serves content at both:
- `https://search123.top` (root domain — for AdSense verification)
- `https://wifi-qr.search123.top` (subdomain — always available)

## How It Works

### Architecture

```
search123.top          → A record → 76.76.21.21 (Vercel IP)
www.search123.top      → CNAME   → cname.vercel-dns.com (redirects to root)
wifi-qr.search123.top  → CNAME   → cname.vercel-dns.com
other-site.search123.top → CNAME → cname.vercel-dns.com
```

- **Root domain** uses an A record (apex domains cannot use CNAME per DNS RFC)
- **www** uses a CNAME; Vercel auto-redirects `www` to the root domain
- **Subdomains** use CNAME as before
- Only **one site** can occupy the root domain at a time
- The root domain assignment is tracked in `root-domain.yaml`

### Tracking File

`root-domain.yaml` at the project root records which site currently holds the root domain:

```yaml
current_site: wifi-qr
assigned_at: "2026-02-19"
```

This file is committed to git so CI/CD workflows and health checks know about the assignment.

## Usage

### Swap Root Domain Site

Use `swap-root.sh` to move the root domain to a different site:

```bash
# Assign wifi-qr to the root domain
./scripts/swap-root.sh wifi-qr

# Assign with verification
./scripts/swap-root.sh wifi-qr --verify

# Later, swap to a different site
./scripts/swap-root.sh my-calculator --verify
```

The script will:
1. Remove the root domain from the old Vercel project
2. Add the root domain to the new Vercel project
3. Ensure DNS A record and www CNAME exist
4. Update `root-domain.yaml`
5. Optionally verify HTTP accessibility

**Important:** The old site keeps its subdomain. Only the root domain binding moves.

### Deploy with Root Domain

When deploying, use `--root` flag or set `root_domain: true` in `site.yaml`:

```bash
# Explicit flag
./scripts/deploy.sh wifi-qr --root
./scripts/dns-setup.sh wifi-qr --root

# Or set in site.yaml (auto-detected by deploy.sh)
# site.yaml:
#   root_domain: true
./scripts/deploy.sh wifi-qr
```

The `launch-site.sh` one-click pipeline also supports `--root`:

```bash
./scripts/launch-site.sh fork https://github.com/user/repo my-tool "My Tool" --root
```

### Default Behavior

**All deploys default to subdomain only.** Root domain is opt-in via:
- `--root` flag on deploy/dns/launch scripts
- `root_domain: true` in the site's `site.yaml`

## DNS Details

| Record | Type | Host | Value | Purpose |
|--------|------|------|-------|---------|
| Apex | A | *(empty)* | `76.76.21.21` | Root domain to Vercel |
| www | CNAME | `www` | `cname.vercel-dns.com` | www redirect to root |
| Subdomain | CNAME | `{site-name}` | `cname.vercel-dns.com` | Site subdomain |

- The A record and www CNAME are created once and never change during swaps
- Only the Vercel project binding changes when swapping root domain sites
- DNS propagation is only needed on first setup (subsequent swaps are instant on Vercel's side)

## Manual Fallback

If scripts fail, you can configure manually:

```bash
# 1. Add root domain to Vercel project
npx vercel domains add search123.top wifi-qr --token $SF_VERCEL_TOKEN
npx vercel domains add www.search123.top wifi-qr --token $SF_VERCEL_TOKEN

# 2. Add DNS records at NameSilo (if not already set)
# A record: Host=(empty), Type=A, Value=76.76.21.21, TTL=3600
# CNAME: Host=www, Type=CNAME, Value=cname.vercel-dns.com, TTL=3600

# 3. Verify
curl -sI https://search123.top
dig A search123.top
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| AdSense still can't verify | DNS may take up to 48h to propagate. Check `dig A search123.top` |
| "Domain already in use" on Vercel | Remove from old project first: `npx vercel domains rm search123.top old-project --yes` |
| Root domain shows wrong site | Run `./scripts/swap-root.sh correct-site --verify` |
| www not redirecting | Check CNAME: `dig CNAME www.search123.top` should show `cname.vercel-dns.com` |
| A record resolves to wrong IP | NameSilo parking records may conflict. `swap-root.sh` auto-removes stale records, but if manual cleanup is needed: NameSilo Dashboard → DNS Manager → delete A records not pointing to `76.76.21.21` |
| DNS cached after record change | Old records may be cached for up to 1 hour (TTL=3600). Use `dig @8.8.8.8 A search123.top` to check propagation via Google DNS |
| Root domain swap fails silently (Hugo sites) | Hugo sites' Vercel project may be named "public" instead of the site name. Check: `npx vercel domains inspect search123.top`. Fix: redeploy with updated `deploy.sh`, or manually `npx vercel link --project <site-name> --yes --cwd sites/<name>/public/` |
