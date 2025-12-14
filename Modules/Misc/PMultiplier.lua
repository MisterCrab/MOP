-- https://github.com/herotc/hero-lib/blob/thewarwithin/HeroLib/Events/PMultiplier.lua
local _G, error, table, pairs, type = 
	  _G, error, table, pairs, type
	
local TMW 							= _G.TMW
local A 							= _G.Action 
local CONST							= A.Const
local Listener						= A.Listener
local Player 						= A.Player
local Unit							= A.Unit 
local Class 						= A.PlayerClass	  

local tremove						= table.remove
local CombatLogGetCurrentEventInfo 	= _G.CombatLogGetCurrentEventInfo or _G.C_CombatLog.GetCurrentEventInfo
local UnitGUID 						= _G.UnitGUID
	
local ListenedSpells 				= {}
local ListenedAuras 				= {}
local TimeSinceLastRemovedOnPlayer	= {}	
local CLEU

--- ============================ CONTENT ============================
-- Register a spell to watch and his multipliers.
-- Examples:
--
--- Buff + Modifier as a function
-- A.Nightblade:RegisterPMultiplier(
--   {
--     A.FinalityNightblade,
--     function ()
--       if Unit("player"):HasBuffs(A.FinalityNightblade.ID, true) == 0 then return 1 end
--       local Multiplier = select(17, Player:BuffInfo(A.FinalityNightblade, nil, true)) -- not present in The Action API
--
--       return 1 + Multiplier/100
--     end
--   }
-- )
--
--- 3x Buffs & Modifier as a number
-- A.Rip:RegisterPMultiplier({A.BloodtalonsBuff, 1.2}, {A.SavageRoar, 1.15}, {A.TigersFury, 1.15})
-- A.Thrash:RegisterPMultiplier({A.BloodtalonsBuff, 1.2}, {A.SavageRoar, 1.15}, {A.TigersFury, 1.15})
--
--- Different SpellCast & SpellAura + AIO function + 3x Buffs & Modifier as a number
-- A.Rake:RegisterPMultiplier(
--   A.RakeDebuff,
--   function () return Player:IsStealthed() and 2 or 1 end,
--   {A.BloodtalonsBuff, 1.2}, {A.SavageRoar, 1.15}, {A.TigersFury, 1.15}
-- )
function A:RegisterPMultiplier(...)
	local Args = { ... }

	-- Get the SpellID to check on AURA_APPLIED/AURA_REFRESH, should be specified as first arg or it'll take the current spell object.
	local SpellAura = self.ID
	local FirstArg = Args[1]
	if type(FirstArg) == "table" and FirstArg.ID then
		SpellAura = tremove(Args, 1).ID
	end

	ListenedAuras[SpellAura] = self.ID
	ListenedSpells[self.ID] = { Buffs = Args, Units = {} }

	-- Custom Bridge
	Listener:Add("ACTION_EVENT_PMULTIPLIER", "COMBAT_LOG_EVENT_UNFILTERED", CLEU)
end

local function SpellRegisterError(Spell)
    local SpellName = Spell:Info()	
    if SpellName then
        return "You forgot to register the spell: " .. SpellName .. " in PMultiplier handler."
    else
        return "You forgot to register the spell object."
    end
end

-- PMultiplier Calculator
local function ComputePMultiplier(ListenedSpell)
	local PMultiplier = 1
	for j = 1, #ListenedSpell.Buffs do
		local Buff = ListenedSpell.Buffs[j]
		-- Check if it's an AIO function and call it.
		if type(Buff) == "function" then
			PMultiplier = PMultiplier * Buff()
		else
			-- Check if we did registered a Buff to check + a modifier (as a number or through a function).
			local ThisSpell = Buff[1]
			local Modifier = Buff[2]

			if Unit("player"):HasBuffs(ThisSpell.ID, true) > 0 or (TimeSinceLastRemovedOnPlayer[ThisSpell.ID] and TMW.time - TimeSinceLastRemovedOnPlayer[ThisSpell.ID] < 0.1) then
				local ModifierType = type(Modifier)

				if ModifierType == "number" then
					PMultiplier = PMultiplier * Modifier
				elseif ModifierType == "function" then
					PMultiplier = PMultiplier * Modifier()
				end
			end
		end
	end

	return PMultiplier
