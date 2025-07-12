local _G, pairs, loadstring, select, math, string =		
	  _G, pairs, loadstring, select, math, string

HeroRotation					= _G.HeroRotation or {}
local Cache 					= _G.HeroCache
local HL 						= _G.HeroLib
local HR 						= HeroRotation 

if not HL then 
	return 
end 

local Cache, Utils 				= HeroCache, HL.Utils
local Unit 						= HL.Unit
local Player 					= Unit.Player
local Target 					= Unit.Target
local Spell 					= HL.Spell
local Item 						= HL.Item
-- Lua
local mathmin 					= math.min
local stringlower	 			= string.lower
local strsplit 					= _G.strsplit

local TMW 						= _G.TMW 
local GetSpellTexture			= TMW.GetSpellTexture

local A 						= _G.Action
local Unit						= A.Unit	
local MultiUnits				= A.MultiUnits
local ActiveNameplates			= MultiUnits:GetActiveUnitPlates()
local BurstIsON					= A.BurstIsON
local GetToggle					= A.GetToggle
local InterruptIsValid			= A.InterruptIsValid

local UnitGUID					= _G.UnitGUID

local isClassic					= A.StdUi.isClassic
local owner						= isClassic and "PlayerClass" or "PlayerSpec"
 
-------------------------------------------------------------------------------
-- Core 
-------------------------------------------------------------------------------	  
function A:HeroCreate() 
	-- @return table, table or nil 
	-- Convert from Action to Hero Spells and Items
	if HL then 
		local S, I = {}, {}
		for k, v in pairs(self) do 
			if v.Type:match("Spell") or (not isClassic and v.SubType == "HeartOfAzeroth") then 
				S[k] = Spell(v.ID)
				-- Push identificator for 'The Action'
				S[k].KEY = k
			end 
			
			if v.Type:match("Item") or v.Type == "Potion" or v.Type:match("Trinket") then 
				I[k] = Item(v.ID)
				-- Push identificator for 'The Action'
				I[k].KEY = k
			end 
		end 
		return S, I
	end 	 
end 

local IsHooked = {}
function A.HeroSetHook(objects, metas)
	-- @usage
	--[[
		A.HeroSetHook({
			S.Brew,
			S.Guard,
			I.SomeTrinket,
		}, 
		{
			[3] = "TellMeWhen_Group2_Icon3",
			[4] = "TellMeWhen_Group2_Icon4",
		})
	]]
	-- Sets hook on call HR.Cast and HR.CastSuggested functions with relative frame for texture show 
	for i = 1, #objects do 
		IsHooked[objects[i].KEY] = metas
	end 
end 

function A.HeroSetHookAllTable(tabl, metas)
	-- @usage 
	--[[
		A.HeroSetHookAllTable(S, {
			[3] = "TellMeWhen_Group2_Icon3",
			[4] = "TellMeWhen_Group2_Icon4",
		})
		A.HeroSetHookAllTable(I, {
			[3] = "TellMeWhen_Group2_Icon3",
			[4] = "TellMeWhen_Group2_Icon4",
		})
	]]
	-- Does same as A.HeroSetHook but it takes all from direct table
	for _, v in pairs(tabl) do 
		IsHooked[v.KEY] = metas
	end 
end 

-------------------------------------------------------------------------------
-- Remap 
-------------------------------------------------------------------------------	  
local Dummy = function() return true end 
local Null	= function() end 
local ObjKey = function(Object)
	if A.IsInitialized and Object and Object.KEY and IsHooked[Object.KEY] then 
		for meta, frame in pairs(IsHooked[Object.KEY]) do
			if A[A[owner]] and A[A[owner]][meta] and A[A[owner]][Object.KEY] then 
				A[A[owner]][Object.KEY]:Show(loadstring("return " .. frame)())
				-- /run local a = assert(loadstring("return TellMeWhen_Group2_Icon4"))(); print(a)
				-- /dump loadstring("return TellMeWhen_Group2_Icon4")()
			end 
		end 
	end 
	
	return true 
end 

