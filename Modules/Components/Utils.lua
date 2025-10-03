-------------------------------------------------------------------------------
-- TellMeWhen Utils
-------------------------------------------------------------------------------
local _G, assert, error, tostring, select, type, next, math, pairs, ipairs, setmetatable, table =
	  _G, assert, error, tostring, select, type, next, math, pairs, ipairs, setmetatable, table
	  
local sort 						= table.sort	 	  
	  
local TMW 						= _G.TMW
local CNDT 						= TMW.CNDT
local Env 						= CNDT.Env
local strlowerCache  			= TMW.strlowerCache

local A   						= _G.Action
local CONST 					= A.Const
local Listener					= A.Listener
local TimerSetRefreshAble		= A.TimerSetRefreshAble
local GetToggle					= A.GetToggle
local toStr 					= A.toStr
local toNum 					= A.toNum
local Print 					= A.Print
local ActionDataColor			= A.Data.C
local ActionDataUniversalColor 	= A.Data.UC
local BuildToC					= A.BuildToC

local isClassic					= A.StdUi.isClassic
local owner 					= isClassic and "PlayerClass" or "PlayerSpec" 
local ownerColor				= ActionDataUniversalColor[0]
local ownerVersion				= BuildToC < 20000 and "Classic" or BuildToC < 30000 and "TBC" or BuildToC < 40000 and "WOTLK" or BuildToC < 50000 and "CATA" or BuildToC < 60000 and "MOP" or "Retail"
local CharacterToUniversalColor	= {}
do 
	local function orderednext(t, n)
		local key = t[t.__next]
		if key then 
			t.__next = t.__next + 1
			return key, t.__source[key]
		end
	end
	local function orderedpairs(t, f)
		local keys, kn = {__source = t, __next = 1}, 1
		for k in pairs(t) do
			keys[kn], kn = k, kn + 1
		end
		sort(keys, f)
		return orderednext, keys
	end
	
	local index = -1
	local order = setmetatable({ Retail = 1, Classic = 2, TBC = 3, WOTLK = 4, CATA = 5, MOP = 6 }, { __index = function() return 0 end })
	local function compare(a, b)
		return order[a] < order[b]
	end
	
	for ver, val in orderedpairs({ 
		-- blank 
		"", -- #0
		Retail = {
			CONST.WARRIOR_ARMS, 
			CONST.WARRIOR_FURY,		
			CONST.WARRIOR_PROTECTION,
			CONST.PALADIN_HOLY,		
			CONST.PALADIN_PROTECTION,		
			CONST.PALADIN_RETRIBUTION,			
			CONST.HUNTER_BEASTMASTERY,	
			CONST.HUNTER_MARKSMANSHIP,			
			CONST.HUNTER_SURVIVAL,		
			CONST.ROGUE_ASSASSINATION,		
			CONST.ROGUE_OUTLAW,	
			CONST.ROGUE_SUBTLETY,		
			CONST.PRIEST_DISCIPLINE,		
			CONST.PRIEST_HOLY,			
			CONST.PRIEST_SHADOW,			
			CONST.SHAMAN_ELEMENTAL,
			CONST.SHAMAN_ENHANCEMENT,
			CONST.SHAMAN_RESTORATION,
			CONST.MAGE_ARCANE,
			CONST.MAGE_FIRE,
			CONST.MAGE_FROST,
			CONST.WARLOCK_AFFLICTION,
			CONST.WARLOCK_DEMONOLOGY,
			CONST.WARLOCK_DESTRUCTION,
			CONST.MONK_BREWMASTER,
			CONST.MONK_MISTWEAVER,
			CONST.MONK_WINDWALKER,
			CONST.DRUID_BALANCE,
			CONST.DRUID_FERAL,
			CONST.DRUID_GUARDIAN,
			CONST.DRUID_RESTORATION,
			CONST.DEMONHUNTER_HAVOC,
			CONST.DEMONHUNTER_VENGEANCE,
			CONST.DEATHKNIGHT_BLOOD,
			CONST.DEATHKNIGHT_FROST,
			CONST.DEATHKNIGHT_UNHOLY,
			CONST.EVOKER_DEVASTATION,
			CONST.EVOKER_PRESERVATION,
			CONST.EVOKER_AUGMENTATION, -- #39
		},
		Classic  = {
			"WARRIOR",
			"PALADIN",
			"HUNTER",
			"ROGUE",
			"PRIEST",
			"SHAMAN",
			"MAGE",
			"WARLOCK",
			"DRUID", -- #48		
		},
		TBC = {
			"WARRIOR",
			"PALADIN",
			"HUNTER",
			"ROGUE",
			"PRIEST",
			"SHAMAN",
			"MAGE",
			"WARLOCK",
			"DRUID", -- #57	
		},
		WOTLK = {
			"WARRIOR",
			"PALADIN",
			"HUNTER",
			"ROGUE",
			"PRIEST",
			"SHAMAN",
			"MAGE",
			"WARLOCK",
			"DRUID",
			"DEATHKNIGHT", -- #67
		},
		CATA = {
			"WARRIOR",
			"PALADIN",
			"HUNTER",
			"ROGUE",
			"PRIEST",
			"SHAMAN",
			"MAGE",
			"WARLOCK",
			"DRUID",
			"DEATHKNIGHT", -- #77
		},
		MOP = {
			"WARRIOR",
			"PALADIN",
			"HUNTER",
			"ROGUE",
			"PRIEST",
			"SHAMAN",
			"MAGE",
			"WARLOCK",
			"MONK",
			"DRUID",
			"DEATHKNIGHT", -- #88
		},
	}, compare) do 		
		if type(val) ~= "table" then 
			index = index + 1
			CharacterToUniversalColor[val] = ActionDataUniversalColor[index]			
		else 
			CharacterToUniversalColor[ver] = {}
			for _, classspec in ipairs(val) do 
				index = index + 1
				CharacterToUniversalColor[ver][classspec] = ActionDataUniversalColor[index]
				--print(index, ver, classspec)
			end 
		end 
	end 

	ownerColor = CharacterToUniversalColor[ownerVersion] and CharacterToUniversalColor[ownerVersion][A[owner]] or CharacterToUniversalColor[""]
end 

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_LossOfControl, A_GetSpellInfo, TeamCacheEnemy, TeamCacheEnemyIndexToPLAYERs

Listener:Add("ACTION_EVENT_UTILS", "ADDON_LOADED", function(addonName) 
	if addonName == CONST.ADDON_NAME then 
		A_LossOfControl					= A.LossOfControl
		A_GetSpellInfo					= A.GetSpellInfo
		TeamCacheEnemy					= A.TeamCache.Enemy
		TeamCacheEnemyIndexToPLAYERs	= TeamCacheEnemy.IndexToPLAYERs
		Listener:Remove("ACTION_EVENT_UTILS", "ADDON_LOADED")	
	end 	
end)
-------------------------------------------------------------------------------  
	  
local huge 					= math.huge	 
local wipe					= _G.wipe
local message				= _G.message
local hooksecurefunc		= _G.hooksecurefunc
local strfind				= _G.strfind	  
local strmatch				= _G.strmatch
local strjoin				= _G.strjoin
local UIParent				= _G.UIParent	
local C_CVar				= _G.C_CVar
	  
local 	 CreateFrame, 	 GetCVar, 	 				   SetCVar =
	  _G.CreateFrame, _G.GetCVar or C_CVar.GetCVar, _G.SetCVar or C_CVar.SetCVar	  

