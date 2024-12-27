#include <sourcemod>
#include <sdktools>
#include <neotokyo>

#pragma semicolon 1
#pragma newdecls required

Database hDB = null;
char g_mapName[64];
char g_hostIP[32];
char g_hostName[64];

public Plugin myinfo = {
	name = "NT win tracker",
	description = "Stores winning team and final scores for casual games into a database",
	author = "bauxite",
	version = "0.3.0",
	url = "https://github.com/bauxiteDYS/SM-NT-Win-Tracker",
};

public void OnConfigsExecuted()
{
	char ip[20];
	char port[10];
	
	FindConVar("hostname").GetString(g_hostName, sizeof(g_hostName));
	FindConVar("ip").GetString(ip, sizeof(ip));
	FindConVar("hostport").GetString(port, sizeof(port));
	Format(g_hostIP, sizeof(g_hostIP), "%s:%s", ip, port);
	
	GetCurrentMap(g_mapName, sizeof(g_mapName));
	
	Database.Connect(DB_Connect); // default connection I guess
}

public void OnMapEnd()
{
	int winlimit = FindConVar("neo_score_limit").IntValue;
	int jinScore = GetTeamScore(TEAM_JINRAI);
	int nsfScore = GetTeamScore(TEAM_NSF);
	
	if(jinScore >= winlimit && jinScore > nsfScore)
	{
		DB_insertScore(TEAM_JINRAI, jinScore, nsfScore);
	} 
	else if (nsfScore >= winlimit && nsfScore > jinScore)
	{
		DB_insertScore(TEAM_NSF, jinScore, nsfScore);
	}
	else if (nsfScore > winlimit || jinScore > winlimit)
	{
		LogError("[NT Win Tracker] Error: Couldn't determine winning team, not inserting score");
	}
	else if (nsfScore < winlimit && jinScore < winlimit)
	{
		LogMessage("[NT Win Tracker] Map ended before winlimit reached, not inserting score");
	}
}

public void DB_Connect(Database db, const char[] error, any data)
{
	if (db == null)
	{
		SetFailState("[NT Win Tracker] Database connection failure: %s", error);
	} 
	else 
	{
		hDB = db;
		DB_init();
	}
}

void DB_init()
{
	char query[512];
	Transaction txn;
	txn = SQL_CreateTransaction();

	hDB.Format(query, sizeof(query), 
	"\
	CREATE TABLE IF NOT EXISTS nt_win_tracker \
	(\
	matchNumber INT UNSIGNED AUTO_INCREMENT PRIMARY KEY, \
	timeStamp INT NOT NULL, \
	hostIP VARCHAR(32) NOT NULL, \
	hostName VARCHAR(65) NOT NULL, \
	mapName VARCHAR(65) NOT NULL, \
	winTeam INT NOT NULL, \
	jinScore INT NOT NULL, \
	nsfScore INT NOT NULL  \
	);\
	");
	
	txn.AddQuery(query);
	hDB.Execute(txn, TxnSuccess_Init, TxnFailure_Init);
}

void TxnSuccess_Init(Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
    PrintToServer("[NT Win Tracker] SQL Database init succesful");
}

void TxnFailure_Init(Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
    SetFailState("[NT Win Tracker] SQL Error Database init failure: [%d] %s", failIndex, error);
}

void DB_insertScore(int winTeam, int jinScore, int nsfScore)
{	
	int timeStamp = GetTime();
	char newQuery[512];
	
	char defQuery[] = 	
	"\
	INSERT INTO nt_win_tracker(timeStamp, hostIP, hostName, mapName, winTeam, jinScore, nsfScore) \
	VALUES (%d, '%s', '%s', '%s', %d, %d, %d);\
	";
	
	hDB.Format(newQuery, sizeof(newQuery), defQuery, timeStamp, g_hostIP, g_hostName, g_mapName, winTeam, jinScore, nsfScore);
	hDB.Query(DB_insert_callback, newQuery, _, DBPrio_Normal);
}

void DB_insert_callback(Database db, DBResultSet results, const char[] error, any data)
{
    if (!db || !results || error[0])
    {
        LogError("[NT Win Tracker] SQL Error: %s", error);
    }
	else
	{
		PrintToServer("[NT Win Tracker] SQL insert was succesful");
	}
}
