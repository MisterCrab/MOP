local _G, type, pairs, next, math, tonumber, select = 
	  _G, type, pairs, next, math, tonumber, select

local TMW 										= _G.TMW
local A 										= _G.Action
local CONST 									= A.Const
local Listener									= A.Listener
local isEnemy									= A.Bit.isEnemy
local isPlayer									= A.Bit.isPlayer
local isPet										= A.Bit.isPet
local TeamCache									= A.TeamCache
local TeamCacheFriendly							= TeamCache.Friendly
local TeamCacheFriendlyUNITs					= TeamCacheFriendly.UNITs
local TeamCacheFriendlyGUIDs					= TeamCacheFriendly.GUIDs
local TeamCacheFriendlyIndexToPLAYERs			= TeamCacheFriendly.IndexToPLAYERs
local TeamCacheFriendlyIndexToPETs				= TeamCacheFriendly.IndexToPETs
local TeamCacheEnemy							= TeamCache.Enemy
local TeamCacheEnemyUNITs						= TeamCacheEnemy.UNITs
local TeamCacheEnemyGUIDs						= TeamCacheEnemy.GUIDs
local TeamCacheEnemyIndexToPLAYERs				= TeamCacheEnemy.IndexToPLAYERs
--local TeamCacheEnemyIndexToPETs				= TeamCacheEnemy.IndexToPETs
local skipedFirstEnter 							= false

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_GetSpellInfo, A_Player, A_Unit, A_CombatTracker, A_GetCurrentGCD, A_GetGCD, ActiveNameplates

Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then 
		A_GetSpellInfo							= function(...) return A.GetSpellInfo(...) or "" end -- TODO
		A_Player								= A.Player
		A_Unit									= A.Unit
		A_CombatTracker							= A.CombatTracker
		A_GetCurrentGCD							= A.GetCurrentGCD
		A_GetGCD 								= A.GetGCD
		ActiveNameplates						= A.MultiUnits:GetActiveUnitPlates()
		
		Listener:Remove("ACTION_EVENT_COMBAT_TRACKER", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------

-- [[ Classic ]]
local GetToggle									= A.GetToggle
local DRData 									= LibStub("DRList-1.0")
--
	  
local huge 										= math.huge 
local abs 										= math.abs 
local math_max									= math.max
local wipe 										= _G.wipe
local strsub									= _G.strsub

local 	 UnitIsUnit, 	UnitGUID, 	 UnitHealth, 	UnitHealthMax, 	  UnitAffectingCombat, 	  UnitDebuff = 
	  _G.UnitIsUnit, _G.UnitGUID, _G.UnitHealth, _G.UnitHealthMax, _G.UnitAffectingCombat, _G.UnitDebuff	  
	  
local 	 InCombatLockdown, 	  CombatLogGetCurrentEventInfo = 
	  _G.InCombatLockdown, _G.CombatLogGetCurrentEventInfo 

local GetSpellTexture							= TMW.GetSpellTexture
local GetSpellInfo								= function(...) return _G.GetSpellInfo(...) or "" end -- TODO

local  CreateFrame,    UIParent					= 
	_G.CreateFrame, _G.UIParent	 
	
local GameBuild 								= tonumber((select(2, _G.GetBuildInfo())))		
local BuildToC									= A.BuildToC

local function GetGUID(unitID)
	return (unitID and (TeamCacheFriendlyUNITs[unitID] or TeamCacheEnemyUNITs[unitID])) or UnitGUID(unitID)
end 

local function GetGroupMaxSize(group)
	if group == "arena" then 	
		return TeamCacheEnemy.MaxSize
	else
		return TeamCacheFriendly.MaxSize
	end 
end 

-------------------------------------------------------------------------------
-- Locals: CombatTracker
-------------------------------------------------------------------------------
local CombatTracker 							= {
	Data			 						= {}, 
	Doubles 								= {
		[3]  								= "Holy + Physical",
		[5]  								= "Fire + Physical",
		[9]  								= "Nature + Physical",
		[17] 								= "Frost + Physical",
		[33] 								= "Shadow + Physical",
		[65] 								= "Arcane + Physical",
		[127]								= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
	},
	SchoolDoubles							= {
		Holy								= {
			[2]								= "Holy",
			[3]								= "Holy + Physical",
			[6]								= "Fire + Holy",
			[10]							= "Nature + Holy",
			[18]							= "Frost + Holy",
			[34]							= "Shadow + Holy",
			[66]							= "Arcane + Holy",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
		},
		Fire								= {
			[4]								= "Fire",
			[5]								= "Fire + Physical",
			[6]								= "Fire + Holy",
			[12]							= "Nature + Fire",
			[20]							= "Frost + Fire",
			[28]							= "Frost + Nature + Fire",
			[36]							= "Shadow + Fire",
			[68]							= "Arcane + Fire",
			[124]							= "Arcane + Shadow + Frost + Nature + Fire",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",			
		},
		Nature								= {
			[8]								= "Nature",
			[9]								= "Nature + Physical",
			[10]							= "Nature + Holy",
			[12]							= "Nature + Fire",
			[24]							= "Frost + Nature",
			[28]							= "Frost + Nature + Fire",
			[40]							= "Shadow + Nature",
			[72]							= "Arcane + Nature",
			[124]							= "Arcane + Shadow + Frost + Nature + Fire",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
		},
		Frost								= {
			[16]							= "Frost",			
			[17]							= "Frost + Physical",			
			[18]							= "Frost + Holy",			
			[20]							= "Frost + Fire",			
			[24]							= "Frost + Nature",
			[28]							= "Frost + Nature + Fire",			
			[48]							= "Shadow + Frost",			
			[80]							= "Arcane + Frost",									
			[124]							= "Arcane + Shadow + Frost + Nature + Fire",									
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",									
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",									
		},
		Shadow								= {
			[32]							= "Shadow",
			[33]							= "Shadow + Physical",
			[34]							= "Shadow + Holy",
			[36]							= "Shadow + Fire",
			[40]							= "Shadow + Nature",
			[48]							= "Shadow + Frost",
			[96]							= "Arcane + Shadow",
			[124]							= "Arcane + Shadow + Frost + Nature + Fire",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
		},
		Arcane								= {
			[64]							= "Arcane",
			[65]							= "Arcane + Physical",
			[66]							= "Arcane + Holy",
			[68]							= "Arcane + Fire",
			[72]							= "Arcane + Nature",
			[80]							= "Arcane + Frost",
			[96]							= "Arcane + Shadow",
			[124]							= "Arcane + Shadow + Frost + Nature + Fire",
			[126]							= "Arcane + Shadow + Frost + Nature + Fire + Holy",
			[127]							= "Arcane + Shadow + Frost + Nature + Fire + Holy + Physical",
		},
	},
	AddToData 								= function(self, GUID, timestamp)
		if not self.Data[GUID] then
			self.Data[GUID] 				= {
				-- For GC
				lastSeen					= timestamp,
				-- RealTime Damage 
				-- Damage Taken                            
				RealDMG_dmgTaken 			= 0,
				RealDMG_dmgTaken_S 			= 0,
				RealDMG_dmgTaken_P 			= 0,
				RealDMG_dmgTaken_M 			= 0,
				RealDMG_hits_taken 			= 0,                
				-- Damage Done
				RealDMG_dmgDone 			= 0,
				RealDMG_dmgDone_S 			= 0,
				RealDMG_dmgDone_P 			= 0,
				RealDMG_dmgDone_M 			= 0,
				RealDMG_hits_done 			= 0,
				-- Sustain Damage 
				-- Damage Taken
				DMG_dmgTaken 				= 0,
				DMG_dmgTaken_S 				= 0,
				DMG_dmgTaken_P 				= 0,
				DMG_dmgTaken_M 				= 0,
				DMG_hits_taken 				= 0,
				DMG_lastHit_taken 			= 0,
				-- Damage Done
				DMG_dmgDone 				= 0,
				DMG_dmgDone_S 				= 0,
				DMG_dmgDone_P 				= 0,
				DMG_dmgDone_M 				= 0,
				DMG_hits_done 				= 0,
				DMG_lastHit_done 			= 0,
				-- Sustain Healing 
				-- Healing taken
				HPS_heal_taken 				= 0,
				HPS_heal_hits_taken 		= 0,
				HPS_heal_lasttime 			= 0,
				-- Healing Done
				HPS_heal_done 				= 0,
				HPS_heal_hits_done 			= 0,
				HPS_heal_lasttime_done 		= 0,
				-- Shared 
				combat_time 				= timestamp,	
			}
			-- Taken damage by @player through specific schools
			if GUID == GetGUID("player") then 
				self.Data[GUID].School		= {
					DMG_dmgTaken_Holy		= 0,
					DMG_dmgTaken_Holy_LH	= 0,
					DMG_dmgTaken_Fire		= 0,
					DMG_dmgTaken_Fire_LH	= 0,
					DMG_dmgTaken_Nature		= 0,
					DMG_dmgTaken_Nature_LH	= 0,
					DMG_dmgTaken_Frost		= 0,
					DMG_dmgTaken_Frost_LH	= 0,
					DMG_dmgTaken_Shadow		= 0,
					DMG_dmgTaken_Shadow_LH	= 0,
					DMG_dmgTaken_Arcane		= 0,
					DMG_dmgTaken_Arcane_LH	= 0,
				}
			end 
		else 
			self.Data[GUID].lastSeen 		= timestamp 
			if self.Data[GUID].combat_time == 0 then 
				self.Data[GUID].combat_time = timestamp
			end
		end	
	end,
	CleanTableByTime						= function(t, time)
		local key_time = next(t)
		while key_time ~= nil and key_time < time do 
			t[key_time] = nil 
			key_time = next(t, key_time)
		end 
	end,
	SummTableByTime							= function(t, time)
		local total = 0
		local key_time, key_value = next(t)
		while key_time ~= nil do 
			if key_time >= time then 
				total = total + key_value
			end 
			key_time, key_value = next(t, key_time)
		end 
		return total
	end,
}

local CombatTrackerData							= CombatTracker.Data
local CombatTrackerDoubles						= CombatTracker.Doubles
local CombatTrackerSchoolDoubles				= CombatTracker.SchoolDoubles
local CombatTrackerCleanTableByTime				= CombatTracker.CleanTableByTime
local CombatTrackerSummTableByTime				= CombatTracker.SummTableByTime

-- Classic: RealUnitHealth
local RealUnitHealth 							= {
	DamageTaken					= {},	-- log damage and healing taken (includes regen as healing only if can be received by events which provide unitID)
	CachedHealthMax				= {},	-- used to display when unit received damage at pre pared full health 
	CachedHealthMaxTemprorary 	= {},	-- used to display when unit received damage at any health percentage 
	SavedHealthPercent			= {},	-- used for post out 
	isHealthWasMaxOnGUID 		= {},	-- used to determine state from which substract recorded taken damage 
}

local RealUnitHealthDamageTaken					= RealUnitHealth.DamageTaken
local RealUnitHealthCachedHealthMax				= RealUnitHealth.CachedHealthMax
local RealUnitHealthCachedHealthMaxTemprorary	= RealUnitHealth.CachedHealthMaxTemprorary
local RealUnitHealthSavedHealthPercent			= RealUnitHealth.SavedHealthPercent
local RealUnitHealthisHealthWasMaxOnGUID		= RealUnitHealth.isHealthWasMaxOnGUID

local function GameBuildHasRealHealth()
	-- @return boolean 
	return GameBuild >= 33302
end 

local function UnitHasRealHealth(unitID)
	-- @return boolean 
	if not unitID then 
		return true 
	end 
	
	if GameBuildHasRealHealth() then 
		if BuildToC >= 30000 then 
			-- WOTLK+ always returns correctly UnitHealth for everything
			return true 
		end 
		
		if A_Unit(unitID):IsEnemy() then 
			return not A_Unit(unitID):IsPet() and not A_Unit(unitID):IsPlayer()
		else 
			return UnitIsUnit(unitID, "player") or UnitIsUnit(unitID, "pet") or (not A_Unit(unitID):IsPet() and not A_Unit(unitID):IsPlayer()) or TeamCacheFriendlyGUIDs[GetGUID(unitID) or ""]
		end 
	else 
		return UnitIsUnit(unitID, "player") or UnitIsUnit(unitID, "pet") or TeamCacheFriendlyGUIDs[GetGUID(unitID) or ""]
	end 
end 

local function DestHasPercentHealth(destGUID, destFlags)
	-- @return boolean 
	return not TeamCacheFriendlyGUIDs[destGUID] --and (not GameBuildHasRealHealth() or TeamCacheEnemyGUIDs[destGUID] or isPlayer(destFlags) or isPet(destFlags))
end 

local function logDefaultGUIDatMaxHealth()
	if TeamCacheFriendly.Size > 0 and TeamCacheFriendly.Type then 
		for i = 1, TeamCacheFriendly.MaxSize do		
			local unitID = TeamCacheFriendlyIndexToPLAYERs[i]
			local unitPetID = TeamCacheFriendlyIndexToPETs[i]
			-- unit API provided health if unit in any group 
			--CombatTracker.logHealthMax(unitID)
			--CombatTracker.logHealthMax(unitPetID)	
			-- unittarget
			if unitID then 
				CombatTracker.logHealthMax(unitID .. "target")
				if unitPetID then 
					CombatTracker.logHealthMax(unitPetID .. "target")
				end 
			end 
		end
	end	
end 

local function logDefaultGUIDatMaxHealthTarget()
	CombatTracker.logHealthMax("target")
	CombatTracker.logHealthMax("targettarget")
end 

local function logDefaultGUIDatMaxHealthMouseover()
	CombatTracker.logHealthMax("mouseover")
	CombatTracker.logHealthMax("mouseovertarget")
end 

--[[ This Logs the UnitHealthMax (Real) ]]
CombatTracker.logHealthMax						= function(...)
	local unitID 	= ...
	if UnitHasRealHealth(unitID) then 
		return 
	end 
	
	local GUID 		= GetGUID(unitID)
	if not GUID then 
		return 
	end 
	
	local curr_hp, max_hp = UnitHealth(unitID), UnitHealthMax(unitID)
	if curr_hp <= 0 then 
		return 
	end 		
	
	if curr_hp == max_hp then 			
		-- Reset summary damage log to accurate calculate real health 
		RealUnitHealthDamageTaken[GUID] = 0 	
		RealUnitHealthCachedHealthMax[GUID] = nil 
		RealUnitHealthSavedHealthPercent[GUID]	= curr_hp 
		RealUnitHealthisHealthWasMaxOnGUID[GUID] = true 
		--print(UnitName(unitID), "MAX HEALTH!")		
	elseif not RealUnitHealthCachedHealthMax[GUID] and CombatTrackerData[GUID] then  	
		-- Always reset damage taken and remember percent out of combat 
		if RealUnitHealthDamageTaken[GUID] ~= 0 and not UnitAffectingCombat(unitID) then 
			RealUnitHealthDamageTaken[GUID] = 0  
			RealUnitHealthSavedHealthPercent[GUID] = curr_hp 
			--print(UnitName(unitID), "Out of combat, DamageTaken: ", RealUnitHealthDamageTaken[GUID])
			return 
		end 
		
		-- Always update percent because out of combat unit gaining health
		if RealUnitHealthDamageTaken[GUID] == 0 then 
			if (not RealUnitHealthSavedHealthPercent[GUID] or curr_hp > RealUnitHealthSavedHealthPercent[GUID]) and not UnitAffectingCombat(unitID) then 
				--print(UnitName(unitID), "Out of combat, SavedPercent: ", curr_hp, "from", RealUnitHealthSavedHealthPercent[GUID] or "nil")
				RealUnitHealthSavedHealthPercent[GUID] = curr_hp 		
			end 
		else 			
			if RealUnitHealthisHealthWasMaxOnGUID[GUID] then 
				if max_hp - curr_hp == 0 then 
					RealUnitHealthCachedHealthMax[GUID] = 0
				else 
					RealUnitHealthCachedHealthMax[GUID] = RealUnitHealthDamageTaken[GUID] * max_hp / (max_hp - curr_hp)
				end 
				RealUnitHealthCachedHealthMaxTemprorary[GUID] = RealUnitHealthCachedHealthMax[GUID]		
				--print(UnitName(unitID), "In combat, MaxHP PRE:", RealUnitHealthCachedHealthMax[GUID]) 
			else 
				if not RealUnitHealthSavedHealthPercent[GUID] then 
					RealUnitHealthDamageTaken[GUID] = 0
					RealUnitHealthSavedHealthPercent[GUID] = curr_hp
					--print(UnitName(unitID), "In combat, SavedPercent (wasn't existed before):", RealUnitHealthSavedHealthPercent[GUID])
					--print(UnitName(unitID), "In combat, DamageTaken: ", RealUnitHealthDamageTaken[GUID])
				elseif RealUnitHealthSavedHealthPercent[GUID] > curr_hp and not RealUnitHealthCachedHealthMaxTemprorary[GUID] then   
					if RealUnitHealthSavedHealthPercent[GUID] - curr_hp == 0 then 
						RealUnitHealthCachedHealthMaxTemprorary[GUID] = 0 
					else
						RealUnitHealthCachedHealthMaxTemprorary[GUID] = RealUnitHealthDamageTaken[GUID] * RealUnitHealthSavedHealthPercent[GUID] / (RealUnitHealthSavedHealthPercent[GUID] - curr_hp)
					end
					RealUnitHealthCachedHealthMax[GUID] = RealUnitHealthCachedHealthMaxTemprorary[GUID]
					--print(UnitName(unitID), "In combat, MaxHP POST POST (percent of health has been decreased):", RealUnitHealthCachedHealthMaxTemprorary[GUID])
				end 
			end 
		end 
	end 	
end 

--[[ ENVIRONMENTAL ]] 
CombatTracker.logEnvironmentalDamage			= function(...)
	local timestamp,_,_, SourceGUID,_,_,_, DestGUID,_, destFlags,_,_, Amount = ... -- CombatLogGetCurrentEventInfo()
	-- Classic: RealUnitHealth log taken
	if DestHasPercentHealth(DestGUID, destFlags) then 
		RealUnitHealthDamageTaken[DestGUID] = (RealUnitHealthDamageTaken[DestGUID] or 0) + Amount
	end 
	
	-- Update last hit time
	-- Taken 
	CombatTrackerData[DestGUID].DMG_lastHit_taken = timestamp
	
	-- Totals
	-- Taken 
	CombatTrackerData[DestGUID].DMG_dmgTaken = CombatTrackerData[DestGUID].DMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].DMG_hits_taken = CombatTrackerData[DestGUID].DMG_hits_taken + 1
	
	-- Real Time Damage 
	-- Taken
	CombatTrackerData[DestGUID].RealDMG_dmgTaken = CombatTrackerData[DestGUID].RealDMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].RealDMG_hits_taken = CombatTrackerData[DestGUID].RealDMG_hits_taken + 1 
	
	-- Only Taken by Player
	if isPlayer(destFlags) then
		-- DS 
		if not CombatTrackerData[DestGUID].DS then 
			CombatTrackerData[DestGUID].DS = {}
		end 
		CombatTrackerData[DestGUID].DS[timestamp] = (CombatTrackerData[DestGUID].DS[timestamp] or 0) + Amount
		-- DS - Garbage 
		CombatTrackerCleanTableByTime(CombatTrackerData[DestGUID].DS, timestamp - 10)
	end 
