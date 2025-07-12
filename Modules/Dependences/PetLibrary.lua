-------------------------------------------------------------------------------------------
-- This library provides Pet methods and any possible interactions 
-- @req: MacroLibrary
-------------------------------------------------------------------------------------------
--[[ DOCUMENTATION:
local Pet = LibStub("PetLibrary")
-- The 'Pet' is a table which has public keys to retrive infomartion about main pet, such as:
-- Pet.Name
-- Pet.GUID 
-- Pet.ID
-- Pet.IsExists
-- Pet.IsDead
-- Pet.IsAttacks
-- Pet.IsCallAble						Note: Returns false if you can't call pet by hunter (if you haven't tamed pet)
-- Pet.Family							Note: Returns English localized string of CreatureFamily
-- Pet.Type 							Note: Returns English localized string of CreatureType
-- Pet.Food		 						Note: Returns English localized table of all available FoodTypes as  { [englishFoodName] = true }
-- Pet.start 							Note: Start time when pet was summoned, never erases afterward
-- Pet.expiration
-- Pet.duration
-- Also 'Pet' has Pet.Data table which is storage and can be used for own manipulation and interaction with PetLibrary 

-- PetLibrary has shared methods which will work without initialization, such as:
-- Pet:IsSpellKnown(spell)				Note: Pet must be active i.e. exists and alive to have it working

-- PetLibrary has API - Actions which required initialization through:
-- Pet:AddActionsSpells(owner, spells, useManagement, useSilence, delMacros) 
-- 
-- Detailed explains about arguments possible to find in function illustration
-- This API - Actions supposed to control (management) pet spells on your action bar by spell-action (Retail) or spell-macro (Classic)
-- And at the end provide range check by your pet to any units by added action's spells
--
-- Action bar performs full cycle work only after pet summon/create/exist.., common usage if pet summoned:
-- Pet:GetInRange(spell, stop)			Note: Returns count of enemy units in range by listed 'spell' argument
-- Pet:IsInRange(spell, unitID)			Note: Returns true if 'unitID' is in range by 'spell' argument 

-- PetLibrary has API - Trackers which required initialization through:
-- Pet:AddTrackers(owner, customConfig)
--
-- Detailed explains about arguments possible to find in function illustration
-- This API - Trackers supposed to prodive additional callbacks and functional for non-main pets which are summoned by character
--
-- Below methods can be used as well for main pet too:
-- Pet:IsActive(pet)					Note: Returns true if 'pet' which is specified is active, if 'nil' then if main pet is active (accepts true as second argument to skip check dead condition)
-- Pet:GetCount(pet)					Note: Returns always number the count of the pets, can return 1 for main pet if he is specified 
-- Pet:GetRemainDuration(pet)			Note: Returns lowest, averange, highest of the remain durations
-- 
-- Callbacks provided with API - Trackers:
-- PetTable is a @table with next keys: id, name, realName, duration, count, GUIDs 
TMW:RegisterCallback("TMW_ACTION_PET_LIBRARY_REMOVED", function(callbackEvent, PetID, PetGUID, PetTable, isMainPet)
	if isMainPet then 
		print("Removed main pet with name " .. PetTable.name)
	else 
		print("Removed non-main pet: " .. PetID .. ", GUID: " .. PetGUID .. ", left count: " .. PetTable.count .. ", left lowest duration: " .. Pet:GetRemainDuration(PetID))
	end 
end)

TMW:RegisterCallback("TMW_ACTION_PET_LIBRARY_ADDED", function(callbackEvent, PetID, PetGUID, PetTable)
	print("Added " .. PetID .. ", his name is " .. PetTable.name .. ", GUID: " .. PetGUID .. ", now count: " .. PetTable.count)
	-- If we want to modify data we can 
	PetTable.myVar = "custom data"
	print(PetTable.myVar)
	print(Pet.Data.Trackers[ Action[Pet.Data.owner] ].PetIDs[PetID].myVar .. " - it's equal") -- it's static table 
	print(Pet.Data.Trackers[ Action[Pet.Data.owner] ].PetGUIDs[PetGUID].myVar .. " - it's equal also but it's not static table") 
	-- The static table means exact PetIDs and Config because once created it will not be erased afterwards unless we will use Pet:RemoveTrackers(owner)
end)

-- Moreover default library even without initialization will prodive callbacks for main pet when it's up or down:
TMW:RegisterCallback("TMW_ACTION_PET_LIBRARY_MAIN_PET_UP", function(callbackEvent)
	print("Main pet summoned/tamed/created with name: " .. Pet.Name)
end)

TMW:RegisterCallback("TMW_ACTION_PET_LIBRARY_MAIN_PET_DOWN", function(callbackEvent)
	print("Main pet dismissed/dead/ran out from master. Is pet ran out? - " .. Pet.IsCallAble .. " Is pet dead? - " .. Pet.IsDead .. " Is pet dismissed? - " .. (not Pet.IsExists and Pet.IsCallAble and not Pet.IsDead))
end)
--]]

local _G, type, next, pairs, select, setmetatable, error, math =
	  _G, type, next, pairs, select, setmetatable, error, math

local TMW 								= _G.TMW 
local A 								= _G.Action
local CONST 							= A.Const
local Listener							= A.Listener
local Print								= A.Print
local GetCL								= A.GetCL
local MacroLibrary						= LibStub("MacroLibrary")
local Lib 								= LibStub:NewLibrary("PetLibrary", 29)

local huge 								= math.huge	  
local max 								= math.max
local wipe 								= _G.wipe	  
local isClassic							= A.StdUi.isClassic
local owner								= isClassic and "PlayerClass" or "PlayerSpec"

local C_CVar 							= _G.C_CVar
local GetCVar 							= C_CVar and C_CVar.GetCVar or _G.GetCVar
local SetCVar 							= C_CVar and C_CVar.SetCVar or _G.SetCVar
	  
local C_SpellBook						= _G.C_SpellBook	  
local C_Spell 							= _G.Spell
local 	 IsActionInRange, 	 GetActionInfo,    PlaceAction,    ClearCursor,    GetCursorInfo, 	 GetPetFoodTypes, 	 													 GetSpellBookItemInfo, 	  									 		 		  GetSpellBookItemName,														  PickupSpellBookItem, 					  		  					  HasPetSpells,    PetHasSpellbook =
	  _G.IsActionInRange, _G.GetActionInfo, _G.PlaceAction, _G.ClearCursor, _G.GetCursorInfo, _G.GetPetFoodTypes, C_SpellBook and C_SpellBook.GetSpellBookItemInfo or _G.GetSpellBookItemInfo, C_SpellBook and C_SpellBook.GetSpellBookItemName or _G.GetSpellBookItemName,	C_SpellBook and C_SpellBook.PickupSpellBookItem or _G.PickupSpellBookItem, C_SpellBook and C_SpellBook.HasPetSpells or _G.HasPetSpells, _G.PetHasSpellbook

local GameLocale 						= _G.GetLocale()
local GetUnitSpeed						= _G.GetUnitSpeed
local CreateFrame						= _G.CreateFrame 	  
local CombatLogGetCurrentEventInfo		= _G.CombatLogGetCurrentEventInfo	 
local InCombatLockdown					= _G.InCombatLockdown   
local UnitGUID							= _G.UnitGUID
local UnitName							= _G.UnitName	
local UnitIsUnit						= _G.UnitIsUnit	
local GARRISON_SWITCH_SPECIALIZATIONS	= _G.GARRISON_SWITCH_SPECIALIZATIONS or ""
local MAX_ACTION_SLOTS					= 120 -- Classic+ have 120 slots now

local Enum								= _G.Enum
local PET_BOOK							= Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet or (isClassic and BOOKTYPE_PET) or 1

