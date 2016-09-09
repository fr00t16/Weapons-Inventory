#define FILTERSCRIPTS

#include 	<a_samp>
#include 	<a_mysql>
#include 	<sscanf2>
#include 	<zcmd>

#define    	MYSQL_HOST        "localhost"
#define    	MYSQL_USER        "root"
#define    	MYSQL_DATABASE    "test"
#define    	MYSQL_PASSWORD    ""

#define    	DIALOG_GUNS_TAKE  17835

#define    	red 			 0xFF0000FF
#define    	green 			 0x00FF00FF
#define    	SCM 			 SendClientMessage

new MySQL:mysql, pID[MAX_PLAYERS];

public OnFilterScriptInit()
{
	mysql = mysql_connect(MYSQL_HOST, MYSQL_USER, MYSQL_PASSWORD, MYSQL_DATABASE);
	mysql_log(ALL);
	if(mysql_errno()) return printf("[Inventory Weapons System] Failed Connection. (Error #%d)", mysql_errno());

	mysql_tquery(mysql, "CREATE TABLE IF NOT EXISTS `WeaponData` ( `ID` int(5) NOT NULL, `WeaponID` tinyint(4) NOT NULL,`Ammo` int(11) NOT NULL, UNIQUE KEY `ID_2` (`ID`,`WeaponID`), KEY `ID` (`ID`) )");
	return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
	switch(dialogid)
	{
		case DIALOG_GUNS_TAKE:
		{
			if(response)
			{
				new query[96], Cache: weapon;
		    	mysql_format(mysql, query, sizeof(query), "SELECT `WeaponID`, `Ammo` FROM `WeaponData` WHERE `ID` = %d ORDER BY `WeaponID` ASC LIMIT %d, 1", pID[playerid], listitem);
				weapon = mysql_query(mysql, query);
				new rows = cache_num_rows();
				if(rows) 
				{
		  			new string[64], weapname[32], weaponid, ammo;

		  			cache_get_value_name_int(0, "WeaponID", weaponid);
		  			cache_get_value_name_int(0, "Ammo", ammo);

		  			GetWeaponName(weaponid, weapname, sizeof(weapname));
		  			GivePlayerWeapon(playerid, weaponid,  ammo);

					format(string, sizeof(string), "You've taken %s with %i ammo from your inventory", weapname, ammo);
					SendClientMessage(playerid, red, string);

					mysql_format(mysql, query, sizeof(query), "DELETE FROM `WeaponData` WHERE `ID` = %d AND `WeaponID` = %d", pID[playerid], weaponid);
					mysql_tquery(mysql, query);
				}
				else SendClientMessage(playerid, red, "Can not find that weapon");
				cache_delete(weapon);
			}
		}
	}
	return 0;
}

CMD:saveweapons(playerid, params[])
{
	new query[220], string[128], ammo, weaponid;
	if(DoesPlayerHaveWeapons(playerid) == false) return SCM(playerid, red, "You don't have any weapons");
	if(sscanf(params, "ii", weaponid, ammo)) return SCM(playerid, red, "Save weapons: /saveweapons <WeaponID> <Ammo>"), SCM(playerid, red, "Make sure you are holding the weapon which you want to save");
	if(weaponid == 0) return SCM(playerid, red, "Invalid weapon ID");
	if(ammo == 0) return SCM(playerid, red, "Invalid ammo");
	if(GetPlayerWeapon(playerid) != weaponid) return SCM(playerid, red, "You don't have that weapon ID");
	if(GetPlayerAmmo(playerid) < ammo) return SCM(playerid, red, "You don't have enough ammo");

	mysql_format(mysql, query, sizeof(query), "INSERT INTO `WeaponData` (ID, WeaponID, Ammo) VALUES (%d, %d, %d) ON DUPLICATE KEY UPDATE `Ammo` = `Ammo` + %d", pID[playerid], weaponid, ammo, ammo);
	mysql_query(mysql, query);

	GivePlayerWeapon(playerid, weaponid, -ammo);

	format(string, sizeof(string), "You have saved %s with %i ammo in your inventory", WeaponNames(weaponid), ammo);
	SCM(playerid, green, string);
	SCM(playerid, red, "Use /takeweapons to take it back from your inventory");
	return 1;
}
CMD:sw(playerid, params[]) return cmd_saveweapons(playerid, params);

CMD:takeweapons(playerid, params[])
{
	new query[140], Cache:weapons, weaponid, ammo;
    mysql_format(mysql, query, sizeof(query), "SELECT `WeaponID`, `Ammo` FROM `WeaponData` WHERE `ID`=%d ORDER BY `WeaponID` ASC", pID[playerid]);
	weapons = mysql_query(mysql, query);
	new rows = cache_num_rows();
	if(rows) 
	{
	    new list[512];
	    format(list, sizeof(list), "#\tWeapon Name\tAmmo\n");
	    for(new i; i < rows; ++i)
	    {
	    	cache_get_value_name_int(i, "WeaponID", weaponid);
	    	cache_get_value_name_int(i, "Ammo", ammo);

	        format(list, sizeof(list), "%s%d\t%s\t%s\n", list, i+1, WeaponNames(weaponid), convertNumber(ammo));
	    }
	    ShowPlayerDialog(playerid, DIALOG_GUNS_TAKE, DIALOG_STYLE_TABLIST_HEADERS, "Inventory - Weapons", list, "Select", "Close");
	}
	else SendClientMessage(playerid, red, "You don't have any weapons in your inventory");
    cache_delete(weapons);
    return 1;
}
CMD:tw(playerid, params[]) return cmd_takeweapons(playerid, params);

// Weapons Inventory 

convertNumber(value)
{
    new string[24];
    format(string, sizeof(string), "%d", value);

    for(new i = (strlen(string) - 3); i > (value < 0 ? 1 : 0) ; i -= 3)
    {
        strins(string[i], ",", 0);
    }
    return string;
}

forward bool:DoesPlayerHaveWeapons(playerid);
public bool:DoesPlayerHaveWeapons(playerid)
{
	new weap, am;
	for(new i = 0; i < 13; i ++)
	{
		GetPlayerWeaponData(playerid, i, weap, am);
		if(weap && am >= 1) return true;
	}
	return false;
}

WeaponNames(id)
{
    new wn[32];
    switch(id)
    {
        case 9:(wn = "Chainsaw");
        case 10:(wn = "Dildo");
        case 11:(wn = "Dildo");
        case 12:(wn = "Dildo");
        case 13:(wn = "Dildo");
        case 14:(wn = "Flowers");
        case 15:(wn = "Cane");
        case 16:(wn = "Grenade");
        case 18:(wn = "Molotov");
        case 22:(wn = "9mm");
        case 23:(wn = "Silenced");
        case 24:(wn = "Desert Eagle");
        case 25:(wn = "Shotgun");
        case 26:(wn = "Sawn-off");
        case 27:(wn = "Combat Shotgun");
        case 28:(wn = "Micro SMG");
        case 29:(wn = "SMG");
        case 30:(wn = "Ak47");
        case 31:(wn = "M4");
        case 32:(wn = "Tec 9");
        case 33:(wn = "Rifle");
        case 34:(wn = "Sniper");
        case 35:(wn = "Rocket Launcher");
        case 37:(wn = "Flame Thrower");
        case 38:(wn = "Minigun");
        case 39:(wn = "Satchel Charge");
        case 40:(wn = "Detonator");
        case 41:(wn = "Spray");
        case 42:(wn = "Fire Extinguisher");
        case 46:(wn = "Parachute");
    }
    return wn;
}