end 

--[[ This Logs the damage for every unit ]]
CombatTracker.logDamage 						= function(...) 
	local timestamp,_,_, SourceGUID,_,_,_, DestGUID,_, destFlags,_,_, spellName, school, Amount = ... -- CombatLogGetCurrentEventInfo()	
	-- Reset and clear 
	-- Damage Done 
	if timestamp - CombatTrackerData[SourceGUID].DMG_lastHit_done > 5 then 
		CombatTrackerData[SourceGUID].DMG_dmgDone = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_S = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_P = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_M = 0
		CombatTrackerData[SourceGUID].DMG_hits_done = 0	
	end 
	
	-- Damage Taken 
	if timestamp - CombatTrackerData[DestGUID].DMG_lastHit_taken > 5 then 
		CombatTrackerData[DestGUID].DMG_dmgTaken = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_S = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_P = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_M = 0
		CombatTrackerData[DestGUID].DMG_hits_taken = 0	
	end 
	
	-- Real Time Damage Done
	if timestamp - CombatTrackerData[SourceGUID].DMG_lastHit_done > A_GetGCD() * 2 + 1 then 
		CombatTrackerData[SourceGUID].RealDMG_dmgDone = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_S = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_P = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_M = 0
		CombatTrackerData[SourceGUID].RealDMG_hits_done = 0		
	end 
	
	-- Real Time Damage Taken
	if timestamp - CombatTrackerData[DestGUID].DMG_lastHit_taken > A_GetGCD() * 2 + 1 then 
		CombatTrackerData[DestGUID].RealDMG_dmgTaken = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_S = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_P = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_M = 0
		CombatTrackerData[DestGUID].RealDMG_hits_taken = 0 
	end 
	
	-- School Damage Taken by @player 
	if CombatTrackerData[DestGUID].School then 
		-- Reset and clear 
		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy_LH 	= 0 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy		= 0
		end 
		
		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire_LH 	= 0 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire		= 0
		end 
		
		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature_LH 	= 0 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature		= 0
		end 
		
		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost_LH 	= 0 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost		= 0
		end 
		
		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow_LH 	= 0 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow		= 0
		end 
		
		if timestamp - CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane_LH > 5 then
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane_LH 	= 0 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane		= 0
		end 
		
		-- Add and log 
		if CombatTrackerSchoolDoubles.Holy[school] then 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy_LH 	= timestamp 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Holy + Amount
		end		

		if CombatTrackerSchoolDoubles.Fire[school] then 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire_LH 	= timestamp 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Fire + Amount
		end		
		
		if CombatTrackerSchoolDoubles.Nature[school] then 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature_LH 	= timestamp 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Nature + Amount
		end	
		
		if CombatTrackerSchoolDoubles.Frost[school] then 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost_LH 	= timestamp 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Frost + Amount
		end	
		
		if CombatTrackerSchoolDoubles.Shadow[school] then 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow_LH 	= timestamp 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Shadow + Amount
		end	
		
		if CombatTrackerSchoolDoubles.Arcane[school] then 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane_LH 	= timestamp 
			CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane		= CombatTrackerData[DestGUID].School.DMG_dmgTaken_Arcane + Amount
		end	
	end 
	
	-- Classic: RealUnitHealth log taken only for out of group 
	if DestHasPercentHealth(DestGUID, destFlags) then 
		RealUnitHealthDamageTaken[DestGUID] = (RealUnitHealthDamageTaken[DestGUID] or 0) + Amount	
	end 
	
	-- Filter by School   
	if CombatTrackerDoubles[school] then
		-- Taken 
		CombatTrackerData[DestGUID].DMG_dmgTaken_P = CombatTrackerData[DestGUID].DMG_dmgTaken_P + Amount
		CombatTrackerData[DestGUID].DMG_dmgTaken_M = CombatTrackerData[DestGUID].DMG_dmgTaken_M + Amount
		-- Done 
		CombatTrackerData[SourceGUID].DMG_dmgDone_P = CombatTrackerData[SourceGUID].DMG_dmgDone_P + Amount
		CombatTrackerData[SourceGUID].DMG_dmgDone_M = CombatTrackerData[SourceGUID].DMG_dmgDone_M + Amount
		-- Real Time Damage - Taken 
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_P = CombatTrackerData[DestGUID].RealDMG_dmgTaken_P + Amount
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_M = CombatTrackerData[DestGUID].RealDMG_dmgTaken_M + Amount
		-- Real Time Damage - Done
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_P = CombatTrackerData[SourceGUID].RealDMG_dmgDone_P + Amount
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_M = CombatTrackerData[SourceGUID].RealDMG_dmgDone_M + Amount       
	elseif school == 1 then
		-- Pysichal
		-- Taken 
		CombatTrackerData[DestGUID].DMG_dmgTaken_P = CombatTrackerData[DestGUID].DMG_dmgTaken_P + Amount
		-- Done 
		CombatTrackerData[SourceGUID].DMG_dmgDone_P = CombatTrackerData[SourceGUID].DMG_dmgDone_P + Amount
		-- Real Time Damage - Taken 
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_P = CombatTrackerData[DestGUID].RealDMG_dmgTaken_P + Amount    
		-- Real Time Damage - Done		
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_P = CombatTrackerData[SourceGUID].RealDMG_dmgDone_P + Amount       
	else
		-- Magic
		-- Taken
		CombatTrackerData[DestGUID].DMG_dmgTaken_M = CombatTrackerData[DestGUID].DMG_dmgTaken_M + Amount
		-- Done 
		CombatTrackerData[SourceGUID].DMG_dmgDone_M = CombatTrackerData[SourceGUID].DMG_dmgDone_M + Amount
		-- Real Time Damage - Taken       
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_M = CombatTrackerData[DestGUID].RealDMG_dmgTaken_M + Amount   
		-- Real Time Damage - Done		
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_M = CombatTrackerData[SourceGUID].RealDMG_dmgDone_M + Amount				
	end
	
	-- Update last hit time
	-- Taken 
	CombatTrackerData[DestGUID].DMG_lastHit_taken = timestamp
	-- Done 
	CombatTrackerData[SourceGUID].DMG_lastHit_done = timestamp
	
	-- Totals
	-- Taken 
	CombatTrackerData[DestGUID].DMG_dmgTaken = CombatTrackerData[DestGUID].DMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].DMG_hits_taken = CombatTrackerData[DestGUID].DMG_hits_taken + 1   
	-- Done 
	CombatTrackerData[SourceGUID].DMG_hits_done = CombatTrackerData[SourceGUID].DMG_hits_done + 1
	CombatTrackerData[SourceGUID].DMG_dmgDone = CombatTrackerData[SourceGUID].DMG_dmgDone + Amount
	
	-- Real Time Damage 
	-- Taken	
	CombatTrackerData[DestGUID].RealDMG_dmgTaken = CombatTrackerData[DestGUID].RealDMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].RealDMG_hits_taken = CombatTrackerData[DestGUID].RealDMG_hits_taken + 1    
	-- Done 	
	CombatTrackerData[SourceGUID].RealDMG_dmgDone = CombatTrackerData[SourceGUID].RealDMG_dmgDone + Amount
	CombatTrackerData[SourceGUID].RealDMG_hits_done = CombatTrackerData[SourceGUID].RealDMG_hits_done + 1 

	-- Only Taken by Player
	if isPlayer(destFlags) then
		-- Spells 
		if not CombatTrackerData[DestGUID].spell_value then 
			CombatTrackerData[DestGUID].spell_value = {}
		end 
		
		if not CombatTrackerData[DestGUID].spell_value[spellName] then 
			CombatTrackerData[DestGUID].spell_value[spellName] = {}
		end 
		CombatTrackerData[DestGUID].spell_value[spellName].TIME 		= timestamp
		CombatTrackerData[DestGUID].spell_value[spellName].Amount		= Amount

		-- DS 
		if not CombatTrackerData[DestGUID].DS then 
			CombatTrackerData[DestGUID].DS = {}
		end 
		CombatTrackerData[DestGUID].DS[timestamp] = (CombatTrackerData[DestGUID].DS[timestamp] or 0) + Amount
		-- DS - Garbage 
		CombatTrackerCleanTableByTime(CombatTrackerData[DestGUID].DS, timestamp - 10)
	end 
end

--[[ This Logs the swings (damage) for every unit ]]
CombatTracker.logSwing 							= function(...) 
	local timestamp,_,_, SourceGUID,_,_,_, DestGUID,_, destFlags,_, Amount = ... -- CombatLogGetCurrentEventInfo()
	-- Reset and clear 
	-- Damage Done 
	if timestamp - CombatTrackerData[SourceGUID].DMG_lastHit_done > 5 then 
		CombatTrackerData[SourceGUID].DMG_dmgDone = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_S = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_P = 0
		CombatTrackerData[SourceGUID].DMG_dmgDone_M = 0
		CombatTrackerData[SourceGUID].DMG_hits_done = 0	
	end 
	
	-- Damage Taken 
	if timestamp - CombatTrackerData[DestGUID].DMG_lastHit_taken > 5 then 
		CombatTrackerData[DestGUID].DMG_dmgTaken = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_S = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_P = 0
		CombatTrackerData[DestGUID].DMG_dmgTaken_M = 0
		CombatTrackerData[DestGUID].DMG_hits_taken = 0	
	end 
	
	-- Real Time Damage Done
	if timestamp - CombatTrackerData[SourceGUID].DMG_lastHit_done > A_GetGCD() * 2 + 1 then 
		CombatTrackerData[SourceGUID].RealDMG_dmgDone = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_S = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_P = 0
		CombatTrackerData[SourceGUID].RealDMG_dmgDone_M = 0
		CombatTrackerData[SourceGUID].RealDMG_hits_done = 0		
	end 
	
	-- Real Time Damage Taken
	if timestamp - CombatTrackerData[DestGUID].DMG_lastHit_taken > A_GetGCD() * 2 + 1 then 
		CombatTrackerData[DestGUID].RealDMG_dmgTaken = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_S = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_P = 0
		CombatTrackerData[DestGUID].RealDMG_dmgTaken_M = 0
		CombatTrackerData[DestGUID].RealDMG_hits_taken = 0 
	end 
	
	-- Update last  hit time
	CombatTrackerData[DestGUID].DMG_lastHit_taken = timestamp
	CombatTrackerData[SourceGUID].DMG_lastHit_done = timestamp
	
	-- Classic: RealUnitHealth log taken only for out of group 
	if DestHasPercentHealth(DestGUID, destFlags) then 
		RealUnitHealthDamageTaken[DestGUID] = (RealUnitHealthDamageTaken[DestGUID] or 0) + Amount	
	end 
	
	-- Damage 
	CombatTrackerData[DestGUID].DMG_dmgTaken_P = CombatTrackerData[DestGUID].DMG_dmgTaken_P + Amount
	CombatTrackerData[DestGUID].DMG_dmgTaken = CombatTrackerData[DestGUID].DMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].DMG_hits_taken = CombatTrackerData[DestGUID].DMG_hits_taken + 1
	CombatTrackerData[SourceGUID].DMG_dmgDone_P = CombatTrackerData[SourceGUID].DMG_dmgDone_P + Amount
	CombatTrackerData[SourceGUID].DMG_dmgDone = CombatTrackerData[SourceGUID].DMG_dmgDone + Amount
	CombatTrackerData[SourceGUID].DMG_hits_done = CombatTrackerData[SourceGUID].DMG_hits_done + 1
	
	-- Real Time Damage 
	-- Taken
	CombatTrackerData[DestGUID].RealDMG_dmgTaken_S = CombatTrackerData[DestGUID].RealDMG_dmgTaken_S + Amount
	CombatTrackerData[DestGUID].RealDMG_dmgTaken_P = CombatTrackerData[DestGUID].RealDMG_dmgTaken_P + Amount
	CombatTrackerData[DestGUID].RealDMG_dmgTaken = CombatTrackerData[DestGUID].RealDMG_dmgTaken + Amount
	CombatTrackerData[DestGUID].RealDMG_hits_taken = CombatTrackerData[DestGUID].RealDMG_hits_taken + 1  
	-- Done    
	CombatTrackerData[SourceGUID].RealDMG_dmgDone_S = CombatTrackerData[SourceGUID].RealDMG_dmgDone_S + Amount
	CombatTrackerData[SourceGUID].RealDMG_dmgDone_P = CombatTrackerData[SourceGUID].RealDMG_dmgDone_P + Amount   
	CombatTrackerData[SourceGUID].RealDMG_dmgDone = CombatTrackerData[SourceGUID].RealDMG_dmgDone + Amount
	CombatTrackerData[SourceGUID].RealDMG_hits_done = CombatTrackerData[SourceGUID].RealDMG_hits_done + 1 
	
	-- Only Taken by Player
	if isPlayer(destFlags) then 
		-- DS 
		if not CombatTrackerData[DestGUID].DS then 
			CombatTrackerData[DestGUID].DS = {}
		end 
		CombatTrackerData[DestGUID].DS[timestamp] = (CombatTrackerData[DestGUID].DS[timestamp] or 0) + Amount
		-- DS - Garbage 
		CombatTrackerCleanTableByTime(CombatTrackerData[DestGUID].DS, timestamp - 10)
	end 
