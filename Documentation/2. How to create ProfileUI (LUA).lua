--[[
-------------------------------------------------------------------------------
-- Introduction 
-------------------------------------------------------------------------------
If you plan to build profile without use lua then you can skip this guide
Important to create mouseover, focus, focustarget, targettarget toggles as Checkbox as on their state will relly many things in API

-------------------------------------------------------------------------------
-- №1: Create snippet 
-------------------------------------------------------------------------------
Write in chat "/tmw options" > LUA Snippets > Profile (left side) > "+" > Write name "ProfileUI" in title of the snippet
--]]

-------------------------------------------------------------------------------
-- №2: Set profile defaults 
-------------------------------------------------------------------------------
-- Constances (written in Constans.lua)

-- Map locals to get faster performance
local _G, setmetatable					= _G, setmetatable
local TMW 								= _G.TMW 
local A 								= _G.Action

-- This indicates to use 'The Action's all components and make it initializated for current profile 
A.Data.ProfileEnabled[A.CurrentProfile] = true 

-------------------------------------------------------------------------------
-- №3: Create UI on 'The Action' for current profile 
-------------------------------------------------------------------------------
--[[ 
A.Data.ProfileUI is a table where you have to set UI elements with DB (DataBase) variables and their default presets. This table can be omitted however then [2] and [7] will display 'Profile has no configuration for this tab.' in /action
]]
-- Structure:
A.Data.ProfileUI = {	
	DateTime = "v0 (00.00.0000)", 	-- 'v' is version (Day, Month, Year)
	[tab.name] = {					-- supports [2] (class tab), [7] (message tab) in /action
		-- Configure if [tab.name] is [2] (class tab)			
		LayoutOptions = {},		-- (optional) is table which can be used to configure layout position
		{						-- {} brackets on this level will create one row 
			RowOptions = {},	-- (optional) is table which can be used to configure this (current) row position on your layout 
			{					-- {} brackets on this level will create one element 
				key = value,	-- is itself element config 
			},
		},
		-- Configure if [tab.name] is [7] (message tab)	
		["phrase"] = {			-- ["phrase"] - This is key which is string phase which will match a message written in /party chat. MUST BE IN LOWER CASE!
			key = value,		-- is itself ["phrase"] config 
		},
	},
}

-- (optional) LayoutOptions and RowOptions Structure:
A.Data.ProfileUI = {	
	[2] = {
		LayoutOptions = {
			columns = '@number', 	-- count of columns per row 
			gutter = '@number', 	-- indent between columns ( from 0 to columns )
			padding = { 			-- indent on [2] itself frame 
				top = '@number', 
				right = '@number', 
				left = '@number',
			},
		},
		{ -- row 
			RowOptions = {
				margin = { 			-- indent on current row for elements 
					top = '@number', 
					right = '@number', 
					left = '@number', 
					bottom = '@number',
				},
			}, 
		},
	},
}

