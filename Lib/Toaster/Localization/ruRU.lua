local ADDON_NAME, private = ...

local _G = getfenv(0)
local L = _G.LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "ruRU", false)

if not L then return end

L["Background"] = "Фон"
L["BOTTOM"] = "Внизу"
L["BOTTOMLEFT"] = "Внизу слева"
L["BOTTOMRIGHT"] = "Внизу справа"
L["CENTER"] = "Центр"
L["Drag to set the spawn point for toasts."] = "Переместите для установки места появления."
L["Emergency"] = "Крайняя необходимость"
L["Floating Icon"] = "Плавающий значок"
L["Hide Toasts"] = "Скрыть уведомление"
L["High"] = "Высокая"
L["Horizontal offset from the anchor point."] = "Горизонтальное смещение точки появления."
L["Icon Size"] = "Размер значка"
L["LEFT"] = "Слева"
L["Moderate"] = "Умеренный"
L["Mute Toasts"] = "Заглушить уведомление"
L["Normal"] = "Нормальный"
L["Preview"] = "Просмотр"
L["Reset Position"] = "Сброс"
L["RIGHT"] = "Справа"
L["Show Anchor"] = "Показать привязку"
L["Show Minimap Icon"] = "Иконка у мини-карты"
L["Spawn Point"] = "Место появления"
L["Text"] = "Текст"
L["Title"] = "Заголовок"
L["TOP"] = "Вверху"
L["TOPLEFT"] = "Вверху слева"
L["TOPRIGHT"] = "Вверху справа"
L["Vertical offset from the anchor point."] = "Вертикальное смещение точки появления."
L["Very Low"] = "Очень низкий"
L["X Offset"] = "Смещение по X"
L["Y Offset"] = "Смещение по Y"