local GetPhysicalScreenSize = _G.GetPhysicalScreenSize
	  
local GetSpellTexture, 	  GetSpellInfo,    CombatLogGetCurrentEventInfo =	
  TMW.GetSpellTexture, _G.GetSpellInfo, _G.CombatLogGetCurrentEventInfo	  

local 	 UnitGUID, 	  UnitIsUnit =
	  _G.UnitGUID, _G.UnitIsUnit

-------------------------------------------------------------------------------
-- DataBase
-------------------------------------------------------------------------------
TMW:RegisterDatabaseDefaults{
	global = {
		TextLayouts = {
			["TMW:textlayout:1Rh4g1a9S6Uf"] = {
				{
					["Outline"] = "OUTLINE",
					["Shadow"] = 0.9,
					["Anchors"] = {
						{
							["y"] = 58,
							["relativeTo"] = "IconModule_CooldownSweepCooldown",
							["relativePoint"] = "RIGHT",
							["x"] = 12.2,
						}, -- [1]
					},
					["Name"] = "Morpheus",
					["Rotate"] = 90,
					["Size"] = 35,
				}, -- [1]
				["GUID"] = "TMW:textlayout:1Rh4g1a9S6Uf",
				["Name"] = "UserInterface_TextVertical",
			},
			["TMW:textlayout:1RkGJEN4L5o_"] = {
				{
					["SkinAs"] = "HotKey",
					["Anchors"] = {
						{
							["y"] = -2,
							["x"] = -2,
							["point"] = "TOPLEFT",
							["relativePoint"] = "TOPLEFT",
						}, -- [1]
						{
							["y"] = -2,
							["x"] = -2,
							["point"] = "TOPRIGHT",
							["relativePoint"] = "TOPRIGHT",
						}, -- [2]
						["n"] = 2,
					},
					["StringName"] = "Привязка/Ярлык",
					["Height"] = 1,
				}, -- [1]
				{
					["SkinAs"] = "Count",
					["Anchors"] = {
						{
							["y"] = 2,
							["x"] = 50.7,
							["point"] = "RIGHT",
							["relativePoint"] = "RIGHT",
						}, -- [1]
					},
					["StringName"] = "Стаки",
					["DefaultText"] = "[Stacks:Hide(0)]",
				}, -- [2]
				["GUID"] = "TMW:textlayout:1RkGJEN4L5o_",
				["Name"] = "UserInterface_DefaultText_RightSide",
				["n"] = 2,
			},
			["TMW:textlayout:1RFt2HZe_Cbk"] = {
				{
					["Outline"] = "OUTLINE",
					["Shadow"] = 0.9,
					["Anchors"] = {
						{
							["point"] = "BOTTOM",
							["relativePoint"] = "BOTTOM",
						}, -- [1]
					},
					["Size"] = 8,
				}, -- [1]
				["GUID"] = "TMW:textlayout:1RFt2HZe_Cbk",
				["Name"] = "UserInterface_Text",
			},
			["TMW:textlayout:1S6ieoFev4r0"] = {
				{
					["Outline"] = "OUTLINE",
					["Shadow"] = 0.9,
					["Anchors"] = {
						{
							["y"] = 2,
							["point"] = "BOTTOM",
							["relativePoint"] = "BOTTOM",
						}, -- [1]
					},
					["Name"] = "AR ZhongkaiGBK Medium",
					["Size"] = 6,
				}, -- [1]
				["GUID"] = "TMW:textlayout:1S6ieoFev4r0",
				["Name"] = "UserInterface_SmallerText",
			},
			["TMW:textlayout:1TMvg5InaYOw"] = {
				{
					["Anchors"] = {
						{
							["y"] = -1.5,
							["x"] = 1.5,
							["point"] = "TOPLEFT",
							["relativePoint"] = "TOPLEFT",
						}, -- [1]
					},
					["DefaultText"] = "[ActionBurst]",
					["Size"] = 6,
				}, -- [1]
				{
					["Anchors"] = {
						{
							["y"] = 1,
							["x"] = 0.5,
							["point"] = "BOTTOMRIGHT",
							["relativePoint"] = "BOTTOMRIGHT",
						}, -- [1]
					},
					["Name"] = "Morpheus",
					["DefaultText"] = "[ActionAoE]",
					["Size"] = 6,
				}, -- [2]
				{
					["Anchors"] = {
						{
							["y"] = 1,
							["x"] = 1.5,
							["point"] = "BOTTOMLEFT",
							["relativePoint"] = "BOTTOMLEFT",
						}, -- [1]
					},
					["Name"] = "Morpheus",
					["DefaultText"] = "[ActionMode]",
					["Size"] = 6,
				}, -- [3]
				["GUID"] = "TMW:textlayout:1TMvg5InaYOw",
				["Name"] = "ActionLayout",
				["n"] = 3,
			},
			["TMW:textlayout:1TYfkpegTiCv"] = {
				{
					["Outline"] = "OUTLINE",
					["Justify"] = "RIGHT",
					["Name"] = "Accidental Presidency",
					["StringName"] = "Alert bar display",
					["Size"] = 11,
				}, -- [1]
				["GUID"] = "TMW:textlayout:1TYfkpegTiCv",
				["Name"] = "Taste Layout",
			},
			["TMW:textlayout:1UbsdH6epahK"] = {
				{
					["Outline"] = "OUTLINE",
					["Justify"] = "RIGHT",
					["Name"] = "Accidental Presidency",
					["StringName"] = "Alert bar display",
					["Size"] = 11,
				}, -- [1]
				["GUID"] = "TMW:textlayout:1UbsdH6epahK",
				["Name"] = "Taste Layout 2",
			},
		},
	},
}

-------------------------------------------------------------------------------
-- TalentMap  
-------------------------------------------------------------------------------
local function AreTablesEqual(t1, t2)
	for k, v in pairs(t1) do if t2[k] ~= v then return false end end	
	for k, v in pairs(t2) do if t1[k] ~= v then return false end end	
	return true
end

local function MirrorTables(t1, t2)
	wipe(t2)
	for k, v in pairs(t1) do
		t2[k] = v
	end
end

if BuildToC < 50500 then 
	-- Classic - Cataclysm
	local TalentMap 										= {}; A.TalentMap = TalentMap
	local TalentMapMirror									= {}
	local GetNumTalentTabs, GetNumTalents, GetTalentInfo 	= _G.GetNumTalentTabs, _G.GetNumTalents, _G.GetTalentInfo
	local function TalentMapUpdate()
		wipe(TalentMap)
		local _, name, rank
		for tab = 1, GetNumTalentTabs() do
			for talent = 1, GetNumTalents(tab) do
				name, _, _, _, rank = GetTalentInfo(tab, talent)
				if name then
					TalentMap[name] = rank or 0
				end
			end
		end
		
		-- This part of code avoids double reconfigure load on Meta Engine
		-- Because on pet (summon) event (which is doubled) PLAYER_TALENT_UPDATE fired twice
		if not AreTablesEqual(TalentMap, TalentMapMirror) then
			MirrorTables(TalentMap, TalentMapMirror)
			TMW:Fire("TMW_ACTION_TALENT_MAP_UPDATED")
		end
		Listener:Remove("ACTION_EVENT_UTILS_TALENT_MAP", "PLAYER_ENTERING_WORLD")
	end

	Listener:Add("ACTION_EVENT_UTILS_TALENT_MAP", "PLAYER_ENTERING_WORLD", 			TalentMapUpdate)
	Listener:Add("ACTION_EVENT_UTILS_TALENT_MAP", "ACTIVE_TALENT_GROUP_CHANGED", 	TalentMapUpdate)	
	Listener:Add("ACTION_EVENT_UTILS_TALENT_MAP", "CHARACTER_POINTS_CHANGED", 		TalentMapUpdate)
