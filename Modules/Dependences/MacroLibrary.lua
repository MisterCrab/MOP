-------------------------------------------------------------------------------------------
-- This library extends official macro API 
-------------------------------------------------------------------------------------------
--[[ DOCUMENTATION:
Macros are possible to create and put on action bar even in combat* but only at PLAYER_LOGIN event 
Listener:Add("ACTION_EVENT_MACRO_LIBRARY_CREATE", "PLAYER_LOGIN", function()
	Lib:CraftMacro("TestMacroOnLoad", Lib.Data.Icons[2], A.LTrim([=[
	  /say 1
	  /say 2
	  /say 3
	]=]), true, true)
	Lib:SetActionButton("TestMacroOnLoad")
	
	Listener:Remove("ACTION_EVENT_MACRO_LIBRARY_CREATE", "PLAYER_LOGIN")	
end)

Callbacks:
TMW:RegisterCallback("TMW_ACTION_MACRO_LIBRARY_ACTION_SLOT_CHANGED", function(callbackEvent, actionSlot)
	print("Changed slot " .. actionSlot)
end)
TMW:RegisterCallback("TMW_ACTION_MACRO_LIBRARY_UPDATED", function(callbackEvent)
	print("Macro created, deleted or changed")
end)
]]
local _G, type, unpack, pairs, next, select	=
	  _G, type, unpack, pairs, next, select	
	  
local TMW								= _G.TMW
local A 								= _G.Action
local CONST 							= A.Const
local Listener							= A.Listener
local Print								= A.Print
local Lib 								= LibStub:NewLibrary("MacroLibrary", 7)
	  
local wipe 								= _G.wipe	  
local MAX_ACCOUNT_MACROS				= _G.MAX_ACCOUNT_MACROS
local MAX_CHARACTER_MACROS				= _G.MAX_CHARACTER_MACROS	  
local MacroFrame_LoadUI					= _G.MacroFrame_LoadUI 
local MacroFrame_Update					-- OnLoad 
local MacroFrame_SelectMacro			-- OnLoad 
local MacroFrame_Show					-- OnLoad 

-- Macro 
local originalDeleteMacro				= _G.DeleteMacro
local DeleteMacro						-- OnLoad 
local 	 CreateMacro, 	 EditMacro,    GetLooseMacroIcons, 	  GetLooseMacroItemIcons, 	 GetMacroIcons,    GetMacroInfo, 	GetMacroItemIcons, 	  GetMacroItem,    GetMacroSpell, 	 SetMacroItem, 	  SetMacroSpell =
	  _G.CreateMacro, _G.EditMacro, _G.GetLooseMacroIcons, _G.GetLooseMacroItemIcons, _G.GetMacroIcons, _G.GetMacroInfo, _G.GetMacroItemIcons, _G.GetMacroItem, _G.GetMacroSpell, _G.SetMacroItem, _G.SetMacroSpell
	  
--[[
local 	 GetMacroBody, 	  GetNumMacros,    GetMacroIndexByName,    GetRunningMacroButton, 	 GetRunningMacro, 	 SetOverrideBindingMacro =
	  _G.GetMacroBody, _G.GetNumMacros, _G.GetMacroIndexByName, _G.GetRunningMacroButton, _G.GetRunningMacro, _G.SetOverrideBindingMacro
]]
	  
-- Cursor 	  
local 	 ClearCursor, 	 CursorHasMacro, 	PickupMacro, 	PlaceAction =
	  _G.ClearCursor, _G.CursorHasMacro, _G.PickupMacro, _G.PlaceAction

-- Key Binding
local SetBindingMacro  					= _G.SetBindingMacro  	
	  
-- Action 
local GetActionInfo						= _G.GetActionInfo	  

-- Misc 
local InCombatLockdown					= _G.InCombatLockdown  
local TempIndex							= {}	  
local TempButtons						= {}

local WipeMacrosSkip 					= {
	LooseIcons 							= true,
	LooseItemsIcons 					= true,
	Icons			 					= true,
	ItemIcons 							= true,
}

Lib.MacroFrame 							= nil -- OnLoad 
Lib.MacroFrameTab1						= nil -- OnLoad 
Lib.MacroFrameTab2						= nil -- OnLoad 
Lib.FreeAccountSlots					= MAX_ACCOUNT_MACROS
Lib.FreeCharacterSlots					= MAX_CHARACTER_MACROS
Lib.Data								= {
	-- Holds all icons available for macros 
	LooseIcons 							= {},
	LooseItemsIcons						= {},
	Icons 								= {},
	ItemIcons							= {},
	-- Holds information about each exist macro by its ID 
	AllMacros							= {},
	AccountMacros						= {},
	CharacterMacros						= {},
	-- Pointers by critera to information tables (by ID) above
	ByNameMacros						= {},
	ByActionMacros						= {},
}  	
-- Holds information about action slots which stored a macro 
Lib.ActionButtons						= {}

