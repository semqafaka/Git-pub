#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "semqa"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "say admin",
	author = PLUGIN_AUTHOR,
	description = "Возможность писать админам с флагом KICK",
	version = PLUGIN_VERSION,
	url = "forum.at-ik.ru"
};

char Col[8][10]={"\x07FFF000", "\x07FFFFFF", "\x0700FF00", "\x07FF0000", "\x0797FD78", "\x0797FD78", "\x07FF0000", "\x0797FD78"}; //\x07%

Handle at_h_kick;
bool at_b_kick;

public OnPluginStart(){
	AddCommandListener(Command_Changeteam, "say");
	AddCommandListener(Command_Changeteam, "say_team");
	

	at_h_kick		= CreateConVar("at_admin_msg",	"1",	"Включить возможность писать от имени Админа (начинайте сообщение со знака *, доступно только админу с флагом KICK)", _, true, 0.0, true, 1.0);
	at_b_kick 		= GetConVarBool(at_h_kick);
	AutoExecConfig(true, "at_admin_msg");
}

public Action:Command_Changeteam(client, const String:command[], args)
{
	decl String:Said[254];
	GetCmdArgString(Said, sizeof(Said) - 1);
	StripQuotes(Said);
	TrimString(Said);
	
	if (client > 0)
		{
			if(IsFakeClient(client))  
	 		return Plugin_Handled;
				
			if((Said[0] == '*') && at_b_kick)
			{
				if (GetUserFlagBits(client) & ADMFLAG_KICK){
					ReplaceString(Said,sizeof(Said), "*", "");
					PrintToChatAll("%s АДМИН: %s", Col[3], Said);
					PrintCenterTextAll("АДМИН: %s", Said);
					return Plugin_Handled;
				}
			}
		}
	return Plugin_Continue;
}