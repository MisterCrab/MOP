-------------------------------------------------------------------------------------
-- This lib has some memory leaks by recreate tables which can be static
-- These tweakes supposed to fix some of them 
-------------------------------------------------------------------------------------
local HealComm = LibStub("LibHealComm-4.0", true)
if not HealComm then return end 

local _G, ipairs, pairs, math	= _G, ipairs, pairs, math
local bit						= _G.bit 
local wipe						= _G.wipe
local hooksecurefunc			= _G.hooksecurefunc

local band 						= bit.band 
local floor						= math.floor
local min						= math.min 

local TMW 						= _G.TMW
local A 						= _G.Action 
local TeamCache 				= A.TeamCache
local TeamCacheFriendly			= TeamCache.Friendly
local TeamCacheFriendlyUNITs	= TeamCacheFriendly.UNITs -- unitID to unitGUID

local ALL_HEALS					= HealComm.ALL_HEALS
local CHANNEL_HEALS				= HealComm.CHANNEL_HEALS
local DIRECT_HEALS				= HealComm.DIRECT_HEALS
local HOT_HEALS					= HealComm.HOT_HEALS
local CASTED_HEALS				= HealComm.CASTED_HEALS
local ABSORB_SHIELDS			= HealComm.ABSORB_SHIELDS
local ALL_DATA					= HealComm.ALL_DATA
local BOMB_HEALS				= HealComm.BOMB_HEALS

local pendingHeals 				= HealComm.pendingHeals
local pendingHots 				= HealComm.pendingHots
local pendingTable				= {pendingHeals, pendingHots}

local UnitGUID					= _G.UnitGUID

local function GetGUID(unitID)
	return (unitID and TeamCacheFriendlyUNITs[unitID]) or UnitGUID(unitID)
end 

local function filterData(spells, filterGUID, bitFlag, time, ignoreGUID)
	local healAmount = 0
	local currentTime = TMW.time

	if spells then
		local 	guid,
				amount, stack, endTime,
				ticksLeft, ticksPassed,
				secondsLeft, bandSeconds, ticks, nextTickIn, fractionalBand
				
		for _, pending in pairs(spells) do
			if( pending.bitType and band(pending.bitType, bitFlag) > 0 ) then
				for i = 1, #(pending), 5 do
					guid = pending[i]
					if( guid == filterGUID or ignoreGUID ) then
						amount = pending[i + 1]
						stack = pending[i + 2]
						endTime = pending[i + 3]
						endTime = endTime > 0 and endTime or pending.endTime

						if( ( pending.bitType == DIRECT_HEALS or pending.bitType == BOMB_HEALS ) and ( not time or endTime <= time ) ) then
							healAmount = healAmount + amount * stack
						elseif( ( pending.bitType == CHANNEL_HEALS or pending.bitType == HOT_HEALS ) and endTime > currentTime ) then
							ticksLeft = pending[i + 4]
							if( not time or time >= endTime ) then
								if( not pending.hasVariableTicks ) then
									healAmount = healAmount + (amount * stack) * ticksLeft
								else
									ticksPassed = pending.totalTicks - ticksLeft
									for numTick, heal in pairs(amount) do
										if numTick > ticksPassed then
											healAmount = healAmount + (heal * stack)
										end
									end
								end
							else
								secondsLeft = endTime - currentTime
								bandSeconds = time - currentTime
								ticks = floor(min(bandSeconds, secondsLeft) / pending.tickInterval)
								nextTickIn = secondsLeft % pending.tickInterval
								fractionalBand = bandSeconds % pending.tickInterval
								if( nextTickIn > 0 and nextTickIn < fractionalBand ) then
									ticks = ticks + 1
								end
								if( not pending.hasVariableTicks ) then
									healAmount = healAmount + (amount * stack) * min(ticks, ticksLeft)
								else
									ticksPassed = pending.totalTicks - ticksLeft
									for numTick, heal in ipairs(amount) do
										if numTick > ticksPassed then
											healAmount = healAmount + (heal * stack)
										end
									end
								end
							end
						end
					end
				end
			end
		end
	end

	return healAmount
end

-- Gets healing amount using the passed filters
function HealComm:GetHealAmount(guid, bitFlag, time, casterGUID)
	local amount = 0
	if( casterGUID and (pendingHeals[casterGUID] or pendingHots[casterGUID]) ) then
		amount = filterData(pendingHeals[casterGUID], guid, bitFlag, time) + filterData(pendingHots[casterGUID], guid, bitFlag, time)
	elseif( not casterGUID ) then
		for i = 1, #pendingTable do
			for _, spells in pairs(pendingTable[i]) do
				amount = amount + filterData(spells, guid, bitFlag, time)
			end
		end
	end

	return amount > 0 and amount or nil
end

-- Gets healing amounts for everyone except the player using the passed filters
function HealComm:GetOthersHealAmount(guid, bitFlag, time)
	local amount = 0
	for i = 1, #pendingTable do
		for casterGUID, spells in pairs(pendingTable[i]) do
			if casterGUID ~= GetGUID("player") then
				amount = amount + filterData(spells, guid, bitFlag, time)
			end
		end
	end

	return amount > 0 and amount or nil
end

-- Refresh erased tables 
hooksecurefunc(HealComm, "GROUP_ROSTER_UPDATE", function()
	wipe(pendingTable)
	pendingTable[#pendingTable + 1] = HealComm.pendingHeals
	pendingTable[#pendingTable + 1] = HealComm.pendingHots
end)