local CachedCast = HR.Cast or Dummy
function HR.Cast(Object, OffGCD, DisplayStyle)
	if CachedCast(Object, OffGCD, DisplayStyle) then 
		ObjKey(Object)
		return true 
	end 
end 

local CachedCastQueue = HR.CastQueue or Dummy 
local CacheQueueSet = { Silence = true, Priority = 1 }
function HR.CastQueue(...)
	CachedCastQueue(...)
	if A.IsInitialized then 
		local args = { ... }
		for i = 1, #args do 
			if args[i].KEY and IsHooked[args[i].KEY] then 			
				if A[A[owner]] and A[A[owner]][args[i].KEY] and not A[A[owner]][args[i].KEY]:IsQueued() then 
					A[A[owner]][args[i].KEY]:SetQueue(CacheQueueSet)
				end 
			end 
		end 
	end 
	return "Should Return"
end

local CachedCastCycle = HR.CastCycle or Dummy
function HR.CastCycle(Object, Range, Condition)
	if CachedCastCycle(Object, Range, Condition) then 
		if Condition(Target) then
			return HR.Cast(Object)
		end
		if HR.AoEON() then
			local BestUnit = nil
			local TargetGUID = UnitGUID("target")
			for _, CycleUnit in pairs(ActiveNameplates) do
				if (not range or Unit(CycleUnit):GetRange() <= range) and UnitGUID(CycleUnit) ~= TargetGUID and Condition(CycleUnit) then
					HR.CastLeftNameplate(CycleUnit, Object)
					return true 
				end
			end
		end				
	end 
end 

local CachedCastTargetIf = HR.CastTargetIf or Dummy
function HR.CastTargetIf(Object, Range, TargetIfMode, TargetIfCondition, Condition)
	local TargetCondition = (not Condition or (Condition and Condition(Target)))
	if not HR.AoEON() and TargetCondition then
		return HR.Cast(Object)
	end	
	if HR.AoEON() then
		local BestUnit, BestConditionValue = nil, nil
		for _, CycleUnit in pairs(ActiveNameplates) do
			if (not range or Unit(CycleUnit):GetRange() <= range) and ((Condition and Condition(CycleUnit)) or not Condition) and (not BestConditionValue or Utils.CompareThis(TargetIfMode, TargetIfCondition(CycleUnit), BestConditionValue)) then
				BestUnit, BestConditionValue = CycleUnit, TargetIfCondition(CycleUnit)
			end
		end
		if BestUnit then
			if (BestUnit:GUID() == Target:GUID()) or (TargetCondition and (BestConditionValue == TargetIfCondition(Target))) then
				return HR.Cast(Object)
			else
				HR.CastLeftNameplate(BestUnit, Object)
				return ObjKey(Object)
			end
		end
	end
end

HR.Print 				= HR.Print or A.Print 
HR.SetAPL 				= HR.SetAPL or Dummy
HR.CastLeft 			= HR.CastLeft or Null 
HR.CastLeftCommon 		= HR.CastLeftCommon or Null 
HR.CastLeftNameplate	= HR.CastLeftNameplate or Dummy 
HR.CastAnnotated		= HR.CastAnnotated or Null 
HR.Locked				= HR.Locked or Null 
HR.ON					= HR.ON or Null
HR.CmdHandler			= HR.CmdHandler or Null
 
HR.GetTexture 			= HR.GetTexture or function(Object) 
	return GetSpellTexture(Object.SpellID)
end 

local CachedCastSuggested = HR.CastSuggested or Dummy
function HR.CastSuggested(Object)
	if CachedCastSuggested(Object) then 
		ObjKey(Object)
		return true 
	end 
end 

-- Get if the CDs are enabled.
function HR.CDsON(unit)
	if A.IsInitialized then 
		return BurstIsON(unit or "target")
	end 
	
	return HeroRotationCharDB and HeroRotationCharDB.Toggles[1]
end

-- Get if the AoE is enabled.
function HR.AoEON()
	if A.IsInitialized then 
		return GetToggle(2, "AoE")
	end 
	
	return HeroRotationCharDB and HeroRotationCharDB.Toggles[2]
