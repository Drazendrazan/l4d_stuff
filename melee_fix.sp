#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1
#pragma newdecls required

#define PL_VERSION "2.1"

Handle hWeaponSwitchFwd;

float fLastMeleeSwing[MAXPLAYERS + 1];
bool bLate;

public Plugin myinfo =
{
	name = "Fast melee fix",
	author = "sheo",
	description = "Fixes the bug with too fast melee attacks",
	version = PL_VERSION,
	url = "http://steamcommunity.com/groups/b1com"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	char gfstring[128];
	GetGameFolderName(gfstring, sizeof(gfstring));
	if (!StrEqual(gfstring, "left4dead2", false))
	{
		SetFailState("Plugin supports Left 4 dead 2 only!");
	}
	HookEvent("weapon_fire", Event_WeaponFire);
	CreateConVar("l4d2_fast_melee_fix_version", PL_VERSION, "Fast melee fix version");
	if (bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				SDKHook(i, SDKHook_WeaponSwitchPost, OnWeaponSwitched);
			}
		}
	}

	hWeaponSwitchFwd = CreateGlobalForward("OnClientMeleeSwitch", ET_Ignore, Param_Cell, Param_Cell);
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
	{
		SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitched);
	}
	fLastMeleeSwing[client] = 0.0;
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && !IsFakeClient(client))
	{
		char sBuffer[64];
		GetEventString(event, "weapon", sBuffer, sizeof(sBuffer));
		if (StrEqual(sBuffer, "melee"))
		{
			fLastMeleeSwing[client] = GetGameTime();
		}
	}
}

void OnWeaponSwitched(int client, int weapon)
{
	if (!IsFakeClient(client) && IsValidEntity(weapon))
	{
		char sBuffer[32];
		GetEntityClassname(weapon, sBuffer, sizeof(sBuffer));
		if (StrEqual(sBuffer, "weapon_melee"))
		{
			float fShouldbeNextAttack = fLastMeleeSwing[client] + 0.92;
			float fByServerNextAttack = GetGameTime() + 0.5;
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", (fShouldbeNextAttack > fByServerNextAttack) ? fShouldbeNextAttack : fByServerNextAttack);

			Call_StartForward(hWeaponSwitchFwd);

			Call_PushCell(client);

			Call_PushCell(weapon);

			Call_Finish();
		}
	}
}