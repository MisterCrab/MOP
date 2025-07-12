local ADDON_NAME, private = ...

local _G = getfenv(0)
local L = _G.LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "zhTW", false)

if not L then return end

L["Background"] = "背景"
L["BOTTOM"] = "下"
L["BOTTOMLEFT"] = "左下"
L["BOTTOMRIGHT"] = "右下"
L["CENTER"] = "中央"
L["Drag to set the spawn point for toasts."] = "拖曳來設定提醒的顯現點。"
L["Emergency"] = "緊急"
L["Floating Icon"] = "浮動圖標"
L["Hide Toasts"] = "隱藏提醒"
L["High"] = "高"
L["Horizontal offset from the anchor point."] = "定位點的水平偏移。"
L["Icon Size"] = "圖標尺寸"
L["LEFT"] = "左"
L["Moderate"] = "中等"
L["Mute Toasts"] = "提醒靜音"
L["Normal"] = "一般"
L["Preview"] = "預覽"
L["Reset Position"] = "重設位置"
L["RIGHT"] = "右"
L["Show Anchor"] = "顯示定位點"
L["Show Minimap Icon"] = "顯示小地圖圖標"
L["Spawn Point"] = "顯現點"
L["Text"] = "文字"
L["Title"] = "標題"
L["TOP"] = "上"
L["TOPLEFT"] = "左上"
L["TOPRIGHT"] = "右上"
L["Vertical offset from the anchor point."] = "定位點的垂直偏移。'"
L["Very Low"] = "非常低"
L["X Offset"] = "X軸偏移"
L["Y Offset"] = "Y軸偏移"

