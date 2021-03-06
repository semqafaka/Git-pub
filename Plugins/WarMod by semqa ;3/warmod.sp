#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#include <warmod>
#undef REQUIRE_PLUGIN
#include <adminmenu>

/* player info */
new g_player_list[MAXPLAYERS + 1];
new bool:g_cancel_list[MAXPLAYERS + 1];
new String:user_damage[MAXPLAYERS + 1][DMG_MSG_SIZE];

new g_scores[2][2];
new g_scores_overtime[2][256][2];
new g_overtime_count = 0;

new g_i_ragdolls = -1;
new g_i_account = -1;
new g_i_frags = -1;

/* miscellaneous */
new String:g_map[64];
new Float:g_match_start;

/* stats */
new bool:g_log_warmod_dir = false;
new String:g_log_filename[128];
new Handle:g_log_file = INVALID_HANDLE;
new String:weapon_list[][] =
{"ak47","m4a1","awp","deagle","mp5navy","aug","p90","famas","galil","scout","g3sg1","hegrenade","usp", "glock","m249","m3","elite","fiveseven","mac10","p228","sg550","sg552","tmp","ump45","xm1014","knife","smokegrenade","flashbang"};
new weapon_stats[MAXPLAYERS + 1][NUM_WEAPONS][LOG_HIT_NUM];
new clutch_stats[MAXPLAYERS + 1][CLUTCH_NUM];
new String:last_weapon[MAXPLAYERS + 1][64];
new bool:g_planted = false;
new Handle:g_stats_trace_timer = INVALID_HANDLE;

/* forwards */
new Handle:g_f_on_lo3 = INVALID_HANDLE;
new Handle:g_f_on_half_time = INVALID_HANDLE;
new Handle:g_f_on_reset_half = INVALID_HANDLE;
new Handle:g_f_on_reset_match = INVALID_HANDLE;
new Handle:g_f_on_end_match = INVALID_HANDLE;

/* cvars */
new Handle:g_h_force_camera = INVALID_HANDLE;
new Handle:g_h_fade_to_black = INVALID_HANDLE;
new Handle:g_h_active = INVALID_HANDLE;
new Handle:g_h_stats_enabled = INVALID_HANDLE;
new Handle:g_h_stats_method = INVALID_HANDLE;
new Handle:g_h_stats_trace_enabled = INVALID_HANDLE;
new Handle:g_h_stats_trace_delay = INVALID_HANDLE;
new Handle:g_h_rcon_only = INVALID_HANDLE;
new Handle:g_h_global_chat = INVALID_HANDLE;
new Handle:g_h_locked = INVALID_HANDLE;
new Handle:g_h_min_ready = INVALID_HANDLE;
new Handle:g_h_max_players = INVALID_HANDLE;
new Handle:g_h_match_config = INVALID_HANDLE;
new Handle:g_h_live_config = INVALID_HANDLE;
new Handle:g_h_knife_config = INVALID_HANDLE;
new Handle:g_h_end_config = INVALID_HANDLE;
new Handle:g_h_round_money = INVALID_HANDLE;
new Handle:g_h_night_vision = INVALID_HANDLE;
new Handle:g_h_bomb_frags = INVALID_HANDLE;
new Handle:g_h_defuse_frags = INVALID_HANDLE;
new Handle:g_h_ingame_scores = INVALID_HANDLE;
new Handle:g_h_max_rounds = INVALID_HANDLE;
new Handle:g_h_warm_up_grens = INVALID_HANDLE;
new Handle:g_h_knife_hegrenade = INVALID_HANDLE;
new Handle:g_h_knife_flashbang = INVALID_HANDLE;
new Handle:g_h_knife_smokegrenade = INVALID_HANDLE;
new Handle:g_h_req_names = INVALID_HANDLE;
new Handle:g_h_show_info = INVALID_HANDLE;
new Handle:g_h_live_override = INVALID_HANDLE;
new Handle:g_h_live_override_knife = INVALID_HANDLE;
new Handle:g_h_auto_ready = INVALID_HANDLE;
new Handle:g_h_auto_swap = INVALID_HANDLE;
new Handle:g_h_auto_swap_delay = INVALID_HANDLE;
new Handle:g_h_half_auto_ready = INVALID_HANDLE;
new Handle:g_h_auto_knife = INVALID_HANDLE;
new Handle:g_h_auto_kick_team = INVALID_HANDLE;
new Handle:g_h_auto_kick_delay = INVALID_HANDLE;
new Handle:g_h_score_mode = INVALID_HANDLE;
new Handle:g_h_overtime = INVALID_HANDLE;
new Handle:g_h_overtime_mr = INVALID_HANDLE;
new Handle:g_h_overtime_money = INVALID_HANDLE;
new Handle:g_h_auto_record = INVALID_HANDLE;
new Handle:g_h_save_file_dir = INVALID_HANDLE;
new Handle:g_h_prefix_logs = INVALID_HANDLE;
new Handle:g_h_play_out = INVALID_HANDLE;
new Handle:g_h_damage = INVALID_HANDLE;
new Handle:g_h_remove_hint_text = INVALID_HANDLE;
new Handle:g_h_remove_gren_sound = INVALID_HANDLE;
new Handle:g_h_body_delay = INVALID_HANDLE;
new Handle:g_h_body_remove = INVALID_HANDLE;
new Handle:g_h_deathcam_remove = INVALID_HANDLE;
new Handle:g_h_deathcam_delay = INVALID_HANDLE;
new Handle:g_h_warmup_respawn = INVALID_HANDLE;
new Handle:g_h_modifiers = INVALID_HANDLE;
new Handle:g_h_status = INVALID_HANDLE;
new Handle:g_h_upload_results = INVALID_HANDLE;
new Handle:g_h_table_name = INVALID_HANDLE;
new Handle:g_h_t = INVALID_HANDLE;
new Handle:g_h_ct = INVALID_HANDLE;
new Handle:g_h_notify_version = INVALID_HANDLE;
new Handle:g_h_t_score = INVALID_HANDLE;
new Handle:g_h_ct_score = INVALID_HANDLE;

new Handle:g_h_mp_startmoney = INVALID_HANDLE;

/* ready system */
new Handle:g_m_ready_up = INVALID_HANDLE;
new bool:g_ready_enabled = false;

/* switches */
new bool:g_active = true;
new bool:g_match = false;
new bool:g_live = false;
new bool:g_playing_out = false;
new bool:g_first_half = true;
new bool:g_overtime = false;
new bool:g_t_money = false;
new bool:g_t_score = false;
new bool:g_t_knife = true;
new bool:g_t_had_knife = false;
new bool:round_end = false;

/* modes */
new g_overtime_mode = 0;

/* teams */
new String:g_t_name[64];
new String:g_ct_name[64];

/* admin menu */
new Handle:g_h_menu = INVALID_HANDLE;

/* database */
new Handle:wm_db = INVALID_HANDLE;

/* deathcam */
new Handle:g_deathcam_delays[MAXPLAYERS + 1] = INVALID_HANDLE;