-------------------------------------------------------------------------------
-- API - Official
-------------------------------------------------------------------------------
function _G.DeleteMacro(ID)
	-- Note: Yes, it will cause double enterence to Lib:UpdateMacros() but it will be fired BEFORE events such as ACTIONBAR_SLOT_CHANGED
	Lib:UpdateMacros()
	return originalDeleteMacro(ID)
end

function Lib:CreateMacro(macroName, macroIcon, macroBody, perCharacter, isLocal)
	return CreateMacro(macroName, macroIcon, macroBody, perCharacter, isLocal)
end

function Lib:GetAction(ID)
	-- @return actionID or nil
	return self:GetSpell(ID) or self:GetItem(ID)
end

function Lib:GetSpell(ID)
	-- @return spellID or nil 
	return GetMacroSpell(ID)
end 

function Lib:GetItem(ID)
	-- @return itemID or nil 
	return GetMacroItem(ID)
end 

function Lib:SetSpell(ID, spellID)
	return SetMacroSpell(ID, spellID)
end 

function Lib:SetItem(ID, itemID)
	return SetMacroItem(ID, itemID)
end 

-------------------------------------------------------------------------------
-- API - Library
-------------------------------------------------------------------------------
function Lib:Show()
	if not self.MacroFrame:IsVisible() then 
		MacroFrame_Show()
	end 
end 

function Lib:Hide()
	if self.MacroFrame and self.MacroFrame:IsVisible() then 
		self.MacroFrame.CloseButton:Click()
	end
end 

function Lib:SelectTab(tab)
	-- Show frame 
	self:Show()
	
	-- Select tab
	if tab == 1 then 
		if self.MacroFrameTab1:IsEnabled() then 
			self.MacroFrameTab1:Click()				
		end 
	else 
		if self.MacroFrameTab2:IsEnabled() then 
			self.MacroFrameTab2:Click()
		end 
	end 
end 

function Lib:SelectMacro(ID)
	if ID then 
		-- Select tab 
		if ID <= MAX_ACCOUNT_MACROS then 
			self:SelectTab(1)
		else 
			self:SelectTab(2)
		end 
		
		-- Select macro 	
		MacroFrame_SelectMacro(ID, true)
		
		-- Refresh frame
		MacroFrame_Update()
	end 
end 

function Lib:WipeMacros()
	for k, v in pairs(self.Data) do 
		if not WipeMacrosSkip[k] and type(v) == "table" then 
			wipe(v)
		end 
	end 
end 

function Lib.UpdateMacros()
	-- Note: Don't use 'self' here
	Lib:WipeMacros()

	local macroName, macroIcon, macroBody, lastIndex, actionID
	-- Update Account Macros 
	lastIndex 								 		= 0
	for i = 1, MAX_ACCOUNT_MACROS do 		
		macroName, macroIcon, macroBody 	 		= GetMacroInfo(i) 		
		if not macroName then 			
			break 
		else 			
			lastIndex						 		= i
			actionID								= Lib:GetAction(i)
			Lib.Data.AllMacros[i] 			 		= { Name = macroName, Icon = macroIcon, Body = macroBody, ID = i, Action = actionID }
			Lib.Data.AllMacros[macroName]	 		= Lib.Data.AllMacros[i]			
			Lib.Data.AccountMacros[i]		 		= Lib.Data.AllMacros[i]
			Lib.Data.ByNameMacros[macroName] 		= Lib.Data.AllMacros[i]
			if actionID then
				if (type(actionID) == "number" and actionID > MAX_ACCOUNT_MACROS + MAX_CHARACTER_MACROS) or (type(actionID) == "string" and not Lib.Data.AllMacros[actionID]) then
					Lib.Data.AllMacros[actionID]	= Lib.Data.AllMacros[i]
				end
				Lib.Data.ByActionMacros[actionID] 	= Lib.Data.AllMacros[i]
			end
		end 
	end 
	Lib.FreeAccountSlots 			 		 		= MAX_ACCOUNT_MACROS - lastIndex
	
	-- Update Character Macros 
	lastIndex 								 		= 0
	for i = 1, MAX_CHARACTER_MACROS do 
		i 									 		= MAX_ACCOUNT_MACROS + i 
		macroName, macroIcon, macroBody 	 		= GetMacroInfo(i) 
		if not macroName then 
			break 
		else 
			lastIndex						 		= i
			actionID								= Lib:GetAction(i)
			Lib.Data.AllMacros[i] 			 		= { Name = macroName, Icon = macroIcon, Body = macroBody, ID = i, Action = actionID }
			Lib.Data.AllMacros[macroName]	 		= Lib.Data.AllMacros[i]			
			Lib.Data.AccountMacros[i]		 		= Lib.Data.AllMacros[i]
			Lib.Data.ByNameMacros[macroName] 		= Lib.Data.AllMacros[i]
			if actionID then
				if (type(actionID) == "number" and actionID > MAX_ACCOUNT_MACROS + MAX_CHARACTER_MACROS) or (type(actionID) == "string" and not Lib.Data.AllMacros[actionID]) then
					Lib.Data.AllMacros[actionID]	= Lib.Data.AllMacros[i]
				end
				Lib.Data.ByActionMacros[actionID] 	= Lib.Data.AllMacros[i]
			end
		end 
	end 
	Lib.FreeCharacterSlots 				 	 		= MAX_CHARACTER_MACROS - lastIndex

	TMW:Fire("TMW_ACTION_MACRO_LIBRARY_UPDATED")