end

if HL then 
	local Spell = HL.Spell
	local Item = HL.Item
	
	-- Connect it with 'The Action' by SetBlocker, SetQueue and custom LUA (+ toggles for Potion, Trinkets, HeartOfAzeroth)
	local function ActionAPI(Object)
		return not A.IsInitialized or (A[A[owner]] and A[A[owner]][Object.KEY] and A[A[owner]][Object.KEY]:IsReady())
	end 
	
	-- Spells 
	local CachedSpellIsCastable = Spell.IsCastable
	function Spell:IsCastable(Range, AoESpell, ThisUnit)
		return ActionAPI(self) and CachedSpellIsCastable(self, Range, AoESpell, ThisUnit)
	end

	local CachedSpellIsCastableP = Spell.IsCastableP
	function Spell:IsCastableP(Range, AoESpell, ThisUnit, BypassRecovery, Offset)
		return ActionAPI(self) and CachedSpellIsCastableP(self, Range, AoESpell, ThisUnit, BypassRecovery, Offset)
	end
	
	local CachedSpellIsReady = Spell.IsReady
	function Spell:IsReady(Range, AoESpell, ThisUnit)
		return ActionAPI(self) and CachedSpellIsReady(self, Range, AoESpell, ThisUnit)
	end
	
	local CachedSpellIsReadyP = Spell.IsReadyP
	function Spell:IsReadyP(Range, AoESpell, ThisUnit)
		return ActionAPI(self) and CachedSpellIsReadyP(self, Range, AoESpell, ThisUnit)
	end
	
	-- Items 
	local CachedItemIsReady = Item.IsReady
	function Item:IsReady()
		return ActionAPI(self) and CachedItemIsReady(self)
	end
end 

local Commons = {}
if not HR.Commons then 
	HR.Commons = {}	
	HR.Commons.Everyone = Commons
	
	-- Put EnemiesCount to 1 if we have AoEON or are targetting an AoE insensible unit
	local AoEInsensibleUnit = {
		--- Legion
		----- Dungeons (7.0 Patch) -----
		--- Mythic+ Affixes
		-- Fel Explosives (7.2 Patch)
		[120651] = true,
	}
	function Commons.AoEToggleEnemiesUpdate ()
		if not HR.AoEON() or AoEInsensibleUnit[Target:NPCID()] then
			for Key, Value in pairs(Cache.EnemiesCount) do
				Cache.EnemiesCount[Key] = mathmin(1, Cache.EnemiesCount[Key]);
			end
		end
	end	
else 
	Commons = HR.Commons.Everyone
end 

local CachedTargetIsValid 	= Commons.TargetIsValid or Dummy 
function Commons.TargetIsValid()
	return CachedTargetIsValid() and (not A.IsInitialized or Unit("target"):IsEnemy())
end 

Commons.UnitIsCycleValid 	= Commons.UnitIsCycleValid or Dummy
Commons.CanDoTUnit		 	= Commons.CanDoTUnit or Dummy 

local CachedInterrupt 	 	= Commons.Interrupt
local CacheInterruptTable 	= {"KickImun", "TotalImun"}
function Commons.Interrupt(Range, Spell, Setting, StunSpells) 
	-- Note: HeroRotations need little bit tweak with it by adding this func with "if Commons.Interrupt(args) then return end" 
	if not A.IsInitialized then 
		return CachedInterrupt(Range, Spell, Setting, StunSpells) 
	else 	
		local Kick, CC = InterruptIsValid("target", "Main")  
		if ((not StunSpells and Kick) or (StunSpells and CC)) and (not Range or Unit("target"):GetRange() <= Range) and (not Spell or (Spell.KEY and IsHooked[Spell.KEY] and A[A[owner]][Spell.KEY] and A[A[owner]][Spell.KEY]:IsReady("target"))) and Unit("target"):CanInterrupt(true, CacheInterruptTable) then 
			return HR.Cast(Spell)
		end 
	end
end 