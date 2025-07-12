-------------------------------------------------------------------------------------
-- Toaster as built-in embeds with own stand alone category and db
-------------------------------------------------------------------------------------
local ADDON_NAME, private														= ...
local _G, unpack, type, math, pairs, error, next, setmetatable, select, rawset	= _G, unpack, type, math, pairs, error, next, setmetatable, select, rawset
local xpcall																	= xpcall
local tremove																	= table.remove
local format 																	= string.format
local math_floor																= math.floor
local math_huge																	= math.huge
local math_max																	= math.max
local wipe																		= _G.wipe
local hooksecurefunc															= _G.hooksecurefunc
local CopyTable																	= _G.CopyTable
local UIParent																	= _G.UIParent
local Toaster																	= _G.Toaster -- The Action _G.Toaster will be initilized first, then _G.Toaster will be replaced by original if Toaster addon will be loaded, but we will keep our local
local LibStub																	= _G.LibStub
local AceDB 																	= LibStub("AceDB-3.0", true)
local AceConfigRegistry 														= LibStub("AceConfigRegistry-3.0", true)
local AceConfigDialog 															= LibStub("AceConfigDialog-3.0", true)	
local AceLocale																	= LibStub("AceLocale-3.0", true)
local LibWindow 																= LibStub("LibWindow-1.1", true)
local LDBIcon 																	= LibStub("LibDBIcon-1.0", true)
local LibToast 																	= LibStub("LibToast-1.0", true)
local templates																	= LibToast and LibToast.templates
local unique_templates															= LibToast and LibToast.unique_templates
local active_toasts																= LibToast and LibToast.active_toasts
local DEFAULT_FADE_HOLD_TIME													= 5
local DEFAULT_WIDTH																= 250
local DEFAULT_HEIGHT															= 50

local TMW 																		= _G.TMW

local A 																		= _G.Action
local toStr 																	= A.toStr
local toNum 																	= A.toNum 
local CONST 																	= A.Const
local Listener																	= A.Listener
local FormatGameLocale															= A.FormatGameLocale
local FormatedGameLocale														= A.FormatedGameLocale
local Unit 																		= A.Unit 

local function round(num, idp)
    local mult = 10 ^ (idp or 0)
    return math_floor(num * mult + 0.5) / mult
end

local expirationToasts = setmetatable({}, { 
	__index = function(t, v)
		t[v] = setmetatable({ expirationTemplate = 0 }, {
			__index = function(t1, v1)
				t1[v1] = 0
				return t1[v1]
			end,
		})
		return t[v]
	end, 
})