elseif BuildToC < 100000 then
	-- MOP - Shadowlands
	local TalentMap 					= {}; A.TalentMap = TalentMap
	local TalentMapMirror				= {}
	local C_SpecializationInfo			= _G.C_SpecializationInfo
	local GetTalentInfo 				= C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo or _G.GetTalentInfo
	local GetPvpTalentInfoByID 			= _G.GetPvpTalentInfoByID
	local GetAllSelectedPvpTalentIDs 	= C_SpecializationInfo and C_SpecializationInfo.GetAllSelectedPvpTalentIDs	
	
	local MAX_NUM_TALENT_TIERS 			= _G.MAX_NUM_TALENT_TIERS
	local NUM_TALENT_COLUMNS 			= _G.NUM_TALENT_COLUMNS
	
	local talentInfoQuery = {}
	local function TalentMapUpdate()
		wipe(TalentMap)
		wipe(talentInfoQuery)
		
		local talentInfo
		for tier = 1, MAX_NUM_TALENT_TIERS do
			for column = 1, NUM_TALENT_COLUMNS do
				talentInfoQuery.tier = tier
				talentInfoQuery.column = column
				talentInfo = GetTalentInfo(talentInfoQuery)
				-- isExceptional @boolean
				-- talentID @number
				-- known @boolean
				-- maxRank @number
				-- hasGoldBorder @boolean
				-- tier @number
				-- selected @boolean
				-- icon @number
				-- grantedByAura @boolean
				-- meetsPreviewPrereq @boolean
				-- previewRank @number
				-- meetsPrereq @boolean
				-- name @string
				-- isPVPTalentUnlocked @boolean
				-- column @number
				-- rank @number
				-- available @boolean
				-- spellID @number	
				if talentInfo and (talentInfo.selected or talentInfo.grantedByAura) then
					TalentMap[talentInfo.name] = talentInfo.rank or 1
					TalentMap[talentInfo.spellID] = talentInfo.rank or 1
					TalentMap[talentInfo.talentID] = talentInfo.rank or 1
				end
			end
		end
		
		local _, name, ids
		if GetPvpTalentInfoByID then
			ids = GetAllSelectedPvpTalentIDs()
			for _, id in pairs(ids) do
				_, name = GetPvpTalentInfoByID(id)
				if name then
					TalentMap[name] = true
					TalentMap[id] = true
				end
			end
		end	
		
		-- This part of code avoids double reconfigure load on Meta Engine
		-- Because on pet (summon) event (which is doubled) PLAYER_TALENT_UPDATE fired twice		
		if not AreTablesEqual(TalentMap, TalentMapMirror) then
			MirrorTables(TalentMap, TalentMapMirror)
			TMW:Fire("TMW_ACTION_TALENT_MAP_UPDATED")
		end
		Listener:Remove("ACTION_EVENT_UTILS_TALENT_MAP", "PLAYER_ENTERING_WORLD")
	end

	Listener:Add("ACTION_EVENT_UTILS_TALENT_MAP", "PLAYER_ENTERING_WORLD", 				TalentMapUpdate)
	Listener:Add("ACTION_EVENT_UTILS_TALENT_MAP", "ACTIVE_TALENT_GROUP_CHANGED", 		TalentMapUpdate)
	Listener:Add("ACTION_EVENT_UTILS_TALENT_MAP", "PLAYER_TALENT_UPDATE", 				TalentMapUpdate)
	-- Legion: Registers events for pvp talents
	if BuildToC >= 70003 then		
		Listener:Add("ACTION_EVENT_UTILS_TALENT_MAP", "PLAYER_PVP_TALENT_UPDATE", 		TalentMapUpdate)
	end
	-- SL: Registers events for Torghast 
	if BuildToC >= 90001 then 
		Listener:Add("ACTION_EVENT_UTILS_TALENT_MAP", "ANIMA_DIVERSION_TALENT_UPDATED", TalentMapUpdate)
	end
else
	-- Retail: DF+
	Listener:Add("ACTION_EVENT_UTILS_TALENT_MAP", "TRAIT_CONFIG_LIST_UPDATED", function()
		CNDT:RegisterEvent("PLAYER_TALENT_UPDATE")
		CNDT:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE")
		CNDT:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED", "PLAYER_TALENT_UPDATE")
		CNDT:RegisterEvent("TRAIT_CONFIG_UPDATED", "PLAYER_TALENT_UPDATE")
		CNDT:RegisterEvent("TRAIT_CONFIG_LIST_UPDATED", "PLAYER_TALENT_UPDATE")
		local C_TimerAfter = _G.C_Timer.After
		CNDT:RegisterEvent("TRAIT_TREE_CHANGED", function() 
			C_TimerAfter(0.5, function()
				CNDT:PLAYER_TALENT_UPDATE()
			end)
		end)		
		CNDT:PLAYER_TALENT_UPDATE()
		Listener:Remove("ACTION_EVENT_UTILS_TALENT_MAP", "TRAIT_CONFIG_LIST_UPDATED")
	end)
end 

-------------------------------------------------------------------------------
-- UnitSpecsMap  
-------------------------------------------------------------------------------
A.UnitSpecsMap = {}
if BuildToC >= 50500 then
	local C_SpecializationInfo = _G.C_SpecializationInfo
	local 	 GetNumClasses,    GetClassInfo,  											   GetNumSpecializationsForClassID, 										 GetSpecializationInfoForClassID, 	 GetArenaOpponentSpec, 	  GetBattlefieldScore, 	  RequestBattlefieldScoreData,	  UnitName =
		  _G.GetNumClasses, _G.GetClassInfo, C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID or _G.GetNumSpecializationsForClassID, _G.GetSpecializationInfoForClassID, _G.GetArenaOpponentSpec, _G.GetBattlefieldScore, _G.RequestBattlefieldScoreData, _G.UnitName
	local UNKNOWN = CONST.UNKNOWN
	local UnitSpecsMap = A.UnitSpecsMap

	local specNameToRole = {}
	local _, class, classID, specID, spec, desc, icon
	for i = 1, GetNumClasses() do
		_, class, classID = GetClassInfo(i)
		specNameToRole[class] = {}

		for j = 1, GetNumSpecializationsForClassID(classID) do
			specID, spec, desc, icon = GetSpecializationInfoForClassID(classID, j)
			specNameToRole[class][spec] = specID
		end
	end

	local function UnitSpecsMapUpdate()
		wipe(UnitSpecsMap)
		local z = A.Zone
		
		if z == "arena" and GetArenaOpponentSpec then
			local unit, name, server, specID
			for i = 1, TeamCacheEnemy.MaxSize do 
				unit = TeamCacheEnemyIndexToPLAYERs[i]

				if unit then 
					name, server = UnitName(unit)
					if name and name ~= UNKNOWN then
						specID = GetArenaOpponentSpec(i)
						if server then
							name = strjoin("-", name, server)
						end
						UnitSpecsMap[name] = specID				
					end
				end 
			end
		elseif z == "pvp" and GetBattlefieldScore then
			RequestBattlefieldScoreData()
			
			local _, name, classToken, talentSpec, specID
			for i = 1, TeamCacheEnemy.MaxSize do 
				name, _, _, _, _, _, _, _, classToken, _, _, _, _, _, _, talentSpec = GetBattlefieldScore(i)
				if name then
					specID = specNameToRole[classToken][talentSpec]
					UnitSpecsMap[name] = specID
				end
			end
		end
	end

	Listener:Add("ACTION_EVENT_UTILS_UNIT_SPECS_MAP", "UNIT_NAME_UPDATE", 				UnitSpecsMapUpdate)
	Listener:Add("ACTION_EVENT_UTILS_UNIT_SPECS_MAP", "ARENA_OPPONENT_UPDATE", 			UnitSpecsMapUpdate)
	Listener:Add("ACTION_EVENT_UTILS_UNIT_SPECS_MAP", "GROUP_ROSTER_UPDATE", 			UnitSpecsMapUpdate)
	Listener:Add("ACTION_EVENT_UTILS_UNIT_SPECS_MAP", "PLAYER_ENTERING_WORLD", 			UnitSpecsMapUpdate)