-- Element Structure:
A.Data.ProfileUI = {	
	[2] = {
		{
			E = "Label",
			L = {			
				-- Fixed LANGUAGE is short game language, like ["enUS"] , more info https://wowwiki.fandom.com/wiki/API_GetLocale . ["enUS"] key must be existed ALWAYS otherwise use ["ANY"] key!! because if user hasn't localization it will use ["enUS"] key 
				[LANGUAGE1] = '@string', 
				[LANGUAGE2] = '@string',
				-- OR Forced LANGUAGE, ANY is valid for any game language (usefully with GetSpellInfo)
				ANY = '@string',
			},
			S = '@string', 			-- font (text) size					
		},
		{
			E = "Header",
			L = {			
				-- Fixed
				[LANGUAGE1] = '@string', 
				[LANGUAGE2] = '@string',
				-- OR Forced
				ANY = '@string',
			},
			S = '@string', 			-- font (text) size					
		},
		{
			E = "Button",
			L = {			
				-- Fixed 
				[LANGUAGE1] = '@string', 
				[LANGUAGE2] = '@string',
				-- OR Forced
				ANY = '@string',
			},
			OnClick = function(self, button, down) 	-- 'self' is own frame button, 'button' is left or right mouse click event, 'down' state of that 
				-- your code here 
			end, 
			-- Optional:
			TT = {									-- tooltip		
				-- Fixed 
				[LANGUAGE] = '@string', 
				-- OR Forced
				ANY = '@string',
			},
			isDisabled = true or nil,
		},
		{
			E = "Checkbox",
			L = {			
				-- Fixed 
				[LANGUAGE1] = '@string', 
				[LANGUAGE2] = '@string',
				-- OR Forced
				ANY = '@string',
			},
			DB = value,				-- name of key for SavedVariables in DataBase
			DBV = value,			-- default value if key wasn't existed before, it's also used for 'Reset Settings', supports @boolean @string @number
			-- Optional:
			TT = {					-- tooltip		
				-- Fixed 
				[LANGUAGE] = '@string', 
				-- OR Forced
				ANY = '@string',
			},
			M = { 					-- macros, if table exists (even without keys) it will unlock macro creation by right click on this element 
				-- Optional:
				Custom = "/run Action.ToggleTest()", -- using custom macro text to create by right click, all below is not valid if Custom key noted
				-- Otherwise it will structure like 
				-- /run Action.SetToggle({[tab.name], Action.Data.ProfileUI[tab.name].DB, Action.Data.ProfileUI[tab.name].L[CL] .. ": "}, Action.Data.ProfileUI[tab.name].M.Value or nil)
				-- It does call func CraftMacro(L[CL], macro above, 1) -- 1 means perCharacter tab in MacroUI, if nil then will be used allCharacters tab in MacroUI
				Value = value or nil, 
				-- Very Very Optional, no idea why it will be need however.. 
				TabN = '@number' or nil,								
				Print = '@string' or nil,								
			},
			isDisabled = true or nil,
		},
		{
			E = "Dropdown",
			L = {			
				-- Fixed 
				[LANGUAGE1] = '@string', 
				[LANGUAGE2] = '@string',
				-- OR Forced
				ANY = '@string',
			},
			DB = value,				-- name of key for SavedVariables in DataBase
			DBV = value,			-- default value from OT key if key wasn't existed before, it's also used for 'Reset Settings', supports @string
			-- Optional:
			TT = {					-- tooltip		
				-- Fixed 
				[LANGUAGE] = '@string', 
				-- OR Forced
				ANY = '@string',
			},
			M = {},					-- macros (same as on Checkbox)
			isDisabled = true or nil,					
			H = '@number',			-- height of element (default 20)
			OT = {					-- option table of menu
				{ text = '@string' or '@table', value = 1 },	-- value must be @number if you use key MULT as true, otherwise it supports @string @number @boolean
				{ text = '@string' or '@table', value = 2 },	-- text can be @table which is equal to structure text = { enUS = "english", ruRU = "russian" } or @string which is equal to text = { ANY = "your text" } or text = "your text"
			},
			MULT = true or nil,		-- makes dropdown as multiselector
			isNotEqualVal = value, 	-- only if MULT is false or omitted, custom value of Dropdown which shouldn't be recorded into Cache, otherwise it's ~= "Off", ~= "OFF" and ~= 0
			SetPlaceholder = { 		-- only if MULT is true, default displayed value if nothing is not selected from menu 
				-- Only Fixed
				[LANGUAGE1] = '@string', 
			}, 
		},
		{
			E = "Slider",
			L = {			
				-- Fixed 
				[LANGUAGE1] = '@string', 
				[LANGUAGE2] = '@string',
				-- OR Forced
				ANY = '@string',
			},
			DB = value,				-- name of key for SavedVariables in DataBase
			DBV = '@number',		-- default value from OT key if key wasn't existed before, it's also used for 'Reset Settings', supports @number
			-- Optional:
			TT = {					-- tooltip		
				-- Fixed 
				[LANGUAGE] = '@string', 
				-- OR Forced
				ANY = '@string',
			},
			M = {},					-- macros (same as on Checkbox)				
			H = '@number',			-- height of element   (default 20)
			MIN = '@number',		-- min value on slider (default -1)
			MAX = '@number',		-- max value on slider (default 100)
			Precision = '@number', 	-- accuracy of slider move (default 2)
			-- One of the next keys:
			-- If one of them is noted then will makes Slider display OFF / AUTO text if it will reach as value to MIN / MAX 
			ONOFF = true,			-- makes to display OFF if value == MIN and AUTO if value == MAX 
			ONLYON = true,			-- makes to display only AUTO if value == MAX 
			ONLYOFF = true,			-- makes to display only OFF if value == MIN 
			-- Otherwise it will display just number
		},
	},
}

-- Message Structure:
A.Data.ProfileUI = {	
	[7] = {
		["phrase"] = {					-- ["phrase"] - This is key which is string phase which will match a message written in /party chat. MUST BE IN LOWER CASE!
			Enabled = true,
			Key = '@string',			-- is a key from Action[Action.PlayerClass] table in your rotation lua snippet, you also can see this key in /action > [3] 'Actions' tab 
			-- Optional:
			LUA = '@string',			-- LUA code which should return true to react on message (has an embedded environment Action[Action.PlayerClass]. so any what has after Action. or Action[Action.PlayerClass]. no need to use, it's let's say easier will be attributed)	
			LUAVER = '@number',			-- This key helps to reset for current MSG default assigned LUA if version of LUA code is different than current user has
			Source = '@string',			-- who said "phrase", if same server then probably no need to add server name after name of speaker
		},
	},
}	