if Toaster and AceDB and AceConfigRegistry and AceConfigDialog and AceLocale and LibWindow and LDBIcon and LibToast then 
	Toaster.expirationToasts = expirationToasts
	local TOASTER_NAME = "The Action Toaster"
	
	-- Locales	
	local function ModifyLocales(addon_name)	
		local L 
 
		L = AceLocale:GetLocale(addon_name)
		if L then 
			if FormatedGameLocale == "enUS" then 
				L["This is a %s preview toast."] = "This is a %s preview notification."
				L["OnlyInCombat"] = "Only in combat"
				L["OnlyInCombat Desc"] = "The Action notifications will be shown only in combat"
				L["RelativeTo"] = "Relative to"
				L["RelativeTo Desc"] = "The Action notifications will be anchored to the specified frame"
				L["W Offset"] = "Width"
				L["W Offset Desc"] = "The Action a width of the notifications"
				L["H Offset"] = "Height"
				L["H Offset Desc"] = "The Action a height of the notifications"
				L["Scale"] = "Scale"	
				L["Scale Desc"] = "The Action a scale of the notifications"		
			end 
			
			if FormatedGameLocale == "ruRU" then 
				L["This is a %s preview toast."] = "Это %s предпросмотр уведомления."
				L["OnlyInCombat"] = "Только в бою"
				L["OnlyInCombat Desc"] = "The Action уведомления будут показываться только в бою"
				L["RelativeTo"] = "Относительно"
				L["RelativeTo Desc"] = "The Action уведомления будут прикреплены к заданному фрейму"
				L["W Offset"] = "Ширина"
				L["W Offset Desc"] = "The Action ширина уведомлений"
				L["H Offset"] = "Высота"
				L["H Offset Desc"] = "The Action высота уведомлений"
				L["Scale"] = "Масштаб"					
				L["Scale Desc"] = "The Action масштаб уведомлений"		
			end 
			
			if FormatedGameLocale == "deDE" then 
				L["This is a %s preview toast."] = "Dies ist eine %s Vorschau-Benachrichtigung."
				L["OnlyInCombat"] = "Nur im Kampf"
				L["OnlyInCombat Desc"] = "The Action benachrichtigungen werden nur im Kampf angezeigt"
				L["RelativeTo"] = "Relativ zu"
				L["RelativeTo Desc"] = "The Action benachrichtigungen werden im angegebenen Frame verankert"
				L["W Offset"] = "Breite"
				L["W Offset Desc"] = "The Action breite der Benachrichtigungen"
				L["H Offset"] = "Höhe"
				L["H Offset Desc"] = "The Action höhe der Benachrichtigungen"
				L["Scale"] = "Rahmen"	
				L["Scale Desc"] = "The Action umfang der Benachrichtigungen"	
			end 
			
			if FormatedGameLocale == "frFR" then 
				L["This is a %s preview toast."] = "Ceci est une notification de prévisualisation %s."
				L["OnlyInCombat"] = "Seulement au combat"
				L["OnlyInCombat Desc"] = "The Action les notifications ne seront affichées qu'en combat"
				L["RelativeTo"] = "Relatif à"
				L["RelativeTo Desc"] = "The Action les notifications seront ancrées au cadre spécifié"
				L["W Offset"] = "Largeur"
				L["W Offset Desc"] = "The Action largeur des notifications"
				L["H Offset"] = "La taille"
				L["H Offset Desc"] = "The Action hauteur des notifications"
				L["Scale"] = "Échelle"	
				L["Scale Desc"] = "The Action échelle des notifications"	
			end 
						
			if FormatedGameLocale == "esES" then 
				L["This is a %s preview toast."] = "Esta es una notificación de vista previa %s."
				L["OnlyInCombat"] = "Solo en combate"
				L["OnlyInCombat Desc"] = "The Action las notificaciones se mostrarán solo en combate"
				L["RelativeTo"] = "Relativo a"
				L["RelativeTo Desc"] = "The Action las notificaciones se anclarán al marco especificado"
				L["W Offset"] = "Anchura"
				L["W Offset Desc"] = "The Action ancho de las notificaciones"
				L["H Offset"] = "Height"
				L["H Offset Desc"] = "The Action altura de las notificaciones"
				L["Scale"] = "Escala"	
				L["Scale Desc"] = "The Action escala de las notificaciones"								
			end 
			
			if FormatedGameLocale == "ptPT" then 
				L["This is a %s preview toast."] = "Esta é uma notificação de visualização do %s."
				L["OnlyInCombat"] = "Só em combate"
				L["OnlyInCombat Desc"] = "The Action as notificações serão mostradas apenas em combate"
				L["RelativeTo"] = "Relativo a"
				L["RelativeTo Desc"] = "The Action as notificações serão ancoradas ao quadro especificado"
				L["W Offset"] = "Largura"
				L["W Offset Desc"] = "The Action largura das notificações"
				L["H Offset"] = "Altura"
				L["H Offset Desc"] = "The Action altura das notificações"
				L["Scale"] = "Escala"	
				L["Scale Desc"] = "The Action escala das notificações"		
			end 
			
			if FormatedGameLocale == "koKR" then 
				L["This is a %s preview toast."] = "%s 미리보기 알림입니다."
				L["OnlyInCombat"] = "전투에서만"
				L["OnlyInCombat Desc"] = "The Action 알림은 전투 중에 만 표시됩니다."
				L["RelativeTo"] = "상대"
				L["RelativeTo Desc"] = "The Action 알림은 지정된 프레임에 고정됩니다."
				L["W Offset"] = "폭"
				L["W Offset Desc"] = "The Action 알림 너비"
				L["H Offset"] = "Height"
				L["H Offset Desc"] = "The Action 알림 높이"
				L["Scale"] = "규모"	
				L["Scale Desc"] = "The Action 알림 규모"	
			end 
			
			if FormatedGameLocale == "zhTW" then 
				L["This is a %s preview toast."] = "这是 %s 预览通知。"
				L["OnlyInCombat"] = "仅在战斗中"
				L["OnlyInCombat Desc"] = "The Action 通知将仅在战斗中显示"
				L["RelativeTo"] = "关系到"
				L["RelativeTo Desc"] = "The Action 通知将锚定到指定框架"
				L["W Offset"] = "宽度"
				L["W Offset Desc"] = "The Action 通知宽度"
				L["H Offset"] = "高度"
				L["H Offset Desc"] = "The Action 通知高度"
				L["Scale"] = "规模"	
				L["Scale Desc"] = "The Action 通知规模"	
			end 
		end 
		
		-- itIT.lua imitation 
		L = AceLocale:NewLocale(addon_name, "itIT", false)
		if L then 
			L["This is a %s preview toast."] = "Questa è una notifica di anteprima %s."
			L["OnlyInCombat"] = "Solo in combattimento"
			L["OnlyInCombat Desc"] = "The Action le notifiche verranno mostrate solo in combattimento"
			L["RelativeTo"] = "Relativo a"
			L["RelativeTo Desc"] = "The Action le notifiche verranno ancorate al frame specificato"
			L["W Offset"] = "Larghezza"
			L["W Offset Desc"] = "The Action larghezza delle notifiche"
			L["H Offset"] = "Altezza"
			L["H Offset Desc"] = "The Action altezza delle notifiche"
			L["Scale"] = "Scala"	
			L["Scale Desc"] = "The Action scala delle notifiche"		
			-- itIT.lua imitation 
			L["Background"] = true
			L["BOTTOM"] = "Parte inferiore"
			L["BOTTOMLEFT"] = "In basso a sinistra"
			L["BOTTOMRIGHT"] = "In basso a destra"
			L["CENTER"] = "Centro"
			L["Drag to set the spawn point for toasts."] = true
			L["Emergency"] = true
			L["Floating Icon"] = true
			L["Hide Toasts"] = true
			L["High"] = true
			L["Horizontal offset from the anchor point."] = true
			L["Icon Size"] = true
			L["LEFT"] = "Left"
			L["Moderate"] = true
			L["Mute Toasts"] = true
			L["Normal"] = true
			L["Preview"] = true
			L["Reset Position"] = true
			L["RIGHT"] = "Right"
			L["Show Anchor"] = true
			L["Show Minimap Icon"] = true
			L["Spawn Point"] = true
			L["Text"] = true
			L["Title"] = true
			L["TOP"] = "Superiore"
			L["TOPLEFT"] = "In alto a sinistra"
			L["TOPRIGHT"] = "In alto a destra"
			L["Vertical offset from the anchor point."] = true
			L["Very Low"] = true
			L["X Offset"] = true
			L["Y Offset"] = true					
		end 		
	end 
			
	-- SavedVariables db object
	local function push_DATABASE_DEFAULTS(DATABASE_DEFAULTS)
		local anchor = DATABASE_DEFAULTS.global.display.anchor
		anchor.relative_to = "QuickJoinToastButton"
		anchor.w = 325 
		anchor.h = 60   
		anchor.point = "TOPLEFT"
		anchor.x = 30
		anchor.y = 25
	end 
	
	local wrongName			= ADDON_NAME .. "Settings"
	local AceDBNew_Original = AceDB.New 
	function AceDB:New(...)	
		local dbName = ...
		if dbName == wrongName then 
			local vararg = { ... }
			vararg[1] = wrongName:gsub("%s+", "") -- "ToasterSavedVariables"
			push_DATABASE_DEFAULTS(vararg[2])
			local db = AceDBNew_Original(self, unpack(vararg)) -- traversed into private.db			
			if not db.global.addons[ADDON_NAME] then
				db.global.addons[ADDON_NAME] = CopyTable(private.DATABASE_DEFAULTS.global.addons["*"])				
			end 
			db.global.addons[ADDON_NAME].known = false  
			private.AddOnObjects[ADDON_NAME] = { name = ADDON_NAME }
			
			Toaster.db = db

			return db 
		elseif dbName == "ToasterSettings" then
			local db 
			if private.db then 
				-- Replace Toaster db by The Action Toaster db if possible 
				db = private.db
			else 
				-- Unregister The Action Toaster db and use original Toaster db
				-- In the Toaster private.db never changes only used as pointer to other tables inside which will be reallocated
				push_DATABASE_DEFAULTS((select(2, ...)))
				db = AceDBNew_Original(self, ...)					
			end 
			
			if db.global.addons[ADDON_NAME] then 
				db.global.addons[ADDON_NAME].known = true 
			end 
			private.AddOnObjects[ADDON_NAME] = nil 
			
			_G.Toaster.db = db

			return db 
		else 
			return AceDBNew_Original(self, ...)
		end 
	end 
	
	-- Active toasts 	
	if active_toasts then 
		local function null()
		end 
		setmetatable(active_toasts, { 
			__newindex = function(t, index, toast)
				-- This is ToastProxy avoid, it's direct object 
				rawset(t, index, toast)
								
				local anchor = _G.Toaster.db.global.display.anchor
				
				-- Set scale 
				toast:SetScale(anchor.scale)
				
				-- Set size  
				toast:SetSize(anchor.w or DEFAULT_WIDTH, anchor.h or DEFAULT_HEIGHT)	
				
				-- Set parent, re-anchor relative to frame 
				if toast.SetPoint_Original == nil then 
					toast.tempData = {}					
					-- Fixes error "Can't measure restricted regions"
					if not toast:IsAnchoringRestricted() then
						for i = 1, toast:GetNumPoints() do 
							toast.tempData[i] = toast:GetPoint(i)
						end 
					else
						toast.tempData[1] = "TOPLEFT"
					end 
					
					toast.SetPoint_Original = toast.SetPoint
					function toast:SetPoint(...)
						-- Fixes re-anchoring errors but this is not a good way tbh
						xpcall(self.SetPoint_Original, null, self, ...) -- self:SetPoint_Original(...)						
						
						local _, needParent = ... 
						if needParent == UIParent then 
							local anchor = _G.Toaster.db.global.display.anchor
							local parent = _G[anchor.relative_to]
							if type(parent) == "table" and parent.GetObjectType and parent ~= UIParent then 							
								wipe(self.tempData) 
								-- Fixes error "Can't measure restricted regions"
								if not self:IsAnchoringRestricted() then 
									for i = 1, self:GetNumPoints() do 
										self.tempData[i] = self:GetPoint(i)
									end 	
								else 
									self.tempData[1] = "TOPLEFT"
								end 
								
								local x, y, s = anchor.x, anchor.y, anchor.scale 
								x = x/s
								y = y/s								
								
								self.tempData[2] = parent 
								self.tempData[3] = toast.tempData[1]
								self.tempData[4] = x
								self.tempData[5] = y 
								self:ClearAllPoints()					
								self:SetPoint(unpack(self.tempData))								 
							end 
						end  						 																		
					end 
					
					-- Only this is viable method to do initial setup, so.. 
					if index == 1 then 
						local parent = _G[anchor.relative_to]
						if type(parent) == "table" and parent.GetObjectType and parent ~= UIParent then 
							wipe(toast.tempData)
							-- Fixes error "Can't measure restricted regions"
							if not toast:IsAnchoringRestricted() then 
								for i = 1, toast:GetNumPoints() do 
									toast.tempData[i] = toast:GetPoint(i)
								end 
							else
								toast.tempData[1] = "TOPLEFT"
							end 
							
							local x, y, s = anchor.x, anchor.y, anchor.scale 
							x = x/s
							y = y/s								
													
							toast.tempData[2] = parent 
							toast.tempData[3] = toast.tempData[1]
							toast.tempData[4] = x
							toast.tempData[5] = y 
							toast:ClearAllPoints()				
							toast:SetPoint(unpack(toast.tempData))
						end 	
					end 
				end 				 
			end,
		})
	end 
	
	-- Anchor frame 
	local LibWindowRestorePosition_Original = LibWindow.RestorePosition
	function LibWindow.RestorePosition(...)
		local Toaster = _G.Toaster
		local anchorFrame = Toaster.anchorFrame
		if ... == anchorFrame then 
			local db = Toaster.db		
			if db then 
				local anchor = db.global.display.anchor
				
				-- Set scale 
				Toaster.storage.scale = anchor.scale or 1
				
				-- Set size 
				anchorFrame:SetSize(anchor.w or DEFAULT_WIDTH, anchor.h or DEFAULT_HEIGHT)
						
				-- Set parent, re-anchor relative to frame 
				local parent = _G[anchor.relative_to]
				if type(parent) == "table" and parent.GetObjectType then 
					anchorFrame:SetParent(parent)					
				elseif anchorFrame:GetParent() ~= UIParent then 
					anchorFrame:SetParent(UIParent)
				end 							
			end 
		end 
		LibWindowRestorePosition_Original(...)
	end 
	
	local function hookOnDragStart(frame)
		frame:HookScript("OnDragStart", function(self)
			if self:GetParent() ~= UIParent then 
				self:SetParent(UIParent)
				local db = _G.Toaster.db	
				if db then 
					db.global.display.anchor.relative_to = "UIParent"
					_G.Toaster.storage.relative_to = "UIParent"
				end 
			end 
		end)
	end 
	
	-- Interface Options Panel
	local function resetTableFromTable(t1, t2)
		if not t1 then 
			t1 = {}
		end 
		
		if type(t2) == "table" then 
			for k, v in pairs(t2) do 
				if type(v) == "table" then 
					resetTableFromTable(t1[k], v)
				else 
					t1[k] = v 
				end 
			end 
		end 
		
		if type(t1) == "table" then 
			for k, v in pairs(t1) do 
				if type(v) == "table" and type(t2[k]) == "table" then 
					resetTableFromTable(v, t2[k])
				elseif t2[k] == nil then 
					t1[k] = nil 
				end 
			end 
		end 
	end 

	local function push_DefautOptions(defaultOptions, db, addon_name)
		-- We will update locales here 
		ModifyLocales(addon_name)
		local L = AceLocale:GetLocale(addon_name)
		
		local args = defaultOptions.args		
		-- Add checkbox "Only in combat"
		args.only_in_combat = {
			order = 31,
			type = "toggle",
			name = L["OnlyInCombat"],
			desc = L["OnlyInCombat Desc"],
			get = function(info)
				return db.global.general.only_in_combat
			end,
			set = function(info, value)
				db.global.general.only_in_combat = value
			end,
		}		
		-- Add editbox "Relative to"  
		args.relative_to = {
			order = 52,
			type = "input",
			name = L["RelativeTo"],
			desc = L["RelativeTo Desc"],
			confirm = true,
			get = function()
				return toStr[db.global.display.anchor.relative_to]
			end,
			set = function(info, value)
				db.global.display.anchor.relative_to = value and toStr[value] or ""
				LibWindow.RestorePosition(_G.Toaster.anchorFrame)
			end,
			dialogControl = "EditBox",
		}
		-- Add editbox "Width"
		args.w = {
			order = 55,
			type = "input",
			name = L["W Offset"],
			desc = L["W Offset Desc"],
			get = function()
				return toStr[round(db.global.display.anchor.w)]
			end,
			set = function(info, value)
				local value = toNum[value] or 0
				if value <= DEFAULT_WIDTH then 
					value = DEFAULT_WIDTH 
				end 
				db.global.display.anchor.w = value
				LibWindow.RestorePosition(_G.Toaster.anchorFrame)
			end,
			dialogControl = "EditBox",
		}
		-- Add editbox "Height"
		args.h = {
			order = 57,
			type = "input",
			name = L["H Offset"],
			desc = L["H Offset Desc"],
			get = function()
				return toStr[round(db.global.display.anchor.h)]
			end,
			set = function(info, value)
				local value = toNum[value] or 0
				if value <= DEFAULT_HEIGHT then 
					value = DEFAULT_HEIGHT
				end 
				db.global.display.anchor.h = value 
				LibWindow.RestorePosition(_G.Toaster.anchorFrame)
			end,
			dialogControl = "EditBox",
		}
		-- Add slider "Scale"
		args.scale = {
			order = 44,
			name = L["Scale"],
			desc = L["Scale Desc"],
			type = "range",
			min = 1,
			max = 8,
			step = 1,
			get = function()
				return db.global.display.anchor.scale
			end,
			set = function(info, value)
				db.global.display.anchor.scale = value
				LibWindow.RestorePosition(_G.Toaster.anchorFrame)
			end,
		}
	end 
	
	local ADDON_NAME_COLOR = ADDON_NAME .. ":Color"
	local TOASTER_NAME_COLOR = "Toaster:Color"	
	local preview_registered = false
	local function createFunc(reference)
		return function()
			if not preview_registered then
				local L = AceLocale:GetLocale(ADDON_NAME)
				LibToast:Register("ToasterPreview", function(toast, ...)
					toast:SetTitle("Preview")
					toast:SetFormattedText(L["This is a %s preview toast."], (...):gsub("_", " "))
					toast:SetIconTexture([[Interface\FriendsFrame\Battlenet-WoWicon]])
					toast:SetUrgencyLevel(...)
				end)
				preview_registered = true
			end
			LibToast:Spawn("ToasterPreview", reference)	
		end 
	end 
	local function replaceFuncs(obj, upperKey)		
		for k, v in pairs(obj) do 
			if type(v) == "table" then 
				replaceFuncs(v, k)
			elseif k == "func" then 
				local reference = upperKey and upperKey:match("%p([%a%p]+)%p")
				if not reference then 
					error("The Action Toaster - Failed to find 'reference'")
				else 
					obj[k] = createFunc(reference)
				end 
			end 
		end 
	end 
	
	hooksecurefunc(AceConfigRegistry, "RegisterOptionsTable", function(...)
		local _, argName, argOptions = ...
		
		-- The Action Toaster
		if argName == ADDON_NAME and type(argOptions) == "function" then 
			-- That will return by function the options table which is static in the Toaster\Config.lua 
			-- This code is private which means what global Toaster's instance will not be affected by this 
			local anchorFrame
			local storage = private.db.global.display.anchor
			for windowFrame, windowObject in pairs(LibWindow.windowData) do 
				if windowObject.storage == storage then 
					anchorFrame = windowFrame
					break 
				end 
			end 
			
			local options = argOptions()
			options.name = TOASTER_NAME					
			
			-- Remove 1th tab since its built-in embeds
			options.args.addOnsOptions = nil 
			
			-- Modify 2th tab 
			local defaultOptions = options.args.defaultOptions
			defaultOptions.args.minimap_icon = nil
			defaultOptions.args.reset.func = function()
				-- This is fix for original code 
				resetTableFromTable(private.db.global.display, private.DATABASE_DEFAULTS.global.display)
				resetTableFromTable(private.db.global.general, private.DATABASE_DEFAULTS.global.general)
                LibWindow.RestorePosition(anchorFrame)
			end	
			push_DefautOptions(defaultOptions, private.db, ADDON_NAME)

			-- Reallocate to Action.Toaster 
			Toaster.options = options
			Toaster.anchorFrame = anchorFrame
			Toaster.storage = storage
			
			-- Update size, scale and parent from db settings
			LibWindow.RestorePosition(anchorFrame)
			hookOnDragStart(anchorFrame)	
		end 
		
		-- The Action Toaster:Color 
		if argName == ADDON_NAME_COLOR and type(argOptions) == "table" then 
			replaceFuncs(argOptions.args)
		end 
		
		-- Toaster (original, stand alone)
		if argName == "Toaster" and _G.Toaster ~= Toaster and _G.Toaster.name == "Toaster" and type(argOptions) == "function" then 		
			-- NOTE: _G.Toaster.db can be replaced by _G.ToasterSettings in case if AceDB will not be reallocated into private.db !! 
			local anchorFrame, storage			
			
			local function GetAnchorFrameAndStorage()
				if not anchorFrame and _G.Toaster.db then 
					storage = _G.Toaster.db.global.display.anchor
					for windowFrame, windowObject in pairs(LibWindow.windowData) do 
						if windowObject.storage == storage then 
							anchorFrame = windowFrame
							Toaster.anchorFrame = anchorFrame
							_G.Toaster.anchorFrame = anchorFrame
							Toaster.storage = storage
							_G.Toaster.storage = storage
							break 
						end 
					end 				
				end 

				return anchorFrame, storage
			end 
			
			local options = argOptions()
			
			-- Modify 2th tab 			
			local defaultOptions = options.args.defaultOptions
			defaultOptions.args.reset.func = function()
				-- This is fix for original code 
				resetTableFromTable(_G.Toaster.db.global.display, private.DATABASE_DEFAULTS.global.display)				
				resetTableFromTable(_G.Toaster.db.global.general, private.DATABASE_DEFAULTS.global.general)		
				LDBIcon:Show("Toaster")
				GetAnchorFrameAndStorage()				
				if anchorFrame then 
					LibWindow.RestorePosition(anchorFrame)
				end 
			end	
			push_DefautOptions(defaultOptions, _G.Toaster.db, "Toaster")
			
			-- Unregister The Action Toaster - Interface Options Panel and use original Toaster panel
			LibWindow.windowData[Toaster.anchorFrame] = nil 
			AceConfigRegistry.tables[ADDON_NAME] = nil			
			AceConfigRegistry.tables[ADDON_NAME .. ":Color"] = nil 
			AceConfigRegistry.tables[TOASTER_NAME] = nil
			AceConfigRegistry.tables[TOASTER_NAME .. ":Color"] = nil 
			
			AceConfigDialog.BlizOptions[ADDON_NAME] = nil 
			AceConfigDialog.BlizOptions[ADDON_NAME .. ":Color"] = nil 
			AceConfigDialog.BlizOptions[TOASTER_NAME] = nil 
			AceConfigDialog.BlizOptions[TOASTER_NAME .. ":Color"] = nil 
			
			local categories = _G.INTERFACEOPTIONS_ADDONCATEGORIES
			local i, data = next(categories)
			while i ~= nil do 
				if data.name == TOASTER_NAME or data.parent == TOASTER_NAME then 
					tremove(categories, i)
				end 			
				i, data = next(categories, i)
			end 
			_G.InterfaceAddOnsList_Update()
			
			-- Reallocate to Action.Toaster 			
			Toaster.options = options
			Toaster.anchorFrame, Toaster.storage = GetAnchorFrameAndStorage() 	
			_G.Toaster.anchorFrame, _G.Toaster.storage = Toaster.anchorFrame, Toaster.storage

			-- Update size, scale and parent from db settings
			LibWindow.RestorePosition(anchorFrame)
			hookOnDragStart(anchorFrame)
		end 	

		-- Toaster:Color 
		if argName == TOASTER_NAME_COLOR and type(argOptions) == "table" then 
			replaceFuncs(argOptions.args)
		end 	
	end)
	
	-- OnInitialize
	local function OnInitialize(self)
		if self.name ~= ADDON_NAME then 
			error("The Action Toaster - Failed in hook on 'Toaster:OnInitialize'. Object doesn't match addon's own object") 
			return
		end 
		
		-- Reallocates Toaster into Action 
		Toaster.IsInitialized			= true	
		
		-- Creates function to open options panel
		local optionsFrame 				= _G.InterfaceOptionsFrame or _G.SettingsPanel or _G.Settings
		local openToCategory 			= _G.InterfaceOptionsFrame_OpenToCategory or _G.Settings.OpenToCategory
		function Toaster:Toggle() 		
			if optionsFrame:IsVisible() then
				optionsFrame:Hide()
			else
				openToCategory(ADDON_NAME)
			end
		end 		
		
		-- Turns off minimap
		local LibDBIcon = LibStub("LibDBIcon-1.0")
		if LibDBIcon.objects[ADDON_NAME] then 
			LibDBIcon:Hide(ADDON_NAME)
			
			-- Just null function which will not cause show up minimap's frame
			LibDBIcon.objects[ADDON_NAME].Show = function() end 
		end
		
		-- Turns off slash command
		Toaster:UnregisterChatCommand("toaster")

		-- Reallocates names so it will keep available running more than one Toaster's instances
		AceConfigRegistry.tables[TOASTER_NAME] = AceConfigRegistry.tables[ADDON_NAME]; AceConfigRegistry.tables[ADDON_NAME] = nil 
		AceConfigRegistry.tables[TOASTER_NAME .. ":Color"] = AceConfigRegistry.tables[ADDON_NAME .. ":Color"]; AceConfigRegistry.tables[ADDON_NAME .. ":Color"] = nil 
		Toaster.name 			= TOASTER_NAME
		Toaster.baseName		= TOASTER_NAME
	
		Toaster.ColorOptions.parent = TOASTER_NAME
		Toaster.ColorOptions.obj.frame.parent = TOASTER_NAME
		Toaster.ColorOptions.obj.userdata.appName = TOASTER_NAME .. ":Color"
		
		Toaster.OptionsFrame.name = TOASTER_NAME		
		Toaster.OptionsFrame.obj.frame.name = TOASTER_NAME
		Toaster.OptionsFrame.obj.label:SetText(TOASTER_NAME)
		Toaster.OptionsFrame.obj:SetName(TOASTER_NAME)
		Toaster.OptionsFrame.obj:SetTitle(TOASTER_NAME)
		Toaster.OptionsFrame.obj.userdata.appName = TOASTER_NAME
				
		AceConfigDialog.BlizOptions[TOASTER_NAME] = AceConfigDialog.BlizOptions[ADDON_NAME]
		AceConfigDialog.BlizOptions[TOASTER_NAME][TOASTER_NAME] = AceConfigDialog.BlizOptions[TOASTER_NAME][ADDON_NAME]
		AceConfigDialog.BlizOptions[ADDON_NAME] = nil
		AceConfigDialog.BlizOptions[TOASTER_NAME][ADDON_NAME] = nil 
		
		AceConfigDialog.BlizOptions[TOASTER_NAME .. ":Color"] = AceConfigDialog.BlizOptions[ADDON_NAME .. ":Color"]
		AceConfigDialog.BlizOptions[TOASTER_NAME .. ":Color"][TOASTER_NAME .. ":Color"] = AceConfigDialog.BlizOptions[TOASTER_NAME .. ":Color"][ADDON_NAME .. ":Color"]
		AceConfigDialog.BlizOptions[ADDON_NAME .. ":Color"] = nil 
		AceConfigDialog.BlizOptions[TOASTER_NAME .. ":Color"][ADDON_NAME .. ":Color"] = nil 
		
		-- Register Action addon to be visible if running stand alone Toaster 
		Listener:Add("ACTION_EVENT_TOASTER", "ADDON_LOADED", function(addonName)			
			if addonName == "Toaster" and _G.Toaster ~= Toaster and _G.Toaster.name == "Toaster" then 	
				-- This thing doesn't hide anything but interracts with private.db of its _G.Toaster to register as an addon in the first tab
				_G.Toaster:HideToastsFromSource(ADDON_NAME)		
				-- Reallocation
				Toaster.OptionsFrame = _G.Toaster.OptionsFrame
				Toaster.ColorOptions = _G.Toaster.ColorOptions				
				Listener:Remove("ACTION_EVENT_TOASTER", "ADDON_LOADED")				
			end 
		end)	
	end 
	
	if not _G[wrongName] then 
		-- If addon was not initilized
		hooksecurefunc(Toaster, "OnInitialize", OnInitialize)
	else 
		-- If addon was already initilized
		if _G["ToasterSettings"] then  
			AceDB:New("ToasterSettings", private.DATABASE_DEFAULTS, "Default")
		end 
		
		AceDB:New(wrongName, private.DATABASE_DEFAULTS, "Default")
		
		-- It will be fired for both instances _G.Toaster and Toaster 
		local AceConfigDialog_AddToBlizOptions = AceConfigDialog.AddToBlizOptions
		AceConfigDialog.AddToBlizOptions = function(self, name) 
			if name == ADDON_NAME then 
				return Toaster.OptionsFrame 
			elseif name == ADDON_NAME_COLOR then 
				return Toaster.ColorOptions
			end 
		end 
		Toaster:SetupOptions()
		AceConfigDialog.AddToBlizOptions = AceConfigDialog_AddToBlizOptions
		
		OnInitialize(Toaster)
	end 

	-- Registers default toast
	LibToast:Register("ActionDefault", function(toast, ...)		
		local msg, urgency, obj = ...
		if type(obj) == "table" and obj:IsActionTable() then 
			toast:SetTitle("The Action - " .. (obj:Info()))
			toast:SetIconTexture((obj:Icon()))
		else
			toast:SetTitle("The Action")
			toast:SetIconTexture(CONST.AUTOTARGET)
		end 
		toast:SetText(msg)		
		toast:SetUrgencyLevel(urgency or "normal")		
	end)	
