local ADDON_NAME, private = ...

local _G = getfenv(0)
local L = _G.LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "esMX", false)

if not L then return end

L["Background"] = "Fondo"
L["BOTTOM"] = "Inferior"
L["BOTTOMLEFT"] = "Inferior izquierda"
L["BOTTOMRIGHT"] = "Inferior derecha"
L["CENTER"] = "Centro"
L["Drag to set the spawn point for toasts."] = "Arrastrar para establecer el punto de anclaje de las ventanas de aviso."
L["Emergency"] = "Emergencia"
L["Floating Icon"] = "Icono flotante"
L["Hide Toasts"] = "Ocultar ventanas de aviso"
L["High"] = "Elevado"
L["Horizontal offset from the anchor point."] = "Cambiar el offset horizontal desde el punto de anclaje."
L["Icon Size"] = "Tamaño de icono"
L["LEFT"] = "Izquierda"
L["Moderate"] = "Mediano"
L["Mute Toasts"] = "Silenciar ventanas de aviso"
L["Normal"] = true
L["Preview"] = "Vista previa"
L["Reset Position"] = "Restablecer posición"
L["RIGHT"] = "Derecha"
L["Show Anchor"] = "Mostrar ancla"
L["Show Minimap Icon"] = "Mostrar icono en minimapa"
L["Spawn Point"] = "Punto de anclaje"
L["Text"] = "Texto"
L["Title"] = "Título"
L["TOP"] = "Superior"
L["TOPLEFT"] = "Superior izquierda"
L["TOPRIGHT"] = "Superior derecha"
L["Vertical offset from the anchor point."] = "Cambiar el offset vertical desde el punto de anclaje."
L["Very Low"] = "Muy bajo"
L["X Offset"] = "Offset X"
L["Y Offset"] = "Offset Y"