end

-------------------------------------------------------------------------------
-- Env.LastPlayerCast
-------------------------------------------------------------------------------
-- Note: This code is modified for Action Core 
do
    local module = CNDT:GetModule("LASTCAST", true)
    if not module then
        module = CNDT:NewModule("LASTCAST", "AceEvent-3.0")
        
        local pGUID = UnitGUID("player")
        assert(pGUID, "pGUID was null when func string was generated!")
		
		local blacklist = {
			[75] = true, 					-- Hunter's Auto Shot
        }
        
        module:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED",
            function()
                local _, e, _, sourceGuid, _, _, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo()
                if (e == "SPELL_CAST_SUCCESS" or e == "SPELL_MISS") and sourceGuid == pGUID and not blacklist[spellID] then
                    Env.LastPlayerCastName 	= strlowerCache[spellName]
                    --Env.LastPlayerCastID 	= spellID
					A.LastPlayerCastName	= spellName
					--A.LastPlayerCastID	= spellID
                    TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
                end
        end)    
        
        module:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED",
            function(_, unit, _, spellID)
                if unit == "player" and not blacklist[spellID] then
					local spellName			= A_GetSpellInfo(spellID)
                    Env.LastPlayerCastName 	= strlowerCache[spellName]
                    Env.LastPlayerCastID 	= spellID
					A.LastPlayerCastName	= spellName
					A.LastPlayerCastID		= spellID
                    TMW:Fire("TMW_CNDT_LASTCAST_UPDATED")
                end
        end)  
    end
end

-------------------------------------------------------------------------------
-- DogTags
-------------------------------------------------------------------------------
local DogTag = LibStub("LibDogTag-3.0", true)
TMW:RegisterCallback("TMW_ACTION_MODE_CHANGED", 		DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_BURST_CHANGED",		DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_AOE_CHANGED", 			DogTag.FireEvent, DogTag)
TMW:RegisterCallback("TMW_ACTION_RANK_DISPLAY_CHANGED", DogTag.FireEvent, DogTag)
-- Taste's 
--TMW:RegisterCallback("TMW_ACTION_CD_MODE_CHANGED", 	DogTag.FireEvent, DogTag)
--TMW:RegisterCallback("TMW_ACTION_AOE_MODE_CHANGED", 	DogTag.FireEvent, DogTag)

local function removeLastChar(text)
	return text:sub(1, -2)
end

if DogTag then
	-- Changes displayed mode on rotation frame
    DogTag:AddTag("TMW", "ActionMode", {
        code = function()
            return A.IsInPvP and "PvP" or "PvE"
        end,
        ret = "string",
        doc = "Displays Rotation Mode",
		example = '[ActionMode] => "PvE"',
        events = "TMW_ACTION_MODE_CHANGED",
        category = "Action",
    })
	-- Changes displayed burst on rotation frame 
	DogTag:AddTag("TMW", "ActionBurst", {
        code = function()
			if A.IsInitialized then 
				local Toggle = GetToggle(1, "Burst") or ""
				Toggle = Toggle and Toggle:upper()
				return Toggle == "EVERYTHING" and ("|c" .. ActionDataColor["GREEN"] .. "EVERY|r") or Toggle == "OFF" and ("|c" .. removeLastChar(ActionDataColor["RED"]) .. Toggle .. "|r") or ("|c" .. ActionDataColor["GREEN"] .. Toggle .. "|r")
			else 
				return ""
			end 
        end,
        ret = "string",
        doc = "Displays Rotation Burst",
		example = '[ActionBurst] => "Auto, Off, Everything"',
        events = "TMW_ACTION_BURST_CHANGED",
        category = "Action",
    })
	-- Changes displayed aoe on rotation frame 
	DogTag:AddTag("TMW", "ActionAoE", {
        code = function()
			if A.IsInitialized then 
				return GetToggle(2, "AoE") and ("|c" .. ActionDataColor["GREEN"] .. "AoE|r") or "|c" .. removeLastChar(ActionDataColor["RED"]) .. "AoE|r"
			else 
				return ""
			end 
        end,
        ret = "string",
        doc = "Displays Rotation AoE",
		example = '[ActionAoE] => "AoE (green or red)"',
        events = "TMW_ACTION_AOE_CHANGED",
        category = "Action",
    })
	-- Changes displayed rank of spell on rotation frame 
	DogTag:AddTag("TMW", "ActionRank", {
        code = function()
			return A.IsInitialized and RankSingle.isColored or "" 
        end,
        ret = "string",
        doc = "Displays Rotation SpellRank in use on the frame",
		example = '[ActionRank] => "1"',
        events = "TMW_ACTION_RANK_DISPLAY_CHANGED",
        category = "Action",
    })
	
	-- Taste's 
	--[[
    DogTag:AddTag("TMW", "ActionModeCD", {
        code = function()            
			if A.IsInitialized and GetToggle(1, "Burst") ~= "Off" then
			    return "|cff00ff00CD|r"
			else 
				return "|cFFFF0000CD|r"
			end
        end,
        ret = "string",
        doc = "Displays CDs Mode",
		example = '[ActionModeCD] => "CDs ON"',
        events = "TMW_ACTION_CD_MODE_CHANGED",
        category = "ActionCDs",
    })
	DogTag:AddTag("TMW", "ActionModeAoE", {
        code = function()            
			if A.IsInitialized and GetToggle(1, "AoE") then
			    return "|cff00ff00AoE|r"
			else 
				return "|cFFFF0000AoE|r"
			end
        end,
        ret = "string",
        doc = "Displays AoE Mode",
		example = '[ActionModeAoE] => "AoE ON"',
        events = "TMW_ACTION_AOE_MODE_CHANGED",
        category = "ActionAoE",
    })	
	]]
	-- The biggest problem of TellMeWhen what he using :setup on frames which use DogTag and it's bring an error
	TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED", function()
		TMW:Fire("TMW_ACTION_MODE_CHANGED")
		TMW:Fire("TMW_ACTION_BURST_CHANGED")
		TMW:Fire("TMW_ACTION_AOE_CHANGED")
		TMW:Fire("TMW_ACTION_RANK_DISPLAY_CHANGED")
		-- Taste's 
		--TMW:Fire("TMW_ACTION_CD_MODE_CHANGED")		
		--TMW:Fire("TMW_ACTION_AOE_MODE_CHANGED")
	end)
