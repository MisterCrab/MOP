local _G, getmetatable, type			= _G, getmetatable, type
local hooksecurefunc					= _G.hooksecurefunc	  
local CreateFrame						= _G.CreateFrame	  
local EnumerateFrames					= _G.EnumerateFrames
local C_AddOns 							= _G.C_AddOns 
local IsAddOnLoaded 					= C_AddOns and C_AddOns.IsAddOnLoaded or _G.IsAddOnLoaded

local function IsLoadedPixelSnap()
	if IsAddOnLoaded("ElvUI") or IsAddOnLoaded("Cell") then
		return true
	end
end

local handled = { ["Frame"] = true }
local object = CreateFrame("Frame")
object.texture = object:CreateTexture(nil, "BACKGROUND")
local OldTexelSnappingBias = object.texture:GetTexelSnappingBias()

local function WatchPixelSnap(frame, snap)
	if (frame and not frame:IsForbidden()) and not frame.PixelSnapDisabled and snap then
		frame.PixelSnapTurnedOff = nil
	end
end

local function EnablePixelSnap(frame)
	if (frame and not frame:IsForbidden()) and frame.PixelSnapDisabled and not frame.PixelSnapTurnedOff then
		if frame.SetSnapToPixelGrid then
			frame:SetTexelSnappingBias(OldTexelSnappingBias)
		elseif frame.GetStatusBarTexture then
			local texture = frame:GetStatusBarTexture()
			if type(texture) == 'table' and texture.SetSnapToPixelGrid then
				texture:SetTexelSnappingBias(OldTexelSnappingBias)
			end
		end

		frame.PixelSnapTurnedOff = true 
	end
end

local function removeapi(object)
	local mt = getmetatable(object).__index
	if mt.DisabledPixelSnap then 
		if mt.SetSnapToPixelGrid then hooksecurefunc(mt, 'SetSnapToPixelGrid', WatchPixelSnap) end
		if mt.SetStatusBarTexture then hooksecurefunc(mt, 'SetStatusBarTexture', EnablePixelSnap) end
		if mt.SetColorTexture then hooksecurefunc(mt, 'SetColorTexture', EnablePixelSnap) end
		if mt.SetVertexColor then hooksecurefunc(mt, 'SetVertexColor', EnablePixelSnap) end
		if mt.CreateTexture then hooksecurefunc(mt, 'CreateTexture', EnablePixelSnap) end
		if mt.SetTexCoord then hooksecurefunc(mt, 'SetTexCoord', EnablePixelSnap) end
		if mt.SetTexture then hooksecurefunc(mt, 'SetTexture', EnablePixelSnap) end
	end
end

object:RegisterEvent("PLAYER_LOGIN")
object:SetScript("OnEvent", function(self, event)
	if IsLoadedPixelSnap() then
		removeapi(object)
		removeapi(object.texture)
		removeapi(object:CreateFontString())
		removeapi(object:CreateMaskTexture())
		removeapi(_G.GameFontNormal)

		object = EnumerateFrames()
		while object do
			local objType = object:GetObjectType()
			if not object:IsForbidden() and not handled[objType] then
				removeapi(object)
				handled[objType] = true
			end
			
			object = EnumerateFrames(object)
		end
	end
	
	self:UnregisterEvent(event)
	self:SetScript("OnEvent", nil)
end)