Lib.IsCallAble 							= true -- Default true for attemp to call pet as Hunter, after that we will know if its call able or not through error message 
Lib.Food								= {
	--[[ Structure:
		["FoodEnglish"] 	= true,
		["Meat"] 			= true,
	--]]
}
Lib.Data 								= {
	isInitializedAddon					= false,
	isInitializedActions				= false,
	isInitializedTrackers				= false,
	isClassic							= isClassic,
	owner								= owner,
	KnownSpells							= {},
	Actions								= {
		--[[ Structure:
		[owner] 						= { -- Retail: specID / Classic: classNameENG upper case
			Config						= {
				useManagement			= true,
				useSilence				= false,
				lastNotificationTime	= TMW.time,
			},
			Spells						= {
				["spellName"]			= {
					button 				= 1-MAX_ACTION_SLOTS,
					type				= "spell", "macro", nil,
					id 					= actionID, nil,
					subtype				= "petaction", nil,
					spellName 			= "spellName", nil,	
				},
			},
			Buttons 					= {
				[actionSlot]			= { -- Pointer to Spells["spellName"]					
					button 				= 1-MAX_ACTION_SLOTS,
					type				= "spell", "macro", nil,
					id 					= actionID, nil,
					subtype				= "petaction", nil,
					spellName 			= "spellName", nil,					
				},
			},
		},
		--]]
	},
	Trackers 							= {		
		--[[ Structure:
		[owner] 						= { -- Retail: specID / Classic: classNameENG upper case
			Config						= {
				PreventCleanPetTable	= false,
				HideErrors				= false,
				[petID]					= { -- This is custom template, if not specified then will be used default
					name 				= "",
					duration 			= huge,
					...					-- custom data that will be created when pet summoned 
				},
			},
			PetIDs						= {	-- It holds main pet but not viable, just table exist to recycle
				[petID]					= {
					id 					= petID,
					name 				= "petName",	-- Can be setup in Config
					realName 			= "DestName",
					duration			= huge,			-- Can be setup in Config
					count 				= 1,
					GUIDs				= {
						["petGUID"]		= {
							updated 	= 0,
							start 		= 0,
							expiration	= 0,
						},
					},
				},
			},
			PetGUIDs 					= {	-- It never holds main pet 
				["GUID"]				= { -- Pointer to PetIDs[petID]
					id 					= petID,
					name 				= "petName",	-- Can be setup in Config
					realName 			= "DestName",
					duration			= huge,			-- Can be setup in Config
					count 				= 1,
					GUIDs				= {
						["petGUID"]		= {
							updated 	= 0,
							start 		= 0,
							expiration	= 0,
						},
					},
				},
			},			
		},
		--]]
	},
	TrackersConfigPetID					= {
		[CONST.HUNTER_BEASTMASTERY or 253] 	= {},
		[CONST.HUNTER_MARKSMANSHIP or 254] 	= {},
		[CONST.HUNTER_SURVIVAL or 255] 		= {},
		[CONST.SHAMAN_ELEMENTAL or 262] 		= {
			[61029] = {
				name = "Primal Fire Elemental",
				duration = 30,
			},
			[77942] = {
				name = "Primal Storm Elemental",
				duration = 30,
			},			
			[61056] = {
				name = "Primal Earth Elemental",
				duration = 60,
			},
			[95061] = {
				name = "Greater Fire Elemental",
				duration = 30,
			},
			[77936] = {
				name = "Greater Storm Elemental",
				duration = 30,
			},
			[95072] = {
				name = "Greater Earth Elemental",
				duration = 60,
			},
		}, 
		[CONST.WARLOCK_AFFLICTION or 265] 	= {},
		[CONST.WARLOCK_DEMONOLOGY or 266] 	= {
			[98035] = {
				name = "Dreadstalker",
				duration = 12.25,
			},
			[55659] = {
				name = "Wild Imp",
				duration = 20,
			},
			[143622] = {
				name = "Wild Imp",
				duration = 20,
			},
			[17252] = {
				name = "Felguard",
				duration = 28,
			},
			[135002] = {
				name = "Demonic Tyrant",
				duration = 15,
			},
		},
		[CONST.WARLOCK_DESTRUCTION or 267] 	= {},
		[CONST.DEATHKNIGHT_BLOOD or 250] 	= {
			[26125] = { -- TWW: Ghoul by Raise Dead if not taken override improvement
				name = "Ghoul",
				duration = 60,
			},
		},
		[CONST.DEATHKNIGHT_FROST or 251] 	= {
			[26125] = { -- TWW: Ghoul by Raise Dead if not taken override improvement
				name = "Ghoul",
				duration = 60,
			},
		},
		[CONST.DEATHKNIGHT_UNHOLY or 252] 	= {
			[26125] = { -- TWW: Ghoul by Raise Dead if not taken override improvement
				name = "Ghoul",
				duration = 60,
			},		
			[99541] = { -- talent All Will Serve
				name = "Risen Skulker",
				duration = huge,
			},
			[106041] = { -- pvp talent Reanimation
				name = "Zombie",
				duration = 20,
			},
		},		
	},
	FoodTypes							= setmetatable(
		-- Formats localization to English locale
		-- Revision May 2020
		{
			enUS				= {
				["Meat"]				= "Meat", 				-- [1]
				["Fish"]				= "Fish", 				-- [2]
				["Cheese"]				= "Cheese", 			-- [3]				
				["Bread"]				= "Bread", 				-- [4]				
				["Fungus"]				= "Fungus", 			-- [5]				
				["Fruit"]				= "Fruit", 				-- [6]				
				["Raw Meat"]			= "Raw Meat", 			-- [7]				
				["Raw Fish"]			= "Raw Fish", 			-- [8]
				["Mechanical Bits"]		= "Mechanical Bits", 	-- [9] Retail 
			},
			ruRU				= {
				["Мясо"]				= "Meat", 				-- [1]
				["Рыба"]				= "Fish", 				-- [2]
				["Сыр"]					= "Cheese", 			-- [3]				
				["Хлеб"]				= "Bread", 				-- [4]				
				["Грибы"]				= "Fungus", 			-- [5]				
				["Фрукты"]				= "Fruit", 				-- [6]				
				["Сырое мясо"]			= "Raw Meat", 			-- [7]				
				["Сырая рыба"]			= "Raw Fish", 			-- [8]
				["Кусочки механизмов"]	= "Mechanical Bits", 	-- [9] Retail 
			},
			frFR				= {
				["Viande"]				= "Meat", 				-- [1]
				["Poisson"]				= "Fish", 				-- [2]
				["Fromage"]				= "Cheese", 			-- [3]				
				["Pain"]				= "Bread", 				-- [4]				
				["Champignon"]			= "Fungus", 			-- [5]				
				["Fruit"]				= "Fruit", 				-- [6]				
				["Viande crue"]			= "Raw Meat", 			-- [7]				
				["Poisson cru"]			= "Raw Fish", 			-- [8]
				["Pièces mécaniques"]	= "Mechanical Bits", 	-- [9] Retail 
			},
			deDE				= {
				["Fleisch"]				= "Meat", 				-- [1]
				["Fisch"]				= "Fish", 				-- [2]
				["Käse"]				= "Cheese", 			-- [3]				
				["Brot"]				= "Bread", 				-- [4]				
				["Fungus"]				= "Fungus", 			-- [5]				
				["Obst"]				= "Fruit", 				-- [6]				
				["Rohes Fleisch"]		= "Raw Meat", 			-- [7]				
				["Roher Fisch"]			= "Raw Fish", 			-- [8]
				["Mechanische Teile"]	= "Mechanical Bits", 	-- [9] Retail 
			},
			esES				= {
				["Carne"]				= "Meat", 				-- [1]
				["Pescado"]				= "Fish", 				-- [2]
				["Queso"]				= "Cheese", 			-- [3]				
				["Pan"]					= "Bread", 				-- [4]				
				["Hongo"]				= "Fungus", 			-- [5] Classic 				
				["Hongos"]				= "Fungus", 			-- [5] Retail				
				["Fruta"]				= "Fruit", 				-- [6]				
				["Carne cruda"]			= "Raw Meat", 			-- [7]				
				["Pescado crudo"]		= "Raw Fish", 			-- [8]
				["Tapitas mecánicas"]	= "Mechanical Bits", 	-- [9] Retail Spain
				["Trozos mecánicos"]	= "Mechanical Bits", 	-- [9] Retail Mexico
			},
			ptPT				= {
				["Carne"]				= "Meat", 				-- [1]
				["Peixe"]				= "Fish", 				-- [2]
				["Queijo"]				= "Cheese", 			-- [3]				
				["Pão"]					= "Bread", 				-- [4]				
				["Fungo"]				= "Fungus", 			-- [5]				
				["Fruta"]				= "Fruit", 				-- [6]				
				["Carne Crua"]			= "Raw Meat", 			-- [7]				
				["Peixe Cru"]			= "Raw Fish", 			-- [8]
				["Pecinhas Mecânicas"]	= "Mechanical Bits", 	-- [9] Retail 
			},			
			itIT				= {
				-- Classic hasn't Italy language but dataBase refferenced their locales to koKR
				["Carne"]				 	= "Meat", 				-- [1]
				["고기"]						= "Meat", 				-- [1] Refference
				["Pesce"]					= "Fish", 				-- [2]
				["생선"]				 		= "Fish", 				-- [2] Refference
				["Formaggio"]				= "Cheese", 			-- [3]				
				["치즈"]			 			= "Cheese", 			-- [3] Refference			
				["Pane"]					= "Bread", 			-- [4]				
				["빵"]						= "Bread", 			-- [4] Refference				
				["Funghi"]					= "Fungus", 			-- [5]				
				["버섯"]				 		= "Fungus", 			-- [5] Refference			
				["Frutta"]					= "Fruit", 			-- [6]				
				["과일"]				 		= "Fruit", 			-- [6] Refference				
				["Carne Cruda"]				= "Raw Meat", 			-- [7]				
				["날고기"]			 	 		= "Raw Meat", 			-- [7] Refference				
				["Pesce Crudo"]			 	= "Raw Fish", 			-- [8]
				["날생선"]			 			= "Raw Fish", 			-- [8] Refference
				["Bocconcini Meccanici"] 	= "Mechanical Bits", 	-- [9] Retail 
			},
			koKR				= {
				["고기"]				= "Meat", 				-- [1] 
				["생선"]				= "Fish", 				-- [2] 
				["치즈"]				= "Cheese", 			-- [3]				
				["빵"]				= "Bread", 				-- [4]	 			
				["버섯"]				= "Fungus", 			-- [5] 				
				["과일"]				= "Fruit", 				-- [6]	 			
				["날고기"]				= "Raw Meat", 			-- [7]				
				["날생선"]				= "Raw Fish", 			-- [8] 
				["기계 부품"]			= "Mechanical Bits", 	-- [9] Retail 
			},
			zhCN				= {
				["肉"]				= "Meat", 				-- [1] 
				["鱼"]				= "Fish", 				-- [2] 
				["奶酪"]			= "Cheese", 			-- [3]	 			
				["面包"]			= "Bread", 				-- [4]	 			
				["蘑菇"]			= "Fungus", 			-- [5] 				
				["水果"]			= "Fruit", 				-- [6]				
				["生肉"]			= "Raw Meat", 			-- [7]	 			
				["生鱼"]			= "Raw Fish", 			-- [8] 
				["机械零件"]			= "Mechanical Bits", 	-- [9] Retail 
			},
			zhTW				= {
				["肉"]				= "Meat", 				-- [1] 
				["魚"]				= "Fish", 				-- [2] 
				["乳酪"]			= "Cheese", 			-- [3] 				
				["麵包"]			= "Bread", 				-- [4] 				
				["蘑菇"]			= "Fungus", 			-- [5] 				
				["水果"]			= "Fruit", 				-- [6] 				
				["生肉"]			= "Raw Meat", 			-- [7] 				
				["生魚"]			= "Raw Fish", 			-- [8] 
				["機械零件"]			= "Mechanical Bits", 	-- [9] Retail 
			},		
		},
		{
			__index = function(t, v)
				local CL = GameLocale
				if GameLocale == "enGB" then 
					CL = "enUS"
				elseif GameLocale == "esMX" then 
					-- Mexico used esES
					CL = "esES"
				elseif GameLocale == "ptBR" then 
					-- Brazil used ptPT 
					CL = "ptPT"
				end 
				
				return t[CL][v]
			end,
		}
	),
	L 									= setmetatable(
		{
			[GameLocale] = {},
			enUS = {
				NOTIFICATION_TITLE 			= "[Pet Library - Notification]",
				FOLLOWING_IS_MISSED 		= "The following pet spells are missed on your action bar:",			
				ADD_THIS_ON_ACTION_BAR 		= " please add this spell on the action bar!\n",
				MANAGEMENT_ERRORS 			= "Last Management Errors:",		
				ACTIONS_SUCCESSFUL 			= "All required pet spells on action bar. Well done! :)",
				SPELLBOOK					= "(SpellBook) - ",
				MACRO						= "(Macro) - ",
			},
			ruRU = {
				NOTIFICATION_TITLE 			= "[Pet Library - Уведомление]",
				FOLLOWING_IS_MISSED 		= "Следующие способности питомца пропущены на вашей панеле команд:",
				ADD_THIS_ON_ACTION_BAR 		= ", пожалуйста, добавьте эту способность на панель команд!\n",
				MANAGEMENT_ERRORS 			= "Последние Ошибки Менеджмента:",	
				ACTIONS_SUCCESSFUL 			= "Все необходимые способности питомца на панеле команд. Так держать! :)",
				SPELLBOOK					= "(Книга Заклинаний) - ",
				MACRO						= "(Макрос) - ",
			},
			deDE = {
				NOTIFICATION_TITLE 			= "[Pet Library - Benachrichtigung]",
				FOLLOWING_IS_MISSED 		= "Die folgenden Haustierzauber werden in Ihrer Aktionsleiste übersehen:",			
				ADD_THIS_ON_ACTION_BAR 		= " bitte füge diesen Zauber in die Aktionsleiste ein!\n",
				MANAGEMENT_ERRORS 			= "Letzte Verwaltungsfehler:",		
				ACTIONS_SUCCESSFUL 			= "Alle erforderlichen Haustierzauber auf der Aktionsleiste. Gut gemacht! :)",
				SPELLBOOK					= "(Zauberbuch) - ",
				MACRO						= "(Makro) - ",
			},
			frFR = {
                NOTIFICATION_TITLE          = "[Pet Library - Notification]",
                FOLLOWING_IS_MISSED         = "Les sorts d'animaux suivants sont manquants sur votre barre d'action:",            
                ADD_THIS_ON_ACTION_BAR      = " veuillez ajouter ce sort dans la barre d'action!\n",
                MANAGEMENT_ERRORS           = "Dernières erreurs de gestion:",        
                ACTIONS_SUCCESSFUL          = "Tous les sorts de familier requis sont sur la barre d'action. Bien joué! :)",
				SPELLBOOK					= "(Livre de sortilèges) - ",
				MACRO						= "(Macro) - ",
			},
			itIT = {
				NOTIFICATION_TITLE 			= "[Pet Library - Notifica]",
				FOLLOWING_IS_MISSED 		= "I seguenti incantesimi da compagnia mancano nella barra delle azioni:",			
				ADD_THIS_ON_ACTION_BAR 		= " per favore aggiungi questo incantesimo sulla barra delle azioni!\n",
				MANAGEMENT_ERRORS 			= "Ultimi errori di gestione:",		
				ACTIONS_SUCCESSFUL 			= "Tutti gli incantesimi da compagnia richiesti sulla barra delle azioni. Molto bene! :)",
				SPELLBOOK					= "(Libro degli incantesimi) - ",
				MACRO						= "(Macro) - ",
			},
			esES = {
				NOTIFICATION_TITLE 			= "[Pet Library - Notificación]",
				FOLLOWING_IS_MISSED 		= "Los siguientes hechizos de mascotas se pierden en tu barra de acción:",			
				ADD_THIS_ON_ACTION_BAR 		= " por favor agrega este hechizo en la barra de acción!\n",
				MANAGEMENT_ERRORS 			= "Últimos errores de gestión:",		
				ACTIONS_SUCCESSFUL 			= "Todos los hechizos de mascotas requeridos en la barra de acción. Bien hecho! :)",
				SPELLBOOK					= "(Libro de hechizos) - ",
				MACRO						= "(Macro) - ",
			},
			ptBR = {
                NOTIFICATION_TITLE          = "[Pet Library - Notificação]",
                FOLLOWING_IS_MISSED         = "As seguintes habilidades do seu pet estão faltando na sua barra de ação:",            
                ADD_THIS_ON_ACTION_BAR      = " Por favor adicione essa habilidade na sua barra de ação!\n",
                MANAGEMENT_ERRORS           = "Ultima gestão de erros:",        
                ACTIONS_SUCCESSFUL          = "Todas as habilidades estão na barra de ação. Muito bom! :)",
                SPELLBOOK                   = "(Livro de habilidades) - ",
                MACRO                       = "(Macro) - ",
            },
		}, 
		{ 
			__index = function(t, v)
				return t[GetCL()][v]
			end,
		}
	),
}
Lib.TrackersCleaner 					= CreateFrame("Frame")
Lib.TrackersCleaner.Trackers			= Lib.Data.Trackers	-- Put in self this table for OnUpdate handler
do 
	local function CreateRoutineToENG(t, mirror)
		-- This need to prevent any text blanks caused by missed keys 
		for k, v in pairs(t) do 
			if k ~= "enUS" and type(v) == "table" then 
				local index = Lib.Data.L[k] and mirror or mirror[k]
				setmetatable(v, { __index = index })
				CreateRoutineToENG(v, index)
			end 
		end 
	end 
	CreateRoutineToENG(Lib.Data.L, Lib.Data.L.enUS)