end

--[[ This Logs the healing for every unit ]]
CombatTracker.logHealing			 			= function(...) 
	local timestamp,_,_, SourceGUID,_,_,_, DestGUID,_, destFlags,_,_, spellName,_, Amount = ... -- CombatLogGetCurrentEventInfo()
	-- Reset 
	-- Taken 
	if timestamp - CombatTrackerData[DestGUID].HPS_heal_lasttime > 5 then
		CombatTrackerData[DestGUID].HPS_heal_taken = 0
		CombatTrackerData[DestGUID].HPS_heal_hits_taken = 0
	end 
	
	-- Done 
	if timestamp - CombatTrackerData[SourceGUID].HPS_heal_lasttime_done > 5 then   
		CombatTrackerData[SourceGUID].HPS_heal_done = 0
		CombatTrackerData[SourceGUID].HPS_heal_hits_done = 0
	end 
	
	-- Update last  hit time
	-- Taken 
	CombatTrackerData[DestGUID].HPS_heal_lasttime = timestamp
	-- Done 
	CombatTrackerData[SourceGUID].HPS_heal_lasttime_done = timestamp
	
	-- Classic: RealUnitHealth log taken only for out of group 
	if DestHasPercentHealth(DestGUID, destFlags) then 
		local compare = (RealUnitHealthDamageTaken[DestGUID] or 0) - Amount
		if compare <= 0 then 
			RealUnitHealthDamageTaken[DestGUID] = 0
		else 
			RealUnitHealthDamageTaken[DestGUID] = compare
		end 	
	end 
	
	-- Totals    
	-- Taken 
	CombatTrackerData[DestGUID].HPS_heal_taken = CombatTrackerData[DestGUID].HPS_heal_taken + Amount
	CombatTrackerData[DestGUID].HPS_heal_hits_taken = CombatTrackerData[DestGUID].HPS_heal_hits_taken + 1
	-- Done   
	CombatTrackerData[SourceGUID].HPS_heal_done = CombatTrackerData[SourceGUID].HPS_heal_done + Amount
	CombatTrackerData[SourceGUID].HPS_heal_hits_done = CombatTrackerData[SourceGUID].HPS_heal_hits_done + 1   
	
	-- Only Taken by Player	
	if isPlayer(destFlags) then 
		-- Spells
		if not CombatTrackerData[DestGUID].spell_value then 
			CombatTrackerData[DestGUID].spell_value = {}
		end 
		
		if not CombatTrackerData[DestGUID].spell_value[spellName] then 
			CombatTrackerData[DestGUID].spell_value[spellName] = {}
		end 
		CombatTrackerData[DestGUID].spell_value[spellName].Amount 	= Amount
		CombatTrackerData[DestGUID].spell_value[spellName].TIME 	= timestamp		 
	end 
end

--[[ This Logs the shields for every player or controlled by player unit ]]
CombatTracker.logAbsorb 						= function(...) 
	local _,_,_, SourceGUID,_,_,_, DestGUID,_, destFlags,_,_, spellName, _, auraType, Amount = ... -- CombatLogGetCurrentEventInfo()    
	if auraType == "BUFF" and Amount and spellName and isPlayer(destFlags) then
		if not CombatTrackerData[DestGUID].absorb_spells then 
			CombatTrackerData[DestGUID].absorb_spells = {}
		end 
		
		CombatTrackerData[DestGUID].absorb_spells[spellName] 	= (CombatTrackerData[DestGUID].absorb_spells[spellName] or 0) + Amount      
		CombatTrackerData[DestGUID].absorb_total				= (CombatTrackerData[DestGUID].absorb_total or 0) + Amount
	end    
end

--[[ Old
CombatTracker.logUpdateAbsorb 					= function(...) 
	local _,_,_, SourceGUID, _,_,_, DestGUID, _, destFlags,_,_, spellName, _, Amount = ... -- CombatLogGetCurrentEventInfo()  -- Classic: Amount sometimes return string ??
	if spellName and type(Amount) == "number" and isPlayer(destFlags) then 
		if not CombatTrackerData[DestGUID].absorb_spells then 
			CombatTrackerData[DestGUID].absorb_spells = {}
		end 
		
		local calc = (CombatTrackerData[DestGUID].absorb_spells[spellName] or 0) - Amount
		if calc <= 0 then 
			CombatTrackerData[DestGUID].absorb_spells[spellName] 	= 0
		else 	
			CombatTrackerData[DestGUID].absorb_spells[spellName] 	= calc   
		end 

		calc = (CombatTrackerData[DestGUID].absorb_total or 0) - Amount
		if calc <= 0 then 
			CombatTrackerData[DestGUID].absorb_total				= 0
		else 
			CombatTrackerData[DestGUID].absorb_total				= calc
		end 
	end 
end]]

CombatTracker.update_logAbsorb					= function(...)
	local timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, srcSpellId, srcSpellName, srcSpellSchool, casterGUID, casterName, casterFlags, casterRaidFlags, spellId, spellName, spellSchool, absorbed
	if type(srcSpellId) == "number" then 
		-- Spell
        timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, srcSpellId, srcSpellName, srcSpellSchool, casterGUID, casterName, casterFlags, casterRaidFlags, spellId, spellName, spellSchool, absorbed = ... -- CombatLogGetCurrentEventInfo()	
	else 
		-- Melee/Ranged
        timestamp, eventtype, srcGUID, srcName, srcFlags, dstGUID, dstName, dstFlags, casterGUID, casterName, casterFlags, casterRaidFlags, spellId, spellName, spellSchool, absorbed = ... -- CombatLogGetCurrentEventInfo()
	end 

	-- 'src' params is who caused absorb change 
	-- 'dts' params is who got changed absorb 
	-- 'caster' params is who and what applied 
	-- 'absorbed' param is amount of absorb change 
	if type(absorbed) == "number" and type(dstGUID) == "string" and spellName and CombatTrackerData[dstGUID].absorb_spells and CombatTrackerData[dstGUID].absorb_spells[spellName] then 		
		local compare = (CombatTrackerData[dstGUID].absorb_spells[spellName] or 0) - absorbed 
		if compare <= 0 then 
			CombatTrackerData[dstGUID].absorb_spells[spellName] = 0
		else 	
			CombatTrackerData[dstGUID].absorb_spells[spellName] = compare   
		end 		
		
		compare = (CombatTrackerData[dstGUID].absorb_total or 0) - absorbed
		if compare <= 0 then 
			CombatTrackerData[dstGUID].absorb_total = 0
		else 
			CombatTrackerData[dstGUID].absorb_total = compare
		end 		
	end 
end 

CombatTracker.remove_logAbsorb 					= function(...) 
	local _,_,_,_,_,_,_, DestGUID,_,_,_,_, spellName,_, spellType,_, amountMissed = ... -- CombatLogGetCurrentEventInfo()
	if (spellType == "BUFF" or spellType == "ABSORB") and spellName and CombatTrackerData[DestGUID].absorb_spells and CombatTrackerData[DestGUID].absorb_spells[spellName] then 
		local compare = (CombatTrackerData[DestGUID].absorb_total or 0) - ((spellType == "BUFF" and CombatTrackerData[DestGUID].absorb_spells[spellName]) or (spellType == "ABSORB" and amountMissed))
		if compare <= 0 then 
			CombatTrackerData[DestGUID].absorb_total				= 0
		else 
			CombatTrackerData[DestGUID].absorb_total				= compare
		end 
		
		if spellType == "BUFF" then 
			CombatTrackerData[DestGUID].absorb_spells[spellName] 	= nil
		else 
			compare = CombatTrackerData[DestGUID].absorb_spells[spellName] - amountMissed
			if compare <= 0 then 
				CombatTrackerData[DestGUID].absorb_spells[spellName] = nil
			else
				CombatTrackerData[DestGUID].absorb_spells[spellName] = compare
			end 
		end 
	end       	
end

--[[ This Logs the last cast and amount for every unit ]]
-- Note: Only @player self and in PvP any players 
CombatTracker.logLastCast 						= function(...) 
	local timestamp,_,_, SourceGUID,_, sourceFlags,_, _,_,_,_,_, spellName = ... -- CombatLogGetCurrentEventInfo()
	if (A.IsInPvP and sourceFlags and isPlayer(sourceFlags)) or SourceGUID == GetGUID("player") then -- Classic doesn't require Hunter data collect 
		-- LastCast time
		if not CombatTrackerData[SourceGUID].spell_lastcast_time then 
			CombatTrackerData[SourceGUID].spell_lastcast_time = {}
		end 
		CombatTrackerData[SourceGUID].spell_lastcast_time[spellName]	= timestamp 
		
		-- Counter 
		if not CombatTrackerData[SourceGUID].spell_counter then 
			CombatTrackerData[SourceGUID].spell_counter = {}
		end 
		CombatTrackerData[SourceGUID].spell_counter[spellName] 			= (CombatTrackerData[SourceGUID].spell_counter[spellName] or 0) + 1
	end 
end 

--[[ This Logs the reset on death for every unit ]]
CombatTracker.logDied							= function(...)
	local _,_,_,_,_,_,_, DestGUID,_, destFlags = ... -- CombatLogGetCurrentEventInfo()
	CombatTrackerData[DestGUID] 							= nil
	RealUnitHealthDamageTaken[DestGUID]						= nil 
	RealUnitHealthCachedHealthMax[DestGUID] 				= nil
	RealUnitHealthisHealthWasMaxOnGUID[DestGUID] 			= nil
	RealUnitHealthSavedHealthPercent[DestGUID] 				= nil 
	if not isPlayer(destFlags) then 
		RealUnitHealthCachedHealthMaxTemprorary[DestGUID] 	= nil 
	end 
end	

--[[ This Logs the DR (Diminishing Returns) for enemy unit PvE dr or player ]]
CombatTracker.logDR								= function(timestamp, EVENT, DestGUID, destFlags, spellID)
	if isEnemy(destFlags) then 
		local drCat = DRData:GetCategoryBySpellID(spellID)
		if drCat and (DRData:IsPvECategory(drCat) or isPlayer(destFlags)) then
			local CombatTrackerDataGUID = CombatTrackerData[DestGUID]
			if not CombatTrackerDataGUID.DR then 
				CombatTrackerDataGUID.DR = {}
			end 
			
			-- All addons included DR library sample have wrong code to perform CLEU 
			-- The main their fail is what DR should be starts AS SOON AS AURA IS APPLIED (not after expire)
			-- They do their approach because "SPELL_AURA_REFRESH" can catch "fake" refreshes caused by spells that break after a certain amount of damage
			-- But we will avoid such situation by "SPELL_AURA_BROKEN" and "SPELL_AURA_BROKEN_SPELL" through skip next "SPELL_AURA_REFRESH" which can be fired within the next 1.3 seconds 
			local dr = CombatTrackerDataGUID.DR[drCat]
			
			-- DR skips next "fake" event "SPELL_AURA_REFRESH" if aura broken by damage 
			if EVENT == "SPELL_AURA_BROKEN" or EVENT == "SPELL_AURA_BROKEN_SPELL" then 
				if dr then 
					dr.brokenTime 					= timestamp + 1.3 -- Adds 1.3 seconds, so if in the next 1.3 seconds fired "SPELL_AURA_REFRESH" that will be skipped. 0.3 is recommended latency
				end 
				return 
			end 
			
			-- DR always starts by "SPELL_AURA_APPLIED" or if its already applied then by "SPELL_AURA_REFRESH"
			if EVENT == "SPELL_AURA_APPLIED" or (EVENT == "SPELL_AURA_REFRESH" and timestamp > (dr and dr.brokenTime or 0)) then 
				-- Remove DR if its expired 
				if dr and dr.reset < timestamp then						
					dr.diminished 					= 100
					dr.application 					= 0
					dr.reset 						= 0
					dr.brokenTime					= 0
				end		
				
				-- Add DR
				if not dr then
					-- If there isn't already a table, make one
					-- Start it at 1th application because the unit just got diminished
					CombatTrackerDataGUID.DR[drCat] = {					
						application 				= 1,
						applicationMax 				= DRData:GetApplicationMax(drCat),
						diminished 					= DRData:GetNextDR(1, drCat) * 100,
						reset				 		= timestamp + DRData:GetResetTime(drCat),	
						brokenTime					= 0,
					}
				else
					-- Diminish the unit by one tick
					-- Ticks go 100% -> 0%			
					if dr.diminished and dr.diminished ~= 0 then
						dr.application 				= dr.application + 1												
						dr.diminished 				= DRData:GetNextDR(dr.application, drCat) * 100
						dr.reset 					= timestamp + DRData:GetResetTime(drCat)
						dr.brokenTime				= 0
					end
				end	
			end 		
		end 
	end 
end 

