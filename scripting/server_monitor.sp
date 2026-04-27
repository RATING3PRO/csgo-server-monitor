#include <sourcemod>
#include <sdktools>
#include <geoip>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"
#define MAX_PLAYERS 64

// 插件信息
public Plugin myinfo = {
    name = "CSGO Server Monitor",
    author = "Your Name",
    description = "CSGO服务器状态监控系统",
    version = PLUGIN_VERSION,
    url = "https://github.com/yourusername/csgo-server-monitor"
};

// 全局变量
ConVar g_cvUpdateInterval;
ConVar g_cvEnableMonitor;
Handle g_hMonitorTimer = null;

// 服务器状态数据结构
enum struct ServerStatus {
    int playerCount;
    int maxPlayers;
    char mapName[64];
    float tickrate;
    float serverVar;
    float cpuUsage;
    float memoryUsage;
}

ServerStatus g_ServerStatus;

// 玩家信息结构
enum struct PlayerInfo {
    int userId;
    char name[MAX_NAME_LENGTH];
    char steamId[32];
    char ipAddress[32];
    char country[64];
    char city[64];
    int ping;
    int score;
    int deaths;
    float connectTime;
}

PlayerInfo g_PlayerList[MAX_PLAYERS];

public void OnPluginStart() {
    // 创建插件版本ConVar
    CreateConVar("sm_servermonitor_version", PLUGIN_VERSION, "Server Monitor Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    
    // 创建配置ConVars
    g_cvUpdateInterval = CreateConVar("sm_monitor_interval", "5.0", "监控数据更新间隔（秒）", FCVAR_NOTIFY, true, 1.0, true, 60.0);
    g_cvEnableMonitor = CreateConVar("sm_monitor_enable", "1", "启用服务器监控", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    // 注册管理员命令
    RegAdminCmd("sm_serverstatus", Command_ServerStatus, ADMFLAG_GENERIC, "显示服务器状态");
    RegAdminCmd("sm_playerlist", Command_PlayerList, ADMFLAG_GENERIC, "显示玩家列表");
    RegAdminCmd("sm_serverinfo", Command_ServerInfo, ADMFLAG_GENERIC, "显示详细服务器信息");
    
    // 注册普通命令
    RegConsoleCmd("sm_status", Command_Status, "查看服务器状态");
    RegConsoleCmd("sm_players", Command_Players, "查看在线玩家");
    
    // 自动生成配置文件
    AutoExecConfig(true, "server_monitor");
    
    // 启动监控定时器
    CreateTimer(1.0, Timer_StartMonitor, _, TIMER_FLAG_NO_MAPCHANGE);
    
    PrintToServer("[Server Monitor] 插件已加载 v%s", PLUGIN_VERSION);
}

public void OnPluginEnd() {
    if (g_hMonitorTimer != null) {
        KillTimer(g_hMonitorTimer);
        g_hMonitorTimer = null;
    }
}

public void OnMapStart() {
    // 获取地图名称
    GetCurrentMap(g_ServerStatus.mapName, sizeof(g_ServerStatus.mapName));
    PrintToServer("[Server Monitor] 地图已加载: %s", g_ServerStatus.mapName);
}

public void OnClientPutInServer(int client) {
    if (!IsValidClient(client)) {
        return;
    }
    
    UpdatePlayerInfo(client);
}

public void OnClientDisconnect(int client) {
    if (!IsValidClient(client)) {
        return;
    }
    
    // 清除玩家数据
    g_PlayerList[client].userId = 0;
}

// 启动监控定时器
public Action Timer_StartMonitor(Handle timer) {
    if (g_cvEnableMonitor.BoolValue) {
        float interval = g_cvUpdateInterval.FloatValue;
        g_hMonitorTimer = CreateTimer(interval, Timer_UpdateMonitor, _, TIMER_REPEAT);
    }
    return Plugin_Stop;
}

// 更新监控数据
public Action Timer_UpdateMonitor(Handle timer) {
    if (!g_cvEnableMonitor.BoolValue) {
        g_hMonitorTimer = null;
        return Plugin_Stop;
    }
    
    UpdateServerStatus();
    UpdateAllPlayersInfo();
    
    return Plugin_Continue;
}

// 更新服务器状态
void UpdateServerStatus() {
    // 获取玩家数量
    g_ServerStatus.playerCount = GetClientCount(false);
    g_ServerStatus.maxPlayers = MaxClients;
    
    // 获取当前地图
    GetCurrentMap(g_ServerStatus.mapName, sizeof(g_ServerStatus.mapName));
    
    // 获取Tickrate
    g_ServerStatus.tickrate = 1.0 / GetTickInterval();
    
    // 获取服务器Var（方差）
    g_ServerStatus.serverVar = GetServerVar();
    
    // 获取CPU和内存使用率（需要系统扩展支持）
    g_ServerStatus.cpuUsage = GetCPUUsage();
    g_ServerStatus.memoryUsage = GetMemoryUsage();
}

// 更新所有玩家信息
void UpdateAllPlayersInfo() {
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i)) {
            UpdatePlayerInfo(i);
        }
    }
}

