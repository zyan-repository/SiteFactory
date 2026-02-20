**English** | [中文](SITES.zh.md)

# Site Registry

All integrated sites in SiteFactory. **Contributors must update this file when adding or removing a site.**

## Sites

| Name | Type | Source | License | Description |
|------|------|--------|---------|-------------|
| wifi-qr | static | [evgeni/qifi](https://github.com/evgeni/qifi) | MIT | WiFi QR code generator — enter SSID & password, get a scannable QR code |

## How to Update

When adding a new site, append a row to the table above:

```markdown
| my-tool | static | [user/repo](https://github.com/user/repo) | MIT | Brief description of what the tool does |
```

Fields:
- **Name**: Directory name under `sites/` (must match `site.yaml → name`)
- **Type**: `static` (forked tool) or `hugo` (content site)
- **Source**: Link to original repo, or `template` for Hugo sites
- **License**: MIT / Apache-2.0 / BSD
- **Description**: One sentence explaining the site's purpose and value to users
