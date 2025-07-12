local _G, math, pairs, type, select, setmetatable	= _G, math, pairs, type, select, setmetatable
local huge 											= math.huge

local TMW 											= _G.TMW 
local CNDT 											= TMW.CNDT
local Env 											= CNDT.Env

local A   											= _G.Action	
local CONST 										= A.Const
local A_Hide 										= A.Hide
local Create 										= A.Create
local GetToggle										= A.GetToggle
local AuraIsValid									= A.AuraIsValid
local IsQueueReady									= A.IsQueueReady
local QueueData										= A.Data.Q
local ShouldStop									= A.ShouldStop
local GetCurrentGCD									= A.GetCurrentGCD
local GetPing										= A.GetPing
local BuildToC										= A.BuildToC
local DetermineUsableObject							= A.DetermineUsableObject

local Re 											= A.Re
local BossMods										= A.BossMods
local IsUnitEnemy									= A.IsUnitEnemy
local Unit											= A.Unit 
local Player										= A.Player 
local LoC 											= A.LossOfControl
local MultiUnits									= A.MultiUnits

local LoC_GetExtra									= LoC.GetExtra
local CONST_PAUSECHECKS_DISABLED 					= CONST.PAUSECHECKS_DISABLED
local CONST_PAUSECHECKS_DEAD_OR_GHOST				= CONST.PAUSECHECKS_DEAD_OR_GHOST
local CONST_PAUSECHECKS_IS_MOUNTED 					= CONST.PAUSECHECKS_IS_MOUNTED
local CONST_PAUSECHECKS_WAITING 					= CONST.PAUSECHECKS_WAITING
local CONST_PAUSECHECKS_SPELL_IS_TARGETING			= CONST.PAUSECHECKS_SPELL_IS_TARGETING
local CONST_PAUSECHECKS_LOOTFRAME 					= CONST.PAUSECHECKS_LOOTFRAME
local CONST_PAUSECHECKS_IS_EAT_OR_DRINK 			= CONST.PAUSECHECKS_IS_EAT_OR_DRINK
local CONST_AUTOTARGET 								= CONST.AUTOTARGET
local CONST_AUTOSHOOT 								= CONST.AUTOSHOOT
local CONST_AUTOATTACK 								= CONST.AUTOATTACK
local CONST_LEFT 									= CONST.LEFT
local CONST_RIGHT									= CONST.RIGHT

local Pet											= _G.LibStub("PetLibrary")
local UnitBuff										= _G.UnitBuff
local UnitIsUnit  									= _G.UnitIsUnit
local UnitIsFriend									= _G.UnitIsFriend

local GetSpellName 									= _G.C_Spell and _G.C_Spell.GetSpellName or _G.GetSpellInfo
local GetCurrentKeyBoardFocus						= _G.GetCurrentKeyBoardFocus
local SpellIsTargeting								= _G.SpellIsTargeting
local IsMouseButtonDown								= _G.IsMouseButtonDown
--local IsPlayerAttacking							= _G.IsPlayerAttacking
local HasWandEquipped								= _G.HasWandEquipped
local HasFullControl								= _G.HasFullControl

local BINDPAD 										= _G.BindPadFrame

local ClassPortaits 								= {
	["WARRIOR"] 									= CONST.PORTRAIT_WARRIOR,
	["PALADIN"] 									= CONST.PORTRAIT_PALADIN,
	["HUNTER"] 										= CONST.PORTRAIT_HUNTER,
	["ROGUE"] 										= CONST.PORTRAIT_ROGUE,
	["PRIEST"] 										= CONST.PORTRAIT_PRIEST,
	["SHAMAN"]	 									= CONST.PORTRAIT_SHAMAN, 		-- Custom because it making conflict with Bloodlust
	["MAGE"] 										= CONST.PORTRAIT_MAGE,
	["WARLOCK"] 									= CONST.PORTRAIT_WARLOCK,
	["DRUID"] 										= CONST.PORTRAIT_DRUID,
	["DEATHKNIGHT"] 								= CONST.PORTRAIT_DEATHKNIGHT,
}