public Plugin:myinfo = {
	name = "AtomMod",
	author = "semqa :3",
	description = WM_DESCRIPTION,
	version = WM_VERSION,
	url = "http://www.vk.com/atomic26"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("warmod");
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("warmod.phrases");
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
	g_f_on_lo3 = CreateGlobalForward("OnLiveOn3", ET_Ignore);
	g_f_on_half_time = CreateGlobalForward("OnHalfTime", ET_Ignore);
	g_f_on_reset_half = CreateGlobalForward("OnResetHalf", ET_Ignore);
	g_f_on_reset_match = CreateGlobalForward("OnResetMatch", ET_Ignore);
	g_f_on_end_match = CreateGlobalForward("OnEndMatch", ET_Ignore);


	RegConsoleCmd("score", ConsoleScore);
	RegConsoleCmd("wm_version", WMVersion);
	RegConsoleCmd("say", SayChat);
	RegConsoleCmd("say_team", SayTeamChat);
	RegConsoleCmd("buy", RestrictBuy);
	RegConsoleCmd("jointeam", ChooseTeam);
	RegConsoleCmd("spectate", ChooseTeam);
	RegConsoleCmd("wm_readylist", ReadyList);
	RegConsoleCmd("wmrl", ReadyList);
	RegConsoleCmd("wm_cash", AskTeamMoney);
	RegAdminCmd("notlive", NotLive, ADMFLAG_CUSTOM1, "Declares half not live and restarts the round");
	RegAdminCmd("nl", NotLive, ADMFLAG_CUSTOM1, "Declares half not live and restarts the round");
	RegAdminCmd("cancelhalf", NotLive, ADMFLAG_CUSTOM1, "Declares half not live and restarts the round");
	RegAdminCmd("ch", NotLive, ADMFLAG_CUSTOM1, "Declares half not live and restarts the round");
	RegAdminCmd("cancelmatch", CancelMatch, ADMFLAG_CUSTOM1, "Declares match not live and restarts round");
	RegAdminCmd("cm", CancelMatch, ADMFLAG_CUSTOM1, "Declares match not live and restarts round");
	RegAdminCmd("readyup", ReadyToggle, ADMFLAG_CUSTOM1, "Starts or stops the ReadyUp System");
	RegAdminCmd("ru", ReadyToggle, ADMFLAG_CUSTOM1, "Starts or stops the ReadyUp System");
	RegAdminCmd("t", ChangeT, ADMFLAG_CUSTOM1, "Team starting terrorists - Designed for score purposes");
	RegAdminCmd("ct", ChangeCT, ADMFLAG_CUSTOM1, "Team starting counter-terrorists - Designed for score purposes");
	RegAdminCmd("swap", SwapAll, ADMFLAG_CUSTOM1, "Swap all players to the opposite team");
	RegAdminCmd("pwd", ChangePassword, ADMFLAG_PASSWORD, "Set or display the sv_password console variable");
	RegAdminCmd("pw", ChangePassword, ADMFLAG_PASSWORD, "Set or display the sv_password console variable");
	RegAdminCmd("active", ActiveToggle, ADMFLAG_CUSTOM1, "Toggle the wm_active console variable");
	RegAdminCmd("minready", ChangeMinReady, ADMFLAG_CUSTOM1, "Set or display the wm_min_ready console variable");
	RegAdminCmd("maxrounds", ChangeMaxRounds, ADMFLAG_CUSTOM1, "Set or display the wm_max_rounds console variable");
	RegAdminCmd("knife", KnifeOn3, ADMFLAG_CUSTOM1, "Remove all weapons except knife and lo3");
	RegAdminCmd("ko3", KnifeOn3, ADMFLAG_CUSTOM1, "Remove all weapons except knife and lo3");
	RegAdminCmd("cancelknife", CancelKnife, ADMFLAG_CUSTOM1, "Declares knife not live and restarts round");
	RegAdminCmd("ck", CancelKnife, ADMFLAG_CUSTOM1, "Declares knife not live and restarts round");
	RegAdminCmd("forceallready", ForceAllReady, ADMFLAG_CUSTOM1, "Forces all players to become ready");
	RegAdminCmd("far", ForceAllReady, ADMFLAG_CUSTOM1, "Forces all players to become ready");
	RegAdminCmd("forceallunready", ForceAllUnready, ADMFLAG_CUSTOM1, "Forces all players to become unready");
	RegAdminCmd("faur", ForceAllUnready, ADMFLAG_CUSTOM1, "Forces all players to become unready");
	RegAdminCmd("lo3", ForceStart, ADMFLAG_CUSTOM1, "Starts the match regardless of player and ready count");
	RegAdminCmd("forcestart", ForceStart, ADMFLAG_CUSTOM1, "Starts the match regardless of player and ready count");
	RegAdminCmd("fs", ForceStart, ADMFLAG_CUSTOM1, "Starts the match regardless of player and ready count");
	RegAdminCmd("forceend", ForceEnd, ADMFLAG_CUSTOM1, "Ends the match regardless of status");
	RegAdminCmd("fe", ForceEnd, ADMFLAG_CUSTOM1, "Ends the match regardless of status");
	RegAdminCmd("readyon", ReadyOn, ADMFLAG_CUSTOM1, "Turns on or restarts the ReadyUp System");
	RegAdminCmd("ron", ReadyOn, ADMFLAG_CUSTOM1, "Turns on or restarts the ReadyUp System");
	RegAdminCmd("readyoff", ReadyOff, ADMFLAG_CUSTOM1, "Turns off the ReadyUp System if enabled");
	RegAdminCmd("roff", ReadyOff, ADMFLAG_CUSTOM1, "Turns off the ReadyUp System if enabled");

	g_h_active = CreateConVar("wm_active", "1", "Enable or disable WarMod as active", FCVAR_NOTIFY);
	g_h_stats_enabled = CreateConVar("wm_stats_enabled", "1", "Enable or disable statistical logging", FCVAR_NOTIFY);
	g_h_stats_method = CreateConVar("wm_stats_method", "2", "Sets the stats logging method: 0 = UDP stream/server logs, 1 = warmod logs, 2 = both", FCVAR_NOTIFY, true, 0.0);
	g_h_stats_trace_enabled = CreateConVar("wm_stats_trace", "0", "Enable or disable updating all player positions, every wm_stats_trace_delay seconds", FCVAR_NOTIFY);
	g_h_stats_trace_delay = CreateConVar("wm_stats_trace_delay", "5", "The ammount of time between sending player position updates", FCVAR_NOTIFY, true, 0.0);
	g_h_rcon_only = CreateConVar("wm_rcon_only", "0", "Enable or disable admin commands to be only executed via RCON or console");
	g_h_global_chat = CreateConVar("wm_global_chat", "1", "Enable or disable the global chat command (@ prefix in messagemode)");
	g_h_locked = CreateConVar("wm_lock_teams", "1", "Enable or disable locked teams when a match is running", FCVAR_NOTIFY);
	g_h_min_ready = CreateConVar("wm_min_ready", "10", "Sets the minimum required ready players to Live on 3", FCVAR_NOTIFY);
	g_h_max_players = CreateConVar("wm_max_players", "10", "Sets the maximum players allowed on both teams combined, others will be forced to spectator (0 = unlimited)", FCVAR_NOTIFY, true, 0.0);
	g_h_match_config = CreateConVar("wm_match_config", "warmod/ruleset_mr15.cfg", "Sets the match config to load on Live on 3");
	g_h_live_config = CreateConVar("wm_live_config", "warmod/on_match_lo3.cfg", "Sets the Live on 3 config");
	g_h_knife_config = CreateConVar("wm_knife_config", "warmod/on_match_ko3.cfg", "Sets the Knife on 3 config");
	g_h_end_config = CreateConVar("wm_reset_config", "warmod/on_match_end.cfg", "Sets the config to load at the end/reset of a match");
	g_h_round_money = CreateConVar("wm_round_money", "1", "Enable or disable a client's team mates money to be displayed at the start of a round (to him only)", FCVAR_NOTIFY);
	g_h_night_vision = CreateConVar("wm_block_nightvision", "1", "Enable or disable blocking nightvision", FCVAR_NOTIFY);
	g_h_bomb_frags = CreateConVar("wm_bomb_frags", "0", "Enable or disable a player getting 3 points for their bomb explosion", FCVAR_NOTIFY);
	g_h_defuse_frags = CreateConVar("wm_defuse_frags", "0", "Enable or disable a player getting 3 points for defusing the bomb", FCVAR_NOTIFY);
	g_h_ingame_scores = CreateConVar("wm_ingame_scores", "1", "Enable or disable ingame scores to be showed at the end of each round", FCVAR_NOTIFY);
	g_h_max_rounds = CreateConVar("wm_max_rounds", "15", "Sets maxrounds before auto team switch", FCVAR_NOTIFY);
	g_h_warm_up_grens = CreateConVar("wm_block_warm_up_grenades", "0", "Enable or disable grenade blocking in warmup", FCVAR_NOTIFY);
	g_h_knife_hegrenade = CreateConVar("wm_knife_hegrenade", "0", "Enable or disable giving a player a hegrenade on Knife on 3", FCVAR_NOTIFY);
	g_h_knife_flashbang = CreateConVar("wm_knife_flashbang", "0", "Sets how many flashbangs to give a player on Knife on 3", FCVAR_NOTIFY, true, 0.0, true, 2.0);
	g_h_knife_smokegrenade = CreateConVar("wm_knife_smokegrenade", "0", "Enable or disable giving a player a smokegrenade on Knife on 3", FCVAR_NOTIFY);
	g_h_req_names = CreateConVar("wm_require_names", "0", "Enable or disable the requirement of set team names for lo3", FCVAR_NOTIFY);
	g_h_show_info = CreateConVar("wm_show_info", "1", "Enable or disable the display of the Ready System to players", FCVAR_NOTIFY);
	g_h_live_override = CreateConVar("wm_live_override", "1", "Enable or disable the override of the execution of wm_live_config and instead uses it's own (wait command fix)", FCVAR_NOTIFY);
	g_h_live_override_knife = CreateConVar("wm_live_override_knife", "1", "Enable or disable the override of the execution of wm_knife_config and instead uses it's own (wait command fix)", FCVAR_NOTIFY);
	g_h_auto_ready = CreateConVar("wm_auto_ready", "1", "Enable or disable the ready system being automatically enabled on map change", FCVAR_NOTIFY);
	g_h_auto_swap = CreateConVar("wm_auto_swap", "1", "Enable or disable the automatic swapping of teams at half time", FCVAR_NOTIFY);
	g_h_auto_swap_delay = CreateConVar("wm_auto_swap_delay", "3", "Time to wait before swapping teams at half time", 0, true, 0.0);
	g_h_half_auto_ready = CreateConVar("wm_half_auto_ready", "1", "Enable or disable the ready system being automatically enabled at end of half", FCVAR_NOTIFY);
	g_h_auto_knife = CreateConVar("wm_auto_knife", "0", "Enable or disable the knife round before going live", FCVAR_NOTIFY);
	g_h_auto_kick_team = CreateConVar("wm_auto_kick_team", "0", "Enable or disable the automatic kicking of the losing team", FCVAR_NOTIFY);
	g_h_auto_kick_delay = CreateConVar("wm_auto_kick_delay", "10", "Sets the seconds to wait before kicking the losing team", FCVAR_NOTIFY, true, 0.0);
	g_h_score_mode = CreateConVar("wm_score_mode", "1", "Sets score mode: 1 = Best Of, 2 = First To (based on wm_max_rounds)", FCVAR_NOTIFY);
	g_h_overtime = CreateConVar("wm_overtime", "1", "Sets overtime mode: 0 = off, 1 = Maxrounds (based on wm_overtime_max_rounds), 2 = Sudden Death", FCVAR_NOTIFY);
	g_h_overtime_mr = CreateConVar("wm_overtime_max_rounds", "3", "Sets overtime maxrounds", FCVAR_NOTIFY, true, 0.0);
	g_h_overtime_money = CreateConVar("wm_overtime_start_money", "10000", "Sets overtime startmoney", FCVAR_NOTIFY, true, 0.0);
	g_h_auto_record = CreateConVar("wm_auto_record", "1", "Enable or disable auto SourceTV demo record on Live on 3", FCVAR_NOTIFY);
	g_h_save_file_dir = CreateConVar("wm_save_dir", "warmod", "Directory to store SourceTV demos and WarMod logs");
	g_h_prefix_logs = CreateConVar("wm_prefix_logs", "1", "Enable or disable the prefixing of \"_\" to uncompleted match SourceTV demos and WarMod logs", FCVAR_NOTIFY);
	g_h_play_out = CreateConVar("wm_play_out", "0", "Enable or disable teams required to play out the match even after a winner has been decided", FCVAR_NOTIFY);
	g_h_damage = CreateConVar("wm_damage", "1", "Sets player console damage mode: 0 = removed, 1 = on death, 2 = delayed until end of the round", FCVAR_NOTIFY);
	g_h_remove_hint_text = CreateConVar("wm_remove_help_hints", "1", "Enable or disable the removal of the help hints", FCVAR_NOTIFY);
	g_h_remove_gren_sound = CreateConVar("wm_remove_grenade_sound", "0", "Enable or disable the \"Fire in the Hole\" sound when throwing grenades", FCVAR_NOTIFY);
	g_h_body_remove = CreateConVar("wm_remove_ragdoll", "1", "Enable or disable the removal of ragdolls after wm_remove_ragdoll_delay seconds of time after death", FCVAR_NOTIFY);
	g_h_body_delay = CreateConVar("wm_remove_ragdoll_delay", "2", "The ammount of time to wait before removing corpses", FCVAR_NOTIFY, true, 0.0);
	g_h_deathcam_remove = CreateConVar("wm_remove_deathcam", "1", "Enable or disable the switching of views after wm_remove_deathcam_delay seconds of time after death", FCVAR_NOTIFY);
	g_h_deathcam_delay = CreateConVar("wm_remove_deathcam_delay", "1.4", "The ammount of time to wait before switching a players view after death", FCVAR_NOTIFY, true, 1.4);
	g_h_warmup_respawn = CreateConVar("wm_warmup_respawn", "0", "Enable or disable the respawning of players in warmup", FCVAR_NOTIFY);
	g_h_modifiers = CreateConVar("wm_modifiers", "1", "Enable or disable slight game modifiers (green RCON + short team_say)", FCVAR_NOTIFY);
	g_h_status = CreateConVar("wm_status", "0", "WarMod automatically updates this value to the corresponding match status code", FCVAR_NOTIFY);
	g_h_upload_results = CreateConVar("wm_upload_results", "0", "Enable or disable the uploading of match results via MySQL", FCVAR_NOTIFY);
	g_h_table_name = CreateConVar("wm_table_name", "wm_results", "The MySQL table name to store match results in");
	g_h_t = CreateConVar("wm_t", DEFAULT_T_NAME, "Team starting terrorists, designed for score and demo naming purposes", FCVAR_NOTIFY);
	g_h_ct = CreateConVar("wm_ct", DEFAULT_CT_NAME, "Team starting counter-terrorists, designed for score and demo naming purposes", FCVAR_NOTIFY);
	g_h_t_score = CreateConVar("wm_t_score", "0", "WarMod automatically updates this value to the Terrorist's total score", FCVAR_NOTIFY);
	g_h_ct_score = CreateConVar("wm_ct_score", "0", "WarMod automatically updates this value to the Counter-Terrorist's total score", FCVAR_NOTIFY);
	g_h_notify_version = CreateConVar("wm_notify_version", WM_VERSION, WM_DESCRIPTION, FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_h_mp_startmoney = FindConVar("mp_startmoney");
	g_i_account = FindSendPropOffs("CCSPlayer", "m_iAccount");
	g_i_ragdolls = FindSendPropOffs("CCSPlayer","m_hRagdoll");
	
	HookConVarChange(g_h_active, OnActiveChange);
	HookConVarChange(g_h_req_names, OnReqNameChange);
	HookConVarChange(g_h_min_ready, OnMinReadyChange);
	HookConVarChange(g_h_stats_trace_enabled, OnStatsTraceChange);
	HookConVarChange(g_h_stats_trace_delay, OnStatsTraceDelayChange);
	HookConVarChange(g_h_auto_ready, OnAutoReadyChange);
	HookConVarChange(g_h_max_rounds, OnMaxRoundChange);
	HookConVarChange(g_h_overtime_mr, OnMaxRoundChange);
	HookConVarChange(g_h_t, OnTChange);
	HookConVarChange(g_h_ct, OnCTChange);
	HookUserMessage(GetUserMessageId("HintText"), MessageHandler, true);
	HookUserMessage(GetUserMessageId("SendAudio"), MessageHandler, true);
	HookUserMessage(GetUserMessageId("TextMsg"), MessageHandler, true);
	HookEvent("round_start", Event_Round_Start);
	HookEvent("round_end", Event_Round_End);
	HookConVarChange(FindConVar("mp_restartgame"), Event_Round_Restart);
	HookEvent("round_freeze_end", Event_Round_Freeze_End);
	HookEvent("player_blind", Event_Player_Blind);
	HookEvent("player_hurt",  Event_Player_Hurt);
	HookEvent("player_death",  Event_Player_Death);
	HookEvent("player_changename", Event_Player_Name);
	HookEvent("player_connect", Event_Player_Connect);
	HookEvent("player_disconnect", Event_Player_Disc);
	HookEvent("player_team", Event_Player_Team);
	HookEvent("bomb_pickup", Event_Bomb_PickUp);
	HookEvent("bomb_dropped", Event_Bomb_Dropped);
	HookEvent("bomb_beginplant", Event_Bomb_Plant_Begin);
	HookEvent("bomb_abortplant", Event_Bomb_Plant_Abort);
	HookEvent("bomb_planted", Event_Bomb_Planted);
	HookEvent("bomb_exploded", Event_Bomb_Exploded);
	HookEvent("bomb_begindefuse", Event_Bomb_Defuse_Begin);
	HookEvent("bomb_abortdefuse", Event_Bomb_Defuse_Abort);
	HookEvent("bomb_defused", Event_Bomb_Defused);
	HookEvent("weapon_fire", Event_Weapon_Fire);
	HookEvent("flashbang_detonate", Event_Detonate_Flash);
	HookEvent("smokegrenade_detonate", Event_Detonate_Smoke);
	HookEvent("hegrenade_detonate", Event_Detonate_HeGrenade);
	HookEvent("item_pickup", Event_Item_Pickup);
	
	wm_db = MySQL_Connect();
	CreateTimer(15.0, HelpText, 0, TIMER_REPEAT);
	CreateTimer(15.0, CheckNames, 0, TIMER_REPEAT);
}

public OnMapStart()
{
	GetCurrentMap(g_map, sizeof(g_map));
	StringToLower(g_map, sizeof(g_map));
	SetConVarStringHidden(g_h_notify_version, WM_VERSION);
	if (GetConVarBool(g_h_stats_trace_enabled))
	{
		g_stats_trace_timer = CreateTimer(GetConVarFloat(g_h_stats_trace_delay), Stats_Trace, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	ResetMatch(true);
	ResetSwitchCameraTimers(false);
}

public OnMapEnd()
{
	ResetSwitchCameraTimers(false);
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		g_h_menu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_h_menu)
	{
		return;
	}
	g_h_menu = topmenu;
	new TopMenuObject:new_menu = AddToTopMenu(g_h_menu, "WarModCommands", TopMenuObject_Category, MenuHandler, INVALID_TOPMENUOBJECT);
	
	if (new_menu == INVALID_TOPMENUOBJECT)
	{
		return;
	}
	AddToTopMenu(g_h_menu, "forcestart", TopMenuObject_Item, MenuHandler, new_menu, "forcestart", ADMFLAG_CUSTOM1);
	AddToTopMenu(g_h_menu, "readyup", TopMenuObject_Item, MenuHandler, new_menu, "readyup", ADMFLAG_CUSTOM1);
	AddToTopMenu(g_h_menu, "knife", TopMenuObject_Item, MenuHandler, new_menu, "knife", ADMFLAG_CUSTOM1);
	AddToTopMenu(g_h_menu, "cancelhalf", TopMenuObject_Item, MenuHandler, new_menu, "cancelhalf", ADMFLAG_CUSTOM1);
	AddToTopMenu(g_h_menu, "cancelmatch", TopMenuObject_Item, MenuHandler, new_menu, "cancelmatch", ADMFLAG_CUSTOM1);
	AddToTopMenu(g_h_menu, "forceallready", TopMenuObject_Item, MenuHandler, new_menu, "forceallready", ADMFLAG_CUSTOM1);
	AddToTopMenu(g_h_menu, "forceallunready", TopMenuObject_Item, MenuHandler, new_menu, "forceallunready", ADMFLAG_CUSTOM1);
	AddToTopMenu(g_h_menu, "toggleactive", TopMenuObject_Item, MenuHandler, new_menu, "toggleactive", ADMFLAG_CUSTOM1);
}

public OnClientPutInServer(client)
{
	user_damage[client][0] = '\0';
	g_player_list[client] = PLAYER_DISC;
	g_cancel_list[client] = false;
}

public OnClientDisconnect(client)
{
	g_player_list[client] = PLAYER_DISC;
	g_cancel_list[client] = false;
	user_damage[client][0] = '\0';
	LogPlayerStats(client);
	if (!IsActive(client, true))
	{
		return;
	}
	if (g_ready_enabled && !g_live)
	{
		ShowInfo(client, true, false, 0);
	}
}

public Action:OnClientCommand(client, args)
{
	if (!IsActive(client, true))
	{
		return Plugin_Continue;
	}
	if (g_h_force_camera == INVALID_HANDLE)
	{
		g_h_force_camera = FindConVar("mp_forcecamera");
	}
	if (client > 0 && !IsFakeClient(client) && IsClientObserver(client) && GetClientTeam(client) > 1 && g_h_force_camera != INVALID_HANDLE && GetConVarInt(g_h_force_camera) == 1)
	{
		new String:arg[256];
		GetCmdArg(0, arg, sizeof(arg));
		if (StrEqual(arg, "spec_prev"))
		{
			if (GetNumAlive(GetClientTeam(client)) > 1)
			{
				SpecPrev(client);
			}
			return Plugin_Handled;
		}
		else if (StrEqual(arg, "spec_next"))
		{
			if (GetNumAlive(GetClientTeam(client)) > 1)
			{
				SpecNext(client);
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

ResetMatch(bool:silent)
{
	if (g_match)
	{
		Call_StartForward(g_f_on_reset_match);
		Call_Finish();
		if (GetConVarBool(g_h_stats_enabled))
		{
			Log2Game("\"match_reset\"");
		}
		new String:end_config[128];
		GetConVarString(g_h_end_config, end_config, sizeof(end_config));
		ServerCommand("exec %s", end_config);
	}
	if (g_log_file != INVALID_HANDLE)
	{
		CloseHandle(g_log_file);
		g_log_file = INVALID_HANDLE;
	}
	g_match = false;
	g_live = false;
	g_first_half = true;
	g_t_money = false;
	g_t_score = false;
	g_t_knife = false;
	g_t_had_knife = false;
	g_playing_out = false;
	SetAllCancelled(false);
	ReadyChangeAll(0, false, true);
	ResetMatchScores();
	ResetTeams();
	g_overtime = false;
	g_overtime_count = 0;
	UpdateStatus();
	CreateTimer(10.0, StopRecord);
	if (GetConVarBool(g_h_auto_ready))
	{
		ReadySystem(true);
		ShowInfo(0, true, false, 0);
		UpdateStatus();
	}
	else if (g_ready_enabled)
	{
		ReadySystem(false);
		ShowInfo(0, false, false, 1);
	}
	
	if (!silent)
	{
		for (new x = 1; x <= 3; x++)
		{
			PrintToChatAll("\x03<AtomMod> \x04%t", "Перезапуск матча");
		}
		ServerCommand("mp_restartgame 1");
	}
}

ResetHalf(bool:silent)
{
	if (g_match)
	{
		Call_StartForward(g_f_on_reset_half);
		Call_Finish();
		if (GetConVarBool(g_h_stats_enabled))
		{
			Log2Game("\"match_half_reset\"");
		}
	}
	
	g_live = false;
	g_t_money = false;
	g_t_score = false;
	g_t_knife = false;
	g_playing_out = false;
	SetAllCancelled(false);
	ReadyChangeAll(0, false, true);
	ResetHalfScores();
	UpdateStatus();
	
	if (GetConVarBool(g_h_auto_ready))
	{
		ReadySystem(true);
		ShowInfo(0, true, false, 0);
		UpdateStatus();
	}
	else
	{
		ReadySystem(false);
		ShowInfo(0, false, false, 1);
	}
	
	if (!silent)
	{
		for (new x = 1; x <= 3; x++)
		{
			PrintToChatAll("\x03<AtomMod> \x04%t", "Половина матча");
		}
		ServerCommand("mp_restartgame 1");
	}
}

ResetTeams()
{
	g_t_name = DEFAULT_T_NAME;
	g_ct_name = DEFAULT_CT_NAME;
	SetConVarStringHidden(g_h_t, DEFAULT_T_NAME);
	SetConVarStringHidden(g_h_ct, DEFAULT_CT_NAME);
}

ResetMatchScores()
{
	g_scores[SCORE_T][SCORE_FIRST_HALF] = 0;
	g_scores[SCORE_T][SCORE_SECOND_HALF] = 0;
	
	g_scores[SCORE_CT][SCORE_FIRST_HALF] = 0;
	g_scores[SCORE_CT][SCORE_SECOND_HALF] = 0;
	
	for (new i = 0; i <= g_overtime_count; i++)
	{
		g_scores_overtime[SCORE_T][i][SCORE_FIRST_HALF] = 0;
		g_scores_overtime[SCORE_T][i][SCORE_SECOND_HALF] = 0;
		
		g_scores_overtime[SCORE_CT][i][SCORE_FIRST_HALF] = 0;
		g_scores_overtime[SCORE_CT][i][SCORE_SECOND_HALF] = 0;
	}
}

ResetHalfScores()
{
	if (!g_overtime)
	{
		if (g_first_half)
		{
			g_scores[SCORE_T][SCORE_FIRST_HALF] = 0;
			g_scores[SCORE_CT][SCORE_FIRST_HALF] = 0;
		}
		else
		{
			g_scores[SCORE_T][SCORE_SECOND_HALF] = 0;
			g_scores[SCORE_CT][SCORE_SECOND_HALF] = 0;
		}
	}
	else
	{
		if (g_first_half)
		{
			g_scores_overtime[SCORE_T][g_overtime_count][SCORE_FIRST_HALF] = 0;
			g_scores_overtime[SCORE_CT][g_overtime_count][SCORE_FIRST_HALF] = 0;
		}
		else
		{
			g_scores_overtime[SCORE_T][g_overtime_count][SCORE_SECOND_HALF] = 0;
			g_scores_overtime[SCORE_CT][g_overtime_count][SCORE_SECOND_HALF] = 0;
		}
	}
}

public Action:ReadyToggle(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	if (IsLive(client, false))
	{
		return Plugin_Handled;
	}
	
	ReadyChangeAll(client, false, true);
	SetAllCancelled(false);
	
	if (!IsReadyEnabled(client, true))
	{
		ReadySystem(true);
		ShowInfo(client, true, false, 0);
		if (client != 0)
		{
			PrintToConsole(client, "<AtomMod> %t", "Система готовности включена");
		}
		else
		{
			PrintToServer("<AtomMod> %T", "Система готовности включена", LANG_SERVER);
		}
		CheckReady();
	}
	else
	{
		ShowInfo(client, false, false, 1);
		ReadySystem(false);
		if (client != 0)
		{
			PrintToConsole(client, "<AtomMod> %t", "Система готовности отключена");
		}
		else
		{
			PrintToServer("<AtomMod> %T", "Система готовности отключена", LANG_SERVER);
		}
	}
	
	LogAction(client, -1, "\"ready_toggle\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:ActiveToggle(client, args)
{
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	if (GetConVarBool(g_h_active))
	{
		SetConVarBool(g_h_active, false);
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Set Inactive");
		}
		else
		{
			PrintToServer("AtomMod - %T", "Set Inactive", LANG_SERVER);
		}
	}
	else
	{
		SetConVarBool(g_h_active, true);
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Set Active");
		}
		else
		{
			PrintToServer("AtomMod - %T", "Set Active", LANG_SERVER);
		}
	}
	
	LogAction(client, -1, "\"active_toggle\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:ChangeMinReady(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	new String:arg[128];
	new minready;
	
	if (GetCmdArgs() > 0)
	{
		GetCmdArg(1, arg, sizeof(arg));
		minready = StringToInt(arg);
		SetConVarInt(g_h_min_ready, minready);
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Set Minready", minready);
		}
		else
		{
			PrintToServer("AtomMod - %T", "Set Minready", LANG_SERVER, minready);
		}
		LogAction(client, -1, "\"set_min_ready\" (player \"%L\") (min_ready \"%d\")", client, minready);
	}
	else
	{
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04wm_min_ready = %d", GetConVarInt(g_h_min_ready));
		}
		else
		{
			PrintToServer("AtomMod - wm_min_ready = %d", GetConVarInt(g_h_min_ready));
		}
	}
	
	return Plugin_Handled;
}

public Action:ChangeMaxRounds(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	new String:arg[128];
	new maxrounds;
	
	if (GetCmdArgs() > 0)
	{
		GetCmdArg(1, arg, sizeof(arg));
		maxrounds = StringToInt(arg);
		SetConVarInt(g_h_max_rounds, maxrounds);
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Set Maxrounds", maxrounds);
		}
		else
		{
			PrintToServer("AtomMod - %T", "Set Maxrounds", LANG_SERVER, maxrounds);
		}
		LogAction(client, -1, "\"set_max_rounds\" (player \"%L\") (max_rounds \"%d\")", client, maxrounds);
	}
	else
	{
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04wm_max_rounds = %d", GetConVarInt(g_h_max_rounds));
		}
		else
		{
			PrintToServer("AtomMod - wm_max_rounds = %d", GetConVarInt(g_h_max_rounds));
		}
	}
	
	return Plugin_Handled;
}

public Action:ChangePassword(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	new String:new_password[128];
	
	if (GetCmdArgs() > 0)
	{
		GetCmdArg(1, new_password, sizeof(new_password));
		ServerCommand("sv_password \"%s\"", new_password);
		
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Set Password", new_password);
		}
		else
		{
			PrintToServer("AtomMod - %T", "Set Password", LANG_SERVER, new_password);
		}
		
		LogAction(client, -1, "\"set_password\" (player \"%L\")", client);
	}
	else
	{
		new String:passwd[128];
		GetConVarString(FindConVar("sv_password"), passwd, sizeof(passwd));
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04sv_password = '%s'", passwd);
		}
		else
		{
			PrintToServer("AtomMod - sv_password = '%s'", passwd);
		}
	}
	
	return Plugin_Handled;
}

ReadyUp(client)
{
	if (!IsActive(client, false))
	{
		return;
	}
	
	if (!IsReadyEnabled(client, false))
	{
		return;
	}
		
	if (client == 0)
	{
		PrintToServer("<AtomMod> %T", "Console Ready", LANG_SERVER);
		return;
	}
	
	if (IsLive(client, false))
	{
		return;
	}
	
	if (g_player_list[client] != PLAYER_READY)
	{
		if (GetClientTeam(client) > 1)
		{
			ReadyServ(client, true, false, true, false);
		}
		else
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Not on Team");
		}
	}
	else
	{
		PrintToChat(client, "\x03<AtomMod> \x04%t", "Already Ready");
	}
}