-- Example:
A.Data.ProfileUI = {	
	DateTime = "v1.2a (01.01.2850)",
	[2] = {					
		{
			{	
				E = "Header",
				L = { 
					enUS = "HEADER", 
					ruRU = "ЗАГОЛОВОК", 
				}, 
				S = 14,
			},
		},					
		{							
			{
				E = "Checkbox", 
				DB = "Feint",
				DBV = true,
				L = { 
					enUS = "Use Feint", 
					ruRU = "Использовать Фейнт", 
				}, 
				TT = { 
					enUS = "Enable to use", 
					ruRU = "Включает для использования", 
				}, 
				M = {},
			},
			{
				E = "Checkbox", 
				DB = "Shiv",
				DBV = false,
				L = { 
					enUS = "Enable Shiv", 
					ruRU = "Разблокировать шивку", 
				}, 
				TT = { 
					enUS = "Enable to use", 
					ruRU = "Включает для использования", 
				}, 
				M = {},
			},
		},
		{
			{
				E = "Dropdown", 														
				H = 20,
				OT = {
					{ 
						text = {
							enUS = "Leap",
							ruRU = "Прыжок",
						}, 
						value = 1,
					},
					{ 
						text = {
							enUS = "Blink",
							ruRU = "Скачок",
						},
						value = 2,
					},
					{ text = "Portal", value = 3 }, -- text can be like just string also which is equal to text = { ANY = "Portal" }
				},
				MULT = true,
				--isNotEqualVal = *any*, -- only if MULT is false or omited 
				DB = "DropdownMult",
				DBV = {
					[1] = true,
					[2] = true,
					[3] = true,
				}, 
				SetPlaceholder = { 
					enUS = "-- DropdownMult --", 
					ruRU = "-- Выпадающий список --", 
				}, 
				L = { 
					enUS = "DropdownMult Config", 
					ruRU = "ВыпадающийСписок Конфиг", 
				}, 
				TT = { 
					enUS = "ToolTip Mult", 
					ruRU = "ТулТипа мульта", 
				}, 
				M = {},									
			},
			{
				E = "Checkbox", 
				DB = "CKnoMacro",
				DBV = true,
				L = { 
					enUS = "CKnoMacro", 
					ruRU = "ЧекБокс без макро", 
				}, 
				TT = { 
					enUS = "English ToolTip", 
					ruRU = "Русский тултип", 
				}, 
			},
		},
		{
			{
				E = "Checkbox", 
				DB = "ShortCK",
				DBV = true,
				L = { 
					enUS = "Short checkBox", 
					ruRU = "Короткий бокс", 
				}, 
			},
			{
				E = "Dropdown", 														
				H = 20,
				OT = {
					{ text = "Simcraft", value = "Simcraft" },
					{ text = "Custom", value = "Custom" },
					{ text = "Off", value = "Off" }
				},
				MULT = false,
				--isNotEqualVal = *any*, -- only if MULT is false or omited 
				DB = "DropdownSingle",
				DBV = "Simcraft",
				L = { 
					enUS = "Dropdown SINGLE", 
					ruRU = "Выпадающий ОДИНОЧ.", 
				}, 
				TT = { 
					enUS = "ToolTip SINGLE", 
					ruRU = "ТулТипа ОДИНОЧ.", 
				}, 
				M = {
					Custom = [[/run Toggle()]],
				},
			},
		},
		{
			{	
				E = "Label",
				L = { 
					enUS = "Label", 
					ruRU = "Метка", 
				}, 
			},							
			{
				E = "Slider", 													
				H = 20,
				MIN = -1, 
				MAX = 100,							
				DB = "Slidertoggle",
				DBV = 40,
				L = { 
					enUS = "Slider Example", 
					ruRU = "Ползунок Пример", 
				}, 
				TT = { 
					enUS = "Slider ToolTip", 
					ruRU = "Ползунок ТулТип", 
				}, 
				M = {
				},
			},
		},
		{
			{
				E = "LayoutSpace",
			},	
			{
				E = "Slider", 													
				H = 20,
				MIN = -1, 
				MAX = 100,							
				DB = "Sliderwithspace",
				DBV = 10,
				L = { 
					enUS = "Slider Example2", 
					ruRU = "Ползунок Пример2", 
				}, 
				TT = { 
					enUS = "Slider ToolTip222", 
					ruRU = "Ползунок ТулТип222", 
				}, 
				M = {
				},
			},							
		},
		{
			{
				E = "Checkbox", 
				DB = "ASDASD",
				DBV = true,
				L = { 
					enUS = "asdasd", 
					ruRU = "asdfsdfg", 
				},
			},
		},
	},
	[7] = {
		["shield"] = { Enabled = true, Key = "POWS", LUAVER = 1, LUA = [[
			-- thisunit is a special thing which will be replaced by string of unitID. Example: some one said phrase "shield party1" then thisunit will be replaced by "party1" and for this MSG will be used meta [7] which is Party1 Rotation which is A[7]()
			-- More info in Action.lua 
			-- You have to keep in mind what once written in DataBase this code can't be changed if you made changes in ProfileUI, you have to use 'Reset Settings' and other people too if you failed here with code, so take attention on it. 
			-- If you want to change LUA written code by next release profile you should increase LUAVER by +1, so if you change LUA then add +1 to LUAVER, this way will cause to reset old LUA and replace it by new one for same phrase
			local ClassActions = Action[PlayerClass]
			return 	ClassActions.POWS:IsReadyM(thisunit) and 											
					ClassActions.POWS:AbsentImun(thisunit) and 
					LossOfControl:IsMissed("SILENCE") and 					-- LossOfControl written like this (not like Action.LossOfControl which is same) because each LUA code has setfenv to Action and then _G if not found in Action
					LossOfControl:Get("SCHOOL_INTERRUPT", "HOLY") == 0
		]] },
	},
}