end 
local L 								= Lib.Data.L

-- Remap
local A_Unit, A_Player, A_GetSpellInfo, A_GetSpellLink, ActiveNameplates, TeamCache, TeamCacheFriendly, TeamCacheFriendlyUNITs, TeamCacheFriendlyGUIDs
Listener:Add("ACTION_EVENT_PET_LIBRARY_STARTUP", "ADDON_LOADED", function(addonName)
	if addonName == CONST.ADDON_NAME then 
		A_Unit							= A.Unit
		A_Player						= A.Player
		A_GetSpellInfo					= A.GetSpellInfo
		A_GetSpellLink					= A.GetSpellLink
		ActiveNameplates				= A.MultiUnits:GetActiveUnitPlates()
		
		TeamCache						= A.TeamCache
		TeamCacheFriendly				= TeamCache.Friendly
		TeamCacheFriendlyUNITs			= TeamCacheFriendly.UNITs
		TeamCacheFriendlyGUIDs			= TeamCacheFriendly.GUIDs 
		
		Lib.Data.isInitializedAddon 	= true 
		
		Listener:Remove("ACTION_EVENT_PET_LIBRARY_STARTUP", "ADDON_LOADED")	
	end 
end)

-------------------------------------------------------------------------------
-- Local - Tools 
-------------------------------------------------------------------------------
local tSpellsEmpty = {}
local GetSpellName = setmetatable({}, {
	__index = function(t, spell)
		local spellName 
		local spellType = type(spell)
		
		if spellType == "table" then 
			spellName = spell:Info()
		elseif spellType == "number" then 
			spellName = A_GetSpellInfo(spell)
		else 
			spellName = spell
		end 
		
		t[spell] = spellName
		return spellName
	end,
	__call = function(t, spell)
		return t[spell]
	end,
})

