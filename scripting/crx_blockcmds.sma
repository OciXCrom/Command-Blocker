#include <amxmodx>
#include <amxmisc>
#include <colorchat>
#include <engine>

#define PLUGIN_VERSION "1.1"

new const g_szPrefix[] = "^1[^3Command Blocker^1]"
new Trie:g_tCommands
new Trie:g_tChat
new g_szImpulseFlag[2]

public plugin_init()
{
	register_plugin("Command Blocker", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CommandBlocker", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("CommandBlocker.txt")
	register_clcmd("say", "hookSay")
	register_clcmd("say_team", "hookSay")
	g_tCommands = TrieCreate()
	g_tChat = TrieCreate()
	fileRead()
}

public plugin_end()
{
	TrieDestroy(g_tCommands)
	TrieDestroy(g_tChat)
}

fileRead()
{
	new szConfigsName[256], szFilename[256]
	get_configsdir(szConfigsName, charsmax(szConfigsName))
	formatex(szFilename, charsmax(szFilename), "%s/CommandBlocker.ini", szConfigsName)
	new iFilePointer = fopen(szFilename, "rt")
	
	if(iFilePointer)
	{
		new szData[66], szCommand[64]
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)
			
			if(szData[0] == EOS || szData[0] == ';')
				continue
				
			new szFlag[2]
			split(szData, szCommand, charsmax(szCommand), szFlag, charsmax(szFlag), "Flag:")
			trim(szCommand)
			
			if(equal(szCommand, "impulse ", 7))
			{
				replace(szCommand, charsmax(szCommand), "impulse", ""); trim(szCommand)
				register_impulse(str_to_num(szCommand), "cmdImpulse")
				
				if(!is_blank(szFlag))
					copy(g_szImpulseFlag, charsmax(g_szImpulseFlag), szFlag)
			}
			else if(equal(szCommand, "say ", 3) || equal(szCommand, "say_team ", 8))
			{
				replace(szCommand, charsmax(szCommand), "say_team", "")
				replace(szCommand, charsmax(szCommand), "say", "")
				trim(szCommand)
				TrieSetString(g_tChat, szCommand, szFlag)
			}
			else
			{
				register_clcmd(szCommand, "cmdBlock")
				
				if(!is_blank(szFlag))
					TrieSetString(g_tCommands, szCommand, szFlag)
			}
		}
		
		fclose(iFilePointer)
	}
}

public cmdBlock(id)
{
	new szCommand[64]
	read_argv(0, szCommand, charsmax(szCommand))
	
	if(TrieKeyExists(g_tCommands, szCommand))
	{
		new szFlag[2]
		TrieGetString(g_tCommands, szCommand, szFlag, charsmax(szFlag))
		
		if(get_user_flags(id) & read_flags(szFlag)) return PLUGIN_CONTINUE
		else ColorChat(id, TEAM_COLOR, "%s %L", g_szPrefix, LANG_SERVER, "CMDBLOCK_NOACCESS")
	}
	else ColorChat(id, TEAM_COLOR, "%s %L", g_szPrefix, LANG_SERVER, "CMDBLOCK_BLOCKED")
	return PLUGIN_HANDLED
}

public cmdImpulse(id)
{
	if(!is_blank(g_szImpulseFlag))
	{
		if(get_user_flags(id) & read_flags(g_szImpulseFlag)) return PLUGIN_CONTINUE
		else ColorChat(id, TEAM_COLOR, "%s %L", g_szPrefix, LANG_SERVER, "CMDBLOCK_NOACCESS")
	}
	else ColorChat(id, TEAM_COLOR, "%s %L", g_szPrefix, LANG_SERVER, "CMDBLOCK_BLOCKED")
	return PLUGIN_HANDLED
}

public hookSay(id)
{
	new szArgs[64], szCommand[32]
	read_argv(1, szArgs, charsmax(szArgs))
	strtok(szArgs, szCommand, charsmax(szCommand), szArgs, charsmax(szArgs), ' ')
	trim(szCommand)
	
	if(TrieKeyExists(g_tChat, szCommand))
	{
		new szFlag[2]
		TrieGetString(g_tChat, szCommand, szFlag, charsmax(szFlag))
		
		if(is_blank(szFlag)) ColorChat(id, TEAM_COLOR, "%s %L", g_szPrefix, LANG_SERVER, "CMDBLOCK_BLOCKED")
		else
		{
			if(get_user_flags(id) & read_flags(szFlag)) return PLUGIN_CONTINUE
			else ColorChat(id, TEAM_COLOR, "%s %L", g_szPrefix, LANG_SERVER, "CMDBLOCK_NOACCESS")
		}
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

bool:is_blank(szString[])
	return szString[0] == EOS ? true : false