end 

-------------------------------------------------------------------------------
-- API 
-------------------------------------------------------------------------------
-- All API should be used through Action.Toaster instead of _G.Toaster (!) 
if not Toaster then 
	Toaster = {} 
end 

A.Toaster = Toaster

function Toaster:Register(template_name, constructor, is_unique)
	-- Registers a template for the given toast. Templates are stored by the library for the duration of the session to be spawned at any time.
	-- Arguments:
	-- template_name
	-- @string - Unique name for the toast template.
	-- 
	-- constructor
	-- @function - All toast API is invoked here. Occurs whenever the template is spawned.
	--
	-- is_unique	
	-- @boolean - if true, no other instances of this toast template may be spawned while one is in existence.
	--
	--[[ Toasts API "constructor(toast, ...)":
	Once the constructor has run, a toast is limited to manipulation from the following methods.

	toast:SetUrgencyLevel(urgency)
		- urgency
		- @string - "very_low", "moderate", "normal", "high", "emergency" - Underscored may be omitted, case does not matter.

	toast:UrgencyLevel()
		- Returns value
		-
		- urgency
		- @string - The current urgency level of the toast object.

	toast:SetTitle(title)
		- title
		- @string - the title of the toast.

	toast:SetFormattedTitle(title_format, ...)
		- title_format
		- @string - the format for the title of the toast.
		-
		- ...
		- @varags - variable number of arguments for the format.

	toast:SetText(text)
		- text
		- @string - the text body of the toast.

	toast:SetFormattedText(text_format, ...)
		- text_format
		- @string - the format for the text body of the toast.
		-
		- ...
		- @varags - variable number of arguments for the format.

	toast:SetIconAtlas(atlas)
		- atlas
		- @string - icon atlas value

	toast:SetIconTexture(texture_path)
		- texture_path
		- @string or @number - path or fileID where the desired icon texture file resides.

	toast:SetIconTexCoord(minX, maxX, minY, maxY)
		- minX
		- @number - Left edge of the scaled/cropped image, as a fraction of the image's width from the left.
		- 
		- maxX
		- @number - Right edge of the scaled/cropped image, as a fraction of the image's width from the left.
		- 
		- minY
		- @number - Top edge of the scaled/cropped image, as a fraction of the image's height from the top.
		- 
		- maxY
		- @number - Bottom (or maxY) edge of the scaled/cropped image, as a fraction of the image's height from the top.

	toast:SetIconTexCoord(ULx, ULy, LLx, LLy, URx, URy, LRx, LRy)
		- ULx
		- @number - Upper left corner X position, as a fraction of the image's width from the left.
		- 
		- ULy
		- @number - Upper left corner Y position, as a fraction of the image's height from the top.
		- 
		- LLx
		- @number - Lower left corner X position, as a fraction of the image's width from the left.
		- 
		- LLy
		- @number - Lower left corner Y position, as a fraction of the image's height from the top.
		- 
		- URx
		- @number - Upper right corner X position, as a fraction of the image's width from the left.
		- 
		- URy
		- @number - Upper right corner Y position, as a fraction of the image's height from the top.
		- 
		- LRx
		- @number - Lower right corner X position, as a fraction of the image's width from the left.
		- 
		- LRy
		- @number - Lower right corner Y position, as a fraction of the image's height from the top.

	toast:SetPrimaryCallback(label, handler)
		- label
		- @string - Label for the button that will be created for this callback.
		- 
		- handler
		- @function - Function to be executed when the button is pressed. Accepts no arguments.

	toast:SetSecondaryCallback(label, handler)
		- label
		- @string - Label for the button that will be created for this callback.
		- 
		- handler
		- @function - Function to be executed when the button is pressed. Accepts no arguments.

	toast:SetTertiaryCallback(label, handler)
		- label
		- @string - Label for the button that will be created for this callback.
		- 
		- handler
		- @function - Function to be executed when the button is pressed. Accepts no arguments.


	toast:SetPayload(...)
		- ...
		- @vararg - Data which all callback buttons may use.

	toast:Payload()
		- Return value
		- 
		- payload
		- @variable - Data which was set as the toast object's payload.

	toast:MakePersistent()
		- The toast will not automatically fade out after being displayed. The user must click the close button in the corner or invoke a handler button.

	toast:SetSoundFile(file_path)
		- file_path
		- @string - path where the desired sound file resides.
]]	
	
	if self.IsInitialized then 
		LibToast:Register(template_name, constructor, is_unique)
	end 
