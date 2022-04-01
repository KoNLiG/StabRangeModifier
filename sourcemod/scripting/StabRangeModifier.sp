#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

// Default stab range values. (Represented by units)
#define KNIFE_RANGE_SHORT 32 // Secondary attack range.
#define KNIFE_RANGE_LONG 48  // Primary attack range.

Address pKNIFE_RANGE_SHORT;
Address pKNIFE_RANGE_LONG;

ConVar stab_range_secondary;
ConVar stab_range_primary;

public Plugin myinfo = 
{
	name = "[CS:GO] Stab-Range-Modifier", 
	author = "KoNLiG", 
	description = "Provides the ability to change CS:GO stab ranges by cvars.", 
	version = "1.0.0", 
	url = "https://github.com/KoNLiG/StabRangeModifier"
};

// Lock the use of this plugin for CS:GO only.
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (GetEngineVersion() != Engine_CSGO)
	{
		strcopy(error, err_max, "This plugin was made for use with CS:GO only.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	// Parse gamedata addresses.
	GameData gamedata = new GameData("StabRangeModifier.game.csgo");
	
	if (!(pKNIFE_RANGE_SHORT = gamedata.GetAddress("SwingOrStab::KNIFE_RANGE_SHORT")))
	{
		SetFailState("Failed to get 'SwingOrStab::KNIFE_RANGE_SHORT' address");
	}
	
	if (!(pKNIFE_RANGE_LONG = gamedata.GetAddress("SwingOrStab::KNIFE_RANGE_LONG")))
	{
		SetFailState("Failed to get 'SwingOrStab::KNIFE_RANGE_LONG' address");
	}
	
	delete gamedata;
	
	// ConVar configuration.
	(stab_range_secondary = CreateConVar(
		"stab_range_secondary", 
		"32.0", 
		"Maximum range for secondary knife stabs. (Units represented)"
	)).AddChangeHook(Hook_RangeChange);
	
	(stab_range_primary = CreateConVar(
		"stab_range_primary", 
		"48.0", 
		"Maximum range for primary knife stabs. (Units represented)"
	)).AddChangeHook(Hook_RangeChange);
	
	AutoExecConfig();
	
	// Verify both addresses to prevent server crashes and further issues.
	if (LoadFromAddress(pKNIFE_RANGE_SHORT, NumberType_Int32) != stab_range_secondary.FloatValue)
	{
		SetFailState("Failed to verify 'SwingOrStab::KNIFE_RANGE_SHORT' address");
	}
	
	// Trigger the change callbacks for initial patch.
	Hook_RangeChange(stab_range_secondary, "", "");
	Hook_RangeChange(stab_range_primary, "", "");
}

// Restore the original values.
public void OnPluginEnd()
{
	StoreToAddress(pKNIFE_RANGE_SHORT, float(KNIFE_RANGE_SHORT), NumberType_Int32);
	StoreToAddress(pKNIFE_RANGE_LONG, float(KNIFE_RANGE_LONG), NumberType_Int32);
}

void Hook_RangeChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	StoreToAddress(convar == stab_range_secondary ? pKNIFE_RANGE_SHORT : pKNIFE_RANGE_LONG, convar.FloatValue, NumberType_Int32);
} 

bool VerifyAddress(GameData gamedata, const char[] name)
{
	
}