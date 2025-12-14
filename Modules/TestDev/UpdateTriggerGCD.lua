local _G, print, pairs						= _G, print, pairs
local TMW 									= _G.TMW
local GetSpellTexture						= TMW.GetSpellTexture

local wipe									= _G.wipe
local sort									= _G.table.sort
local concat								= _G.table.concat
local tostringall							= _G.tostringall

local GetSpellBaseCooldown				 	= _G.GetSpellBaseCooldown
local GetSpellDescription					= _G.C_Spell.GetSpellDescription
local GetSpellInfo							= _G.C_Spell.GetSpellInfo

local function fromLowest(a, b)
	return a[1] < b[1]
end

function CreateTriggerGCD()
	local spellInfo, spellName, spellID, base, baseGCD
	local t, n = {}, 0
	for ID = 1, _G.ACTION_CONST_SPELLID_MAXID or 1500000 do 
		spellInfo = GetSpellInfo(ID)
		if spellInfo then
			spellName, spellID = spellInfo.name, spellInfo.spellID
			if spellID == ID and spellName:find("[\128-\255]") and GetSpellTexture(spellID) then -- must be used on cyrillic because of \128-\255
				if GetSpellDescription(spellID) then 
					base, baseGCD = GetSpellBaseCooldown(spellID)
					if base and baseGCD then 
						n = n + 1
						t[n] = { ID, baseGCD }
					end 
				end 
			end
		end
	end 			
	sort(t, fromLowest)
	
	
	local TriggerGCD = {}
	for i = 1, #t do
		TriggerGCD[t[i][1]] = t[i][2]
	end
	TMW.db.global.TriggerGCD = TriggerGCD

	print("TriggerGCD created!")
end 

function MergeTriggerGCD()
	local TriggerGCD1 = TMW.db.global.TriggerGCD
	local TriggerGCD2 = _G.Action.Enum.TriggerGCD
	
	for ID, baseGCD in pairs(TriggerGCD1) do
		TriggerGCD2[ID] = baseGCD
	end
	
	
	local t, n = {}, 0
	for ID, baseGCD in pairs(TriggerGCD2) do
		n = n + 1
		t[n] = { ID, baseGCD }
	end	
	sort(t, fromLowest)
	
	
	local TriggerGCD = {}
	for i = 1, #t do
		TriggerGCD[t[i][1]] = t[i][2]
	end
	TMW.db.global.TriggerGCD = TriggerGCD
	
	print("TriggerGCD merged!")
end

function ExportTriggerGCD()
	local TriggerGCD = TMW.db.global.TriggerGCD
	
    local t, n = {}, 0
    for ID, baseGCD in pairs(TriggerGCD) do
        n = n + 1
        t[n] = { ID, baseGCD }
    end	
    sort(t, fromLowest)
	
	
    local lines, n = {}, 0
    for i = 1, #t do
        n = n + 1
        lines[n] = ("[%d] = %d,\n\t"):format(t[i][1], t[i][2])
    end

    TMW.db.global.TriggerGCD = "{\n\t" .. concat(lines) .. "}"
	-- \\n replace to \n
	
	print("TriggerGCD exported!")
end


local Merge = _G.WOW_PROJECT_ID ~= _G.WOW_PROJECT_MAINLINE
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:SetScript("OnEvent", function()
	if Merge then
		CreateTriggerGCD()
		MergeTriggerGCD()
	else
		CreateTriggerGCD()
	end
	ExportTriggerGCD()
end)