end 

function Toaster:UnRegister(template_name, is_unique)
	-- Unregisters a template for the given toast.
	
	if self.IsInitialized then 
		templates[template_name] = nil
		if is_unique then 
			unique_templates[template_name] = nil 
		end 
	end 
end 

function Toaster:IsRegistered(template_name, is_unique)
	-- @return boolean 
	return templates[template_name] and (is_unique == nil or unique_templates[template_name]) and true 
end 

function Toaster:IsPlaying(template_name, msg)
	-- @return boolean 
	if expirationToasts[template_name] then 
		if msg and expirationToasts[template_name][msg] then 
			return TMW.time <= expirationToasts[template_name][msg]
		else 
			return TMW.time <= expirationToasts[template_name].expirationTemplate
		end 
	end 
end 

function Toaster:GetTimeSincePlaying(template_name, msg)
	-- @return number 
	-- Returns 0 if it's still playing 
	if expirationToasts[template_name] then 
		if msg and expirationToasts[template_name][msg] then 
			return math_max(TMW.time - expirationToasts[template_name][msg], 0)
		else
			return math_max(TMW.time - expirationToasts[template_name].expirationTemplate, 0)
		end 
	end 
	
	return math_huge
end 

function Toaster:ChangeTimer(template_name, msg, timer)
	if expirationToasts[template_name] then
		if timer and timer <= 0 then 
			timer = nil 
		end 
		
		if msg and expirationToasts[template_name][msg] then 
			expirationToasts[template_name][msg] = TMW.time + (timer or (((_G.Toaster and _G.Toaster:Duration(ADDON_NAME)) or DEFAULT_FADE_HOLD_TIME) + 1.2)) 
		else
			expirationToasts[template_name].expirationTemplate = TMW.time + (timer or (((_G.Toaster and _G.Toaster:Duration(ADDON_NAME)) or DEFAULT_FADE_HOLD_TIME) + 1.2)) 
		end 
	end 