end 

function Lib:UpdateActionButtons()	
	local macroID, previous_state		
	for i = 1, 120 do 
		previous_state	= self.ActionButtons[i]
		macroID 		= self:GetIndexByActionButton(i)
		
		if macroID then 
			self.ActionButtons[i] = macroID
		elseif previous_state then 
			self.ActionButtons[i] = nil 
		end 
		
		if previous_state ~= macroID then 
			TMW:Fire("TMW_ACTION_MACRO_LIBRARY_ACTION_SLOT_CHANGED", i)
		end 
	end
end 

function Lib.UpdateActionButton(actionSlot)
	-- Note: Don't use 'self' here
	local previous_state	= Lib.ActionButtons[actionSlot]
	local macroID			= Lib:GetIndexByActionButton(actionSlot) 
	
	if macroID then 
		Lib.ActionButtons[actionSlot] = macroID
	elseif previous_state then 
		Lib.ActionButtons[actionSlot] = nil 
	end 
	
	if previous_state ~= macroID then 
		TMW:Fire("TMW_ACTION_MACRO_LIBRARY_ACTION_SLOT_CHANGED", actionSlot)
	end 
end

function Lib:CraftMacro(macroName, macroIcon, macroBody, perCharacter, isHidden)
	-- @return @string of error or @nil of success
	-- @usage: 
	-- Lib:CraftMacro(@string, @string or @number or @nil, @string[, @boolean, @boolean])
	-- /dump LibStub("MacroLibrary"):CraftMacro("TestName", nil, "/say test1 /say test2", true)
	-- 1. macroName is a name of the macro title 
	-- 2. macroIcon is a texture of the macro 
	-- 3. macroBody is a text of the macro 
	-- 4. perCharacter, must be true if need create macro in character's tab 
	-- 5. isHidden, must be true if need create macro without cause opened macro frame 
	local macroName = macroName:sub(1, 30) -- actually 63 but funky different languages have different character capacity per byte
	if self.Data.ByNameMacros[macroName] then
		if not isHidden then 
			self:SelectMacro(self.Data.ByNameMacros[macroName].ID)
		end 
		
		return "MacroExists"
	elseif InCombatLockdown() and not issecure() then 
	
		return "InCombatLockdown"
	elseif perCharacter and self.FreeCharacterSlots == 0 then 
		if not isHidden then 
			self:SelectTab(2)
		end 
		
		return "MacroLimit"
	elseif self.FreeAccountSlots == 0 then 
		if not isHidden then 
			self:SelectTab(1)
		end 
		
		return "MacroLimit"
	end 
	
	self:CreateMacro(macroName, macroIcon or "INV_MISC_QUESTIONMARK", macroBody, perCharacter)
	
	if not isHidden then 
		self:SelectMacro(self.Data.ByNameMacros[macroName].ID)
	end
end

