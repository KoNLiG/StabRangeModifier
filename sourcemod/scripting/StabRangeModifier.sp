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

enum
{
	OS_LINUX, 
	OS_WINDOWS
}

int g_OS;

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
		SetFailState("Failed to get address 'SwingOrStab::KNIFE_RANGE_SHORT'");
	}
	
	if (!VerifyAddress(gamedata, "CKnife::SwingOrStab", "SwingOrStab::KNIFE_RANGE_SHORT"))
	{
		SetFailState("Failed to verify address 'SwingOrStab::KNIFE_RANGE_SHORT'");
	}
	
	if (!(pKNIFE_RANGE_LONG = gamedata.GetAddress("SwingOrStab::KNIFE_RANGE_LONG")))
	{
		SetFailState("Failed to get address 'SwingOrStab::KNIFE_RANGE_LONG'");
	}
	
	if (!VerifyAddress(gamedata, "CKnife::SwingOrStab", "SwingOrStab::KNIFE_RANGE_LONG"))
	{
		SetFailState("Failed to verify address 'SwingOrStab::KNIFE_RANGE_LONG'");
	}
	
	if ((g_OS = gamedata.GetOffset("OS")) == -1)
	{
		SetFailState("Failed to get server OS");
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
	
	// Trigger the change callbacks for initial patch.
	Hook_RangeChange(stab_range_secondary, "", "");
	Hook_RangeChange(stab_range_primary, "", "");
}

// Restore the original values.
public void OnPluginEnd()
{
	any range_short, range_long;
	if (g_OS == OS_LINUX)
	{
		range_short = float(KNIFE_RANGE_SHORT);
		range_long = float(KNIFE_RANGE_LONG);
	}
	else
	{
		range_short = KNIFE_RANGE_SHORT;
		range_long = KNIFE_RANGE_LONG;
	}
	
	StoreToAddress(pKNIFE_RANGE_SHORT, range_short, NumberType_Int32);
	StoreToAddress(pKNIFE_RANGE_LONG, range_long, NumberType_Int32);
}

void Hook_RangeChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	any range;
	if (g_OS == OS_LINUX)
	{
		range = convar.FloatValue;
	}
	else
	{
		range = convar.IntValue;
	}
	
	StoreToAddress(convar == stab_range_secondary ? pKNIFE_RANGE_SHORT : pKNIFE_RANGE_LONG, range, NumberType_Int32);
}

bool VerifyAddress(GameData gamedata, const char[] signature, const char[] key)
{
	char bytes[256];
	if (!gamedata.GetKeyValue(key, bytes, sizeof(bytes)))
	{
		return false;
	}
	
	int offset = gamedata.GetOffset(key);
	if (offset == -1)
	{
		return false;
	}
	
	Address address = gamedata.GetMemSig(signature) + view_as<Address>(offset);
	
	StrCat(bytes, sizeof(bytes), " ");
	
	char byte[16];
	int current_pos, pos, len;
	
	while ((pos = SplitString(bytes[current_pos], " ", byte, sizeof(byte))) != -1)
	{
		current_pos += pos;
		
		TrimString(byte);
		
		if (byte[0])
		{
			if (LoadFromAddress(address + view_as<Address>(len), NumberType_Int8) != StringToInt(byte, 0x10))
			{
				return false;
			}
			
			len++;
		}
	}
	
	return true;
} 