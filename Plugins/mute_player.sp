// Этот плагин создан специально для серверов Атомик
// Наша оффициальная группа Вконтакте vk.com/atomic26

#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>
#include <sdktools_voice>

public Plugin:myinfo = 
{
	name	= "Мут чата/микрофона",
	author	= "semqa :3",
	version	= "1.2.1"
};

Handle KV;
Handle MyUnMuteTimer[MAXPLAYERS+1];
bool chat_muted[MAXPLAYERS+1];

new const String:MutType[4][] = 
{
	"",
	"чат",
	"микрофон",
	"чат + микрофон"
};

public OnPluginStart()
{
	KV = CreateKeyValues(		"mute_player");
	FileToKeyValues(KV,			"/addons/sourcemod/configs/mute_player.cfg");

	RegConsoleCmd("say",		say);
	RegConsoleCmd("say_team",	say);
	RegAdminCmd("mute_add",		mute_add,		ADMFLAG_ROOT);
	RegAdminCmd("mute_del",		mute_del,		ADMFLAG_ROOT);
	RegAdminCmd("mute_del_all",	mute_del_all,	ADMFLAG_ROOT);
	RegAdminCmd("mute_list",	mute_list,		ADMFLAG_ROOT);
}

public OnPluginEnd() KeyValuesToFile(KV, "/addons/sourcemod/configs/mute_player.cfg");
public OnMapEnd() KeyValuesToFile(KV, "/addons/sourcemod/configs/mute_player.cfg");


public Action:mute_add(client, args)
{
	if (args != 3)
	{
		ReplyToCommand(client, "mute_add <userid/steamid> <0=навсегда/мин> <1=чат/2=микрофон/3=чат+микрофон>");
		return Plugin_Handled;
	}
	decl String:SteaM[25]; GetCmdArg(1, SteaM, 25);
	new target = StringToInt(SteaM);
	if (target > 0)
	{
		if ((target = GetClientOfUserId(target)) < 1)
		{
			ReplyToCommand(client, "Игрок с userid \"%s\" не найден", SteaM);
			return Plugin_Handled;
		}
		SteaM[0] = '\0'; 
		GetClientAuthId(target,AuthId_Steam2,SteaM, 25);
	}
	if (StrContains(SteaM, "STEAM_") != 0)
	{
		ReplyToCommand(client, "Неверный steamid: \"%s\"", SteaM);
		return Plugin_Handled;
	}
	decl String:value[15];

	// type
	GetCmdArg(3, value, 15);
	new type = StringToInt(value);
	if (type < 1 || type > 3)
	{
		ReplyToCommand(client, "Неверный тип мута: \"%s\"", value);
		return Plugin_Handled;
	}

	// time
	GetCmdArg(2, value, 15);
	new time = StringToInt(value);
	KvJumpToKey(KV, SteaM, true);
	KvSetNum(KV, "type",  type);
	if (time > 0) KvSetNum(KV, "time",  time * 60 + GetTime());
	else KvSetNum(KV, "time",  0);
	KvRewind(KV);
	if (target > 0)
	{
		MutePlayer(target, type);//
		if (time > 0)
		{
			KillUnMuteTimer(target);//
			MyUnMuteTimer[target] = CreateTimer(float(time*60), MyUnMuteTimer_CallBack, target);
			PrintToChatAll("\x04[ Мут-лист ] %N получил мут на %s мин", target, value);
		}
		else
			PrintToChatAll("\x04[ Мут-лист ] %N получил вечный мут", target);
	}
	else
	{
		decl String:x_steam[25];
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientAuthId(i,AuthId_Steam2, x_steam, 25) && strcmp(x_steam, SteaM) == 0)
			{
				MutePlayer(i, type);//

				if (time > 0)
				{
					KillUnMuteTimer(i);//
					MyUnMuteTimer[i] = CreateTimer(float(time*60), MyUnMuteTimer_CallBack, i);
					PrintToChatAll("\x04[ Мут-лист ] %N получил мут на %s мин", i, value);
				}
				else
					PrintToChatAll("\x04[ Мут-лист ] %N получил вечный мут", i);

				break;
			}
		}
	}
	ReplyToCommand(client, "Мут успешно выдан");
	return Plugin_Handled;
}


///


public Action:mute_del(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "mute_del <userid/steamid>");
		return Plugin_Handled;
	}

	decl String:SteaM[25]; GetCmdArg(1, SteaM, 25);
	new target = StringToInt(SteaM);
	if (target > 0)
	{
		if ((target = GetClientOfUserId(target)) < 1)
		{
			ReplyToCommand(client, "Игрок с userid \"%s\" не найден", SteaM);
			return Plugin_Handled;
		}
		SteaM[0] = '\0'; GetClientAuthId(target,AuthId_Steam2, SteaM, 25);
	}

	if (StrContains(SteaM, "STEAM_") != 0)
		ReplyToCommand(client, "Неверный steamid: \"%s\"", SteaM);
	
	else if (KvJumpToKey(KV, SteaM, false))
	{
		KvDeleteThis(KV);
		KvRewind(KV);
	// СЮДА 	ReplyToCommand(client, "Мут снят");
		UnMuteSteaM(SteaM);//
	}
	else
		ReplyToCommand(client, "Его нет в базе");

	return Plugin_Handled;
}