function Lib:EditMacro(ID, newName, newIcon, newBody, perCharacter, isHidden)
	-- @return @string of error or @nil of success
	-- @usage: 
	-- Lib:EditMacro(@number, @string, @string or @number, @string, @boolean, @boolean) 
	-- 1. ID is the index of macro
	-- 2. newName is a name of the macro 
	-- 3. newIcon is a texture of the macro
	-- 4. newBody is a text of the macro 
	-- 5. perCharacter, must be true if need create macro in character's tab 
	-- 6. isHidden, must be true if need create macro without cause opened macro frame 
	if InCombatLockdown() and not issecure() then 
		return "InCombatLockdown"
	end 
	
	EditMacro(ID, newName, newIcon, newBody, perCharacter, isHidden)	
	
	if not isHidden then 
		self:SelectMacro(self.Data.ByNameMacros[macroName].ID)
	end
end 

function Lib:DeleteMacro(ID)
	-- Note: issecure doesn't work here 
	-- @return @string of error or @nil of success
	if InCombatLockdown() then 
		return "InCombatLockdown"
	end 
	DeleteMacro(ID)
end

function Lib:GetFreeNum()
	-- @return @number of the account available slot macros, @number of the character available slot macros 
	return self.FreeAccountSlots, self.FreeCharacterSlots
end 

function Lib:GetUsedNum()
	-- @return @number of the account used macros, @number of the character used macros 
	return MAX_ACCOUNT_MACROS - self.FreeAccountSlots, MAX_CHARACTER_MACROS - self.FreeCharacterSlots
end

function Lib:GetMaxNum()
	-- @return @number of the account max macros, @number of the character max macros 
	return MAX_ACCOUNT_MACROS, MAX_CHARACTER_MACROS
end

