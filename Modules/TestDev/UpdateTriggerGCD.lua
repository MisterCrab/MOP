local TMW 									= TMW
local GetSpellTexture						= TMW.GetSpellTexture

local A 									= Action
local GetSpellInfo							= A.GetSpellInfo
local print 								= A.Print
local wipe									= wipe
local tostringall							= tostringall

local GetSpellBaseCooldown				 	= GetSpellBaseCooldown

-- Classic version
function ClassicTriggerGCD()
	if TMW.db.profiles.TriggerGCD then 
		wipe(TMW.db.profiles.TriggerGCD)
	else 
		TMW.db.profiles.TriggerGCD = {}
	end 
	
	local temp = {}
	for i = 1, 900000 do 
		local spellName, _, spellTexture, _, _, _, spellID = GetSpellInfo(i)
		if spellName and spellID == i and spellName:find("[\128-\255]") and GetSpellTexture(spellID) then 
			local isPlayerSpell = GetSpellDescription(spellID)
			if isPlayerSpell then 
				local base, baseGCD = GetSpellBaseCooldown(spellID)
				if base and baseGCD then 
					TMW.db.profiles.TriggerGCD[tostringall(i .. "	")] = baseGCD
					-- RegEx (\d)\s("]) => $1]
				end 
			end 
		end 
	end 
	
	print("TriggerGCD updated!")
end 