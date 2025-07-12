local _G, next		 							= 
	  _G, next
	  
local A 										= _G.Action
local Listener 									= A.Listener

local TeamCache									= A.TeamCache
local TeamCacheFriendly							= TeamCache.Friendly
local TeamCacheFriendlyUNITs					= TeamCacheFriendly.UNITs
local TeamCacheEnemy							= TeamCache.Enemy
local TeamCacheEnemyUNITs						= TeamCacheEnemy.UNITs 
	  
local wipe										= _G.wipe	  
	  
local 	 UnitPlayerControlled, 	  CanInspect, 	 CheckInteractDistance,    UnitIsUnit, 	  UnitGUID =
	  _G.UnitPlayerControlled, _G.CanInspect, _G.CheckInteractDistance, _G.UnitIsUnit, _G.UnitGUID

local 	 InspectUnit, 	 GetInventoryItemID, 	GetItemInfoInstant,    GetLocale =
	  _G.InspectUnit, _G.GetInventoryItemID, _G.GetItemInfoInstant, _G.GetLocale
	  
local HideUIPanel								= _G.HideUIPanel	  

local InspectCache 								= {}
local IsInspectFrameHooked 
local UseCloseInspect 

-- This is not fixed by game API on languages which are different than English, it's bring an error
local GameLocale 								= GetLocale()
local SetCVar, GetCVar							= _G.SetCVar, _G.GetCVar
local scriptErrors 
local AllowedLocale								= {
	enGB 										= true,
	enUS										= true,
}

local function GetGUID(unitID)
	return (unitID and (TeamCacheFriendlyUNITs[unitID] or TeamCacheEnemyUNITs[unitID])) or UnitGUID(unitID)
end 

local function UnitInspectItem(unitID, invID)
    if UnitPlayerControlled(unitID) and CheckInteractDistance(unitID, 1) and CanInspect(unitID, false) and not UnitIsUnit("player", unitID) then  
		local GUID = GetGUID(unitID)
		if not GUID then 
			return 
		end 
		
		if not InspectCache[GUID] then 
			InspectCache[GUID] = {}
		end 
		
		if not InspectCache[GUID][invID] then 
			InspectCache[GUID][invID] = {}
		end 				
		
		-- Open inspect frame 
		--if not _G.InspectFrame or not _G.InspectFrame:IsShown() then 
			-- ByPass game errors depend on language, English game is OKAY, game devs missed to fix for different languages inspect 			
			if not AllowedLocale[GameLocale] then 
				scriptErrors = GetCVar("scriptErrors")
				if scriptErrors and scriptErrors ~= "0" then 
					SetCVar("scriptErrors", 0)
				end 				
			end 
						
			InspectUnit(unitID)				
		--end 
		
		-- Getting info from inspect frame 
		local ID = GetInventoryItemID(unitID, invID)
		
		-- Close inspect frame 		
		if not IsInspectFrameHooked then 
			UseCloseInspect = true
			_G.InspectFrame:HookScript("OnShow", function(self)
				if UseCloseInspect then 				
					HideUIPanel(InspectFrame)
					UseCloseInspect = false 
					-- Return errors back to be shown, just bypass errors from inspectUI
					if scriptErrors and scriptErrors == "1" then 
						SetCVar("scriptErrors", 1)
					end 					
				end 
			end)
			IsInspectFrameHooked = true 
		else 
			UseCloseInspect = true 
		end 
		
		-- Save info 
		if ID then 
			-- https://wow.gamepedia.com/ItemType
			local _, _, _, _, _, ClassID, SubClassID 	= GetItemInfoInstant(ID)						
			InspectCache[GUID][invID].itemClassID 		= ClassID
			InspectCache[GUID][invID].itemSubClassID 	= SubClassID		
			InspectCache[GUID][invID].itemID 			= ID 
			
			return InspectCache[GUID][invID]			
		end 
		
		-- Wipe 
		if InspectCache[GUID][invID] then 
			wipe(InspectCache[GUID][invID])
		end 
		
		return InspectCache[GUID][invID]
    end