function Lib:GetIndexByName(macroName)
	-- @return multi-@numbers or @nil
	local macroName = macroName:sub(1, 30) -- actually 63 but funky different languages have different character capacity per byte
	if self:IsExists(macroName) then 
		wipe(TempIndex)
		
		-- Account macros 
		for _, v in pairs(self.Data.AccountMacros) do 
			if v.Name == macroName then 
				TempIndex[#TempIndex + 1] = v.ID 
			end 
		end 
		
		-- Character macros 
		for _, v in pairs(self.Data.CharacterMacros) do 
			if v.Name == macroName then 
				TempIndex[#TempIndex + 1] = v.ID 
			end 
		end 
		
		return unpack(TempIndex)
	end 
end 

function Lib:GetIndexByActionButton(actionSlot)
	-- @return @number or @nil
	local actionType, actionID = GetActionInfo(actionSlot)
	if actionType == "macro" and actionID ~= 0 and self.Data.ByActionMacros[actionID] then 
		return self.Data.ByActionMacros[actionID].ID
	end
end 

function Lib:GetActionButtons(ID)
	-- @return multi-@numbers or @nil
	local macroID = ID and self.Data.AllMacros[ID] and self.Data.AllMacros[ID].ID
	if macroID and next(self.ActionButtons) then 
		wipe(TempButtons)
		
		for k, v in pairs(self.ActionButtons) do 
			if v == macroID then 
				TempButtons[#TempButtons + 1] = k
			end 
		end 
		
		return unpack(TempButtons)
	end 
end 

function Lib:GetInfo(ID, By)
	-- @return macroName, macroIcon, macroBody, macroID or nil 
	-- Note: Instead of official GetMacroInfo the last return will be macroID
	local base = self.Data[By or "AllMacros"][ID]
	if base then 
		return base.Name, base.Icon, base.Body, base.ID
	end 
end 

function Lib:GetName(ID)
	-- @return @string or @nil
	return ID and self.Data.AllMacros[ID] and self.Data.AllMacros[ID].Name
end 

function Lib:GetIcon(ID)
	-- @return @string or @number or @nil
	return ID and self.Data.AllMacros[ID] and self.Data.AllMacros[ID].Icon
end 

function Lib:GetBody(ID)
	-- @return @string or @nil
	return ID and self.Data.AllMacros[ID] and self.Data.AllMacros[ID].Body
end 

function Lib:IsPerCharacter(ID)
	-- @return @boolean
	return ID and self.Data.AllMacros[ID] and self.Data.AllMacros[ID].perCharacter
end 

function Lib:IsExists(ID)
	-- @return @boolean
	return ID and self.Data.AllMacros[ID] and true
end 

function Lib:SetActionButton(ID, actionSlot)
	-- @return @number of the actionslot or @nil 
	-- @usage:
	-- Lib:SetActionButton(@string or @number[, @number])
	-- /dump LibStub("MacroLibrary"):SetActionButton(121, 1)
	-- 1. ID is a index or name of the macro
	-- 2. actionSlot is number (0-120) or nil to use first available slot from the latest available bar
	if (not InCombatLockdown() or issecure()) and self:IsExists(ID) then 
		 PickupMacro(ID)
		 
		 if CursorHasMacro() then 
			local slot 
			
			if actionSlot then 
				PlaceAction(actionSlot)
				slot = actionSlot
			else
				local used 
				for i = 120, 1, -1 do 
					used = GetActionInfo(i)
					if not used then 
						PlaceAction(i)
						slot = i												
						break 
					end 
				end 
			end 
			
			ClearCursor() 

			return slot
		 end 
	end 	
end 

function Lib:SetBinding(hotKey, ID)
	-- @return Flag - 1 if the binding has been changed successfully, nil otherwise
	-- @usage:
	-- Lib:SetBinding(@string or @nil, @string or @number)
	if (not InCombatLockdown() or issecure()) and self:IsExists(ID) then 
		return SetBindingMacro(hotKey, ID)
	end 
end 

-------------------------------------------------------------------------------
-- API - 'The Action'
-------------------------------------------------------------------------------
function Lib:CraftMacroSpellByObjects(perCharacter, ...)
	-- @usage Lib:CraftMacroSpellByObjects(@boolean or @nil, A.Spell1, A.Spell2, A.Spell3)
	local lastError, obj, error
	for i = 1, select("#", ...) do 
		obj   	= select(i, ...)
		error 	= self:CraftMacro((obj:Info()), nil, "#showtooltip\n/cast " .. (obj:Info()), perCharacter, true)
		if error == "MacroLimit" then 
			lastError = "MACROLIMIT"
		elseif error == "InCombatLockdown" then 
			lastError = "MACROINCOMBAT"
		end 
	end 
	
	if lastError then 
		Print(A.GetLocalization()[lastError])
	end
end 

function Lib:CraftMacroItemByObjects(perCharacter, ...)
	-- @usage Lib:CraftMacroSpellByObjects(@boolean or @nil, A.Item1, A.Item2, A.Item3)
	local lastError, obj, error
	for i = 1, select("#", ...) do 
		obj   	= select(i, ...)
		error 	= self:CraftMacro((obj:Info()), nil, "#showtooltip\n/use " .. (obj:Info()), perCharacter, true)
		if error == "MacroLimit" then 
			lastError = "MACROLIMIT"
		elseif error == "InCombatLockdown" then 
			lastError = "MACROINCOMBAT"
		end 
	end 
	
	if lastError then 
		Print(A.GetLocalization()[lastError])
	end
end 

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------
Listener:Add("ACTION_EVENT_MACRO_LIBRARY", "UPDATE_MACROS", 			Lib.UpdateMacros)
Listener:Add("ACTION_EVENT_MACRO_LIBRARY", "ACTIONBAR_SLOT_CHANGED", 	Lib.UpdateActionButton)

-------------------------------------------------------------------------------
-- Initial Action Slots Cache 
-------------------------------------------------------------------------------
Listener:Add("ACTION_EVENT_MACRO_LIBRARY", "PLAYER_LOGIN", function()
	Lib:UpdateActionButtons()
	Listener:Remove("ACTION_EVENT_MACRO_LIBRARY", "PLAYER_LOGIN")	
end)

-------------------------------------------------------------------------------
-- OnLoad
-------------------------------------------------------------------------------
Listener:Add("ACTION_EVENT_MACRO_LIBRARY", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then 
		-- Cache in tables all icons available for macros 
		GetLooseMacroIcons(Lib.Data.LooseIcons)
		GetLooseMacroItemIcons(Lib.Data.LooseItemsIcons)
		GetMacroIcons(Lib.Data.Icons)
		GetMacroItemIcons(Lib.Data.ItemIcons)

		MacroFrame_LoadUI()
		MacroFrame_Update				= _G.MacroFrame_Update 		or function() 						Lib.MacroFrame:Update() 							end 
		MacroFrame_SelectMacro			= _G.MacroFrame_SelectMacro or function(ID, scrollToSelected) 	Lib.MacroFrame:SelectMacro(ID, scrollToSelected) 	end 
		MacroFrame_Show					= _G.MacroFrame_Show 		or function() 						Lib.MacroFrame:Show() 								end
		Lib.MacroFrame 					= _G.MacroFrame
		Lib.MacroFrameTab1				= _G.MacroFrameTab1
		Lib.MacroFrameTab2				= _G.MacroFrameTab2
		
		-- This local will be overwritten by below 'function _G.DeleteMacro'
		DeleteMacro						= _G.DeleteMacro					
		
		Listener:Remove("ACTION_EVENT_MACRO_LIBRARY", "ADDON_LOADED")	
	end 
end)