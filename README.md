# CS2 CSS Inventory Simulator (D1 Worker 定制版)

本仓库是官方插件 [ianlucas/cs2-css-inventory-simulator](https://github.com/ianlucas/cs2-css-inventory-simulator) 的定制 fork。

**主要改动**：把插件对接的服务端后台从官方的 `inventory.cstrike.app` 换成你自己的 Cloudflare Worker + D1 服务。域名与 API key 使用自定义 ConVar（`invsim_url` / `invsim_apikey`）配置，不写死在源码之外的公开文档里。

## 这次定制改了什么

| 文件 | 改动 |
|---|---|
| `source/InventorySimulator/Services/ConVars.cs` | 默认 `invsim_url` / `invsim_apikey` 指向你的 D1 Worker 后台 |
| `.github/workflows/sync-upstream.yml` | 每 6 小时自动同步上游，合并时保护 `ConVars.cs`，新 tag 自动触发 release |
| `.github/workflows/ci.yml` | 增加 `push tags: v*` 触发，继承上游出包逻辑 |
| `.gitattributes` | `ConVars.cs merge=keepMine` 合并保护，保证上游合入不覆盖我们的 URL/key |
| `sync-upstream.sh` | 本地手动同步上游 + 构建验证脚本 |

除上述外，其余代码与上游一致，完全复刻上游 **v5 协议**，无需新端点。

## 配套后端仓库

后台是独立的 Cloudflare Worker + D1 项目：

**[cyqmq/cs2-cfworker-inventory-simulator](https://github.com/cyqmq/cs2-cfworker-inventory-simulator)**

先部署好 Worker，再让本插件通过 `invsim_url` / `invsim_apikey` 连接该服务。

## 使用教程

### 1. 构建

```bash
dotnet build -c Release
```

构建产物在 `bin/Release/`。

### 2. 部署到 CS2 服务器

前置要求：
- 服务器已安装 [Metamod](https://www.sourcemm.net/)
- 已安装 [CounterStrikeSharp](https://github.com/roflmuffin/CounterStrikeSharp)（**with-runtime** 版本，需支持 .NET 10，建议使用最新版）

拷贝文件：
1. `bin/Release/plugins/InventorySimulator/` → `<游戏目录>/csgo/addons/counterstrikesharp/plugins/`
2. `bin/Release/gamedata/` → `<游戏目录>/csgo/addons/counterstrikesharp/gamedata/`

注意：
- 产物中缺少 `runtimeconfig.json` 是正常的，CounterStrikeSharp 4.x 不需要它（仅需 dll + deps.json + pdb）。
- `gamedata/inventory-simulator.json`（函数签名）需随 CS2 更新，本仓库自动同步上游时会带上新签名。

重启服务器后，控制台执行 `css_plugins` 确认插件已加载：

```
css_plugins
# 应看到 [#1:LOADED]: "InventorySimulator" (版本号)
```

### 3. 配置后台地址与 API key

插件用两个 ConVar 连接你的后端，首个值是编译时的默认值，你也可以在运行时/配置文件覆盖：

| ConVar | 说明 | 类型 |
|---|---|---|
| `invsim_url` | 后端基础 URL，例如 `https://your-worker.example.com` | string |
| `invsim_apikey` | 后端 API key（用于 StatTrak / 喷雾等需要鉴权的接口） | string |

在控制台直接设置：

```
invsim_url https://your-worker.example.com
invsim_apikey your_api_key_here
```

或写入 `cfg/server.cfg`（推荐，重启生效）：

```
invsim_url "https://your-worker.example.com"
invsim_apikey "your_api_key_here"
```

> 注意：若 `invsim_url` 不是官方主机 `inventory.cstrike.app`，插件会自动关闭 keyless 的公开 StatTrak/喷雾请求，改用带 key 的鉴权方式（`IsPublicApiStatTrakIncrement` / `IsPublicApiSprayConsume` 会被置为 false）。

### 4. 基础功能使用

玩家在 Web / Worker 端配置好外观后进服，插件会自动从后端拉取并在游戏内模拟应用（不改变真实 Steam 库存）。

| 功能 | 开启方式 | 相关 ConVar |
|---|---|---|
| `!ws` 手动刷新/切换皮肤 | `invsim_ws_enabled 1` | `IsWsEnabled`、`IsWsImmediately`、`WsCooldown` |
| 喷雾 / 涂鸦 | `!spray` 或按使用键| `IsSprayEnabled`、`IsSprayOnUse`、`SprayCooldown` |
| StatTrak 击杀计数 | 用带 StatTrak 的武器击杀，自动同步到后端 | `IsStatTrakIgnoreBots` |
| 登录绑定（可选） | `invsim_wslogin 1` | `IsWsLogin`（需后端支持，默认关闭） |

常用 ConVar 速查：

```
invsim_ws_enabled 1          // 开启 !ws 命令
invsim_ws_immediately 1      // 刷新后立即生效（不用等重生）
invsim_ws_cooldown 30        // 刷新冷却（秒）
invsim_spray_enabled 1       // 开启喷雾（默认开）
invsim_spray_on_use 1        // 按使用键喷漆
invsim_spray_cooldown 30     // 喷雾冷却（秒）
```

## 自动同步上游

本 fork 通过 GitHub Actions（`sync-upstream.yml`）定期合并上游 `ianlucas` 的更新，并保护 `ConVars.cs` 不被上游覆盖。被保护的文件：

`source/InventorySimulator/Services/ConVars.cs`

触发方式：
- 每 6 小时自动运行一次
- 可在 Actions 页面手动 `workflow_dispatch`

本地手动同步可用脚本：

```bash
./sync-upstream.sh            # 同步并入 + 构建验证
./sync-upstream.sh --no-build # 只同步，不构建
```

## 授权

上游代码采用 MIT License，本 fork 延续相同授权。见 [License.txt](License.txt)。