end

-------------------------------------------------------------------------------
-- Icons
-------------------------------------------------------------------------------
-- Note: icon can be "TMW:icon:1S2PCb9iygE4" (as GUID) or "TellMeWhen_Group1_Icon1" (as ID)
function Env.IsIconPhysicallyShown(icon)
	-- @return boolean, if icon physically shown	
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.attributes.realAlpha == 1) or false
end 

function Env.IsIconDisplay(icon)
	-- @return textureID or 0 
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.Enabled and FRAME:IsVisible() and FRAME.attributes.texture) or 0    
end

function Env.IsIconEnabled(icon)
	-- @return boolean
    local FRAME = TMW:GetDataOwner(icon)
    return (FRAME and FRAME.Enabled) or false
end

-------------------------------------------------------------------------------
-- IconType: TheAction - LossOfControl
-------------------------------------------------------------------------------
local L = TMW.L
local INCONTROL 	= 1 -- Inside control 
local CONTROLLOST 	= 2 -- Out of control  

local TypeLOC = TMW.Classes.IconType:New("TheAction - LossOfControl")
TypeLOC.name = "[The Action] " .. L["LOSECONTROL_ICONTYPE"]	
TypeLOC.desc = L["LOSECONTROL_ICONTYPE_DESC"]
TypeLOC.menuIcon = "Interface\\Icons\\Spell_Shadow_Possession"
TypeLOC.AllowNoName = true
TypeLOC.usePocketWatch = 1
TypeLOC.hasNoGCD = true
TypeLOC.canControlGroup = true

TypeLOC:UsesAttributes("state")
TypeLOC:UsesAttributes("start, duration")
TypeLOC:UsesAttributes("texture")

TypeLOC:RegisterConfigPanel_XMLTemplate(165, "TellMeWhen_IconStates", {
	[INCONTROL] 	= { text = "|cFF00FF00" .. L["LOSECONTROL_INCONTROL"],   },
	[CONTROLLOST] 	= { text = "|cFFFF0000" .. L["LOSECONTROL_CONTROLLOST"], },
})

local function LossOfControlOnUpdate(icon, time)
	local attributes = icon.attributes
	local start = attributes.start or 0
	local duration = attributes.duration or 0
	
	if duration == huge then 
		duration = select(2, A_LossOfControl:GetFrameData())
	end 

	if duration ~= 0 and time - start < duration then 
		icon:SetInfo(
			"state; start, duration",
			CONTROLLOST,
			start, duration
		)
	else 
		icon:SetInfo(
			"texture; state; start, duration",
			icon.FirstTexture,
			INCONTROL,
			0, 0
		)
	end 
	--[[
	if TMW.time - start > duration then	
		icon:SetInfo(
			"texture; state; start, duration",
			icon.FirstTexture,
			INCONTROL,
			0, 0
		)	
		--icon.NextUpdateTime = 0 -- FIX ME: Is it necessary to prevent persistent auras??
	else
		icon:SetInfo(
			"state; start, duration",
			CONTROLLOST,
			start, duration
		)			
	end]]
end

local function LossOfControlOnEvent(icon)	
	local textureID, duration = A_LossOfControl:GetFrameData()		
	if duration ~= 0 and textureID ~= 0 then 
		icon:SetInfo(
			"texture; state; start, duration",
			textureID,
			CONTROLLOST,
			TMW.time, duration
		)
	else 
		icon:SetInfo(
			"texture; state; start, duration",
			icon.FirstTexture,
			INCONTROL,
			0, 0
		)
	end 
	--icon.NextUpdateTime = 0
end 

function TypeLOC:Setup(icon)	
	icon.FirstTexture = GetSpellTexture(CONST.PICKPOCKET)
	icon:SetInfo("texture", icon.FirstTexture)
	
	TMW:RegisterCallback("TMW_ACTION_LOSS_OF_CONTROL_UPDATE", LossOfControlOnEvent, icon)
	
	icon:SetUpdateMethod("manual")	
	icon:SetUpdateFunction(LossOfControlOnUpdate)
	icon:Update()
end

TypeLOC:Register(103)

-------------------------------------------------------------------------------
-- Misc
-------------------------------------------------------------------------------
local BlackBackground 	= CreateFrame("Frame", nil, UIParent)
if _G.BackdropTemplateMixin == nil and BlackBackground.SetBackdrop then -- Only expac less than Shadowlands
	BlackBackground:SetBackdrop(nil)
end 
BlackBackground:SetFrameStrata("HIGH")
BlackBackground:SetSize(273, 30)
BlackBackground:SetPoint("TOPLEFT", 0, 12) 
BlackBackground:SetShown(false)
BlackBackground.IsEnable = true
BlackBackground.texture = BlackBackground:CreateTexture(nil, "OVERLAY")
BlackBackground.texture:SetAllPoints(true)
BlackBackground.texture:SetColorTexture(0, 0, 0, 1)

local function CreateMiscFrame(name, anchor, x, y)
	local frame 		= CreateFrame("Frame", name, UIParent)
	if frame.SetBackdrop then 
		frame:SetBackdrop(nil)
	end 
	frame:SetFrameStrata("TOOLTIP")
	frame:SetToplevel(true)
	frame:SetSize(1, 1)
	frame:SetScale(1)
	frame:SetPoint(anchor, x, y)
	frame.texture = frame:CreateTexture(nil, "OVERLAY")
	frame.texture:SetAllPoints(true)
	frame.texture:SetColorTexture(0, 0, 0, 1.0)
	return frame
end 

local RankSingle 		 = CreateMiscFrame("RankSingle", "TOPLEFT", 163, -1)
local RankAoE	 		 = CreateMiscFrame("RankAoE", "TOPLEFT", 163, -2)
local Character	 		 = CreateMiscFrame(nil, "TOPLEFT", 163, -3)
Character.texture:SetColorTexture(ownerColor())
TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", function()
	ownerColor = CharacterToUniversalColor[ownerVersion] and CharacterToUniversalColor[ownerVersion][A[owner]] or CharacterToUniversalColor[""]
	if ownerColor then 
		if not Character:IsShown() then
            Character:Show()
        end	
		Character.texture:SetColorTexture(ownerColor())
		TimerSetRefreshAble("Character:Hide", 20, function() Character:Hide() end)
	end 
end) 

local Framework	 		 = CreateMiscFrame(nil, "TOPLEFT", 163, -4)
function Framework:UpdateColor()
	local current = A.IsInitialized and GetToggle(9, "Framework") or "v1"
	if Framework.lastknown ~= current then
		Framework.lastknown = current
		if not Framework:IsShown() then
            Framework:Show()
        end	
		
		if current == "v1" then
			Framework.texture:SetColorTexture(ActionDataUniversalColor[1]())
		elseif current == "v2" then
			Framework.texture:SetColorTexture(ActionDataUniversalColor[2]())
		elseif current == "MetaEngine" then
			Framework.texture:SetColorTexture(ActionDataUniversalColor[3]())		
		end

		TMW:Fire("TMW_ACTION_UPDATE_FRAMES_OPACITY")
		TimerSetRefreshAble("Framework:Hide", 20, function() Framework:Hide() end)		
	end