ReadyDown(client)
{
	if (!IsActive(client, false))
	{
		return;
	}
	
	if (!IsReadyEnabled(client, false) || client == 0)
	{
		return;
	}
	
	if (IsLive(client, false))
	{
		return;
	}
	
	if (client == 0)
	{
		PrintToServer("<AtomMod> %T", "Console Not Ready", LANG_SERVER);
		return;
	}
	
	if (g_player_list[client] != PLAYER_UNREADY)
	{
		if (GetClientTeam(client) > 1)
		{
			ReadyServ(client, false, false, true, false);
		}
		else
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Not on Team");
		}
	}
	else
	{
		PrintToChat(client, "\x03<AtomMod> \x04%t", "Already Not Ready");
	}
}

public Action:ForceAllReady(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	if (g_ready_enabled)
	{
		ReadyChangeAll(client, true, true);
		CheckReady();
		
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Forced Ready");
		}
		else
		{
			PrintToConsole(client, "<AtomMod> %T", "Forced Ready", LANG_SERVER);
		}
		
		ShowInfo(client, true, false, 0);
	}
	else
	{
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Ready System Disabled2");
		}
		else
		{
			PrintToConsole(client, "<AtomMod> %T", "Ready System Disabled2", LANG_SERVER);
		}
	}
	
	LogAction(client, -1, "\"force_all_ready\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:ForceAllUnready(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	if (g_ready_enabled)
	{
		ReadyChangeAll(client, false, true);
		CheckReady();
		
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Forced Not Ready");
		}
		else
		{
			PrintToServer("<AtomMod> %T", "Forced Not Ready", LANG_SERVER);
		}
		
		ShowInfo(client, true, false, 0);
	}
	else
	{
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Ready System Disabled2");
		}
		else
		{
			PrintToServer("<AtomMod> %T", "Ready System Disabled2", LANG_SERVER);
		}
	}
	
	LogAction(client, -1, "\"force_all_unready\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:ForceStart(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	ResetHalf(true);
	ShowInfo(0, false, false, 1);
	SetAllCancelled(false);
	ReadySystem(false);
	LiveOn3(true);
	
	LogAction(client, -1, "\"force_start\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:ForceEnd(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		Log2Game("\"force_end\"");
	}
	
	ResetMatch(true);
	
	LogAction(client, -1, "\"force_end\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:ReadyOn(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	if (IsLive(client, false))
	{
		return Plugin_Handled;
	}
	
	ReadyChangeAll(client, false, true);
	SetAllCancelled(false);
	
	ReadySystem(true);
	ShowInfo(client, true, false, 0);
	if (client != 0)
	{
		PrintToConsole(client, "<AtomMod> %t", "Ready System Enabled");
	}
	else
	{
		PrintToServer("<AtomMod> %T", "Ready System Enabled", LANG_SERVER);
	}
	CheckReady();
	
	LogAction(client, -1, "\"ready_on\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:ReadyOff(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	if (IsLive(client, false))
	{
		return Plugin_Handled;
	}
	
	ReadyChangeAll(client, false, true);
	SetAllCancelled(false);
	
	if (IsReadyEnabled(client, true))
	{
		ShowInfo(client, false, false, 1);
		ReadySystem(false);
	}
	
	if (client != 0)
	{
		PrintToConsole(client, "<AtomMod> %t", "Ready System Disabled");
	}
	else
	{
		PrintToServer("<AtomMod> %T", "Ready System Disabled", LANG_SERVER);
	}
	
	LogAction(client, -1, "\"ready_off\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:ConsoleScore(client, args)
{
	if (g_match)
	{
		if (g_live)
		{
			if (client != 0)
			{
				PrintToConsole(client, "<AtomMod> %t:", "Match Is Live");
			}
			else
			{
				PrintToServer("<AtomMod> %T:", "Match Is Live", LANG_SERVER);
			}
		}
		PrintToConsole(client, "<AtomMod> %s: [%d] %s: [%d] MR%d", g_t_name, GetTScore(), g_ct_name, GetCTScore(), GetConVarInt(g_h_max_rounds));
		if (g_overtime)
		{
			PrintToConsole(client, "<AtomMod> %t%s (%d): [%d] %s: [%d] MR%d", "Score Overtime", g_overtime_count + 1, g_t_name, GetTOTScore(), g_ct_name, GetCTOTScore(), GetConVarInt(g_h_overtime_mr));
		}
	}
	else
	{
		if (client != 0)
		{
			PrintToConsole(client, "<AtomMod> %t", "Match Not In Progress");
		}
		else
		{
			PrintToServer("<AtomMod> %T", "Match Not In Progress", LANG_SERVER);
		}
	}
	
	return Plugin_Handled;
}

ShowScore(client)
{
	if (!IsActive(client, false))
	{
		return;
	}
	
	if (g_match)
	{
		if (!g_overtime)
		{
			DisplayScore(client, 0, true);
		}
		else
		{
			DisplayScore(client, 1, true);
		}
	}
	else
	{
		PrintToChat(client, "\x03<AtomMod> \x04%t", "Match Not In Progress");
	}
	
	return;
}

DisplayScore(client, msgindex, bool:priv)
{
	if (!GetConVarBool(g_h_ingame_scores))
	{
		return;
	}
	
	if (msgindex == 0) // standard play score
	{
		new String:score_msg[192];
		GetScoreMsg(client, score_msg, sizeof(score_msg), GetTScore(), GetCTScore());
		if (priv)
		{
			PrintToChat(client, "\x03<AtomMod> %s", score_msg);
		}
		else
		{
			PrintToChatAll("\x03<AtomMod> %s", score_msg);
		}
	}
	else if (msgindex == 1) // overtime play score
	{
		new String:score_msg[192];
		GetScoreMsg(client, score_msg, sizeof(score_msg), GetTOTScore(), GetCTOTScore());
		if (priv)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t%s", "Score Overtime", score_msg);
		}
		else
		{
			PrintToChatAll("\x03<AtomMod> \x04%t%s", "Score Overtime", score_msg);
		}
	}
	else if (msgindex == 2) // overall play score
	{
		new String:score_msg[192];
		GetScoreMsg(client, score_msg, sizeof(score_msg), GetTTotalScore(), GetCTTotalScore());
		if (priv)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t%s", "Score Overall", score_msg);
		}
		else
		{
			PrintToChatAll("\x03<AtomMod> \x04%t%s", "Score Overall", score_msg);
		}
	}
}

public GetScoreMsg(client, String:result[], maxlen, t_score, ct_score)
{
	SetGlobalTransTarget(client);
	if (t_score > ct_score)
	{
		Format(result, maxlen, "\x01%t \x04%d\x03-\x04%d", "T Выйграли", g_t_name, t_score, ct_score);
	}
	else if (t_score == ct_score)
	{
		Format(result, maxlen, "\x01%t \x04%d\03-\x04%d", "Ничья", t_score, ct_score);
	}
	else
	{
		Format(result, maxlen, "\x01%t \x04%d\x03-\x04%d", "CT Выйграли", g_ct_name, ct_score, t_score);
	}
}

ReadyInfoPriv(client)
{
	if (!IsActive(client, false))
	{
		return;
	}
		
	if (!IsReadyEnabled(client, false))
	{
		return;
	}
	
	if (client != 0 && !g_live)
	{
		g_cancel_list[client] = false;
		ShowInfo(client, true, true, 0);
	}
}

SwitchCameraTimer(client, Float:delay)
{
	ResetSwitchCameraTimer(client);
	g_deathcam_delays[client] = CreateTimer(delay, SpecNextFake, client);
}

ResetSwitchCameraTimer(client, bool:killTimer=true)
{
	if (killTimer && g_deathcam_delays[client] != INVALID_HANDLE)
	{
		KillTimer(g_deathcam_delays[client]);
	}
	g_deathcam_delays[client] = INVALID_HANDLE;
}

ResetSwitchCameraTimers(bool:killTimer=true)
{
	for (new client = 1; client <= MaxClients; client++)
	{
		ResetSwitchCameraTimer(client, killTimer);
	}
}

public Event_Round_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	round_end = false;
	
	ResetSwitchCameraTimers();
	
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		Log2Game("\"round_start\" (freezetime \"%d\")", GetConVarInt(FindConVar("mp_freezetime")));
	}
	
	CreateTimer(0.1, ShowDamage, false);
	
	g_planted = false;
	
	ResetClutchStats();
	
	if (!g_t_score)
	{
		g_t_score = true;
	}
	
	if (g_t_knife)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) > 1)
			{
				SetEntData(i, g_i_account, 0);
				CS_StripButKnife(i);
				if (GetConVarBool(g_h_knife_hegrenade))
				{
					GivePlayerItem(i, "weapon_hegrenade");
				}
				if (GetConVarInt(g_h_knife_flashbang) >= 1)
				{
					GivePlayerItem(i, "weapon_flashbang");
					if (GetConVarInt(g_h_knife_flashbang) >= 2)
					{
						GivePlayerItem(i, "weapon_flashbang");
					}
				}
				if (GetConVarBool(g_h_knife_smokegrenade))
				{
					GivePlayerItem(i, "weapon_smokegrenade");
				}
			}
		}
	}
	
	if (!g_match || !g_t_money || !GetConVarBool(g_h_round_money) || g_i_account == -1)
	{
		return;
	}
	
	new the_money[MAXPLAYERS + 1];
	new num_players;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			the_money[num_players] = i;
			num_players++;
		}
	}
	
	SortCustom1D(the_money, num_players, SortMoney);
	
	new String:player_name[32];
	new String:player_money[10];
	new String:has_weapon[1];
	new pri_weapon;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		for (new x = 0; x < num_players; x++)
		{
			GetClientName(the_money[x], player_name, sizeof(player_name));
			if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == GetClientTeam(the_money[x]))
			{
				pri_weapon = GetPlayerWeaponSlot(the_money[x], 0);
				if (pri_weapon == -1)
				{
					has_weapon = ">";
				}
				else
				{
					has_weapon = "\0";
				}
				IntToMoney(GetEntData(the_money[x], g_i_account), player_money, sizeof(player_money));
				PrintToChat(i, "\x01$%s \x04%s> \x03%s", player_money, has_weapon, player_name);
			}
		}
	}
}

public Action:AskTeamMoney(client, args)
{
	ShowTeamMoney(client);
	return Plugin_Handled;
}

stock ShowTeamMoney(client)
{
	new the_money[MAXPLAYERS + 1];
	new num_players;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			the_money[num_players] = i;
			num_players++;
		}
	}
	
	SortCustom1D(the_money, num_players, SortMoney);
	
	new String:player_name[32];
	new String:player_money[10];
	new String:has_weapon[1];
	new pri_weapon;
	
	PrintToChat(client, "\x01--------");
	for (new x = 0; x < num_players; x++)
	{
		GetClientName(the_money[x], player_name, sizeof(player_name));
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == GetClientTeam(the_money[x]))
		{
			pri_weapon = GetPlayerWeaponSlot(the_money[x], 0);
			if (pri_weapon == -1)
			{
				has_weapon = ">";
			}
			else
			{
				has_weapon = "\0";
			}
			IntToMoney(GetEntData(the_money[x], g_i_account), player_money, sizeof(player_money));
			PrintToChat(client, "\x01$%s \x04%s> \x03%s", player_money, has_weapon, player_name);
		}
	}
}

public Event_Round_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	round_end = true;
	
	ResetSwitchCameraTimers();
	
	if (!IsActive(0, true))
	{
		return;
	}
	
	CreateTimer(0.1, ShowDamage, true);
	
	new winner = GetEventInt(event, "winner");
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == winner)
			{
				clutch_stats[i][CLUTCH_WON] = 1;
			}
			LogPlayerStats(i);
			LogClutchStats(i);
		}
		Log2Game("\"round_end\" (winner \"%d\") (reason \"%d\")", winner, GetEventInt(event, "reason"));
	}
	
	if (winner > 1 && g_t_score)
	{
		if (g_t_knife)
		{
			if (GetConVarBool(g_h_auto_knife) && GetConVarBool(g_h_auto_ready))
			{
				ReadyChangeAll(0, false, true);
				SetAllCancelled(false);
				ReadySystem(true);
				ShowInfo(0, true, false, 0);
			}
			if (GetConVarBool(g_h_stats_enabled))
			{
				if (winner == TERRORIST_TEAM)
				{
					Log2Game("\"knife_win\" (team \"%s\")", g_t_name);
				}
				else if (winner == COUNTER_TERRORIST_TEAM)
				{
					Log2Game("\"knife_win\" (team \"%s\")", g_ct_name);
				}
			}
			g_t_knife = false;
			g_t_had_knife = true;
			UpdateStatus();
		}
		
		if (!g_live)
		{
			return;
		}
		
		if (!g_t_money)
		{
			g_t_money = true;
		}
		
		AddScore(winner);
		CheckScores();
		UpdateStatus();
	}
}

public Event_Round_Restart(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled) && !StrEqual(newVal, "0"))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			ResetPlayerStats(i);
			clutch_stats[i][CLUTCH_LAST] = 0;
			clutch_stats[i][CLUTCH_VERSUS] = 0;
			clutch_stats[i][CLUTCH_FRAGS] = 0;
			clutch_stats[i][CLUTCH_WON] = 0;
		}
		Log2Game("\"round_restart\" (delay \"%s\")", newVal);
	}
}

public Event_Round_Freeze_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		Log2Game("\"round_freeze_end\"");
	}
}

public Event_Player_Blind(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client > 0)
		{
			new String:log_string[256];
			CS_GetAdvLogString(client, log_string, sizeof(log_string));
			Log2Game("\"player_blind\" (player \"%s\") (duration \"%.2f\")", log_string, GetEntPropFloat(client, Prop_Send, "m_flFlashDuration"));
		}
	}
}

public Event_Player_Hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		new damage = GetEventInt(event, "dmg_health");
		new damage_armor = GetEventInt(event, "dmg_armor");
		new hitgroup = GetEventInt(event, "hitgroup");
		new String:weapon[64];
		GetEventString(event, "weapon", weapon, 64);
		
		if (attacker > 0)
		{
			new weapon_index = GetWeaponIndex(weapon);
			if (victim > 0)
			{
				GetClientWeapon(victim, last_weapon[victim], 64);
				ReplaceString(last_weapon[victim], 64, "weapon_", "");
				new String:attacker_log_string[256];
				new String:victim_log_string[256];
				CS_GetAdvLogString(attacker, attacker_log_string, sizeof(attacker_log_string));
				CS_GetAdvLogString(victim, victim_log_string, sizeof(victim_log_string));
				Log2Game("\"player_hurt\" (attacker \"%s\") (victim \"%s\") (weapon \"%s\") (damage \"%d\") (damage_armor \"%d\") (hitgroup \"%d\")", attacker_log_string, victim_log_string, weapon, damage, damage_armor, hitgroup);
			}
			if (weapon_index > -1)
			{
				weapon_stats[attacker][weapon_index][LOG_HIT_HITS]++;
				weapon_stats[attacker][weapon_index][LOG_HIT_DAMAGE] += damage;
				if (hitgroup < 8)
				{
					weapon_stats[attacker][weapon_index][hitgroup + LOG_HIT_OFFSET]++;
				}
			}
		}
	}
}

