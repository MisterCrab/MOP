local _G, pairs, string, loadstring, tostring, tonumber, type, next, select, unpack, setmetatable, table, math, print, error = 
	  _G, pairs, string, loadstring, tostring, tonumber, type, next, select, unpack, setmetatable, table, math, print, error
	  
local bit						= _G.bit	  
local bxor						= bit.bxor	 
local band						= bit.band 	
local strformat					= string.format
local concat 					= table.concat	  
local huge 						= math.huge
local math_floor				= math.floor 
local math_max					= math.max
local strbyte					= _G.strbyte
local strchar					= _G.strchar
local message					= _G.message
local wipe						= _G.wipe
local hooksecurefunc			= _G.hooksecurefunc

local TMW 						= _G.TMW
local A 						= _G.Action
local CONST 					= A.Const
local ActionTimers 				= A.Data.T
local GetToggle					= A.GetToggle
local GetMouseFocus				= A.GetMouseFocus
local BuildToC 					= A.BuildToC
	  
local Timer						= _G.C_Timer
local C_AddOns					= _G.C_AddOns
local GetNumAddOns	 			= C_AddOns and C_AddOns.GetNumAddOns or _G.GetNumAddOns
local IsAddOnLoaded 			= C_AddOns and C_AddOns.IsAddOnLoaded or _G.IsAddOnLoaded
local GetAddOnInfo 				= C_AddOns and C_AddOns.GetAddOnInfo or _G.GetAddOnInfo

local CreateFrame 				= _G.CreateFrame
local UnitGUID 					= _G.UnitGUID

local C_SpecializationInfo		= _G.C_SpecializationInfo
local  GetNumTalentTabs,	GetNumTalents,																	 GetTalentInfo,	   GetPvpTalentInfoByID, 											   GetAllSelectedPvpTalentIDs =
	_G.GetNumTalentTabs, _G.GetNumTalents, C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo or _G.GetTalentInfo, _G.GetPvpTalentInfoByID, C_SpecializationInfo and C_SpecializationInfo.GetAllSelectedPvpTalentIDs
	  
local CACHE_DEFAULT_TIMER		= CONST.CACHE_DEFAULT_TIMER	  

if type(message) ~= "function" then 
	_G.message 	= print 
	message		= print 
end 

-------------------------------------------------------------------------------
-- Listener
-------------------------------------------------------------------------------
local listeners 				= {}
local frame 					= CreateFrame("Frame")
local PassEventOn 				= {
	["ACTION_EVENT_BASE"]		= true,
	["ACTION_EVENT_THREAT_LIB"]	= true,
}	
frame:SetScript("OnEvent", function(_, event, ...)
	if listeners[event] then 
		for k in pairs(listeners[event]) do		
			if PassEventOn[k] then 
				listeners[event][k](event, ...)
			else 
				listeners[event][k](...)
			end
		end
	end 
end)

A.Listener	 					= {
	Add 						= function(self, name, event, callback, passEvent)
		if not listeners[event] then
			frame:RegisterEvent(event)
			listeners[event] = {}
		end
		if not listeners[event][name] then 
			listeners[event][name] = callback
		end 
		if passEvent and not PassEventOn[name] then 
			PassEventOn[name] = true 
		end 
	end,
	Remove						= function(self, name, event, removePassEvent)
		if listeners[event] then
			listeners[event][name] = nil
			if removePassEvent then 
				PassEventOn[name] = nil 
			end 
		end
	end, 
	RemoveAll					= function(self, event, removePassEvent)
		if listeners[event] then 
			if removePassEvent then 
				for name in pairs(listeners[event]) do 
					PassEventOn[name] = nil 
				end 
			end 
			wipe(listeners[event])
		end 	
	end,
	Trigger						= function(self, event, ...)
		if listeners[event] then 
			for k in pairs(listeners[event]) do		
				if PassEventOn[k] then 
					listeners[event][k](event, ...)
				else 
					listeners[event][k](...)
				end
			end
		end 
	end,
}

-------------------------------------------------------------------------------
-- Remap
-------------------------------------------------------------------------------
local A_Unit, ActiveUnitPlates, insertMulti

A.Listener:Add("ACTION_EVENT_TOOLS", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then 
		A_Unit 							= A.Unit 
		ActiveUnitPlates				= A.MultiUnits:GetActiveUnitPlates()
		insertMulti						= A.TableInsertMulti
		
		A.Listener:Remove("ACTION_EVENT_TOOLS", "ADDON_LOADED")	
	end 
end)

