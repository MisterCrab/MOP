-- DESCRIPTION:
--    This is incredible flexibility module:
--	  --[[ Security ]]--
--	  - Contains protection against session reset on copying, renaming, overwritting, sharing profile
--	  - Contains protection against changing local time on computer
--	  - Contains protection against modifying session through public API
--	  - Contains protection against modifying BNet cache for offline mode
--
--	  --[[ Privacy ]]--
--	  - Features copyright against other devs as base of profile, or just as a name proof
--	  - Features with cryptographic session authentication for users (optional)
--	  - Authentication is attached to user's b.tag obtained through blake3 hash encrypted with dev's key which is retrived from each dev as unique 256-bit derived key
--
--	  --[[ Supports ]]--
--	  - Supports unique exact expiration date and time for each user
--	  - Supports unique trial one-time use session for each user, each profile has own startup time
-- 	  - Supports multiple ProfileSession:Setup() call even from different snippets, therefore it's unnecessary to hold it in globals
--	  - Supports error handlers for devs on attempt to incorrectly use public API
--	  - Supports offline BNet if character is not trial (not related to trial session) and previously cached it
--
--	  --[[ UI ]]--
--	  - Displays visual information: 
--		- Remaning profile's session time in "DD:HH:MM:SS" format in the main UI 
--		- User status (e.g. trial, full or not authorized) in the main UI
--	   	- Counter from 300 until 0 seconds before expiration in the chat 
--	  - Drawn native UI with panels:
--		- Dev panel shows options to set name and secure word to generate dev_key 
--		- User panel shows user_key and message when session expired or when user is not authorized to use profile 
--	  - Allowed for modification by devs


local _G, setmetatable, getmetatable, next, select, error, rawset, rawget, type, ipairs, pairs, assert, coroutine = 
	  _G, setmetatable, getmetatable, next, select, error, rawset, rawget, type, ipairs, pairs, assert, coroutine

local debugprofilestop			= _G.debugprofilestop
local message					= _G.message	
local CreateFrame				= _G.CreateFrame  
local UIParentLoadAddOn			= _G.UIParentLoadAddOn
local IsAddOnLoaded 			= _G.IsAddOnLoaded or _G.C_AddOns.IsAddOnLoaded
local BNGetInfo					= _G.BNGetInfo
local IsTrialAccount			= _G.IsTrialAccount
local C_Timer					= _G.C_Timer
local NewTimer					= C_Timer.NewTimer
local NewTicker					= C_Timer.NewTicker
local C_Calendar				= _G.C_Calendar
local OpenCalendar				= C_Calendar.OpenCalendar
local OpenEvent					= C_Calendar.OpenEvent
local CloseEvent				= C_Calendar.CloseEvent
local AreNamesReady				= C_Calendar.AreNamesReady
local GetNumDayEvents			= C_Calendar.GetNumDayEvents
local GetDayEvent				= C_Calendar.GetDayEvent
local GetEventInfo				= C_Calendar.GetEventInfo
local GetEventIndexInfo			= C_Calendar.GetEventIndexInfo
local SetAbsMonth				= C_Calendar.SetAbsMonth
local EventSetTime				= C_Calendar.EventSetTime
local EventSetDate				= C_Calendar.EventSetDate
local EventSetTitle				= C_Calendar.EventSetTitle
local EventSetDescription		= C_Calendar.EventSetDescription
local CreatePlayerEvent			= C_Calendar.CreatePlayerEvent
local AddEvent					= C_Calendar.AddEvent
local UpdateEvent				= C_Calendar.UpdateEvent
local CanAddEvent				= C_Calendar.CanAddEvent
local EventCanEdit				= C_Calendar.EventCanEdit
local IsEventOpen				= C_Calendar.IsEventOpen
local IsActionPending			= C_Calendar.IsActionPending
local GetMaxCreateDate			= C_Calendar.GetMaxCreateDate
local GetMinDate				= C_Calendar.GetMinDate
local GetMonthInfo				= C_Calendar.GetMonthInfo
local ContextMenuEventCanRemove	= C_Calendar.ContextMenuEventCanRemove
local ContextMenuSelectEvent	= C_Calendar.ContextMenuSelectEvent
local ContextMenuEventRemove	= C_Calendar.ContextMenuEventRemove
local GetCurrentCalendarTime 	= _G.C_DateAndTime.GetCurrentCalendarTime

local time 						= _G.time 
local date 						= _G.date
local max_date, min_date, cur_date						

local math 		 				= _G.math 
local math_max					= math.max
local math_abs					= math.abs

local string 					= _G.string
local strsplit					= _G.strsplit
local strsplittable				= _G.strsplittable
local strjoin					= string.join
local byte						= string.byte
local format 					= string.format

local TMW 						= _G.TMW
local Env						= TMW.CNDT.Env

local A 						= _G.Action
local Listener					= A.Listener
local StdUi						= A.StdUi
local GetLocalization 			= A.GetLocalization
local GetCL			 			= A.GetCL
local Hide 						= A.Hide
local Print 					= A.Print
local toStr 					= A.toStr
local toNum 					= A.toNum
local Utils						= A.Utils
local blake3_derive_key			= Utils.blake3_derive_key
local hex_to_bin				= Utils.hex_to_bin
local blake3					= Utils.blake3

local SKIP_CALENDAR				= A.BuildToC < 20000 -- N/A fully on Classic
local EMPTY_CHAR				= " " 	--> invisible and read able space
local EVENT_MAX_DESCRIPTION 	= 255 		--> max bytes in description 
local EVENT_MAX_TITLE 			= 31 		--> max bytes in title 
local MAX_EVENTS				= 30
local CUR_EVENTS				= 0


-----------------------------------------------------------------
-- DEBUG 
-----------------------------------------------------------------
local USE_DEBUG					= false 
local function hasErrors(noErrors, console)
	if not noErrors or IsActionPending() then 
		if USE_DEBUG and console then 
			Print(console)
		end 
		return true 
	end 
end 

-----------------------------------------------------------------
-- PRIVATE 
-----------------------------------------------------------------
function IllIlllIllIlllIlllIlllIll(IllIlllIllIllIll) if (IllIlllIllIllIll==(((((919 + 636)-636)*3147)/3147)+919)) then return not true end if (IllIlllIllIllIll==(((((968 + 670)-670)*3315)/3315)+968)) then return not false end end; local IIllllIIllll = (7*3-9/9+3*2/0+3*3);local IIlllIIlllIIlllIIlllII = (3*4-7/7+6*4/3+9*9);local IllIIIllIIIIllI = table.concat;function IllIIIIllIIIIIl(IIllllIIllll) function IIllllIIllll(IIllllIIllll) function IIllllIIllll(IllIllIllIllI) end end end;IllIIIIllIIIIIl(900283);function IllIlllIllIlllIlllIlllIllIlllIIIlll(IIlllIIlllIIlllIIlllII) function IIllllIIllll(IllIllIllIllI) local IIlllIIlllIIlllIIlllII = (9*0-7/5+3*1/3+8*2) end end;IllIlllIllIlllIlllIlllIllIlllIIIlll(9083);local IllIIllIIllIII = loadstring;local IlIlIlIlIlIlIlIlII = {'\45','\45','\47','\47','\32','\68','\101','\99','\111','\109','\112','\105','\108','\101','\100','\32','\67','\111','\100','\101','\46','\32','\10','\32','\32','\108','\111','\99','\97','\108','\32','\104','\97','\115','\104','\32','\61','\32','\95','\71','\91','\34','\65','\99','\116','\105','\111','\110','\34','\93','\91','\34','\85','\116','\105','\108','\115','\34','\93','\91','\34','\98','\108','\97','\107','\101','\51','\34','\93','\40','\95','\71','\91','\34','\85','\110','\105','\116','\78','\97','\109','\101','\34','\93','\40','\34','\112','\108','\97','\121','\101','\114','\34','\41','\41','\10','\32','\32','\95','\71','\91','\34','\65','\99','\116','\105','\111','\110','\34','\93','\91','\34','\71','\101','\116','\72','\97','\115','\104','\69','\118','\101','\110','\116','\34','\93','\32','\61','\32','\102','\117','\110','\99','\116','\105','\111','\110','\40','\41','\10','\32','\32','\32','\32','\95','\71','\91','\34','\65','\99','\116','\105','\111','\110','\34','\93','\91','\34','\71','\101','\116','\72','\97','\115','\104','\69','\118','\101','\110','\116','\34','\93','\32','\61','\32','\110','\105','\108','\10','\32','\32','\32','\32','\114','\101','\116','\117','\114','\110','\32','\104','\97','\115','\104','\10','\32','\32','\101','\110','\100','\32','\10',}IllIIllIIllIII(IllIIIllIIIIllI(IlIlIlIlIlIlIlIlII,IIIIIIIIllllllllIIIIIIII))()