public Event_Player_Death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new bool:headshot = GetEventBool(event, "headshot");
	new String: weapon[64];
	GetEventString(event, "weapon", weapon, sizeof(weapon));
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		if (attacker > 0 && victim > 0 && attacker != victim)
		{
			new String:attacker_log_string[256];
			new String:victim_log_string[256];
			CS_GetAdvLogString(attacker, attacker_log_string, sizeof(attacker_log_string));
			CS_GetAdvLogString(victim, victim_log_string, sizeof(victim_log_string));
			Log2Game("\"player_death\" (attacker \"%s\") (victim \"%s\") (weapon \"%s\") (headshot \"%d\")", attacker_log_string, victim_log_string, weapon, headshot);
		}
		else if (victim > 0 && victim == attacker || StrEqual(weapon, "worldspawn"))
		{
			new String:log_string[256];
			CS_GetAdvLogString(victim, log_string, sizeof(log_string));
			ReplaceString(weapon, sizeof(weapon), "worldspawn", "world");
			Log2Game("\"player_suicide\" (player \"%s\") (weapon \"%s\")", log_string, weapon);
		}
		if (victim > 0)
		{
			new weapon_index = GetWeaponIndex(weapon);
			if (attacker > 0)
			{
				new victim_team = GetClientTeam(victim);
				new attacker_team = GetClientTeam(attacker);
				if (weapon_index > -1)
				{
					weapon_stats[attacker][weapon_index][LOG_HIT_KILLS]++;
					if (headshot == true)
					{
						weapon_stats[attacker][weapon_index][LOG_HIT_HEADSHOTS]++;
					}
					if (attacker_team == victim_team)
					{
						weapon_stats[attacker][weapon_index][LOG_HIT_TEAMKILLS]++;
					}
				}
				new victim_num_alive = GetNumAlive(victim_team);
				new attacker_num_alive = GetNumAlive(attacker_team);
				if (victim_num_alive == 0)
				{
					clutch_stats[victim][CLUTCH_LAST] = 1;
					if (clutch_stats[victim][CLUTCH_VERSUS] == 0)
					{
						clutch_stats[victim][CLUTCH_VERSUS] = attacker_num_alive;
					}
				}
				if (attacker_num_alive == 1)
				{
					if (attacker_team != victim_team)
					{
						clutch_stats[attacker][CLUTCH_FRAGS]++;
						if (clutch_stats[attacker][CLUTCH_LAST] == 0)
						{
							clutch_stats[attacker][CLUTCH_VERSUS] = victim_num_alive + 1;
						}
						clutch_stats[attacker][CLUTCH_LAST] = 1;
					}
				}
			}
			new victim_weapon_index = GetWeaponIndex(last_weapon[victim]);
			if (victim_weapon_index > -1)
			{
				weapon_stats[victim][victim_weapon_index][LOG_HIT_DEATHS]++;
			}
		}
	}
	
	if (!g_live && GetConVarBool(g_h_warmup_respawn))
	{
		CreateTimer(0.1, RespawnPlayer, victim);
	}
	else
	{
		if (GetConVarBool(g_h_deathcam_remove))
		{
			if (g_h_force_camera == INVALID_HANDLE)
			{
				g_h_force_camera = FindConVar("mp_forcecamera");
			}
			if (g_h_force_camera != INVALID_HANDLE && GetConVarInt(g_h_force_camera) == 1)
			{
				if (GetNumAlive(GetClientTeam(victim)) > 0)
				{
					SwitchCameraTimer(victim, GetConVarFloat(g_h_deathcam_delay));
					new target;
					for (new i = 1; i <= MaxClients; i++)
					{
						if (i != victim && IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && GetClientTeam(i) == GetClientTeam(victim))
						{
							target = GetEntPropEnt(i, Prop_Send, "m_hObserverTarget");
							if (IsValidEntity(target) && IsClientObserver(target))
							{
								SwitchCameraTimer(i, GetConVarFloat(g_h_deathcam_delay));
							}
						}
					}
				}
			}
		}
		
		if (g_h_fade_to_black == INVALID_HANDLE)
		{
			g_h_fade_to_black = FindConVar("mp_fadetoblack");
		}
		if (GetConVarBool(g_h_fade_to_black))
		{
			CreateTimer(6.0, SetSpecTimer, victim, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	if (GetConVarBool(g_h_body_remove) && GetNumAlive(GetClientTeam(victim)) > 0)
	{
		CreateTimer(GetConVarFloat(g_h_body_delay), RemoveRagdoll, victim, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Event_Player_Name(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		new String:newname[32];
		GetEventString(event, "newname", newname, sizeof(newname));
		Log2Game("\"player_name\" (player \"%s\") (new_name \"%s\")", log_string, newname);
	}
	
	if (g_ready_enabled && !g_live)
	{
		CreateTimer(0.1, UpdateInfo);
	}
}

public Event_Player_Connect(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetConVarBool(g_h_stats_enabled) && client != 0)
	{
		new String:log_string[256];
		CS_GetLogString(client, log_string, sizeof(log_string));
		new String:authip[32];
		GetEventString(event, "address", authip, sizeof(authip));
		Log2Game("\"player_connect\" (player \"%s\") (address \"%s\")", log_string, authip);
	}
}

public Event_Player_Disc(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetConVarBool(g_h_stats_enabled) && client != 0)
	{
		new String:log_string[256];
		CS_GetLogString(client, log_string, sizeof(log_string));
		new String:reason[128];
		GetEventString(event, "reason", reason, sizeof(reason));
		Log2Game("\"player_disconnect\" (player \"%s\") (reason \"%s\")", log_string, reason);
	}
}

public Event_Player_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new old_team = GetEventInt(event, "oldteam");
	new new_team = GetEventInt(event, "team");
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetLogString(client, log_string, sizeof(log_string));
		Log2Game("\"player_team\" (player \"%s\") (oldteam \"%d\") (newteam \"%d\")", log_string, old_team, new_team);
	}
	
	if (old_team < 2)
	{
		CreateTimer(4.0, ShowPluginInfo, client);
		if (!g_live && g_ready_enabled && !GetEventBool(event, "disconnect") && !IsFakeClient(client))
		{
			CreateTimer(4.0, UpdateInfo);
		}
	}
	
	if (old_team == 0)
	{
		CreateTimer(2.0, HelpText, client, TIMER_FLAG_NO_MAPCHANGE);
		
		CreateTimer(2.0, AdvertGameTech, client);
	}
	
	if (!g_live && g_ready_enabled && !GetEventBool(event, "disconnect") && !IsFakeClient(client)) {
		if (new_team != SPECTATOR_TEAM) {
			if (g_player_list[client] == PLAYER_READY)
			{
				ReadyServ(client, false, false, true, false);
			}
			else
			{
				ReadyServ(client, false, true, true, false);
			}
		}
		else
		{
			g_player_list[client] = PLAYER_DISC;
			ShowInfo(client, true, false, 0);
		}
	}
	
	if (new_team > 1 && !g_live && GetConVarBool(g_h_warmup_respawn)) {
		CreateTimer(0.1, RespawnPlayer, client);
	}
}

public Event_Bomb_Exploded(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!GetConVarBool(g_h_bomb_frags) && !round_end) // must not be after round end as they no longer get frags
	{
		SetFrags(client, GetFrags(client) - 3);
	}
}

public Event_Bomb_PickUp(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		Log2Game("\"bomb_pickup\" (player \"%s\")", log_string);
	}
}

public Event_Bomb_Dropped(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		Log2Game("\"bomb_dropped\" (player \"%s\")", log_string);
	}
}

public Event_Bomb_Plant_Begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		Log2Game("\"bomb_plant_begin\" (player \"%s\") (site \"%d\")", log_string, GetEventInt(event, "site"));
	}
}

public Event_Bomb_Plant_Abort(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
		return;
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		Log2Game("\"bomb_plant_abort\" (player \"%s\") (site \"%d\")", log_string, GetEventInt(event, "site"));
	}
}

public Event_Bomb_Planted(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_planted = true;
	
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		Log2Game("\"bomb_planted\" (player \"%s\") (site \"%d\") (origin_x \"%d\") (origin_y \"%d\")", log_string, GetEventInt(event, "site"), GetEventInt(event, "posx"), GetEventInt(event, "posy"));
	}
}

public Event_Bomb_Defuse_Begin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(client, log_string, sizeof(log_string));
		Log2Game("\"bomb_defuse_begin\" (player \"%s\") (kit \"%d\")", log_string, GetEventInt(event, "site"), GetEventBool(event, "haskit"));
	}
}

public Event_Bomb_Defuse_Abort(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		Log2Game("\"bomb_defuse_abort\" (player \"%s\")", log_string);
	}
}

public Event_Bomb_Defused(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(client, log_string, sizeof(log_string));
		Log2Game("\"bomb_defused\" (player \"%s\") (site \"%d\")", log_string, GetEventInt(event, "site"));
	}
	
	if (!GetConVarBool(g_h_defuse_frags))
	{
		SetFrags(client, GetFrags(client) - 3);
	}
}

public Event_Weapon_Fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if (client > 0)
		{
			new String: weapon[64];
			GetEventString(event, "weapon", weapon, 64);
			new weapon_index = GetWeaponIndex(weapon);
			if (weapon_index > -1)
			{
				weapon_stats[client][weapon_index][LOG_HIT_SHOTS]++;
			}
		}
	}
}

public Event_Detonate_Flash(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		Log2Game("\"grenade_detonate\" (player \"%s\") (grenade \"flashbang\")", log_string);
	}
}

public Event_Detonate_Smoke(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		Log2Game("\"grenade_detonate\" (player \"%s\") (grenade \"smokegrenade\")", log_string);
	}
}

public Event_Detonate_HeGrenade(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		Log2Game("\"grenade_detonate\" (player \"%s\") (grenade \"hegrenade\")", log_string);
	}
}

public Event_Item_Pickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		CS_GetAdvLogString(GetClientOfUserId(GetEventInt(event, "userid")), log_string, sizeof(log_string));
		new String:item[64];
		GetEventString(event, "item", item, sizeof(item));
		Log2Game("\"item_pickup\" (player \"%s\") (item \"%s\")", log_string, item);
	}
}

AddScore(team)
{
	if (!g_overtime)
	{
		if (team == TERRORIST_TEAM)
		{
			if (g_first_half)
			{
				g_scores[SCORE_T][SCORE_FIRST_HALF]++;
			}
			else
			{
				g_scores[SCORE_T][SCORE_SECOND_HALF]++;
			}
		}
		
		if (team == COUNTER_TERRORIST_TEAM)
		{
			if (g_first_half)
			{
				g_scores[SCORE_CT][SCORE_FIRST_HALF]++;
			}
			else
			{
				g_scores[SCORE_CT][SCORE_SECOND_HALF]++;
			}
		}
	}
	else
	{
		if (team == TERRORIST_TEAM)
		{
			if (g_first_half)
			{
				g_scores_overtime[SCORE_T][g_overtime_count][SCORE_FIRST_HALF]++;
			}
			else
			{
				g_scores_overtime[SCORE_T][g_overtime_count][SCORE_SECOND_HALF]++;
			}
		}
		
		if (team == COUNTER_TERRORIST_TEAM)
		{
			if (g_first_half)
			{
				g_scores_overtime[SCORE_CT][g_overtime_count][SCORE_FIRST_HALF]++;
			}
			else
			{
				g_scores_overtime[SCORE_CT][g_overtime_count][SCORE_SECOND_HALF]++;
			}
		}
	}
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		Log2Game("\"score_update\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
	}
	
	SetConVarIntHidden(g_h_t_score, GetTTotalScore());
	SetConVarIntHidden(g_h_ct_score, GetCTTotalScore());
}

