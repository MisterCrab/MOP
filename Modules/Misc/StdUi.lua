-------------------------------------------------------------------------------------
-- StdUi BackdropTemplate fix 
-------------------------------------------------------------------------------------
local _G, pairs					= _G, pairs
local A 						= _G.Action
local BackdropTemplateMixin 	= _G.BackdropTemplateMixin
local LibStub					= _G.LibStub

-- Do nothing if its not 9.x+ API or StdUi has been updated
if BackdropTemplateMixin == nil or (LibStub.minors["StdUi"] and LibStub.minors["StdUi"] >= 5) then 
	return 
end 

-------------------------------------------------------------------------------------
-- Local fix inheritance
-------------------------------------------------------------------------------------
local StdUi						= A.StdUi

function StdUi:AddBackdropTemplateMixin(frame)
	if frame.SetBackdrop == nil then 
		for method, func in pairs(BackdropTemplateMixin) do 
			if frame[method] == nil then 
				frame[method] = func
			end 
		end 
	end 
end

StdUi.originalApplyBackdrop = StdUi.ApplyBackdrop
function StdUi:ApplyBackdrop(...)
	self:AddBackdropTemplateMixin(...)
	self:originalApplyBackdrop(...)
end 

StdUi.originalClearBackdrop = StdUi.ClearBackdrop
function StdUi:ClearBackdrop(...)
	self:AddBackdropTemplateMixin(...)
	self:originalClearBackdrop(...)
end

-- Has specific obtain function
StdUi.originalSetHighlightBorder = StdUi.SetHighlightBorder
function StdUi.SetHighlightBorder(self)
	local frame = self
	if self.target then 
		frame = self.target
	end 
	self.stdUi:AddBackdropTemplateMixin(frame)
	self.stdUi.originalSetHighlightBorder(self)
end

StdUi.originalMarkAsValid = StdUi.MarkAsValid
function StdUi:MarkAsValid(...)
	self:AddBackdropTemplateMixin(...)
	self:originalMarkAsValid(...)
end 

-------------------------------------------------------------------------------------
-- Global fix inheritance
-------------------------------------------------------------------------------------
-- Need for ColorPicker since there are a bug in lib with buttons, they inherits global instance instead of local
-- The good thing is what it will also spreads on other addons that use same lib on global instance 
local _StdUi					= LibStub("StdUi")
_StdUi.AddBackdropTemplateMixin = StdUi.AddBackdropTemplateMixin

_StdUi.originalApplyBackdrop = _StdUi.ApplyBackdrop
function _StdUi:ApplyBackdrop(...)
	self:AddBackdropTemplateMixin(...)
	self:originalApplyBackdrop(...)
end 

_StdUi.originalClearBackdrop = _StdUi.ClearBackdrop
function _StdUi:ClearBackdrop(...)
	self:AddBackdropTemplateMixin(...)
	self:originalClearBackdrop(...)
end

-- Has specific obtain function
_StdUi.originalSetHighlightBorder = _StdUi.SetHighlightBorder
function _StdUi.SetHighlightBorder(self)
	local frame = self
	if self.target then 
		frame = self.target
	end 
	self.stdUi:AddBackdropTemplateMixin(frame)
	self.stdUi.originalSetHighlightBorder(self)
end

_StdUi.originalMarkAsValid = _StdUi.MarkAsValid
function _StdUi:MarkAsValid(...)
	self:AddBackdropTemplateMixin(...)
	self:originalMarkAsValid(...)
end 