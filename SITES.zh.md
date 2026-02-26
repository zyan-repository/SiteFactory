[English](SITES.md) | **中文**

# 站点清单

SiteFactory 中所有已集成的站点。**贡献者添加或移除站点时必须同步更新此文件。**

## 站点列表

| 名称 | 类型 | 来源 | 许可证 | 说明 |
|------|------|------|--------|------|
| adsense-home | hugo | template | — | 搜索与工具聚合首页（Search123），部署在根域名 |
| wifi-qr | static | [evgeni/qifi](https://github.com/evgeni/qifi) | MIT | WiFi 二维码生成器 — 输入 SSID 和密码，生成可扫描的二维码 |
| word-counter | static | [letchagan/Simple-Word-counter](https://github.com/letchagan/Simple-Word-counter) | MIT | 字数、字符、句子、段落统计工具 |
| timestamp-converter | static | [miguelmota/unix-timestamp-converter](https://github.com/miguelmota/unix-timestamp-converter) | MIT | Unix 时间戳与日期互转工具 |
| color-converter | static | [Murtaza-Ax/Color-Converter](https://github.com/Murtaza-Ax/Color-Converter) | MIT | HEX/RGB 颜色转换器，带实时预览 |
| json-linter | static | [njoylab/json-linter-tool](https://github.com/njoylab/json-linter-tool) | MIT | JSON 格式化、校验、压缩工具 |
| markdown-editor | static | [matinkg/markdown-renderer](https://github.com/matinkg/markdown-renderer) | MIT | Markdown 实时编辑与预览工具 |

## 如何更新

添加新站点时，在上方表格末尾追加一行：

```markdown
| my-tool | static | [user/repo](https://github.com/user/repo) | MIT | 简要说明工具用途 |
```

字段说明：
- **名称**：`sites/` 下的目录名（必须与 `site.yaml → name` 一致）
- **类型**：`static`（fork 工具站）或 `hugo`（内容站）
- **来源**：原始仓库链接，Hugo 站点填 `template`
- **许可证**：MIT / Apache-2.0 / BSD
- **说明**：一句话描述站点的用途和价值