CheckScores()
{
	if (GetConVarInt(g_h_score_mode) == 1)
	{
		if (!g_overtime)
		{
			if (GetScore() == GetConVarInt(g_h_max_rounds)) // half time
			{
				if (!g_first_half)
				{
					return;
				}
				Call_StartForward(g_f_on_half_time);
				Call_Finish();
				if (GetConVarBool(g_h_stats_enabled))
				{
					Log2Game("\"half_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
				}
				DisplayScore(0, 0, false);
				
				if (!GetConVarBool(g_h_auto_swap))
				{
					PrintToChatAll("\x03<AtomMod> \x04%t", "Half Time");
				}
				else
				{
					PrintToChatAll("\x03<AtomMod> \x04%t", "Half Time Auto Swap");
					CreateTimer(GetConVarFloat(g_h_auto_swap_delay), Swap, TIMER_FLAG_NO_MAPCHANGE);
				}
				
				g_live = false;
				g_t_money = false;
				g_first_half = false;
				SetAllCancelled(false);
				ReadyChangeAll(0, false, true);
				SwitchScores();
				
				if (!StrEqual(g_t_name, DEFAULT_T_NAME, false) && !StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
				{
					SwitchTeams();
				}
				
				if (GetConVarBool(g_h_auto_ready) || GetConVarBool(g_h_half_auto_ready))
				{
					ReadySystem(true);
					CreateTimer(GetConVarFloat(g_h_auto_swap_delay) + 0.5, UpdateInfo, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else if (GetTScore() == GetConVarInt(g_h_max_rounds) && GetCTScore() == GetConVarInt(g_h_max_rounds)) // complete draw
			{
				if (GetConVarInt(g_h_overtime) == 1)
				{ // max rounds overtime
					if (GetConVarBool(g_h_stats_enabled))
					{
						Log2Game("\"over_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
					}
					DisplayScore(0, 0, false);
					PrintToChatAll("\x03<AtomMod> \x04%t", "Добавочное время", GetConVarInt(g_h_overtime_mr));
					g_live = false;
					g_t_money = false;
					g_overtime = true;
					g_overtime_mode = 1;
					g_first_half = true;
					SetAllCancelled(false);
					ReadyChangeAll(0, false, true);
					
					if (GetConVarBool(g_h_auto_ready) || GetConVarBool(g_h_half_auto_ready))
					{
						ReadySystem(true);
						ShowInfo(0, true, false, 0);
						CheckReady();
					}
				}
				else if (GetConVarInt(g_h_overtime) == 2) // sudden death overtime
				{
					if (GetConVarBool(g_h_stats_enabled))
					{
						Log2Game("\"over_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
					}
					DisplayScore(0, 0, false);
					PrintToChatAll("\x03<AtomMod> \x04%t", "Over Time Sudden Death");
					g_live = false;
					g_t_money = false;
					g_overtime = true;
					g_overtime_mode = 2;
					g_first_half = true;
					
					SetAllCancelled(false);
					ReadyChangeAll(0, false, true);
					
					if (GetConVarBool(g_h_auto_ready) || GetConVarBool(g_h_half_auto_ready))
					{
						ReadySystem(true);
						ShowInfo(0, true, false, 0);
						CheckReady();
					}
				}
				else
				{
					Call_StartForward(g_f_on_end_match);
					Call_Finish();
					if (GetConVarBool(g_h_stats_enabled))
					{
						Log2Game("\"full_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
					}
					if (GetConVarBool(g_h_prefix_logs))
					{
						RenameLogs();
					}
					DisplayScore(0, 0, false);
					if (GetConVarBool(g_h_auto_kick_team))
					{
						CreateTimer(GetConVarFloat(g_h_auto_kick_delay), KickLoserTeam, GetLoserTeam());
					}
					PrintToChatAll("\x03<AtomMod> \x04%t", "Full Time");
					if (GetConVarBool(g_h_upload_results))
					{
						new match_length = RoundFloat(GetEngineTime() - g_match_start);
						if (StrEqual(g_t_name, DEFAULT_T_NAME, false) && StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
						{
							SwitchTeams();
						}
						MySQL_UploadResults(match_length, g_map, GetConVarInt(g_h_max_rounds), GetConVarInt(g_h_overtime_mr), g_overtime_count, GetConVarBool(g_h_play_out), g_t_name, GetTTotalScore(), g_scores[SCORE_T][SCORE_FIRST_HALF], g_scores[SCORE_T][SCORE_SECOND_HALF], GetTOTTotalScore(), g_ct_name, GetCTTotalScore(), g_scores[SCORE_CT][SCORE_FIRST_HALF], g_scores[SCORE_CT][SCORE_SECOND_HALF], GetCTOTTotalScore());
					}
					ResetMatch(true);
				}
			}
			else if (GetScore() == GetConVarInt(g_h_max_rounds) * 2) // full time (all rounds have been played out)
			{
				Call_StartForward(g_f_on_end_match);
				Call_Finish();
				if (GetConVarBool(g_h_stats_enabled))
				{
					Log2Game("\"full_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
				}
				if (GetConVarBool(g_h_prefix_logs))
				{
					RenameLogs();
				}
				DisplayScore(0, 0, false);
				PrintToChatAll("\x03<AtomMod> \x04%t", "Full Time");
				if (GetConVarBool(g_h_auto_kick_team))
				{
					CreateTimer(GetConVarFloat(g_h_auto_kick_delay), KickLoserTeam, GetLoserTeam());
				}
				if (GetConVarBool(g_h_upload_results))
				{
					new match_length = RoundFloat(GetEngineTime() - g_match_start);
					if (StrEqual(g_t_name, DEFAULT_T_NAME, false) && StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
					{
						SwitchTeams();
					}
					MySQL_UploadResults(match_length, g_map, GetConVarInt(g_h_max_rounds), GetConVarInt(g_h_overtime_mr), g_overtime_count, GetConVarBool(g_h_play_out), g_t_name, GetTTotalScore(), g_scores[SCORE_T][SCORE_FIRST_HALF], g_scores[SCORE_T][SCORE_SECOND_HALF], GetTOTTotalScore(), g_ct_name, GetCTTotalScore(), g_scores[SCORE_CT][SCORE_FIRST_HALF], g_scores[SCORE_CT][SCORE_SECOND_HALF], GetCTOTTotalScore());
				}
				ResetMatch(true);
			}
			else if (!g_playing_out && GetTScore() == GetConVarInt(g_h_max_rounds) + 1 || GetCTScore() == GetConVarInt(g_h_max_rounds) + 1) // full time
			{
				DisplayScore(0, 0, false);
				PrintToChatAll("\x03<AtomMod> \x04%t", "Full Time");
				
				if (!GetConVarBool(g_h_play_out))
				{
					Call_StartForward(g_f_on_end_match);
					Call_Finish();
					if (GetConVarBool(g_h_stats_enabled))
					{
						Log2Game("\"full_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
					}
					if (GetConVarBool(g_h_prefix_logs))
					{
						RenameLogs();
					}
					if (GetConVarBool(g_h_auto_kick_team))
					{
						CreateTimer(GetConVarFloat(g_h_auto_kick_delay), KickLoserTeam, GetLoserTeam());
					}
					if (GetConVarBool(g_h_upload_results))
					{
						new match_length = RoundFloat(GetEngineTime() - g_match_start);
						if (StrEqual(g_t_name, DEFAULT_T_NAME, false) && StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
						{
							SwitchTeams();
						}
						MySQL_UploadResults(match_length, g_map, GetConVarInt(g_h_max_rounds), GetConVarInt(g_h_overtime_mr), g_overtime_count, GetConVarBool(g_h_play_out), g_t_name, GetTTotalScore(), g_scores[SCORE_T][SCORE_FIRST_HALF], g_scores[SCORE_T][SCORE_SECOND_HALF], GetTOTTotalScore(), g_ct_name, GetCTTotalScore(), g_scores[SCORE_CT][SCORE_FIRST_HALF], g_scores[SCORE_CT][SCORE_SECOND_HALF], GetCTOTTotalScore());
					}
					ResetMatch(true);
				}
				else
				{
					if (GetConVarBool(g_h_stats_enabled))
					{
						Log2Game("\"full_time_playing_out\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
					}
					g_playing_out = true;
					PrintToChatAll("\x03<AtomMod> \x04%t", "Playing Out Notice", (GetConVarInt(g_h_max_rounds) * 2));
				}
			}
			else
			{
				DisplayScore(0, 0, false);
			}
		}
		else
		{
			if (GetOTScore() == GetConVarInt(g_h_overtime_mr)) // half time
			{
				if (!g_first_half)
				{
					return;
				}
				Call_StartForward(g_f_on_half_time);
				Call_Finish();
				if (GetConVarBool(g_h_stats_enabled))
				{
					Log2Game("\"over_half_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
				}
				DisplayScore(0, 1, false);
				
				if (!GetConVarBool(g_h_auto_swap))
				{
					PrintToChatAll("\x03<AtomMod> \x04%t", "Half Time");
				}
				else
				{
					PrintToChatAll("\x03<AtomMod> \x04%t", "Half Time Auto Swap");
					CreateTimer(GetConVarFloat(g_h_auto_swap_delay), Swap, TIMER_FLAG_NO_MAPCHANGE);
				}
				
				g_live = false;
				g_t_money = false;
				g_first_half = false;
				SetAllCancelled(false);
				ReadyChangeAll(0, false, true);
				SwitchScores();
				
				if (!StrEqual(g_t_name, DEFAULT_T_NAME, false) && !StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
				{
					SwitchTeams();
				}
				
				if (GetConVarBool(g_h_auto_ready) || GetConVarBool(g_h_half_auto_ready))
				{
					ReadySystem(true);
					CreateTimer(GetConVarFloat(g_h_auto_swap_delay) + 0.5, UpdateInfo, TIMER_FLAG_NO_MAPCHANGE);
					CheckReady();
				}
			}
			else if (GetTOTScore() == GetConVarInt(g_h_overtime_mr) && GetCTOTScore() == GetConVarInt(g_h_overtime_mr)) // complete draw
			{
				if (g_overtime_mode == 1)
				{ // max rounds overtime
					if (GetConVarBool(g_h_stats_enabled))
						Log2Game("\"over_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
					DisplayScore(0, 1, false);
					PrintToChatAll("\x03<AtomMod> \x04%t", "Over Time", GetConVarInt(g_h_overtime_mr));
					g_live = false;
					g_t_money = false;
					g_overtime_count++;
					g_first_half = true;
					SetAllCancelled(false);
					ReadyChangeAll(0, false, true);
					
					if (GetConVarBool(g_h_auto_ready) || GetConVarBool(g_h_half_auto_ready))
					{
						ReadySystem(true);
						ShowInfo(0, true, false, 0);
						CheckReady();
					}
					
					return;
				}
				else if (g_overtime_mode == 2) // sudden death overtime
				{
					Call_StartForward(g_f_on_end_match);
					Call_Finish();
					if (GetConVarBool(g_h_auto_kick_team))
					{
						CreateTimer(GetConVarFloat(g_h_auto_kick_delay), KickLoserTeam, GetLoserTeam());
					}
					if (GetConVarBool(g_h_upload_results))
					{
						new match_length = RoundFloat(GetEngineTime() - g_match_start);
						if (StrEqual(g_t_name, DEFAULT_T_NAME, false) && StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
						{
							SwitchTeams();
						}
						MySQL_UploadResults(match_length, g_map, GetConVarInt(g_h_max_rounds), GetConVarInt(g_h_overtime_mr), g_overtime_count, GetConVarBool(g_h_play_out), g_t_name, GetTTotalScore(), g_scores[SCORE_T][SCORE_FIRST_HALF], g_scores[SCORE_T][SCORE_SECOND_HALF], GetTOTTotalScore(), g_ct_name, GetCTTotalScore(), g_scores[SCORE_CT][SCORE_FIRST_HALF], g_scores[SCORE_CT][SCORE_SECOND_HALF], GetCTOTTotalScore());
					}
					if (GetConVarBool(g_h_stats_enabled))
					{
						Log2Game("\"over_full_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
					}
					if (GetConVarBool(g_h_prefix_logs))
					{
						RenameLogs();
					}
					DisplayScore(0, 2, false);
					PrintToChatAll("\x03<AtomMod> \x04%t", "Full Time");
					ResetMatch(true);
					return;
				}
			}
			else if (GetTOTScore() == GetConVarInt(g_h_overtime_mr) + 1 || GetCTOTScore() == GetConVarInt(g_h_overtime_mr) + 1) // full time
			{
				Call_StartForward(g_f_on_end_match);
				Call_Finish();
				if (GetConVarBool(g_h_auto_kick_team))
				{
					CreateTimer(GetConVarFloat(g_h_auto_kick_delay), KickLoserTeam, GetLoserTeam());
				}
				if (GetConVarBool(g_h_stats_enabled))
				{
					Log2Game("\"over_full_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
				}
				if (GetConVarBool(g_h_prefix_logs))
				{
					RenameLogs();
				}
				DisplayScore(0, 2, false);
				PrintToChatAll("\x03<AtomMod> \x04%t", "Full Time");
				if (GetConVarBool(g_h_upload_results))
				{
					new match_length = RoundFloat(GetEngineTime() - g_match_start);
					if (StrEqual(g_t_name, DEFAULT_T_NAME, false) && StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
					{
						SwitchTeams();
					}
					MySQL_UploadResults(match_length, g_map, GetConVarInt(g_h_max_rounds), GetConVarInt(g_h_overtime_mr), g_overtime_count, GetConVarBool(g_h_play_out), g_t_name, GetTTotalScore(), g_scores[SCORE_T][SCORE_FIRST_HALF], g_scores[SCORE_T][SCORE_SECOND_HALF], GetTOTTotalScore(), g_ct_name, GetCTTotalScore(), g_scores[SCORE_CT][SCORE_FIRST_HALF], g_scores[SCORE_CT][SCORE_SECOND_HALF], GetCTOTTotalScore());
				}
				ResetMatch(true);
				return;
			}
			else
			{
				DisplayScore(0, 1, false);
			}
		}
	}
	else
	{
		if (g_first_half && GetConVarBool(g_h_auto_swap) && (GetTScore() == RoundToFloor(GetConVarFloat(g_h_max_rounds) / 2) || GetCTScore() == RoundToFloor(GetConVarFloat(g_h_max_rounds) / 2)))
		{
			if (!g_first_half)
			{
				return;
			}
			Call_StartForward(g_f_on_half_time);
			Call_Finish();
			if (GetConVarBool(g_h_stats_enabled))
			{
				Log2Game("\"half_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
			}
			DisplayScore(0, 0, false);
			
			if (!GetConVarBool(g_h_auto_swap))
			{
				PrintToChatAll("\x03<AtomMod> \x04%t", "Half Time");
			}
			else
			{
				PrintToChatAll("\x03<AtomMod> \x04%t", "Half Time Auto Swap");
				CreateTimer(GetConVarFloat(g_h_auto_swap_delay), Swap, TIMER_FLAG_NO_MAPCHANGE);
			}
			
			g_live = false;
			g_t_money = false;
			g_first_half = false;
			SetAllCancelled(false);
			ReadyChangeAll(0, false, true);
			SwitchScores();
			
			if (!StrEqual(g_t_name, DEFAULT_T_NAME, false) && !StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
			{
				SwitchTeams();
			}
			
			if (GetConVarBool(g_h_auto_ready) || GetConVarBool(g_h_half_auto_ready))
			{
				ReadySystem(true);
				CreateTimer(GetConVarFloat(g_h_auto_swap_delay) + 0.5, UpdateInfo, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else if (GetTScore() == GetConVarInt(g_h_max_rounds) || GetCTScore() == GetConVarInt(g_h_max_rounds))
		{
			Call_StartForward(g_f_on_end_match);
			Call_Finish();
			if (GetConVarBool(g_h_stats_enabled))
			{
				Log2Game("\"full_time\" \"%s\" \"%d\" \"%s\" \"%d\"", g_t_name, GetTTotalScore(), g_ct_name, GetCTTotalScore());
			}
			if (GetConVarBool(g_h_prefix_logs))
			{
				RenameLogs();
			}
			DisplayScore(0, 0, false);
			if (GetConVarBool(g_h_auto_kick_team))
			{
				CreateTimer(GetConVarFloat(g_h_auto_kick_delay), KickLoserTeam, GetLoserTeam());
			}
			PrintToChatAll("\x03<AtomMod> \x04%t", "Full Time");
			if (GetConVarBool(g_h_upload_results))
			{
				new match_length = RoundFloat(GetEngineTime() - g_match_start);
				if (StrEqual(g_t_name, DEFAULT_T_NAME, false) && StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
				{
					SwitchTeams();
				}
				MySQL_UploadResults(match_length, g_map, GetConVarInt(g_h_max_rounds), GetConVarInt(g_h_overtime_mr), g_overtime_count, GetConVarBool(g_h_play_out), g_t_name, GetTTotalScore(), g_scores[SCORE_T][SCORE_FIRST_HALF], g_scores[SCORE_T][SCORE_SECOND_HALF], GetTOTTotalScore(), g_ct_name, GetCTTotalScore(), g_scores[SCORE_CT][SCORE_FIRST_HALF], g_scores[SCORE_CT][SCORE_SECOND_HALF], GetCTOTTotalScore());
			}
			ResetMatch(true);
		}
		else
		{
			DisplayScore(0, 0, false);
		}
	}
}

GetScore()
{
	return GetTScore() + GetCTScore();
}

GetTScore()
{
	return g_scores[SCORE_T][SCORE_FIRST_HALF] + g_scores[SCORE_T][SCORE_SECOND_HALF];
}

GetCTScore()
{
	return g_scores[SCORE_CT][SCORE_FIRST_HALF] + g_scores[SCORE_CT][SCORE_SECOND_HALF];
}

GetOTScore()
{
	return GetTOTScore() + GetCTOTScore();
}

GetTOTScore()
{
	return g_scores_overtime[SCORE_T][g_overtime_count][SCORE_FIRST_HALF] + g_scores_overtime[SCORE_T][g_overtime_count][SCORE_SECOND_HALF];
}

GetCTOTScore()
{	
	return g_scores_overtime[SCORE_CT][g_overtime_count][SCORE_FIRST_HALF] + g_scores_overtime[SCORE_CT][g_overtime_count][SCORE_SECOND_HALF];
}

GetTOTTotalScore()
{
	new result;
	for (new i = 0; i <= g_overtime_count; i++)
	{
		result += g_scores_overtime[SCORE_T][i][SCORE_FIRST_HALF] + g_scores_overtime[SCORE_T][i][SCORE_SECOND_HALF];
	}
	return result;
}

GetCTOTTotalScore()
{
	new result;
	for (new i = 0; i <= g_overtime_count; i++)
	{
		result += g_scores_overtime[SCORE_CT][i][SCORE_FIRST_HALF] + g_scores_overtime[SCORE_CT][i][SCORE_SECOND_HALF];
	}
	return result;
}

GetTTotalScore()
{
	new result;
	result = GetTScore();
	for (new i = 0; i <= g_overtime_count; i++)
	{
		result += g_scores_overtime[SCORE_T][i][SCORE_FIRST_HALF] + g_scores_overtime[SCORE_T][i][SCORE_SECOND_HALF];
	}
	return result;
}

GetCTTotalScore()
{
	new result;
	result = GetCTScore();
	for (new i = 0; i <= g_overtime_count; i++)
	{
		result += g_scores_overtime[SCORE_CT][i][SCORE_FIRST_HALF] + g_scores_overtime[SCORE_CT][i][SCORE_SECOND_HALF];
	}
	return result;
}

public SortMoney(elem1, elem2, const array[], Handle:hndl)
{
	new money1 = GetEntData(elem1, g_i_account);
	new money2 = GetEntData(elem2, g_i_account);
	
	if (money1 > money2)
	{
		return -1;
	}
	else if (money1 == money2)
	{
		return 0;
	}
	else
	{
		return 1;
	}
}

ReadyServ(client, bool:ready, bool:silent, bool:show, bool:priv)
{
	new String:log_string[256];
	CS_GetLogString(client, log_string, sizeof(log_string));
	if (ready)
	{
		if (GetConVarBool(g_h_stats_enabled) && g_player_list[client] == PLAYER_UNREADY)
		{
			Log2Game("\"player_ready\" \"%s\"", log_string);
		}
		g_player_list[client] = PLAYER_READY;
		if (!silent)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Ready");
		}
	}
	else
	{
		if (GetConVarBool(g_h_stats_enabled) && g_player_list[client] == PLAYER_READY)
		{
			Log2Game("\"player_unready\" \"%s\"", log_string);
		}
		g_player_list[client] = PLAYER_UNREADY;
		if (!silent)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Not Ready");
		}
	}
	
	if (show)
	{
		ShowInfo(client, true, priv, 0);
	}
	
	CheckReady();
}

CheckReady()
{
	if ((GetConVarBool(g_h_req_names) && (StrEqual(g_t_name, DEFAULT_T_NAME, false) || StrEqual(g_ct_name, DEFAULT_CT_NAME, false))) && (!GetConVarBool(g_h_auto_knife) || g_t_had_knife))
	{
		return;
	}
	
	new ready_num;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_player_list[i] == PLAYER_READY && IsClientInGame(i) && !IsFakeClient(i))
		{
			ready_num++;
		}
	}
	
	if (g_ready_enabled && !g_live && (ready_num >= GetConVarInt(g_h_min_ready) || GetConVarInt(g_h_min_ready) == 0))
	{
		if (!g_t_had_knife && !g_match && GetConVarBool(g_h_auto_knife))
		{
			ShowInfo(0, false, false, 1);
			SetAllCancelled(false);
			ReadySystem(false);
			KnifeOn3(0, 0);
			return;
		}
		ShowInfo(0, false, false, 1);
		SetAllCancelled(false);
		ReadySystem(false);
		LiveOn3(true);
	}
}

LiveOn3(bool:e_war)
{
	Call_StartForward(g_f_on_lo3);
	Call_Finish();
	
	g_t_score = false;
	
	new String:match_config[64];
	GetConVarString(g_h_match_config, match_config, sizeof(match_config));
	
	new String:live_config[64];
	GetConVarString(g_h_live_config, live_config, sizeof(live_config));
	
	if (e_war && !StrEqual(match_config, ""))
	{
		ServerCommand("exec %s", match_config);
	}
	
	if (g_overtime)
	{
		ServerCommand("mp_startmoney %d", GetConVarInt(g_h_overtime_money));
	}
	
	if (!g_match)
	{
		g_match_start = GetEngineTime();
		
		new String:date[32];
		FormatTime(date, sizeof(date), "%Y-%m-%d-%H%M");
		
		new String:t_name[64];
		new String:ct_name[64];
		t_name = g_t_name;
		ct_name = g_ct_name;
		StripFilename(t_name, sizeof(t_name));
		StripFilename(ct_name, sizeof(ct_name));
		StringToLower(t_name, sizeof(t_name));
		StringToLower(ct_name, sizeof(ct_name));
		if (!StrEqual(g_t_name, DEFAULT_T_NAME, false) || !StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
		{
			Format(g_log_filename, sizeof(g_log_filename), "%s-%s-%s-vs-%s", date, g_map, t_name, ct_name);
		}
		else
		{
			Format(g_log_filename, sizeof(g_log_filename), "%s-%s", date, g_map);
		}
		
		new String:save_dir[128];
		GetConVarString(g_h_save_file_dir, save_dir, sizeof(save_dir));
		new String:file_prefix[1];
		if (GetConVarBool(g_h_prefix_logs))
		{
			file_prefix = "_";
		}
		if (GetConVarBool(g_h_auto_record))
		{
			ServerCommand("tv_stoprecord");
			if (DirExists(save_dir))
			{
				ServerCommand("tv_record \"%s/%s%s.dem\"", save_dir, file_prefix, g_log_filename);
				g_log_warmod_dir = true;
			}
			else
			{
				ServerCommand("tv_record \"%s%s.dem\"", file_prefix, g_log_filename);
				g_log_warmod_dir = false;
			}
		}
		
		if (GetConVarBool(g_h_stats_enabled))
		{
			new String:filepath[128];
			if (DirExists(save_dir))
			{
				Format(filepath, sizeof(filepath), "%s/%s%s.log", save_dir, file_prefix, g_log_filename);
				g_log_file = OpenFile(filepath, "w");
				g_log_warmod_dir = true;
			}
			else if (DirExists("logs"))
			{
				Format(filepath, sizeof(filepath), "logs/%s%s.log", file_prefix, g_log_filename);
				g_log_file = OpenFile(filepath, "w");
				g_log_warmod_dir = false;
			}
		}
		
		LogPlayers();
	}
	
	if (!GetConVarBool(g_h_live_override))
	{
		ServerCommand("exec %s", live_config);
	}
	else
	{
		LiveOn3Override();
	}
	
	g_match = true;
	g_live = true;
	
	CreateTimer(10.0, AdvertGameTechSpecs);
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		Log2Game("\"live_on_3\" (map \"%s\") (t \"%s\") (ct \"%s\") (status \"%d\") (version \"%s\")", g_map, g_t_name, g_ct_name, UpdateStatus(), WM_VERSION);
	}
}

stock LiveOn3Override()
{
	new Handle:kv = CreateKeyValues("live_override");
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/warmod_live_override.txt");
	if (!FileToKeyValues(kv, path))
	{
		return false;
	}
	new String:text[128];
	new lastdelay;
	new delay;
	
	if (KvJumpToKey(kv, "live_first_restart"))
	{
		delay = KvGetNum(kv, "delay");
		KvGetString(kv, "text", text, sizeof(text));
		CreateTimer(0.1, RestartRound, delay);
		new Handle:datapack;
		CreateDataTimer(0.9, PrintToChatDelayed, datapack);
		WritePackString(datapack, text);
		lastdelay = delay;
		KvGoBack(kv);
	}
	if (KvJumpToKey(kv, "live_second_restart"))
	{
		delay = KvGetNum(kv, "delay");
		KvGetString(kv, "text", text, sizeof(text));
		CreateTimer(float(lastdelay) + 1.3, RestartRound, delay);
		new Handle:datapack;
		CreateDataTimer(float(lastdelay) + 2.0, PrintToChatDelayed, datapack);
		WritePackString(datapack, text);
		lastdelay = lastdelay + delay;
		KvGoBack(kv);
	}
	if (KvJumpToKey(kv, "live_third_restart"))
	{
		delay = KvGetNum(kv, "delay");
		KvGetString(kv, "text", text, sizeof(text));
		CreateTimer(float(lastdelay) + 2.5, RestartRound, delay);
		new Handle:datapack;
		CreateDataTimer(float(lastdelay) + 3.5, PrintToChatDelayed, datapack);
		WritePackString(datapack, text);
		lastdelay = lastdelay + delay;
		KvGoBack(kv);
	}
	if (KvJumpToKey(kv, "live_finished"))
	{
		new String:key[8];
		for (new i = 1; i <= 5; i++)
		{
			IntToString(i, key, sizeof(key));
			Format(key, sizeof(key), "text%s", key);
			
			KvGetString(kv, key, text, sizeof(text));
			if (!StrEqual(text, ""))
			{
				new Handle:datapack;
				CreateDataTimer(float(lastdelay) + 3.5, PrintToChatDelayed, datapack);
				WritePackString(datapack, text);
			}
		}
	}
	CloseHandle(kv);
	return true;
}

public Action:AdvertGameTech(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsFakeClient(client))
	{
		PrintToChat(client, "\x03Посетите нашу группу в VK:");
		PrintToChat(client, "\x03www.vk.com/atomic26");
	}
}

public Action:AdvertGameTechSpecs(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsFakeClient(i))
		{
			PrintToChat(i, "\x03Посетите нашу группу в VK:");
			PrintToChat(i, "\x03www.vk.com/atomic26");
		}
	}
}

public Action:KnifeOn3(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	g_t_knife = true;
	g_t_score = false;
	
	if (GetConVarBool(g_h_stats_enabled))
	{
		Log2Game("\"knife_on_3\" (map \"%s\") (t \"%s\") (ct \"%s\")", g_map, g_t_name, g_ct_name);
	}
	
	new String:match_config[64];
	GetConVarString(g_h_match_config, match_config, sizeof(match_config));
	
	if (!StrEqual(match_config, ""))
	{
		ServerCommand("exec %s", match_config);
	}
	
	new String:knife_config[64];
	GetConVarString(g_h_knife_config, knife_config, sizeof(knife_config));
	
	if (!GetConVarBool(g_h_live_override_knife))
	{
		ServerCommand("exec %s", knife_config);
	}
	else
	{
		KnifeOn3Override();
	}
	
	UpdateStatus();
	
	LogAction(client, -1, "\"knife_on_3\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

stock KnifeOn3Override()
{
	new Handle:kv = CreateKeyValues("live_override");
	new String:path[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, path, sizeof(path), "configs/warmod_live_override_knife.txt");
	if (!FileToKeyValues(kv, path))
	{
		return false;
	}
	new String:text[128];
	new lastdelay;
	new delay;
	
	if (KvJumpToKey(kv, "live_first_restart"))
	{
		delay = KvGetNum(kv, "delay");
		KvGetString(kv, "text", text, sizeof(text));
		CreateTimer(0.1, RestartRound, delay);
		new Handle:datapack;
		CreateDataTimer(0.9, PrintToChatDelayed, datapack);
		WritePackString(datapack, text);
		lastdelay = delay;
		KvGoBack(kv);
	}
	if (KvJumpToKey(kv, "live_second_restart"))
	{
		delay = KvGetNum(kv, "delay");
		KvGetString(kv, "text", text, sizeof(text));
		CreateTimer(float(lastdelay) + 1.3, RestartRound, delay);
		new Handle:datapack;
		CreateDataTimer(float(lastdelay) + 2.0, PrintToChatDelayed, datapack);
		WritePackString(datapack, text);
		lastdelay = lastdelay + delay;
		KvGoBack(kv);
	}
	if (KvJumpToKey(kv, "live_third_restart"))
	{
		delay = KvGetNum(kv, "delay");
		KvGetString(kv, "text", text, sizeof(text));
		CreateTimer(float(lastdelay) + 2.5, RestartRound, delay);
		new Handle:datapack;
		CreateDataTimer(float(lastdelay) + 3.5, PrintToChatDelayed, datapack);
		WritePackString(datapack, text);
		lastdelay = lastdelay + delay;
		KvGoBack(kv);
	}
	if (KvJumpToKey(kv, "live_finished"))
	{
		new String:key[8];
		for (new i = 1; i <= 5; i++)
		{
			IntToString(i, key, sizeof(key));
			Format(key, sizeof(key), "text%s", key);
			
			KvGetString(kv, key, text, sizeof(text));
			if (!StrEqual(text, ""))
			{
				new Handle:datapack;
				CreateDataTimer(float(lastdelay) + 3.5, PrintToChatDelayed, datapack);
				WritePackString(datapack, text);
			}
		}
	}
	CloseHandle(kv);
	return true;
}

public Action:ChooseTeam(client, args)
{
	if (!IsActive(client, true))
	{
		return Plugin_Continue;
	}
		
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	if (g_match && GetClientTeam(client) > 1 && GetConVarBool(g_h_locked))
	{
		PrintToChat(client, "\x03<AtomMod> \x04%t", "Change Teams Midgame");
		return Plugin_Stop;
	}
	
	new max_players = GetConVarInt(g_h_max_players);
	if ((g_ready_enabled || g_match) && max_players != 0 && GetClientTeam(client) <= 1 && CS_GetPlayingCount() >= max_players)
	{
		PrintToChat(client, "\x03<AtomMod> \x04%t", "Maximum Players");
		ChangeClientTeam(client, SPECTATOR_TEAM);
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public Action:RestrictBuy(client, args)
{
	if (!IsActive(client, true))
	{
		return Plugin_Continue;
	}
	
	if (client == 0)
	{
		return Plugin_Continue;
	}
	
	new String:arg[128];
	GetCmdArgString(arg, 128);
	if (StrEqual(arg, "nvgs", false) && GetConVarBool(g_h_night_vision))
	{
		PrintToChat(client, "\x03<AtomMod> \x04%t", "Nightvision Blocked");
		return Plugin_Handled;
	}
	
	if (!g_live && GetConVarBool(g_h_warm_up_grens))
	{
		new String:the_weapon[32];
		Format(the_weapon, sizeof(the_weapon), "%s", arg);
		ReplaceString(the_weapon, sizeof(the_weapon), "weapon_", "");
		ReplaceString(the_weapon, sizeof(the_weapon), "item_", "");
		
		if (StrContains(the_weapon, "hegren", false) != -1 || StrContains(the_weapon, "flash", false) != -1 || StrContains(the_weapon, "smokegrenade", false) != -1)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Grenades Blocked");
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:ReadyList(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	new String:player_name[32];
	new player_count;
	
	ReplyToCommand(client, "<AtomMod> %T:", "Ready System", LANG_SERVER);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			GetClientName(i, player_name, sizeof(player_name));
			if (g_player_list[i] == PLAYER_UNREADY)	{
				ReplyToCommand(client, "unready > %s", player_name);
				player_count++;
			}
		}
	}
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			GetClientName(i, player_name, sizeof(player_name));
			if (g_player_list[i] == PLAYER_READY)
			{
				ReplyToCommand(client, "ready > %s", player_name);
				player_count++;
			}
		}
	}
	if (player_count == 0)
	{
		ReplyToCommand(client, "%T", "No Players Found", LANG_SERVER);
	}
	
	return Plugin_Handled;
}

public Action:NotLive(client, args)
{ 
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	ResetHalf(false);
	
	if (client == 0)
	{
		PrintToServer("<AtomMod> %T", "Half Reset", LANG_SERVER);
	}
	
	LogAction(client, -1, "\"half_reset\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:CancelMatch(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	ResetMatch(false);
	
	if (client == 0)
	{
		PrintToServer("<AtomMod> %T", "Match Reset", LANG_SERVER);
	}
	
	LogAction(client, -1, "\"match_reset\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:CancelKnife(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	if (g_t_knife)
	{
		if (GetConVarBool(g_h_stats_enabled))
		{
			Log2Game("\"knife_reset\"");
		}
		
		g_t_knife = false;
		g_t_had_knife = false;
		ServerCommand("mp_restartgame 1");
		for (new x = 1; x <= 3; x++)
		{
			PrintToChatAll("\x03<AtomMod> \x04%t", "Knife Round Cancelled");
		}
		if (client == 0)
		{
			PrintToServer("<AtomMod> %T", "Knife Round Cancelled", LANG_SERVER);
		}
	}
	else
	{
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Knife Round Inactive");
		}
		else
		{
			PrintToServer("<AtomMod> %T", "Knife Round Inactive", LANG_SERVER);
		}
	}
	
	UpdateStatus();
	
	LogAction(client, -1, "\"knife_reset\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

ReadySystem(bool:enable)
{
	if (enable)
	{
		if (GetConVarBool(g_h_stats_enabled))
		{
			Log2Game("\"ready_system\" \"enable\"");
		}
		g_ready_enabled = true;
	}
	else
	{
		if (GetConVarBool(g_h_stats_enabled))
		{
			Log2Game("\"ready_system\" \"disable\"");
		}
		g_ready_enabled = false;
	}
}

ShowInfo(client, bool:enable, bool:priv, time)
{
	if (!IsActive(client, true))
	{
		return;
	}
	
	if (priv && g_cancel_list[client])
	{
		return;
	}
		
	if (!GetConVarBool(g_h_show_info))
	{
		return;
	}
	
	if (!enable)
	{
		g_m_ready_up = CreatePanel();
		new String:panel_title[128];
		Format(panel_title, sizeof(panel_title), "<AtomMod> %t", "Ready System Disabled", client);
		SetPanelTitle(g_m_ready_up, panel_title);
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				SendPanelToClient(g_m_ready_up, i, Handler_DoNothing, time);
			}
		}
		
		CloseHandle(g_m_ready_up);
		
		UpdateStatus();
		
		return;
	}
	
	new String:players_unready[192];
	new String:player_name[32];
	new String:player_temp[192];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (g_player_list[i] == PLAYER_UNREADY && IsClientInGame(i) && !IsFakeClient(i))
		{
			GetClientName(i, player_name, sizeof(player_name));
			Format(player_temp, sizeof(player_temp), "  %s\n", player_name);
			StrCat(players_unready, sizeof(players_unready), player_temp);
		}
	}
	
	if (priv)
	{
		DispInfo(client, players_unready, time);
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) && !g_cancel_list[i])
			{
				DispInfo(i, players_unready, time);
			}
		}
	}
	UpdateStatus();
}

DispInfo(client, String:players_unready[], time)
{
	new String:Temp[128];
	SetGlobalTransTarget(client);
	g_m_ready_up = CreatePanel();
	Format(Temp, sizeof(Temp), "AtomMod - %t.\n%t.", "Ready System", "www.vk.com/atomic26");
	SetPanelTitle(g_m_ready_up, Temp);
	DrawPanelText(g_m_ready_up, "\n \n");
	Format(Temp, sizeof(Temp), "%t!", "Match Begin Msg", GetConVarInt(g_h_min_ready));
	DrawPanelItem(g_m_ready_up, Temp);
	DrawPanelText(g_m_ready_up, "\n \n");	
	Format(Temp, sizeof(Temp), "%t", "Info Not Ready");
	DrawPanelItem(g_m_ready_up, Temp);
	DrawPanelText(g_m_ready_up, players_unready);
	DrawPanelText(g_m_ready_up, " \n");
	Format(Temp, sizeof(Temp), "%t", "Info Exit");
	DrawPanelItem(g_m_ready_up, Temp);
	SendPanelToClient(g_m_ready_up, client, Handler_ReadySystem, time);
	CloseHandle(g_m_ready_up);
}

ReadyChangeAll(client, bool:up, bool:silent)
{
	if (up)
	{
		if (GetConVarBool(g_h_stats_enabled))
		{
			Log2Game("\"ready_all\"");
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) &&  GetClientTeam(i) > 1)
			{
				g_player_list[i] = PLAYER_READY;
			}
		}
	}
	else
	{
		if (GetConVarBool(g_h_stats_enabled))
		{
			Log2Game("\"unready_all\"");
		}
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i) &&  GetClientTeam(i) > 1)
			{
				g_player_list[i] = PLAYER_UNREADY;
			}
		}
	}
	if (!silent)
	{
		ShowInfo(client, true, true, 0);
	}
}

IsReadyEnabled(client, bool:silent)
{
	if (g_ready_enabled)
	{
		return true;
	}
	else
	{
		if (!silent)
		{
			if (client != 0)
			{
				PrintToChat(client, "\x03<AtomMod> \x04%t", "Ready System Disabled2");
			}
			else
			{
				PrintToServer("<AtomMod> %T", "Ready System Disabled2", LANG_SERVER);
			}
		}
	}
	return false;
}

IsLive(client, bool:silent)
{
	if (!g_live)
	{
		return false;
	}
	else
	{
		if (!silent)
		{
			if (client != 0)
			{
				PrintToChat(client, "\x03<AtomMod> \x04%t", "Match Is Live");
			}
			else
			{
				PrintToServer("<AtomMod> %T", "Match Is Live", LANG_SERVER);
			}
		}
	}
	return true;
}

IsActive(client, bool:silent)
{
	if (g_active)
	{
		return true;
	}
	else
	{
		if (!silent)
		{
			if (client != 0)
			{
				PrintToChat(client, "\x03<AtomMod> \x04%t", "WarMod Inactive");
			}
			else
			{
				PrintToServer("AtomMod - %T", "AtomMod Inactive", LANG_SERVER);
			}
		}
	}
	return false;
}

IsAdminCmd(client, bool:silent)
{
	if (client == 0 || !GetConVarBool(g_h_rcon_only))
	{
		return true;
	}
	else
	{
		if (!silent)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "AtomMod Rcon Only");
		}
	}
	return false;
}

public OnActiveChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (StringToInt(newVal) != 0)
	{
		g_active = true;
	}
	else
	{
		g_active = false;
	}
}
public OnReqNameChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	CheckReady();
}

public OnMinReadyChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (!g_live && g_ready_enabled)
	{
		ShowInfo(0, true, false, 0);
	}
	
	if (!g_match && g_ready_enabled)
	{
		CheckReady();
	}
}

public OnStatsTraceChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (g_stats_trace_timer != INVALID_HANDLE)
	{
		KillTimer(g_stats_trace_timer);
		g_stats_trace_timer = INVALID_HANDLE;
	}
	if (!StrEqual(newVal, "0", false))
	{
		g_stats_trace_timer = CreateTimer(GetConVarFloat(g_h_stats_trace_delay), Stats_Trace, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnStatsTraceDelayChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (g_stats_trace_timer != INVALID_HANDLE)
	{
		KillTimer(g_stats_trace_timer);
		g_stats_trace_timer = INVALID_HANDLE;
	}
	if (GetConVarBool(g_h_stats_trace_enabled))
	{
		g_stats_trace_timer = CreateTimer(GetConVarFloat(g_h_stats_trace_delay), Stats_Trace, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnAutoReadyChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (!g_match && !g_ready_enabled && StrEqual(newVal, "1", false))
	{
		ReadySystem(true);
		ReadyChangeAll(0, false, true);
		SetAllCancelled(false);
		ShowInfo(0, true, false, 0);
	}
}

public OnMaxRoundChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (g_live)
	{
		CheckScores();
	}
}

public OnTChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!StrEqual(newVal, ""))
	{
		Format(g_t_name, sizeof(g_t_name), "%s", newVal);
	}
	else
	{
		Format(g_t_name, sizeof(g_t_name), "%s", DEFAULT_T_NAME);
		SetConVarStringHidden(g_h_t, DEFAULT_T_NAME);
	}
	
	CheckReady();
}

public OnCTChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (!StrEqual(newVal, ""))
	{
		Format(g_ct_name, sizeof(g_ct_name), "%s", newVal);
	}
	else
	{
		Format(g_ct_name, sizeof(g_ct_name), "%s", DEFAULT_CT_NAME);
		SetConVarStringHidden(g_h_ct, DEFAULT_CT_NAME);
	}
	
	CheckReady();
}

public Handler_ReadySystem(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		if (param2 == 3)
		{
			g_cancel_list[param1] = true;
		}
	}
}

public Handler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	/* Do nothing */
}

public SetAllCancelled(bool:cancelled)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
		{
			g_cancel_list[i] = cancelled;
		}
	}
}

public Action:ChangeT(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	new String:name[32];
	
	if (GetCmdArgs() > 0)
	{
		GetCmdArgString(name, sizeof(name));
		Format(g_t_name, sizeof(g_t_name), "%s", name);
		SetConVarStringHidden(g_h_t, name);
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Change T Name", name);
		}
		else
		{
			PrintToServer("AtomMod - %T", "Change T Name", LANG_SERVER, name);
		}
		CheckReady();
		LogAction(client, -1, "\"set_t_name\" (player \"%L\") (name \"%s\")", client, name);
	}
	else
	{
		GetConVarString(g_h_t, name, sizeof(name));
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04wm_t = %s", name);
		}
		else
		{
			PrintToServer("AtomMod - wm_t = %s", name);
		}
	}
	
	return Plugin_Handled;
}

public Action:ChangeCT(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	new String:name[32];
	
	if (GetCmdArgs() > 0)
	{
		GetCmdArgString(name, sizeof(name));
		Format(g_ct_name, sizeof(g_ct_name), "%s", name);
		SetConVarStringHidden(g_h_ct, name);
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04%t", "Change CT Name", name);
		}
		else
		{
			PrintToServer("AtomMod - %T", "Change CT Name", LANG_SERVER, name);
		}
		CheckReady();
		LogAction(client, -1, "\"set_ct_name\" (player \"%L\") (name \"%s\")", client, name);
	}
	else
	{
		GetConVarString(g_h_ct, name, sizeof(name));
		if (client != 0)
		{
			PrintToChat(client, "\x03<AtomMod> \x04wm_ct = %s", name);
		}
		else
		{
			PrintToServer("AtomMod - wm_ct = %s", name);
		}
	}
	
	return Plugin_Handled;
}

public Action:SayChat(client, args)
{
	if (!IsActive(0, true))
	{
		return Plugin_Continue;
	}
	
	if (client == 0 && args != 0)
	{
		if (GetConVarBool(g_h_modifiers))
		{
			new String:text[192];
			GetCmdArgString(text, sizeof(text));		
			PrintToChatAll("\x03%t\x01%s", "Console", text);
			LogToGame("\"%L\" say \"%s\"", client, text);
			return Plugin_Handled;
		}
		else
		{
			return Plugin_Continue;
		}
	}
	else
	{
		new String:text[192];
		new start_index;
		GetCmdArgString(text, sizeof(text));
		
		if (text[strlen(text)-1] == '"')
		{
			text[strlen(text)-1] = '\0';
			start_index = 1;
		}
		
		if (text[start_index] == '@' && GetConVarBool(g_h_global_chat))
		{
			if (CheckAdminForChat(client))
			{
				new String:message[192];
				strcopy(message, 192, text[start_index + 1]);
				
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && !IsFakeClient(i))
					{
						PrintToChat(i, "\x03%t\x01%s", "Console", message);
					}
				}
				
				LogToGame("\"%L\" say \"%s\"", 0, message);
			}
			else
			{
				PrintToChat(client, "\03<AtomMod> \x04%t", "No Permission");
			}
			return Plugin_Handled;
		}
		
		new msg_start;
		
		if (text[start_index] == '!' || text[start_index] == '.' || text[start_index] == '/')
		{
			msg_start = 1;
		}
		
		new String:message[192];
		strcopy(message, 192, text[start_index + msg_start]);
		
		new String:name[64];
		GetClientName(client, name, sizeof(name));
		
		if (msg_start == 0)
		{
			return Plugin_Continue;
		}
		
		new String:command[192];
		new String:split_str[8][32];
		ExplodeString(text[start_index + msg_start], " ", split_str, 8, 32);
		strcopy(command, 192, split_str[0]);
		
		if (StrEqual(command, "ready", false) || StrEqual(command, "rdy", false) || StrEqual(command, "r", false))
		{
			ReadyUp(client);
		}
		else if (StrEqual(command, "unready", false) || StrEqual(command, "notready", false) || StrEqual(command, "unrdy", false) || StrEqual(command, "notrdy", false) || StrEqual(command, "ur", false) || StrEqual(command, "nr", false))
		{
			ReadyDown(client);
		}
		else if (StrEqual(command, "scores", false) || StrEqual(command, "score", false) || StrEqual(command, "s", false))
		{
			ShowScore(client);
		}
		else if (StrEqual(command, "info", false) || StrEqual(command, "i", false))
		{
			if (GetConVarBool(g_h_show_info))
			{
				ReadyInfoPriv(client);
			}
			else
			{
				PrintToChat(client, "\03<AtomMod> \x04%t", "ShowInfo Disabled");
			}
		}
		else if (StrEqual(command, "help", false))
		{
			DisplayHelp(client);
		}
		else
		{
			return Plugin_Continue;
		}
		
		new String:LogString[192];
		CS_GetLogString(client, LogString, sizeof(LogString));
		LogToGame("\"%s\" say \"%s\"", LogString, text[start_index]);
		
		return Plugin_Handled;
	}
}

