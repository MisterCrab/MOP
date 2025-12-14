-------------------------------------------------------------------------------------
-- I decided to fix issue which owner of Lib don't want to fix, this mostly game bug
-- Issue is named CLEU on event SPELL_CAST_FAILED 
-- This thing works wrong in over 50% cases which is not okay
-- This is additional code which make extension for original Lib 
-- This code checking unit movement to properly fire SPELL_CAST_FAILED event 
-- Cost around zero in performance even on 0 update interval
-------------------------------------------------------------------------------------

local _G, next, pairs			= _G, next, pairs

local LibClassicCasterino 		= _G.LibStub("LibClassicCasterino", true)
if not LibClassicCasterino then return end

local f 						= LibClassicCasterino.frame
local callbacks 				= LibClassicCasterino.callbacks
local casters 					= LibClassicCasterino.casters

local TMW 						= _G.TMW 
local A							= _G.Action
local Unit 						= A.Unit 
local MultiUnits				= A.MultiUnits
local NameplatesGUID 			= MultiUnits:GetActiveUnitPlatesGUID()
local TeamCache 				= A.TeamCache
local FriendlyGUIDs				= TeamCache.Friendly.GUIDs
local EnemyGUIDs				= TeamCache.Enemy.GUIDs

local UnitGUID, UnitIsVisible	= _G.UnitGUID, _G.UnitIsVisible
local GetUnitSpeed				= _G.GetUnitSpeed

local commonUnits 				= {
    "target",
    "targettarget",
	"mouseover",
}

local function FireToUnits(event, guid, ...)
	for i = 1, #commonUnits do
        if UnitGUID(commonUnits[i]) == guid then
            callbacks:Fire(event, commonUnits[i], ...)
        end
    end

    local fUnit = FriendlyGUIDs[guid]
    if fUnit then
        callbacks:Fire(event, fUnit, ...)
    end
	
    local eUnit = EnemyGUIDs[guid]
    if eUnit then
        callbacks:Fire(event, eUnit, ...)
    end	
	
    local nameplateUnit 	= NameplatesGUID[guid]
    if nameplateUnit then
        callbacks:Fire(event, nameplateUnit, ...)
    end
end

local function CastStop(srcGUID, castType, suffix)
    local currentCast = casters[srcGUID]
    if currentCast then
        casters[srcGUID] = nil
        local event = "UNIT_SPELLCAST_" .. suffix
        FireToUnits(event, srcGUID)
    end
end

f:SetScript("OnUpdate", function(self, elapsed)
	if not next(casters) then 
		return 
	end 
	
    for i = 1, #commonUnits do
		local GUID = UnitGUID(commonUnits[i])
        if GUID and casters[GUID] and GetUnitSpeed(commonUnits[i]) ~= 0 then
            CastStop(GUID, "CAST", "INTERRUPTED")
			return 
        end
    end
	
	-- If we're outside pvp BG then use nameplates instead of unitID "arena" since it's not exist
	-- If existd then better to use their GUIDs since they are not limited to distance
	if not next(EnemyGUIDs) then 
		if nameplateUnit and next(NameplatesGUID) then
			for guid, unit in pairs(NameplatesGUID) do 
				if casters[guid] and GetUnitSpeed(unit) ~= 0 then
					CastStop(guid, "CAST", "INTERRUPTED")
					return
				end 
			end 
		end
	end 

	for guid, unit in pairs(FriendlyGUIDs) do 
		if casters[guid] and UnitIsVisible(unit) and GetUnitSpeed(unit) ~= 0 then
            CastStop(guid, "CAST", "INTERRUPTED")
			return 
        end
	end 

	for guid, unit in pairs(EnemyGUIDs) do 
		if casters[guid] and UnitIsVisible(unit) and GetUnitSpeed(unit) ~= 0 then
            CastStop(guid, "CAST", "INTERRUPTED")
			return
        end
	end 
end)