///


public Action:mute_del_all(client, args)
{
	if (!KvGotoFirstSubKey(KV, true))
	{
		PrintToConsole(client, "База и так пуста");
		return Plugin_Handled;
	}

	CloseHandle(KV);
	KV = CreateKeyValues("mute_player");
	KeyValuesToFile(KV, "addons/sourcemod/configs/mute_player.txt");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			KillUnMuteTimer(i);//
			chat_muted[i] = false;
			SetClientListeningFlags(i, VOICE_NORMAL);
		}
	}
	PrintToConsole(client, "База очищена (все муты удалены)");

	return Plugin_Handled;
}


///


public Action:mute_list(client, args)
{
	if (!KvGotoFirstSubKey(KV, true))
	{
		PrintToConsole(client, "Мутов нет");
		return Plugin_Handled;
	}
	new x = 0, time, type, world_time = GetTime(), H, M, S;
	decl String:SteaM[25];
	do
	{
		if (!KvGetSectionName(KV, SteaM, 25))
			continue;

		time = KvGetNum(KV, "time");
		type = KvGetNum(KV, "type");
		if (time < 1)
		{
			PrintToConsole(client, "%02d. %s (%s) | вечный мут", ++x, SteaM, MutType[type]);
		}
		else
		{
			time -= world_time;
			H = time / 3600;
			M = (time % 3600) / 60;
			S = time % 60;
			if (S > -1) PrintToConsole(client, "%02d. %s (%s) | до снятия мута: %d:%02d:%02d", ++x, SteaM, MutType[type], H, M, S);
			else PrintToConsole(client, "%02d. %s (%s) | мут снят (время истекло)", ++x, SteaM, MutType[type]);
		}
	}
	while (KvGotoNextKey(KV, true));
	KvRewind(KV);
	return Plugin_Handled;
}


///


public Action:say(client, args)
{
	if (chat_muted[client] && client > 0) return Plugin_Handled;
	return Plugin_Continue;
}

MutePlayer(client, mut_type)//
{
	if (mut_type != 2) chat_muted[client] = true;
	if (mut_type != 1) SetClientListeningFlags(client, VOICE_MUTED);
}

UnMuteSteaM(const String:SteaM[])//
{
	decl String:x_steam[25];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientAuthId(i,AuthId_Steam2, x_steam, 25) && strcmp(x_steam, SteaM) == 0)
		{
			KillUnMuteTimer(i);//
			chat_muted[i] = false;
			SetClientListeningFlags(i, VOICE_NORMAL);
			PrintToChat(i, "\x04[ Мут-лист ] %N, с вас снят мут", i);
		}
	}
}


///


public Action:MyUnMuteTimer_CallBack(Handle:timer, any:client)
{
	MyUnMuteTimer[client] = INVALID_HANDLE;
	decl String:SteaM[25];
	if (GetClientAuthId(client,AuthId_Steam2, SteaM, 25) && KvJumpToKey(KV, SteaM))
	{
		new type = KvGetNum(KV, "type");
		KvDeleteThis(KV);
		KvRewind(KV);
		if (type == 1) chat_muted[client] = false;
		else if (type == 2) SetClientListeningFlags(client, VOICE_NORMAL);
		else
		{
			chat_muted[client] = false;
			SetClientListeningFlags(client, VOICE_NORMAL);
		}
		PrintToChat(client, "\x04[ Мут-лист ] %N, с вас снят мут", client);
	}
	return Plugin_Stop;
}


///


public OnClientPutInServer(client)
{
	chat_muted[client] = false;

	if (IsFakeClient(client))
		return;

	decl String:SteaM[25];
	if (!GetClientAuthId(client,AuthId_Steam2, SteaM, 25) || !KvJumpToKey(KV, SteaM))
		return;

	new time = KvGetNum(KV, "time");
	new type = KvGetNum(KV, "type");
	if (time != 0)
	{
		time -= GetTime();
		if (time < 1)
		{
			KvDeleteThis(KV);
			KvRewind(KV);
			return;
		}
		MyUnMuteTimer[client] = CreateTimer(float(time), MyUnMuteTimer_CallBack, client);
	}
	KvRewind(KV);
	MutePlayer(client, type);//
}


///


public OnClientDisconnect(client)
{
	KillUnMuteTimer(client);//
}

KillUnMuteTimer(client)//
{
	if (MyUnMuteTimer[client] != INVALID_HANDLE)
	{
		KillTimer(MyUnMuteTimer[client]);
		MyUnMuteTimer[client] = INVALID_HANDLE;
	}
}