end 

function Toaster:Spawn(template_name, ...)
	-- Spawns a toast by his registered template.
	-- Arguments:
	-- template_name
	-- @string - Pre-existing unique name for the toast template to be spawned.
	--
	-- ... 
	-- @vararg - extra data which is passed to the toast's constructor function.
	
	if self.IsInitialized and (not self.db.global.general.only_in_combat or Unit("player"):CombatTime() > 0) then 
		if template_name == nil or templates[template_name] == nil then 
			template_name = "ActionDefault"
		end 
		
		local msg = ...
		if type(msg) ~= "string" then 
			msg = nil 			
			local max_arg = select("#", ...)
			if max_arg > 1 then
				local arg
				for i = 2, max_arg do 
					arg = select(i, ...)
					if type(arg) == "string" then 
						msg = arg 
						break
					end 
				end 
			end 
		end 
		
		local expiration = TMW.time + (((_G.Toaster and _G.Toaster:Duration(ADDON_NAME)) or DEFAULT_FADE_HOLD_TIME) + 1.2)
		expirationToasts[template_name].expirationTemplate = expiration
		if msg and TMW.time > expirationToasts[template_name][msg] then 
			expirationToasts[template_name][msg] = expiration
		end 
		
		LibToast:Spawn(template_name, ...)
	end 