// 更新单个玩家信息
void UpdatePlayerInfo(int client) {
    if (!IsValidClient(client)) {
        return;
    }
    
    g_PlayerList[client].userId = GetClientUserId(client);
    GetClientName(client, g_PlayerList[client].name, sizeof(g_PlayerList[].name));
    GetClientAuthId(client, AuthId_Steam2, g_PlayerList[client].steamId, sizeof(g_PlayerList[].steamId));
    GetClientIP(client, g_PlayerList[client].ipAddress, sizeof(g_PlayerList[].ipAddress));
    
    // 获取地理位置信息
    if (!IsFakeClient(client)) {
        GeoipCountry(g_PlayerList[client].ipAddress, g_PlayerList[client].country, sizeof(g_PlayerList[].country));
        GeoipCity(g_PlayerList[client].ipAddress, g_PlayerList[client].city, sizeof(g_PlayerList[].city));
    }
    
    // 获取玩家统计
    g_PlayerList[client].ping = GetClientAvgLatency(client, NetFlow_Both) * 1000.0;
    g_PlayerList[client].score = GetClientFrags(client);
    g_PlayerList[client].deaths = GetClientDeaths(client);
    g_PlayerList[client].connectTime = GetClientTime(client);
}

// 命令：显示服务器状态
public Action Command_ServerStatus(int client, int args) {
    UpdateServerStatus();
    
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "       CSGO 服务器状态监控");
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "在线人数: %d / %d", g_ServerStatus.playerCount, g_ServerStatus.maxPlayers);
    PrintToConsole(client, "当前地图: %s", g_ServerStatus.mapName);
    PrintToConsole(client, "Tickrate: %.1f", g_ServerStatus.tickrate);
    PrintToConsole(client, "Server Var: %.2f ms", g_ServerStatus.serverVar);
    PrintToConsole(client, "CPU 使用率: %.1f%%", g_ServerStatus.cpuUsage);
    PrintToConsole(client, "内存使用: %.1f MB", g_ServerStatus.memoryUsage);
    PrintToConsole(client, "========================================");
    
    if (client > 0) {
        ReplyToCommand(client, "[SM] 服务器状态已输出到控制台");
    }
    
    return Plugin_Handled;
}

// 命令：显示玩家列表
public Action Command_PlayerList(int client, int args) {
    UpdateAllPlayersInfo();
    
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "          在线玩家列表");
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "%-3s %-20s %-8s %-15s %-20s", "ID", "名称", "分数", "Ping", "地理位置");
    PrintToConsole(client, "----------------------------------------");
    
    int count = 0;
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i)) {
            char location[128];
            if (strlen(g_PlayerList[i].city) > 0) {
                Format(location, sizeof(location), "%s, %s", g_PlayerList[i].city, g_PlayerList[i].country);
            } else {
                Format(location, sizeof(location), "%s", g_PlayerList[i].country);
            }
            
            PrintToConsole(client, "%-3d %-20s %3d/%-3d %-6d ms %-20s", 
                i, 
                g_PlayerList[i].name, 
                g_PlayerList[i].score,
                g_PlayerList[i].deaths,
                g_PlayerList[i].ping,
                location);
            count++;
        }
    }
    
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "总计: %d 名玩家在线", count);
    PrintToConsole(client, "========================================");
    
    if (client > 0) {
        ReplyToCommand(client, "[SM] 玩家列表已输出到控制台");
    }
    
    return Plugin_Handled;
}