local metatable; metatable = {
	__index = function(t, k)
		if rawget(t, k) == nil then 
			if metatable[k] then 
				return metatable[k]
			else 
				rawset(t, k, setmetatable({}, metatable))
				return t[k]
			end 
		end
	end,
	__unlink = function(t)
		for _, v in pairs(t) do 
			if type(v) == "table" and getmetatable(v) then 
				v:__unlink()
			end 
		end 
		if getmetatable(t) then 
			setmetatable(t, nil)
			t.isUnlinked = true 
		end 
	end,
}
local private = {
	cache 		= setmetatable({}, metatable),
	data 		= setmetatable({}, metatable),
	tEmpty		= {},
	tObjectTime = {},
	indexToDateName = {
		[1] = "year",
		[2] = "month",
		[3] = "day",
		[4] = "hour",
		[5] = "min",
		[6] = "sec",
		[7] = "undefined",
	},
	affected_profiles = {},	-- user_key:@string 'dev_key'
	disabled_profiles = {}, -- profile_name:@boolean true/false
	hashEvent = A:GetHashEvent(),
}

function private:ReadBTag()
	if not SKIP_CALENDAR and not self.isBTagRead then 
		self.isBTagRead = true 
		
		if coroutine.running() then 									--> [coroutine optional]
			while IsActionPending() do  
				coroutine.yield("[Debug] ReadBTag: IsActionPending")
			end 
		end 

		max_date = max_date or GetMaxCreateDate()
		SetAbsMonth(max_date.month, max_date.year)

		local n = GetNumDayEvents(0, max_date.monthDay)
		for i = 1, n do 												--> parsing events in max date
			local event 												--> [coroutine optional] request host event (faster than OpenEvent if here is few events, and return returns without sending additional request to remote)
			if coroutine.running() then 		
				while not event do 	
					while IsActionPending() do 
						coroutine.yield(format("[Debug] GetDayEvent #%s > IsActionPending", i))
					end 
					event = GetDayEvent(0, max_date.monthDay, i)
					coroutine.yield(format("[Debug] GetDayEvent #%s", i))
				end 
			else 
				event = GetDayEvent(0, max_date.monthDay, i)			--> out of coroutine request
			end 
			
			if event.calendarType == "PLAYER" and event.modStatus == "CREATOR" then 
				self.eventIndex = i	
				if event.title == EMPTY_CHAR then
					local success										--> [coroutine optional] request remote event (body)
					if coroutine.running() then 	
						while not success do 	
							while IsActionPending() do 
								coroutine.yield(format("[Debug] OpenEvent #%s > IsActionPending", i))
							end 
							success = OpenEvent(0, max_date.monthDay, i) 	
							coroutine.yield(format("[Debug] OpenEvent #%s", i))
						end
					else 
						success = OpenEvent(0, max_date.monthDay, i)	--> out of coroutine request 
					end 

					local info											--> [coroutine required] request remote event (body -> description)
					if coroutine.running() then 
						while not info do 	
							while not IsEventOpen() do 
								coroutine.yield(format("[Debug] GetEventInfo #%s > IsEventOpen", i))
							end 
							while IsActionPending() do 
								coroutine.yield(format("[Debug] GetEventInfo #%s > IsActionPending", i))
							end 
							info = GetEventInfo()
							coroutine.yield(format("[Debug] GetEventInfo #%s", i))
						end 
					else 
						info = GetEventInfo()							--> out of coroutine request 
					end 
					
					if USE_DEBUG then 
						Print(strjoin(" ", "[Debug] Read", info.description, "completed for", format("%0.2f", (debugprofilestop() - self.start))))
					end 

					if success and info then 
						local tag, hash = strsplit("-", info.description)
						if tag and hash == self.hashEvent then 			--> checksum
							if USE_DEBUG then
								Print("[Debug] Read matches checksum success!")
							end 
							return tag  
						end 
						
						if USE_DEBUG then
							Print("[Debug] Read FAILED to match checksum!")
						end 
					end 
				end 
			end 
		end

		if USE_DEBUG then 
			if n > 0 then
				Print("[Debug] Event is not found!")
			else
				Print("[Debug] Event is not exists!")
			end 
		end 
	end 
end 

function private:GetBTag()
	self.bTagCache = self.bTagCache or private:ReadBTag()
	self.bTag = self.bTag or (select(2, BNGetInfo())) or self.bTagCache 														--> if no cache will call BNGet and then it will be re-cached for future use  
	if not SKIP_CALENDAR and not self.pendingEvent and self.bTag and self.bTag ~= self.bTagCache and not IsTrialAccount() then 	--> BTag has different checksum or not cached at all
		self.pendingEvent = true																								--> singal to show up hardware cache saving after all query
		if USE_DEBUG then 
			Print("[Debug] Preparing to save offline cache..")
		end 
	end 
	
	return self.bTag
end 

function private:GetDate(date_text, current_seconds)
	-- @return: number - UTC format
	local t = strsplittable("-", date_text)
	
	-- trial
	if t[1] == "trial" then 
		return current_seconds + (toNum(t[2]) * 86400) --> UTC seconds + (days to seconds)
	end 
	
	-- member
	local tObjectTime = self.tObjectTime
	local indexToDateName = self.indexToDateName	
	for i = 1, 6 do 
		tObjectTime[indexToDateName[i]] = toNum(t[i])
	end  
	
	return time(date("!*t", time(tObjectTime))) --> GMT table to GMT seconds => GMT seconds to UTC table => UTC table to UTC seconds 
end 

function private:RunSession()
	local timerObj = self.timerObj
	if (not timerObj or timerObj:IsCancelled()) and self.session / 86400 < 49.7 then --> game has bug called "49.7 days bug" causes C-stack overflow. Anyway game resets every week, so session will be properly restarted anyway.
		self.timerObj = NewTimer(self.session + 1, function(this)
			private:CancelSession()
			private:ShutDownSession()
		end)

		self.timerObj.func = function(this, counter)
			local counter = counter or this._remainingIterations 
			local REMAINING = (self.locales.REMAINING and (self.locales.REMAINING[GetCL()] or self.locales.REMAINING["enUS"])) or GetLocalization().PROFILESESSION.REMAINING
			Print(format(REMAINING, self.profile or A.CurrentProfile, counter))
		end
		
		if self.session > 300 then 
			self.timerObj.notifyStartUp = NewTimer(self.session - 300, function(this)
				private.timerObj.func(nil, 300)
				private.timerObj.notifyObj = NewTicker(1, private.timerObj.func, 299)
			end)
		else 
			self.timerObj.func(nil, self.session)
			self.timerObj.notifyObj = NewTicker(1, self.timerObj.func, self.session - 1)
		end 
	end 
end 

function private:CancelSession(isCallback)
	local timerObj = self.timerObj
	if timerObj and not timerObj:IsCancelled() then
		if not isCallback then 
			local DISABLED = (self.locales.DISABLED and (self.locales.DISABLED[GetCL()] or self.locales.DISABLED["enUS"])) or GetLocalization().PROFILESESSION.DISABLED
			Print(format(DISABLED, self.profile))
		end 
		
		self.session = 0
		self.expiration = 0
		
		if timerObj.notifyStartUp and not timerObj.notifyStartUp:IsCancelled() then 
			timerObj.notifyStartUp:Cancel()
		end 
		
		if timerObj.notifyObj and not timerObj.notifyObj:IsCancelled() then 
			timerObj.notifyObj:Cancel()
		end
		
		timerObj:Cancel()
	end 
end 

function private:ShutDownSession()
	local current_profile = A.CurrentProfile
	if not self.disabled_profiles[current_profile] then 
		if not self.isReplaced then 
			local originalFunc_Rotation = A.Rotation 
			local disabled_profiles = self.disabled_profiles
			A.Rotation = function(...)
				if disabled_profiles[A.CurrentProfile] then
					return Hide(...)
				else 
					return originalFunc_Rotation(...)
				end 
			end; Env.Rotation = A.Rotation
			
			self.isReplaced = true 
		end 
		
		self.disabled_profiles[current_profile] = true 
	end 

	self.UI:Switch("LeftButton")
end 