-- Alternative method of write 
A.Data.ProfileUI 									= {
	DateTime = "v1.2a (01.01.2850)",
	[2] 											= { LayoutOptions = { gutter = 3, padding = { left = 3, right = 3 } } }, 
	[7] = {
		["shield"] = { Enabled = true, Key = "POWS", LUAVER = 1, LUA = [[
			-- thisunit is a special thing which will be replaced by string of unitID. Example: some one said phrase "shield party1" then thisunit will be replaced by "party1" and for this MSG will be used meta [7] which is Party1 Rotation which is A[7]()
			-- More info in Action.lua 
			-- You have to keep in mind what once written in DataBase this code can't be changed if you made changes in ProfileUI, you have to use 'Reset Settings' and other people too if you failed here with code, so take attention on it. 
			-- If you want to change LUA written code by next release profile you should increase LUAVER by +1, so if you change LUA then add +1 to LUAVER, this way will cause to reset old LUA and replace it by new one for same phrase
			local ClassActions = Action[PlayerClass]
			return 	ClassActions.POWS:IsReadyM(thisunit) and 											
					ClassActions.POWS:AbsentImun(thisunit) and 
					LossOfControl:IsMissed("SILENCE") and 					-- LossOfControl written like this (not like Action.LossOfControl which is same) because each LUA code has setfenv to Action and then _G if not found in Action
					LossOfControl:Get("SCHOOL_INTERRUPT", "HOLY") == 0
		]] },
	},
}

local ProfileUI = A.Data.ProfileUI[2]
ProfileUI[#ProfileUI + 1] = {
	{	
		E = "Header",
		L = { 
			enUS = "HEADER", 
			ruRU = "ЗАГОЛОВОК", 
		}, 
		S = 14,
	},
}				
ProfileUI[#ProfileUI + 1] = {							
	{
		E = "Checkbox", 
		DB = "Feint",
		DBV = true,
		L = { 
			enUS = "Use Feint", 
			ruRU = "Использовать Фейнт", 
		}, 
		TT = { 
			enUS = "Enable to use", 
			ruRU = "Включает для использования", 
		}, 
		M = {},
	},
	{
		E = "Checkbox", 
		DB = "Shiv",
		DBV = false,
		L = { 
			enUS = "Enable Shiv", 
			ruRU = "Разблокировать шивку", 
		}, 
		TT = { 
			enUS = "Enable to use", 
			ruRU = "Включает для использования", 
		}, 
		M = {},
	},
}
-- ... and etc 

-- Misc: About ProfileDB (example)
-- A.Data.ProfileUI will create A.Data.ProfileDB, you can set A.Data.ProfileDB like this instead point DB and DBV actually in the ProfileUI, but if both up then A.Data.ProfileUI will overwrite A.Data.ProfileDB
-- So don't take attention on it unless you need it for some purposes like visual comfort
A.Data.ProfileDB = {
	[2] = {	
		Feint = true, 
		Shiv = false, 
		CKnoMacro = true,
		ShortCK = true,
		DropdownMult = {
			[1] = true,
			[2] = true,
			[3] = true,
		},
		DropdownSingle = "Simcraft",
		Slidertoggle = 40,
		Sliderwithspace = 10,
		Personalskhf = "unkas",
	},
}

