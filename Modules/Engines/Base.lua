-------------------------------------------------------------------------------
--[[ 
Global nil-able variables:
A.Zone				(@string)		"none", "pvp", "arena", "party", "raid", "scenario"
A.ZoneID			(@number) 		wow.gamepedia.com/UiMapID/Classic
A.IsInInstance		(@boolean)
A.TimeStampZone 	(@number)
A.TimeStampDuel 	(@number)
A.IsInPvP 			(@boolean)
A.IsInDuel			(@boolean)

Global tables:
A.InstanceInfo 		(@table: Name, Type, difficultyID, ID, GroupSize)
A.TeamCache			(@table) - return cached units + info about friendly and enemy group
]]
-------------------------------------------------------------------------------
local _G, pairs, type, math 					= 
	  _G, pairs, type, math
	  
local TMW 										= _G.TMW
local A   										= _G.Action
local CONST 									= A.Const
local Listener									= A.Listener	

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit 

Listener:Add("ACTION_EVENT_BASE", "ADDON_LOADED", function(event, addonName) -- "ACTION_EVENT_BASE" fires with arg1 event!
	if addonName == CONST.ADDON_NAME then 
		A_Unit = A.Unit 
		Listener:Remove("ACTION_EVENT_BASE", "ADDON_LOADED")	
	end 	
end)
-------------------------------------------------------------------------------

local InstanceInfo								= {}
local TeamCache									= { 
	threatData									= {},
	Friendly 									= {
		Size									= 1,
		MaxSize									= 1,
		UNITs									= {},
		GUIDs									= {},
		IndexToPLAYERs							= {},
		IndexToPETs								= {},
		-- [[ Classic only ]]
		hasShaman								= false,
	},
	Enemy 										= {
		Size 									= 0,
		MaxSize									= 0,
		UNITs									= {},
		GUIDs 									= {},
		IndexToPLAYERs							= {},
		IndexToPETs								= {},
		-- [[ Classic only ]]
		hasShaman 								= false,
	},
}

local TeamCacheFriendly 						= TeamCache.Friendly
local TeamCacheFriendlyUNITs					= TeamCacheFriendly.UNITs -- unitID to unitGUID
local TeamCacheFriendlyGUIDs					= TeamCacheFriendly.GUIDs -- unitGUID to unitID
local TeamCacheFriendlyIndexToPLAYERs			= TeamCacheFriendly.IndexToPLAYERs
local TeamCacheFriendlyIndexToPETs				= TeamCacheFriendly.IndexToPETs
local TeamCacheEnemy 							= TeamCache.Enemy
local TeamCacheEnemyUNITs						= TeamCacheEnemy.UNITs -- unitID to unitGUID
local TeamCacheEnemyGUIDs						= TeamCacheEnemy.GUIDs -- unitGUID to unitID
local TeamCacheEnemyIndexToPLAYERs				= TeamCacheEnemy.IndexToPLAYERs
local TeamCacheEnemyIndexToPETs					= TeamCacheEnemy.IndexToPETs
local TeamCachethreatData						= TeamCache.threatData

local huge 										= math.huge
local wipe										= _G.wipe 
local C_Map										= _G.C_Map 

local 	 IsInRaid, 	  IsInGroup, 	IsInInstance, 	 IsActiveBattlefieldArena,    RequestBattlefieldScoreData = 
	  _G.IsInRaid, _G.IsInGroup, _G.IsInInstance, _G.IsActiveBattlefieldArena, _G.RequestBattlefieldScoreData

local 	 UnitInBattleground, 	UnitExists,    UnitIsFriend, 	UnitGUID = 
	  _G.UnitInBattleground, _G.UnitExists, _G.UnitIsFriend, _G.UnitGUID

local 	 GetInstanceInfo, 	 GetNumBattlefieldScores, 	 GetNumGroupMembers =  
	  _G.GetInstanceInfo, _G.GetNumBattlefieldScores, _G.GetNumGroupMembers  

local GetBestMapForUnit 						= C_Map.GetBestMapForUnit	

local playerTarget								= "" -- Classic ThreatData
local player 									= "player"
local pet										= "pet"
local target 									= "target"
local targettarget								= "targettarget"
	  
-------------------------------------------------------------------------------
-- Instance, Zone, Mode, Duel, TeamCache
-------------------------------------------------------------------------------	  
A.TeamCache 	= TeamCache
A.InstanceInfo 	= InstanceInfo

function A:GetTimeSinceJoinInstance()
	-- @return number
	return (self.TimeStampZone and TMW.time - self.TimeStampZone) or huge
end 

function A:GetTimeDuel()
	-- @return number
	return (self.IsInDuel and TMW.time - self.TimeStampDuel - CONST.CACHE_DEFAULT_OFFSET_DUEL) or 0
