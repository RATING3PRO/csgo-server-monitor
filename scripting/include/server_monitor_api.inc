/**
 * CSGO Server Monitor API
 * 
 * 提供给其他插件调用的接口
 */

#if defined _server_monitor_included
    #endinput
#endif
#define _server_monitor_included

/**
 * 获取服务器基础状态
 * 
 * @param playerCount   输出：当前在线玩家数
 * @param maxPlayers    输出：服务器最大玩家数
 * @param mapName       输出：当前地图名称
 * @param mapNameSize   地图名称缓冲区大小
 * @param tickrate      输出：服务器Tickrate
 * @return              成功返回true，失败返回false
 */
native bool Monitor_GetServerStatus(int &playerCount, int &maxPlayers, char[] mapName, int mapNameSize, float &tickrate);

/**
 * 获取服务器性能指标
 * 
 * @param serverVar     输出：服务器方差（毫秒）
 * @param cpuUsage      输出：CPU使用率（百分比）
 * @param memoryUsage   输出：内存使用量（MB）
 * @return              成功返回true，失败返回false
 */
native bool Monitor_GetPerformance(float &serverVar, float &cpuUsage, float &memoryUsage);

/**
 * 获取玩家地理位置信息
 * 
 * @param client        玩家索引
 * @param country       输出：国家名称
 * @param countrySize   国家名称缓冲区大小
 * @param city          输出：城市名称
 * @param citySize      城市名称缓冲区大小
 * @return              成功返回true，失败返回false
 */
native bool Monitor_GetPlayerLocation(int client, char[] country, int countrySize, char[] city, int citySize);

/**
 * 获取玩家网络信息
 * 
 * @param client        玩家索引
 * @param ping          输出：玩家延迟（毫秒）
 * @param ipAddress     输出：IP地址
 * @param ipSize        IP地址缓冲区大小
 * @return              成功返回true，失败返回false
 */
native bool Monitor_GetPlayerNetwork(int client, int &ping, char[] ipAddress, int ipSize);

/**
 * 获取玩家游戏统计
 * 
 * @param client        玩家索引
 * @param score         输出：击杀数
 * @param deaths        输出：死亡数
 * @param connectTime   输出：连接时长（秒）
 * @return              成功返回true，失败返回false
 */
native bool Monitor_GetPlayerStats(int client, int &score, int &deaths, float &connectTime);

/**
 * 强制更新服务器状态
 * 立即更新所有监控数据，不等待定时器
 * 
 * @return              成功返回true，失败返回false
 */
native bool Monitor_ForceUpdate();

/**
 * 获取在线真实玩家数量（不包括BOT）
 * 
 * @return              真实玩家数量
 */
native int Monitor_GetRealPlayerCount();

/**
 * 检查玩家是否来自指定国家
 * 
 * @param client        玩家索引
 * @param countryCode   国家代码（如 "CN", "US", "JP"）
 * @return              是返回true，否返回false
 */
native bool Monitor_IsPlayerFromCountry(int client, const char[] countryCode);

/**
 * 获取服务器平均延迟
 * 
 * @return              平均延迟（毫秒），如果没有玩家返回0
 */
native int Monitor_GetAveragePing();

/**
 * 当服务器状态更新时触发
 * 
 * @param playerCount   当前玩家数
 * @param tickrate      当前Tickrate
 */
forward void OnServerStatusUpdated(int playerCount, float tickrate);

/**
 * 当玩家信息更新时触发
 * 
 * @param client        玩家索引
 * @param ping          玩家延迟
 */
forward void OnPlayerInfoUpdated(int client, int ping);

/**
 * 当检测到服务器性能异常时触发
 * 
 * @param type          异常类型：1=高延迟, 2=高CPU, 3=高内存
 * @param value         异常值
 */
forward void OnPerformanceWarning(int type, float value);

public SharedPlugin __pl_server_monitor = {
    name = "server_monitor",
    file = "server_monitor.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_server_monitor_SetNTVOptional() {
    MarkNativeAsOptional("Monitor_GetServerStatus");
    MarkNativeAsOptional("Monitor_GetPerformance");
    MarkNativeAsOptional("Monitor_GetPlayerLocation");
    MarkNativeAsOptional("Monitor_GetPlayerNetwork");
    MarkNativeAsOptional("Monitor_GetPlayerStats");
    MarkNativeAsOptional("Monitor_ForceUpdate");
    MarkNativeAsOptional("Monitor_GetRealPlayerCount");
    MarkNativeAsOptional("Monitor_IsPlayerFromCountry");
    MarkNativeAsOptional("Monitor_GetAveragePing");
}
#endif