end
TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED", Framework.UpdateColor)
TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED", Framework.UpdateColor)
TMW:RegisterCallback("TMW_ACTION_ON_PROFILE_POST", Framework.UpdateColor)
TMW:RegisterCallback("TMW_ACTION_FRAMEWORK_CHANGED", Framework.UpdateColor)

local function UpdateFrames()
    if not TellMeWhen_Group1 or not strfind(strlowerCache(TellMeWhen_Group1.Name), "shown main") then 
        if BlackBackground:IsShown() then
            BlackBackground:Hide()
        end     
		
        if TargetColor and TargetColor:IsShown() then
            TargetColor:Hide()
        end  
		
		if RankSingle:IsShown() then
            RankSingle:Hide()
        end				
		
		if RankAoE:IsShown() then
            RankAoE:Hide()
        end	

		if Character:IsShown() then 
			Character:Hide()
		end 
		
		if Framework:IsShown() then 
			Framework:Hide()
		end		
		
        return 
    end
	
	----------------------
	-- SCALE CONTROLLER --
	--	
	
	local myheight = select(2, GetPhysicalScreenSize())
    local myscale1 = 0.42666670680046 * (1080 / myheight)  
    local group1 = TellMeWhen_Group1:GetEffectiveScale()  
	
	-- "Shown Main"
    if group1 ~= nil and group1 ~= myscale1 then
        TellMeWhen_Group1:SetParent(nil)
        TellMeWhen_Group1:SetScale(myscale1) 
        TellMeWhen_Group1:SetFrameStrata("TOOLTIP")
        TellMeWhen_Group1:SetToplevel(true) 
        if BlackBackground.IsEnable then 
            if not BlackBackground:IsShown() then
                BlackBackground:Show()
            end
            BlackBackground:SetScale(myscale1 / (BlackBackground:GetParent() and BlackBackground:GetParent():GetEffectiveScale() or 1))      
        end 
    end
	
	-- HealingEngine
    if TargetColor then
        if not TargetColor:IsShown() then
            TargetColor:Show()
        end
        TargetColor:SetScale((0.71111112833023 * (1080 / myheight)) / (TargetColor:GetParent() and TargetColor:GetParent():GetEffectiveScale() or 1))
    end           

	-- Rank Spells 
	if RankSingle then 
		if not RankSingle:IsShown() then
            RankSingle:Show()
        end
        RankSingle:SetScale((0.71111112833023 * (1080 / myheight)) / (RankSingle:GetParent() and RankSingle:GetParent():GetEffectiveScale() or 1))	
	end 
	
	if RankAoE then 
		if not RankAoE:IsShown() then
            RankAoE:Show()
        end
        RankAoE:SetScale((0.71111112833023 * (1080 / myheight)) / (RankAoE:GetParent() and RankAoE:GetParent():GetEffectiveScale() or 1))	
	end 	
	
	-- Character
	if Character then 
		if not Character:IsShown() then
            Character:Show()
        end
        Character:SetScale((0.71111112833023 * (1080 / myheight)) / (Character:GetParent() and Character:GetParent():GetEffectiveScale() or 1))	
		TimerSetRefreshAble("Character:Hide", 20, function() Character:Hide() end)
	end 

	-- Framework
	if Framework then 
		if not Framework:IsShown() then
            Framework:Show()
        end
        Framework:SetScale((0.71111112833023 * (1080 / myheight)) / (Framework:GetParent() and Framework:GetParent():GetEffectiveScale() or 1))	
		TimerSetRefreshAble("Framework:Hide", 20, function() Framework:Hide() end)
	end 	

	------------------------
	-- OPACITY CONTROLLER --
	-- Update opacity only for v1 frames, skip other frames as they still can be used for AutoProfile
	--
	
	local alpha = A.MetaEngine and A.MetaEngine:IsHealthy() and GetToggle(1, "DisableRegularFrames") and 0 or 1
	
	if group1 and TellMeWhen_Group1:GetAlpha() ~= alpha then
		TellMeWhen_Group1:SetAlpha(alpha)
	end

	if TargetColor and TargetColor:GetAlpha() ~= alpha then
		TargetColor:SetAlpha(alpha)
	end	
	
	-- Rank Spells 
	if RankSingle and RankSingle:GetAlpha() ~= alpha then 
		RankSingle:SetAlpha(alpha)
	end 
	
	if RankAoE and RankAoE:GetAlpha() ~= alpha then 
		RankAoE:SetAlpha(alpha)
	end
end

local function UpdateCVAR()
	if not A.IsInitialized then return end
	
	local CVars = GetToggle(1, "CVars")
	
    if CVars[1] and GetCVar("Contrast") ~= "50" then 
		SetCVar("Contrast", 50)
		Print("Contrast should be 50")		
	end
	
    if CVars[2] and GetCVar("Brightness") ~= "50" then 
		SetCVar("Brightness", 50) 
		Print("Brightness should be 50")			
	end
	
    if CVars[3] and GetCVar("Gamma") ~= "1.000000" then 
		SetCVar("Gamma", "1.000000") 
		Print("Gamma should be 1")	
	end
	
	if CVars[4] then
		local colorblindsimulator = GetCVar("colorblindsimulator") -- Renamed to colorblindSimulator on some versions (?)
		if colorblindsimulator ~= nil and colorblindsimulator ~= "0" then 
			SetCVar("colorblindsimulator", 0) 
		end 
		
		local colorblindSimulator = GetCVar("colorblindSimulator")
		if colorblindSimulator ~= nil and colorblindSimulator ~= "0" then 
			SetCVar("colorblindSimulator", 0) 
		end 
	end
	
	if CVars[5] then
		local colorblindWeaknessFactor = GetCVar("colorblindWeaknessFactor")
		if colorblindWeaknessFactor ~= nil and colorblindWeaknessFactor ~= "0.5"  then 
			SetCVar("colorblindWeaknessFactor", 0.5) 
		end
	end
	
	if CVars[6] and toNum[GetCVar("SpellQueueWindow") or 400] == nil then 
		SetCVar("SpellQueueWindow", 400) 
	end 
	
    if CVars[7] and GetCVar("doNotFlashLowHealthWarning") ~="1" then 
		SetCVar("doNotFlashLowHealthWarning", 1) 
	end
	
	if CVars[8] then
		local nameplateMaxDistance = GetCVar("nameplateMaxDistance")
		if nameplateMaxDistance and toNum[nameplateMaxDistance] < CONST.CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE then 
			SetCVar("nameplateMaxDistance", CONST.CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE) 
			Print("nameplateMaxDistance " .. nameplateMaxDistance .. " => " .. CONST.CACHE_DEFAULT_NAMEPLATE_MAX_DISTANCE)	
		end	
	end
	
	if CVars[9] and isClassic and toNum[GetCVar("nameplateNotSelectedAlpha") or 0] >= 0 then 
		SetCVar("nameplateNotSelectedAlpha", -1)
	end 
	
	if CVars[10] and toNum[GetCVar("nameplateOccludedAlphaMult") or 0] > 0.4 then 
		SetCVar("nameplateOccludedAlphaMult", 0.4)
	end 
	
	-- Description fix
	if CVars[11] and toNum[GetCVar("breakUpLargeNumbers") or 1] ~= 0 then 
		SetCVar("breakUpLargeNumbers", 0)
	end
	
    -- WM removal
    if CVars[12] and GetCVar("screenshotQuality") ~= "10" then 
		SetCVar("screenshotQuality", 10)  
	end
	
    if CVars[13] and GetCVar("nameplateShowEnemies") ~= "1" then
        SetCVar("nameplateShowEnemies", 1) 
		Print("Enemy nameplates should be enabled")
    end
	
	if CVars[14] and GetCVar("autoSelfCast") ~= "1" then 
		SetCVar("autoSelfCast", 1)
	end 
	
	if GetToggle(1, "cameraDistanceMaxZoomFactor") then 
		local cameraDistanceMaxZoomFactor = GetCVar("cameraDistanceMaxZoomFactor")
		if cameraDistanceMaxZoomFactor ~= "4" then 
			SetCVar("cameraDistanceMaxZoomFactor", 4) 
			Print("cameraDistanceMaxZoomFactor " .. cameraDistanceMaxZoomFactor .. " => " .. 4)	
		end		
	end