end 
 
function A:CheckInPvP()
	-- @return boolean
    if  
		self.Zone == "arena" or 
		self.Zone == "pvp" or 
		UnitInBattleground(player) or 
		IsActiveBattlefieldArena() or 
		( A_Unit(target):IsPlayer() and (A_Unit(target):IsEnemy() or (A_Unit(targettarget):IsPlayer() and A_Unit(targettarget):IsEnemy())) )
	then 
		return true 
	end 
	return false 	
end

local GetEventInfo 						= {
	UPDATE_INSTANCE_INFO				= "INSTANCE",
	ZONE_CHANGED						= "ZONE",
	ZONE_CHANGED_INDOORS				= "ZONE",
	ZONE_CHANGED_NEW_AREA				= "ZONE",
	PLAYER_LOGIN						= "ENTERING",
	PLAYER_ENTERING_WORLD				= "ENTERING",
	PLAYER_ENTERING_BATTLEGROUND		= "ENTERING",
	PLAYER_TARGET_CHANGED				= "TARGET",	
	DUEL_REQUESTED						= "DUEL",
	DUEL_FINISHED						= "DUEL",	
	GROUP_ROSTER_UPDATE					= "UNITS",
}
local IsInstanceZone					= {
	INSTANCE							= true,
	ZONE								= true,
	ENTERING							= true,		
}
local IsModeDuel						= {
	ZONE								= true,
	ENTERING							= true,
	TARGET								= true,
	DUEL								= true,
}
local IsUnitUpdate						= {
	INSTANCE							= true,
	ZONE								= true,
	ENTERING							= true,
	UNITS								= true,
}

