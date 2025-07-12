-------------------------------------------------------------------------------------
-- Original lib has missed some spells
-- This file extend spell list and API methods
-------------------------------------------------------------------------------------

local Lib 												= LibStub("DRList-1.0")
local L													= Lib.L
local diminishedDurations								= Lib.diminishedDurations[Lib.gameExpansion]
local categoryNames										= Lib.categoryNames[Lib.gameExpansion]
local spellList											= Lib.spellList

local _G, pairs											= _G, pairs
local TMW 												= _G.TMW

-------------------------------------------------------------------------------
-- API extend  
-------------------------------------------------------------------------------	  
-- This code works faster than in the original lib, so keep it here
function Lib:GetNextDR(diminished, category)
    local durations = diminishedDurations[category or "default"]
    if not durations and categoryNames[category] then
        -- Redirect to default when "stun", "root" etc is passed
        durations = diminishedDurations["default"]		
    end
	
	return durations and durations[diminished] or 0
end

-- This is custom lib improvement
function Lib:GetApplicationMax(category)
	local durations = diminishedDurations[category or "default"] or (categoryNames[category] and diminishedDurations.default)
	return durations and #durations + 1 or 0
end 

-- Keep same API as DRData-1.0 for easier transitions
Lib.NextDR = Lib.GetNextDR

-------------------------------------------------------------------------------
-- List extend  
-------------------------------------------------------------------------------	  

if Lib.gameExpansion == "classic" then 
	categoryNames.disarm = L.DISARMS
	
	-- Disarms
	spellList[676]     	= "disarm"  		-- Disarm
	spellList[14251]   	= "disarm"    		-- Riposte
	spellList[23365]   	= "disarm"    		-- Dropped Weapon

	-- Incapacitates
	spellList[2094]		= "incapacitate" 	-- Blind 
	spellList[9484]		= "incapacitate" 	-- Shackle Undead 
	spellList[710]		= "incapacitate"	-- Banish

	-- Turn Undead 
	spellList[2878]    	= "fear"          	-- Turn Undead

	-- Stuns 
	spellList[19482]  	= "stun"   			-- War Stomp (Doomguard pet)
elseif Lib.gameExpansion == "tbc" then 
	-- Disarms
	spellList[23365]   	= "disarm"			-- Dropped Weapon

	-- Incapacitates
	spellList[9484]		= "incapacitate"	-- Shackle Undead 
	spellList[710]		= "incapacitate"	-- Banish

	-- Turn Undead 
	spellList[2878]    	= "fear"			-- Turn Undead
																			
	-- Stuns              													
	spellList[19482]  	= "stun"			-- War Stomp (Doomguard pet)
end 