end
TMW:RegisterCallback("TMW_ACTION_CVARS_CHANGED", UpdateCVAR)

local function ConsoleUpdate()
	UpdateCVAR()
    UpdateFrames()      
end 

TMW:RegisterSelfDestructingCallback("TMW_ACTION_IS_INITIALIZED_PRE", function()
    TMW:RegisterCallback("TMW_GROUP_SETUP_POST", function(_, frame)
		local str_group = toStr[frame]
		if strfind(str_group, "TellMeWhen_Group1") then                
			UpdateFrames()  
		end
    end)
	
	TMW:RegisterCallback("TMW_ACTION_UPDATE_FRAMES_OPACITY", 		UpdateFrames	)
	
	Listener:Add("ACTION_EVENT_UTILS", "DISPLAY_SIZE_CHANGED", 		ConsoleUpdate	)
	Listener:Add("ACTION_EVENT_UTILS", "UI_SCALE_CHANGED", 			ConsoleUpdate	)
	
	-- [[ COMPATIBILITY FOR OLD INTERFACE ]] 
	--Listener:Add("ACTION_EVENT_UTILS", "PLAYER_ENTERING_WORLD", 	ConsoleUpdate	)
	--Listener:Add("ACTION_EVENT_UTILS", "CVAR_UPDATE",				UpdateCVAR		)
	if VideoOptionsFrame then 
		VideoOptionsFrame:HookScript("OnHide", 						ConsoleUpdate	)
	end 
	
	if InterfaceOptionsFrame then 
		InterfaceOptionsFrame:HookScript("OnHide", 					UpdateCVAR		)
	end 
	--------------------------------------------------------------------------------
	
	-- ONLY CLASSIC: For GetToggle things we have to make post call	
	if isClassic then 
		TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED", 			UpdateCVAR		) 
	end 
	
	if SettingsPanel then 
		SettingsPanel:HookScript("OnHide", 							ConsoleUpdate	) 		
	end 
	
    ConsoleUpdate()
	
    return true -- Signal RegisterSelfDestructingCallback to unregister
end)   

function A.BlackBackgroundIsShown()
	-- @return boolean 
	return BlackBackground:IsShown()
end 

function A.BlackBackgroundSet(bool)
    BlackBackground.IsEnable = bool 
    BlackBackground:SetShown(bool)
end