end

CLEU = function(...)
	local _, EVENT, _, SourceGUID, _,_,_, DestGUID, _, _, _, SpellID = CombatLogGetCurrentEventInfo()
	
	-- PMultiplier OnCast Listener
	if EVENT == "SPELL_CAST_SUCCESS" then 
		local ListenedSpell = ListenedSpells[SpellID]
		if not ListenedSpell then return end
			
		local PMultiplier = ComputePMultiplier(ListenedSpell)		
		local Units = ListenedSpell.Units
		local Dot = Units[DestGUID]
		if Dot then
			Dot.PMultiplier = PMultiplier
			Dot.Time = TMW.time
		else
			Units[DestGUID] = Units[DestGUID] or {}
			local t = Units[DestGUID]
			t.PMultiplier = PMultiplier
			t.Time = TMW.time
			t.Applied = false
		end   
	-- PMultiplier OnApply/OnRefresh Listener
	elseif EVENT == "SPELL_AURA_APPLIED" or EVENT == "SPELL_AURA_REFRESH" then 
		local ListenedAura = ListenedAuras[SpellID]
		if not ListenedAura then return end

		local ListenedSpell = ListenedSpells[ListenedAura]
		if not ListenedSpell then return end

		local Units = ListenedSpell.Units
		local Dot = Units[DestGUID]
		if Dot then
			Dot.Applied = true
		else
			-- Hardcoded PMultiplier for Improved Garrote with Indiscriminate Carnage
			-- Indiscriminate Carnage applies Garrote to off-targets before the primary target
			-- SPELL_CAST_SUCCESS is also called after the off-targets receive the Garrote effect,
			-- so we can't just check the ListenedSpell table.
			local PMult = 1
			-- Custom Bridge
			if Class == "ROGUE" then
				local S = A[CONST.ROGUE_ASSASSINATION]
				if S and S.ImprovedGarrote and S.Garrote and S.ImprovedGarroteAura and S.ImprovedGarroteBuff
				and S.ImprovedGarrote:IsExists() and SpellID == S.Garrote.ID 
				and (Unit("player"):HasBuffs(S.ImprovedGarroteAura.ID, true) > 0 or Unit("player"):HasBuffs(S.ImprovedGarroteBuff.ID, true) > 0) then
					PMult = 1.5
				else
					PMult = ComputePMultiplier(ListenedSpell)
				end
			else
				PMult = ComputePMultiplier(ListenedSpell)
			end		
			Units[DestGUID] = Units[DestGUID] or {}
			local t = Units[DestGUID]
			t.PMultiplier = PMult
			t.Time = TMW.time
			t.Applied = true		
		end 
	elseif EVENT == "SPELL_AURA_REMOVED" then 
		-- Player Aura Removed Listener
		TimeSinceLastRemovedOnPlayer[SpellID] = TMW.time
		
		local ListenedAura = ListenedAuras[SpellID]
		if not ListenedAura then return end

		local ListenedSpell = ListenedSpells[ListenedAura]
		if not ListenedSpell then return end

		local Dot = ListenedSpell.Units[DestGUID]
		if Dot then
			Dot.Applied = false
		end
	-- PMultiplier OnRemove & OnUnitDeath Listener    
	elseif EVENT == "UNIT_DIED" or EVENT == "UNIT_DESTROYED" then
		local Units
		for _, ListenedSpell in pairs(ListenedSpells) do
			Units = ListenedSpell.Units
			if Units[DestGUID] then
				Units[DestGUID] = nil
			end
		end	            
	end 
end

-- dot.foo.pmultiplier
function Unit:PMultiplier(ThisSpell)
	local ListenedSpell = ListenedSpells[ThisSpell.ID]
	if not ListenedSpell then error(SpellRegisterError(ThisSpell)) end

	local Units = ListenedSpell.Units
	local Dot = Units[UnitGUID(self.UnitID)]

	return (Dot and Dot.Applied and Dot.PMultiplier) or 0
end

-- action.foo.persistent_multiplier
function Player:PMultiplier(ThisSpell)
	local ListenedSpell = ListenedSpells[ThisSpell.ID]
	if not ListenedSpell then error(SpellRegisterError(ThisSpell)) end

	return ComputePMultiplier(ListenedSpell)
end