end 

function Toaster:SpawnByTimer(template_name, timer, ...)
	-- Spawns a toast by his registered template with expiration timer 
	-- Each toast has signature as template_name with message, at least one of the vararg must contain @string type as an argument
	-- Arguments:
	-- template_name
	-- @string - Pre-existing unique name for the toast template to be spawned.
	--
	-- timer 
	-- @number or @nil - if its nil or <= 0 then timer will be set to its toast's duration or default faded time.
	-- 
	-- ... 
	-- @vararg - extra data which is passed to the toast's constructor function.
	
	if self.IsInitialized and (not self.db.global.general.only_in_combat or Unit("player"):CombatTime() > 0) then 
		if template_name == nil or templates[template_name] == nil then 
			template_name = "ActionDefault"
		end 
		
		local msg = ...
		if type(msg) ~= "string" then 
			msg = nil 			
			local max_arg = select("#", ...)
			if max_arg > 1 then
				local arg
				for i = 2, max_arg do 
					arg = select(i, ...)
					if type(arg) == "string" then 
						msg = arg 
						break
					end 
				end 
			end 
		end 
				
		if msg and TMW.time > expirationToasts[template_name][msg] then 
			if timer and timer <= 0 then 
				timer = nil 
			end 
			local expiration = TMW.time + (timer or (((_G.Toaster and _G.Toaster:Duration(ADDON_NAME)) or DEFAULT_FADE_HOLD_TIME) + 1.2))			
			expirationToasts[template_name][msg] = expiration
			expirationToasts[template_name].expirationTemplate = expiration
			
			LibToast:Spawn(template_name, ...)
		end 
	end 