local function tMerge(to, from, skipExistKeys)
	if type(from) ~= "table" then return to end 
	for k, v in pairs(from) do 
		if type(v) == "table" then
			if not to[k] then 
				to[k] = {}
			end 
			
			tMerge(to[k], v)
		elseif not skipExistKeys or to[k] == nil then 
			to[k] = v
		end
	end 
	return to
end

-------------------------------------------------------------------------------
-- Local - Actions
-------------------------------------------------------------------------------
local function SetActionButton(spellName, actionSlot)
	if InCombatLockdown() then 
		return "InCombatLockdown"
	end 
	
	if C_SpellBook and C_SpellBook.PickupSpellBookItem then 
		PickupSpellBookItem(Lib.Data.KnownSpells[spellName] or 0, PET_BOOK)
	else 
		PickupSpellBookItem(spellName)
	end 
	
	if GetCursorInfo() == "petaction" then 
		local slot 
			
		if actionSlot then 			
			PlaceAction(actionSlot)
			slot = actionSlot
		else
			local used 
			for i = MAX_ACTION_SLOTS, 1, -1 do 
				used = GetActionInfo(i)
				if not used then 
					PlaceAction(i)
					slot = i												
					break 
				end 
			end 
		end 
		
		ClearCursor() 

		return nil, slot
	end 
end 

local function UpdateActions(callbackEvent)
	local Pointer = Lib.Data.Actions[A[owner]]
	if Pointer and not Pointer.Config.Locked then 
		Pointer.Config.Locked = true 
		
		for i = 1, #Pointer.Buttons do 
			wipe(Pointer.Buttons[i])
		end
		
		for spellName in pairs(Pointer.Spells) do 
			Pointer.Spells[spellName] = tSpellsEmpty
		end
		
		local actionType, actionID, actionSubType, actionSpellName
		local macroName, _, macroBody, macroID
		for i = MAX_ACTION_SLOTS, 1, -1 do 
			actionType, actionID, actionSubType = GetActionInfo(i)
			if actionID ~= 0 then 
				if actionType == "spell" and actionSubType == "pet" then 
					-- If it's spell we always can check range, no matter if spell known or learned
					actionSpellName = A_GetSpellInfo(actionID)
				elseif actionType == "macro" then 
					-- If it's macro we can check range only if spell learned 				
					macroName, _, macroBody, macroID = MacroLibrary:GetInfo(actionID, "ByActionMacros")
					if not macroName then
						macroName, _, macroBody, macroID = MacroLibrary:GetInfo(actionID)
					end
					
					if macroBody then
						if macroBody:find("#showtooltip\n/cast " .. macroName) then
							actionSpellName = macroName
						elseif Pointer.Spells[macroName] then
							MacroLibrary:DeleteMacro(macroID)
						end
					end 
				end 
			end 
			
			Pointer.Buttons[i].button 		= i
			Pointer.Buttons[i].type 		= actionType
			Pointer.Buttons[i].id	 		= actionID			-- Only for UpdateAction(i) to compare with cache
			Pointer.Buttons[i].subtype 		= actionSubType		-- Only for UpdateAction(i) to compare with cache
			Pointer.Buttons[i].spellName 	= actionSpellName	
			
			if actionSpellName and Pointer.Spells[actionSpellName] then 				
				if actionType == "spell" then -- Note: Don't use Lib:IsSpellKnown at this line!
					Pointer.Buttons[i].valid 	= true
				elseif Lib:IsSpellKnown(actionSpellName) then 
					Pointer.Buttons[i].valid 	= true
				else 
					Pointer.Buttons[i].valid 	= nil 
				end 
			
				if Pointer.Spells[actionSpellName].type ~= "spell" then -- Forced to overwrite "macro" by "spell" if possible
					Pointer.Spells[actionSpellName] = Pointer.Buttons[i]
					if actionSubType == "spell" and Pointer.Config.delMacros and MacroLibrary:IsExists(actionSpellName) then 						
						MacroLibrary:DeleteMacro(actionSpellName)
					end 
				end 
			else 
				Pointer.Buttons[i].valid = nil 
			end 
			
			actionSpellName = nil 
		end
		
		-- If we don't have pet spell book available then it's pointless to do management and notifications 
		if not PetHasSpellbook() then
			Pointer.Config.Locked = nil 
			return 
		end 
		
		local err, errTemp, notification, button
		for spellName in pairs(Pointer.Spells) do 
			if not Pointer.Spells[spellName].button and Lib:IsSpellKnown(spellName) then 				
				if Pointer.Config.useManagement then 
					if not isClassic then
						-- Put by spell book 
						errTemp, button 			= SetActionButton(spellName)

						if errTemp and not Pointer.Config.useSilence then 
							errTemp = spellName .. L.SPELLBOOK .. errTemp
						end 

						if button and Pointer.Config.delMacros and MacroLibrary:IsExists(spellName) then 						
							MacroLibrary:DeleteMacro(spellName)							 
						end 
					else 
						-- Put by macro 
						errTemp			 			= MacroLibrary:CraftMacro(spellName, nil, "#showtooltip\n/cast " .. spellName, true, true)
						button			 			= MacroLibrary:SetActionButton(spellName)
						if errTemp and not Pointer.Config.useSilence then 
							errTemp = spellName .. L.MACRO .. errTemp
						end 
					end 
					
					if button then
						Pointer.Buttons[button].button = button
						Pointer.Buttons[button].type, Pointer.Buttons[button].id, Pointer.Buttons[button].subtype = GetActionInfo(button)	
						-- Debug 
						if not Pointer.Buttons[button].type then 
							errTemp = (errTemp and "\n" or "") .. spellName .. " - nil GetActionInfo"
						else 
							Pointer.Buttons[button].spellName = spellName
							Pointer.Buttons[button].valid 	  = true 
							Pointer.Spells[spellName]		  = Pointer.Buttons[button]
						end 
					end 
					
					-- Debug
					if errTemp then 
						if not Pointer.Config.useSilence then 
							err = (err or "\n") .. errTemp .. "\n"
						end 
						errTemp = nil 
					end 										
				end 
				
				-- Missed
				if not Pointer.Config.useSilence and not Pointer.Spells[spellName].button then 
					notification = (notification or "\n") .. A_GetSpellLink(spellName) .. L.ADD_THIS_ON_ACTION_BAR
				end 
			end 
		end 
		
		if not Pointer.Config.useSilence and (callbackEvent ~= "TMW_PET_LIBRARY_SPELL_BOOK_CHANGED_ACTIONS" or A.IsInitialized) and TMW.time - Pointer.Config.lastNotificationTime > 1 then -- Must have timer in very rare situation when UNIT_PET fires 3 times instead of 4
			if notification or err then 
				Pointer.Config.lastNotificationTime = TMW.time 
				Print(L.NOTIFICATION_TITLE)
				
				-- Missed
				if notification then 
					Print(L.FOLLOWING_IS_MISSED)			
					Print(notification)
				end 
				
				-- Debug
				if err then 
					Print(L.MANAGEMENT_ERRORS .. err)
				end 
			end 
			
			if not notification and not InCombatLockdown() then 
				Pointer.Config.lastNotificationTime = TMW.time
				-- Successful 
				Print(L.NOTIFICATION_TITLE)
				Print(L.ACTIONS_SUCCESSFUL)
			end 
		end 
		
		Pointer.Config.Locked = nil 
	end 
end 

