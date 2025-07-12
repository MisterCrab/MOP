---------------------------------------------------
--------------- CUSTOM PREV SPELLS ----------------
---------------------------------------------------
local _G, table, pairs, type, math         	= _G, table, pairs, type, math
local wipe 									= _G.wipe
local tinsert                          		= table.insert
local math_max								= math.max

local TMW 									= _G.TMW
local A                                     = _G.Action
local CONST 								= A.Const
local Listener								= A.Listener
local EnumTriggerGCD 						= A.Enum.TriggerGCD 
local TeamCacheFriendly						= A.TeamCache.Friendly
local TeamCacheFriendlyUNITs				= TeamCacheFriendly.UNITs 			-- unitID to GUID 
local TeamCacheFriendlyGUIDs				= TeamCacheFriendly.GUIDs 			-- GUID to unitID 
local Print 								= A.Print
local Unit                                  = A.Unit 
local Player								= A.Player 
local Pet                                   = _G.LibStub("PetLibrary")

local StdUi									= A.StdUi
local isClassic								= StdUi.isClassic 
local owner									= isClassic and "PlayerClass" or "PlayerSpec"

local GetNumSpecializationsForClassID, GetSpecializationInfo
if not isClassic then 
	GetNumSpecializationsForClassID			= _G.GetNumSpecializationsForClassID
	GetSpecializationInfo					= _G.GetSpecializationInfo
end 

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_GetSpellInfo, A_GetGCD
Listener:Add("ACTION_EVENT_PREV_SPELLS", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then 		
		A_GetSpellInfo						= A.GetSpellInfo 
		A_GetGCD							= A.GetGCD
		Listener:Remove("ACTION_EVENT_PREV_SPELLS", "ADDON_LOADED")	
	end 
end)
-------------------------------------------------------------------------------

local CombatLogGetCurrentEventInfo			= _G.CombatLogGetCurrentEventInfo
local LastSpellName, LastSpellBy

-- File Locals
local TriggerGCD 							= {}								-- TriggerGCD table until it has been filtered
local LastRecord 							= 15 								-- Number of recorded spells
local PrevGCDPredicted 						= 0
local PrevGCDCastTime 						= 0
local PrevOffGCDCastTime 					= 0
local Prev 									= {
    GCD 									= {},
    OffGCD 									= {},
    PetGCD 									= {},
    PetOffGCD 								= {},
}
local Custom 								= {
    Whitelist 								= {},
    Blacklist 								= {},
}
local PrevSuggested 						= {
	Spell 									= nil,
	Time	 								= 0,
}

-- Init all the records at 0, so it saves one check on PrevGCD method.
for i = 1, LastRecord do
	for _, Table in pairs(Prev) do
		tinsert(Table, 0)
	end
end

-- Clear Old Records
local function RemoveOldRecords()
    for _, Table in pairs(Prev) do
        local n = #Table
        while n > LastRecord do
            Table[n] = nil
            n = n - 1
        end
    end
end

local function COMBAT_LOG_EVENT_UNFILTERED(...)	 	
	local _, Event, _, SourceGUID, _, SourceFlags, _, DestGUID, DestName, DestFlags, _, _, SpellName = CombatLogGetCurrentEventInfo()
	
	local Caster = SourceGUID == TeamCacheFriendlyUNITs.player and "Player" or SourceGUID == TeamCacheFriendlyUNITs.pet and "Pet"	
	if not Caster then 
		return 
	end 
	
	-- On Cast Success Listener
    if Event == "SPELL_CAST_SUCCESS" and not (LastSpellName == SpellName and LastSpellBy == "UNIT_SPELLCAST_SUCCEEDED") then 
		if TriggerGCD[SpellName] ~= nil then		
			LastSpellName = SpellName
			LastSpellBy = "COMBAT_LOG_EVENT_UNFILTERED"
			
			if Caster == "Player" then
				-- Player
				if TriggerGCD[SpellName] then 
					tinsert(Prev.GCD, 1, SpellName)
					PrevGCDCastTime = TMW.time 
					wipe(Prev.OffGCD)
					tinsert(Prev.OffGCD, 0)
					PrevOffGCDCastTime = 0
					PrevGCDPredicted = 0
				else 
					-- Prevents unwanted spells to be registered as OffGCD	
					tinsert(Prev.OffGCD, 1, SpellName)	
					PrevOffGCDCastTime = TMW.time
					PrevGCDCastTime = 0	
				end 
			else
				-- Pet 
				if TriggerGCD[SpellName] then
					tinsert(Prev.PetGCD, 1, SpellName)
					wipe(Prev.PetOffGCD)
					tinsert(Prev.PetOffGCD, 0)
				else 
					-- Prevents unwanted spells to be registered as OffGCD.
					tinsert(Prev.PetOffGCD, 1, SpellName)
				end		    
			end
			
			RemoveOldRecords()
		end  					
    end

    -- Player Start Cast prediction
    if Event == "SPELL_CAST_START" and Caster == "Player" and TriggerGCD[SpellName] then
        PrevGCDPredicted = SpellName
    end

    -- Player Cast Failed prediction
    if Event == "SPELL_CAST_FAILED" and Caster == "Player" and PrevGCDPredicted == SpellName then
        PrevGCDPredicted = 0
    end
