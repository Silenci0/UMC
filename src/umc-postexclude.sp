// SPDX-License-Identifier: GPL-3.0-only

#pragma semicolon 1

#include <sourcemod>
#include <umc-core>
#include <umc_utils>

public Plugin myinfo =
{
    name = "[UMC] Post-Played Exclusion",
    author = "Steell, Powerlord, Mr.Silence, VIORA",
    description = "Allows users to specify an amount of time after a map is played that it should be excluded.",
    version = PL_VERSION,
    url = "https://github.com/crescentrose/UMC"
}

#define POSTEX_KEY_MAP "allow_every"
#define POSTEX_KEY_DEFAULT "default_allow_every"
#define POSTEX_KEY_GROUP "group_allow_every"
#define POSTEX_DEFAULT_VALUE 0

new Handle:cvar_nom_ignore = INVALID_HANDLE;
new Handle:cvar_display_ignore = INVALID_HANDLE;
new Handle:time_played_trie = INVALID_HANDLE;
new Handle:time_played_groups_trie = INVALID_HANDLE;

new time_penalty;

public OnPluginStart()
{
    cvar_nom_ignore = CreateConVar(
        "sm_umc_postex_ignorenominations",
        "0",
        "Determines if nominations are exempt from being excluded due to Post-Played Exclusion.",
        0, true, 0.0, true, 1.0
    );
    
    cvar_display_ignore = CreateConVar(
        "sm_umc_postex_ignoredisplay",
        "0",
        "Determines if maps being displayed are exempt from being excluded due to Post-Played Exclusion.",
        0, true, 0.0, true, 1.0
    );
    
    AutoExecConfig(true, "umc-postexclude");
    
    time_played_trie = CreateTrie();
    time_played_groups_trie = CreateTrie();
}

public OnConfigsExecuted()
{
    decl String:map[MAP_LENGTH], String:group[MAP_LENGTH];
    GetCurrentMap(map, sizeof(map));
    UMC_GetCurrentMapGroup(group, sizeof(group));

    new Handle:groupMaps;
    if (!GetTrieValue(time_played_trie, group, groupMaps))
    {
        groupMaps = CreateTrie();
        SetTrieValue(time_played_trie, group, groupMaps);
    }
    SetTrieValue(groupMaps, map, GetTime());
    SetTrieValue(time_played_groups_trie, group, GetTime() - time_penalty);
    
    time_penalty = 0;
}

bool:IsMapStillDelayed(const String:map[], const String:group[], minsDelayedMap, minsDelayedGroup)
{
    new Handle:groupMaps;
    if (!GetTrieValue(time_played_trie, group, groupMaps))
    {
        return false;
    }
    
    new timePlayedMap;
    decl String:resolvedMap[MAP_LENGTH];
    
    FindMap(map, resolvedMap, sizeof(resolvedMap));
    
    if (!GetTrieValue(groupMaps, resolvedMap, timePlayedMap))
    {
        return false;
    }
    
    new minsSinceMapPlayed = GetTime() - timePlayedMap / 60;
    
    new timePlayedGroup;
    if (!GetTrieValue(time_played_groups_trie, group, timePlayedGroup))
    {
        return false;
    }
    
    new minsSinceGroupPlayed = GetTime() - timePlayedGroup / 60;
    
    if (timePlayedMap == timePlayedGroup)
    {
        if (minsDelayedMap < minsDelayedGroup)
        {
            return minsSinceMapPlayed <= minsDelayedMap;
        }
    }
    return minsSinceMapPlayed <= minsDelayedMap || minsSinceGroupPlayed <= minsDelayedGroup;
}

//Called when UMC wants to know if this map is excluded
public Action UMC_OnDetermineMapExclude(Handle kvHandle, const char[] map, const char[] group, bool isNom, bool forMapChange)
{
    KeyValues kv = view_as<KeyValues>(kvHandle);

    if (isNom && GetConVarBool(cvar_nom_ignore))
        return Plugin_Continue;
    
    if (!forMapChange && GetConVarBool(cvar_display_ignore))
        return Plugin_Continue;
    
    if (kv == null)
        return Plugin_Continue;
    
    int exclusionTime, mapExclusionTime, groupExclusionTime;
    
    kv.Rewind();
    if (kv.JumpToKey(group))
    {
        groupExclusionTime = kv.GetNum(POSTEX_KEY_GROUP, POSTEX_DEFAULT_VALUE);
        mapExclusionTime = kv.GetNum(POSTEX_KEY_DEFAULT, POSTEX_DEFAULT_VALUE);
    
        if (kv.JumpToKey(map))
        {    
            exclusionTime = kv.GetNum(POSTEX_KEY_MAP, mapExclusionTime);
        }
        else
        {
            exclusionTime = groupExclusionTime;
        }

        kv.GoBack();
    }
    
    if (IsMapStillDelayed(map, group, exclusionTime, groupExclusionTime))
        return Plugin_Stop;
    
    return Plugin_Continue;
}

//Called when UMC has set the next map
public UMC_OnNextmapSet(Handle:kv, const String:map[], const String:group[], const String:display[])
{
    if (kv == INVALID_HANDLE)
    {
        return;
    }
    
    new gDef, gVal;

    KvRewind(kv);
    if (KvJumpToKey(kv, group))
    {
        gDef = KvGetNum(kv, POSTEX_KEY_GROUP, POSTEX_DEFAULT_VALUE);
        
        if (KvJumpToKey(kv, map))
        {
            gVal = KvGetNum(kv, POSTEX_KEY_GROUP, gDef);
            KvGoBack(kv);
        }
        else
        {
            gVal = gDef;
        }
        KvGoBack(kv);
    }
    
    new penalty = (gDef - gVal) * 60;
    time_penalty = penalty > 0 ? penalty : 0;
}