local function UpdateAction(i)
	if i == 0 or i > MAX_ACTION_SLOTS or (not isClassic and (not A.IsOLDprofile or A_Unit("player"):GetSpellLastCast(GARRISON_SWITCH_SPECIALIZATIONS) > 0) and A_Unit("player"):GetSpellLastCast(GARRISON_SWITCH_SPECIALIZATIONS) < 0.5) then return end -- We don't need react on Target Possessed Action Bar or if we casted 'Change specialization'
	local Pointer = Lib.Data.Actions[A[owner]]
	if Pointer and not Pointer.Config.Locked then 	
		local actionSpellName, macroName, macroTexture, macroBody, macroBodyIsChanged
		local actionType, actionID, actionSubType = GetActionInfo(i)
		if actionID ~= 0 then 
			if actionType == "spell" and actionSubType == "pet" then 
				-- If it's spell we always can check range, no matter if spell known or learned
				actionSpellName = A_GetSpellInfo(actionID)
			elseif actionType == "macro" then 
				-- If it's macro we can check range only if spell learned 				
				macroName, macroTexture, macroBody = MacroLibrary:GetInfo(actionID, "ByActionMacros")
				if macroBody and macroBody:find("#showtooltip\n/cast " .. macroName) then 
					actionSpellName = macroName
					if macroName ~= Pointer.Buttons[i].spellName or (Lib:IsSpellKnown(macroName) and macroTexture == 134400) then 
						macroBodyIsChanged = true 
					end 
				else 
					macroBodyIsChanged = true 
				end 
			end 
		end
		
		-- Do nothing if no changes
		if Pointer.Buttons[i].type == actionType and Pointer.Buttons[i].id == actionID and Pointer.Buttons[i].subtype == actionSubType and not macroBodyIsChanged then 
			return 
		end 
		
		local previousSpellName 		= Pointer.Buttons[i].spellName	
		local previousType				= Pointer.Buttons[i].type
		Pointer.Buttons[i].button 		= i
		Pointer.Buttons[i].type 		= actionType
		Pointer.Buttons[i].id	 		= actionID			-- Only for UpdateAction(i) to compare with cache
		Pointer.Buttons[i].subtype 		= actionSubType		-- Only for UpdateAction(i) to compare with cache
		Pointer.Buttons[i].spellName 	= actionSpellName	
				
		if actionSpellName and Pointer.Spells[actionSpellName] then 			
			if actionType == "spell" then -- Note: Don't use Lib:IsSpellKnown at this line!
				Pointer.Buttons[i].valid 	= true
			elseif Lib:IsSpellKnown(actionSpellName) then 
				Pointer.Buttons[i].valid 	= true
			else 
				Pointer.Buttons[i].valid 	= nil 
			end 
		
			Pointer.Spells[actionSpellName] = Pointer.Buttons[i]
			if actionSubType == "spell" and Pointer.Config.delMacros and MacroLibrary:IsExists(actionSpellName) then 						
				MacroLibrary:DeleteMacro(actionSpellName)
			end 
		else 
			Pointer.Buttons[i].valid = nil 
		end 
		
		local isMissed
		if previousSpellName ~= actionSpellName and previousSpellName and Pointer.Spells[previousSpellName] then 
			Pointer.Spells[previousSpellName] = tSpellsEmpty
			isMissed = true 
			for j = 1, #Pointer.Buttons do 
				if Pointer.Buttons[j].spellName == previousSpellName then 				
					Pointer.Spells[previousSpellName] = Pointer.Buttons[j]
					isMissed = false 
					break 
				end 
			end 	
			
			-- Reset
			if isMissed then 
				Pointer.Spells[previousSpellName] = tSpellsEmpty
			end 
		end 
		
		if not Pointer.Config.useSilence then 
			if isMissed and (previousType == "spell" or Lib:IsSpellKnown(previousSpellName)) then
				-- Notify user if he trying to remove last one action which can be useable, if user has another copy of the action 'isMissed' will be false
				Print(L.NOTIFICATION_TITLE)
				Print("\n" .. A_GetSpellLink(previousSpellName) .. L.ADD_THIS_ON_ACTION_BAR)
			elseif Pointer.Buttons[i].valid then 
				-- If we added required action let's check and confirm what we don't need anything else 
				local notification
				for spellName in pairs(Pointer.Spells) do 
					if not Pointer.Spells[spellName].button and Lib:IsSpellKnown(spellName) then 	
						notification = (notification or "\n") .. A_GetSpellLink(spellName) .. L.ADD_THIS_ON_ACTION_BAR
					end 
				end 
				
				if macroBodyIsChanged then	
					Pointer.Buttons[i].subtype = "updateMacro"
					notification = (notification or "\n") .. A_GetSpellLink(Pointer.Buttons[i].spellName) .. L.ADD_THIS_ON_ACTION_BAR
				end 
				
				Print(L.NOTIFICATION_TITLE)				
				if notification then 
					-- Missed
					Print(L.FOLLOWING_IS_MISSED)					
					Print(notification)
				else 
					-- Successful 
					Print(L.ACTIONS_SUCCESSFUL)
				end 
			end 
		end 
	end 
end 

-------------------------------------------------------------------------------
-- Local - Trackers
-------------------------------------------------------------------------------
local IsKeyIsNotEraseAble = {
	count 	= true,
	id 		= true,
}; Lib.Data.IsKeyIsNotEraseAble = IsKeyIsNotEraseAble
local function CleanTrackersPetTable(tab)
	-- Note: Use only if count <= 0, means no active pets
	for k, v in pairs(tab) do 
		if not IsKeyIsNotEraseAble[k] and type(v) ~= "table" then 
			tab[k] = nil 
		end 
	end 
	wipe(tab.GUIDs)
end 

local function HasTrackersPetInCount()
	for k, v in pairs(Lib.Data.Trackers[A[owner]].PetIDs) do 
		if v.count > 0 then 
			return true 
		end 
	end 
end

local function OnTrackersCleanerUpdate(self, elapsed)
	self.TimeSinceLastUpdate = (self.TimeSinceLastUpdate or 0) + elapsed	
	if self.TimeSinceLastUpdate > 1 then 
		local Pointer = self.Trackers[A[owner]]
		
		if not Pointer then 
			self:SetScript("OnUpdate", nil)
		else 
			local petID, petData = next(Pointer.PetIDs) 
			
			if petID then 
				while petID ~= nil do 
					for petGUID, dataGUID in pairs(petData.GUIDs) do 
						if (dataGUID.expiration == huge and TMW.time - dataGUID.updated > 6) or dataGUID.expiration - TMW.time <= 0 then 
							Pointer.PetGUIDs[petGUID] 				= nil 	
							Pointer.PetIDs[petID].GUIDs[petGUID] 	= nil	
							Pointer.PetIDs[petID].count 			= max(Pointer.PetIDs[petID].count - 1, 0)
							if Pointer.PetIDs[petID].count <= 0 and not Pointer.Config.PreventCleanPetTable then 
								CleanTrackersPetTable(Pointer.PetIDs[petID])
							end	 
							
							TMW:Fire("TMW_ACTION_PET_LIBRARY_REMOVED", petID, petGUID, Pointer.PetIDs[petID])
						end 
					end 
					
					petID, petData = next(Pointer.PetIDs, petID)
				end 
			end 
			
			-- Stop unnecessary loop
			if not HasTrackersPetInCount() then 
				self:SetScript("OnUpdate", nil)
			end 	
		end 
		
		self.TimeSinceLastUpdate = 0
	end 	
end

local function WipeTrackers(callbackEvent, event)
	if event == "PLAYER_SPECIALIZATION_CHANGED" and (isClassic or ((not A.IsOLDprofile or A_Unit("player"):GetSpellLastCast(GARRISON_SWITCH_SPECIALIZATIONS) > 0) and A_Unit("player"):GetSpellLastCast(GARRISON_SWITCH_SPECIALIZATIONS) < 0.5)) then 
		for _, ownerData in pairs(Lib.Data.Trackers) do 
			for _, petData in pairs(ownerData.PetIDs) do 
				petData.count = 0
				for _, v in pairs(petData) do 
					if type(v) == "table" then 
						wipe(v)
					end 
				end
			end 
			wipe(ownerData.PetGUIDs)
		end 	
		Lib.TrackersCleaner:SetScript("OnUpdate", nil)
	end 
end 

-------------------------------------------------------------------------------
-- Local - Shared
-------------------------------------------------------------------------------
local function GetElementalDurationByPetID(petID)
	local Pointer = Lib.Data.Trackers[A[owner]]
	if Pointer and Pointer.Config[petID] and Pointer.Config[petID].duration then 
		return Pointer.Config[petID].duration
	end 
	
	if Lib.Data.TrackersConfigPetID[CONST.SHAMAN_ELEMENTAL or 262][petID] and Lib.Data.TrackersConfigPetID[CONST.SHAMAN_ELEMENTAL or 262][petID].duration then 
		return Lib.Data.TrackersConfigPetID[CONST.SHAMAN_ELEMENTAL or 262][petID].duration
	end 
	
	return huge
end 

