#include <sourcemod>

new Handle:g_hSQL = INVALID_HANDLE;
new g_iSQLReconnectCounter;
new String:sql_selectMaps[] = "SELECT map FROM mapzone WHERE type = 0 GROUP BY map ORDER BY map;";

public Plugin:myinfo = 
{
	name = "[Timer] Maplist Helper",
	author = "Zipcore",
	description = "Re-writes maplist.txt and mapcycle.txt with valid maps",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	RegAdminCmd("sm_maplist_rewrite", Cmd_Rewrite, ADMFLAG_BAN);
	
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
}

public OnMapStart()
{
	if (g_hSQL == INVALID_HANDLE)
	{
		ConnectSQL();
	}
}

public Action:Cmd_Rewrite(client, args)
{
	ReWriteMaplist();
	return Plugin_Handled;
}

ConnectSQL()
{
	if (g_hSQL != INVALID_HANDLE)
	{
		CloseHandle(g_hSQL);
	}

	g_hSQL = INVALID_HANDLE;

	if (SQL_CheckConfig("timer"))
	{
		SQL_TConnect(ConnectSQLCallback, "timer");
	}
	else
	{
		SetFailState("PLUGIN STOPPED - Reason: no config entry found for 'timer' in databases.cfg - PLUGIN STOPPED");
	}
}

public ConnectSQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (g_iSQLReconnectCounter >= 5)
	{
		PrintToServer("PLUGIN STOPPED - Reason: reconnect counter reached max - PLUGIN STOPPED");
		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		PrintToServer("Connection to SQL database has failed, Reason: %s", error);
		g_iSQLReconnectCounter++;
		ConnectSQL();
		return;
	}
	g_hSQL = CloneHandle(hndl);
	
	g_iSQLReconnectCounter = 1;
}

public ReWriteMaplist()
{
	decl String:Query[255];
	Format(Query, 255, sql_selectMaps);
	SQL_TQuery(g_hSQL, SQL_CountMapCallback, Query, false);
}

public SQL_CountMapCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		return;
	}
	
	if(SQL_GetRowCount(hndl))
	{
		decl String:path[PLATFORM_MAX_PATH];
		decl String:path2[PLATFORM_MAX_PATH];
		Format(path, sizeof(path), "maplist.txt");
		Format(path2, sizeof(path2), "mapcycle.txt");
		new Handle:hfile = OpenFile(path, "w");
		new Handle:hfile2 = OpenFile(path2, "w");
		
		decl String:sMap[128];
		
		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, sMap, sizeof(sMap));
			WriteFileLine(hfile, sMap);
			WriteFileLine(hfile2, sMap);
		}
		
		CloseHandle(hfile);
		CloseHandle(hfile2);
	}
}