--[[ These are the events we're looking for and its respective action ]]
CombatTracker.OnEventCLEU 						= {
	["SPELL_DAMAGE"] 						= CombatTracker.logDamage,
	["DAMAGE_SHIELD"] 						= CombatTracker.logDamage,
	["DAMAGE_SPLIT"]						= CombatTracker.logDamage,
	["SPELL_PERIODIC_DAMAGE"] 				= CombatTracker.logDamage,
	["SPELL_BUILDING_DAMAGE"] 				= CombatTracker.logDamage,
	["RANGE_DAMAGE"] 						= CombatTracker.logDamage,
	["SWING_DAMAGE"] 						= CombatTracker.logSwing,
	["ENVIRONMENTAL_DAMAGE"]				= CombatTracker.logEnvironmentalDamage,
	["SPELL_HEAL"] 							= CombatTracker.logHealing,
	["SPELL_PERIODIC_HEAL"] 				= CombatTracker.logHealing,
	["SPELL_AURA_APPLIED"] 					= CombatTracker.logAbsorb,   
	["SPELL_AURA_REFRESH"] 					= CombatTracker.logAbsorb, 
	["SPELL_ABSORBED"] 						= CombatTracker.update_logAbsorb, 
	["SPELL_AURA_REMOVED"] 					= CombatTracker.remove_logAbsorb,  
	["SPELL_MISSED"] 						= CombatTracker.remove_logAbsorb,  
	["SPELL_CAST_SUCCESS"] 					= CombatTracker.logLastCast,
	["UNIT_DIED"] 							= CombatTracker.logDied,
	["UNIT_DESTROYED"]						= CombatTracker.logDied,
	["UNIT_DISSIPATES"]						= CombatTracker.logDied,
	["PARTY_KILL"] 							= CombatTracker.logDied,
	["SPELL_INSTAKILL"] 					= CombatTracker.logDied,
}

CombatTracker.OnEventDR							= {
	["SPELL_AURA_BROKEN"]					= CombatTracker.logDR,
	["SPELL_AURA_BROKEN_SPELL"]				= CombatTracker.logDR,
	["SPELL_AURA_APPLIED"]					= CombatTracker.logDR,
	["SPELL_AURA_REFRESH"]					= CombatTracker.logDR,
}				

local CombatTrackerOnEventCLEU					= CombatTracker.OnEventCLEU
local CombatTrackerOnEventDR					= CombatTracker.OnEventDR

-------------------------------------------------------------------------------
-- Locals: UnitTracker
-------------------------------------------------------------------------------
local UnitTracker 								= {
	Data 								= {},
	isRegistered 						= {
		[GetSpellInfo(CONST.SPELLID_FREEZING_TRAP)] = true,
	},
	isBlink								= {
		[GetSpellInfo(1953)] = true, 
		[1953] 				 = true, 
	},
	isNotResetFlyingEvent				= {
		["SUCCESS"] = true,
		["T_START"] = true,
		["_FAILED"] = true,		
		["_CREATE"] = true,	
		["_SUMMON"]	= true,
	},
	maxResetFlyingTimer					= 10, -- Classic must be 10 to be safe for delayed casts
	-- OnEvent 
	UNIT_SPELLCAST_SUCCEEDED			= function(self, SourceGUID, sourceFlags, spellName)
		if self.isRegistered[spellName] and SourceGUID ~= GetGUID("player") and (not self.isRegistered[spellName].inPvP or A.IsInPvP) and (not self.isRegistered[spellName].isFriendly or not isEnemy(sourceFlags)) then		
			if not self.Data[SourceGUID] then 
				self.Data[SourceGUID] = {}
			end 
			
			if not self.Data[SourceGUID][spellName] then 
				self.Data[SourceGUID][spellName] = {}
			end 
			
			self.Data[SourceGUID][spellName].start 			= TMW.time 
			self.Data[SourceGUID][spellName].expire 		= TMW.time + self.isRegistered[spellName].Timer 
			self.Data[SourceGUID][spellName].isFlying 		= true 
			self.Data[SourceGUID][spellName].blackListCLEU 	= self.isRegistered[spellName].blackListCLEU	
			self.Data[SourceGUID][spellName].enemy 			= isEnemy(sourceFlags) 	
		end
	end,
	UNIT_SPELLCAST_SUCCEEDED_PLAYER		= function(self, unitID, spellID)
		if unitID == "player" then 
			local GUID 		= GetGUID(unitID)
			local spellName = A_GetSpellInfo and A_GetSpellInfo(spellID) or GetSpellInfo(spellID)
			local timestamp = TMW.time
			
			if not self.Data[GUID] then 
				self.Data[GUID] = {}
			end 	

			if not self.Data[GUID][spellName] then 
				self.Data[GUID][spellName] = {}
			end 				
			
			if not self.Data[GUID][spellName].isFlying then 
				self.Data[GUID][spellName].start 	= timestamp
				self.Data[GUID][spellName].isFlying = true 
			end 
			
			-- We will log CombatTrackerData here because this event fires earlier than CLEU 
			CombatTracker:AddToData(GUID, timestamp)
			CombatTracker.logLastCast(timestamp, nil, nil, GUID, nil, nil, nil, nil, nil, nil, nil, nil, spellName)
		end 
	end, 
	SPELL_CAST_SUCCESS					= function(self, SourceGUID, sourceFlags, spellName)
		-- Note: This trigger is used only for Blink
		if self.isBlink[spellName] and A.IsInPvP and isEnemy(sourceFlags) and isPlayer(sourceFlags) then 
			if not self.Data[SourceGUID] then 
				self.Data[SourceGUID] = {}
			end 
			
			self.Data[SourceGUID].Blink = TMW.time + 15					
		end 
	end, 
	UNIT_DIED							= function(self, DestGUID)
		self.Data[DestGUID] = nil 
	end,
	RESET_IS_FLYING						= function(self, EVENT, SourceGUID, spellName)
		-- Makes exception for events with _CREATE _FAILED _START since they are point less to be triggered		
		if self.Data[SourceGUID] and self.Data[SourceGUID][spellName] and self.Data[SourceGUID][spellName].isFlying and (not self.Data[SourceGUID][spellName].blackListCLEU or not self.Data[SourceGUID][spellName].blackListCLEU[EVENT]) then 
			local lastSeven = strsub(EVENT, -7)
			if not self.isNotResetFlyingEvent[lastSeven] then 
				self.Data[SourceGUID][spellName].isFlying = false 	
			end 
		end 
	end, 
	IsEventIsDied						= {
		["UNIT_DIED"] 					= true,
		["UNIT_DESTROYED"]				= true,
		["UNIT_DISSIPATES"]				= true,
		["PARTY_KILL"] 					= true,
		["SPELL_INSTAKILL"] 			= true,
	},
}

local UnitTrackerData							= UnitTracker.Data
local UnitTrackerIsBlink						= UnitTracker.isBlink
local UnitTrackerMaxResetFlyingTimer 			= UnitTracker.maxResetFlyingTimer
local UnitTrackerIsEventIsDied					= UnitTracker.IsEventIsDied

-------------------------------------------------------------------------------
-- Locals: LossOfControl
-------------------------------------------------------------------------------
local LossOfControl								= {	
	FrameOrder									= {
		[1] 									= {
			"CYCLONE", "BANISH", "CHARM", "DISORIENT", "FREEZE", "HORROR", "INCAPACITATE", "POLYMORPH", "SAP", "SHACKLE_UNDEAD", "SLEEP", "TURN_UNDEAD", "STUN", "FEAR",
		},
		[2]										= {
			"DISARM", "PACIFYSILENCE", "ROOT", "SILENCE", "SCHOOL_INTERRUPT",
		},
		[3]										= {
			"DAZE", "PACIFY", "POSSESS", "SNARE", "CONFUSE",
		},
	},
	FrameData 									= { Result = 0, TextureID = 0, Order = 0 },
	FrameDataIndex								= {
		-- For GetToggle(1, "LossOfControlTypes")
		["PHYSICAL"] 							= 1,
		["HOLY"] 								= 2,
		["FIRE"] 								= 3,
		["NATURE"] 								= 4,
		["FROST"] 								= 5,
		["SHADOW"] 								= 6,
		["ARCANE"] 								= 7,
		["BANISH"] 								= 8,
		["CHARM"] 								= 9,
		["CYCLONE"]								= 10,
		["DAZE"]								= 11,
		["DISARM"]								= 12,
		["DISORIENT"]							= 13,
		["FREEZE"]								= 14,
		["HORROR"]								= 15,
		["INCAPACITATE"]						= 16,
		["PACIFY"]								= 17,
		["PACIFYSILENCE"]						= 18, 
		["POLYMORPH"]							= 19,
		["POSSESS"]								= 20,
		["SAP"]									= 21,
		["SHACKLE_UNDEAD"]						= 22,
		["SLEEP"]								= 23,
		["SNARE"]								= 24, 
		["TURN_UNDEAD"]							= 25, 
		["ROOT"]								= 26, 
		["CONFUSE"]								= 27, 
		["STUN"]								= 28,
		["SILENCE"]								= 29,
		["FEAR"]								= 30, 
	},
	OnFrameSortData								= function(self)
		local isFound
		
		if not A.IsInitialized or GetToggle(1, "LossOfControlPlayerFrame") or GetToggle(1, "LossOfControlRotationFrame") then 
			-- in temp all found things and then sort them by duration, don't forget to create toggle in [1] + probably dropdown to select which types track !!!!!!!!
			local enabledTypes = not A.IsInitialized or GetToggle(1, "LossOfControlTypes")
						
			for i = 1, #self.FrameOrder do 
				for j = 1, #self.FrameOrder[i] do 
					local locName = self.FrameOrder[i][j]					
					if self.Data[locName] then 
						if locName == "SCHOOL_INTERRUPT" then 
							for schoolName in pairs(self.Data["SCHOOL_INTERRUPT"]) do 
								if self.Data[locName][schoolName].Result > self.FrameData.Result and self.Data[locName][schoolName].TextureID ~= 0 and (not A.IsInitialized or enabledTypes[self.FrameDataIndex[schoolName]]) then 
									self.FrameData.Result 		= self.Data[locName][schoolName].Result
									self.FrameData.TextureID 	= self.Data[locName][schoolName].TextureID
									isFound						= true 
								end 
							end 
						else 
							if self.Data[locName].Result > self.FrameData.Result and self.Data[locName].TextureID ~= 0 and (not A.IsInitialized or enabledTypes[self.FrameDataIndex[locName]]) then 
								self.FrameData.Result 			= self.Data[locName].Result
								self.FrameData.TextureID 		= self.Data[locName].TextureID
								isFound							= true 
							end 
						end 
					end 
				end 
				
				if isFound then 
					self.FrameData.Order = i
					break 
				end 
			end 						
		end 

		if not isFound then 
			self.FrameData.Order 		= 0 
			self.FrameData.Result 		= 0
			self.FrameData.TextureID 	= 0
		end 	
		
		TMW:Fire("TMW_ACTION_LOSS_OF_CONTROL_UPDATE")
	end, 	
	Data 										= {
		["SCHOOL_INTERRUPT"]					= {
			["PHYSICAL"] 						= { Result = 0, TextureID = 0 },
			["HOLY"] 							= { Result = 0, TextureID = 0 },
			["FIRE"] 							= { Result = 0, TextureID = 0 },
			["NATURE"] 							= { Result = 0, TextureID = 0 },
			["FROST"] 							= { Result = 0, TextureID = 0 },
			["SHADOW"] 							= { Result = 0, TextureID = 0 },
			["ARCANE"] 							= { Result = 0, TextureID = 0 },
		},	 
		["BANISH"] 								= { Applied = {}, Result = 0, TextureID = 0 },
		["CHARM"] 								= { Applied = {}, Result = 0, TextureID = 0 },
		--["CYCLONE"]							= { Applied = {}, Result = 0, TextureID = 0 },
		--["DAZE"]								= { Applied = {}, Result = 0, TextureID = 0 },
		["DISARM"]								= { Applied = {}, Result = 0, TextureID = 0 },
		["DISORIENT"]							= { Applied = {}, Result = 0, TextureID = 0 },
		["FREEZE"]								= { Applied = {}, Result = 0, TextureID = 0 },
		["HORROR"]								= { Applied = {}, Result = 0, TextureID = 0 },
		["INCAPACITATE"]						= { Applied = {}, Result = 0, TextureID = 0 },
		--["INTERRUPT"]							= { Applied = {}, Result = 0, TextureID = 0 }, -- NEVER UNCOMMENT THIS LINE !
		--["PACIFY"]							= { Applied = {}, Result = 0, TextureID = 0 },
		--["PACIFYSILENCE"]						= { Applied = {}, Result = 0, TextureID = 0 }, 
		["POLYMORPH"]							= { Applied = {}, Result = 0, TextureID = 0 },
		--["POSSESS"]							= { Applied = {}, Result = 0, TextureID = 0 },
		["SAP"]									= { Applied = {}, Result = 0, TextureID = 0 },
		["SHACKLE_UNDEAD"]						= { Applied = {}, Result = 0, TextureID = 0 },
		["SLEEP"]								= { Applied = {}, Result = 0, TextureID = 0 },
		["SNARE"]								= { Applied = {}, Result = 0, TextureID = 0 }, 
		["TURN_UNDEAD"]							= { Applied = {}, Result = 0, TextureID = 0 }, 
		["ROOT"]								= { Applied = {}, Result = 0, TextureID = 0 }, 
		--["CONFUSE"]							= { Applied = {}, Result = 0, TextureID = 0 }, 
		["STUN"]								= { Applied = {}, Result = 0, TextureID = 0 },
		["SILENCE"]								= { Applied = {}, Result = 0, TextureID = 0 },
		["FEAR"]								= { Applied = {}, Result = 0, TextureID = 0 }, 
	},
	Aura										= {
		-- TEST 
		--[GetSpellInfo(11918)]					= {"STUN", "ROOT"},
		-- [[ ROOT ]] 
		-- Entangling Roots
		[GetSpellInfo(339)]						= "ROOT",
		-- Feral Charge Effect
		[GetSpellInfo(19675)]					= "ROOT",
		-- Improved Wing Clip
		[GetSpellInfo(19229)]					= "ROOT",
		-- Entrapment
		[GetSpellInfo(19185)]					= "ROOT",
		-- Boar Charge
		[GetSpellInfo(25999)]					= "ROOT",
		-- Frost Nova
		[GetSpellInfo(122)]						= "ROOT",
		-- Frostbite
		[GetSpellInfo(12494)]					= "ROOT",
		-- Trap
		[GetSpellInfo(8312)]					= "ROOT",
		-- Mobility Malfunction
		[GetSpellInfo(8346)]					= "ROOT",
		-- Net-o-Matic
		[GetSpellInfo(13099)]					= "ROOT",
		-- Fire Blossom
		[GetSpellInfo(19636)]					= "ROOT",
		-- Paralyze
		[GetSpellInfo(23414)]					= "ROOT",
		-- Chains of Ice
		[GetSpellInfo(113)]						= "ROOT",
		-- Grasping Vines
		[GetSpellInfo(8142)]					= "ROOT",
		-- Soul Drain
		[GetSpellInfo(7295)]					= "ROOT",
		-- Net
		[GetSpellInfo(6533)]					= "ROOT",
		-- Electrified Net
		[GetSpellInfo(11820)]					= "ROOT",
		-- Ice Blast
		[GetSpellInfo(11264)]					= "ROOT",
		-- Earthgrab
		[GetSpellInfo(8377)]					= "ROOT",
		-- Web Spray
		[GetSpellInfo(12252)]					= "ROOT",
		-- Web
		[GetSpellInfo(745)]						= "ROOT",
		-- Web Explosion
		[GetSpellInfo(15474)]					= "ROOT",
		-- Hooked Net
		[GetSpellInfo(14030)]					= "ROOT",
		-- Encasing Webs
		[GetSpellInfo(4962)]					= "ROOT",
		
		-- [[ SNARE ]]
		-- Wing Clip
		[GetSpellInfo(2974)]					= "SNARE",
		-- Concussive Shot
		[GetSpellInfo(5116)]					= "SNARE",
		-- Dazed
		[GetSpellInfo(15571)]					= "SNARE", -- FIX ME: Can be DAZE 
		-- Frost Trap
		[GetSpellInfo(13809)]					= "SNARE",
		-- Frost Trap Aura
		[GetSpellInfo(13810)]					= "SNARE",
		-- Blizzard
		[GetSpellInfo(10)]						= "SNARE",
		-- Cone of Cold
		[GetSpellInfo(120)]						= "SNARE",
		-- Frostbolt
		[GetSpellInfo(116)]						= "SNARE",
		-- Blast Wave
		[GetSpellInfo(11113)]					= "SNARE",
		-- Mind Flay
		[GetSpellInfo(15407)]					= "SNARE",
		-- Crippling Poison
		[GetSpellInfo(3409)]					= "SNARE",
		-- Frost Shock
		[GetSpellInfo(8056)]					= "SNARE",
		-- Earthbind
		[GetSpellInfo(3600)]					= "SNARE",
		-- Curse of Exhaustion
		[GetSpellInfo(18223)]					= "SNARE",
		-- Aftermath
		[GetSpellInfo(18118)]					= "SNARE",
		-- Cripple
		[GetSpellInfo(89)]						= "SNARE",
		-- Hamstring
		[GetSpellInfo(1715)]					= "SNARE",
		-- Long Daze
		[GetSpellInfo(12705)]					= "SNARE",
		-- Piercing Howl
		[GetSpellInfo(12323)]					= "SNARE",
		-- Curse of Shahram
		[GetSpellInfo(16597)]					= "SNARE",
		-- Magma Shackles
		[GetSpellInfo(19496)]					= "SNARE",		
		-- Suppression Aura
		[GetSpellInfo(22247)]					= "SNARE",	
		-- Thunderclap
		[GetSpellInfo(15548)]					= "SNARE",	
		-- Slow
		[GetSpellInfo(13747)]					= "SNARE",
		-- Brood Affliction: Blue
		[GetSpellInfo(23153)]					= "SNARE",
		-- Molten Metal
		[GetSpellInfo(5213)]					= "SNARE",
		-- Melt Ore
		[GetSpellInfo(5159)]					= "SNARE",		
		-- Frostbolt Volley
		[GetSpellInfo(8398)]					= "SNARE",	
		-- Hail Storm
		[GetSpellInfo(10734)]					= "SNARE",	
		-- Twisted Tranquility
		[GetSpellInfo(21793)]					= "SNARE",	
		-- Frost Shot
		[GetSpellInfo(12551)]					= "SNARE",	
		-- Icicle
		[GetSpellInfo(11131)]					= "SNARE",	
		-- Chilled
		[GetSpellInfo(18101)]					= "SNARE",	
		
		-- [[ STUN ]]
		-- Pounce
		[GetSpellInfo(9005)]					= "STUN",
		-- Bash
		[GetSpellInfo(5211)]					= "STUN",
		-- Starfire Stun
		[GetSpellInfo(16922)]					= "STUN",
		-- Improved Concussive Shot
		[GetSpellInfo(19410)]					= "STUN",
		-- Intimidation
		[GetSpellInfo(24394)]					= "STUN",
		-- Impact
		[GetSpellInfo(12355)]					= "STUN",
		-- Hammer of Justice
		[GetSpellInfo(853)]						= "STUN",
		-- Stun
		[GetSpellInfo(20170)]					= "STUN",
		-- Blackout
		[GetSpellInfo(15269)]					= "STUN",
		-- Kidney Shot
		[GetSpellInfo(408)]						= "STUN",
		-- Cheap Shot
		[GetSpellInfo(1833)]					= "STUN",
		-- Inferno Effect
		[GetSpellInfo(22703)]					= "STUN",
		-- Pyroclasm
		[GetSpellInfo(18093)]					= "STUN",
		-- War Stomp
		[GetSpellInfo(19482)]					= "STUN",
		-- Charge Stun
		[GetSpellInfo(7922)]					= "STUN",
		-- Mace Stun Effect
		[GetSpellInfo(5530)]					= "STUN",
		-- Revenge Stun
		[GetSpellInfo(12798)]					= "STUN",
		-- Stun
		[GetSpellInfo(56)]						= "STUN",
		-- Tidal Charm 
		[GetSpellInfo(835)]						= "STUN",
		-- Rough Copper Bomb
		[GetSpellInfo(4064)]					= "STUN",
		-- Large Copper Bomb
		[GetSpellInfo(4065)]					= "STUN",
		-- Small Bronze Bomb
		[GetSpellInfo(4066)]					= "STUN",
		-- Big Bronze Bomb
		[GetSpellInfo(4067)]					= "STUN",
		-- Iron Grenade
		[GetSpellInfo(4068)]					= "STUN",
		-- Big Iron Bomb
		[GetSpellInfo(4069)]					= "STUN",
		-- The Big One
		[GetSpellInfo(12562)]					= "STUN",
		-- Mithril Frag Bomb
		[GetSpellInfo(12421)]					= "STUN",
		-- Dark Iron Bomb
		[GetSpellInfo(19784)]					= "STUN",
		-- Thorium Grenade
		[GetSpellInfo(19769)]					= "STUN",
		-- M73 Frag Grenade
		[GetSpellInfo(13808)]					= "STUN",
		-- Knockdown
		[GetSpellInfo(15753)]					= "STUN",
		-- Enveloping Winds 
		[GetSpellInfo(15535)]					= "STUN",
		-- Highlord's Justice
		[GetSpellInfo(20683)]					= "STUN",
		-- Crusader's Hammer
		[GetSpellInfo(17286)]					= "STUN",
		-- Might of Shahram
		[GetSpellInfo(16600)]					= "STUN",
		-- Smite Demon
		[GetSpellInfo(13907)]					= "STUN",
		-- Ground Stomp
		[GetSpellInfo(19364)]					= "STUN",
		-- Pyroclast Barrage
		[GetSpellInfo(19641)]					= "STUN",
		-- Fist of Ragnaros
		[GetSpellInfo(20277)]					= "STUN",
		-- Brood Power: Green
		[GetSpellInfo(22289)]					= "STUN",
		-- Time Stop 
		[GetSpellInfo(23171)]					= "STUN",
		-- Tail Lash
		[GetSpellInfo(23364)]					= "STUN",
		-- Aura of Nature
		[GetSpellInfo(25043)]					= "STUN",
		-- Shield Slam
		[GetSpellInfo(8242)]					= "STUN",
		-- Rhahk'Zor Slam
		[GetSpellInfo(6304)]					= "STUN",
		-- Smite Slam
		[GetSpellInfo(6435)]					= "STUN",
		-- Smite Stomp
		[GetSpellInfo(6435)]					= "STUN",
		-- Axe Toss
		[GetSpellInfo(6466)]					= "STUN",
		-- Thundercrack
		[GetSpellInfo(8150)]					= "STUN",
		-- Fel Stomp
		[GetSpellInfo(7139)]					= "STUN",
		-- Ravage
		[GetSpellInfo(8391)]					= "STUN",
		-- Smoke Bomb
		[GetSpellInfo(7964)]					= "STUN",
		-- Backhand
		[GetSpellInfo(6253)]					= "STUN",
		-- Rampage
		[GetSpellInfo(8285)]					= "STUN",
		-- Enveloping Winds
		[GetSpellInfo(6728)]					= "STUN",
		-- Ground Tremor
		[GetSpellInfo(6524)]					= "STUN",
		-- Summon Shardlings
		[GetSpellInfo(21808)]					= "STUN",
		-- Petrify
		[GetSpellInfo(11020)]					= "STUN",
		-- Freeze Solid
		[GetSpellInfo(11836)]					= "STUN",
		-- Lash
		[GetSpellInfo(25852)]					= "STUN",
		-- Paralyzing Poison
		[GetSpellInfo(3609)]					= "STUN",
		-- Hand of Thaurissan
		[GetSpellInfo(17492)]					= "STUN",
		-- Drunken Stupor
		[GetSpellInfo(14870)]					= "STUN",
		-- Chest Pains
		[GetSpellInfo(6945)]					= "STUN",
		-- Skull Crack
		[GetSpellInfo(3551)]					= "STUN",
		-- Snap Kick
		[GetSpellInfo(15618)]					= "STUN",
		-- Throw Axe
		[GetSpellInfo(16075)]					= "STUN",
		-- Crystallize
		[GetSpellInfo(16104)]					= "STUN",
		-- Stun Bomb
		[GetSpellInfo(16497)]					= "STUN",
		-- Ground Smash
		[GetSpellInfo(12734)]					= "STUN",
		-- Burning Winds
		[GetSpellInfo(17293)]					= "STUN",
		-- Ice Tomb
		[GetSpellInfo(16869)]					= "STUN",
		-- Sacrifice
		[GetSpellInfo(22651)]					= "STUN",
		-- Goblin Mortar
		[GetSpellInfo(13237)]					= "STUN",
		-- Improved Starfire
		[GetSpellInfo(16922)]					= "STUN",
		
		-- [[ DISARM ]]
		-- Disarm
		[GetSpellInfo(676)]						= "DISARM",		
		-- Dropped Weapon
		[GetSpellInfo(23365)]					= "DISARM",	
		
		-- [[ SLEEP ]]
		-- Hibernate
		[GetSpellInfo(2637)]					= "SLEEP",
		-- Wyvern Sting
		[GetSpellInfo(19386)]					= "SLEEP",
		-- Sleep
		[GetSpellInfo(9159)]					= "SLEEP",
		-- Dreamless Sleep Potion
		[GetSpellInfo(15822)]					= "SLEEP",
		-- Calm Dragonkin
		[GetSpellInfo(19872)]					= "SLEEP",
		-- Druid's Slumber
		[GetSpellInfo(8040)]					= "SLEEP",
		-- Naralex's Nightmare
		[GetSpellInfo(7967)]					= "SLEEP",
		-- Deep Sleep
		[GetSpellInfo(9256)]					= "SLEEP",
		-- Enchanting Lullaby
		[GetSpellInfo(16798)]					= "SLEEP",
		-- Crystalline Slumber
		[GetSpellInfo(3636)]					= {"STUN", "SLEEP"},
		
		-- [[ INCAPACITATE ]] 
		-- Mangle
		[GetSpellInfo(22570)]					= "INCAPACITATE",
		-- Repentance
		[GetSpellInfo(20066)]					= "INCAPACITATE",
		-- Gouge
		[GetSpellInfo(1776)]					= "INCAPACITATE",
		-- Reckless Charge
		[GetSpellInfo(13327)]					= "INCAPACITATE",
		
		-- [[ FREEZE ]] 
		-- Freezing Trap Effect
		[GetSpellInfo(3355)]					= {"ROOT", "FREEZE"},
		-- Freeze
		[GetSpellInfo(5276)]					= {"STUN", "FREEZE"},
		
		-- [[ DISORIENT ]]
		-- Scatter Shot
		[GetSpellInfo(19503)]					= {"INCAPACITATE", "DISORIENT"},
		-- Blind
		[GetSpellInfo(2094)]					= {"INCAPACITATE", "DISORIENT"},
		-- Glimpse of Madness
		[GetSpellInfo(26108)]					= {"INCAPACITATE", "DISORIENT"},
		-- Ancient Despair
		[GetSpellInfo(19369)]					= {"INCAPACITATE", "DISORIENT"},
		
		-- [[ SILENCE ]]
		-- Counterspell - Silenced
		[GetSpellInfo(18469)]					= "SILENCE",
		-- Silence 
		[GetSpellInfo(15487)]					= "SILENCE",
		-- Shield Bash - Silenced
		[GetSpellInfo(18498)]					= "SILENCE",
		-- Spell Lock (Felhunter)
		[GetSpellInfo(24259)]					= "SILENCE",
		-- Arcane Bomb
		[GetSpellInfo(19821)]					= "SILENCE",
		-- Silence (Silent Fang sword)
		[GetSpellInfo(18278)]					= "SILENCE",
		-- Soul Burn
		[GetSpellInfo(19393)]					= "SILENCE",
		-- Screams of the Past
		[GetSpellInfo(7074)]					= "SILENCE",
		-- Sonic Burst
		[GetSpellInfo(8281)]					= "SILENCE",
		-- Putrid Stench
		[GetSpellInfo(12946)]					= "SILENCE",	
		-- Banshee Shriek
		[GetSpellInfo(16838)]					= "SILENCE",		
		
		-- [[ HORROR ]] (on mechanic Fleeing)
		-- Psychic Scream
		[GetSpellInfo(8122)]					= {"FEAR", "HORROR"},
		-- Howl of Terror
		[GetSpellInfo(5484)]					= {"FEAR", "HORROR"},
		-- Death Coil
		[GetSpellInfo(6789)]					= {"FEAR", "HORROR"},
		-- Intimidating Shout
		[GetSpellInfo(5246)]					= {"FEAR", "HORROR"},
		-- Flash Bomb
		[GetSpellInfo(5134)]					= {"FEAR", "HORROR"},
		-- Corrupted Fear
		[GetSpellInfo(21330)]					= {"FEAR", "HORROR"},
		-- Bellowing Roar
		[GetSpellInfo(18431)]					= {"FEAR", "HORROR"},	
		-- Terrify
		[GetSpellInfo(7399)]					= {"FEAR", "HORROR"},		
		-- Repulsive Gaze
		[GetSpellInfo(21869)]					= {"FEAR", "HORROR"},	
		
		-- [[ FEAR ]]
		-- Fear
		[GetSpellInfo(5782)]					= "FEAR",
		-- Scare Beast
		[GetSpellInfo(1513)]					= "FEAR",
		
		-- [[ TURN_UNDEAD ]]
		-- Turn Undead
		[GetSpellInfo(2878)]					= {"FEAR", "TURN_UNDEAD"},
		
		-- [[ POLYMORPH ]]
		-- Polymorph
		[GetSpellInfo(118)]						= "POLYMORPH",
		-- Polymorph: Sheep
		[GetSpellInfo(851)]						= "POLYMORPH",
		-- Polymorph: Turtle
		[GetSpellInfo(28271)]					= "POLYMORPH",
		-- Polymorph: Pig
		[GetSpellInfo(28272)]					= "POLYMORPH",
		-- Polymorph: Chicken
		[GetSpellInfo(228)]						= "POLYMORPH",
		-- Polymorph Backfire
		[GetSpellInfo(28406)]					= "POLYMORPH",
		-- Greater Polymorph
		[GetSpellInfo(22274)]					= "POLYMORPH",
		-- Hex
		[GetSpellInfo(17172)]					= "POLYMORPH",
		-- Hex of Jammal'an
		[GetSpellInfo(12480)]					= "POLYMORPH",
		
		-- [[ CHARM ]]
		-- Mind Control
		[GetSpellInfo(605)]						= "CHARM",
		-- Seduction
		[GetSpellInfo(6358)]					= "CHARM",
		-- Gnomish Mind Control Cap
		[GetSpellInfo(13181)]					= "CHARM",
		-- Dominion of Soul
		[GetSpellInfo(16053)]					= "CHARM",
		-- Dominate Mind
		[GetSpellInfo(15859)]					= "CHARM",
		-- Shadow Command
		[GetSpellInfo(22667)]					= "CHARM",
		-- Creature of Nightmare
		[GetSpellInfo(25806)]					= "CHARM",
		-- Cause Insanity
		[GetSpellInfo(12888)]					= "CHARM",
		-- Domination
		[GetSpellInfo(17405)]					= "CHARM",
		-- Possess
		[GetSpellInfo(17244)]					= "CHARM",
		-- Arugal's Curse
		[GetSpellInfo(7621)]					= {"POLYMORPH", "CHARM"},
		
		-- [[ SHACKLE_UNDEAD ]]
		-- Shackle Undead 
		[GetSpellInfo(9484)]					= "SHACKLE_UNDEAD",
		
		-- [[ SAP ]]
		-- Sap
		[GetSpellInfo(6770)]					= {"INCAPACITATE", "SAP"},
		
		-- [[ BANISH ]] 
		-- Banish
		[GetSpellInfo(710)]						= "BANISH",
	},
	Interrupt									= {
		-- Shield Bash 
		[GetSpellInfo(72)]						= { Duration = 6, TextureID = 132357 },
		-- Pummel
		[GetSpellInfo(6552)]					= { Duration = 4, TextureID = 132938 },
		-- Kick
		[GetSpellInfo(1766)]					= { Duration = 5, TextureID = 132219 },
		-- Counterspell
		[GetSpellInfo(2139)]					= { Duration = 10, TextureID = 135856 },
		-- Earth Shock 
		[GetSpellInfo(8042)]					= { Duration = 2, TextureID = 136026 },
		-- Spell Lock
		[GetSpellInfo(19647)]					= { Duration = 8, TextureID = 136174 }, -- since we can't get exactly info about enemy talents we will assume it as 8 instead of 6 
		-- Feral Charge
		[GetSpellInfo(19675)]					= { Duration = 4, TextureID = 132183 },
	},
	BitBandSchool								= {
		[0x1]									= "PHYSICAL",
		[0x2]									= "HOLY",
		[0x4]									= "FIRE",
		[0x8]									= "NATURE",
		[0x10]									= "FROST",
		[0x20]									= "SHADOW",
		[0x40]									= "ARCANE",
	},
	Enumerate									= function(self, action, aura, ...)
		local Expiration, TextureID = 0, 0
		if action == "Add" then 
			local _, Name, expirationTime, spellID
			for j = 1, huge do 
				Name, _, _, _, _, expirationTime, _, _, _, spellID = UnitDebuff("player", j)
				if not Name then 
					break 
				elseif Name == aura then 
					Expiration = expirationTime == 0 and huge or expirationTime
					TextureID  = GetSpellTexture(spellID)
					break
				end 
			end 
		end 
			
		local isTable = type(self.Aura[aura]) == "table"
		for i = 1, isTable and #self.Aura[aura] or 1 do
			local locType = isTable and self.Aura[aura][i] or self.Aura[aura]
			
			-- Create once reusable table 
			if not self.Data[locType].Applied[aura] then 
				self.Data[locType].Applied[aura] = {}
			end 
		
			if Expiration > self.Data[locType].Result then 
				-- Applied more longer duration than previous
				self.Data[locType].Result 		= Expiration
				self.Data[locType].TextureID 	= TextureID
				self.Data[locType].Applied[aura].Result 	= Expiration	
				self.Data[locType].Applied[aura].TextureID	= TextureID
			elseif Expiration == 0 then 
				-- Removed 
				if self.Data[locType].Applied[aura] then 
					wipe(self.Data[locType].Applied[aura])
				end 
				
				-- Recheck if persistent another loss of control and update expirationTime, otherwise 0 if nothing
				local maxExpiration, relativeTextureID = 0, 0					
				for k, v in pairs(self.Data[locType].Applied) do 
					if next(v) and v.Result > maxExpiration then  -- if maxExpiration == 0 or (next(v) and v.Result > maxExpiration) then 
						maxExpiration 		= v.Result 	   or 0
						relativeTextureID 	= v.TextureID  or 0
					end 
				end 					 
				
				self.Data[locType].Result 		= maxExpiration	
				self.Data[locType].TextureID 	= relativeTextureID				
			else	
				-- Applied more shorter duration if previous is longer 
				self.Data[locType].Applied[aura].Result 	= Expiration
				self.Data[locType].Applied[aura].TextureID 	= TextureID
			end 
		end 
		
		self:OnFrameSortData()
	end, 
	OnEventInterrupt 							= function(self, timestamp, spellName, lockSchool) 
		self.Data["SCHOOL_INTERRUPT"][lockSchool].Result 	= timestamp + self.Interrupt[spellName].Duration
		self.Data["SCHOOL_INTERRUPT"][lockSchool].TextureID = self.Interrupt[spellName].TextureID
		
		self:OnFrameSortData()
	end, 
	Reset 										= function(self, DestGUID)
		for k, v in pairs(self.Data) do 
			if k == "SCHOOL_INTERRUPT" then 
				for _, v2 in pairs(v) do 
					v2.Result = 0
					v2.TextureID = 0
				end 
			else 
				v.Result = 0
				v.TextureID = 0
				wipe(v.Applied)
			end 
		end 
		
		self.FrameData.Order	  = 0 
		self.FrameData.Result	  = 0 
		self.FrameData.TextureID  = 0
		TMW:Fire("TMW_ACTION_LOSS_OF_CONTROL_UPDATE")
	end, 
}

LossOfControl.OnEvent 							= {
	-- Add 
	SPELL_AURA_APPLIED 							= function(aura) LossOfControl:Enumerate("Add", aura) end,
	--SPELL_AURA_APPLIED_DOSE 					= function(aura) LossOfControl:Enumerate("Add", aura) end, 
	SPELL_AURA_REFRESH 							= function(aura) LossOfControl:Enumerate("Add", aura) end,
	SPELL_INTERRUPT								= function(timestamp, spellName, lockSchool) LossOfControl:OnEventInterrupt(timestamp, spellName, lockSchool) end,
	-- Remove 
	SPELL_AURA_REMOVED							= function(aura) LossOfControl:Enumerate("Remove", aura) end, 
	--SPELL_AURA_REMOVED_DOSE 					= function(aura) LossOfControl:Enumerate("Remove", aura) end,
	SPELL_AURA_BROKEN							= function(aura) LossOfControl:Enumerate("Remove", aura) end,  -- TODO: Testing persistent auras, should fix stucking issue
	SPELL_AURA_BROKEN_SPELL						= function(aura) LossOfControl:Enumerate("Remove", aura) end,  -- TODO: Testing persistent auras, should fix stucking issue
	SPELL_DISPEL								= function(aura) LossOfControl:Enumerate("Remove", aura) end,  -- TODO: Testing persistent auras, should fix stucking issue
}

LossOfControl.OnEventReset						= {
	-- Reset 
	UNIT_DIED									= function() LossOfControl:Reset() end,
	UNIT_DESTROYED								= function() LossOfControl:Reset() end,
	UNIT_DISSIPATES								= function() LossOfControl:Reset() end,
	PARTY_KILL									= function() LossOfControl:Reset() end,
	SPELL_INSTAKILL								= function() LossOfControl:Reset() end,
}

local LossOfControlFrameData					= LossOfControl.FrameData
local LossOfControlData							= LossOfControl.Data
local LossOfControlAura							= LossOfControl.Aura
local LossOfControlInterrupt					= LossOfControl.Interrupt
local LossOfControlBitBandSchool				= LossOfControl.BitBandSchool
local LossOfControlOnEvent 						= LossOfControl.OnEvent 
local LossOfControlOnEventReset 				= LossOfControl.OnEventReset 

-------------------------------------------------------------------------------
-- OnEvent
-------------------------------------------------------------------------------
local COMBAT_LOG_EVENT_UNFILTERED 				= function(...)	
	local timestamp = TMW.time 
	local _, EVENT, _, SourceGUID, _, sourceFlags, _, DestGUID, _, destFlags, _, spellID, spellName, spellSchool, auraType, a16, a17, a18, a19, a20, a21, a22, a23, a24 = CombatLogGetCurrentEventInfo()
	
	-- Add the unit to our data if we dont have it
	CombatTracker:AddToData(SourceGUID, timestamp)
	CombatTracker:AddToData(DestGUID, timestamp) 
	
	-- Trigger 
	if CombatTrackerOnEventCLEU[EVENT] then  
		CombatTrackerOnEventCLEU[EVENT](timestamp, EVENT, _, SourceGUID, _, sourceFlags, _, DestGUID, _, destFlags, _, spellID, spellName, spellSchool, auraType, a16, a17, a18, a19, a20, a21, a22, a23, a24)
	end 
	
	-- Diminishing (DR-Tracker)
	if CombatTrackerOnEventDR[EVENT] and (auraType == "DEBUFF" or a18 == "DEBUFF") then 
		CombatTrackerOnEventDR[EVENT](timestamp, EVENT, DestGUID, destFlags, spellID)
	end 
	
	-- Loss of Control (Classic only)
	if LossOfControlOnEvent[EVENT] then 
		if auraType == "DEBUFF" and spellName and LossOfControlAura[spellName] and GetGUID("player") == DestGUID then 
			LossOfControlOnEvent[EVENT](spellName)
		end 
		
		if EVENT == "SPELL_INTERRUPT" and spellSchool and LossOfControlInterrupt[spellName] and GetGUID("player") == DestGUID then 
			local lockSchool = LossOfControlBitBandSchool[spellSchool] 
			if lockSchool then 
				LossOfControlOnEvent[EVENT](timestamp, spellName, lockSchool)
			end 
		end 
	elseif LossOfControlOnEventReset[EVENT] and GetGUID("player") == DestGUID then 
		LossOfControlOnEventReset[EVENT]()
	end 
		
	-- PvP players tracker
	if EVENT == "SPELL_CAST_SUCCESS" then  
		-- Blink 
		UnitTracker:SPELL_CAST_SUCCESS(SourceGUID, sourceFlags, spellName)
		-- Other
		UnitTracker:UNIT_SPELLCAST_SUCCEEDED(SourceGUID, sourceFlags, spellName)
	end 
	
	if EVENT == "SPELL_MISSED" or EVENT == "SPELL_CREATE" then 
		UnitTracker:UNIT_SPELLCAST_SUCCEEDED(SourceGUID, sourceFlags, spellName)
	end 

	-- Reset isFlying
	if UnitTrackerIsEventIsDied[EVENT] then 
		UnitTracker:UNIT_DIED(DestGUID)
	else 
		local firstFive = strsub(EVENT, 1, 5)
		if firstFive == "SPELL" and not UnitTrackerIsBlink[spellName] then 
			UnitTracker:RESET_IS_FLYING(EVENT, SourceGUID, spellName)
		end 
	end 
end 

local UNIT_SPELLCAST_SUCCEEDED					= function(...)
	local unitID, _, spellID = ...
	if unitID == "player" and not UnitTrackerIsBlink[spellID] then  
		UnitTracker:UNIT_SPELLCAST_SUCCEEDED_PLAYER(unitID, spellID)
	end 
end

TMW:RegisterCallback("TMW_ACTION_ENTERING",											function(event, subevent)
	if skipedFirstEnter then 
		if not InCombatLockdown() then 
			if subevent ~= "UPDATE_INSTANCE_INFO" then 
				wipe(UnitTrackerData)
				wipe(CombatTrackerData)
			end 
			wipe(RealUnitHealthDamageTaken)
			wipe(RealUnitHealthCachedHealthMax)
			wipe(RealUnitHealthisHealthWasMaxOnGUID)
			wipe(RealUnitHealthCachedHealthMaxTemprorary)
			wipe(RealUnitHealthSavedHealthPercent)
			logDefaultGUIDatMaxHealthTarget()
		end 
	else 
		skipedFirstEnter = true 
	end 
end)
TMW:RegisterCallback("TMW_ACTION_GROUP_UPDATE",										logDefaultGUIDatMaxHealth			)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_TARGET_CHANGED",				logDefaultGUIDatMaxHealthTarget		)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UPDATE_MOUSEOVER_UNIT",				logDefaultGUIDatMaxHealthMouseover	)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "NAME_PLATE_UNIT_ADDED",				CombatTracker.logHealthMax			)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_TARGET",							function(...) 
	local unitID = ... 
	CombatTracker.logHealthMax(unitID .. "target")