local eventInfo, oldMode, counter, guid, arena, arenapet, arenapetguid, member, memberpet, memberpetguid
local function OnEvent(event, ...)   
	eventInfo 							= GetEventInfo[event]
	
	-- For threat lib 
	if eventInfo == "TARGET" then 
		playerTarget = UnitExists(target) and (UnitIsFriend(player, target) and targettarget or target) or ""
	end 
	
	-- Update Instance, Zone
	if IsInstanceZone[eventInfo] then
		A.IsInInstance, A.Zone 			= IsInInstance()
		A.ZoneID 						= GetBestMapForUnit(player) or 0
		
		local name, instanceType, difficultyID, _, _, _, _, instanceID, instanceGroupSize = GetInstanceInfo()
		if name then 
			InstanceInfo.Name 			= name 
			InstanceInfo.Type 			= instanceType
			InstanceInfo.difficultyID 	= difficultyID
			InstanceInfo.ID 			= instanceID
			InstanceInfo.GroupSize		= instanceGroupSize
			A.TimeStampZone 			= TMW.time
		end 
	end 
	
	-- Update Mode, Duel
    if IsModeDuel[eventInfo] and not A.IsLockedMode then
		oldMode 						= A.IsInPvP

		-- Duel 
		if eventInfo == "DUEL" then 
			if event == "DUEL_REQUESTED" then
				A.IsInPvP, A.IsInDuel, A.TimeStampDuel = true, true, TMW.time
			else
				A.IsInPvP, A.IsInDuel, A.TimeStampDuel = A:CheckInPvP(), nil, nil				
			end   
		end 
		
		-- Zone, Target
		if eventInfo ~= "DUEL" and not A.IsInDuel then                             			
			A.IsInPvP 					= A:CheckInPvP()  						 
		end  
		
		if oldMode ~= A.IsInPvP then 
			TMW:Fire("TMW_ACTION_MODE_CHANGED")
		end 
	end
	
	-- Update Units 
	if IsUnitUpdate[eventInfo] then 
		-- Wipe Friendly 
		TeamCacheFriendly.hasShaman = false 
		for _, v in pairs(TeamCacheFriendly) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 
		
		-- Wipe Enemy
		TeamCacheEnemy.hasShaman = false 
		for _, v in pairs(TeamCacheEnemy) do
			if type(v) == "table" then 
				wipe(v)
			end 
		end 		                             
				
		-- Enemy
		if A.Zone == "pvp" then
			RequestBattlefieldScoreData()                
			TeamCacheEnemy.Size = GetNumBattlefieldScores()    			
			TeamCacheEnemy.Type = "arena"	
			TeamCacheEnemy.MaxSize = 40
		else
			TeamCacheEnemy.Size = 0		
			TeamCacheEnemy.Type = nil 
			TeamCacheEnemy.MaxSize = 0
		end
				
		if TeamCacheEnemy.Size > 0 and TeamCacheEnemy.Type then    
			counter = 0
			for i = 1, huge do 
				arena = TeamCacheEnemy.Type .. i
				guid  = UnitGUID(arena)
				
				if guid then 
					counter = counter + 1
					
					TeamCacheEnemyUNITs[arena] 				= guid
					TeamCacheEnemyGUIDs[guid] 				= arena					
					TeamCacheEnemyIndexToPLAYERs[i] 		= arena					
					if not TeamCacheEnemy.hasShaman and A_Unit(arena):Class() == "SHAMAN" then 
						TeamCacheEnemy.hasShaman = true 
					end 
						
					arenapet 								= TeamCacheEnemy.Type .. pet .. i
					arenapetguid 							= UnitGUID(arenapet)
					if arenapetguid then 
						TeamCacheEnemyUNITs[arenapet] 		= arenapetguid
						TeamCacheEnemyGUIDs[arenapetguid] 	= arenapet					
						TeamCacheEnemyIndexToPETs[i] 		= arenapet	
					end 
				end 
				
				if counter >= TeamCacheEnemy.Size or i >= TeamCacheEnemy.MaxSize then 
					if counter >= TeamCacheEnemy.Size then 
						TeamCacheEnemy.MaxSize = counter
					end 
					break 
				end 
			end   
		end          
		
		-- Friendly
		TeamCacheFriendly.Size = GetNumGroupMembers()
		if IsInRaid() then
			TeamCacheFriendly.Type = "raid"
			TeamCacheFriendly.MaxSize = 40
		elseif IsInGroup() then
			TeamCacheFriendly.Type = "party"   
			TeamCacheFriendly.MaxSize = 5
		else 
			TeamCacheFriendly.Type = nil 
			TeamCacheFriendly.MaxSize = TeamCacheFriendly.Size
		end    
		
		guid = UnitGUID(player)
		TeamCacheFriendlyUNITs[player] 	= guid
		TeamCacheFriendlyGUIDs[guid] 	= player 		
		if TeamCacheFriendly.Type == "party" then 
			TeamCacheFriendlyIndexToPLAYERs[5] = player
			if A.PlayerClass == "SHAMAN" then 
				TeamCacheFriendly.hasShaman = true 
			end 
		end 
		
		guid = UnitGUID(pet)
		if guid then 
			TeamCacheFriendlyUNITs[pet] 	= guid
			TeamCacheFriendlyGUIDs[guid] 	= pet	
			if TeamCacheFriendly.Type == "party" then 
				TeamCacheFriendlyIndexToPETs[5]	= pet
			end 
		end 				
		
		if TeamCacheFriendly.Size > 0 and TeamCacheFriendly.Type then 
			counter = TeamCacheFriendly.Type == "party" and 1 or 0
			for i = 1, huge do 
				member = TeamCacheFriendly.Type .. i
				guid   = UnitGUID(member)
				
				if guid then 
					counter = counter + 1
					
					TeamCacheFriendlyUNITs[member] 				= guid
					TeamCacheFriendlyGUIDs[guid] 				= member
					TeamCacheFriendlyIndexToPLAYERs[i] 			= member		 					
					if not TeamCacheFriendly.hasShaman and A_Unit(member):Class() == "SHAMAN" and A_Unit(member):InParty() then -- Shaman's totems in Classic works only on party group
						TeamCacheFriendly.hasShaman = true 
					end 
					
					memberpet 									= TeamCacheFriendly.Type .. pet .. i
					memberpetguid 								= UnitGUID(memberpet)
					if memberpetguid then 
						TeamCacheFriendlyUNITs[memberpet] 		= memberpetguid
						TeamCacheFriendlyGUIDs[memberpetguid] 	= memberpet					
						TeamCacheFriendlyIndexToPETs[i] 		= memberpet	
					end 
				end 

				if counter >= TeamCacheFriendly.Size or i >= TeamCacheFriendly.MaxSize then 
					if counter >= TeamCacheFriendly.Size and TeamCacheFriendly.Type ~= "party" then 
						TeamCacheFriendly.MaxSize = counter -- only update non-party max size e.g. to understand raid10, raid15, raid20, raid40
					end 
					break 
				end 	
			end 
		end	

		if event ~= "PLAYER_LOGIN" then
			TMW:Fire("TMW_ACTION_GROUP_UPDATE", event)			-- callback is used in Action UI [8] tab and Combat.lua to refresh and prepare unitGUID for deprecated official API on UnitHealth and UnitHealthMax
		end 	
	end 
	
	if eventInfo == "ENTERING" and event ~= "PLAYER_LOGIN" then
		TMW:Fire("TMW_ACTION_ENTERING", event)					-- callback is used in PetLibrary.lua, HealingEngine.lua, Combat.lua to refresh and prepare unitGUID for deprecated official API on UnitHealth and UnitHealthMax
	end 	
end 

-- Register events 
for event in pairs(GetEventInfo) do 
	Listener:Add("ACTION_EVENT_BASE", event, OnEvent)
end 