// 命令：显示详细服务器信息
public Action Command_ServerInfo(int client, int args) {
    UpdateServerStatus();
    UpdateAllPlayersInfo();
    
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "      CSGO 服务器详细信息");
    PrintToConsole(client, "========================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "[基础信息]");
    PrintToConsole(client, "  在线人数: %d / %d", g_ServerStatus.playerCount, g_ServerStatus.maxPlayers);
    PrintToConsole(client, "  当前地图: %s", g_ServerStatus.mapName);
    PrintToConsole(client, "");
    PrintToConsole(client, "[性能指标]");
    PrintToConsole(client, "  Tickrate: %.1f", g_ServerStatus.tickrate);
    PrintToConsole(client, "  Server Var: %.2f ms", g_ServerStatus.serverVar);
    PrintToConsole(client, "");
    PrintToConsole(client, "[系统资源]");
    PrintToConsole(client, "  CPU 使用率: %.1f%%", g_ServerStatus.cpuUsage);
    PrintToConsole(client, "  内存使用: %.1f MB", g_ServerStatus.memoryUsage);
    PrintToConsole(client, "");
    PrintToConsole(client, "[玩家统计]");
    
    int totalPing = 0;
    int validPlayers = 0;
    
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i) && !IsFakeClient(i)) {
            totalPing += g_PlayerList[i].ping;
            validPlayers++;
        }
    }
    
    if (validPlayers > 0) {
        PrintToConsole(client, "  平均延迟: %d ms", totalPing / validPlayers);
    }
    
    PrintToConsole(client, "  真实玩家: %d", validPlayers);
    PrintToConsole(client, "  BOT数量: %d", g_ServerStatus.playerCount - validPlayers);
    PrintToConsole(client, "");
    PrintToConsole(client, "========================================");
    
    if (client > 0) {
        ReplyToCommand(client, "[SM] 服务器详细信息已输出到控制台");
    }
    
    return Plugin_Handled;
}

// 命令：普通玩家查看状态
public Action Command_Status(int client, int args) {
    UpdateServerStatus();
    
    if (client == 0) {
        ReplyToCommand(client, "此命令只能在游戏中使用");
        return Plugin_Handled;
    }
    
    PrintToChat(client, " \x04[服务器状态]\x01 在线: \x03%d/%d\x01 | 地图: \x03%s\x01 | Tickrate: \x03%.0f", 
        g_ServerStatus.playerCount, 
        g_ServerStatus.maxPlayers, 
        g_ServerStatus.mapName, 
        g_ServerStatus.tickrate);
    
    PrintToChat(client, " \x04[性能]\x01 Var: \x03%.2f ms\x01 | CPU: \x03%.1f%%\x01 | 内存: \x03%.0f MB", 
        g_ServerStatus.serverVar, 
        g_ServerStatus.cpuUsage, 
        g_ServerStatus.memoryUsage);
    
    return Plugin_Handled;
}

// 命令：普通玩家查看玩家列表
public Action Command_Players(int client, int args) {
    if (client == 0) {
        ReplyToCommand(client, "此命令只能在游戏中使用");
        return Plugin_Handled;
    }
    
    UpdateAllPlayersInfo();
    
    PrintToChat(client, " \x04[在线玩家]\x01 共 \x03%d\x01 名玩家", g_ServerStatus.playerCount);
    
    for (int i = 1; i <= MaxClients; i++) {
        if (IsValidClient(i)) {
            char location[64];
            if (strlen(g_PlayerList[i].country) > 0) {
                Format(location, sizeof(location), " [%s]", g_PlayerList[i].country);
            } else {
                location = "";
            }
            
            PrintToChat(client, " \x03%s\x01 - %d/%d - %dms%s", 
                g_PlayerList[i].name,
                g_PlayerList[i].score,
                g_PlayerList[i].deaths,
                g_PlayerList[i].ping,
                location);
        }
    }
    
    return Plugin_Handled;
}

// 获取服务器方差
float GetServerVar() {
    // 这是一个简化的实现，实际需要通过ConVar获取
    ConVar sv_var = FindConVar("sv_var");
    if (sv_var != null) {
        return sv_var.FloatValue * 1000.0; // 转换为毫秒
    }
    return 0.0;
}

// 获取CPU使用率（需要系统扩展）
float GetCPUUsage() {
    // 这需要额外的扩展支持，这里返回模拟值
    // 实际实现需要使用System2扩展或类似工具
    ConVar host_cpu_usage = FindConVar("host_cpu_usage");
    if (host_cpu_usage != null) {
        return host_cpu_usage.FloatValue;
    }
    return 0.0;
}

// 获取内存使用（需要系统扩展）
float GetMemoryUsage() {
    // 这需要额外的扩展支持，这里返回模拟值
    // 实际实现需要使用System2扩展或类似工具
    ConVar host_mem_usage = FindConVar("host_mem_usage");
    if (host_mem_usage != null) {
        return host_mem_usage.FloatValue;
    }
    return 0.0;
}

// 验证客户端有效性
bool IsValidClient(int client) {
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}