public Action:SayTeamChat(client, args)
{
	if (!IsActive(0, true))
	{
		return Plugin_Continue;
	}
	
	if (client != 0 && args != 0)
	{
		new String:text[192];
		GetCmdArgString(text, sizeof(text));
		
		new start_index;
		if (text[strlen(text)-1] == '"')
		{
			text[strlen(text)-1] = '\0';
			start_index = 1;
		}
		
		new String:LogString[192];
		CS_GetLogString(client, LogString, sizeof(LogString));
		
		LogToGame("\"%s\" say_team \"%s\"", LogString, text[start_index]);
		
		new msg_start = 0;
		
		if (text[start_index] == '!' || text[start_index] == '.' || text[start_index] == '/')
		{
			msg_start = 1;
		}
		
		new String:message[192];
		strcopy(message, 192, text[start_index + msg_start]);
		
		new client_team = GetClientTeam(client);
		new String:client_name[32];
		GetClientName(client, client_name, sizeof(client_name));
		
		if (msg_start == 1)
		{
			new String:command[192];
			new String:split_str[8][32];
			ExplodeString(text[start_index + msg_start], " ", split_str, 8, 32);
			strcopy(command, 192, split_str[0]);
			
			if (StrEqual(command, "ready", false) || StrEqual(command, "rdy", false) || StrEqual(command, "r", false))
			{
				ReadyUp(client);
				return Plugin_Handled;
			}
			else if (StrEqual(command, "unready", false) || StrEqual(command, "notready", false) || StrEqual(command, "unrdy", false) || StrEqual(command, "notrdy", false) || StrEqual(command, "ur", false) || StrEqual(command, "nr", false))
			{
				ReadyDown(client);
				return Plugin_Handled;
			}
			else if (StrEqual(command, "scores", false) || StrEqual(command, "score", false) || StrEqual(command, "s", false))
			{
				ShowScore(client);
				return Plugin_Handled;
			}
			else if (StrEqual(command, "info", false) || StrEqual(command, "i", false))
			{
				if (GetConVarBool(g_h_show_info))
				{
					ReadyInfoPriv(client);
				}
				else
				{
					PrintToChat(client, "\03<AtomMod> \x04%t", "ShowInfo Disabled");
				}
				return Plugin_Handled;
			}
			else if (StrEqual(command, "help", false))
			{
				DisplayHelp(client);
				return Plugin_Handled;
			}
		}
		
		if (!GetConVarBool(g_h_modifiers))
		{
			return Plugin_Continue;
		}
		
		strcopy(message, 192, text[start_index]);
		
		new client_list[MAXPLAYERS + 1];
		new client_num = 0;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsPlayerAlive(client))
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == client_team)
				{
					client_list[client_num] = i;
					client_num++;
				}
			}
			else
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == client_team && !IsPlayerAlive(i))
				{
					client_list[client_num] = i;
					client_num++;
				}
			}
		}
		
		new Handle:h_message = StartMessage("SayText2", client_list, client_num);
		BfWriteByte(h_message, client);
		BfWriteByte(h_message, true);
		if (IsPlayerAlive(client))
		{
			BfWriteString(h_message, "\x01(TEAM) \x03%s1 \x01:  %s2");
		}
		else
		{
			BfWriteString(h_message, "\x01*DEAD* (TEAM) \x03%s1 \x01:  %s2");
		}
		BfWriteString(h_message, client_name);
		BfWriteString(h_message, message);
		EndMessage();
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