end 

function Toaster:PlayDemo(spellID)
	-- Runs in 3 seconds after use the demo preview of the use in the loop notifications about spellID
	-- 3 iterations every 20 seconds before stop loop
	-- @usage: /run Action.Toaster:PlayDemo(198013)
	if self.IsInitialized then 
		if not spellID then 
			spellID = 198013
		end 
		
		if not self:IsRegistered("ActionDemo") then 
			self:Register("ActionDemo", function(toast, ...)		
				local msg, urgency, spellID = ...
				if spellID then 
					local name, _, icon = A.GetSpellInfo(spellID)
					toast:SetTitle("The Action - " .. name)
					toast:SetIconTexture(icon)
				else
					toast:SetTitle("The Action")
					toast:SetIconTexture(CONST.AUTOTARGET)
				end 
				toast:SetText(msg)		
				toast:SetUrgencyLevel(urgency or "normal")		
			end)
		end 
		
		if not self.demoFrame then 
			self.demoFrame = _G.CreateFrame("Frame")
			self.demoFrame.setDefaults = function()
				self.demoFrame.iteration = 0
				self.demoFrame.cdTime = 20
				self.demoFrame.delay = 0
				self.demoFrame.expirationTime = TMW.time + 6
				self.demoFrame.spellID = spellID
				self.demoFrame.spellName = A.GetSpellInfo(self.demoFrame.spellID)
			end 
			self.demoFrame.getCooldown = function()
				return math_max(self.demoFrame.expirationTime - TMW.time, 0)
			end 
			self.demoFrame.func = function(this, elapsed)
				this.elapse = (this.elapse or 0) + elapsed
				if this.elapse > TMW.UPD_INTV then 
					local cd = round(this:getCooldown())
					if cd == 0 then 												
						-- Just simulation that we're still moving
						this.delay = this.delay + elapsed 
						if this.delay > 2.5 then 
							this.delay = 0 
							this.iteration = this.iteration + 1
							this.expirationTime = TMW.time + this.cdTime
							
							-- Stop demo 
							if this.iteration > 3 then 
								this:SetScript("OnUpdate", nil)
							end 
						elseif this.delay > 2 then 
							-- Still ignores notification? Let's run it as emergency!
							self:SpawnByTimer("ActionDemo", 0.2, "Are you blind?! DO NOT move!!!! xD", "emergency", this.spellID)
						else 
							self:SpawnByTimer("ActionDemo", 0, "Is ready to cast! Stop moving!!!", "high", this.spellID)
						end 
					elseif cd <= 3 then 
						self:SpawnByTimer("ActionDemo", 0, ("Will be ready in %d. Prepare to stop moving!"):format(cd), "normal", this.spellID)
					end 
					
					this.elapse = 0 
				end 
			end
			self.demoFrame.setDefaults()
			self.demoFrame:SetScript("OnUpdate", self.demoFrame.func)
		else 
			self.demoFrame.setDefaults()
			self.demoFrame:SetScript("OnUpdate", self.demoFrame.func)
		end 
	end 
