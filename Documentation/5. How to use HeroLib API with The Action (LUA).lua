--[[
-------------------------------------------------------------------------------
-- Introduction 
-------------------------------------------------------------------------------
This guide will describe how to be super lazy and transfer HeroRotations (https://github.com/herotc/hero-rotation) by few mins 
Make sure what you created ProfileUI and specizalition snippets before to continue as it was described in previous guides
Make sure what you have enabled HeroLib and HeroCache addons

-------------------------------------------------------------------------------
-- №1: Make Hero API defaults
-------------------------------------------------------------------------------
Write in chat /tmw > 'LUA Snippets' > Find to edit your specizalition snippet for profile 
Make sure what Action[Action.PlayerClass] has same KEY names as it has HeroRotation code for Spell and Item 
You have to put them with same name and same case sensitive in Action[Action.PlayerClass]
--]]

Action[Action.PlayerClass] = {
	-- your actions to create same as it has HeroRotation but with Action structure 
}

-- And we make it shorter for access
local A = setmetatable(Action[Action.PlayerClass], { __index = Action })

-- Now we have to set Hero API defaults 
-- HeroLib
local HL     = HeroLib
local Cache  = HeroCache

-- We can add check for addon enabled to avoid errors for people who missing enable it, like that:
if HL then 
	local Unit   = HL.Unit
	local Player = Unit.Player
	local Target = Unit.Target
	local Pet    = Unit.Pet
	local Spell  = HL.Spell
	local Item   = HL.Item
	-- HeroRotation
	-- You can skip HeroRotation if you do not plan to use by Hero API short table 'HR.' and if APL function in HeroRotation hasn't 'HR.' or if you will remove these parts 
	-- However you can just leave it as it, even if you don't will have enabled HeroRotation some parts of that will be remaped by code in Modules/Misc/HeroLib.lua
	-- You can open that module to see what it remap and what not for more info 
	local HR   = HeroRotation	
	
	-- Now we use 'The Action' API to get from Action[PLAYERSPEC] recreated actions for 'Hero API' by using this code here:
	local S, I = A:HeroCreate() 		-- Get S (Spell) and I (Item) tables as it does 'Hero API' 
	Action.HeroSetHookAllTable(S, {
		-- [3] is 'Meta Icon' which will be used as position to display whole rotation, look '1. Introduction.lua' about 'Shown Main' if you forgot what each meta does
		-- "TellMeWhen_Group2_Icon3" is string in quotes, this is refference for 'Condition Icon', if you're confused about this look '3. How to create Rotation (LUA).lua' №4
		[3] = "TellMeWhen_Group2_Icon3",
	})
	Action.HeroSetHookAllTable(I, {
		[3] = "TellMeWhen_Group2_Icon3",
	})
	
	-- You can use standalone table keys, you're not limited to use Action.HeroSetHookAllTable for only one table always, look 'HeroLib.lua' for more info 
	
	
	-- Copy past here code which you have in HeroRotation after S and I 
	--[[ Remove next things if you see in copied code:
		HR.SetAPL
		HR.Cast(S.PoolEnergy)
		Everyone.
		HR.Commons.
		Settings 
		General 
		Commons 		
		Because they can be nil and it will bring lua error if they will remain in copied code 
	]]
	local function APL()
		-- This is usually always exist and we will use it
	end 
end 

-------------------------------------------------------------------------------
-- №2: Put HeroRotation to 'The Action' rotation 
-------------------------------------------------------------------------------
-- It does use this structure:
A['@number'] = function(icon)
	-- use here next code taken from HeroRotation 
	if HL and APL() then 
		return true 
	end 
	-- you can use additional rotation here after or above 'if APL() then' either even inside APL()
	-- if you will use APL() then you have to add argument (icon) for APL to pass frame there, like 'local function APL(icon)'
end 

-- Now it will support SetBlocker, Toggles and LUA for [3] 'Actions' tab in /action for 'HeroRotation', also HR.CDsON, HR.AoEON remap to 'The Action' toggles

-------------------------------------------------------------------------------
-- №3: Working example on BrewMaster Monk
-------------------------------------------------------------------------------
local TMW = TMW 
local CNDT = TMW.CNDT 
local Env = CNDT.Env
local Action = Action

Action[Action.PlayerClass] = {
	-- Racial
	ArcaneTorrent                         	= Action.Create({ Type = "Spell", ID = 50613 	}),
	BloodFury                             	= Action.Create({ Type = "Spell", ID = 20572  	}),
	Fireblood 							  	= Action.Create({ Type = "Spell", ID = 265221 	}),
	AncestralCall						  	= Action.Create({ Type = "Spell", ID = 274738 	}),
	Berserking                            	= Action.Create({ Type = "Spell", ID = 26297	}),
	ArcanePulse							  	= Action.Create({ Type = "Spell", ID = 260364	}),
	QuakingPalm							  	= Action.Create({ Type = "Spell", ID = 107079 	}),
	Haymaker							  	= Action.Create({ Type = "Spell", ID = 287712 	}), 
	WarStomp							  	= Action.Create({ Type = "Spell", ID = 20549 	}),
	BullRush							  	= Action.Create({ Type = "Spell", ID = 255654 	}),	
	GiftofNaaru 						  	= Action.Create({ Type = "Spell", ID = 59544	}),
	Shadowmeld							  	= Action.Create({ Type = "Spell", ID = 58984	}), -- usable in Action Core 
	Stoneform						  		= Action.Create({ Type = "Spell", ID = 20594	}), 
	WilloftheForsaken				  		= Action.Create({ Type = "Spell", ID = 7744		}), -- not usable in APL but user can Queue it	
	EscapeArtist						  	= Action.Create({ Type = "Spell", ID = 20589	}), -- not usable in APL but user can Queue it
	EveryManforHimself				  		= Action.Create({ Type = "Spell", ID = 59752	}), -- not usable in APL but user can Queue it
	-- CrownControl	 
	Paralysis								= Action.Create({ Type = "Spell", ID = 115078	}),
	ParalysisAntiFake						= Action.Create({ Type = "Spell", ID = 115078, Desc = "[2] Kick", QueueForbidden = true	}),
	LegSweep							  	= Action.Create({ Type = "Spell", ID = 119381	}),
	LegSweepGreen						  	= Action.Create({ Type = "SpellSingleColor", ID = 119381, Color = "GREEN", Desc = "[1] CC", QueueForbidden = true }),
	SpearHandStrike						  	= Action.Create({ Type = "Spell", ID = 116705	}),
	SpearHandStrikeGreen					= Action.Create({ Type = "SpellSingleColor", ID = 116705, Color = "GREEN", Desc = "[2] Kick", QueueForbidden = true }),
	-- Suppotive	
	Resuscitate							  	= Action.Create({ Type = "Spell", ID = 115178, QueueForbidden = true	}),
	Provoke								  	= Action.Create({ Type = "Spell", ID = 115546	}),	
	SummonBlackOxStatue					 	= Action.Create({ Type = "Spell", ID = 115315 	}),
	ProvokeSummonBlackOxStatue				= Action.Create({ Type = "Spell", ID = 115546, Color = "PINK", Texture = 115315 }),
	Admonishment 							= Action.Create({ Type = "Spell", ID = 207025	}),	-- PvP Talent Provoke 
	Detox								  	= Action.Create({ Type = "Spell", ID = 218164	}),
	TigersLust						   	  	= Action.Create({ Type = "Spell", ID = 116841	}),
	Vivify								  	= Action.Create({ Type = "Spell", ID = 116670	}),
	-- Defensives	
	IronskinBrew                          	= Action.Create({ Type = "Spell", ID = 115308 	}), -- on simcraft it is Brews
	PurifyingBrew                        	= Action.Create({ Type = "Spell", ID = 119582 	}),
	HealingElixir						  	= Action.Create({ Type = "Spell", ID = 122281 	}),
	ZenMeditation						  	= Action.Create({ Type = "Spell", ID = 115176 	}),
	Guard								  	= Action.Create({ Type = "Spell", ID = 115295 	}),	
	DampenHarm                            	= Action.Create({ Type = "Spell", ID = 122278 	}),
	FortifyingBrew                        	= Action.Create({ Type = "Spell", ID = 115203 	}),			
	-- Rotation 	
	BlackoutStrike                        	= Action.Create({ Type = "Spell", ID = 205523 	}),
	BlackOxBrew                           	= Action.Create({ Type = "Spell", ID = 115399 	}),	
	BreathofFire                          	= Action.Create({ Type = "Spell", ID = 115181 	}),
	CracklingJadeLightning				  	= Action.Create({ Type = "Spell", ID = 117952 	}),
	ChiBurst                              	= Action.Create({ Type = "Spell", ID = 123986 	}),
	ChiWave                               	= Action.Create({ Type = "Spell", ID = 115098 	}),	
	ExpelHarm							  	= Action.Create({ Type = "Spell", ID = 115072 	}),
	InvokeNiuzaotheBlackOx                	= Action.Create({ Type = "Spell", ID = 132578 	}),	
	KegSmash                              	= Action.Create({ Type = "Spell", ID = 121253 	}),	
	RushingJadeWind                       	= Action.Create({ Type = "Spell", ID = 116847 	}),	
	TigerPalm                             	= Action.Create({ Type = "Spell", ID = 100780 	}),
	-- Auras 
	BreathofFireDotDebuff					= Action.Create({ Type = "Spell", ID = 123725, Hidden = true }), 
	BlackoutComboBuff                       = Action.Create({ Type = "Spell", ID = 196736, Hidden = true }), 
	SpecialDelivery                       	= Action.Create({ Type = "Spell", ID = 196730, Hidden = true }),	
	LightBrewing                          	= Action.Create({ Type = "Spell", ID = 196721, Hidden = true }),
	-- Movememnt	
	Roll									= Action.Create({ Type = "Spell", ID = 109132	}),
	ChiTorpedo								= Action.Create({ Type = "Spell", ID = 115008	}),
	TranscendenceTransfer					= Action.Create({ Type = "Spell", ID = 119996	}), -- not usable in APL but user can Queue it
	-- PvP
	DoubleBarrel							= Action.Create({ Type = "Spell", ID = 202335	}),
	MightyOxKick							= Action.Create({ Type = "Spell", ID = 202370	}),
	AvertHarm								= Action.Create({ Type = "Spell", ID = 202162	}),	
	CraftNimbleBrew							= Action.Create({ Type = "Spell", ID = 213658, QueueForbidden = true }),
	NimbleBrew								= Action.Create({ Type = "Item", ID = 137648, Color = "RED", QueueForbidden = true }),	
	-- Items
	BattlePotionOfAgility				 	= Action.Create({ Type = "Potion", ID = 163223 }),	
	SuperiorBattlePotionOfAgility			= Action.Create({ Type = "Potion", ID = 168489 }),	
}

local A = setmetatable(Action[Action.PlayerClass], { __index = Action })

-- Simcraft Imported
-- HeroLib
local HL     		= HeroLib
local Cache  		= HeroCache
local Unit   		= HL.Unit
local Player 		= Unit.Player
local Target 		= Unit.Target
local Pet    		= Unit.Pet
local MultiSpell 	= HL.MultiSpell
local Spell  		= HL.Spell
local Item   		= HL.Item
-- HeroRotation
local HR   = HeroRotation

---------------------------
-- PORT TO ACTION 
local S, I = A:HeroCreate()
Action.HeroSetHookAllTable(S, { -- Spells 
	[3] = "TellMeWhen_Group2_Icon3",
})
Action.HeroSetHookAllTable(I, { -- Items
	[3] = "TellMeWhen_Group2_Icon3",
})
-- Adding manually missed staff
S.Brews                                 = Spell(115308)
S.BlackoutCombo                         = Spell(196736)
S.BlackoutComboBuff                     = Spell(228563)
-- MultiSpell as well need manually to add 
S.Execute 								= MultiSpell(1,2)
---------------------------

-- Rotation Var
local ShouldReturn; -- Used to get the return string
local ForceOffGCD = {true, false};

-- Array of the 3 stagger levels
local staggerDebuffs = {
  [124273] = true,
  [124274] = true,
  [124275] = true,
};

-- UnitAura function from BrewmasterTools
local function BrMUnitAura(unit, spellID, filter)
  local i, id = 0, 0
  if type(spellID) == "number" then
    while id do
      i = i + 1
      id = select(10, UnitAura(unit, i, filter))
      if spellID == id then
        return UnitAura(unit, i, filter)
      end
    end
  else
    while id do
      i = i + 1
      id = select(10, UnitAura(unit, i, filter))
      if spellID[id] then
        return UnitAura(unit, i, filter)
      end
    end
  end
end

-- GetNextTick function from BrewmasterTools
local function GetNextTick()
  return select(16,BrMUnitAura("player", staggerDebuffs, "HARMFUL")) or 0
end

-- makeTempAdder function from BrewmasterTools
local function BrMMakeTempAdder()
  local val = 0
  return function(toAdd, decayTime) --modify upvalue
    val = val + toAdd
    C_Timer.After(decayTime,function()
      val = val - toAdd
    end)
  end,
  function()  return val  end --access upvalue
end

BrMAddToPool, BrMGetNormalStagger = BrMMakeTempAdder()

local function ShouldPurify ()
  local NormalizedStagger = BrMGetNormalStagger();
  local NextStaggerTick = GetNextTick();
  local NStaggerPct = NextStaggerTick > 0 and NextStaggerTick/Player:MaxHealth() or 0;
  local ProgressPct = NormalizedStagger > 0 and Player:Stagger()/NormalizedStagger or 0;
  if NStaggerPct > 0.015 and ProgressPct > 0 then
    if NStaggerPct <= 0.03 then -- Yellow (> 80%)
      return ProgressPct > 0.8 or false;
    elseif NStaggerPct <= 0.05 then -- Orange (> 70%)
      return ProgressPct > 0.7 or false;
    elseif NStaggerPct <= 0.1 then -- Red (> 50%)
      return ProgressPct > 0.5 or false;
    else -- Magenta
      return true;
    end
  end
end

--- ======= ACTION LISTS =======
local function APL()
--[[ check if our Helper HeroAPI.lua works
	if true then 
		HR.Cast(S.RushingJadeWind) 
		return true 
	end
]]	
  -- Unit Update
  HL.GetEnemies(8, true);

  -- Misc
  local BrewMaxCharge = 3 + (S.LightBrewing:IsAvailable() and 1 or 0);
  local IronskinDuration = 7;
  local IsTanking = Player:IsTankingAoE(8) or Player:IsTanking(Target);

  local function Defensives()
    -- ironskin_brew,if=buff.blackout_combo.down&incoming_damage_1999ms>(health.max*0.1+stagger.last_tick_damage_4)&buff.elusive_brawler.stack<2&!buff.ironskin_brew.up
    -- ironskin_brew,if=cooldown.brews.charges_fractional>1&cooldown.black_ox_brew.remains<3
    -- Note: Extra handling of the charge management only while tanking.
    --       "- (IsTanking and 1 + (Player:BuffRemains(S.IronskinBrewBuff) <= IronskinDuration * 0.5 and 0.5 or 0) or 0)"
    if S.IronskinBrew:IsCastableP() and Player:BuffDownP(S.BlackoutComboBuff)
        and S.Brews:ChargesFractional() >= BrewMaxCharge - 0.1 - (IsTanking and 1 + (Player:BuffRemains(S.IronskinBrewBuff) <= IronskinDuration * 0.5 and 0.5 or 0) or 0)
        and Player:BuffRemains(S.IronskinBrewBuff) <= IronskinDuration * 2 then
      if HR.Cast(S.IronskinBrew) then return ""; end
    end
    -- purifying_brew,if=stagger.pct>(6*(3-(cooldown.brews.charges_fractional)))&(stagger.last_tick_damage_1>((0.02+0.001*(3-cooldown.brews.charges_fractional))*stagger.last_tick_damage_30))
    if S.PurifyingBrew:IsCastableP() and ShouldPurify() then
      if HR.Cast(S.PurifyingBrew) then return ""; end
    end
    -- BlackoutCombo Stagger Pause w/ Ironskin Brew
    if S.IronskinBrew:IsCastableP() and Player:BuffP(S.BlackoutComboBuff) and Player:HealingAbsorbed() and ShouldPurify() then
      if HR.Cast(S.IronskinBrew) then return ""; end
    end
  end

  --- In Combat
  if true then
    -- Interrupts
    -- Defensives
    if IsTanking then
      ShouldReturn = Defensives(); if ShouldReturn then return ShouldReturn; end
    end
    -- blood_fury
    if S.BloodFury:IsCastableP() and HR.CDsON() then
      if HR.Cast(S.BloodFury) then return ""; end
    end
    -- berserking
    if S.Berserking:IsCastableP() and HR.CDsON() then
      if HR.Cast(S.Berserking) then return ""; end
    end
    -- lights_judgment
    -- fireblood
    -- ancestral_call
    -- invoke_niuzao_the_black_ox
    if S.InvokeNiuzaotheBlackOx:IsCastableP(40) and HR.CDsON() and Target:TimeToDie() > 25 then
      if HR.Cast(S.InvokeNiuzaotheBlackOx) then return ""; end
    end
    -- black_ox_brew,if=cooldown.brews.charges_fractional<0.5
    if S.BlackOxBrew:IsCastableP() and S.Brews:ChargesFractional() <= 0.5 then
      if HR.Cast(S.BlackOxBrew) then return ""; end
    end
    -- black_ox_brew,if=(energy+(energy.regen*cooldown.keg_smash.remains))<40&buff.blackout_combo.down&cooldown.keg_smash.up
    if S.BlackOxBrew:IsCastableP() and (Player:Energy() + (Player:EnergyRegen() * S.KegSmash:CooldownRemainsP())) < 40 and Player:BuffDownP(S.BlackoutComboBuff) and S.KegSmash:CooldownUpP() then
      if S.Brews:Charges() >= 2 and Player:StaggerPercentage() >= 1 then
        HR.Cast(S.IronskinBrew, ForceOffGCD);
        HR.Cast(S.PurifyingBrew, ForceOffGCD);
        if HR.Cast(S.BlackOxBrew) then return ""; end
      else
        if S.Brews:Charges() >= 1 then HR.Cast(S.IronskinBrew, ForceOffGCD); end
        if HR.Cast(S.BlackOxBrew) then return ""; end
      end
    end
    -- keg_smash,if=spell_targets>=2
    if S.KegSmash:IsCastableP(25) and Cache.EnemiesCount[8] >= 2 then
      if HR.Cast(S.KegSmash) then return ""; end
    end
    -- tiger_palm,if=talent.rushing_jade_wind.enabled&buff.blackout_combo.up&buff.rushing_jade_wind.up
    if S.TigerPalm:IsCastableP("Melee") and S.RushingJadeWind:IsAvailable() and Player:BuffP(S.BlackoutComboBuff) and Player:BuffP(S.RushingJadeWind) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- tiger_palm,if=(talent.invoke_niuzao_the_black_ox.enabled|talent.special_delivery.enabled)&buff.blackout_combo.up
    if S.TigerPalm:IsCastableP("Melee") and (S.InvokeNiuzaotheBlackOx:IsAvailable() or S.SpecialDelivery:IsAvailable()) and Player:BuffP(S.BlackoutComboBuff) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- blackout_strike
    if S.BlackoutStrike:IsCastableP("Melee") then
      if HR.Cast(S.BlackoutStrike) then return ""; end
    end
    -- keg_smash
    if S.KegSmash:IsCastableP(25) then
      if HR.Cast(S.KegSmash) then return ""; end
    end
    -- rushing_jade_wind,if=buff.rushing_jade_wind.down
    if S.RushingJadeWind:IsCastableP() and Player:BuffDownP(S.RushingJadeWind) then
      if HR.Cast(S.RushingJadeWind) then return ""; end
    end
    -- breath_of_fire,if=buff.blackout_combo.down&(buff.bloodlust.down|(buff.bloodlust.up&&dot.breath_of_fire_dot.refreshable))
    if S.BreathofFire:IsCastableP(10, true) and (Player:BuffDownP(S.BlackoutComboBuff) and (Player:HasNotHeroism() or (Player:HasHeroism() and true and Target:DebuffRefreshableCP(S.BreathofFireDotDebuff)))) then
      if HR.Cast(S.BreathofFire) then return ""; end
    end
    -- chi_burst
    if S.ChiBurst:IsCastableP(10) then
      if HR.Cast(S.ChiBurst) then return ""; end
    end
    -- chi_wave
    if S.ChiWave:IsCastableP(25) then
      if HR.Cast(S.ChiWave) then return ""; end
    end
    -- tiger_palm,if=!talent.blackout_combo.enabled&cooldown.keg_smash.remains>gcd&(energy+(energy.regen*(cooldown.keg_smash.remains+gcd)))>=65
    if S.TigerPalm:IsCastableP("Melee") and (not S.BlackoutCombo:IsAvailable() and S.KegSmash:CooldownRemainsP() > Player:GCD() and (Player:Energy() + (Player:EnergyRegen() * (S.KegSmash:CooldownRemainsP() + Player:GCD()))) >= 65) then
      if HR.Cast(S.TigerPalm) then return ""; end
    end
    -- arcane_torrent,if=energy<31
    if HR.CDsON() and S.ArcaneTorrent:IsCastableP() and Player:Energy() < 31 then
      if HR.Cast(S.ArcaneTorrent) then return ""; end
    end
    -- rushing_jade_wind
    if S.RushingJadeWind:IsCastableP() then
      if HR.Cast(S.RushingJadeWind) then return ""; end
    end
	
    -- downtime energy pooling
    --if HR.Cast(S.PoolEnergy) then return "Pool Energy"; end
  end
end
-- Finished

function Env.AutoPurify()
	-- Using by Dynamic bar also
	local lvl = BrewmasterTools.GetStaggerLevel()
	if (lvl > 1 and lvl < 3 and BrewmasterTools.GetStaggerProgress() > 80) or (lvl == 3 and BrewmasterTools.GetStaggerProgress() > 70) or (lvl == 4 and BrewmasterTools.GetStaggerProgress() > 50) or lvl > 4 then 
		return true, lvl
	end 
	return false, -1
end 

-- [3] Single Rotation
A[3] = function(icon)
	if HL and APL() then 
		return true 
	end 
	-- test after simcraft our api like if nothing to do
	return A.Roll:Show(icon)
end
