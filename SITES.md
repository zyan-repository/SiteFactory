**English** | [中文](SITES.zh.md)

# Site Registry

All integrated sites in SiteFactory. **Contributors must update this file when adding or removing a site.**

## Sites

| Name | Type | Source | License | Description |
|------|------|--------|---------|-------------|
| adsense-home | hugo | template | — | Search & tools hub homepage (Search123), deployed on root domain |
| wifi-qr | static | [evgeni/qifi](https://github.com/evgeni/qifi) | MIT | WiFi QR code generator — enter SSID & password, get a scannable QR code |
| word-counter | static | [letchagan/Simple-Word-counter](https://github.com/letchagan/Simple-Word-counter) | MIT | Word, character, sentence and paragraph counter |
| timestamp-converter | static | [miguelmota/unix-timestamp-converter](https://github.com/miguelmota/unix-timestamp-converter) | MIT | Unix timestamp to human-readable date converter |
| color-converter | static | [Murtaza-Ax/Color-Converter](https://github.com/Murtaza-Ax/Color-Converter) | MIT | HEX/RGB color converter with live preview |
| json-linter | static | [njoylab/json-linter-tool](https://github.com/njoylab/json-linter-tool) | MIT | JSON formatter, validator and minifier |
| markdown-editor | static | [matinkg/markdown-renderer](https://github.com/matinkg/markdown-renderer) | MIT | Live markdown editor with syntax highlighting and instant preview |

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