end)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_HEALTH",							CombatTracker.logHealthMax			)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_HEALTH_FREQUENT",					CombatTracker.logHealthMax			)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_MAXHEALTH",						CombatTracker.logHealthMax			)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "COMBAT_LOG_EVENT_UNFILTERED", 			COMBAT_LOG_EVENT_UNFILTERED			) 
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "UNIT_SPELLCAST_SUCCEEDED", 			UNIT_SPELLCAST_SUCCEEDED			)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_REGEN_ENABLED", 				function()
	if A.Zone ~= "pvp" and not A.IsInDuel and not A_Player:IsStealthed() then 
		wipe(UnitTrackerData)
		wipe(CombatTrackerData)		
	end 
	
	local GUID = GetGUID("player")
	CombatTracker:AddToData(GUID, TMW.time)
	if CombatTrackerData[GUID] then 
		CombatTrackerData[GUID].combat_time = 0 
	end 	 
end)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_REGEN_DISABLED", 				function()
	-- Need leave slow delay to prevent reset Data which was recorded before combat began for flyout spells, otherwise it will cause a bug
	if A_CombatTracker:GetSpellLastCast("player", A.LastPlayerCastName) > 1.5 and A.Zone ~= "pvp" and not A.IsInDuel and not A_Player:IsStealthed() and A_Player:CastTimeSinceStart() > 5 then 
		wipe(UnitTrackerData)   		
		wipe(CombatTrackerData) 
	end 
	
	local GUID = GetGUID("player")
	CombatTracker:AddToData(GUID, TMW.time)
	if CombatTrackerData[GUID] then 
		CombatTrackerData[GUID].combat_time = TMW.time 
	end 	 