-------------------------------------------------------------------------------
-- №4: Use remain space for shared code between all specializations in profile (optional)
-------------------------------------------------------------------------------
local GetToggle				 = A.GetToggle
local InterruptIsValid		 = A.InterruptIsValid
local Unit 					 = A.Unit
local select 				 = select 

local GrappleWeaponPvPunits	 = setmetatable({}, { __index = function(t, v)
	t[v] = GetToggle(2, "GrappleWeaponPvPunits")
	return t[v]
end})
local ImunBuffsCC	 		 = {"CCTotalImun", "DamagePhysImun", "TotalImun"}
local ImunBuffsInterrupt	 = {"KickImun", "TotalImun", "DamagePhysImun"}

function A.GrappleWeaponIsReady(unitID, skipShouldStop, isMsg)
	if A.IsInPvP then 
		local isArena = unitID:match("arena")
		if 	(
				(unitID == "arena1" and GrappleWeaponPvPunits[A.PlayerSpec][1]) or 
				(unitID == "arena2" and GrappleWeaponPvPunits[A.PlayerSpec][2]) or
				(unitID == "arena3" and GrappleWeaponPvPunits[A.PlayerSpec][3]) or
				(not isArena and GrappleWeaponPvPunits[A.PlayerSpec][4]) 
			) 
		then 
			if (not isArena and Unit(unitID):IsEnemy() and Unit(unitID):IsPlayer()) or (isArena and not Unit(unitID):InLOS() and (A.Zone == "arena" or A.Zone == "pvp")) then 
				local GrappleWeapon = A[A.PlayerSpec].GrappleWeapon
				if  GrappleWeapon and 
					(
						(
							not isMsg and GetToggle(2, "GrappleWeaponPvP") ~= "OFF" and ((not isArena and GrappleWeapon:IsReady(unitID, nil, nil, skipShouldStop)) or (isArena and GrappleWeapon:IsReadyByPassCastGCD(unitID))) and 								
							Unit(unitID):IsMelee() and (GetToggle(2, "GrappleWeaponPvP") == "ON COOLDOWN" or Unit(unitID):HasBuffs("DamageBuffs") > 8)
						) or 
						(
							isMsg and GrappleWeapon:IsReadyM(unitID)
						)
					) and 
					GrappleWeapon:AbsentImun(unitID, ImunBuffsCC, true) and 
					Unit(unitID):IsControlAble("disarm") and 
					Unit(unitID):InCC() == 0 and 
					Unit(unitID):HasDeBuffs("Disarmed") == 0
				then 
					return true 
				end 
			end 
		end 
	end 
end 

function A:CanInterruptPassive(unitID, countGCD)
	if A.IsInPvP and (A.Zone == "arena" or A.Zone == "pvp") then 		
		if self.isSpearHandStrike then 
			-- MW hasn't SpearHandStrike action 
			local useKick, _, _, notInterruptable = InterruptIsValid(unitID, "Heal", nil, countGCD)
			if not useKick then 
				useKick, _, _, notInterruptable = InterruptIsValid(unitID, "PvP", nil, countGCD)
			end 
			if useKick and not notInterruptable and self:IsReadyByPassCastGCD(unitID) and self:AbsentImun(unitID, ImunBuffsInterrupt, true) then 
				return true 
			end 
		end 
		
		if self.isParalysis then 
			local ParalysisPvP = GetToggle(2, "ParalysisPvP")
			if ParalysisPvP and ParalysisPvP ~= "OFF" and self:IsReadyByPassCastGCD(unitID) then 
				local _, useCC, castRemainsTime 
				if Toggle == "BOTH" then 
					useCC, _, _, castRemainsTime = select(2, InterruptIsValid(unitID, "Heal", nil, countGCD))
					if not useCC then 
						useCC, _, _, castRemainsTime = select(2, InterruptIsValid(unitID, "PvP", nil, countGCD))
					end 
				else 
					useCC, _, _, castRemainsTime = select(2, InterruptIsValid(unitID, Toggle, nil, countGCD))
				end 
				if useCC and castRemainsTime >= GetLatency() and Unit(unitID):IsControlAble("incapacitate") and not Unit(unitID):InLOS() and self:AbsentImun(unitID, ImunBuffsCC, true) then 
					return true 
				end 
			end 
		end 					
	end 
end 