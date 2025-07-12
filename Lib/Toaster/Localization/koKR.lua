local ADDON_NAME, private = ...

local _G = getfenv(0)
local L = _G.LibStub("AceLocale-3.0"):NewLocale(ADDON_NAME, "koKR", false)

if not L then return end

L["Background"] = "배경"
L["BOTTOM"] = "하단"
L["BOTTOMLEFT"] = "좌측하단"
L["BOTTOMRIGHT"] = "우측하단"
L["CENTER"] = "중앙"
L["Drag to set the spawn point for toasts."] = "드래그해서 팝업창의 생성 지점을 설정하세요."
L["Emergency"] = "긴급"
L["Floating Icon"] = "아이콘 분리"
L["Hide Toasts"] = "Toasts 숨기기"
L["High"] = "높음"
L["Horizontal offset from the anchor point."] = "고정 위치로부터 수평으로 이동합니다."
L["Icon Size"] = "아이콘 크기"
L["LEFT"] = "좌측"
L["Moderate"] = "보통"
L["Mute Toasts"] = "Toasts 음소거"
L["Normal"] = "일반"
L["Preview"] = "미리보기"
L["Reset Position"] = "위치 초기화"
L["RIGHT"] = "우측"
L["Show Anchor"] = "고정기 표시"
L["Show Minimap Icon"] = "미니맵 아이콘 표시"
L["Spawn Point"] = "생성 지점"
L["Text"] = "문자"
L["Title"] = "제목"
L["TOP"] = "상단"
L["TOPLEFT"] = "좌측상단"
L["TOPRIGHT"] = "우측상단"
L["Vertical offset from the anchor point."] = "고정 위치로부터 수직으로 이동합니다."
L["Very Low"] = "매우 낮음"
L["X Offset"] = "X 좌표"
L["Y Offset"] = "Y 좌표"

