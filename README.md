# CS2 CSS Inventory Simulator (D1 Worker 定制版)

本仓库是官方插件 [ianlucas/cs2-css-inventory-simulator](https://github.com/ianlucas/cs2-css-inventory-simulator) 的定制 fork。

**主要改动**：把插件对接的服务端后台从官方的 `inventory.cstrike.app` 换成了自己的 Cloudflare Worker + D1 服务（域名 `https://YOUR_WORKER_URL`）。

## 这次定制改了什么

| 文件 | 改动 |
|---|---|
| `source/InventorySimulator/Services/ConVars.cs` | `invsim_url` → `https://YOUR_WORKER_URL`，`invsim_apikey` → 本项目的 D1 Worker key |
| `.github/workflows/sync-upstream.yml` | 每 6 小时自动同步上游，合并时保护 `ConVars.cs`，新 tag 自动触发 release |
| `.github/workflows/ci.yml` | 增加 `push tags: v*` 触发，继承上游出包逻辑 |
| `.gitattributes` | `ConVars.cs merge=keepMine` 合并保护，保证上游合入不覆盖我们的 URL/key |
| `sync-upstream.sh` | 本地手动同步上游 + 构建验证脚本 |

除上述外，其余代码与上游一致，完全复刻上游 **v5 协议**，无需新端点。

## 配套后端仓库

后台是独立的 Cloudflare Worker + D1 项目：

**[cyqmq/cs2-cfworker-inventory-simulator](https://github.com/cyqmq/cs2-cfworker-inventory-simulator)**

部署好 Worker 后，本插件通过 `invsim_url` / `invsim_apikey` 连接该服务。

## 构建

```bash
dotnet build -c Release
```

## 部署

1. Copy `bin/Release/plugins/InventorySimulator/` → `<游戏目录>/csgo/addons/counterstrikesharp/plugins/`
2. Copy `bin/Release/gamedata/` → `<游戏目录>/csgo/addons/counterstrikesharp/gamedata/`
3. 安装 CounterStrikeSharp（with-runtime，支持 net10）
4. 控制台 `css_plugins` 确认加载

## 自动同步上游

本 fork 会通过 GitHub Actions（`sync-upstream.yml`）定期合并上游 `ianlucas` 的更新，并保护 `ConVars.cs` 不被上游覆盖。被保护的文件：

`source/InventorySimulator/Services/ConVars.cs`

## 授权

上游代码采用 MIT License，本 fork 延续相同授权。见 [License.txt](License.txt)。
