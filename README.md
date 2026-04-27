# CSGO 服务器状态监控系统

[![Build Status](https://github.com/RATING3PRO/csgo-server-monitor/workflows/Compile%20SourceMod%20Plugin/badge.svg)](https://github.com/RATING3PRO/csgo-server-monitor/actions)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![SourceMod](https://img.shields.io/badge/SourceMod-1.10+-orange.svg)](https://www.sourcemod.net/)

基于 SourcePawn 的 CSGO 服务器状态监控插件，实时追踪服务器性能和玩家信息。

## 功能特性

### 服务器监控
- 在线人数统计（真实玩家 + BOT）
- 当前地图信息
- Tickrate 实时监控
- Server Var（延迟波动）
- CPU 使用率
- 内存使用量

### 玩家信息
- 玩家列表管理
- 地理位置（国家/城市）
- 网络延迟统计
- 游戏数据（分数/死亡/时长）
- Steam ID 和 IP 地址

## 快速开始

### 安装

1. 从 [Releases](https://github.com/RATING3PRO/csgo-server-monitor/releases) 下载最新版本
2. 解压到服务器目录
3. 加载插件：
   ```
   sm plugins load server_monitor
   ```

### 前置要求

- SourceMod 1.10+
- MetaMod:Source 1.11+
- CSGO 服务器

### 配置

配置文件自动生成在 `cfg/sourcemod/server_monitor.cfg`

```cfg
// 监控数据更新间隔（秒）
sm_monitor_interval "5.0"

// 启用服务器监控
sm_monitor_enable "1"
```

## 命令

### 管理员命令（需要 ADMFLAG_GENERIC 权限）

| 命令 | 描述 |
|------|------|
| `sm_serverstatus` | 显示服务器状态概览 |
| `sm_playerlist` | 显示详细玩家列表 |
| `sm_serverinfo` | 显示完整服务器信息 |

### 玩家命令

| 命令 | 描述 |
|------|------|
| `sm_status` | 查看服务器状态 |
| `sm_players` | 查看在线玩家 |

## 使用示例

```
> sm_serverstatus

========================================
       CSGO 服务器状态监控
========================================
在线人数: 12 / 32
当前地图: de_dust2
Tickrate: 128.0
Server Var: 0.45 ms
CPU 使用率: 35.2%
内存使用: 1024.5 MB
========================================
```

## API 接口

插件提供 API 供其他插件调用，详见 `server_monitor_api.inc`

### Native 函数

```sourcepawn
// 获取服务器状态
native bool Monitor_GetServerStatus(int &playerCount, int &maxPlayers, 
                                     char[] mapName, int mapNameSize, float &tickrate);

// 获取性能指标
native bool Monitor_GetPerformance(float &serverVar, float &cpuUsage, float &memoryUsage);

// 获取玩家地理位置
native bool Monitor_GetPlayerLocation(int client, char[] country, int countrySize, 
                                       char[] city, int citySize);

// 获取玩家网络信息
native bool Monitor_GetPlayerNetwork(int client, int &ping, char[] ipAddress, int ipSize);

// 获取玩家统计
native bool Monitor_GetPlayerStats(int client, int &score, int &deaths, float &connectTime);

// 强制更新数据
native bool Monitor_ForceUpdate();

// 获取真实玩家数量
native int Monitor_GetRealPlayerCount();

// 检查玩家国家
native bool Monitor_IsPlayerFromCountry(int client, const char[] countryCode);

// 获取平均延迟
native int Monitor_GetAveragePing();
```

### Forward 回调

```sourcepawn
// 服务器状态更新时触发
forward void OnServerStatusUpdated(int playerCount, float tickrate);

// 玩家信息更新时触发
forward void OnPlayerInfoUpdated(int client, int ping);

// 性能警告时触发
forward void OnPerformanceWarning(int type, float value);
```

## 编译

### 自动编译（推荐）

项目使用 GitHub Actions 自动编译，支持 SourceMod 1.11 和 1.12。

推送代码或创建 Release 时自动触发编译。

### 手动编译

```bash
spcomp -i"include" server_monitor.sp -o server_monitor.smx
```

## 其他功能

### GeoIP 地理位置

需要 GeoIP2 数据库文件：

```
csgo/addons/sourcemod/configs/geoip/
├── GeoIP2-City.mmdb
└── GeoIP2-Country.mmdb
```

下载地址：https://dev.maxmind.com/geoip/geolite2-free-geolocation-data

### CPU/内存监控

需要安装以下扩展之一：
- [System2](https://github.com/dordnung/System2)
- [SteamWorks](https://github.com/KyleSanderson/SteamWorks)