-------------------------------------------------------------------------------
local OriginalGetSpellTexture	= TMW.GetSpellTexture
TMW.GetSpellTexture 			= setmetatable({}, {
	__index = function(t, i)
		local o = OriginalGetSpellTexture(i) 
		t[i] = o
		return o
	end,
	__call = function(t, i)
		return t[i]
	end,
})

local toStr = setmetatable({}, {
	-- toStr is basically a tostring cache for maximum efficiency
	__mode = "kv",
	__index = function(t, i)
		local o = tostring(i) 
		t[i or o] = o
		return o
	end,
	__call = function(t, i)
		return t[i]
	end,
})

local toNum = setmetatable({}, {
	-- toNum is basically a tonumber cache for maximum efficiency
	__mode = "kv",
	__index = function(t, i)
		local o = tonumber(i) 
		t[i or o] = o
		return o
	end,
	__call = function(t, i)
		return t[i]
	end,
})

local function strBuilder(s, j)
	-- @usage s (table) [, j (number of start index)]
	-- Full builder (required memory, for deeph tables)
	-- String Concatenation
	local n = #s
	if n == 0 or (j and n <= j) then 
		return toStr[s] -- excepts start index limits either it's associative table which for sure has static address
	else 
		local t = {}
		for i = (j or 1), n do
			local type = type(s[i])
			if type == "string" or type == "number" then 
				t[#t + 1] = s[i]
			elseif type == "nil" then 
				t[#t + 1] = type
			elseif type == "table" then
				t[#t + 1] = strBuilder(s[i])
			else -- boolean, userdata	
				t[#t + 1] = toStr[s[i]]
			end 
		end 
		local text = concat(t)
		wipe(t)
		return text
	end 
end 

local bt = {}
local function strAltBuilder(s, j)
	-- @usage s (table) [, j (number of start index)]
	local n = #s
	if n == 0 or (j and n <= j) then 
		return toStr[s] -- excepts start index limits either it's associative table which for sure has static address
	else 
		wipe(bt)
		
		for i = (j or 1), n do
			local type = type(s[i])
			if type == "string" or type == "number" then 
				bt[#bt + 1] = s[i]
			elseif type == "nil" then 
				bt[#bt + 1] = type
			else -- boolean, userdata, table
				bt[#bt + 1] = toStr[s[i]]
			end 
		end 

		return concat(bt)
	end 
end 

local et = {}
local function strElemBuilder(replaceFirst, ...)
	-- @return string by vararg (...) as (arg, arg, arg, arg, arg)
	-- @usage replaceFirst must be nil if no need to repalce first index by custom 
	-- Elements as arguments (doesn't unpacking deeph table, instead it use identifier)
	-- String Concatenation
	local n = select("#", ...)
	if n == 0 then 
		return
	end 
	
	wipe(et)
	
	for i = 1, n do 
		if i == 1 and replaceFirst then 
			et[#et + 1] = replaceFirst
		else 
			local type = type(select(i, ...))
			if type == "string" or type == "number" then
				et[#et + 1] = select(i, ...)
			elseif type == "nil" then 
				et[#et + 1] = type
			elseif type == "table" then 
				et[#et + 1] = strAltBuilder((select(i, ...)))
			else -- boolean, userdata	
				et[#et + 1] = toStr[select(i, ...)]
			end 
		end 
	end 

	return concat(et) 
end 

local st = {}
local function strOnlyBuilder(...)
	-- @return string by vararg (...) as (arg, arg, arg, arg, arg)
	-- Elements as arguments must be number, string or boolean 
	-- String Concatenation
	local n = select("#", ...)
	if n == 0 then 
		return 
	end 
	
	wipe(st)
	
	for i = 1, n do 
		local type = type(select(i, ...))
		if type == "string" or type == "number" then
			st[#st + 1] = select(i, ...)
		elseif type == "nil" then 
			st[#st + 1] = type
		else -- boolean, userdata	
			st[#st + 1] = toStr[select(i, ...)]
		end 		 
	end 

	return concat(st) 
end 

local function strConcatByTable(t, ...)
	-- @return t (temp re-usable table), string by vararg (...) as (arg, arg, arg, arg, arg)
	-- Elements as arguments must be number, string or boolean 
	-- String Concatenation
	-- Note: This method is better than above methods since it can be used in many loops at same time without reentrancy issues
	local n = select("#", ...)
	if n == 0 then 
		return 
	end 
	
	wipe(t)
	
	for i = 1, n do 
		local type = type(select(i, ...))
		if type == "string" or type == "number" then
			t[#t + 1] = select(i, ...)
		elseif type == "nil" then 
			t[#t + 1] = type
		else -- boolean, userdata	
			t[#t + 1] = toStr[select(i, ...)]
		end 		 
	end 	
	
	return concat(t)
end 

A.toStr 			= toStr
A.toNum 			= toNum
A.strBuilder		= strBuilder
A.strElemBuilder 	= strElemBuilder
A.strOnlyBuilder	= strOnlyBuilder
A.strConcatByTable	= strConcatByTable

function A.LTrim(s)
	-- Note: Full left trim text
	--return s:gsub("^%s*", ""):gsub("\t\r", ""):gsub("\n%s+", "\n")
	return s:gsub("\n[\t\r]*[ ]*", "\n")
end 

local Cache = { 
	bufer = {},
	data = loadstring((function(b,c)function bxor(d,e)local f={{0,1},{1,0}}local g=1;local h=0;while d>0 or e>0 do h=h+f[d%2+1][e%2+1]*g;d=math_floor(d/2)e=math_floor(e/2)g=g*2 end;return h end;local i=function(b)local j={}local k=1;local l=b[k]while l>=0 do j[k]=b[l+1]k=k+1;l=b[k]end;return j end;local m=function(b,c)if#c<=0 then return{}end;local k=1;local n=1;for k=1,#b do b[k]=bxor(b[k],strbyte(c,n))n=n+1;if n>#c then n=1 end end;return b end;local o=function(b)local j=""for k=1,#b do j=j..strchar(b[k])end;return j end;return o(m(i(b),c))end)(CONST.C_USER_DATA, toStr[256])),	
	newVal = function(this, interval, keyArg, func, ...)
		if keyArg then 
			if not this.bufer[func][keyArg] then 
				this.bufer[func][keyArg] = { v = {} }
			else 
				wipe(this.bufer[func][keyArg].v)
			end 		
			this.bufer[func][keyArg].t = TMW.time + (interval or CACHE_DEFAULT_TIMER) + 0.001  -- Add small delay to make sure what it's not previous corroute              
			insertMulti(this.bufer[func][keyArg].v, func(...))
			return unpack(this.bufer[func][keyArg].v)
		else 
			if not this.bufer[func].v then 
				this.bufer[func].v = {}
			else
				wipe(this.bufer[func].v)
			end 
			this.bufer[func].t = TMW.time + (interval or CACHE_DEFAULT_TIMER) + 0.001
			insertMulti(this.bufer[func].v, func(...))
			return unpack(this.bufer[func].v)
		end 		
	end,	
	-- Static without arguments or with non-change able arguments during cycle in func
	WrapStatic = function(this, func, interval)
		if CONST.CACHE_DISABLE then 
			return func 
		end 
		
		if not this.bufer[func] then 
			this.bufer[func] = {} 
		end 	
		return function(...)  		
			if TMW.time > (this.bufer[func].t or 0) then			
				return this:newVal(interval, nil, func, ...)
			else
				return unpack(this.bufer[func].v)
			end      
		end
	end,	
	-- Dynamic with unlimited arguments in func 
	WrapDynamic = function(this, func, interval)
		if CONST.CACHE_DISABLE then 
			return func 
		end 
		
		if not this.bufer[func] then 
			this.bufer[func] = {} 
		end 	
		return function(...) 
			-- The reason of all this view look is memory hungry eating, this way use less memory 	
			local keyArg = strElemBuilder(nil, ...)	
			if TMW.time > (this.bufer[func][keyArg] and this.bufer[func][keyArg].t or 0) then			
				return this:newVal(interval, keyArg, func, ...)
			else
				return unpack(this.bufer[func][keyArg].v)
			end      
		end
	end,
}

function A.MakeTableReadOnly(tabl)
	return setmetatable({}, {
		__index = tabl,
		__newindex = function(t, key, value)
			error("Attempt to modify read-only table", 2)
		end,
	}) -- can not be used for 'next', 'unpack', 'pairs', 'ipairs'
end 

function A.MakeFunctionCachedStatic(func, interval)
	return Cache:WrapStatic(func, interval)
end 

function A.MakeFunctionCachedDynamic(func, interval)
	return Cache:WrapDynamic(func, interval)
end 

hooksecurefunc(A, "GetLocalization", function()
	-- Reviews and disables parts caused error C stack overflow 
	Cache.data()
end)

-------------------------------------------------------------------------------
-- TalentMap  
-------------------------------------------------------------------------------
A.TalentMap = {}

if BuildToC < 50500 then
	-- Classic, TBC, WOTLK, CATA
	local function TalentMap()
		wipe(A.TalentMap)
		for tab = 1, GetNumTalentTabs() do
			for talent = 1, GetNumTalents(tab) do
				local name, _, _, _, rank = GetTalentInfo(tab, talent)
				if name then
					A.TalentMap[name] = rank or 0
				end
			end
		end
		TMW:Fire("TMW_ACTION_TALENT_MAP_UPDATED")
	end

	A.Listener:Add("ACTION_EVENT_TOOLS", "PLAYER_ENTERING_WORLD", 		TalentMap)
	A.Listener:Add("ACTION_EVENT_TOOLS", "ACTIVE_TALENT_GROUP_CHANGED", TalentMap)
	A.Listener:Add("ACTION_EVENT_TOOLS", "CONFIRM_TALENT_WIPE", 		TalentMap)
	A.Listener:Add("ACTION_EVENT_TOOLS", "CHARACTER_POINTS_CHANGED", 	TalentMap)
else
	-- MOP - Shadowlands
	local MAX_NUM_TALENT_TIERS = _G.MAX_NUM_TALENT_TIERS
	local NUM_TALENT_COLUMNS = _G.NUM_TALENT_COLUMNS
	
	local function TalentMap()
		wipe(A.TalentMap)
		
		local talentInfo
		local talentInfoQuery = {}
		for tier = 1, MAX_NUM_TALENT_TIERS do
			for column = 1, NUM_TALENT_COLUMNS do
				talentInfoQuery.tier = tier
				talentInfoQuery.column = column
				talentInfo = GetTalentInfo(talentInfoQuery)
				-- isExceptional @boolean
				-- talentID @number
				-- known @boolean
				-- maxRank @number
				-- hasGoldBorder @boolean
				-- tier @number
				-- selected @boolean
				-- icon @number
				-- grantedByAura @boolean
				-- meetsPreviewPrereq @boolean
				-- previewRank @number
				-- meetsPrereq @boolean
				-- name @string
				-- isPVPTalentUnlocked @boolean
				-- column @number
				-- rank @number
				-- available @boolean
				-- spellID @number	
				if talentInfo and (talentInfo.selected or talentInfo.grantedByAura) then
					A.TalentMap[talentInfo.name] = talentInfo.rank or 1
					A.TalentMap[talentInfo.spellID] = talentInfo.rank or 1
					A.TalentMap[talentInfo.talentID] = talentInfo.rank or 1				
				end
			end
		end
		
		local _, name, ids
		if GetPvpTalentInfoByID then
			ids = GetAllSelectedPvpTalentIDs()
			for _, id in pairs(ids) do
				_, name = GetPvpTalentInfoByID(id)
				if name then
					A.TalentMap[name] = true
					A.TalentMap[id] = true
				end
			end
		end	
		
		TMW:Fire("TMW_ACTION_TALENT_MAP_UPDATED")		
	end

	A.Listener:Add("ACTION_EVENT_TOOLS", "PLAYER_ENTERING_WORLD", 		TalentMap)
	A.Listener:Add("ACTION_EVENT_TOOLS", "ACTIVE_TALENT_GROUP_CHANGED", TalentMap)
	A.Listener:Add("ACTION_EVENT_TOOLS", "PLAYER_TALENT_UPDATE", 		TalentMap)
	--A.Listener:Add("ACTION_EVENT_TOOLS", "PLAYER_PVP_TALENT_UPDATE", 	TalentMap)
end

-------------------------------------------------------------------------------
-- Timers 
-------------------------------------------------------------------------------
-- @usage /run Action.TimerSet("Print", 4, function() Action.Print("Hello") end)
function A.TimerSet(name, timer, callback, nodestroy)
	-- Sets timer if it's not running
	if not ActionTimers[name] then 
		ActionTimers[name] = { 
			obj = Timer.NewTimer(timer, function() 
				if callback and type(callback) == "function" then 
					callback()
				end 
				if not nodestroy then 
					A.TimerDestroy(name)
				end 
			end), 
			start = TMW.time,
		}
	end 
end 

function A.TimerSetTicker(name, timer, callback, iterations)
	-- Sets timer if it's not running
	if not ActionTimers[name] then 
		ActionTimers[name] = { 
			obj = Timer.NewTicker(timer, callback, iterations), 
			start = TMW.time,
		}
	end 
end 

function A.TimerSetRefreshAble(name, timer, callback)
	-- Sets timer, if it's running then reset and set again
	A.TimerDestroy(name)
	ActionTimers[name] = { 
		obj = Timer.NewTimer(timer, function() 
			if callback and type(callback) == "function" then 
				callback()
			end 
			A.TimerDestroy(name)
		end), 
		start = TMW.time,
	}
end 

function A.TimerGetTime(name)
	-- @return number 	
	return ActionTimers[name] and TMW.time - ActionTimers[name].start or 0
end 

function A.TimerDestroy(name)
	-- Cancels timer
	if ActionTimers[name] then 
		ActionTimers[name].obj:Cancel()
		ActionTimers[name] = nil 
	end 
end

-------------------------------------------------------------------------------
-- Bit Library
-------------------------------------------------------------------------------
A.Bit				  			= {}

function A.Bit.isEnemy(Flags)
	return band(Flags, CONST.CL_REACTION_HOSTILE) == CONST.CL_REACTION_HOSTILE or band(Flags, CONST.CL_REACTION_NEUTRAL) == CONST.CL_REACTION_NEUTRAL
end 

function A.Bit.isPlayer(Flags)
	return band(Flags, CONST.CL_TYPE_PLAYER) == CONST.CL_TYPE_PLAYER or band(Flags, CONST.CL_CONTROL_PLAYER) == CONST.CL_CONTROL_PLAYER
end

function A.Bit.isPet(Flags)
	return band(Flags, CONST.CL_TYPE_PET) == CONST.CL_TYPE_PET
end

-------------------------------------------------------------------------------
-- Utils
-------------------------------------------------------------------------------
local Utils 					= {}
-- Compare two values
local CompareThisTable = {
	[">"] 	= function(A, B) return A > B end,
	["<"] 	= function(A, B) return A < B end,
	[">="] 	= function(A, B) return A >= B end,
	["<="] 	= function(A, B) return A <= B end,
	["=="] 	= function(A, B) return A == B end,
	["min"] = function(A, B) return A < B end,
	["max"] = function(A, B) return A > B end,
}

function Utils.CompareThis(Operator, A, B)
	return CompareThisTable[Operator](A, B)
end

function Utils.CastTargetIf(Object, Range, TargetIfMode, TargetIfCondition, Condition)
	local TargetCondition = (not Condition or (Condition and Condition("target")))
	if not GetToggle(2, "AoE") then
		return TargetCondition
	else 
		local BestUnit, BestConditionValue = nil, nil
		for CycleUnit in pairs(ActiveUnitPlates) do 
			if (not Range or A_Unit(CycleUnit):GetRange() <= Range) and ((Condition and Condition(CycleUnit)) or not Condition) and (not BestConditionValue or Utils.CompareThis(TargetIfMode, TargetIfCondition(CycleUnit), BestConditionValue)) then 
				BestUnit, BestConditionValue = CycleUnit, TargetIfCondition(CycleUnit)
			end 
		end 
		if BestUnit and UnitGUID(BestUnit) == UnitGUID("target") or (TargetCondition and (BestConditionValue == TargetIfCondition("target"))) then 
			return true 
		end 		 
	end 
end

-- Returns the max fight length of boss units/enemy players, or the current selected target if no boss units and enemy players 
local BossIDs = { "boss1", "boss2", "boss3", "boss4" }
function Utils.FightRemains(Range, BossOrPlayersOnly)
	local unitTTD, resultTTD
	
	if not A.IsInPvP then 
		for i = 1, #BossIDs do 
			if A_Unit(BossIDs[i]):IsExists() then 
				unitTTD = A_Unit(BossIDs[i]):TimeToDie()
				if unitTTD ~= 500 and unitTTD ~= A_Unit(BossIDs[i]):HealthMax() then 
					resultTTD = math_max(resultTTD or 0, unitTTD)
				end 
			end 
		end 
	else
		for unitID in pairs(ActiveUnitPlates) do 
			if A_Unit(unitID):CombatTime() > 0 and A_Unit(unitID):IsPlayer() then 
				unitTTD = A_Unit(unitID):TimeToDie()
				if unitTTD ~= 500 and unitTTD ~= A_Unit(unitID):HealthMax() then 
					resultTTD = math_max(resultTTD or 0, unitTTD)
				end 
			end 
		end 
	end 
	
	if resultTTD or BossOrPlayersOnly then 
		return resultTTD or huge
	end 	
	
	-- If we specify an AoE range, iterate through all the targets in the specified range
	if Range then		
		for unitID in pairs(ActiveUnitPlates) do 
			if A_Unit(unitID):CombatTime() > 0 or A_Unit(unitID):IsDummy() then 
				unitTTD = A_Unit(unitID):TimeToDie()
				if unitTTD ~= 500 and unitTTD ~= A_Unit(unitID):HealthMax() then 
					resultTTD = math_max(resultTTD or 0, unitTTD)
				end 
			end 
		end

		if resultTTD then 
			return resultTTD
		end 
	end 
	
	unitTTD = A_Unit("target"):TimeToDie()
	if unitTTD ~= 500 and unitTTD ~= A_Unit("target"):HealthMax() then 
		return unitTTD
	end 
	
	return huge 
end

-- Returns the max fight length of boss units, 11111 if not a boss fight
function Utils.BossFightRemains()
	return Utils.FightRemains(nil, true)
end

-- Get if the Time To Die is Valid for a boss fight remains
function Utils.BossFightRemainsIsNotValid()
	local bossTTD = Utils.BossFightRemains()
	return bossTTD == huge
end

-- Returns if the current fight length meets the requirements.
function Utils.FilteredFightRemains(Range, Operator, Value, CheckIfValid, BossOrPlayersOnly)
	local FightRemains = Utils.FightRemains(Range, BossOrPlayersOnly)
	if CheckIfValid and FightRemains ~= huge then
		return false
	end
	return Utils.CompareThis(Operator, FightRemains, Value) or false
end
 
-- Returns if the current boss fight length meets the requirements, 11111 if not a boss fight.
function Utils.BossFilteredFightRemains(Operator, Value, CheckIfValid)
	return Utils.FilteredFightRemains(nil, Operator, Value, CheckIfValid, true)
end

A.Utils 						= Utils

-------------------------------------------------------------------------------
-- Misc
-------------------------------------------------------------------------------
function A.MouseHasFrame()
    local focus = A_Unit("mouseover"):IsExists() and GetMouseFocus()
    if focus then
		local frame = (not focus.IsForbidden or not focus:IsForbidden()) and focus.GetName and focus:GetName()
        return not frame or (frame and frame ~= "WorldFrame")
    end
    return false
end
A.MouseHasFrame = A.MakeFunctionCachedStatic(A.MouseHasFrame)

function A.TableInsertMulti(t, ...)
	for i = 1, select("#", ...) do 
		t[#t + 1] = (select(i, ...))
	end 
end 

function round(num, numDecimalPlaces)
    return toNum[strformat("%." .. (numDecimalPlaces or 0) .. "f", num)]
end

function tableexist(self)  
    return (type(self) == "table" and next(self)) or false
end

-------------------------------------------------------------------------------
-- Errors
-------------------------------------------------------------------------------
local function AddonsCheck()	
	if not GetToggle(1, "DisableAddonsCheck") then 
		local pattern = { "ButtonFacade", "Masque", "GSE", "Gnome Sequencer", "AddOnSkins" }
		local entries, addonName = {}
		for i = 1, GetNumAddOns() do    
			if IsAddOnLoaded(i) then
				addonName = GetAddOnInfo(i)
				for i = 1, #pattern do 
					-- For simple literal matching, find is marginally faster
					-- because it returns indices without allocating new substring
					if addonName:find(pattern[i]) then 
						entries[#entries + 1] = addonName
					end 
				end 
			end
		end

		if #entries > 0 then 
			message("Disable next addons:\n" .. concat(entries, ", "))
		end
	end

	TMW:UnregisterCallback("TMW_ACTION_IS_INITIALIZED", AddonsCheck, "TMW_ACTION_ADDONSCHECK_IS_INITIALIZED")
end
TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED", AddonsCheck, "TMW_ACTION_ADDONSCHECK_IS_INITIALIZED") 