end)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_ENTERING_WORLD",				function() LossOfControl:Reset() end)
Listener:Add("ACTION_EVENT_COMBAT_TRACKER", "PLAYER_ENTERING_BATTLEGROUND",			function() LossOfControl:Reset() end)

-------------------------------------------------------------------------------
-- OnUpdate
-------------------------------------------------------------------------------
local Frame = CreateFrame("Frame", nil, UIParent)	 
Frame:SetScript("OnUpdate", function(self, elapsed)
	self.TimeSinceLastUpdate = (self.TimeSinceLastUpdate or 0) + elapsed
	if self.TimeSinceLastUpdate > 15 then	
		local GUID, Data = next(CombatTrackerData)
		
		while GUID ~= nil do 
			if TMW.time - Data.lastSeen > 60 then  
				CombatTrackerData[GUID] = nil 
				Data = nil 
				TMW:Fire("TMW_ACTION_COMBAT_TRACKER_GUID_WIPE", GUID)
			end 
			
			GUID, Data = next(CombatTrackerData,  GUID)
		end 
		
		self.TimeSinceLastUpdate = 0
	end 
end)

-------------------------------------------------------------------------------
-- API: CombatTracker
-------------------------------------------------------------------------------
A.CombatTracker									= {
	--[[ Returns the real unit max health ]]
	-- Same functional as on retail (only during recorded logs!)
	UnitHealthMax								= function(self, unitID)
		-- @return number (0 in case if unit dead or if it's not recorded by logs)		
		-- Exception for self because we can self real hp by this func 
		if UnitHasRealHealth(unitID) then 
			return UnitHealthMax(unitID)
		end 
			
		local GUID = UnitGUID(unitID)	-- Not GetGUID(unitID) because it will never be Base members	
		if RealUnitHealthCachedHealthMax[GUID] then 
			-- Pre out 			
			return RealUnitHealthCachedHealthMax[GUID] 
		elseif RealUnitHealthCachedHealthMaxTemprorary[GUID] then 
			-- Post out 
			return RealUnitHealthCachedHealthMaxTemprorary[GUID] 
		elseif RealUnitHealthDamageTaken[GUID] and RealUnitHealthDamageTaken[GUID] > 0 then			
			-- Broken out 
			local max_hp = UnitHealthMax(unitID)
			if max_hp ~= 0 then 
				local curr_value = RealUnitHealthDamageTaken[GUID] / (1 - (UnitHealth(unitID) / max_hp)) 
				if curr_value > 0 then
					return curr_value				 					
				end 
			end 
		end 

		return 0 
	end,
	--[[ Returns the real unit health ]]
	-- Same functional as on retail (only during recorded logs!)
	UnitHealth									= function(self, unitID)
		-- @return number (0 in case if unit dead or if it's not recorded by logs)
		-- Exception for self because we can self real hp by this func 
		if UnitHasRealHealth(unitID) then  
			return UnitHealth(unitID)
		end 
		
		local GUID = UnitGUID(unitID)	-- Not GetGUID(unitID) because it will never be Base members		
		
		-- Unit wiped or not recorded 
		if not RealUnitHealthDamageTaken[GUID] then 
			return 0 
		end 	
		
		if RealUnitHealthCachedHealthMax[GUID] then 
			-- Pre out 
			local curr_value 
			if UnitAffectingCombat(unitID) then 
				-- In combat
				curr_value = RealUnitHealthCachedHealthMax[GUID] - RealUnitHealthDamageTaken[GUID] 
			else
				-- Out of combat 
				curr_value = UnitHealth(unitID) * RealUnitHealthCachedHealthMax[GUID] / 100
			end 
			--print("PRE OUT UnitHealth(", unitID, "): ", curr_value)
			if curr_value > 0 then 
				return curr_value
			else 
				return abs(curr_value)	
			end 			
			-- Way which more accurate (in case if CLEU missed something in damage / healing log) but required more performance 
			--return UnitHealth(unitID) * RealUnitHealthCachedHealthMax[GUID] / UnitHealthMax(unitID)
		elseif RealUnitHealthCachedHealthMaxTemprorary[GUID] then 
			-- Post out 
			local curr_value 
			if UnitAffectingCombat(unitID) then 
				-- In combat
				curr_value = RealUnitHealthCachedHealthMaxTemprorary[GUID] - RealUnitHealthDamageTaken[GUID]
			else 
				-- Out of combat 
				curr_value = UnitHealth(unitID) * RealUnitHealthCachedHealthMaxTemprorary[GUID] / 100
			end 
			--print("POST POST OUT UnitHealth(", unitID, "): ", curr_value)
			if curr_value > 0 then 
				return curr_value
			else 
				return abs(curr_value)
			end 
		elseif RealUnitHealthDamageTaken[GUID] > 0 then 
			-- Broken out
			local curr_hp, max_hp = UnitHealth(unitID), UnitHealthMax(unitID)
			if max_hp ~= 0 then 
				local curr_value = (RealUnitHealthDamageTaken[GUID] / (1 - (curr_hp / max_hp))) - RealUnitHealthDamageTaken[GUID] 
				--print("BROKEN OUT UnitHealth(", unitID, "): ", curr_value)
				if curr_value > 0 then 
					return (curr_hp == max_hp or curr_value == huge) and 0 or curr_value
				else 
					return abs((curr_hp == max_hp or curr_value == huge) and 0 or curr_value)
				end 		
			end 
		end 
		
		return 0 
	end,
	--[[ Return boolean if unit has real value ]]
	UnitHasRealHealth							= function(self, unitID)
		-- @return boolean 
		return UnitHasRealHealth(unitID)
	end,
	--[[ Returns the total ammount of time a unit is in-combat for ]]
	CombatTime									= function(self, unitID)
		-- @return number, GUID 
		local unit = unitID or "player"
		local GUID = GetGUID(unit)
		
		if CombatTrackerData[GUID] and CombatTrackerData[GUID].combat_time ~= 0 then 
			if (UnitIsUnit(unit, "player") and InCombatLockdown()) or UnitAffectingCombat(unit) then     
				return TMW.time - CombatTrackerData[GUID].combat_time, GUID	               
			else
				CombatTrackerData[GUID].combat_time = 0
			end 
		end		
		return 0, GUID		
	end, 
	--[[ Get Last X seconds incoming DMG (10 sec max, default X is 5) ]] 
	GetLastTimeDMGX								= function(self, unitID, X)
		local GUID 								= GetGUID(unitID)

		if CombatTrackerData[GUID] and CombatTrackerData[GUID].DS then  
			return CombatTrackerSummTableByTime(CombatTrackerData[GUID].DS, TMW.time - (X or 5)) 
		end
		return 0	
	end, 
	--[[ Get RealTime DMG Taken ]]
	GetRealTimeDMG								= function(self, unitID)
		local total, Hits, phys, magic, swing 	= 0, 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)

		if combatTime > 0 and TMW.time - CombatTrackerData[GUID].DMG_lastHit_taken <= A_GetGCD() * 2 + 1 then   
			Hits 		= CombatTrackerData[GUID].RealDMG_hits_taken        
			if Hits > 0 then                     
				total 	= CombatTrackerData[GUID].RealDMG_dmgTaken / Hits
				phys 	= CombatTrackerData[GUID].RealDMG_dmgTaken_P / Hits
				magic 	= CombatTrackerData[GUID].RealDMG_dmgTaken_M / Hits     
				swing 	= CombatTrackerData[GUID].RealDMG_dmgTaken_S / Hits 
			end
		end
		return total, Hits, phys, magic, swing
	end,
	--[[ Get RealTime DMG Done ]]	
	GetRealTimeDPS								= function(self, unitID)
		local total, Hits, phys, magic, swing 	= 0, 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)

		if combatTime > 0 and TMW.time - CombatTrackerData[GUID].DMG_lastHit_done <= A_GetGCD() * 2 + 1 then   
			Hits 		= CombatTrackerData[GUID].RealDMG_hits_done
			if Hits > 0 then                         
				total 	= CombatTrackerData[GUID].RealDMG_dmgDone / Hits
				phys 	= CombatTrackerData[GUID].RealDMG_dmgDone_P / Hits
				magic 	= CombatTrackerData[GUID].RealDMG_dmgDone_M / Hits  
				swing 	= CombatTrackerData[GUID].RealDMG_dmgDone_S / Hits 
			end
		end
		return total, Hits, phys, magic, swing
	end,	
	--[[ Get DMG Taken ]]
	GetDMG										= function(self, unitID)
		local total, Hits, phys, magic 			= 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)

		if combatTime > 0 and TMW.time - CombatTrackerData[GUID].DMG_lastHit_taken <= 5 then
			total 	= CombatTrackerData[GUID].DMG_dmgTaken / combatTime
			phys 	= CombatTrackerData[GUID].DMG_dmgTaken_P / combatTime
			magic 	= CombatTrackerData[GUID].DMG_dmgTaken_M / combatTime
			Hits 	= CombatTrackerData[GUID].DMG_hits_taken or 0			
		end
		return total, Hits, phys, magic 
	end,
	--[[ Get DMG Done ]]
	GetDPS										= function(self, unitID)
		local total, Hits, phys, magic 			= 0, 0, 0, 0
		local GUID 								= GetGUID(unitID)

		if CombatTrackerData[GUID] and TMW.time - CombatTrackerData[GUID].DMG_lastHit_done <= 5 then
			Hits 		= CombatTrackerData[GUID].DMG_hits_done        
			if Hits > 0 then
				total 	= CombatTrackerData[GUID].DMG_dmgDone / Hits
				phys 	= CombatTrackerData[GUID].DMG_dmgDone_P / Hits
				magic 	= CombatTrackerData[GUID].DMG_dmgDone_M / Hits            
			end
		end
		return total, Hits, phys, magic
	end,
	--[[ Get Heal Taken ]]
	GetHEAL										= function(self, unitID)
		local total, Hits 						= 0, 0
		local GUID 								= GetGUID(unitID)

		if CombatTrackerData[GUID] and TMW.time - CombatTrackerData[GUID].HPS_heal_lasttime <= 5 then
			Hits 		= CombatTrackerData[GUID].HPS_heal_hits_taken
			if Hits > 0 then				
				total 	= CombatTrackerData[GUID].HPS_heal_taken / Hits                              
			end
		end
		return total, Hits     
	end,
	--[[ Get Heal Done ]]	
	GetHPS										= function(self, unitID)
		local total, Hits 						= 0, 0
		local GUID 								= GetGUID(unitID)   

		if CombatTrackerData[GUID] then
			Hits = CombatTrackerData[GUID].HPS_heal_hits_done
			if Hits > 0 then             
				total = CombatTrackerData[GUID].HPS_heal_done / Hits 
			end
		end
		return total, Hits       
	end,	
	-- [[ Get School Damage Taken (by @player only) ]]
	GetSchoolDMG								= function(self, unitID)
		-- @return number
		-- [1] Holy 
		-- [2] Fire 
		-- [3] Nature 
		-- [4] Frost 
		-- [5] Shadow 
		-- [6] Arcane 
		local Holy, Fire, Nature, Frost, Shadow, Arcane = 0, 0, 0, 0, 0, 0
		local combatTime, GUID 					= self:CombatTime(unitID)
		
		if combatTime > 0 and CombatTrackerData[GUID].School then
			local timestamp = TMW.time
			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Holy_LH <= 5 then
				Holy = CombatTrackerData[GUID].School.DMG_dmgTaken_Holy / combatTime
			end 
			
			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Fire_LH <= 5 then
				Fire = CombatTrackerData[GUID].School.DMG_dmgTaken_Fire / combatTime
			end 
			
			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Nature_LH <= 5 then
				Nature = CombatTrackerData[GUID].School.DMG_dmgTaken_Nature / combatTime
			end 
			
			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Frost_LH <= 5 then
				Frost = CombatTrackerData[GUID].School.DMG_dmgTaken_Frost / combatTime
			end 
			
			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Shadow_LH <= 5 then
				Shadow = CombatTrackerData[GUID].School.DMG_dmgTaken_Shadow / combatTime
			end 
			
			if timestamp - CombatTrackerData[GUID].School.DMG_dmgTaken_Arcane_LH <= 5 then
				Arcane = CombatTrackerData[GUID].School.DMG_dmgTaken_Arcane / combatTime
			end 
		end 
		return Holy, Fire, Nature, Frost, Shadow, Arcane
	end,
	--[[ Get Spell Amount Taken (if was taken) in the last X seconds ]]
	GetSpellAmountX								= function(self, unitID, spell, X) 
		local GUID 								= GetGUID(unitID)    

		if type(spell) == "number" then 
			spell = A_GetSpellInfo(spell)
		end 
		if CombatTrackerData[GUID] and CombatTrackerData[GUID].spell_value and CombatTrackerData[GUID].spell_value[spell] and TMW.time - CombatTrackerData[GUID].spell_value[spell].TIME <= (X or 5) then
			return CombatTrackerData[GUID].spell_value[spell].Amount
		end		
		return 0  
	end,
	--[[ Get Spell Amount Taken last time (if didn't called upper function with timer) ]]
	GetSpellAmount								= function(self, unitID, spell)
		local GUID 								= GetGUID(unitID) 

		if type(spell) == "number" then 
			spell = A_GetSpellInfo(spell)
		end 		
		return (CombatTrackerData[GUID] and CombatTrackerData[GUID].spell_value and CombatTrackerData[GUID].spell_value[spell] and CombatTrackerData[GUID].spell_value[spell].Amount) or 0
	end,	
	--[[ This is tracks CLEU spells only if they was applied/missed/reflected e.g. received in any form by end unit to feedback that info ]]
	--[[ Instead of this function for spells which have flying but wasn't received by end unit, since spell still in the fly, you need use A.UnitCooldown ]]
	-- Note: Only @player self and in PvP any players 	
	GetSpellLastCast 							= function(self, unitID, spell)
		-- @return number, number 
		-- time in seconds since last cast, timestamp of start 
		local GUID 								= GetGUID(unitID) 

		if type(spell) == "number" then 
			spell = A_GetSpellInfo(spell)
		end 		
		if CombatTrackerData[GUID] and CombatTrackerData[GUID].spell_lastcast_time and CombatTrackerData[GUID].spell_lastcast_time[spell] then 
			local start = CombatTrackerData[GUID].spell_lastcast_time[spell]
			return TMW.time - start, start 
		end 
		return huge, 0 
	end,
	--[[ Get Count Spell of total used during fight ]]
	-- Note: Only @player self and in PvP any players 
	GetSpellCounter								= function(self, unitID, spell)
		local GUID 								= GetGUID(unitID)
		
		if type(spell) == "number" then 
			spell = A_GetSpellInfo(spell)
		end 		
		if CombatTrackerData[GUID] and CombatTrackerData[GUID].spell_counter then
			return CombatTrackerData[GUID].spell_counter[spell] or 0
		end 
		return 0
	end,
	--[[ Get Absorb Taken ]]
	-- Note: Only players or controlled by players (pets)
	GetAbsorb									= function(self, unitID, spell)
		local GUID	 							= GetGUID(unitID)

		if type(spell) == "number" then 
			spell = A_GetSpellInfo(spell)
		end 		
		if GUID and CombatTrackerData[GUID] and CombatTrackerData[GUID].absorb_spells then 
			if spell then 		
				local absorb = CombatTrackerData[GUID].absorb_spells[spell] or 0
				if absorb <= 0 then 
					absorb = abs(A_Unit(unitID):AuraVariableNumber(spell, "HELPFUL"))
				end 
				
				return absorb
			else
				return CombatTrackerData[GUID].absorb_total or 0
			end 
		end 
			
		return 0
	end,
	--[[ Get DR: Diminishing (only enemy) ]]
	GetDR 										= function(self, unitID, drCat)
		-- @return: DR_Tick (@number), DR_Remain (@number: 0 -> 18), DR_Application (@number: 0 -> 5), DR_ApplicationMax (@number: 5 <-> 0)
		-- DR_Tick is Tick (number: 100 -> 50 -> 25 -> 0) where 0 is fully imun, 100 is no imun
		-- "taunt" has unique Tick (number: 100 -> 65 -> 42 -> 27 -> 0)
		-- DR_Remain is remain in seconds time before DR_Application will be reset
		-- DR_Application is how much DR stacks were applied currently and DR_ApplicationMax is how much by that category can be applied in total 
		--[[ drCat accepts:
			"disorient"						-- TBC Retail
			"incapacitate"					-- Any
			"silence"						-- WOTLK+ Retail
			"stun"							-- Any
			"random_stun"					-- non-Retail 
			"taunt"							-- Retail 
			"root"							-- Any 
			"random_root"					-- non-Retail
			"disarm"						-- Classic+ Retail
			"knockback"						-- Retail
			"counterattack"					-- TBC+ non-Retail
			"chastise"						-- TBC 
			"kidney_shot"					-- Classic TBC 
			"unstable_affliction"			-- TBC 
			"death_coil"					-- TBC 
			"fear"							-- Classic+ non-Retail
			"mind_control"					-- Classic+ non-Retail 
			"horror"						-- WOTLK+ non-Retail
			"opener_stun"					-- WOTLK 
			"scatter"						-- TBC+ non-Retail
			"cyclone"						-- WOTLK+ non-Retail
			"charge"						-- WOTLK 
			"deep_freeze_rof"				-- CATA+ non-Retail
			"bind_elemental"				-- CATA+ non-Retail
			"frost_shock"					-- Classic 
			
			non-Player unitID considered as PvE spells and accepts only: 
			"stun", "kidney_shot"						-- Classic 
			"stun", "random_stun", "kidney_shot"		-- TBC 
			"stun", "random_stun", "opener_stun"		-- WOTLK 
			"stun", "random_stun", "cyclone"			-- CATA 
			"taunt", "stun"								-- Retail 
			
			Same note should be kept in Unit(unitID):IsControlAble, Unit(unitID):GetDR(), CombatTracker.GetDR(unitID)
		]]
		local GUID 								= GetGUID(unitID)		
		local DR 								= CombatTrackerData[GUID] and CombatTrackerData[GUID].DR and CombatTrackerData[GUID].DR[drCat]
		if DR and DR.reset and DR.reset >= TMW.time then 
			return DR.diminished, DR.reset - TMW.time, DR.application, DR.applicationMax
		end 
		
		return 100, 0, 0, 0	
	end, 
	--[[ Time To Die ]]
	TimeToDieX									= function(self, unitID, X)
		local UNIT 								= unitID or "target"
		local ttd 								= 500
		
		-- Training dummy totems exception
		if A.Zone ~= "none" or not A_Unit(UNIT):IsDummy() then 
			local health 						= A_CombatTracker:UnitHealth(UNIT)
			local DMG, Hits 					= self:GetDMG(UNIT)
			
			-- We need "health > 0" condition to ensure that the unit is still alive
			if DMG >= 1 and Hits > 1 and health > 0 then		
				ttd = (health - ( A_CombatTracker:UnitHealthMax(UNIT) * (X / 100) )) / DMG
				-- ToDo: Probably this condition will fix negative numbers, if so then remove it on v2
				if ttd <= 0 then 
					return 500
				end 				
			end 
		end		
		
		return ttd
	end,
	TimeToDie									= function(self, unitID)
		local UNIT 								= unitID or "target"		
		local ttd 								= 500		

		-- Training dummy totems exception
		if A.Zone ~= "none" or not A_Unit(UNIT):IsDummy() then 
			local health 						= A_CombatTracker:UnitHealth(UNIT)
			local DMG, Hits 					= self:GetDMG(UNIT)
			
			-- We need "health > 0" condition to ensure that the unit is still alive
			if DMG >= 1 and Hits > 1 and health > 0 then
				ttd = health / DMG
				-- ToDo: Probably this condition will fix negative numbers, if so then remove it on v2
				if ttd <= 0 then 
					return 500
				end 				
			end 
		end

		return ttd
	end,
	TimeToDieMagicX								= function(self, unitID, X)
		local UNIT 								= unitID or "target"		
		local ttd 								= 500
		
		-- Training dummy totems exception
		if A.Zone ~= "none" or not A_Unit(UNIT):IsDummy() then 
			local health 						= A_CombatTracker:UnitHealth(UNIT)
			local _, Hits, _, DMG 				= self:GetDMG(UNIT)
			
			-- We need "health > 0" condition to ensure that the unit is still alive
			if DMG >= 1 and Hits > 1 and health > 0 then		
				ttd = (health - ( A_CombatTracker:UnitHealthMax(UNIT) * (X / 100) )) / DMG
				-- ToDo: Probably this condition will fix negative numbers, if so then remove it on v2
				if ttd <= 0 then 
					return 500
				end 				
			end 
		end		
		
		return ttd		
	end,
	TimeToDieMagic								= function(self, unitID)
		local UNIT 								= unitID or "target"
		local ttd 								= 500		

		-- Training dummy totems exception
		if A.Zone ~= "none" or not A_Unit(UNIT):IsDummy() then 
			local health 						= A_CombatTracker:UnitHealth(UNIT)
			local _, Hits, _, DMG 				= self:GetDMG(UNIT)
			
			-- We need "health > 0" condition to ensure that the unit is still alive
			if DMG >= 1 and Hits > 1 and health > 0 then
				ttd = health / DMG
				-- ToDo: Probably this condition will fix negative numbers, if so then remove it on v2
				if ttd <= 0 then 
					return 500
				end 				
			end 
		end

		return ttd		
	end,
	--[[ Debug Real Health ]]
	Debug 										= function(self, command)
		local cmd = command:lower()
		if cmd == "wipe" then 
			local GUID = GetGUID("target")
			if GUID then 
				RealUnitHealthDamageTaken[GUID] = nil 
				RealUnitHealthCachedHealthMax[GUID] = nil 
				RealUnitHealthisHealthWasMaxOnGUID[GUID] = nil 
				RealUnitHealthCachedHealthMaxTemprorary[GUID] = nil 
				RealUnitHealthSavedHealthPercent[GUID] = nil 
				logDefaultGUIDatMaxHealthTarget()
			end 
		elseif cmd == "data" then 
			return RealUnitHealth
		end 
	end, 
}

-------------------------------------------------------------------------------
-- API: UnitCooldown
-------------------------------------------------------------------------------
A.UnitCooldown 									= {
	Register							= function(self, spellName, timer, isFriendlyArg, inPvPArg, CLEUbl)	
		-- isFriendlyArg, inPvPArg are optional		
		-- CLEUbl is a table = { ['Event_CLEU'] = true, } which to skip and don't reset by them in fly
		if type(spellName) == "number" then 
			spellName = A_GetSpellInfo and A_GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		if UnitTrackerIsBlink[spellName] then 
			A.Print("[Error] Can't register Blink or Shrimmer because they are already registered. Please use function Action.UnitCooldown:GetBlinkOrShrimmer(unitID)")
			return 
		end 		
		
		local inPvP 	 = inPvPArg 
		local isFriendly = isFriendlyArg
		
		UnitTracker.isRegistered[spellName] = { isFriendly = isFriendly, inPvP = inPvP, Timer = timer, blackListCLEU = CLEUbl } 	
	end,
	UnRegister							= function(self, spellName)	
		if type(spellName) == "number" then 
			spellName = A_GetSpellInfo and A_GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		UnitTracker.isRegistered[spellName] = nil 
		wipe(UnitTrackerData)
	end,		
	GetCooldown							= function(self, unit, spellName)		
		-- @return number, number (remain cooldown time in seconds, start time stamp when spell was used and counter launched)
		if type(spellName) == "number" then 
			spellName = A_GetSpellInfo and A_GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		if unit == "any" or unit == "enemy" or unit == "friendly" then 
			for _, v in pairs(UnitTrackerData) do 
				if v[spellName] and v[spellName].expire and (unit == "any" or (unit == "enemy" and v[spellName].enemy) or (unit == "friendly" and not v[spellName].enemy)) then 
					return math_max(v[spellName].expire - TMW.time, 0), v[spellName].start
				end 
			end 
		elseif unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = GetGUID(unitID)
				if not GUID then 
					if unit == "party" or i >= GetGroupMaxSize(unit) then  
						break 
					end   
				elseif UnitTrackerData[GUID] and UnitTrackerData[GUID][spellName] and UnitTrackerData[GUID][spellName].expire then 
					return math_max(UnitTrackerData[GUID][spellName].expire - TMW.time, 0), UnitTrackerData[GUID][spellName].start
				end 				
			end 
		else 
			local GUID = GetGUID(unit)
			if GUID and UnitTrackerData[GUID] and UnitTrackerData[GUID][spellName] and UnitTrackerData[GUID][spellName].expire then 
				return math_max(UnitTrackerData[GUID][spellName].expire - TMW.time, 0), UnitTrackerData[GUID][spellName].start
			end 	
		end
		return 0, 0
	end,
	GetMaxDuration						= function(self, unit, spellName)
		-- @return number (max cooldown of the spell on a unit)
		if type(spellName) == "number" then 
			spellName = A_GetSpellInfo and A_GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		if unit == "any" or unit == "enemy" or unit == "friendly" then 
			for _, v in pairs(UnitTrackerData) do 
				if v[spellName] and v[spellName].expire and (unit == "any" or (unit == "enemy" and v[spellName].enemy) or (unit == "friendly" and not v[spellName].enemy)) then 
					return math_max(v[spellName].expire - v[spellName].start, 0)
				end 
			end 
		elseif unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = GetGUID(unitID)
				if not GUID then 
					if unit == "party" or i >= GetGroupMaxSize(unit) then   
						break 
					end 
				elseif UnitTrackerData[GUID] and UnitTrackerData[GUID][spellName] and UnitTrackerData[GUID][spellName].expire then 
					return math_max(UnitTrackerData[GUID][spellName].expire - UnitTrackerData[GUID][spellName].start, 0)
				end 				
			end 
		else 
			local GUID = GetGUID(unit)
			if GUID and UnitTrackerData[GUID] and UnitTrackerData[GUID][spellName] and UnitTrackerData[GUID][spellName].expire then 
				return math_max(UnitTrackerData[GUID][spellName].expire - UnitTrackerData[GUID][spellName].start, 0)
			end 
		end
		return 0		
	end,
	GetUnitID 							= function(self, unit, spellName)
		-- @return unitID (who last casted spell) otherwise nil  
		if type(spellName) == "number" then 
			spellName = A_GetSpellInfo and A_GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		if unit == "any" or unit == "enemy" or unit == "friendly" then 
			for GUID, v in pairs(UnitTrackerData) do 
				if v[spellName] and v[spellName].expire and v[spellName].expire - TMW.time >= 0 and (unit == "any" or (unit == "enemy" and v[spellName].enemy) or (unit == "friendly" and not v[spellName].enemy)) then 
					if unit == "any" or unit == "enemy" then 
						if A.Zone ~= "pvp" then 							
							if ActiveNameplates then 
								for unitID in pairs(ActiveNameplates) do 
									if GUID == UnitGUID(unitID) then -- Not GetGUID(unitID) because it will never be Base members
										return unitID
									end 
								end 
							end 
						else
							for i = 1, TeamCacheEnemy.MaxSize do 
								if TeamCacheEnemyIndexToPLAYERs[i] and GUID == TeamCacheEnemyUNITs[TeamCacheEnemyIndexToPLAYERs[i]] then 
									return TeamCacheEnemyIndexToPLAYERs[i]
								end 
							end 
						end 
					end 
					
					if (unit == "any" or unit == "friendly") and TeamCacheFriendly.Type then 
						for i = 1, TeamCacheFriendly.MaxSize do 
							if TeamCacheFriendlyIndexToPLAYERs[i] and GUID == TeamCacheFriendlyUNITs[TeamCacheFriendlyIndexToPLAYERs[i]] then 
								return TeamCacheFriendlyIndexToPLAYERs[i]
							end 
						end 
					end 
				end 
			end 
		elseif unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = GetGUID(unitID)
				if not GUID then 
					if unit == "party" or i >= GetGroupMaxSize(unit) then   
						break 
					end  
				elseif UnitTrackerData[GUID] and UnitTrackerData[GUID][spellName] and UnitTrackerData[GUID][spellName].expire and UnitTrackerData[GUID][spellName].expire - TMW.time >= 0 then 
					return unitID
				end
			end 
		end 
	end,
	--[[ Mage Shrimmer/Blink Tracker (only enemy) ]]
	GetBlinkOrShrimmer					= function(self, unit)
		-- @return number, number, number 
		-- [1] Current Charges, [2] Current Cooldown, [3] Summary Cooldown     			
		local charges, cooldown, summary_cooldown = 1, 0, 0  
		if unit == "any" or unit == "enemy" or unit == "friendly" then 
			for _, v in pairs(UnitTrackerData) do 
				if v.Shrimmer then 
					charges = 2
					for i = #v.Shrimmer, 1, -1 do
						cooldown = v.Shrimmer[i] - TMW.time
						if cooldown > 0 then
							charges = charges - 1
							summary_cooldown = summary_cooldown + cooldown												
						end            
					end 
					break 
				elseif v.Blink then 
					cooldown = v.Blink - TMW.time
					if cooldown <= 0 then 
						cooldown = 0 
					else 
						charges = 0
						summary_cooldown = cooldown
					end 
					break 
				end 
			end 
		elseif unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = GetGUID(unitID)
				if not GUID then 
					if unit == "party" or i >= GetGroupMaxSize(unit) then   
						break 
					end   
				elseif UnitTrackerData[GUID] then 
					if UnitTrackerData[GUID].Shrimmer then 
						charges = 2
						for i = #UnitTrackerData[GUID].Shrimmer, 1, -1 do
							cooldown = UnitTrackerData[GUID].Shrimmer[i] - TMW.time
							if cooldown > 0 then
								charges = charges - 1
								summary_cooldown = summary_cooldown + cooldown												
							end            
						end 
						break 
					elseif UnitTrackerData[GUID].Blink then 
						cooldown = UnitTrackerData[GUID].Blink - TMW.time
						if cooldown <= 0 then 
							cooldown = 0 
						else 
							charges = 0
							summary_cooldown = cooldown
						end 
						break 
					end 
				end 				
			end 
		else 
			local GUID = GetGUID(unit)
			if GUID and UnitTrackerData[GUID] then 
				if UnitTrackerData[GUID].Shrimmer then 
					charges = 2
					for i = #UnitTrackerData[GUID].Shrimmer, 1, -1 do
						cooldown = UnitTrackerData[GUID].Shrimmer[i] - TMW.time
						if cooldown > 0 then
							charges = charges - 1
							summary_cooldown = summary_cooldown + cooldown												
						end            
					end 					
				elseif UnitTrackerData[GUID].Blink then 
					cooldown = UnitTrackerData[GUID].Blink - TMW.time
					if cooldown <= 0 then 
						cooldown = 0 
					else 
						charges = 0
						summary_cooldown = cooldown
					end 					 
				end 
			end 		
		end
		return charges, cooldown, summary_cooldown	
	end, 
	--[[ Is In Flying Spells Tracker ]]
	IsSpellInFly						= function(self, unit, spellName)
		-- @return boolean 
		if type(spellName) == "number" then 
			spellName = A_GetSpellInfo and A_GetSpellInfo(spellName) or GetSpellInfo(spellName)
		end 
		
		if unit == "any" or unit == "enemy" or unit == "friendly" then 
			for _, v in pairs(UnitTrackerData) do 
				if v[spellName] and v[spellName].isFlying and (unit == "any" or (unit == "enemy" and v[spellName].enemy) or (unit == "friendly" and not v[spellName].enemy)) then 
					if TMW.time - v[spellName].start > UnitTrackerMaxResetFlyingTimer then 
						v[spellName].isFlying = false 
					end 
					return v[spellName].isFlying
				end 
			end 
		elseif unit == "arena" or unit == "raid" or unit == "party" then 
			for i = 1, (unit == "party" and 4 or 40) do 
				local unitID = unit .. i
				local GUID = GetGUID(unitID)
				if not GUID then 
					if unit == "party" or i >= GetGroupMaxSize(unit) then   
						break 
					end   
				elseif UnitTrackerData[GUID] and UnitTrackerData[GUID][spellName] and UnitTrackerData[GUID][spellName].isFlying then 
					if TMW.time - UnitTrackerData[GUID][spellName].start > UnitTrackerMaxResetFlyingTimer then 
						UnitTrackerData[GUID][spellName].isFlying = false 
					end 
					return UnitTrackerData[GUID][spellName].isFlying
				end 				
			end 
		else 
			local GUID = GetGUID(unit)
			if GUID and UnitTrackerData[GUID] and UnitTrackerData[GUID][spellName] then 
				if UnitTrackerData[GUID][spellName].isFlying then 
					if TMW.time - UnitTrackerData[GUID][spellName].start > UnitTrackerMaxResetFlyingTimer then 
						UnitTrackerData[GUID][spellName].isFlying = false 
					end 
					return UnitTrackerData[GUID][spellName].isFlying
				--elseif TMW.time - UnitTrackerData[GUID][spellName].start < 0.2 then 
					-- CLEU reser earlier than UNIT_SPELLCAST_SUCCEEDED and UNIT_SPELLCAST_SUCCEEDED fires after CLEU one more time 
					--return true 
				end 
			end 
		end 
	end,
}
 
-- Tracks Freezing Trap 
A.UnitCooldown:Register(CONST.SPELLID_FREEZING_TRAP, 30)
A.UnitCooldown:Register(CONST.SPELLID_FREEZING_TRAP2, 30)

-------------------------------------------------------------------------------
-- API: LossOfControl
-------------------------------------------------------------------------------
A.LossOfControl									= {
	Get											= function(self,  locType, name)
		-- @return number (remain duration in seconds of LossOfControl), number (textureID)
		-- Note: For external usage (not frame!)
		if LossOfControlData[locType] then 
			if name then 
				if LossOfControlData[locType][name] then 
					return math_max(LossOfControlData[locType][name].Result - TMW.time, 0), LossOfControlData[locType][name].TextureID 
				end 
			else 
				return math_max(LossOfControlData[locType].Result - TMW.time, 0), LossOfControlData[locType].TextureID 
			end 
		end 
		
		return 0, 0 
	end, 
	IsMissed									= function(self, MustBeMissed)
		-- @return boolean 
		local result = true
		if type(MustBeMissed) == "table" then 
			for i = 1, #MustBeMissed do 
				if self:Get(MustBeMissed[i]) > 0 then 
					result = false  
					break 
				end
			end
		else
			result = self:Get(MustBeMissed) == 0
		end 
		return result 
	end,
	IsValid										= function(self, MustBeApplied, MustBeMissed, Exception)
		-- @return boolean (if result is fully okay), boolean (if result is not okay but we can pass it to use another things as remove control)
		local isApplied = false 
		local result = isApplied
		
		for i = 1, #MustBeApplied do 
			if self:Get(MustBeApplied[i]) > 0 then 
				isApplied = true 
				result = isApplied
				break 
			end 
		end 
		
		-- Exception 
		if Exception and not isApplied then 
			-- Dwarf in DeBuffs
			if A.PlayerRace == "Dwarf" then 
				isApplied = A_Unit("player"):HasDeBuffs("Poison") > 0 -- or A_Unit("player"):HasDeBuffs("Disease") > 0 or or A_Unit("player"):HasDeBuffs("Bleeding") > 0 -- these 2 is not added in Unit.lua 
			end
		end 
		
		if isApplied and MustBeMissed then 
			for i = 1, #MustBeMissed do 
				if self:Get(MustBeMissed[i]) > 0 then 
					result = false 
					break 
				end
			end
		end 
		
		return result, isApplied
	end,
	GetExtra 									= {
		["Dwarf"] 								= {
			Applied 							= {"SLEEP"}, 
			Missed 								= {"POLYMORPH", "INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "STUN", "FEAR", "HORROR", "CHARM", "SHACKLE_UNDEAD", "TURN_UNDEAD"},
		},
		["Scourge"] 							= {
			Applied 							= {"FEAR", "HORROR", "SLEEP", "CHARM"}, -- FIX ME: "HORROR" is it works (?)
			Missed 								= {"INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "STUN", "SHACKLE_UNDEAD", "ROOT"}, 
		},
		["Gnome"]	 							= {
			Applied 							= {"ROOT", "SNARE", "DAZE"}, -- Need summary for: "DAZE" 
			Missed 								= {"INCAPACITATE", "DISORIENT", "FREEZE", "SILENCE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "SLEEP", "STUN", "SHACKLE_UNDEAD", "FEAR", "HORROR", "CHARM", "TURN_UNDEAD"},
		},		
	},	
	--[[TestFrameData								= function(self, duration, textureID)
		-- Note: For test only to simulate conditions on frames. If arguments are omit then will be used for test Shield Bash 
		LossOfControlFrameData.Order			= 3
		LossOfControlFrameData.Result 			= TMW.time + (duration or 6)
		LossOfControlFrameData.TextureID 		= textureID or 132357
		TMW:Fire("TMW_ACTION_LOSS_OF_CONTROL_UPDATE")
	end,
	TestFrameReset								= function(self)
		LossOfControl:Reset()
	end,]]
	UpdateFrameData 							= function(self)
		-- Note: Used for manually update frame (in case if checkbox in UI was activaed while loss of control receive)
		LossOfControlFrameData.Order			= 0 
		LossOfControlFrameData.Result 			= 0
		LossOfControlFrameData.TextureID 		= 0
		LossOfControl:OnFrameSortData()
	end, 
	GetFrameData								= function(self)
		-- @return number (textureID), number (remain duration), number (expirationTime of control)
		-- Note: Used for frames with sorted by order to display CURRENT high priority loss of control. 0 for both in case if nothing isn't applied 
		return LossOfControlFrameData.TextureID, math_max(LossOfControlFrameData.Result - TMW.time, 0), LossOfControlFrameData.Result
	end,
	GetFrameOrder 								= function(self)
		-- @return number (priority 1 - heavy, 2 - medium, 3 - light, 0 - no control)		
		return LossOfControlFrameData.Order
	end,
	IsEnabled									= function(self, frame_type)
		-- @return boolean 
		-- Note: Used for frames to determine which should be shown
		if A.IsInitialized then 
			if frame_type == "PlayerFrame" then 
				return GetToggle(1, "LossOfControlPlayerFrame")
			else 
				return GetToggle(1, "LossOfControlRotationFrame")
			end 
		end 
	end,
}