end

local function UNIT_SPELLCAST_SUCCEEDED(unitID, _, spellID)
	local Caster = unitID == "player" and "Player" or unitID == "pet" and "Pet"	
	if not Caster then 
		return 
	end 
	
	local SpellName = A_GetSpellInfo(spellID)
	if TriggerGCD[SpellName] ~= nil and not (LastSpellName == SpellName and LastSpellBy == "COMBAT_LOG_EVENT_UNFILTERED") then	
		LastSpellName = SpellName
		LastSpellBy = "UNIT_SPELLCAST_SUCCEEDED"
		
		if Caster == "Player" then
			-- Player
			if TriggerGCD[SpellName] then 
				tinsert(Prev.GCD, 1, SpellName)
				PrevGCDCastTime = TMW.time 
				wipe(Prev.OffGCD)
				tinsert(Prev.OffGCD, 0)
				PrevOffGCDCastTime = 0
				PrevGCDPredicted = 0
			else 
				-- Prevents unwanted spells to be registered as OffGCD	
				tinsert(Prev.OffGCD, 1, SpellName)	
				PrevOffGCDCastTime = TMW.time
				PrevGCDCastTime = 0	
			end 
		else
			-- Pet 
			if TriggerGCD[SpellName] then
				tinsert(Prev.PetGCD, 1, SpellName)
				wipe(Prev.PetOffGCD)
				tinsert(Prev.PetOffGCD, 0)
			else 
				-- Prevents unwanted spells to be registered as OffGCD.
				tinsert(Prev.PetOffGCD, 1, SpellName)
			end		    
		end	
		
		RemoveOldRecords()
	end 
end 

local CheckInitialization, Initialization
CheckInitialization = function()
	if not A.IsInitialized then 	
		Listener:Remove("ACTION_EVENT_PREV_SPELLS", "COMBAT_LOG_EVENT_UNFILTERED")
		Listener:Remove("ACTION_EVENT_PREV_SPELLS", "UNIT_SPELLCAST_SUCCEEDED")
		TMW:UnregisterCallback("TMW_ACTION_ON_PROFILE_POST", 					CheckInitialization, "ACTION_CHECK_INITIALIZATION_PREV_SPELL")
		TMW:RegisterSelfDestructingCallback("TMW_ACTION_IS_INITIALIZED_PRE",	Initialization)
	end 
end 

Initialization = function()
	Player:FilterTriggerGCD()
	Listener:Add("ACTION_EVENT_PREV_SPELLS", "COMBAT_LOG_EVENT_UNFILTERED",	 	COMBAT_LOG_EVENT_UNFILTERED)
	Listener:Add("ACTION_EVENT_PREV_SPELLS", "UNIT_SPELLCAST_SUCCEEDED", 		UNIT_SPELLCAST_SUCCEEDED)
	TMW:RegisterCallback("TMW_ACTION_ON_PROFILE_POST", 							CheckInitialization, "ACTION_CHECK_INITIALIZATION_PREV_SPELL")
	return true -- Signal RegisterSelfDestructingCallback to unregister
end 
TMW:RegisterSelfDestructingCallback("TMW_ACTION_IS_INITIALIZED_PRE", 			Initialization)

------------------------------------
--------------- API ----------------
------------------------------------
-- Filter the Enum TriggerGCD table to keep only registered spells for a given class (based on SpecID).
function Player:FilterTriggerGCD()
	wipe(TriggerGCD)
	
	local spellName, spellID, _
	if not isClassic then 		
		local specID
		for i = 1, GetNumSpecializationsForClassID(A.PlayerClassID) do 
			specID = GetSpecializationInfo(i)
			if specID and A[specID] then 
				for actionName, actionValue in pairs(A[specID]) do 
					if type(actionValue) == "table" and actionValue.Type then 
						spellName, spellID = nil, nil
						if actionValue.Type == "Spell" then 
							spellID = actionValue.ID
						elseif actionValue.Type:match("Item") or actionValue.Type:match("Trinket") then 
							spellName, spellID = actionValue:GetItemSpell()
						end 	
							
						if spellID and EnumTriggerGCD[spellID] then 
							if actionValue.Type == "Spell" then 
								spellName = actionValue:Info()
							end 
							
							if spellName then 
								TriggerGCD[spellName] = (EnumTriggerGCD[spellID] > 0)
							end 
						end 
					end 
				end 
			end 
		end	
	elseif A[A[owner]] then 
		for actionName, actionValue in pairs(A[A[owner]]) do 
			if type(actionValue) == "table" and actionValue.Type then 
				spellName, spellID = nil, nil
				if actionValue.Type == "Spell" then 
					spellID = actionValue.ID
				elseif actionValue.Type:match("Item") or actionValue.Type:match("Trinket") then 
					spellName, spellID = actionValue:GetItemSpell()
				end 	
					
				if spellID and EnumTriggerGCD[spellID] then 
					if actionValue.Type == "Spell" then 
						spellName = actionValue:Info()
					end 
					
					if spellName then 
						TriggerGCD[spellName] = (EnumTriggerGCD[spellID] > 0)
					end 
				end 
			end 
		end 
	end 

	-- Add Spells based on the Whitelist
	for spellName, spellValue in pairs(Custom.Whitelist) do
		TriggerGCD[spellName] = spellValue
	end
	
	-- Remove Spells based on the Blacklist
	for spellName in pairs(Custom.Blacklist) do
		TriggerGCD[spellName] = nil 
	end 