end 

local function UnitInspectWipe(...)
	if next(InspectCache) then 
		local unitID = ... 
		if unitID then 
			local GUID = GetGUID(unitID)
			if GUID and InspectCache[GUID] then 
				wipe(InspectCache[GUID])
			end 
		else 
			wipe(InspectCache)
		end 
	end 
end 

Listener:Add("ACTION_EVENT_UNIT_INSPECT", "PLAYER_REGEN_ENABLED", 		UnitInspectWipe)
Listener:Add("ACTION_EVENT_UNIT_INSPECT", "UNIT_INVENTORY_CHANGED",		UnitInspectWipe)


-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
function A.GetUnitItem(unitID, invID, itemClassID, itemSubClassID, itemID, byPassDistance)
	-- @return boolean or nil 
	-- Optional: itemClassID, itemSubClassID, itemID, byPassDistance
	local GUID = GetGUID(unitID)
	if GUID then 
		if InspectCache[GUID] and InspectCache[GUID][invID] and InspectCache[GUID][invID].itemID then 
			return (not itemClassID or InspectCache[GUID][invID].itemClassID == itemClassID) and (not itemSubClassID or InspectCache[GUID][invID].itemSubClassID == itemSubClassID) and (not itemID or InspectCache[GUID][invID].itemID == itemID)
		else
			local I = UnitInspectItem(unitID, invID)
			return (byPassDistance and not I and true) or (I and (not itemClassID or I.itemClassID == itemClassID) and (not itemSubClassID or I.itemSubClassID == itemSubClassID) and (not itemID or I.itemID == itemID))
		end 
	end 
end

function A.GetUnitItemInfo(unitID, invID)
	-- @return table or nil 
	-- Table Keys:
	-- .itemClassID
	-- .itemSubClassID
	-- .itemID
	-- Optional: itemClassID, itemSubClassID, itemID, byPassDistance
	local GUID = GetGUID(unitID)
	if GUID then 
		if InspectCache[GUID] and InspectCache[GUID][invID] and InspectCache[GUID][invID].itemID then 
			return InspectCache[GUID][invID]
		else
			return UnitInspectItem(unitID, invID)
		end 
	end 
end  

-------------------------------------------------------------------------------
-- Example 
-------------------------------------------------------------------------------
-- Check equiped Shields on a unit: 
-- /dump Action.GetUnitItem("target", ACTION_CONST_INVSLOT_OFFHAND, LE_ITEM_CLASS_ARMOR, LE_ITEM_ARMOR_SHIELD)
-- Check equiped Two hand on a unit:
-- /dump Action.GetUnitItem("target", ACTION_CONST_INVSLOT_MAINHAND, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_AXE2H) or Action.GetUnitItem("target", ACTION_CONST_INVSLOT_MAINHAND, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_MACE2H) or Action.GetUnitItem("target", ACTION_CONST_INVSLOT_MAINHAND, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_SWORD2H) or Action.GetUnitItem("target", ACTION_CONST_INVSLOT_MAINHAND, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_POLEARM) or Action.GetUnitItem("target", ACTION_CONST_INVSLOT_MAINHAND, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_STAFF)
-- Check equiped One hand on a unit:
-- /dump Action.GetUnitItem("target", ACTION_CONST_INVSLOT_MAINHAND, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_AXE1H) or Action.GetUnitItem("target", ACTION_CONST_INVSLOT_MAINHAND, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_MACE1H) or Action.GetUnitItem("target", ACTION_CONST_INVSLOT_MAINHAND, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_SWORD1H) or Action.GetUnitItem("target", ACTION_CONST_INVSLOT_MAINHAND, LE_ITEM_CLASS_WEAPON, LE_ITEM_WEAPON_DAGGER)