SwitchScores()
{
	new temp;
	
	temp = g_scores[SCORE_T][SCORE_FIRST_HALF];
	g_scores[SCORE_T][SCORE_FIRST_HALF] = g_scores[SCORE_CT][SCORE_FIRST_HALF];
	g_scores[SCORE_CT][SCORE_FIRST_HALF] = temp;
	
	temp = g_scores[SCORE_T][SCORE_SECOND_HALF];
	g_scores[SCORE_T][SCORE_SECOND_HALF] = g_scores[SCORE_CT][SCORE_SECOND_HALF];
	g_scores[SCORE_CT][SCORE_SECOND_HALF] = temp;
	
	for (new i = 0; i <= g_overtime_count; i++)
	{
		temp = g_scores_overtime[SCORE_T][i][SCORE_FIRST_HALF];
		g_scores_overtime[SCORE_T][i][SCORE_FIRST_HALF] = g_scores_overtime[SCORE_CT][i][SCORE_FIRST_HALF];
		g_scores_overtime[SCORE_CT][i][SCORE_FIRST_HALF] = temp;
		
		temp = g_scores_overtime[SCORE_T][i][SCORE_SECOND_HALF];
		g_scores_overtime[SCORE_T][i][SCORE_SECOND_HALF] = g_scores_overtime[SCORE_CT][i][SCORE_SECOND_HALF];
		g_scores_overtime[SCORE_CT][i][SCORE_SECOND_HALF] = temp;
	}
}

SwitchTeams()
{
	new String:temp[64];
	temp = g_t_name;
	g_t_name = g_ct_name;
	SetConVarStringHidden(g_h_t, g_ct_name);
	g_ct_name = temp;
	SetConVarStringHidden(g_h_ct, temp);
}

public Action:SwapAll(client, args)
{
	if (!IsActive(client, false))
	{
		return Plugin_Handled;
	}
	
	if (!IsAdminCmd(client, false))
	{
		return Plugin_Handled;
	}
	
	CS_SwapTeams();
	SwitchScores();
	
	if (!StrEqual(g_t_name, DEFAULT_T_NAME, false) && !StrEqual(g_ct_name, DEFAULT_CT_NAME, false))
	{
		SwitchTeams();
	}
	
	LogAction(client, -1, "\"team_swap\" (player \"%L\")", client);
	
	return Plugin_Handled;
}

public Action:Swap(Handle:timer)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (!g_live)
	{
		CS_SwapTeams();
	}
}

public Action:UpdateInfo(Handle:timer)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (!g_live)
	{
		ShowInfo(0, true, false, 0);
	}
}

public Action:StopRecord(Handle:timer)
{
	if (!g_match)
	{
		ServerCommand("tv_stoprecord");
	}
}

public Action:ShowDamage(Handle:timer, any:dead_only)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (user_damage[i][0] != '\0' && IsClientInGame(i) && !IsFakeClient(i) && (!dead_only || (dead_only && !IsPlayerAlive(i))))
		{
			PrintToConsole(i, user_damage[i]);
			user_damage[i][0] = '\0';
		}
	}
}

public Action:SpecNextFake(Handle:timer, any:client)
{
	ResetSwitchCameraTimer(client, false);
	if (IsClientInGame(client) && GetClientTeam(client) > 0 && !IsPlayerAlive(client))
	{
		SpecNext(client, 0.4);
	}
}

public Action:SetSpecTimer(Handle:timer, any:client)
{
	if (IsClientInGame(client) && GetClientTeam(client) > 0 && !IsPlayerAlive(client))
	{
		FakeClientCommandEx(client, "spec_next");
		FakeClientCommandEx(client, "spec_mode 1");
		if (g_h_fade_to_black == INVALID_HANDLE)
		{
			g_h_fade_to_black = FindConVar("mp_fadetoblack");
		}
		if (g_h_fade_to_black != INVALID_HANDLE && GetConVarInt(g_h_fade_to_black) == 2)
		{
			new targets[2];
			targets[0] = client;
			new Handle:message = StartMessage("Fade", targets, 1, 1);
			BfWriteShort(message, 1536);
			BfWriteShort(message, 1536);
			BfWriteShort(message, (0x0001 | 0x0010));
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			BfWriteByte(message, 0);
			EndMessage();
		}
	}
}

public Action:RemoveRagdoll(Handle:timer, any:victim)
{
	if (!IsActive(0, true))
	{
		return;
	}
	
	if (IsValidEntity(victim) && !IsPlayerAlive(victim))
	{
		new player_ragdoll = GetEntDataEnt2(victim, g_i_ragdolls);
		if (player_ragdoll != -1)
		{
			RemoveEdict(player_ragdoll);
		}
	}
}

public Action:KickLoserTeam(Handle:timer, any:team)
{
	if (team != -1)
	{
		KickTeam(team);
	}
}

Log2Game(const String:Format[], any:...)
{
	decl String:buffer[1024];
	VFormat(buffer, sizeof(buffer), Format, 2);
	new stats_method = GetConVarInt(g_h_stats_method);
	if (stats_method == 0 || stats_method == 2)
	{
		LogToGame("WarMod triggered %s", buffer);
	}
	if ((stats_method == 1 || stats_method == 2) && g_log_file != INVALID_HANDLE)
	{
		LogToOpenFileEx(g_log_file, buffer);
	}
}

LogPlayers()
{
	new String:player_name[32];
	new String:authid[32];
	new String:team[32];
	new String:authip[32];
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) > 1 && !IsFakeClient(i))
		{
			GetClientName(i, player_name, sizeof(player_name));
			GetClientAuthString(i, authid, sizeof(authid));
			GetClientIP(i, authip, sizeof(authip));
			
			if (GetClientTeam(i) == TERRORIST_TEAM)
			{
				team = "TERRORIST";
			}
			else if (GetClientTeam(i) == COUNTER_TERRORIST_TEAM)
			{
				team = "CT";
			}
			else if (GetClientTeam(i) == SPECTATOR_TEAM)
			{
				team = "Spectator";
			}
			
			Log2Game("\"player_status\" \"%s<%s><%s><%s>\"", player_name, authid, authip, team);
		}
	}
}

public Action:Stats_Trace(Handle:timer)
{
	if (GetConVarBool(g_h_stats_enabled))
	{
		new String:log_string[256];
		for (new i = 1; i < MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) > 1 && !IsFakeClient(i) && IsPlayerAlive(i))
			{
				CS_GetAdvLogString(i, log_string, sizeof(log_string));
				Log2Game("\"player_trace\" (player \"%s\")", log_string);
			}
		}
	}
}

RenameLogs()
{
	new String:save_dir[128];
	GetConVarString(g_h_save_file_dir, save_dir, sizeof(save_dir));
	if (g_log_file != INVALID_HANDLE)
	{
		CloseHandle(g_log_file);
		g_log_file = INVALID_HANDLE;
		new String:old_log_filename[128];
		new String:new_log_filename[128];
		if (g_log_warmod_dir)
		{
			Format(old_log_filename, sizeof(old_log_filename), "%s/_%s.log", save_dir, g_log_filename);
			Format(new_log_filename, sizeof(new_log_filename), "%s/%s.log", save_dir, g_log_filename);
		}
		else
		{
			Format(old_log_filename, sizeof(old_log_filename), "logs/_%s.log", g_log_filename);
			Format(new_log_filename, sizeof(new_log_filename), "logs/%s.log", g_log_filename);
		}
		RenameFile(new_log_filename, old_log_filename);
	}
	CreateTimer(15.0, RenameDemos);
}

public Action:RenameDemos(Handle:timer)
{
	new String:save_dir[128];
	GetConVarString(g_h_save_file_dir, save_dir, sizeof(save_dir));
	new String:old_demo_filename[128];
	new String:new_demo_filename[128];
	if (g_log_warmod_dir)
	{
		Format(old_demo_filename, sizeof(old_demo_filename), "%s/_%s.dem", save_dir, g_log_filename);
		Format(new_demo_filename, sizeof(new_demo_filename), "%s/%s.dem", save_dir, g_log_filename);
	}
	else
	{
		Format(old_demo_filename, sizeof(old_demo_filename), "_%s.dem", g_log_filename);
		Format(new_demo_filename, sizeof(new_demo_filename), "%s.dem", g_log_filename);	
	}
	RenameFile(new_demo_filename, old_demo_filename);
}

ResetPlayerStats(client)
{
	for (new i = 0; i < NUM_WEAPONS; i++)
	{
		for (new x = 0; x < LOG_HIT_NUM; x++)
		{
			weapon_stats[client][i][x] = 0;
		}
	}
}

ResetClutchStats()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		clutch_stats[i][CLUTCH_LAST] = 0;
		clutch_stats[i][CLUTCH_VERSUS] = 0;
		clutch_stats[i][CLUTCH_FRAGS] = 0;
		clutch_stats[i][CLUTCH_WON] = 0;
	}
}

LogPlayerStats(client)
{
	if (IsClientInGame(client) && GetClientTeam(client) > 1)
	{
		new String:log_string[256];
		CS_GetLogString(client, log_string, sizeof(log_string));
		for (new i = 0; i < NUM_WEAPONS; i++)
		{
			if (weapon_stats[client][i][LOG_HIT_SHOTS] > 0 || weapon_stats[client][i][LOG_HIT_DEATHS] > 0)
			{
				Log2Game("\"weapon_stats\" (player \"%s\") (weapon \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\") (generic \"%d\")", log_string, weapon_list[i], weapon_stats[client][i][LOG_HIT_SHOTS], weapon_stats[client][i][LOG_HIT_HITS], weapon_stats[client][i][LOG_HIT_KILLS], weapon_stats[client][i][LOG_HIT_HEADSHOTS], weapon_stats[client][i][LOG_HIT_TEAMKILLS], weapon_stats[client][i][LOG_HIT_DAMAGE], weapon_stats[client][i][LOG_HIT_DEATHS], weapon_stats[client][i][LOG_HIT_HEAD], weapon_stats[client][i][LOG_HIT_CHEST], weapon_stats[client][i][LOG_HIT_STOMACH], weapon_stats[client][i][LOG_HIT_LEFTARM], weapon_stats[client][i][LOG_HIT_RIGHTARM], weapon_stats[client][i][LOG_HIT_LEFTLEG], weapon_stats[client][i][LOG_HIT_RIGHTLEG], weapon_stats[client][i][LOG_HIT_GENERIC]);
			}
		}
		new round_stats[LOG_HIT_NUM];
		for (new i = 0; i < NUM_WEAPONS; i++)
		{
			for (new x = 0; x < LOG_HIT_NUM; x++)
			{
				round_stats[x] += weapon_stats[client][i][x];
			}
		}
		Log2Game("\"round_stats\" (player \"%s\") (shots \"%d\") (hits \"%d\") (kills \"%d\") (headshots \"%d\") (tks \"%d\") (damage \"%d\") (deaths \"%d\") (head \"%d\") (chest \"%d\") (stomach \"%d\") (leftarm \"%d\") (rightarm \"%d\") (leftleg \"%d\") (rightleg \"%d\") (generic \"%d\")", log_string, round_stats[LOG_HIT_SHOTS], round_stats[LOG_HIT_HITS], round_stats[LOG_HIT_KILLS], round_stats[LOG_HIT_HEADSHOTS], round_stats[LOG_HIT_TEAMKILLS], round_stats[LOG_HIT_DAMAGE], round_stats[LOG_HIT_DEATHS], round_stats[LOG_HIT_HEAD], round_stats[LOG_HIT_CHEST], round_stats[LOG_HIT_STOMACH], round_stats[LOG_HIT_LEFTARM], round_stats[LOG_HIT_RIGHTARM], round_stats[LOG_HIT_LEFTLEG], round_stats[LOG_HIT_RIGHTLEG], round_stats[LOG_HIT_GENERIC]);
		ResetPlayerStats(client);
	}
}

LogClutchStats(client)
{
	if (IsClientInGame(client) && GetClientTeam(client) > 1)
	{
		if (clutch_stats[client][CLUTCH_LAST] == 1)
		{
			new String:log_string[256];
			CS_GetLogString(client, log_string, sizeof(log_string));
			Log2Game("\"player_clutch\" (player \"%s\") (versus \"%d\") (frags \"%d\") (bomb_planted \"%d\") (won \"%d\")", log_string, clutch_stats[client][CLUTCH_VERSUS], clutch_stats[client][CLUTCH_FRAGS], g_planted, clutch_stats[client][CLUTCH_WON]);
			clutch_stats[client][CLUTCH_LAST] = 0;
			clutch_stats[client][CLUTCH_VERSUS] = 0;
			clutch_stats[client][CLUTCH_FRAGS] = 0;
			clutch_stats[client][CLUTCH_WON] = 0;
		}
	}
}