local GetKeyByRace 									= {
	-- I use this to check if we have created for spec needed spell 
	NightElf 										= "Shadowmeld",
	Human 											= "Perception",
	Gnome 											= "EscapeArtist",
	Dwarf 											= "Stoneform",
	Scourge 										= "WilloftheForsaken",
	Troll 											= "Berserking",
	Tauren 											= "WarStomp",
	Orc 											= "BloodFury",
}

local playerClass									= A.PlayerClass
local player										= "player"
local target 										= "target"
local mouseover										= "mouseover"
local targettarget									= "targettarget"

-------------------------------------------------------------------------------
-- Conditions
-------------------------------------------------------------------------------
local FoodAndDrink 									= {	
	[GetSpellName(587) or ""]						= true, -- Conjure Food 
	[GetSpellName(18233)] 							= true,	-- Food
	[GetSpellName(1131) or ""] 						= true,	-- Food
	[GetSpellName(22734)] 							= true, -- Drink
	[GetSpellName(34291) or ""]						= true, -- Drink
	[GetSpellName(29029)] 							= true,	-- Fizzy Energy Drink
	[GetSpellName(18140)] 							= true,	-- Blessed Sunfruit Juice
	[GetSpellName(23698)] 							= true,	-- Alterac Spring Water
	[GetSpellName(23692)] 							= true,	-- Alterac Manna Biscuit
	[GetSpellName(24410)] 							= true,	-- Arathi Basin Iron Ration
	[GetSpellName(24411)] 							= true,	-- Arathi Basin Enriched Ration 
	[GetSpellName(25990)] 							= true, -- Graccu's Mince Meat Fruitcake	
	[GetSpellName(18124)] 							= true, -- Blessed Sunfruit
	[GetSpellName(24384)] 							= true,	-- Essence Mango
	[GetSpellName(26263)] 							= true,	-- Dim Sum (doesn't triggers Food and Drink)
	[GetSpellName(26030)] 							= true,	-- Windblossom Berries (doesn't triggers Food and Drink)
	[GetSpellName(25691)] 							= true, -- Brain Food (unknown what does it exactly trigger)
	[GetSpellName(746)] 							= true,	-- First Aid
}
local FoodAndDrinkBlacklist 						= {
	[GetSpellName(396092) or ""]					= true, -- Well Fed
}
local function IsDrinkingOrEating()
	-- @return boolean 
	local auraName
	for i = 1, huge do 
		auraName = UnitBuff(player, i, "HELPFUL")
		if not auraName then 
			break 
		elseif FoodAndDrink[auraName] and not FoodAndDrinkBlacklist[auraName] then 
			return true 
		end 
	end 
end 

local function PauseChecks()  	
	if not TMW.Locked or GetCurrentKeyBoardFocus() ~= nil or (BINDPAD and BINDPAD:IsVisible()) then 
		return CONST_PAUSECHECKS_DISABLED
	end 
	
	if 	(GetToggle(1, "CheckDeadOrGhost") and Unit(player):IsDead()) or 
		(
			GetToggle(1, "CheckDeadOrGhostTarget") and 
			(
				(Unit(target):IsDead() and not UnitIsFriend(player, target) and (not A.IsInPvP or Unit(target):Class() ~= "HUNTER")) or 
				(GetToggle(2, mouseover) and Unit(mouseover):IsDead() and not UnitIsFriend(player, mouseover) and (not A.IsInPvP or Unit(mouseover):Class() ~= "HUNTER"))
			)
		) 
	then 																																																										-- exception in PvP Hunter 
		return CONST_PAUSECHECKS_DEAD_OR_GHOST
	end 	
	
	if GetToggle(1, "CheckMount") and Player:IsMounted() then 																																												-- exception Divine Steed and combat mounted auras
		return CONST_PAUSECHECKS_IS_MOUNTED
	end 

	if GetToggle(1, "CheckCombat") and Unit(player):CombatTime() == 0 and Unit(target):CombatTime() == 0 and not Player:IsStealthed() and BossMods:GetPullTimer() == 0 then 																		-- exception Stealthed and DBM pulling event 
		return CONST_PAUSECHECKS_WAITING
	end 	
	
	if GetToggle(1, "CheckSpellIsTargeting") and SpellIsTargeting() and (playerClass ~= "ROGUE" or Player:IsMoving() or Unit(player):CombatTime() ~= 0) then																				-- exception Classic Rogue only ue mechanic of poison enchants
		return CONST_PAUSECHECKS_SPELL_IS_TARGETING
	end	
	
	if GetToggle(1, "CheckLootFrame") and _G.LootFrame:IsShown() then
		return CONST_PAUSECHECKS_LOOTFRAME
	end	
	
	if GetToggle(1, "CheckEatingOrDrinking") and Player:IsStaying() and Unit(player):CombatTime() == 0 and IsDrinkingOrEating() then
		return CONST_PAUSECHECKS_IS_EAT_OR_DRINK
	end	
end
PauseChecks 						= A.MakeFunctionCachedStatic(PauseChecks)
A.PauseChecks 						= PauseChecks

local GetMetaType = setmetatable({}, { __index = function(t, v)
	local istype = type(v)
	t[v] = istype	
	return istype
end })

local Temp = {
	LivingActionPotionIsMissed		= {"INCAPACITATE", "DISORIENT", "FREEZE", "POSSESS", "SAP", "CYCLONE", "BANISH", "PACIFYSILENCE", "POLYMORPH", "SLEEP", "SHACKLE_UNDEAD", "FEAR", "HORROR", "CHARM", "TURN_UNDEAD"},
}
local TempLivingActionPotionIsMissed = Temp.LivingActionPotionIsMissed

-------------------------------------------------------------------------------
-- API
-------------------------------------------------------------------------------
A.AntiFakeWhite					 	= Create({ Type = "SpellSingleColor", 	ID = 1,		Color = "WHITE",     															  Hidden = true         		   								})
A.Trinket1 							= Create({ Type = "TrinketBySlot", 		ID = CONST.INVSLOT_TRINKET1,	 				BlockForbidden = true, Desc = "Upper Trinket (/use 13)"														})
A.Trinket2 							= Create({ Type = "TrinketBySlot", 		ID = CONST.INVSLOT_TRINKET2, 					BlockForbidden = true, Desc = "Lower Trinket (/use 14)" 													})
A.Shoot								= Create({ Type = "Spell", 				ID = 5019, 										QueueForbidden = true, BlockForbidden = true, Hidden = true,  Desc = "Wand" 								})
A.AutoShot							= Create({ Type = "Spell", 				ID = 75, 										QueueForbidden = true, BlockForbidden = true, Hidden = true,  Desc = "Hunter's shoot" 						})
A.HSFel1							= Create({ Type = "Item", 				ID = 36894, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSFel2							= Create({ Type = "Item", 				ID = 36893, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSFel3							= Create({ Type = "Item", 				ID = 36894, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSGreater1						= Create({ Type = "Item", 				ID = 5510, 										QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSGreater2						= Create({ Type = "Item", 				ID = 19010, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSGreater3						= Create({ Type = "Item", 				ID = 19011, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HS1								= Create({ Type = "Item", 				ID = 5509, 										QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HS2								= Create({ Type = "Item", 				ID = 19008, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HS3								= Create({ Type = "Item", 				ID = 19009, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSLesser1							= Create({ Type = "Item", 				ID = 5511, 										QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSLesser2							= Create({ Type = "Item", 				ID = 19006, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSLesser3							= Create({ Type = "Item", 				ID = 19007, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSMajor1							= Create({ Type = "Item", 				ID = 9421, 										QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSMajor2							= Create({ Type = "Item", 				ID = 19012, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSMajor3							= Create({ Type = "Item", 				ID = 19013, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSMinor1							= Create({ Type = "Item", 				ID = 5512, 										QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSMinor2							= Create({ Type = "Item", 				ID = 19004, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.HSMinor3							= Create({ Type = "Item", 				ID = 19005, 									QueueForbidden = true, Desc = "[6] HealthStone" 															})
A.DarkRune							= Create({ Type = "Item", 				ID = 20520, Texture = 134417,																				  Desc = "[3,4,6] Runes" 						})
A.DemonicRune						= Create({ Type = "Item", 				ID = 12662, Texture = 134417,																				  Desc = "[3,4,6] Runes" 						})
A.LimitedInvulnerabilityPotion		= Create({ Type = "Potion", 			ID = 3387																																					})
A.LivingActionPotion				= Create({ Type = "Potion", 			ID = 20008																																					})
A.RestorativePotion					= Create({ Type = "Potion", 			ID = 9030																																					})
A.SwiftnessPotion					= Create({ Type = "Potion", 			ID = 2459																																					}) -- is situational too much and better make own conditions inside each profile depends on class and situation 
A.MinorHealingPotion				= Create({ Type = "Potion", 			ID = 118																																					})
A.LesserHealingPotion				= Create({ Type = "Potion", 			ID = 858																																					})
A.HealingPotion						= Create({ Type = "Potion", 			ID = 929																																					})
A.GreaterHealingPotion				= Create({ Type = "Potion", 			ID = 1710																																					})
A.SuperiorHealingPotion				= Create({ Type = "Potion", 			ID = 3928																																					})
A.MajorHealingPotion				= Create({ Type = "Potion", 			ID = 13446																																					})

local function IsShoot(unit)
	return 	playerClass ~= "WARRIOR" and playerClass ~= "ROGUE" and 		-- their shot must be in profile 
			GetToggle(1, "AutoShoot") and not Player:IsShooting() and  
			(
				(playerClass == "HUNTER" and A.AutoShot:IsReadyP(unit)) or 	-- :IsReady also checks ammo amount by :IsUsable method
				(playerClass ~= "HUNTER" and HasWandEquipped() and A.Shoot:IsInRange(unit) and GetCurrentGCD() <= GetPing() and (not GetToggle(1, "AutoAttack") or not Player:IsAttacking() or Unit(unit):GetRange() > 6))
			)
end 

-- [[ It does set texture inside own return, so the return after this function "then" must be "return true" to keep icon shown ]]
-- Custom Toggles: "Stoneform", "Runes"
function A.CanUseStoneformDefense(icon)
	-- @return boolean or nil 
	-- Note: Requires in ProfileUI [2] configured toggle "Stoneform". "P" attribute  
	if A.PlayerRace == "Dwarf" then 
		local Stoneform = GetToggle(2, "Stoneform")
		if Stoneform and Stoneform >= 0 and A[playerClass].Stoneform:IsRacialReadyP(player) and 
			(
				-- Auto 
				( 	
					Stoneform >= 100 and 
					(
						(
							not A.IsInPvP and 						
							Unit(player):TimeToDieX(45) < 4 
						) or 
						(
							A.IsInPvP and 
							(
								Unit(player):UseDeff() or 
								(
									Unit(player, 5):HasFlags() and 
									Unit(player):GetRealTimeDMG() > 0 and 
									Unit(player):IsFocused() 								
								)
							)
						)
					) 
				) or 
				-- Custom
				(	
					Stoneform < 100 and 
					Unit(player):HealthPercent() <= Stoneform
				)
			) 
		then 
			return A[playerClass].Stoneform:Show(icon)
		end 	
	end
end 

function A.CanUseStoneformDispel(icon, toggle)
	-- @return boolean or nil 
	-- Note: Requires toggles or data from UI tab "Auras"
	local str_toggle = toggle
	if not str_toggle then 
		str_toggle = true 
	end 
	if A.PlayerRace == "Dwarf" and A[playerClass].Stoneform:IsRacialReady(player, true) and (AuraIsValid(player, str_toggle, "Poison") or AuraIsValid(player, str_toggle, "Bleed") or AuraIsValid(player, str_toggle, "Disease")) then 
		return A[playerClass].Stoneform:Show(icon)
	end 	
end 

function A.CanUseManaRune(icon)
	-- @return boolean or nil 
	-- Note: Requires in ProfileUI [2] configured toggle "Runes"
	if Unit(player):PowerType() == "MANA" and not ShouldStop() then 
		local Runes = GetToggle(2, "Runes") 
		if Runes > 0 and Unit(player):Health() > 1100 then 
			local Rune = DetermineUsableObject(player, true, nil, true, nil, A.DarkRune, A.DemonicRune)
			if Rune then 			
				if Runes >= 100 then -- AUTO 
					if Unit(player):PowerPercent() <= 20 then 
						return Rune:Show(icon)	
					end 
				elseif Unit(player):PowerPercent() <= Runes then 
					return Rune:Show(icon)								 
				end 
			end 
		end 
	end 
end 

function A.CanUseHealingPotion(icon)
	-- @return boolean or nil
	local Healthstone = GetToggle(1, "HealthStone")  
	if Healthstone >= 0 and (BuildToC < 110000 or A.ZoneID ~= 1684 or Unit(player):HasDeBuffs(320102) == 0) then -- Retail: Theater of Pain zone excluding "Blood and Glory" debuff 
		local healthPotion = DetermineUsableObject(player, true, nil, nil, nil, A.MajorHealingPotion, A.SuperiorHealingPotion, A.GreaterHealingPotion, A.HealingPotion, A.LesserHealingPotion, A.MinorHealingPotion)
		if healthPotion then 
			if Healthstone >= 100 then -- AUTO 
				if Unit(player):TimeToDie() <= 9 and Unit(player):HealthPercent() <= 40 then 
					return healthPotion:Show(icon)
				end 
			elseif Unit(player):HealthPercent() <= Healthstone then 
				return healthPotion:Show(icon)
			end 
		end 
	end 
	
	--[[ Leaved it here, might will need later
	HealingPotionValue						= {
		[A.MinorHealingPotion.ID]			= A.MinorHealingPotion:GetItemDescription()[1],
		[A.LesserHealingPotion.ID]			= A.LesserHealingPotion:GetItemDescription()[1],
		[A.HealingPotion.ID]				= A.HealingPotion:GetItemDescription()[1],
		[A.GreaterHealingPotion.ID]			= A.GreaterHealingPotion:GetItemDescription()[1],
		[A.SuperiorHealingPotion.ID]		= A.SuperiorHealingPotion:GetItemDescription()[1],
		[A.MajorHealingPotion.ID]			= A.MajorHealingPotion:GetItemDescription()[1],
	}
	]]
end 

function A.CanUseLimitedInvulnerabilityPotion(icon)
	-- @return boolean or nil
	if A.LimitedInvulnerabilityPotion:IsReady(player) and Unit(player):GetRealTimeDMG(3) > 0 and ((A.Role ~= "TANK" and A.IsInInstance and UnitIsUnit(targettarget, player) and select(2, Unit(player):ThreatSituation()) >= 100) or Unit(player):IsExecuted() or Unit(player):IsFocused(4, nil, nil, true)) then 
		return A.LimitedInvulnerabilityPotion:Show(icon)
	end 
end 

function A.CanUseLivingActionPotion(icon, inRange)
	-- @return boolean or nil
	if A.LivingActionPotion:IsReady(player) and (LoC:Get("STUN") > 1 or (not inRange and (LoC:Get("ROOT") > 1 or (LoC:Get("SNARE") > 0 and Unit(player):GetMaxSpeed() <= 50)))) and LoC:IsMissed(TempLivingActionPotionIsMissed) then 
		return A.LivingActionPotion:Show(icon)
	end 
end 

function A.CanUseRestorativePotion(icon, toggle)
	-- @return boolean or nil
	-- Note: Requires toggles or data from UI tab "Auras"
	local str_toggle = toggle
	if not str_toggle then 
		str_toggle = true 
	end 
	if A.RestorativePotion:IsReady(player) and (AuraIsValid(player, str_toggle, "Magic") or AuraIsValid(player, str_toggle, "Curse") or AuraIsValid(player, str_toggle, "Disease") or AuraIsValid(player, str_toggle, "Poison")) then 
		return A.RestorativePotion:Show(icon)
	end 
end 

function A.CanUseSwiftnessPotion(icon, unitID, range)
	-- @return boolean or nil
	if A.SwiftnessPotion:IsReady(player) and Player:IsMoving() and Unit(unitID or target):GetRange() >= (range or 10) and Unit(unitID or target):TimeToDieX(35) <= A.GetGCD() * 2 and Unit(player):GetMaxSpeed() <= 120 and Unit(player):GetCurrentSpeed() <= Unit(unitID or target):GetCurrentSpeed() then 
		return A.SwiftnessPotion:Show(icon)
	end 
end 

function A.Rotation(icon)
	local APL = A[playerClass]
	if not A.IsInitialized or not APL then 
		return A_Hide(icon)		
	end 	
	
	local meta 		= icon.ID
	local metaobj  	= APL[meta]
	local metatype 	= GetMetaType[metaobj or "nil"]
	
	-- [1] CC / [2] Interrupt 
	if meta <= 2 then 
		if metatype == "function" then 
			if metaobj(icon) then 
				return true
			elseif GetToggle(1, "AntiFakePauses")[meta] then
				return A.AntiFakeWhite:Show(icon)
			end 
		end 						
		
		return A_Hide(icon)
	end 
	
	-- [5] Trinket 
	if meta == 5 then 
		local result, isApplied, RacialAction
		
		-- Use racial available trinkets if we don't have additional RACIAL_LOC
		-- Note: Additional RACIAL_LOC is the main reason why I avoid here :AutoRacial (see below 'if isApplied then ')
		if GetToggle(1, "Racial") then 
			local playerRace 		= A.PlayerRace
			
			RacialAction 			= APL[GetKeyByRace[playerRace]]			
			local RACIAL_LOC 		= LoC_GetExtra[playerRace]							-- Loss Of Control 
			if RACIAL_LOC and RacialAction and RacialAction:IsReady(player, true) and RacialAction:IsExists() then 
				result, isApplied 	= LoC:IsValid(RACIAL_LOC.Applied, RACIAL_LOC.Missed, playerRace == "Dwarf" or playerRace == "Gnome")
				if result then 
					return RacialAction:Show(icon)
				end 
			end 		
		end	
		
		-- Use specialization spell trinkets
		if metatype == "function" and metaobj(icon) then  
			return true 			
		end 		
		
		-- Use racial if nothing is not available 
		if isApplied then 
			return RacialAction:Show(icon)
		end 
			
		return A_Hide(icon)		 
	end 
	
	local PauseChecks = PauseChecks()
	if PauseChecks then
		if meta == 3 then 
			return A:Show(icon, PauseChecks)
		end  
		return A_Hide(icon)		
	end 		
	
	-- [6] Passive: @player, @raid1, @party1, @arena1 
	if meta == 6 then 
		-- Shadowmeld
		if APL.Shadowmeld and APL.Shadowmeld:AutoRacial(player) then 
			return APL.Shadowmeld:Show(icon)
		end 
		
		-- Cursor 
		if A.GameTooltipClick and not IsMouseButtonDown("LeftButton") and not IsMouseButtonDown("RightButton") then 			
			if A.GameTooltipClick == "LEFT" then 
				return A:Show(icon, CONST_LEFT)			 
			elseif A.GameTooltipClick == "RIGHT" then 
				return A:Show(icon, CONST_RIGHT)
			end 
		end 
		
		-- ReTarget 
		if A.Zone == "pvp" and (A:GetTimeSinceJoinInstance() >= 30 or Unit(player):CombatTime() > 0) and Re:CanTarget(icon) then  
			return true
		end 
		
		if not Player:IsStealthed() then 
			-- Healthstone 
			local Healthstone = GetToggle(1, "HealthStone") 
			if Healthstone >= 0 then 
				local HealthStoneObject = DetermineUsableObject(player, true, nil, true, nil, A.HSFel3, A.HSFel2, A.HSFel1, A.HSGreater3, A.HSGreater2, A.HSGreater1, A.HS3, A.HS2, A.HS1, A.HSLesser3, A.HSLesser2, A.HSLesser1, A.HSMajor3, A.HSMajor2, A.HSMajor1, A.HSMinor3, A.HSMinor2, A.HSMinor1)
				if HealthStoneObject then 			
					if Healthstone >= 100 then -- AUTO 
						if Unit(player):TimeToDie() <= 9 and Unit(player):HealthPercent() <= 40 then 
							return HealthStoneObject:Show(icon)	
						end 
					elseif Unit(player):HealthPercent() <= Healthstone then 
						return HealthStoneObject:Show(icon)								 
					end 
				end 
			end 		
		end 
		
		-- AutoTarget 
		if GetToggle(1, "AutoTarget") and Unit(player):CombatTime() > 0 -- and not A.IamHealer
			-- No existed or switch in PvE if we accidentally selected out of combat enemy unit  
			and (not Unit(target):IsExists() or (A.Zone ~= "none" and not A.IsInPvP and Unit(target):CombatTime() == 0 and Unit(target):IsEnemy() and Unit(target):HealthPercent() >= 100)) 
			-- If there PvE in 40 yards any in combat enemy (exception target) or we're on (R)BG 
			and ((not A.IsInPvP and MultiUnits:GetByRangeInCombat(nil, 1) >= 1) or A.Zone == "pvp")
		then 
			return A:Show(icon, CONST_AUTOTARGET)			 
		end 
	end 
	
	-- Queue System
	if IsQueueReady(meta) then                                              
		return QueueData[1]:Show(icon)				 
    end 
	
	-- Hide frames which are not used by profile
	if metatype ~= "function" then 
		return A_Hide(icon)
	end 
	
	-- Save unit for AutoAttack, AutoShoot
	local unit, useShoot
	if IsUnitEnemy(mouseover) then 
		unit = mouseover
	elseif IsUnitEnemy(target) then 
		unit = target
	elseif IsUnitEnemy(targettarget) then 
		unit = targettarget
	end 	
	
	-- [3] Single / [4] AoE: AutoAttack
	if unit and (meta == 3 or meta == 4) and not Player:IsStealthed() and Unit(player):IsCastingRemains() == 0 and HasFullControl() then 
		useShoot = IsShoot(unit)
		if not useShoot and unit ~= targettarget and GetToggle(1, "AutoAttack") and not Player:IsAttacking() then 
			-- Cancel shoot because it doesn't reseting by /startattack and it will be stucked to shooting
			--if playerClass ~= "HUNTER" and Player:IsShooting() and HasWandEquipped() then 
				--return A:Show(icon, CONST_AUTOSHOOT)
			--end 
			
				-- Use AutoAttack only if not a hunter or it's is out of range by AutoShot 
			if 	(playerClass ~= "HUNTER" or not GetToggle(1, "AutoShoot") or not Player:IsShooting() or not A.AutoShot:IsInRange(unit)) and 
				-- ByPass Rogue's mechanic
				(playerClass ~= "ROGUE" or ((unit ~= mouseover or UnitIsUnit(unit, target)) and Unit(unit):HasDeBuffs("BreakAble") == 0)) and 
				-- ByPass Warlock's mechanic 
				(playerClass ~= "WARLOCK" or Unit(unit):GetRange() <= 5)
			then 
				return A:Show(icon, CONST_AUTOATTACK)
			end 
		end 
	end 
	
	-- [3] Single / [4] AoE / [6-8] Passive: @player-party1-3, @raid1-3, @arena1-3 + Active: other AntiFakes
	if metaobj(icon) then 
		return true 
	end 
	
	-- [3] Single / [4] AoE: AutoShoot
	if useShoot and (meta == 3 or meta == 4) then 
		return A:Show(icon, CONST_AUTOSHOOT)
	end 
	
	-- [3] Set Class Portrait
	if meta == 3 and not GetToggle(1, "DisableClassPortraits") then 
		return A:Show(icon, ClassPortaits[playerClass])
	end 
	
	-- [7] CC Focus / [8] Interrupt Focus / [9] CC2 / [10] CC2 Focus
	if BuildToC >= 20000 and metaobj and meta >= 7 and GetToggle(1, "AntiFakePauses")[meta - 4] then 
		return A.AntiFakeWhite:Show(icon)
	end 
	
	A_Hide(icon)			
end 

-- setfenv will make working it way faster as lua condition for TMW frames 
do 
	local vType
	for k, v in pairs(A) do 
		vType = type(v)
		if (vType == "table" or vType == "function") and _G[k] == nil and Env[k] == nil then 
			Env[k] = v
		end		
	end 
end 
--[[
CNDT.EnvMeta.__index = function(t, v)		
	if _G[v] ~= nil then 	
		return _G[v]
	else		
		local vType = type(A[v])
		if vType == "table" or vType == "function" then 
			t[v] = A[v]
		end 
		return A[v]
	end 
end]]