-------------------------------------------------------------------------------
-- Frames 
-------------------------------------------------------------------------------
-- TellMeWhen Documentation - Sets attributes of an icon.
-- 
-- The attributes passed to this function will be processed by a [[api/icon-data-processor/api-documentation/|IconDataProcessor]] (and possibly one or more [[api/icon-data-processor-hook/api-documentation/|IconDataProcessorHook]]) and interested [[api/icon-module/api-documentation/|IconModule]]s will be notified of any changes to the attributes.
-- @name Icon:SetInfo
-- @paramsig signature, ...
-- @param signature [string] A semicolon-delimited string of attribute strings as passed to the constructor of a [[api/icon-data-processor/api-documentation/|IconDataProcessor]].
-- @param ... [...] Any number of params that will match up one-for-one with the signature passed in.
-- @usage icon:SetInfo("texture", "Interface\\AddOns\\TellMeWhen\\Textures\\Disabled")
--  
--  -- From IconTypes/IconType_wpnenchant:
--  icon:SetInfo("state; start, duration; spell",
--    STATE_ABSENT,
--    0, 0,
--    nil
--  )
-- 
--  -- From IconTypes/IconType_reactive:
--  icon:SetInfo("state; texture; start, duration; charges, maxCharges, chargeStart, chargeDur; stack, stackText; spell",
--    STATE_USABLE,
--    GetSpellTexture(iName),
--    start, duration,
--    charges, maxCharges, chargeStart, chargeDur
--    stack, stack,
--    iName			
local paramTable = {}
local function TMWAPI(icon, ...)
    local attributesString, param = ...
	
	if icon.attributes then 
		if attributesString == "state" then 
			-- Color if not colored (Alpha will show it)
			if type(param) == "table" and param["Color"] then 
				if icon.attributes.calculatedState.Color ~= param["Color"] then 
					paramTable.Color, paramTable.Alpha, paramTable.Texture = param["Color"], param["Alpha"], param["Texture"]
					icon:SetInfo(attributesString, paramTable)
				end
				return 
			end 
			
			-- Hide if not hidden
			if type(param) == "number" and (param == 0 or param == CONST.TMW_DEFAULT_STATE_HIDE) then
				if icon.attributes.realAlpha ~= 0 then 
					icon:SetInfo(attributesString, param)
				end 
				return 
			end 
		end 
		
		if attributesString == "texture" and type(param) == "number" then         
			if (icon.attributes.calculatedState.Color ~= "ffffffff" or icon.attributes.realAlpha == 0) then 
				-- Show + Texture if hidden
				icon:SetInfo(strjoin("", "state; ", attributesString), CONST.TMW_DEFAULT_STATE_SHOW, param)
			elseif icon.attributes.texture ~= param then 
				-- Texture if not applied        
				icon:SetInfo(attributesString, param)
			end 
			return         
		end 
	end 
    
    icon:SetInfo(...)
end
  
function A.Hide(icon)
	-- @usage A.Hide(icon)
	if not icon then 
		error("A.Hide tried to hide nil 'icon'", 2)
	else 
		local meta = icon.ID		
		if meta == 3 and RankSingle.isColored then 
			RankSingle.texture:SetColorTexture(0, 0, 0, 1.0)
			RankSingle.isColored = nil 
			TMW:Fire("TMW_ACTION_RANK_DISPLAY_CHANGED")
		end 
		
		if meta == 4 and RankAoE.isColored then 
			RankAoE.texture:SetColorTexture(0, 0, 0, 1.0)
			RankAoE.isColored = nil 
		end 
		
		if icon.attributes.state ~= CONST.TMW_DEFAULT_STATE_HIDE then 
			TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", meta, A)
			icon:SetInfo("state; texture", CONST.TMW_DEFAULT_STATE_HIDE, "")			
		end 
	end 
end 

function A:Show(icon, texture) 
	-- @usage self:Show(icon) for own texture with color filter or self:Show(icon, textureID)		
	if not icon then 
		error((not texture and self:GetKeyName() or tostring(texture)) .. " tried to use Show() method with nil 'icon'", 2)
	else 
		-- Sets ranks 
		local meta = icon.ID
		
		-- Only fire for pure action object, moved here for performance
		TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", meta, self.Start and self:IsQueued() and getmetatable(self).__index or self, texture)
		
		if meta == 3 then 
			if not self.useMaxRank and self.isRank then 
				if self.isRank ~= RankSingle.isColored then 
					RankSingle.texture:SetColorTexture(ActionDataUniversalColor[self.isRank]())
					RankSingle.isColored = self.isRank 
					TMW:Fire("TMW_ACTION_RANK_DISPLAY_CHANGED")
				end 
			elseif RankSingle.isColored then 
				RankSingle.texture:SetColorTexture(0, 0, 0, 1.0)
				RankSingle.isColored = nil 
				TMW:Fire("TMW_ACTION_RANK_DISPLAY_CHANGED")
			end 
		end 
		
		if meta == 4 then 
			if not self.useMaxRank and self.isRank then 
				if self.isRank ~= RankAoE.isColored then 
					RankAoE.texture:SetColorTexture(ActionDataUniversalColor[self.isRank]())
					RankAoE.isColored = self.isRank 
				end 
			elseif RankAoE.isColored then 
				RankAoE.texture:SetColorTexture(0, 0, 0, 1.0)
				RankAoE.isColored = nil 
			end 	
		end 
		
		if texture then 
			TMWAPI(icon, "texture", texture)
		else 
			TMWAPI(icon, self:Texture())
		end 		
				
		return true 
	end 
end 

function A:ExecuteScript()
	if not self:IsBlocked() and self.LastTimeExecuted ~= TMW.time then
		self.LastTimeExecuted = TMW.time
		TMW:Fire("TMW_ACTION_METAENGINE_UPDATE", "Script", self)
	end
end

function A.FrameHasSpell(frame, spellID)
	-- @return boolean 
	-- @usage A.FrameHasSpell(icon, {123, 168, 18}) or A.FrameHasSpell(icon, 1022)
	if frame and frame.Enabled and frame:IsVisible() and frame.attributes and type(frame.attributes.texture) == "number" then 
		local texture = frame.attributes.texture
		if type(spellID) == "table" then 
			for i = 1, #spellID do 
				if texture == GetSpellTexture(spellID[i]) then 
					return true 
				end 
			end 
		else 
			return texture == GetSpellTexture(spellID) 
		end 	
	end 
	return false 
end 

function A.FrameHasObject(frame, ...)
	-- @return boolean 
	-- @usage A.FrameHasObject(frame, A.Spell1, A.Item1)
	if frame and frame.Enabled and frame:IsVisible() and frame.attributes and frame.attributes.texture and frame.attributes.texture ~= "" then 
		local texture = frame.attributes.texture
		for i = 1, select("#", ...) do 
			local obj = select(i, ...)
			local _, objTexture = obj:Texture()
			if objTexture and objTexture == texture then 
				return true 
			end 
		end 
	end 
end 

-------------------------------------------------------------------------------
-- TMW Help Frame
-------------------------------------------------------------------------------
Listener:Add("ACTION_EVENT_UTILS_TMW_HELP", "ADDON_LOADED", function(addonName) 
	if addonName == CONST.ADDON_NAME_TMW_OPTIONS or addonName == CONST.ADDON_NAME_TMW then 
		_G.TellMeWhen_IconEditor.Pages.Help:HookScript("OnShow", function(self)
			self:Hide()
		end)
		Listener:Remove("ACTION_EVENT_UTILS_TMW_HELP", "ADDON_LOADED")
	end 
end)

-------------------------------------------------------------------------------
-- TMW PlayerNames fix
-------------------------------------------------------------------------------
if TELLMEWHEN_VERSIONNUMBER <= 87303 then -- Classic 87303
	local NAMES 											= TMW.NAMES
	local GetNumBattlefieldScores, 	  GetBattlefieldScore 	= 
	   _G.GetNumBattlefieldScores, _G.GetBattlefieldScore
	function NAMES:UPDATE_BATTLEFIELD_SCORE()
		for i = 1, GetNumBattlefieldScores() do
			local name, _, _, _, _, _, _, _, _, classToken = GetBattlefieldScore(i)
			if name and self.ClassColors[classToken] then 
				self.ClassColoredNameCache[name] = self.ClassColors[classToken] .. name .. "|r"
			end
		end
	end
end 

-------------------------------------------------------------------------------
-- TMW IconConfig.lua attempt to index field 'CurrentTabGroup' (nil value) fix
-------------------------------------------------------------------------------
Listener:Add("ACTION_EVENT_UTILS_TMW_OPTIONS", "ADDON_LOADED", function(addonName) 
	if addonName == CONST.ADDON_NAME_TMW_OPTIONS or addonName == CONST.ADDON_NAME_TMW then 
		local IE 			= TMW.IE
		local CI 			= TMW.CI
		local PlaySound 	= _G.PlaySound
		if not IE or not CI then 
			return 
		end 
		function IE:LoadIcon(isRefresh, icon)
			if icon ~= nil then

				local ic_old = CI.icon

				if type(icon) == "table" then			
					PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
					IE:SaveSettings()
					
					CI.icon = icon
					
					if ic_old ~= CI.icon then
						IE.Pages.IconMain.PanelsLeft.ScrollFrame:SetVerticalScroll(0)
						IE.Pages.IconMain.PanelsRight.ScrollFrame:SetVerticalScroll(0)
					end

					IE.TabGroups.ICON:SetChildrenEnabled(true)

				elseif icon == false then
					CI.icon = nil
					IE.TabGroups.ICON:SetChildrenEnabled(false)

					if IE.CurrentTabGroup and IE.CurrentTabGroup.identifier == "ICON" then
						IE.ResetButton:Disable()
					end
				end

				TMW:Fire("TMW_CONFIG_ICON_LOADED_CHANGED", CI.icon, ic_old)
			end

			IE:Load(isRefresh)
		end
		Listener:Remove("ACTION_EVENT_UTILS_TMW_OPTIONS", "ADDON_LOADED")	
	end 	
end)

-------------------------------------------------------------------------------
-- TMW LockToggle fix
-------------------------------------------------------------------------------
local InCombatLockdown = _G.InCombatLockdown
local function LockToggle()
	if not TMW.Locked and not TMW.ALLOW_LOCKDOWN_CONFIG and (InCombatLockdown() or A.Zone == "pvp") then 
		TMW.ALLOW_LOCKDOWN_CONFIG = true 
		TMW:LockToggle()
		TMW:Update()
		TMW.ALLOW_LOCKDOWN_CONFIG = false
	end 
end 
hooksecurefunc(TMW, "LockToggle", LockToggle)

-------------------------------------------------------------------------------
-- TMW GetCurrentSpecialization fix
-------------------------------------------------------------------------------
-- Fixes error "Message: ...nterface/AddOns/TellMeWhen/Components/Core/Utils.lua:1496: attempt to perform arithmetic on local 'i' (a nil value)"
-- Cata-and-earlier
local A_GetCurrentSpecialization = A.GetCurrentSpecialization
local TMW_GetCurrentSpecialization = TMW.GetCurrentSpecialization
if A_GetCurrentSpecialization and TMW_GetCurrentSpecialization then 
	function TMW.GetCurrentSpecialization(...)
		return TMW_GetCurrentSpecialization(...) or A_GetCurrentSpecialization()
	end 
end