local function UpdateFoodType(...)
	local n = select("#", ...)
	wipe(Lib.Food)
	
	if n > 0 then 
		for i = 1, n do 			
			Lib.Food[Lib:FormatFood((select(i, ...)))] = true 
		end 
	end 
end 

local function UpdateKnownSpells()
	local KnownSpells = Lib.Data.KnownSpells
	wipe(KnownSpells)
	
	local spellObj, spellName, spellID
	for i = 1, (HasPetSpells() or 0) do -- HasPetSpells() is nil if pet does not have spellbook	
		spellObj = GetSpellBookItemInfo(i, PET_BOOK) 
		if type(spellObj) == "table" then
			-- Retail
			spellName = spellObj.name
			spellID = spellObj.spellID
		else
			-- Classic+
			spellName, _, spellID = GetSpellBookItemName(i, PET_BOOK)
		end
		
		if spellName then 
			KnownSpells[spellName] = i 
		end 
		
		if spellID then 
			KnownSpells[spellID] = i 
		end 
	end
end 

local function SPELLS_CHANGED()	
	local cvar = GetCVar("spellBookHidePassives")
	SetCVar("spellBookHidePassives", "0")
	
	UpdateKnownSpells()
	if PetHasSpellbook() then
		UpdateActions()
	end

	SetCVar("spellBookHidePassives", cvar)
end
Listener:Add("ACTION_EVENT_PET_LIBRARY_ACTIONS", "SPELLS_CHANGED", SPELLS_CHANGED)

local function UpdateMainPet()
	UpdateFoodType(GetPetFoodTypes())		
	
	Lib.GUID  			= UnitGUID("pet")
	Lib.Name 			= UnitName("pet")	
	Lib.IsExists  		= A_Unit("pet"):IsExists()	
	
	if TeamCacheFriendlyUNITs.pet then 
		TeamCacheFriendlyGUIDs[TeamCacheFriendlyUNITs.pet] = nil 
		TeamCacheFriendlyUNITs.pet = nil 
	end 
	
	if Lib.IsExists and Lib.GUID then
		TeamCacheFriendlyGUIDs[Lib.GUID] = "pet"
		TeamCacheFriendlyUNITs.pet = Lib.GUID
		
		Lib.IsDead	  	= A_Unit("pet"):IsDead() -- Must be here because when pet frame gone this function will be fired
		Lib.Family		= A_Unit("pet"):CreatureFamily()
		Lib.Type		= A_Unit("pet"):CreatureType()
		Lib.ID			= select(6, A_Unit("pet"):InfoGUID(Lib.GUID))
		Lib.IsCallAble 	= true -- Pet tamed / summoned 
				
		if not isClassic and A.PlayerSpec == (CONST.SHAMAN_ELEMENTAL or 262) then 
			Lib.duration = GetElementalDurationByPetID(Lib.ID)
		else 
			Lib.duration = huge 
		end 
		
		Lib.start 		= TMW.time 
		Lib.expiration 	= TMW.time + Lib.duration		
		TMW:Fire("TMW_ACTION_PET_LIBRARY_MAIN_PET_UP")
	else 			
		Lib.IsAttacks	= nil 
		Lib.Family		= nil 
		Lib.Type		= nil 
		Lib.ID			= nil 
		
		--Lib.start 	= nil 
		Lib.duration	= nil 
		Lib.expiration	= nil 	
		TMW:Fire("TMW_ACTION_PET_LIBRARY_MAIN_PET_DOWN")	
	end 		
	
	-- Trackers
	-- "Removes" main pet from trackers if it was added by CLEU but leaves table exist to re-use it 
	if Lib.GUID then 
		local Pointer = Lib.Data.Trackers[A[owner]]
		if Pointer and Pointer.PetGUIDs[Lib.GUID] then  
			local petID 							= Pointer.PetGUIDs[Lib.GUID].id
			Pointer.PetGUIDs[Lib.GUID] 				= nil
			Pointer.PetIDs[petID].GUIDs[Lib.GUID] 	= nil	
			Pointer.PetIDs[petID].count 			= 0
			if not Pointer.Config.PreventCleanPetTable then 
				CleanTrackersPetTable(Pointer.PetIDs[petID])
			end
			
			-- Stop unnecessary loop
			if not HasTrackersPetInCount() then 
				Lib.TrackersCleaner:SetScript("OnUpdate", nil) 
			end

			TMW:Fire("TMW_ACTION_PET_LIBRARY_REMOVED", petID, Lib.GUID, Pointer.PetIDs[petID], true)	
		end 	
	end 
end 

local eventFiredCount = 0
local function UNIT_PET(unitID)	
	if unitID == "player" then
		eventFiredCount = eventFiredCount + 1
		
		-- On PLAYER_LOGIN
		if eventFiredCount == 1 then
			UpdateMainPet()
		end
		
		-- On RELOAD or UPDATE
		-- Event fired twice in a row, this code should prevent it and work as the clocks
		if eventFiredCount % 2 == 0 then
			-- On even tick when pet info is available
			UpdateMainPet()
		end
	end 
end 
Listener:Add("ACTION_EVENT_PET_LIBRARY_UNIT_PET", "UNIT_PET", UNIT_PET)

local GetMessageInfo 		 					= {
	[SPELL_FAILED_NO_PET or ""] 	 			= "NOCALLPET",
	[PETTAME_NOPETAVAILABLE or ""]				= "NOCALLPET",
	[ERR_PET_BROKEN or ""]	 					= "NOCALLPET", 	-- Fires when unhappy pet ran out from master
	[ERR_PET_SPELL_DEAD or ""] 					= "DEAD",
	[SPELL_FAILED_CUSTOM_ERROR_63  or ""]		= "DEAD", 		-- FIX ME: Is it necessary?
	[SPELL_FAILED_CUSTOM_ERROR_63_NONE or ""] 	= "DEAD", 		-- FIX ME: Is it necessary?
	[PETTAME_DEAD or ""]						= "DEAD",
	[PETTAME_NOTDEAD or ""]	 					= "NODEAD",	
}; Lib.Data.GetMessageInfo = GetMessageInfo
local function UI_ERROR_MESSAGE(...)
	local _, msg 	= ...
	local msgEvent 	= GetMessageInfo[msg]
	if msgEvent ~= "" then 
		if msgEvent == "NOCALLPET" then 
			Lib.IsCallAble  = false 
		elseif msgEvent == "DEAD" then
			Lib.IsCallAble  = true 
			Lib.IsDead 		= true 
		elseif msgEvent == "NODEAD" then 
			Lib.IsDead 		= false
		end 
	end 
end 
Listener:Add("ACTION_EVENT_PET_LIBRARY_UI_ERROR_MESSAGE", "UI_ERROR_MESSAGE", UI_ERROR_MESSAGE)

