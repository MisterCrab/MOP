local ADDON_NAME, private = ...

local _G = getfenv(0)

local isReleaseVersion = true
--[===[@debug@
isReleaseVersion = false
--@end-debug@]===]


local L = _G.LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "enUS", isReleaseVersion, isReleaseVersion)

if not L then return end

L["Background"] = true
L["BOTTOM"] = "Bottom"
L["BOTTOMLEFT"] = "Bottom Left"
L["BOTTOMRIGHT"] = "Bottom Right"
L["CENTER"] = "Center"
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
L["TOP"] = "Top"
L["TOPLEFT"] = "Top Left"
L["TOPRIGHT"] = "Top Right"
L["Vertical offset from the anchor point."] = true
L["Very Low"] = true
L["X Offset"] = true
L["Y Offset"] = true