end 

-------------------------------------------------------------------------------
-- API Examples
-------------------------------------------------------------------------------
-- "ActionDefault" toast template accepts as vararg arguments:
-- msg[, urgency[, obj]]
-- msg 
-- @string - Notification text, required!
-- 
-- urgency
-- @string - "very_low", "moderate", "normal", "high", "emergency" - Underscored may be omitted, case does not matter. Default "normal"
--
-- obj
-- @table - The Action's object 
--[[
-- Registers own toast:
local Toaster = _G.Action.Toaster 
local GetSpellTexture = _G.TMW.GetSpellTexture
Toaster:Register("MyOwnToast", function(toast, ...)
	local title, message, spellID = ...
	toast:SetTitle(title or "nil")
	toast:SetText(message or "nil")
	if spellID then 
		if type(spellID) ~= "number" then 
			error(tostring(spellID) .. " (spellID) is not a number for 'MyOwnToast'!")
			toast:SetIconTexture("Interface\FriendsFrame\Battlenet-WoWicon")
		else 
			toast:SetIconTexture((GetSpellTexture(spellID)))
		end 
	else 
		toast:SetIconTexture("Interface\FriendsFrame\Battlenet-WoWicon")
	end 
	toast:SetUrgencyLevel("normal") 
end)

-- Spawn our registered 'MyOwnToast' toast:
/run Action.Toaster:Spawn("MyOwnToast", "My Title", "My Message", 1022) -- 1022 is Blessing of Protection spellID
/run Action.Toaster:Spawn("MyOwnToast", "My Title", "My Message")		-- Can be used without spellID argument if we don't need spell texture 
 
-- Spawn examples:
/run Action.Toaster:Spawn("ActionDefault", "Test message provided by toast as normal")
/run Action.Toaster:Spawn("ActionDefault", "Test message provided by toast as emergency", "emergency")
/run Action.Toaster:Spawn("ActionDefault", ("Test message provided by toast as emergency by %s"):format((Action[Action.PlayerSpec].Trinket1:Info())), "emergency", Action[Action.PlayerSpec].Trinket1)


-- SpawnByTimer examples:
-- If timer is nil or <= 0 then the timer will be set to its toast's duration or default faded time
/run Action.Toaster:SpawnByTimer("ActionDefault", 0, "Test message provided by toast as normal")					
/run Action.Toaster:SpawnByTimer("ActionDefault", 0, "Test message provided by toast as emergency", "emergency")
/run Action.Toaster:SpawnByTimer("ActionDefault", 0, ("Test message provided by toast as emergency by %s"):format((Action[Action.PlayerSpec].Trinket1:Info())), "emergency", Action[Action.PlayerSpec].Trinket1)

-- Spam message not often than 10 seconds 
/run if not Action.Toaster:IsPlaying("ActionDefault") then Action.Toaster:SpawnByTimer("ActionDefault", 10, ("Spam message was sent at %d"):format(TMW.time)) end 
]]