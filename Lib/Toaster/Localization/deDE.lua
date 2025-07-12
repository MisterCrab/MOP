local ADDON_NAME, private = ...

local _G = getfenv(0)
local L = _G.LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "deDE", false)

if not L then return end

L["Background"] = "Hintergrund"
L["BOTTOM"] = "Unten"
L["BOTTOMLEFT"] = "Unten Links"
L["BOTTOMRIGHT"] = "Unten Rechts"
L["CENTER"] = "Zentrum"
L["Drag to set the spawn point for toasts."] = "Ziehen, um den Ankerpunkt festzulegen."
L["Emergency"] = "Notfall"
L["Floating Icon"] = "Schwebendes Symbol"
L["Hide Toasts"] = "Fenster verstecken"
L["High"] = "Hoch"
L["Horizontal offset from the anchor point."] = "Der horizontale Offset vom Ankerpunkt aus."
L["Icon Size"] = "Symbolgröße"
L["LEFT"] = "Links"
L["Moderate"] = "Moderat"
L["Mute Toasts"] = "Fenster stummschalten"
L["Normal"] = true
L["Preview"] = "Vorschau"
L["Reset Position"] = "Position zurücksetzen"
L["RIGHT"] = "Rechts"
L["Show Anchor"] = "Anker anzeigen"
L["Show Minimap Icon"] = "Minikartensymbol anzeigen"
L["Spawn Point"] = "Ankerpunkt"
L["Text"] = true
L["Title"] = "Titel"
L["TOP"] = "Oben"
L["TOPLEFT"] = "Oben Links"
L["TOPRIGHT"] = "Oben Rechts"
L["Vertical offset from the anchor point."] = "Der vertikale Offset vom Ankerpunkt aus."
L["Very Low"] = "Sehr niedrig"
L["X Offset"] = true
L["Y Offset"] = true