local GetEventCLEU			= {
	["UNIT_DIED"] 			= "DEAD",
	["UNIT_DESTROYED"] 		= "DEAD",
	["UNIT_DISSIPATES"] 	= "DEAD",		
	["PARTY_KILL"] 			= "DEAD",
	["SPELL_INSTAKILL"] 	= "DEAD",
	["SPELL_DAMAGE"]		= "ZOMBIE_DEAD",
	["SPELL_SUMMON"] 		= "SUMMON",	
}; Lib.Data.GetEventCLEU = GetEventCLEU
local function COMBAT_LOG_EVENT_UNFILTERED(...)
	local _, Event, _, SourceGUID, _, _, _, DestGUID, DestName, _, _, arg12, arg13 = CombatLogGetCurrentEventInfo()	
	local EventCLEU = GetEventCLEU[Event]
	
	-- Shared 
	if EventCLEU == "DEAD" and DestGUID == Lib.GUID then 
		UpdateMainPet()
		Lib.IsCallAble  = true 
		Lib.IsDead 		= true 
	end 
	
	-- Trackers
	local Pointer = Lib.Data.Trackers[A[owner]]
	if Pointer then
		if EventCLEU == "DEAD" or (not isClassic and EventCLEU == "ZOMBIE_DEAD" and A.PlayerSpec == (CONST.DEATHKNIGHT_UNHOLY or 252)) then 			
			if DestGUID and Pointer.PetGUIDs[DestGUID] then 
				local petID = Pointer.PetGUIDs[DestGUID].id						
				
				if Pointer.PetIDs[petID] then	
					Pointer.PetGUIDs[DestGUID] 					= nil 
					Pointer.PetIDs[petID].GUIDs[DestGUID]		= nil 
					Pointer.PetIDs[petID].count 				= max(Pointer.PetIDs[petID].count - 1, 0)
					if Pointer.PetIDs[petID].count <= 0 and not Pointer.Config.PreventCleanPetTable then 
						CleanTrackersPetTable(Pointer.PetIDs[petID])
					end
					
					TMW:Fire("TMW_ACTION_PET_LIBRARY_REMOVED", petID, DestGUID, Pointer.PetIDs[petID])	
				else 
					Pointer.PetGUIDs[DestGUID].GUIDs[DestGUID]	= nil 
					Pointer.PetGUIDs[DestGUID].count 			= max(Pointer.PetGUIDs[DestGUID].count - 1, 0)
					if Pointer.PetGUIDs[DestGUID].count <= 0 and not Pointer.Config.PreventCleanPetTable then 
						CleanTrackersPetTable(Pointer.PetGUIDs[DestGUID])
					end
					Pointer.PetGUIDs[DestGUID] 					= nil 
					
					if not Pointer.Config.HideErrors then 
						error("[PetLibrary] CLEU couldn't find petID from guid: " .. DestGUID .. " name (" .. DestName .. ")")
					end 
					
					TMW:Fire("TMW_ACTION_PET_LIBRARY_REMOVED", petID, DestGUID, Pointer.PetGUIDs[DestGUID])	
				end 								
				
				-- Stop unnecessary loop
				if not HasTrackersPetInCount() then 
					Lib.TrackersCleaner:SetScript("OnUpdate", nil)
				end 
			end 
		elseif EventCLEU == "SUMMON" then 
			if SourceGUID and SourceGUID == (TeamCacheFriendlyUNITs.player or UnitGUID("player")) and DestGUID ~= Lib.GUID then
				local petID = select(6, A_Unit(""):InfoGUID(DestGUID))
				if petID and petID ~= Lib.ID then 
					if not Pointer.PetIDs[petID] then 
						Pointer.PetIDs[petID] = { GUIDs = {} }
					end 
					
					Pointer.PetIDs[petID].id 				= petID
					Pointer.PetIDs[petID].name 				= Pointer.Config[petID] and Pointer.Config[petID].name 		or DestName
					Pointer.PetIDs[petID].realName			= DestName
					Pointer.PetIDs[petID].duration 			= Pointer.Config[petID] and Pointer.Config[petID].duration 	or huge
					Pointer.PetIDs[petID].count 			= (Pointer.PetIDs[petID].count or 0) + 1
					Pointer.PetIDs[petID].GUIDs[DestGUID] 	= {
						updated			= TMW.time, 
						start 			= TMW.time, 
						expiration		= TMW.time + Pointer.PetIDs[petID].duration,
					}
					tMerge(Pointer.PetIDs[petID], Pointer.Config[petID], true)
					
					Pointer.PetGUIDs[DestGUID]				= Pointer.PetIDs[petID]
					if Lib.TrackersCleaner:GetScript("OnUpdate") == nil then 
						Lib.TrackersCleaner:SetScript("OnUpdate", OnTrackersCleanerUpdate)
					end 
					
					TMW:Fire("TMW_ACTION_PET_LIBRARY_ADDED", petID, DestGUID, Pointer.PetIDs[petID])
				end 
			end 
		else
			if SourceGUID and Pointer.PetGUIDs[SourceGUID] and Pointer.PetGUIDs[SourceGUID].GUIDs[SourceGUID] then 
				Pointer.PetGUIDs[SourceGUID].GUIDs[SourceGUID].updated = TMW.time 
			end 
			
			if DestGUID and Pointer.PetGUIDs[DestGUID] and Pointer.PetGUIDs[DestGUID].GUIDs[DestGUID] then 
				Pointer.PetGUIDs[DestGUID].GUIDs[DestGUID].updated = TMW.time 
			end 
		end 
	end 
end 
Listener:Add("ACTION_EVENT_PET_LIBRARY_CLEU", 	"COMBAT_LOG_EVENT_UNFILTERED", COMBAT_LOG_EVENT_UNFILTERED)
Listener:Add("ACTION_EVENT_PET_LIBRARY_ATTACK", "PET_ATTACK_START", function() Lib.IsAttacks = true  end)
Listener:Add("ACTION_EVENT_PET_LIBRARY_ATTACK", "PET_ATTACK_STOP", 	function() Lib.IsAttacks = false end)

-------------------------------------------------------------------------------
-- API - Actions
-------------------------------------------------------------------------------
-- This API - Action must be initializated through call Lib:AddActionsSpells
function Lib:SetActionsConfig(owner, useManagement, useSilence, delMacros)
	if self.Data.Actions[owner] then 
		self.Data.Actions[owner].Config.useManagement			 = useManagement
		self.Data.Actions[owner].Config.useSilence				 = useSilence
		self.Data.Actions[owner].Config.delMacros				 = delMacros
		self.Data.Actions[owner].Config.lastNotificationTime	 = 0
	end 
end 

function Lib:AddActionsSpells(owner, spells, useManagement, useSilence, delMacros)
	-- @usage:	 Lib:AddActionsSpells(owner, spells[, useManagement, useSilence, delMacros])
	-- Classic:  Lib:AddActionsSpells(@string, @table, @boolean, @boolean, @boolean), example Lib:AddActionsSpells(A.PlayerClass, { A.PetSpell1, A.PetSpell2.ID, (A.PetSpell3:Info()) }, true)
	-- Retail: 	 Lib:AddActionsSpells(@number, @table, @boolean, @boolean, @boolean), example Lib:AddActionsSpells(A.PlayerSpec,  { A.PetSpell1, A.PetSpell2.ID, (A.PetSpell3:Info()) }, true)
	-- owner is class (Classic) or specialization (Retail)
	-- spells is array table which accepts object-table, spellID, spellName
	-- useManagement is boolean indicated to control action panel by petaction or macro buttons 
	-- useSilence is boolean if 'true' will turns off print notifications about missed actions
	-- AddActionsSpells is boolean if 'true' will delete macros (with action slot) if spell is found on action panel as 'petaction'
	-- Notes:
	-- Notifications will be printed always when player changes spec or summon main pet for all missed actions, otherwise only per slot changed action 
	-- NEVER CALL THIS FUNCTION BEFORE ACTION INITIALIZATION! Otherwise upvalues will not be properly functional
	if not Lib.Data.isInitializedAddon then 
		error("PetLibrary too early called AddActionsSpells function. You have to call this only AFTER db initialization!")
		return 
	end 
	
	if not self.Data.Actions[owner] then 
		self.Data.Actions[owner] 		= {			
			Config				 		= {
				useManagement 		 	= useManagement,
				useSilence			 	= useSilence,
				delMacros				= delMacros,
				lastNotificationTime 	= 0,				
			},
			Spells 				 		= {},
			Buttons  			 		= {},
		}
		
		for i = 1, MAX_ACTION_SLOTS do 
			self.Data.Actions[owner].Buttons[i] = {}
		end 
	else 
		self:SetActionsConfig(owner, useManagement, useSilence, delMacros)
	end 
	
	for i = 1, #spells do	
		self.Data.Actions[owner].Spells[GetSpellName(spells[i])] = tSpellsEmpty
	end 		
	
	-- Forced to get actual CL for notifications
	A.GetLocalization()
	
	-- Register events
	Listener:Add("ACTION_EVENT_PET_LIBRARY_ACTIONS", "ACTIONBAR_SLOT_CHANGED",  		UpdateAction													)
	TMW:RegisterCallback("TMW_ACTION_SPELL_BOOK_CHANGED", 								UpdateActions, 		"TMW_PET_LIBRARY_SPELL_BOOK_CHANGED_ACTIONS")
end

function Lib:RemoveActionsSpells(owner, spells)
	-- @usage simular with Lib:AddActionsSpells just without Config atributtes at the end
	if self.Data.Actions[owner] then 
		for i = 1, #spells do 
			self.Data.Actions[owner].Spells[GetSpellName(spells[i])] = nil 
		end 
		
		if not next(self.Data.Actions[owner].Spells) then 
			self.Data.Actions[owner] = nil 
		end 
	else 
		return 
	end 
	
	local hasActiveSpells = false 
	for owner, data in pairs(self.Data.Actions) do 
		if next(data.Spells) then 
			hasActiveSpells = true 
			break 
		end 
	end 
	
	if not hasActiveSpells then 
		Listener:Remove("ACTION_EVENT_PET_LIBRARY_ACTIONS", "ACTIONBAR_SLOT_CHANGED"																	)
		TMW:UnregisterCallback("TMW_ACTION_SPELL_BOOK_CHANGED", 						UpdateActions, 		"TMW_PET_LIBRARY_SPELL_BOOK_CHANGED_ACTIONS")
	else 
		UpdateActions()
	end 
end 

function Lib:IsInRange(spell, unitID)
	-- @return 	boolean
	-- @usage	Lib:IsInRange(@table (array/object-action) or @spellID or @spellName[, @string])
	-- Note: This function doesn't check if pet alive, exists!
	local Pointer = self.Data.Actions[A[owner]]
	if Pointer then 
		local action 
		if type(spell) == "table" and not spell.ID then -- not spell.ID indicated to non object-action table 
			for i = 1, #spell do
				action = Pointer.Spells[GetSpellName(spell[i])]
				if action and action.valid and action.button and IsActionInRange(action.button, unitID or "target") then
					return true
				end
			end
		else 
			action = Pointer.Spells[GetSpellName(spell)]
			return action and action.valid and action.button and IsActionInRange(action.button, unitID or "target")
		end 
	end 
