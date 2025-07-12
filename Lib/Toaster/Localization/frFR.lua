local ADDON_NAME, private = ...

local _G = getfenv(0)
local L = _G.LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "frFR", false)

if not L then return end

L["Background"] = "Arrière-plan"
L["BOTTOM"] = "en bas"
L["BOTTOMLEFT"] = "Bas-gauche"
L["BOTTOMRIGHT"] = "Bas-droite"
L["CENTER"] = "Centre"
L["Drag to set the spawn point for toasts."] = "Glisser pour regler le point d'apparition des Toasts"
L["Emergency"] = "Urgence"
L["Floating Icon"] = "Icône flottant"
L["Hide Toasts"] = "Cacher les fenêtres"
L["High"] = "Haut"
L["Horizontal offset from the anchor point."] = "Décalage horizontal du point d'ancrage."
L["Icon Size"] = "Taille de l'icône"
L["LEFT"] = "Gauche"
L["Moderate"] = "Modéré"
L["Mute Toasts"] = "Metre Toaster en pause"
L["Normal"] = true
L["Preview"] = "Aperçu"
L["Reset Position"] = "Réinitialiser la Position"
L["RIGHT"] = "Droite"
L["Show Anchor"] = "voir le point d'ancrage"
L["Show Minimap Icon"] = "Afficher l'icône de la minicarte"
L["Spawn Point"] = "Point d'apparition"
L["Text"] = "Texte"
L["Title"] = "Titre"
L["TOP"] = "en Haut"
L["TOPLEFT"] = "Haut-gauche"
L["TOPRIGHT"] = "Haut-droite"
L["Vertical offset from the anchor point."] = "Décalage vertical du point d'ancrage."
L["Very Low"] = "Très bas"
L["X Offset"] = "Décalage 'X'"
L["Y Offset"] = "Décalage 'Y'"

