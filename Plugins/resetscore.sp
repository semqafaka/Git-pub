
/* Создан и профиксен специально для серверов Атомик */

#include <sourcemod>
#include <sdktools>

#define PLUGIN_AUTHOR	"semqa :3"
#define PLUGIN_VERSION	"1.0.3"
#pragma semicolon 1

Handle gPluginEnabled = INVALID_HANDLE;

public Plugin myinfo =
{
	name = "Обнулятор",
	author = PLUGIN_AUTHOR,
	description = "plugin special fixed for ATOMIC servers",
	version = PLUGIN_VERSION,
	url = "www.vk.com/atomic26"
};
public OnPluginStart()
{
	RegConsoleCmd( "say", CommandSay );
	RegConsoleCmd( "say_team", CommandSay );
	
	gPluginEnabled = CreateConVar( "sm_resetscore", "1" );  //Включение, отключение resetscore. 1-вкл,0-откл.
	CreateConVar( "resetscore_version", PLUGIN_VERSION, "Reset Score", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
}
public Action CommandSay( id, args )
{
	char Said[ 128 ];
	GetCmdArgString( Said, sizeof( Said ) - 1 );
	StripQuotes( Said );
	TrimString( Said );
	
	if( StrEqual( Said, "!resetscore" ) || StrEqual( Said, "!restartscore" ) || StrEqual( Said, "!rs" ) || StrEqual( Said, "!кы" ) || StrEqual( Said, "!куыуеысщку" ) || StrEqual( Said, "rs" ) || StrEqual( Said, "кы" )  )
	{
		if( GetConVarInt( gPluginEnabled ) == 0 )
		{
			PrintToChat( id, "\x07FFFFFF[Обнулятор] \x0700FF00Плагин отключен!" );
			PrintToConsole( id, "\x07FFFFFF[Обнулятор] \x0700FF00Вы не можете использовать эту команду т.к. плагин отключен!" );
		
			return Plugin_Continue;
		}

		if( GetClientDeaths( id ) == 0 && GetClientFrags( id ) == 0 )
		{
			PrintToChat( id, "\x07FFFFFF[Обнулятор] \x0700FF00Ваш счет и так равен 0!" );
			PrintToConsole( id, "\x07FFFFFF[Обнулятор] \x07FF0000Вы не можете сейчас обнулить счет" );
			
			return Plugin_Continue;
		}
				
		SetClientFrags( id, 0 );
		SetClientDeaths( id, 0 );
	
		char Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );
	
		PrintToChat( id, "\x07FFFFFF[Обнулятор] \x07FF0000Твой счет сброшен!" );
		PrintToChatAll( "\x07FFFFFF[Обнулятор] \x07FF0000\x04%s обнулил свой счет.", Name );
		PrintToConsole( id, "\x07FFFFFF[Обнулятор] \x07FF0000Ваш счет сброшен." );
	}
	
	return Plugin_Continue;
}	 
stock SetClientFrags( index, frags )
{
	SetEntProp( index, Prop_Data, "m_iFrags", frags );
	return 1;
}
stock SetClientDeaths( index, deaths )
{
	SetEntProp( index, Prop_Data, "m_iDeaths", deaths );
	return 1;
}