GetWeaponIndex(const String:weapon[])
{
	for (new i = 0; i < NUM_WEAPONS; i++)
	{
		if (StrEqual(weapon, weapon_list[i], false))
		{
			return i;
		}
	}
	return -1;
}

Handle:MySQL_Connect()
{
	new String:error[256];
	new Handle:db = INVALID_HANDLE;
	
	if (SQL_CheckConfig("warmod"))
	{
		db = SQL_Connect("warmod", true, error, sizeof(error));
	}
	
	return db;
}

MySQL_UploadResults(match_length, String:map[], max_rounds, overtime_max_rounds, overtime_count, bool:played_out, String:t_name[], t_overall_score, t_first_half_score, t_second_half_score, t_overtime_score, String:ct_name[], ct_overall_score, ct_first_half_score, ct_second_half_score, ct_overtime_score)
{
	if (wm_db == INVALID_HANDLE)
	{
		return;
	}
	
	new String:error[256];
	new String:query_str[1024];
	new String:tbl_name[128];
	
	GetConVarString(g_h_table_name, tbl_name, sizeof(tbl_name));
	SQL_EscapeString(wm_db, tbl_name, tbl_name, sizeof(tbl_name));
	
	Format(query_str, sizeof(query_str), "CREATE TABLE IF NOT EXISTS `%s` ( `match_id` int(11) unsigned NOT NULL auto_increment, `match_start` datetime NOT NULL, `match_end` datetime NOT NULL, `map` varchar(64) NOT NULL, `max_rounds` tinyint(3) unsigned NOT NULL, `overtime_max_rounds` tinyint(3) unsigned NOT NULL, `overtime_count` tinyint(3) unsigned NOT NULL, `played_out` tinyint(1) NOT NULL, `t_name` varchar(128) NOT NULL, `t_overall_score` tinyint(3) unsigned NOT NULL, `t_first_half_score` tinyint(3) unsigned NOT NULL, `t_second_half_score` tinyint(3) unsigned NOT NULL, `t_overtime_score` tinyint(3) unsigned NOT NULL, `ct_name` varchar(128) NOT NULL, `ct_overall_score` tinyint(3) unsigned NOT NULL, `ct_first_half_score` tinyint(3) unsigned NOT NULL, `ct_second_half_score` tinyint(3) unsigned NOT NULL, `ct_overtime_score` tinyint(3) unsigned NOT NULL, PRIMARY KEY (`match_id`));", tbl_name);
	SQL_FastQuery(wm_db, query_str);
	
	Format(query_str, sizeof(query_str), "INSERT INTO `%s` (`match_id`, `match_start`, `match_end`, `map`, `max_rounds`, `overtime_max_rounds`, `overtime_count`, `played_out`, `t_name`, `t_overall_score`, `t_first_half_score`, `t_second_half_score`, `t_overtime_score`, `ct_name`, `ct_overall_score`, `ct_first_half_score`, `ct_second_half_score`, `ct_overtime_score`) VALUES (NULL, DATE_SUB(NOW(), INTERVAL ? SECOND), NOW(), ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)", tbl_name);
	new Handle:db_query = SQL_PrepareQuery(wm_db, query_str,	error, sizeof(error));
	
	if (db_query == INVALID_HANDLE)
	{
		return;
	}
	
	new pid = 0;
	
	SQL_BindParamInt(db_query, pid++, match_length, false);
	SQL_BindParamString(db_query, pid++, map, false);
	SQL_BindParamInt(db_query, pid++, max_rounds, false);
	SQL_BindParamInt(db_query, pid++, overtime_max_rounds, false);
	SQL_BindParamInt(db_query, pid++, overtime_count, false);
	if (played_out)
	{
		SQL_BindParamInt(db_query, pid++, 1, false);
	}
	else
	{
		SQL_BindParamInt(db_query, pid++, 0, false);
	}
	SQL_BindParamString(db_query, pid++, t_name, false);
	SQL_BindParamInt(db_query, pid++, t_overall_score, false);
	SQL_BindParamInt(db_query, pid++, t_first_half_score, false);
	SQL_BindParamInt(db_query, pid++, t_second_half_score, false);
	SQL_BindParamInt(db_query, pid++, t_overtime_score, false);
	SQL_BindParamString(db_query, pid++, ct_name, false);
	SQL_BindParamInt(db_query, pid++, ct_overall_score, false);
	SQL_BindParamInt(db_query, pid++, ct_first_half_score, false);
	SQL_BindParamInt(db_query, pid++, ct_second_half_score, false);
	SQL_BindParamInt(db_query, pid++, ct_overtime_score, false);
	
	SQL_Execute(db_query);
	
	CloseHandle(db_query);
}

public Action:MessageHandler(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	if (!IsActive(0, true))
	{
		return Plugin_Continue;
	}
	
	new String:msg_name[128];
	GetUserMessageName(msg_id, msg_name, sizeof(msg_name));
	new String:message[256];
	BfReadString(bf, message, sizeof(message));
	new String:msg[256];
	Format(msg, sizeof(msg), "%s", message[1]);
	TrimString(msg);
	if (GetConVarInt(g_h_damage) != 1 && StrEqual(msg_name, "TextMsg", false))
	{
		if (StrEqual(msg, "Damage Given to \"%s1\" - %s2") || StrEqual(msg, "Damage Taken from \"%s1\" - %s2"))
		{
			if (GetConVarInt(g_h_damage) == 0)
			{
				return Plugin_Handled;
			}
			new String:s1[128];
			new String:s2[128];
			BfReadString(bf, s1, sizeof(s1));
			BfReadString(bf, s2, sizeof(s2));
			ReplaceString(message, sizeof(message), "%s1", s1);
			ReplaceString(message, sizeof(message), "%s2", s2);
		}
		else if (StrEqual(msg, "Player: %s1 - Damage Given") || StrEqual(msg, "Player: %s1 - Damage Taken"))
		{
			if (GetConVarInt(g_h_damage) == 0)
			{
				return Plugin_Handled;
			}
			new String:s1[128];
			BfReadString(bf, s1, sizeof(s1));
			ReplaceString(message, sizeof(message), "%s1", s1);
		}
		else if (StrEqual(msg, "-------------------------"))
		{
			if (GetConVarInt(g_h_damage) == 0)
			{
				return Plugin_Handled;
			}
		}
		else
		{
			return Plugin_Continue;
		}
		
		for (new i = 0; i < playersNum; i++)
		{
			StrCat(user_damage[players[i]], DMG_MSG_SIZE, message);
		}
		
		return Plugin_Handled;
	}
	else if (GetConVarBool(g_h_remove_gren_sound) && StrEqual(msg_name, "SendAudio", false))
	{
		PrintToServer("Incoming: %s", message);
		if (StrEqual(message, "Radio.FireInTheHole", false))
		{
			return Plugin_Handled;
		}
	}
	else if (GetConVarBool(g_h_remove_hint_text) && StrEqual(msg_name, "HintText", false))
	{
		if (message[1] == '#' && StrContains(message, "#Hint", false) != 0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public MenuHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	new String:menu_name[256];
	GetTopMenuObjName(topmenu, object_id, menu_name, sizeof(menu_name));
	SetGlobalTransTarget(param);
	
	if (StrEqual(menu_name, "WarModCommands"))
	{
		if (action == TopMenuAction_DisplayTitle)
		{
			Format(buffer, maxlength, "%t:", "Admin_Menu WarMod Commands");
		}
		else if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%t", "Admin_Menu WarMod Commands");
		}
	}
	else if (StrEqual(menu_name, "forcestart"))
	{
		if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%t", "Admin_Menu Force Start");
		}
		else if (action == TopMenuAction_SelectOption)
		{
			ForceStart(param, 0);
		}
	}
	else if (StrEqual(menu_name, "readyup"))
	{
		if (action == TopMenuAction_DisplayOption)
		{
			if (g_ready_enabled)
			{
				Format(buffer, maxlength, "%t", "Admin_Menu Disable ReadyUp");
			}
			else
			{
				Format(buffer, maxlength, "%t", "Admin_Menu Enable ReadyUp");
			}
		}
		else if (action == TopMenuAction_SelectOption)
		{
			ReadyToggle(param, 0);
		}
	}
	else if (StrEqual(menu_name, "knife"))
	{
		if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%t", "Admin_Menu Knife");
		}
		else if (action == TopMenuAction_SelectOption)
		{
			KnifeOn3(param, 0);
		}
	}
	else if (StrEqual(menu_name, "cancelhalf"))
	{
		if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%t", "Admin_Menu Cancel Half");
		}
		else if (action == TopMenuAction_SelectOption)
		{
			NotLive(param, 0);
		}
	}
	else if (StrEqual(menu_name, "cancelmatch"))
	{
		if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%t", "Admin_Menu Cancel Match");
		}
		else if (action == TopMenuAction_SelectOption)
		{
			CancelMatch(param, 0);
		}
	}
	else if (StrEqual(menu_name, "forceallready"))
	{
		if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%t", "Admin_Menu ForceAllReady");
		}
		else if (action == TopMenuAction_SelectOption)
		{
			ForceAllReady(param, 0);
		}
	}
	else if (StrEqual(menu_name, "forceallunready"))
	{
		if (action == TopMenuAction_DisplayOption)
		{
			Format(buffer, maxlength, "%t", "Admin_Menu ForceAllUnready");
		}
		else if (action == TopMenuAction_SelectOption)
		{
			ForceAllUnready(param, 0);
		}
	}
	else if (StrEqual(menu_name, "toggleactive"))
	{
		if (action == TopMenuAction_DisplayOption)
		{
			if (GetConVarBool(g_h_active))
			{
				Format(buffer, maxlength, "%t", "Admin_Menu Deactivate WarMod");
			}
			else
			{
				Format(buffer, maxlength, "%t", "Admin_Menu Activate WarMod");
			}
		}
		else if (action == TopMenuAction_SelectOption)
		{
			ActiveToggle(param, 0);
		}
	}
}

public Action:RestartRound(Handle:timer, any:delay)
{
	ServerCommand("mp_restartgame %d", delay);
}

public Action:PrintToChatDelayed(Handle:timer, Handle:datapack)
{
	decl String:text[128];
	ResetPack(datapack);
	ReadPackString(datapack, text, sizeof(text));
	ServerCommand("say %s", text);
}

public Action:CheckNames(Handle:timer, any:client)
{
	if ((GetConVarBool(g_h_req_names) && g_ready_enabled && !g_live && (StrEqual(g_t_name, DEFAULT_T_NAME, false) || StrEqual(g_ct_name, DEFAULT_CT_NAME, false))) && (!GetConVarBool(g_h_auto_knife) || g_t_had_knife))
	{
		new num_ready;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (g_player_list[i] == PLAYER_READY && IsClientInGame(i) && !IsFakeClient(i))
			{
				num_ready++;
			}
		}
		if (num_ready >= GetConVarInt(g_h_min_ready))
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i))
				{
					PrintToChat(i, "\x03<AtomMod> \x04%t", "Names Required");
				}
			}
		}
	}
}

public Action:RespawnPlayer(Handle:timer, any:client)
{
	CS_RespawnPlayer(client);
	SetEntData(client, g_i_account, GetConVarInt(g_h_mp_startmoney));
}

public Action:HelpText(Handle:timer, any:client)
{
	if (!IsActive(0, true))
	{
		return Plugin_Handled;
	}
	
	if (!g_live && g_ready_enabled)
	{
		DisplayHelp(client);
	}
	
	return Plugin_Handled;
}

public DisplayHelp(client)
{
	if (client == 0)
	{
		PrintHintTextToAll("%t: /ready /unready /info /score", "Available Commands");
	}
	else
	{
		if (IsClientConnected(client) && IsClientInGame(client))
		{
			PrintHintText(client, "%t: /ready /unready /info /score", "Available Commands");
		}
	}
}

public Action:ShowPluginInfo(Handle:timer, any:client)
{
	if (client != 0 && IsClientConnected(client) && IsClientInGame(client))
	{
		new String:max_rounds[64];
		GetConVarName(g_h_max_rounds, max_rounds, sizeof(max_rounds));
		new String:min_ready[64];
		GetConVarName(g_h_min_ready, min_ready, sizeof(min_ready));
		new String:play_out[64];
		GetConVarName(g_h_play_out, play_out, sizeof(play_out));
		PrintToConsole(client, "=============================================================================================");
		PrintToConsole(client, "This server is running Atomic WarMod %s Server Plugin", WM_VERSION);
		PrintToConsole(client, "");
		PrintToConsole(client, "Messagemode commands:				Aliases:");
		PrintToConsole(client, "  /ready - Mark yourself as ready 		  /rdy /r");
		PrintToConsole(client, "  /unready - Mark yourself as not ready 	  /notready /unrdy /notrdy /ur /nr");
		PrintToConsole(client, "  /info - Display the Ready System if enabled 	  /i");
		PrintToConsole(client, "  /scores - Display the match score if live 	  /score /s");
		PrintToConsole(client, "");
		PrintToConsole(client, "Current settings: %s: %d / %s: %d / %s: %d", max_rounds, GetConVarInt(g_h_max_rounds), min_ready, GetConVarInt(g_h_min_ready), play_out, GetConVarBool(g_h_play_out));
		PrintToConsole(client, "=============================================================================================");
	}
}

public Action:WMVersion(client, args)
{
	if (client == 0)
	{
		PrintToServer("\"wm_version\" = \"%s\"\n - <AtomMod> %s", WM_VERSION, WM_DESCRIPTION);
	}
	else
	{
		PrintToConsole(client, "\"wm_version\" = \"%s\"\n - <AtomMod> %s", WM_VERSION, WM_DESCRIPTION);
	}
	
	return Plugin_Handled;
}

bool:CheckAdminForChat(client)
{
	new AdminId:aid = GetUserAdmin(client);
	if (aid == INVALID_ADMIN_ID)
	{
		return false;			
	}
	return GetAdminFlag(aid, Admin_Chat, Access_Effective);
}

UpdateStatus()
{
	new value;
	if (!g_match)
	{
		if (!g_t_knife)
		{
			if (!g_ready_enabled)
			{
				if (!g_t_had_knife)
				{
					value = 0;
				}
				else
				{
					value = 3;
				}
			}
			else
			{
				if (!g_t_had_knife && GetConVarBool(g_h_auto_knife))
				{
					value = 1;
				}
				else
				{
					value = 4;
				}
			}
		}
		else
		{
			value = 2;
		}
	}
	else
	{
		if (!g_overtime)
		{
			if (!g_live)
			{
				if (!g_ready_enabled)
				{
					if (g_first_half)
					{
						value = 3;
					}
					else
					{
						value = 6;
					}
				}
				else
				{
					if (g_first_half)
					{
						value = 4;
					}
					else
					{
						value = 7;
					}
				}
			}
			else
			{
				if (g_first_half)
				{
					value = 5;
				}
				else
				{
					value = 8;
				}
			}
		}
		else
		{
			if (!g_live)
			{
				if (!g_ready_enabled)
				{
					value = 9;
				}
				else
				{
					value = 10;
				}
			}
			else
			{
				if (g_first_half)
				{
					value = 11 + (g_overtime_count * 2);
				}
				else
				{
					value = 12 + (g_overtime_count * 2);
				}
			}
		}
	}
	SetConVarIntHidden(g_h_status, value);
	return value;
}

GetLoserTeam()
{
	if (GetTTotalScore() > GetCTTotalScore())
	{
		return COUNTER_TERRORIST_TEAM;
	}
	else if (GetTTotalScore() < GetCTTotalScore())
	{
		return TERRORIST_TEAM;
	}
	else return -1;
}

KickTeam(team)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{
			KickClient(i, "%t", "Autokick");
		}
	}
}

GetFrags(client)
{
	if (g_i_frags != -1 || (g_i_frags = FindDataMapOffs(client, "m_iFrags")) != -1)
	{
		return GetEntData(client, g_i_frags);
	}
	
	return false;
}

SetFrags(client, frags)
{
	if (g_i_frags != -1 || (g_i_frags = FindDataMapOffs(client, "m_iFrags")) != -1)
	{
		SetEntData(client, g_i_frags, frags);
	}
}

SpecNext(client, Float:time=0.1)
{
	new client_team = GetClientTeam(client);
	new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	new last_target = GetLastTarget(client_team);
	new new_target = -1;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == client_team && IsPlayerAlive(i))
		{
			new_target = i;
			if (new_target > target || target == last_target)
			{
				break;
			}
		}
	}
	if (new_target != -1)
	{
		if (time > 0.1)
		{
			SpecTarget_Delayed(client, new_target, time);
		}
		else
		{
			SpecTarget(client, new_target);
		}
	}
}

SpecPrev(client, Float:time=0.1)
{
	new client_team = GetClientTeam(client);
	new target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
	new first_target = GetFirstTarget(client_team);
	new last_target = GetLastTarget(client_team);
	new new_target = -1;
	if (target == first_target)
	{
		new_target = last_target;
	}
	else
	{
		for (new i = MaxClients - 1; i >= 1; i--)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == client_team && IsPlayerAlive(i))
			{
				new_target = i;
				if (new_target < target)
				{
					break;
				}
			}
		}
	}
	if (new_target != -1)
	{
		if (time > 0.1)
		{
			SpecTarget_Delayed(client, new_target, time);
		}
		else
		{
			SpecTarget(client, new_target);
		}
	}
}

SpecTarget_Delayed(client, target, Float:time=0.1)
{
	new Handle:dp;
	CreateDataTimer(time, Timer_SpecTarget, dp, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(dp, client);
	WritePackCell(dp, target);	
}

public Action:Timer_SpecTarget(Handle:timer, Handle:dp)
{
	ResetPack(dp);
	new client = ReadPackCell(dp);
	new target = ReadPackCell(dp);
	SpecTarget(client, target);
}

SpecTarget(client, target)
{
	SetEntProp(client, Prop_Send, "m_iObserverMode", 4);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", target);
	CreateTimer(0.2, Timer_SpecTarget2, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_SpecTarget2(Handle:timer, any:client)
{
	FakeClientCommand(client, "spec_mode 1");
}

GetLastTarget(team)
{
	new last;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
		{
			last = i;
		}
	}
	return last;
}

GetFirstTarget(team)
{
	new first;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
		{
			first = i;
			break;
		}
	}
	return first;
}