end 

function Lib:GetInRange(spell, stop)
	-- @return number 
	-- @usage  Lib:GetInRange(@table (array/object-action) or @spellID or @spellName[, @number])
	-- Returns number of total units in range by 'spell', if 'stop' is nil then will take all possible units
	-- Note: This function doesn't check if pet alive, exists!
	local total = 0 
	for unitID in pairs(ActiveNameplates) do
		if self:IsInRange(spell, unitID) then 
			total = total + 1                                            
		end  
		
		if stop and total >= stop then
			break                        
		end     
	end 
	
    return total 
end

function Lib:GetActionButton(spell)
	-- @return 	number or nil 
	-- @usage 	Lib:GetActionButton(@table object-action or @spellID or @spellName)
	local Pointer = self.Data.Actions[A[owner]]
	return Pointer and Pointer.Spells[GetSpellName(spell)] and Pointer.Spells[GetSpellName(spell)].button
end 

-------------------------------------------------------------------------------
-- API - Trackers
-------------------------------------------------------------------------------
-- This API - Action must be initializated through call Lib:AddTrackers
function Lib:AddTrackers(owner, customConfig)
	-- @usage:	 Lib:AddTrackers(owner[, customConfig])
	-- Classic:  Lib:AddTrackers(@string[, @table]), example Lib:AddTrackers(A.PlayerClass)
	-- Retail: 	 Lib:AddTrackers(@number[, @table]), example Lib:AddTrackers(A.PlayerSpec, Lib.Data.TrackersConfigPetID[A.PlayerSpec])
	-- owner is class (Classic) or specialization (Retail)
	-- customConfig structure:
	-- {
	--		PreventCleanPetTable	= false,
	--		HideErrors				= false,
	-- 		[petID] = {
	--			-- your key = value here that will be merged into Lib.Data.Trackers[owner].PetIDs[PetID] when new pet summons 
	--		},
	-- }
	if not self.Data.Trackers[owner] then 
		self.Data.Trackers[owner] 		= {	
			Config 						= tMerge(tMerge({}, self.Data.TrackersConfigPetID[owner]), customConfig),
			PetIDs 						= {},
			PetGUIDs					= {},
		}
	else
		tMerge(self.Data.Trackers[owner].Config, customConfig)
	end 
	
	-- Register events 
	if not isClassic and not self.isInitializedTrackers then 
		TMW:RegisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED",  WipeTrackers)
		self.isInitializedTrackers = true
	end 
end 

function Lib:RemoveTrackers(owner)
	-- @usage simular with Lib:AddTrackers just without Config atributtes at the end
	self.Data.Trackers[owner] = nil 
	if self.isInitializedTrackers and not next(self.Data.Trackers) then 
		TMW:UnregisterCallback("TMW_ACTION_PLAYER_SPECIALIZATION_CHANGED",  WipeTrackers)
		self.isInitializedTrackers = false 
	end 
end 

-------------------------------------------------------------------------------
-- API - Shared
-------------------------------------------------------------------------------
-- This API - Shared works without initialization
function Lib:FormatFood(foodName)
	-- @return string or nil 
	-- Returns formated to English 'foodName'
	return self.Data.FoodTypes[foodName]
end 

function Lib:CanEatFood(foodName)
	-- @return boolean 
	-- Returns true if pet can eat 'foodName' (argument can be localized by locale, it will be formated)
	local name = self.Data.FoodTypes[foodName] or foodName
	return name and self.Food[name] 
end 

function Lib:CanCall()
	-- @return boolean 
	-- Note: Usage only on Hunter at the moment 
	return self.IsCallAble and not self.IsDead and not self.IsExists
end 

function Lib:IsActive(pet, skipIsDead)
	-- @return boolean 
	-- @usage: Lib:GetRemainDuration([petID|petName][, skipIsDead])
	-- Note: skipIsDead viable only for main pet 
	
	-- Main pet 
	if (not pet or self.ID == pet or self.Name == pet) and self.IsExists and (skipIsDead or not self.IsDead) then 
		return true 
	end 
	
	-- Trackers API
	if pet then
		return self:GetCount(pet) > 0
	end 
end 

function Lib:IsAttacking(unitID)
	-- @return boolean 
	return self.IsAttacks and A_Unit("pettarget"):IsExists() and (not unitID or UnitIsUnit("pettarget", unitID))
end 

function Lib:IsBehind(x)
	-- @return boolean 
	-- Note: Returns true if pet is behind the target since x seconds taken from the last ui message 
	return A_Player:IsPetBehind(x)
end

function Lib:IsBehindTime()
	-- @return number
	-- Note: Returns time since pet behind the target	
	return A_Player:IsPetBehindTime()
end

function Lib:IsSpellKnown(spell)
	-- @return boolean 
	-- usage: Lib:IsSpellKnown(@table object-action, @string, @number)
	-- 'spell' accepts spellName, spellID and Action.Object
	-- Note: Pet must be active i.e. exists and alive to have it working
	if C_SpellBook and C_SpellBook.GetSpellBookItemInfo then 
		return self.Data.KnownSpells[GetSpellName(spell)] and true 
	else 
		return GetSpellBookItemInfo(GetSpellName(spell)) and true -- DON'T TOUCH THIS AS WHILE ITS STILL AVAILABLE ON CLASSIC+ IT CAN CHECK IN REAL-TIME IF NOT SPECIFIED SECOND ARGUMENT
	end 
	-- Only this function is best way to check if spell known so far 
end 

function Lib:GetRemainDuration(pet)
	-- @return number, number, number
	-- @usage: Lib:GetRemainDuration([petID|petName])
	-- Returns lowest, averange, highest of the remain durations 	
	
	local duration
	-- Main pet	
	if not pet or self.ID == pet or self.Name == pet then 
		if self.expiration then 
			duration = max(self.expiration - TMW.time, 0)
			return duration, duration, duration
		end 
	end 
	
	-- Trackers API
	if pet and self.Data.Trackers[A[owner]] then 
		local lowest, highest, total, count = 0, 0, 0, 0
		for _, petData in pairs(self.Data.Trackers[A[owner]].PetIDs) do 
			if petData.id == pet or petData.name == pet then 
				for _, dataGUID in pairs(petData.GUIDs) do 
					duration = max(dataGUID.expiration - TMW.time, 0)
					if duration > 0 then 
						count = count + 1
						total = total + duration
						
						if duration < lowest or lowest == 0 then 
							lowest = duration
						end 
						
						if duration > highest or highest == 0 then 
							highest = duration
						end 
					end 
				end 
			end 
		end 
		
		if count > 0 then 
			return lowest, total / count, highest
		end 
	end  
	
	return 0, 0, 0
end 

function Lib:GetCount(pet)
	-- @return number 
	-- @usage Lib:GetCount(petID|petName)
	if not pet then 
		return 0 
	end 
	
	-- Trackers API 
	if self.Data.Trackers[A[owner]] then 
		local count = 0
		for _, petData in pairs(self.Data.Trackers[A[owner]].PetIDs) do 
			if petData.id == pet or petData.name == pet then 
				count = count + petData.count
			end 
		end 
		
		if count > 0 then 
			return count 
		end 
	end  
	
	-- Main pet 
	if (self.ID == pet or self.Name == pet) and self.IsExists and not self.IsDead then 
		return 1
	end 
	
	return 0
end 

function Lib:GetRange()
	-- @return number 
	-- Returns range in yards to the pet 
	return A_Unit("pet"):GetRange() 
end 

function Lib:GetRangeBetweenTarget()
	-- @return number 
	-- Returns range in yards between pet and his 'pettarget', otherwise returns 'huge' if no attacking
	if self:IsAttacking() then 
		return max(A_Unit("pettarget"):GetRange() - self:GetRange(), 0)
	else 
		return huge
	end 
end 

function Lib:GetTimeToRangeBetweenTarget(yards)
	-- @return number 
	-- Returns time in seconds to get in 'yards' (or 5 yards which is melee) between pet and his target, otherwise returns 'huge'
	local currentSpeed 	= GetUnitSpeed("pet")
	if currentSpeed then 
		return max((self:GetRangeBetweenTarget() - (yards or 5))  / currentSpeed, 0)
	else 
		return huge 
	end 
end 

function Lib:DisableErrors(state)
	-- @usage true / false
	-- Actions API
	for _, data in pairs(self.Data.Actions) do  
		data.Config.useSilence = state
	end 
	
	-- Trackers API
	for _, data in pairs(self.Data.Trackers) do  
		data.Config.HideErrors = state
	end 
end 