end

-- Add actions in the Trigger GCD Whitelist
function A:AddToTriggerGCD(Value)
    if type(Value) ~= "boolean" then Print("You must give a boolean as argument.") end
    Custom.Whitelist[self:Info() or ""] = Value
end

-- Add spells in the Trigger GCD Blacklist 
function A:RemoveFromTriggerGCD()
	Custom.Blacklist[self:Info() or ""] = true
end

-- Time of the last on-GCD SPELL_CAST_SUCCESS
function Player:PrevGCDTime()
	return PrevGCDCastTime
end

-- Time of the last off-GCD SPELL_CAST_SUCCESS
function Player:PrevOffGCDTime()
	return PrevOffGCDCastTime
end

-- Time of the last SPELL_CAST_SUCCESS of any type
function Player:PrevCastTime()
	return math_max(PrevGCDCastTime, PrevOffGCDCastTime)
end

-- Returns if a GCD has been started but we don't yet know what the spell is
function Player:IsPrevCastPending()
	-- If we recieved a SPELL_CAST_START event, we know about the cast
	if PrevGCDPredicted > 0 then
		return false
	end

	-- Otherwise, check to see if the GCD was started after the last known SPELL_CAST_SUCCESS
	if A_GetGCD() > PrevGCDCastTime then
		return true
	end

	return false
end

-- Sets the last known tracked suggestion before the start of the next GCD
function Player:SetPrevSuggestedSpell(SuggestedSpell)
	if SuggestedSpell == nil or SuggestedSpell.SpellID ~= nil then
		-- Don't update the previous suggested spell if we are currently on the GCD
		if A_GetGCD() > PrevGCDCastTime then
			return
		end
		PrevSuggested.Spell = SuggestedSpell
		PrevSuggested.Time = TMW.time 
	end
end

-- prev_gcd.x.foo
function Player:PrevGCD(Index, Spell)
	if Index > LastRecord then Print("Only the last " .. LastRecord .. " GCDs can be checked.") end
	if Spell then
		return Prev.GCD[Index] == Spell:Info()
	else
		return Prev.GCD[Index]
	end
end

-- Player:PrevGCD with cast start prediction
function Player:PrevGCDP(Index, Spell, ForcePred)
	if Index > LastRecord then Print("Only the last " .. (LastRecord) .. " GCDs can be checked.") end

	-- If we don't have a PrevGCDPredicted from SPELL_CAST_START, attempt to use the last suggested spell instead
	-- This is only used when the local GCD has begun but a SPELL_CAST_SUCCESS has not yet fired to determine what the spell is
	local PredictedGCD = PrevGCDPredicted
	if PredictedGCD == 0 and PrevSuggested.Spell and PrevSuggested.Time > PrevGCDCastTime then
		local SpellName = PrevSuggested.Spell:Info()
		if A_GetGCD() > PrevGCDCastTime and TriggerGCD[SpellName] then
			PredictedGCD = SpellName
		end
	end
	
	local bool = type(PredictedGCD) == "string" or PredictedGCD > 0
	if bool and Index == 1 or ForcePred then
		return PredictedGCD == Spell:Info()
	elseif bool then
		return Player:PrevGCD(Index - 1, Spell)
	else
		return Player:PrevGCD(Index, Spell)
	end
end

-- prev_off_gcd.x.foo
function Player:PrevOffGCD(Index, Spell)
	if Index > LastRecord then Print("Only the last " .. LastRecord .. " OffGCDs can be checked.") end
	return Prev.OffGCD[Index] == Spell:Info()
end

-- Player:PrevOffGCD with cast start prediction
function Player:PrevOffGCDP(Index, Spell)
	if Index > LastRecord then Print("Only the last " .. (LastRecord) .. " GCDs can be checked.") end
	if PrevGCDPredicted > 0 and Index == 1 then
		return false
	elseif PrevGCDPredicted > 0 then
		return Player:PrevOffGCD(Index - 1, Spell)
	else
		return Player:PrevOffGCD(Index, Spell)
	end
end

-- "pet.prev_gcd.x.foo"
function Pet:PrevGCD(Index, Spell)
	if Index > LastRecord then Print("Only the last " .. LastRecord .. " GCDs can be checked.") end
	return Prev.PetGCD[Index] == Spell:Info()
end

-- "pet.prev_off_gcd.x.foo"
function Pet:PrevOffGCD(Index, Spell)
	if Index > LastRecord then Print("Only the last " .. LastRecord .. " OffGCDs can be checked.") end
	return Prev.PetOffGCD[Index] == Spell:Info()
end