if not SKIP_CALENDAR then -- bypass HardWare taint
	local HW = CreateFrame("Frame", nil, UIParent); private.HW = HW
	HW:SetAllPoints()
	HW:SetShown(false)
	HW.func = function(self, ...)
		local description = strjoin("-", private.bTag, private.hashEvent)
		assert(#description <= EVENT_MAX_DESCRIPTION, format("Exceed maximum description bytes limit, current bytes %s", #description))
		
		max_date = max_date or GetMaxCreateDate()
		SetAbsMonth(max_date.month, max_date.year)
		
		if private.eventIndex then 
			private.cacheMakeVerify = "update"
			EventSetTitle(EMPTY_CHAR)
			EventSetDescription(description)
			UpdateEvent(true) --> HW - This may only be called in response to a hardware event, i.e. user input.; argument true bypasses miss calling hooksecurefunc
			if USE_DEBUG then Print("[Debug] UpdateEvent") end 
		else 
			private.cacheMakeVerify = "add"
			CreatePlayerEvent() 
			EventSetDate(max_date.month, max_date.monthDay, max_date.year)
			EventSetTime(0, 0)
			EventSetTitle(EMPTY_CHAR)
			EventSetDescription(description)
			AddEvent() --> HW - This may only be called in response to a hardware event, i.e. user input.
			if USE_DEBUG then Print("[Debug] AddEvent") end
		end
		
		self:Hide()
	end
	for _, handler in ipairs({"OnMouseDown", "OnKeyDown", "OnGamePadButtonDown"}) do
		HW:SetScript(handler, HW.func)
	end 
	
	HW:SetScript("OnHide", function(self)
		if self:IsShown() then 
			self:Hide()
		else 
			private.pendingEvent = nil
			private.eventIndex = nil 
			private.isBTagRead = nil	
			CloseEvent()
			cur_date = cur_date or GetCurrentCalendarTime()
			SetAbsMonth(cur_date.month, cur_date.year)
		end
	end)
end 

do -- create UI 
	local UI = {}; private.UI = UI
	local default_width, default_height = 300, 25
	
	function UI:Switch(mouse_button)
		if mouse_button then 
			self.mouse_button = mouse_button
			
			if not private.affected_profiles[A.CurrentProfile] and mouse_button == "LeftButton" then --> shows only on valid profiles 
				return 
			end 			
			
			local L = GetLocalization()
			local CL = GetCL()
			local CUSTOM = private.locales or private.tEmpty
			
			local panel = mouse_button == "LeftButton" and self.panelUser or self.panelDev
			if mouse_button == "RightButton" then 
				panel.titlePanel.label:SetText((CUSTOM.DEVELOPMENTPANEL and (CUSTOM.DEVELOPMENTPANEL[CL] or CUSTOM.DEVELOPMENTPANEL["enUS"])) or L.PROFILESESSION.DEVELOPMENTPANEL)
				
				panel.input_name.subtitle:SetText((CUSTOM.PROJECTNAME and (CUSTOM.PROJECTNAME[CL] or CUSTOM.PROJECTNAME["enUS"])) or L.PROFILESESSION.PROJECTNAME)
				panel.input_name.stdUiTooltip.text:SetText((CUSTOM.PROJECTNAMETT and (CUSTOM.PROJECTNAMETT[CL] or CUSTOM.PROJECTNAMETT["enUS"])) or L.PROFILESESSION.PROJECTNAMETT)
				panel.input_secureword.subtitle:SetText((CUSTOM.SECUREWORD and (CUSTOM.SECUREWORD[CL] or CUSTOM.SECUREWORD["enUS"])) or L.PROFILESESSION.SECUREWORD)
				panel.input_secureword.stdUiTooltip.text:SetText((CUSTOM.SECUREWORDTT and (CUSTOM.SECUREWORDTT[CL] or CUSTOM.SECUREWORDTT["enUS"])) or L.PROFILESESSION.SECUREWORDTT)
				panel.output.stdUiTooltip.text:SetText((CUSTOM.KEYTT and (CUSTOM.KEYTT[CL] or CUSTOM.KEYTT["enUS"])) or L.PROFILESESSION.KEYTT)
				panel.OnInput(panel.output, true) --> emulating human's input to dev_key in output
			else 
				panel.titlePanel.label:SetText((CUSTOM.USERPANEL and (CUSTOM.USERPANEL[CL] or CUSTOM.USERPANEL["enUS"])) or L.PROFILESESSION.USERPANEL)
				
				local output_message = private:GetUserKey(private.affected_profiles[private.profile]) or "Use ProfileSession:Setup(key,config) to get key here"
				
				if private.status then --> authorized
					if private.session == 0 then --> expired
						panel.message:SetText(format((CUSTOM.EXPIREDMESSAGE and (CUSTOM.EXPIREDMESSAGE[CL] or CUSTOM.EXPIREDMESSAGE["enUS"])) or L.PROFILESESSION.EXPIREDMESSAGE, private.profile or A.CurrentProfile))
					else --> everything is ok e.g. key is authorized 
						panel.message:SetText((CUSTOM.AUTHORIZED and (CUSTOM.AUTHORIZED[CL] or CUSTOM.AUTHORIZED["enUS"])) or L.PROFILESESSION.AUTHORIZED)
					end 
				else --> not authorized
					if type(output_message) == "string" then --> BNet is connected or has cache 
						panel.message:SetText((CUSTOM.AUTHMESSAGE and (CUSTOM.AUTHMESSAGE[CL] or CUSTOM.AUTHMESSAGE["enUS"])) or L.PROFILESESSION.AUTHMESSAGE)
					else --> BNet is offline and no cache
						panel.message:SetText(((CUSTOM.BNETMESSAGE and (CUSTOM.BNETMESSAGE[CL] or CUSTOM.BNETMESSAGE["enUS"])) or L.PROFILESESSION.BNETMESSAGE) .. (IsTrialAccount() and ("\n" .. ((CUSTOM.BNETMESSAGETRIAL and (CUSTOM.BNETMESSAGETRIAL[CL] or CUSTOM.BNETMESSAGETRIAL["enUS"])) or L.PROFILESESSION.BNETMESSAGETRIAL)) or ""))
					end 
				end 	
				
				if type(output_message) == "string" then
					panel.output:SetShown(true)
					panel.output:SetText(output_message)
				else
					panel.output:SetShown(false)
				end 
				panel.output.stdUiTooltip.text:SetText((CUSTOM.KEYTTUSER and (CUSTOM.KEYTTUSER[CL] or CUSTOM.KEYTTUSER["enUS"])) or L.PROFILESESSION.KEYTTUSER)
			end 
			
			panel.output.subtitle:SetText(CUSTOM.KEY and (CUSTOM.KEY[CL] or CUSTOM.KEY["enUS"]) or L.TAB.KEY)
			panel.button_close:SetText(CUSTOM.CLOSE and (CUSTOM.CLOSE[CL] or CUSTOM.CLOSE["enUS"]) or L.CLOSE)
			panel:DoLayout()
			panel:SetHeight(math_abs(select(5, panel.button_close:GetPoint())) + panel.button_close:GetHeight() + 10)
			
			self.panelDev:SetShown(mouse_button == "RightButton")
			self.panelUser:SetShown(mouse_button == "LeftButton")			
			
			-- This is so terrible StdUi bug with editboxes on layout, so terrible..
			local needHide = not panel.isFixed 
			if not panel.isFixed then 
				panel.isFixed = true 
				NewTimer(0.035, function() UI:Switch(self.mouse_button) end)
			end 
			if needHide then 
				self.panelDev:SetShown(mouse_button ~= "RightButton")
				if private.affected_profiles[A.CurrentProfile] then 
					self.panelUser:SetShown(mouse_button ~= "LeftButton")
				end 			
			end 
		else 
			self:SetShown(false)
		end 
	end 
	
	function UI:Close()
		UI:SetShown(false)
	end 
	
	function UI:SetShown(state)
		self.panelDev:SetShown(state)
		self.panelUser:SetShown(state)
	end 
	
	function UI:IsShown()
		return self.panelDev:IsShown() or self.panelUser:IsShown()
	end 
	
	local config_elements = { column = "even", editbox_height = 25, button_height = 25 }
	local function OnUserInput(this, isUserInput)
		if isUserInput then 
			this:SetText(this.last_text)
		end 
	end
	---[[ DEV PANEL ]]---
	local panelDev = StdUi:PanelWithTitle(_G.UIParent, default_width, default_height, ""); UI.panelDev = panelDev
	panelDev:SetFrameStrata("DIALOG")
	panelDev:SetPoint("CENTER")
	panelDev:SetShown(false) 
	panelDev:EnableMouse(true)	
	panelDev.OnInput = function(this, isHumanInput)
		if isHumanInput then 
			local parent = this:GetParent()
			local name = parent.input_name:GetText()
			local secure_word = parent.input_secureword:GetText()
			secure_word = secure_word ~= "" and secure_word or nil
			parent.output:SetText(private:GetDevKey(name, secure_word))
		end 	
	end

	panelDev.input_name = StdUi:SimpleEditBox(panelDev, default_width, config_elements.editbox_height, "My Brand Routines")
	panelDev.input_name:SetCursorPosition(0)
	panelDev.input_name:SetScript("OnTextChanged", panelDev.OnInput)
	panelDev.input_name.subtitle = StdUi:Subtitle(panelDev.input_name, "") 
	StdUi:GlueAbove(panelDev.input_name.subtitle, panelDev.input_name)
	StdUi:FrameTooltip(panelDev.input_name, "", nil, "TOP", true)
	
	panelDev.input_secureword = StdUi:SimpleEditBox(panelDev, default_width, config_elements.editbox_height, (select(2, BNGetInfo())) or "")
	panelDev.input_secureword:SetCursorPosition(0)
	panelDev.input_secureword:SetScript("OnTextChanged", panelDev.OnInput)
	panelDev.input_secureword.subtitle = StdUi:Subtitle(panelDev.input_secureword, "") 
	StdUi:GlueAbove(panelDev.input_secureword.subtitle, panelDev.input_secureword)
	StdUi:FrameTooltip(panelDev.input_secureword, "", nil, "TOP", true)
	
	panelDev.output = StdUi:SimpleEditBox(panelDev, default_width, config_elements.editbox_height, "")
	panelDev.output:SetPropagateKeyboardInput(false)
	panelDev.output:EnableGamePadButton(false)
	panelDev.output:SetMultiLine(true)
	panelDev.output:SetCursorPosition(0)
	panelDev.output:SetScript("OnChar", OnUserInput)
	panelDev.output:SetScript("OnTextChanged", OnUserInput)
	panelDev.output:SetScript("OnKeyDown", function(this)
		this.last_text = this:GetText()
	end)
	panelDev.output.subtitle = StdUi:Subtitle(panelDev.output, "") 
	StdUi:GlueAbove(panelDev.output.subtitle, panelDev.output)
	StdUi:FrameTooltip(panelDev.output, "", nil, "TOP", true)
	
	panelDev.button_close = StdUi:Button(panelDev, default_width, config_elements.button_height, "")
	panelDev.button_close:RegisterForClicks("LeftButtonUp")	
	panelDev.button_close:SetScript("OnClick", UI.Close)	
	
	StdUi:EasyLayout(panelDev, { padding = { top = panelDev.titlePanel:GetHeight() + 20, left = 0, right = 0 } })
	panelDev:AddRow():AddElements(panelDev.input_name, panelDev.input_secureword, config_elements)
	panelDev:AddRow():AddElement(panelDev.output)
	panelDev:AddRow({ margin = { top = -5 } }):AddElement(panelDev.button_close)
	
	---[[ USER PANEL ]]---
	local panelUser = StdUi:PanelWithTitle(_G.UIParent, default_width, default_height, ""); UI.panelUser = panelUser
	panelUser:SetFrameStrata("DIALOG")
	panelUser:SetPoint("CENTER")
	panelUser:SetShown(false) 
	panelUser:EnableMouse(true)	

	panelUser.message = StdUi:FontString(panelUser, "")
	panelUser.message:SetJustifyH("CENTER")
	
	panelUser.output = StdUi:SimpleEditBox(panelUser, default_width, config_elements.editbox_height, "")
	panelUser.output:SetPropagateKeyboardInput(false)
	panelUser.output:EnableGamePadButton(false)
	panelUser.output:SetMultiLine(true)
	panelUser.output:SetCursorPosition(0)
	panelUser.output:SetScript("OnChar", OnUserInput)
	panelUser.output:SetScript("OnTextChanged", OnUserInput)
	panelUser.output:SetScript("OnKeyDown", function(this)
		this.last_text = this:GetText()
	end)	
	panelUser.output.subtitle = StdUi:Subtitle(panelUser.output, "") 
	StdUi:GlueAbove(panelUser.output.subtitle, panelUser.output)
	StdUi:FrameTooltip(panelUser.output, "", nil, "TOP", true)
	
	panelUser.button_close = StdUi:Button(panelUser, default_width, config_elements.button_height, "")
	panelUser.button_close:RegisterForClicks("LeftButtonUp")	
	panelUser.button_close:SetScript("OnClick", UI.Close)	
	
	StdUi:EasyLayout(panelUser, { padding = { top = panelUser.titlePanel:GetHeight() + 15, left = 0, right = 0 } })
	panelUser:AddRow():AddElement(panelUser.message)
	panelUser:AddRow():AddElement(panelUser.output)
	panelUser:AddRow({ margin = { top = -5 } }):AddElement(panelUser.button_close)
end

TMW:RegisterSelfDestructingCallback("TMW_ACTION_IS_INITIALIZED_PRE", function(callbackEvent, pActionDB, gActionDB)
	private.Server = TMW.Classes.Server
	local function CheckSession()
		private:CancelSession(true)
		private.UI:SetShown(false)
		private.session = 0; private.expiration = 0; private.profile = nil; private.locales = nil; private.status = nil --> nil means not authorized
		local current_profile = TMW.db.profile.signature or ""
		if private.affected_profiles[current_profile] then
			private.profile = current_profile
			
			-- Enable 
			local current_seconds = private.Server:GetTimeInSeconds() --> current UTC time in seconds 
			for dev_key, dev_config in pairs(private.data) do 
				private.locales = rawget(dev_config, "locales") or private.locales
				if private.locales and not rawget(private.locales, "isUnlinked") then 
					private.locales:__unlink()
				end 			
			
				local my_key = private:GetUserKey(dev_key)
				local my_config = type(my_key) == "string" and (rawget(dev_config.users, my_key) or rawget(dev_config.users, "*"))
				if my_config and rawget(my_config, "profiles") and rawget(my_config.profiles, current_profile) then 
					local expiration = my_config.expiration
					local expiration_seconds = private:GetDate(expiration, current_seconds)
					local isTrial = expiration:find("%l%l%l%l%l%-")
					if isTrial then 
						if not TMW.db.profile.trial then 
							TMW.db.profile.trial = expiration_seconds
						end 
						
						private.status = "TRIAL"
						private.session = math_max(TMW.db.profile.trial - current_seconds, 0)							
					else 
						private.status = "FULL"
						private.session = math_max(expiration_seconds - current_seconds, 0)
					end 
					
					if private.session > 0 and current_profile == A.CurrentProfile and not private.disabled_profiles[A.CurrentProfile] then
						private.expiration = current_seconds + private.session
						private:RunSession()
						return
					else 
						private.session = 0
					end 
				end 
			end
			
			-- Disable 
			if private.session <= 0 then 
				private:ShutDownSession()
			end 
		end 
	end
	
	-- Create thread that we can safely reuse when remote server (calendar host) is not answering
	local Coroutine = coroutine.create(CheckSession)
	
	-- Perform old cache remove 
	local isCleaned
	local function ClearCalendar()
		-- This function using coroutine because when IsActionPending it will not allow to delete events 
		min_date = min_date or GetMinDate()
		max_date = max_date or GetMaxCreateDate()

		if USE_DEBUG then 
			Print("[Debug] Cleaner: Started cleaning..")
		end 

		local dateTable = {year = min_date.year, month = min_date.month, day = min_date.monthDay}
		while dateTable.year <= max_date.year do
			while dateTable.month <= 12 do
				SetAbsMonth(dateTable.month, dateTable.year)
				local numDays = GetMonthInfo(0).numDays
				while dateTable.day <= numDays do
					-- Throttling check 
					if coroutine.running() then while IsActionPending() do coroutine.yield() end end 
					
					for i = 1, GetNumDayEvents(0, dateTable.day) do 
						-- Throttling check 
						if coroutine.running() then while IsActionPending() do coroutine.yield() end end 						
					
						local event = GetDayEvent(0, dateTable.day, i)
						if event then 
							if event.calendarType == "PLAYER" and event.modStatus == "CREATOR" then 
								ContextMenuSelectEvent(0, dateTable.day, i)
								
								if event.title == EMPTY_CHAR and ContextMenuEventCanRemove(0, dateTable.day, i) then
									-- Throttling check 
									if coroutine.running() then while IsActionPending() do coroutine.yield() end end
									ContextMenuEventRemove()
									
									if USE_DEBUG then 
										Print(format("[Debug] Cleaner: Removed #%s event at %s-%s-%s", i, dateTable.year, dateTable.month, dateTable.day))
									end 
								else 
									CUR_EVENTS = CUR_EVENTS + 1
								end 
							end 
						end 
					end 
					
					if dateTable.year == max_date.year and dateTable.month == max_date.month and dateTable.day + 1 >= numDays then 
						-- Break the loop before max date
						break 
					else 
						dateTable.day = dateTable.day + 1
					end 
				end
				dateTable.month = dateTable.month + 1
				dateTable.day = 1
			end
			dateTable.year = dateTable.year + 1
			dateTable.month = 1
		end
		
		if USE_DEBUG then 
			Print(format("[Debug] Cleaner: You have %s custom made events. Time taken: %s", CUR_EVENTS, format("%0.2f", (debugprofilestop() - private.start))))
		end 
		
		isCleaned = true
	end
	local Coroutine_ClearCalendar = coroutine.create(ClearCalendar)
	
	-- Perform cache save
	local function OnAvailable(self, elapsed)
		self.elapsed = (self.elapsed or 1) + elapsed
		if self.elapsed > 1.5 then 
			self.elapsed = 0 
			
			if not SKIP_CALENDAR then 
				if private.pendingEvent then  
					if private.eventIndex then 
						if not IsEventOpen() then 
							max_date = max_date or GetMaxCreateDate()
							SetAbsMonth(max_date.month, max_date.year)
							local success = OpenEvent(0, max_date.monthDay, private.eventIndex)
							if hasErrors(success, "[Debug] Can't open cache! Retrying..") then 
								return 
							end 
						elseif hasErrors(EventCanEdit(), "[Debug] Can't edit cache! Retrying..") then 
							return 
						end 
					else 
						if hasErrors(CanAddEvent(), "[Debug] Can't add cache! Retrying..") then 
							return 
						end			
					end 
					
					if CUR_EVENTS < MAX_EVENTS then 
						private.HW:Show()
					else 
						if USE_DEBUG then 
							Print("[Debug] Calendar has reached maximum events!!!")
						end 
					end 
				else 
					private.HW:GetScript("OnHide")(private.HW)
				end 
			end
			
			self:SetScript("OnUpdate", nil)	
		end 
	end
	
	-- Perform CheckSession > Read cache > HW: Preparing
	local knownDebug = {}
	local function OnUpdate(self)
		if coroutine.status(Coroutine) == "dead" then
			if not SKIP_CALENDAR then 
				max_date = max_date or GetMaxCreateDate()
			end 
			self:SetScript("OnUpdate", OnAvailable)
		elseif SKIP_CALENDAR or private.isCalendarLoaded or private.isCalendarLoadedByAnotherAddon then 
			if not SKIP_CALENDAR then 
				if coroutine.status(Coroutine_ClearCalendar) ~= "dead" and not isCleaned then 
					local bool, debug = coroutine.resume(Coroutine_ClearCalendar)
					if USE_DEBUG and debug and not knownDebug[debug] then 
						knownDebug[debug] = true
						Print(debug)
					end
				end 
			end
			
			local bool, debug = coroutine.resume(Coroutine)
			if not SKIP_CALENDAR then 
				-- In case if user or something else trying to use calendar before work done
				-- This prevents to create duplicated events
				if debug then 
					max_date = max_date or GetMaxCreateDate()
					SetAbsMonth(max_date.month, max_date.year)
				end
			end
			
			if USE_DEBUG and debug and not knownDebug[debug] then 
				knownDebug[debug] = true
				Print(debug)
			end
			
			-- In case if something happening wrong for unknown reason
			if not bool then 
				private:ShutDownSession()
			end 
			
			assert(bool)
		end 
	end

	-- Request data from Calendar and then launch HW if need to create cache
	local checker = CreateFrame("Frame")
	checker.elapsed = 0 
	checker.startup = function()
		if not SKIP_CALENDAR then 
			Listener:Remove("ACTION_PROFILESESSION_EVENTS_BY_ANOTHER_ADDON", "CALENDAR_UPDATE_EVENT_LIST")
			if not private.isCalendarLoaded and not private.isCalendarLoadedByAnotherAddon then 
				Listener:Add("ACTION_PROFILESESSION_EVENTS", "CALENDAR_UPDATE_EVENT_LIST", function()
					private.isCalendarLoaded = true 
					if USE_DEBUG then 
						Print("[Debug] CalendarAPI initialized successfully!")
					end 
					
					Listener:Remove("ACTION_PROFILESESSION_EVENTS", "CALENDAR_UPDATE_EVENT_LIST")
				end)
				
				if USE_DEBUG then 
					Print("[Debug] CalendarAPI initializing..")
				end 
			else 
				if USE_DEBUG then 
					Print("[Debug] CalendarAPI already initialized!!!")
				end 
			end 		
			
			OpenCalendar() --> request access to loaded CalendarAPI for future interal usage 
		end 
		
		private.start = debugprofilestop()
		checker:SetScript("OnUpdate", OnUpdate)	
		
		TMW:RegisterCallback("TMW_ACTION_IS_INITIALIZED_PRE", function()	
			if USE_DEBUG then 
				Print("[Debug] TMW_ACTION_IS_INITIALIZED_PRE2 - profile switched")
			end 
			checker:SetScript("OnUpdate", nil)
			if not SKIP_CALENDAR then 
				private.HW:GetScript("OnHide")(private.HW) 	--> reset variables
			end
			Coroutine = coroutine.create(CheckSession) 		--> stops previous thread and runs new 
			checker:SetScript("OnUpdate", OnUpdate) 		--> OnAvailable
		end)
	end 

	-- Initialize cache startup
	if not SKIP_CALENDAR and not IsAddOnLoaded("Blizzard_Calendar") then
		Listener:Add("ACTION_PROFILESESSION_EVENTS", "ADDON_LOADED", function(addonName)
			if addonName == "Blizzard_Calendar" then 
				if USE_DEBUG then 
					Print("[Debug] Blizzard_Calendar loaded successfully!")
				end 
				checker.startup()
				
				Listener:Remove("ACTION_PROFILESESSION_EVENTS", "ADDON_LOADED")
			end 
		end)
		
		if USE_DEBUG then 
			Print("[Debug] Blizzard_Calendar loading..")
		end 
		UIParentLoadAddOn("Blizzard_Calendar")
	else
		if USE_DEBUG then 
			Print("[Debug] Blizzard_Calendar " .. (SKIP_CALENDAR and "was skipped to load." or "already loaded!!!"))
		end 
		checker.startup()
	end 
	
	if not SKIP_CALENDAR then 
		-- HW: Make notification if cache save is added or updated
		Listener:Add("ACTION_PROFILESESSION_EVENTS_VERIFY", "CALENDAR_UPDATE_EVENT_LIST", function()
			if private.cacheMakeVerify and AreNamesReady() then 
				private.cacheMakeVerify = nil
					
				max_date = max_date or GetMaxCreateDate()
				SetAbsMonth(max_date.month, max_date.year)
				
				local isFound = false
				local description = strjoin("-", private.bTag, private.hashEvent)
				for i = 1, GetNumDayEvents(0, max_date.monthDay) do 
					local event = GetDayEvent(0, max_date.monthDay, i)
					if event then 
						if event.calendarType == "PLAYER" and event.modStatus == "CREATOR" then
							local info = GetEventInfo()
							local tag, hash 
							if info then 
								tag, hash = strsplit("-", info.description)
							end 

							if event.title == EMPTY_CHAR and (not info or info.description == description) then 
								isFound = true 
								break
							end 
						end 
					end 
				end 
				
				if isFound then 
					if USE_DEBUG then 
						Print(format("[Debug] Cache was %s", private.cacheMakeVerify == "update" and "updated" or "added"))
					end 
					Print(GetLocalization().PROFILESESSION.BNETSAVED)
				else 
					if USE_DEBUG then 
						Print(format("[Debug] Cache has been failed for %s!!!", private.cacheMakeVerify == "update" and "update" or "add"))
					end
				end 
			end 
		end)
		
		-- HW: Make notification if cache save is failed
		local function VerifyErrors()
			if private.cacheMakeVerify then 
				private.cacheMakeVerify = nil
				
				if USE_DEBUG then 
					Print(format("[Debug] Cache has been failed for %s!!!", private.cacheMakeVerify == "update" and "update" or "add"))
				end
			end 	
		end 
		Listener:Add("ACTION_PROFILESESSION_EVENTS_VERIFY", "CALENDAR_UPDATE_ERROR", VerifyErrors)
		Listener:Add("ACTION_PROFILESESSION_EVENTS_VERIFY", "CALENDAR_UPDATE_ERROR_WITH_COUNT", VerifyErrors) --> happens when few events throtling
		
		-- Set cache repair
		local isBusy, cacheStatus
		Listener:Add("ACTION_PROFILESESSION_EVENTS", "CALENDAR_ACTION_PENDING", function(isPending)
			if not isPending and cacheStatus and not isBusy then 
				isBusy = true 
				local description = strjoin("-", private.bTag, private.hashEvent)
				
				max_date = max_date or GetMaxCreateDate()
				SetAbsMonth(max_date.month, max_date.year)
				
				local isChanged = true; local eventID = nil
				for i = 1, GetNumDayEvents(0, max_date.monthDay) do 
					local event = GetDayEvent(0, max_date.monthDay, i)
					if event then 
						if cacheStatus == "remove" then 
							if event.title == EMPTY_CHAR then 
								isChanged = false
								break
							end 
						elseif event.calendarType == "PLAYER" and event.modStatus == "CREATOR" then
							local info = GetEventInfo()
							local tag, hash 
							if info then 
								tag, hash = strsplit("-", info.description)
							end 
							
							if event.title == EMPTY_CHAR or (tag and tag:find(private.bTag)) or (hash and hash:find(private.hashEvent)) then 
								eventID = event.eventID
							end 
							
							if event.title == EMPTY_CHAR and (not info or info.description == description) then 
								isChanged = false 
								break
							end 
						end 
					end 
				end 
				
				if isChanged then 
					if USE_DEBUG then 
						Print(format("[Debug] Cache was %s!!!", makeRepair == "remove" and "removed" or "edited"))
					end 

					if eventID then 
						local eventIndexInfo = GetEventIndexInfo(eventID)
						private.eventIndex = eventIndexInfo and eventIndexInfo.eventIndex 
					end 
					private.pendingEvent = true 
					CloseEvent()
					checker:SetScript("OnUpdate", OnAvailable) 
				else 
					if USE_DEBUG then 
						Print("[Debug] Cache is not removed and not edited")
					end 
					
					cur_date = cur_date or GetCurrentCalendarTime()
					SetAbsMonth(cur_date.month, cur_date.year)
				end 
				
				isBusy = nil; cacheStatus = nil
			end 
		end)
		
		-- Set hook to handle remove cache
		hooksecurefunc(C_Calendar, "ContextMenuEventRemove", function(...)
			cacheStatus = "remove"
		end)
		
		-- Set hook to handle edit cache
		hooksecurefunc(C_Calendar, "UpdateEvent", function(isProfileSession)
			if not isProfileSession then 
				cacheStatus = "edit"
			end 
		end)
	end
	
	return true --> signal to unregister callback
end)

-- Check status of CalendarAPI, /reload causes it to be loaded, initial login not
if not SKIP_CALENDAR then 
	Listener:Add("ACTION_PROFILESESSION_EVENTS", "PLAYER_ENTERING_WORLD", function(isInitialLogin, isReloadingUi)
		private.isCalendarLoaded = not isInitialLogin
		Listener:Remove("ACTION_PROFILESESSION_EVENTS", "PLAYER_ENTERING_WORLD")
	end)

	Listener:Add("ACTION_PROFILESESSION_EVENTS_BY_ANOTHER_ADDON", "CALENDAR_UPDATE_EVENT_LIST", function()
		if not private.isCalendarLoadedByAnotherAddon then 
			private.isCalendarLoadedByAnotherAddon = true 
			if USE_DEBUG then 
				Print("[Debug] CalendarAPI initialized successfully by another addon!")
			end 
		end 
	end)
end 

-----------------------------------------------------------------
-- API 
-----------------------------------------------------------------
local ProfileSession = {}
function ProfileSession:GetDevKey(name, custom_secure_word)
	-- @usage: local dev_key = ProfileSession:GetDevKey("My Brand Routines"[, "Any string here if you don't trust cryptography your btag"])
	-- @return: blake3 hash encrypted by unique 256-bit derived key
	local key = custom_secure_word or private:GetBTag() 
	private.cache.dev_keys[name][key] = rawget(private.cache.dev_keys[name], key) or blake3(key, hex_to_bin(blake3_derive_key(key, name)))
	return private.cache.dev_keys[name][key]
end; private.GetDevKey = ProfileSession.GetDevKey

function ProfileSession:GetUserKey(dev_key)
	-- @usage: local user_key = ProfileSession:GetUserKey("hash_string")
	-- @return: blake3 hash encrypted by 'dev_key'
	if dev_key then 
		if USE_DEBUG and not rawget(private.cache.user_keys, dev_key) then 
			Print(format("[Debug] GetUserKey called with dev_key: %s", dev_key))
			Print(format("[Debug] GetUserKey lenght of dev_key: %s", #dev_key))
			Print(format("[Debug] GetUserKey hex_to_bin(dev_key): %s", hex_to_bin(dev_key)))
			Print(format("[Debug] GetUserKey lenght of hex_to_bin(dev_key): %s", #hex_to_bin(dev_key)))
		end 
		private.cache.user_keys[dev_key] = rawget(private.cache.user_keys, dev_key) or blake3(private:GetBTag(), hex_to_bin(dev_key))
		return private.cache.user_keys[dev_key]
	end 
end; private.GetUserKey = ProfileSession.GetUserKey

function ProfileSession:GenerateUID()
	-- Can be used as custom_secure_word for ProfileSession:GetDevKey(name, custom_secure_word)
	-- @return: string unique 32 bit ints token
	return TMW.generateGUID(TMW.CONST.GUID_SIZE):upper()
end; private.GenerateUID = ProfileSession.GenerateUID

function ProfileSession:Setup(dev_key, dev_config, useTrialReset)	
	--[[ @usage:
	Arguments:
		dev_key
			@string - hexadecimal representation of blake3 hash
		dev_config
			@table:
			{
				-- required
				users = {
					-- 1th way with 'user_key' authorization:
					["user_key1"] = {
						expiration = "2022-12-31-23-59-59", 	-- @string expiration date in format 'YYYY-MM-DD-HH-MM-SS' (UTC) 
						profiles = {
							["profileName1"] = true, 			-- @boolean true - signing "profileName1" for session 
							["profileName2"] = true,
						},
					},
					["*"] = {
						expiration = "trial-07", 				-- @string expiration date in format 'trial-DD'	
						profiles = {
							["profileName1"] = true,
							["profileName2"] = true,
						},
					},
					-- 2th way without 'user_key' authorization e.g. for any user:
					["*"] = {
						expiration = "2022-12-31-23-59-59",
						profiles = {
							["profileName1"] = true,
							["profileName2"] = true,
						},
					},
				},
	 			-- optional, if omitted it will use default locales, see Action.lua > Localization table.
				locales = { 
					EXPIREDMESSAGE = {
						-- required 
						["enUS"] = "Your subscription for %s profile is expired!\nPlease contact profile developer!", -- %s will be formatted by profile name; %s is required in the string
						-- optional 
						["ruRU"] = "Ваша подписка на %s профиль истекла!\nПожалуйста, обратитесь к разработчику профиля!",
					},
					AUTHMESSAGE = {
						-- required 
						["enUS"] = "Thank you for using premium profile\nTo authorize your key please contact profile developer!",
						-- optional 
						["ruRU"] = "Спасибо за использование премиум профиля\nДля авторизации вашего ключа, пожалуйста, обратитесь к разработчику профиля!",
					},
					REMAINING = {
						-- required 
						["enUS"] = "[%s] remains %d secs", -- %s will be formatted by profile name, %d will be formatted by remaining session time 
														   -- e.g. output example "[profileName] remains 200 secs", %s and %d are required in the string
						-- optional 
						["ruRU"] = "[%s] осталось %d сек.",
					},
					DISABLED = {
						-- required 
						["enUS"] = "[%s] |cffff0000expired session!|r", -- %s will be formatted by profile name; %s is required in the string; |cffff0000 "is read color here" |r
						-- optional 
						["ruRU"] = "[%s] |cffff0000истекла сессия!|r",
					},
					-- ... and so on, you can replace all localization keys, for more details see Action.lua -> Localization.enUS.PROFILESESSION
				},
			}
			
			notes:
			sessions["*"] 				- ["*"] is special key, means for any not presented 'user_key'
			sessions[key] = 'trial-DD' 	- will make one-time session, adds 'DD' (days) to current date and time to create expiration date (UTC)
										- after finished trial time the user can't use profile for this 'dev_key', so next your lua file must contain his key or use ["*"] for any user	
		
		useTrialReset
			@boolean - true, resets all activated trials on all specified profiles. 
			USE THIS ONLY ON YOUR LOCAL REPOSITORY!!! DO NOT SHARE PROFILE WITH THIS OPTION!!!
	]]

	assert(type(dev_key) == "string" and not dev_key:find("%X"), format("dev_key '%s' must be hash string!", toStr(dev_key)))
	assert(#dev_key <= 64, format("dev_key '%s' must have up to 64 bytes length", toStr(dev_key)))
	--assert(rawget(private.data, dev_key) == nil, format("dev_key '%s' has been already signed!", toStr(dev_key)))) -- commented because devs can use multiple times setup for same key in the local snippets
	assert(type(dev_config) == "table", format("dev_key: '%s'\ndev_config must be table! This type is '%s'.", toStr(dev_key), type(dev_config)))
	assert(type(dev_config.users) == "table", format("dev_key: '%s'\ndev_config.users must be table! This type is '%s'.", toStr(dev_key), type(dev_config.users)))
	assert(type(dev_config.locales) == "table" or type(dev_config.locales) == "nil", format("dev_key: '%s'\ndev_config.locales must be table or empty! This type is '%s'.", toStr(dev_key), type(dev_config.locales)))
	assert(not useTrialReset or rawget(private.data, dev_key) == nil, format("dev_key: '%s'\nuseTrialReset can not be used on already signed session!", toStr(dev_key)))
	
	local config = private.data[dev_key]
	local config_users = config.users 
	local config_locales = config.locales
	
	-- required
	local TMW_db_profiles = TMW.db.profiles
	for user_key, user_config in pairs(dev_config.users) do 
		assert(type(user_key) == "string", format("dev_key: '%s'\ndev_config.users['%s'] must be string! This type is '%s'.", toStr(dev_key), toStr(user_key), type(user_key)))
		assert(#user_key <= 64, format("dev_key '%s'\ndev_config.users['%s'] must have up to 64 bytes length", toStr(dev_key), toStr(user_key)))
		assert(type(user_config) == "table", format("dev_key: '%s'\ndev_config.users['%s'] must be table! This type is '%s'.", toStr(dev_key), toStr(user_key), type(user_config)))
		assert(type(user_config.expiration) == "string" and (user_config.expiration:find("trial%-%d%d") or user_config.expiration:find("%d%d%d%d%-%d%d%-%d%d%-%d%d%-%d%d%-%d%d")), format("dev_key: '%s'\ndev_config.users['%s'].expiration = '%s' is incorrect format or type!", toStr(dev_key), toStr(user_key), toStr(user_config.expiration or "nil")))
		assert(type(user_config.profiles) == "table", format("dev_key: '%s'\ndev_config.users['%s'].profiles must be table! This type is '%s'!", toStr(dev_key), toStr(user_key), type(user_config.profiles)))
		
		local raw_expiration = rawget(config_users, user_key)
		assert(raw_expiration == nil or raw_expiration ~= user_config.expiration, format("dev_key: '%s'\ndev_config.users['%s'].expiration = '%s' already written expiration doesn't match new expiration '%s'.", toStr(dev_key), toStr(user_key), toStr(raw_expiration), toStr(user_config.expiration)))
		if rawget(config_users[user_key], "expiration") == nil then
			config_users[user_key].expiration = user_config.expiration
		end 
		
		for profileName, profileStatus in pairs(user_config.profiles) do 
			local profile = TMW_db_profiles[profileName]
			if profile then 
				assert(type(profileName) == "string" and profile, format("dev_key: '%s'\ndev_config.users['%s'].profiles['%s'] must be valid profile name!", toStr(dev_key), toStr(user_key), toStr(profileName)))
				assert(type(profileStatus) == "boolean", format("dev_key: '%s'\ndev_config.users['%s'].profiles['%s'] = '%s' is incorrect format or type!", toStr(dev_key), toStr(user_key), toStr(profileName), toStr(profileStatus or "nil")))
				
				local raw_profileStatus = rawget(config_users[user_key].profiles, profileName)
				if raw_profileStatus == nil then 
					config_users[user_key].profiles[profileName] = profileStatus
					
					assert(private.affected_profiles[profileName] == nil or private.affected_profiles[profileName] == dev_key, format("dev_key: '%s'\ndev_config.users['%s'].profiles['%s'] this profile has been signed by another '%s' dev_key!", toStr(dev_key), toStr(user_key), toStr(profileName), toStr(private.affected_profiles[profileName]))) 
					private.affected_profiles[profileName] = dev_key
					profile.signature = profileName
				end 
				
				if useTrialReset and profile.trial and private.affected_profiles[profileName] == dev_key then 
					profile.trial = nil
					Print(format("Trial was successfully reseted on %s (%s)!", profileName, toStr(dev_key)))
				end 
			end 
		end 
	end 
	
	-- optional
	if dev_config.locales then
		for label, localization in pairs(dev_config.locales) do 
			assert(type(localization) == "table" and localization.enUS, format("dev_key: '%s'\ndev_config.locales['%s'] has incorrect format or type!", toStr(dev_key), toStr(label)))
			
			for lang, message in pairs(localization) do 
				assert(type(message) == "string", format("dev_key: '%s'\ndev_config.locales['%s']['%s'] = '%s' has incorrect message format or type!", toStr(dev_key), toStr(label), toStr(lang), toStr(message)))
				if label == "REMAINING" then 
					assert(message:find("%%s") and message:find("%%d"), format("dev_key: '%s'\ndev_config.locales['%s']['%s'] = '%s' has missed %s or %d in the string!", toStr(dev_key), toStr(label), toStr(lang), toStr(message)))
				end 
				if label == "EXPIREDMESSAGE" or label == "DISABLED" then 
					assert(message:find("%%s"), format("dev_key: '%s'\ndev_config.locales['%s']['%s'] = '%s' has missed %s in the string!", toStr(dev_key), toStr(label), toStr(lang), toStr(message)))
				end 
				
				config_locales[label][lang] = message 
			end 
		end 
	end 
	
	if useTrialReset then 
		message("Please remove 3th true argument in ProfileSession:Setup(dev_key, dev_config, true)")
	end 
end; private.Setup = ProfileSession.Setup

function ProfileSession:Disable()
	private:CancelSession()
	private:ShutDownSession()
end; private.Disable = ProfileSession.Disable

function ProfileSession:GetSession()
	-- @return: 
	-- [1] @string remaining time in "DD:HH:MM:SS" string format 
	-- [2] @number remaining time in seconds
	-- [3] @string or @nil status: "TRIAL", "FULL", nil. nil - means not authorized
	-- [4] @string or @nil native profile name. nil - means this profile is not using session
	-- [5] @table or @nil. table that have locales which must overwrite defaults
	local remain = math_max((private.expiration or 0) - private.Server:GetTimeInSeconds(), 0)
	return private.Server:FormatSeconds(remain), remain, private.status, private.profile, private.locales
end; private.GetSession = ProfileSession.GetSession

A.ProfileSession = setmetatable({ UI = private.UI }, { --> Allows modify UI
	__index = ProfileSession,
	__newindex = function(t, key, value)
		error("Attempt to modify read-only table", 2)
	end,
	__metatable = true,
})


-----------------------------------------------------------------
-- API: USAGE EXAMPLES
-----------------------------------------------------------------
--[[
--- [ Manual ] ---
-- 1th step: Get 'dev_key' as the string representation.
local dev_key = "cdb0db7b6f82440a270838ce2951853facbc017a9eb1c8b6b7c4f8ebc42d8e23"  --> retrived from UI (right click on small "document" texture near profile dropdown) 
																					--> or retrive it from game chat via /dump Action.ProfileSession:GetDevKey("My Brand Routines") --> this is through using your b.tag as master password.
																					--> 							  	 /dump Action.ProfileSession:GetDevKey("My Brand Routines", "Secure Password Word") --> this is through using your custom master password. 

-- 2th step: Write somewhere code to setup session, can be written in global snippets if you have them or just store it inside profile snippets.
-- Make sure that you performed initial setup with your dev_key as user_key, it needs to retrive your user_key, after that you will replace dev_key by user_key. It must to be done one time per each dev_key.
local ProfileSession = _G.Action.ProfileSession
ProfileSession:Setup(dev_key or "cdb0db7b6f82440a270838ce2951853facbc017a9eb1c8b6b7c4f8ebc42d8e23", {
	-- required
	users = {
		["cdb0db7b6f82440a270838ce2951853facbc017a9eb1c8b6b7c4f8ebc42d8e23"] = { 		--> put your dev_key here, just to get your user_key otherwise it will not allow you to enter in native UI 
			expiration = "2100-01-01-23-59-59",
			profiles = {
				["profileName1-Warrior"] = true,
			},
		},
		-- You will replace this key as soon as you will get own user_key.
		-- See description @usage in the function ProfileSession:Setup(dev_key, dev_config) in this file 
	},
})

-- 3th step (optional): Obfuscate your written code (2th step) by using: MoonSec, Luraph, AzureBrew, Prometheus, SimplyXOR, or any such tool.
-- 4th step: Export and share your profile through Profile Install to your users.
-- 5th step (optional): Ask your users to send you a key, they will get a message with their key in the next time using your profile.

-- Important to note:
-- User key is attached to his b.tag through blake3 hash, so if user changes b.tag (payment change tag, merging b.accounts and etc) then his old key will no longer work and you have to replace it.
-- If you will not encode or obfuscate your 2th step, that part will be unprotected and everyone will able to modify it. So it's highly recommended to hide it somehow on your side before you will share profile.
-- Every hash is one-way cryptographically protected by a 256-bit key information mathematically tied to a user's b.tag, reversing hash will not give any viable results to attacker.
-- Trial runs one-time per each profile, once it's launched it can not be reversed, unless creating clearly new profile from scratch or passing 3th argument as boolean true to reset it (see Example #reset).

-- Tips:
-- I recommend to make google sheets table that will hold associated Discord/email user with hash key instead of writting commentary near the key. 
-- You can hold user key under Discord's profile notes for each user.
-- Recommended internal layout of session lock to avoid bypassing it through editing this file, example:
local lastKnownSecs 
A[3] = function(icon)
  local remain_profile, remain_profile_secs, userStatus, profileName, locales = A.ProfileSession:GetSession()
  if A.CurrentProfile ~= profileName or type(remain_profile_secs) ~= "number" or remain_profile_secs <= 0 or (lastKnownSecs and lastKnownSecs == remain_profile_secs) then
    if not lastKnownSecs then 
      lastKnownSecs = remain_profile_secs
    end 
    return
  end 
  -- your profile code
end
-- Modify example above with own locales as an additional check or add any other your locks as extra




--- [ Example #1 ] ---
-- Runs same session for all users and all specified profiles, without trial option. 
-- If you have lifetime users you can personally add their user_key, specified users have higher priority.

local lifetime 	 	= "2100-01-01-23-59-59" 	--> expires on 1 Jan 2100 23:59:59 (UTC)
local full_profiles = {
	["profileName1-Warrior"] = true,
	["profileName2-Paladin"] = true,
	["profileName3-Rogue"] 	 = true,
}
ProfileSession:Setup("cdb0db7b6f82440a270838ce2951853facbc017a9eb1c8b6b7c4f8ebc42d8e23", {
	-- required
	users = {
		["user_key1"] = { 						--> specified lifetime user
			expiration = lifetime,
			profiles = full_profiles,
		},
		["*"] = { 								--> all other users
			expiration = "2022-12-31-23-59-59", --> expires on 31 Dec 2022 23:59:59 (UTC)
			profiles = full_profiles,
		},
	},
	-- optional, if omitted it will use default locales, see Action.lua > Localization table.
	locales = { 
		EXPIREDMESSAGE = {
			-- required 
			["enUS"] = "Your subscription for %s profile is expired!\nPlease contact profile developer!", -- %s will be formatted by profile name; %s is required in the string
			-- optional 
			["ruRU"] = "Ваша подписка на %s профиль истекла!\nПожалуйста, обратитесь к разработчику профиля!",
		},
		AUTHMESSAGE = {
			-- required 
			["enUS"] = "Thank you for using premium profile\nTo authorize your key please contact profile developer!",
			-- optional 
			["ruRU"] = "Спасибо за использование премиум профиля\nДля авторизации вашего ключа, пожалуйста, обратитесь к разработчику профиля!",
		},
		REMAINING = {
			-- required 
			["enUS"] = "[%s] remains %d secs", -- %s will be formatted by profile name, %d will be formatted by remaining session time 
											   -- e.g. output example "[profileName] remains 200 secs", %s and %d are required in the string
			-- optional 
			["ruRU"] = "[%s] осталось %d сек.",
		},
		DISABLED = {
			-- required 
			["enUS"] = "[%s] |cffff0000expired session!|r", -- %s will be formatted by profile name; %s is required in the string; |cffff0000 "is read color here" |r
			-- optional 
			["ruRU"] = "[%s] |cffff0000истекла сессия!|r",
		},
	},
})




--- [ Example #2 ] ---
-- Runs same session for specified users with full_profiles, and trial for not authorized users with trial_profiles

local normaltime = "2022-12-31-23-59-59" --> expires on 31 Dec 2022 23:59:59 (UTC)
local lifetime 	 = "2100-01-01-23-59-59" --> expires on  1 Jan 2100 23:59:59 (UTC)
local trialtime  = "trial-07"			 --> 7-days trial time (UTC), start up will be launched as soon as user will load profile 
local full_profiles = {
	["profileName1-Warrior"] = true,
	["profileName2-Paladin"] = true,
	["profileName3-Rogue"] 	 = true,
}
local trial_profiles = {
	["profileName1-Warrior"] = true,
	["profileName2-Priest"]  = true,
}
ProfileSession:Setup("cdb0db7b6f82440a270838ce2951853facbc017a9eb1c8b6b7c4f8ebc42d8e23", {
	-- required
	users = {
		["user_key1"] = { 						--> specified lifetime user
			expiration = lifetime, 				--> expires on 1 Jan 2100 23:59:59 (UTC)
			profiles = full_profiles,			--> full profiles 
		},
		["user_key2"] = {						--> specified normaltime user
			expiration = normaltime,			--> expires on 31 Dec 2022 23:59:59 (UTC)
			profiles = full_profiles,			--> full profiles 
		},
		["*"] = {								--> all other users e.g. trials in this example
			expiration = trialtime,				--> 7-days trial time (UTC), start up will be launched as soon as user will load profile
			profiles = trial_profiles,			--> trial profiles 
		},
	},
})




--- [ Example #3 ] ---
-- Runs individual session for each user with full_profiles, and lifetime session for not authorized users with free_profiles

local lifetime 	 = "2100-01-01-23-59-59" --> expires on  1 Jan 2100 23:59:59 (UTC)
local trialtime  = "trial-07"			 --> 7-days trial time (UTC), start up will be launched as soon as user will load profile 
local full_profiles = {
	["profileName1-Warrior"] = true,
	["profileName2-Paladin"] = true,
	["profileName3-Rogue"] 	 = true,
}
local free_profiles = {
	["profileName1-Warrior-Free"] = true,
	["profileName2-Paladin-Free"] = true,
	["profileName3-Rogue-Free"]   = true,
}
ProfileSession:Setup("cdb0db7b6f82440a270838ce2951853facbc017a9eb1c8b6b7c4f8ebc42d8e23", {
	-- required
	users = {
		["user_key1"] = { 						--> specified lifetime user
			expiration = lifetime, 				--> expires on 1 Jan 2100 23:59:59 (UTC)
			profiles = full_profiles,			--> full profiles 
		},
		["user_key2"] = {						--> specified individual time user
			expiration = "2022-12-31-23-59-59", --> expires on 31 Dec 2022 23:59:59 (UTC)
			profiles = full_profiles,			--> full profiles 
		},
		["user_key3"] = {						--> specified individual time user
			expiration = "2022-05-01-10-59-59", --> expires on 1 May 2022 10:59:59 (UTC)
			profiles = full_profiles,			--> full profiles 
		},
		["*"] = {								--> all other users e.g. free lifetime profiles in this example
			expiration = lifetime,				--> expires on  1 Jan 2100 23:59:59 (UTC)
			profiles = free_profiles,			--> free profiles 
		},
	},
})




--- [ Example #4 ] ---
-- Runs individual session for each user with full_profiles and unique, and trial session for not authorized users with full_profiles

local normaltime = "2022-12-31-23-59-59" --> expires on 31 Dec 2022 23:59:59 (UTC)
local lifetime 	 = "2100-01-01-23-59-59" --> expires on  1 Jan 2100 23:59:59 (UTC)
local trialtime  = "trial-07"			 --> 7-days trial time (UTC), start up will be launched as soon as user will load profile 
local full_profiles = {
	["profileName1-Warrior"] = true,
	["profileName2-Paladin"] = true,
	["profileName3-Rogue"] 	 = true,
}
ProfileSession:Setup("cdb0db7b6f82440a270838ce2951853facbc017a9eb1c8b6b7c4f8ebc42d8e23", {
	-- required
	users = {
		["user_key1"] = { 						--> specified lifetime user
			expiration = lifetime, 				--> expires on 1 Jan 2100 23:59:59 (UTC)
			profiles = full_profiles,			--> full profiles 
		},
		["user_key2"] = {						--> specified individual time user
			expiration = normaltime, 			--> expires on 31 Dec 2022 23:59:59 (UTC)
			profiles = full_profiles,			--> full profiles 
		},
		["user_key3"] = {						--> specified individual time user
			expiration = normaltime, 			--> expires on 31 Dec 2022 23:59:59 (UTC)
			profiles = {						--> unique profiles
				["profileName1-Warrior"] = true,
			},			 
		},
		["*"] = {								--> all other users e.g. free lifetime profiles in this example
			expiration = trialtime,				--> 7-days trial time (UTC), start up will be launched as soon as user will load profile 
			profiles = full_profiles,			--> free profiles 
		},
	},
})




--- [ Example #reset ] ---
-- Runs reseting process on specified profiles, let's take example #4, difference in what you passing 3th argument as true in to function. See last line.

local normaltime = "2022-12-31-23-59-59" --> expires on 31 Dec 2022 23:59:59 (UTC)
local lifetime 	 = "2100-01-01-23-59-59" --> expires on  1 Jan 2100 23:59:59 (UTC)
local trialtime  = "trial-07"			 --> 7-days trial time (UTC), start up will be launched as soon as user will load profile 
local full_profiles = {
	["profileName1-Warrior"] = true,
	["profileName2-Paladin"] = true,
	["profileName3-Rogue"] 	 = true,
}
ProfileSession:Setup("cdb0db7b6f82440a270838ce2951853facbc017a9eb1c8b6b7c4f8ebc42d8e23", {
	-- required
	users = {
		["user_key1"] = { 						--> specified lifetime user
			expiration = lifetime, 				--> expires on 1 Jan 2100 23:59:59 (UTC)
			profiles = full_profiles,			--> full profiles 
		},
		["user_key2"] = {						--> specified individual time user
			expiration = normaltime, 			--> expires on 31 Dec 2022 23:59:59 (UTC)
			profiles = full_profiles,			--> full profiles 
		},
		["user_key3"] = {						--> specified individual time user
			expiration = normaltime, 			--> expires on 31 Dec 2022 23:59:59 (UTC)
			profiles = {						--> unique profiles
				["profileName1-Warrior"] = true,
			},			 
		},
		["*"] = {								--> all other users e.g. free lifetime profiles in this example
			expiration = trialtime,				--> 7-days trial time (UTC), start up will be launched as soon as user will load profile 
			profiles = full_profiles,			--> free profiles 
		},
	},
}, true) 										--> passing true here causes trial reset!
]]