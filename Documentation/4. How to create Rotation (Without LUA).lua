--[[
-------------------------------------------------------------------------------
-- Introduction 
-------------------------------------------------------------------------------
If you use lua then you can skip it. If you didn't read 1. Introduction.lua you have to read before continue

-------------------------------------------------------------------------------
-- №1 Create for profile groups
-------------------------------------------------------------------------------
1. First you need create own profile:
Write in chat "/tmw options" > Click on 'General' > 'Main settings' (or 'Main options') > at the top you will see dropdown menu abd below 'Write name'
Write your own name and press 'Enter'
Then you can (recommend) copy template '[GGL] Basic' by overwrite current profile 

It will apply for you content of copied profile which you can edit and skip next steps 

2. The most popular is to create 2 groups with names PvE and PvP
Write in chat "/tmw options" > Click on 'Groups' > '+' > Write your own name 
Set required for yourself number of icons and rows with scale and position

-------------------------------------------------------------------------------
-- №2 Create content and logic for profile groups
-------------------------------------------------------------------------------
If you finished with №1 and you see at the left upper corner group with name "Shown Main" and its at top above any other groups then you did all correctly, if not then return to look above

TellMeWhen interface of edit is very easy and allows make very solid functional without lua skills with intuite understand able menu

1. You have to create any icon in new group of PvE or PvP for example. Go to "/tmw options" > Group > "+" > Add new group with own name which you will use to build frames with logic like "PvE"
2. Right click on any box of created group > select type Icon, like 'Cooldown', and write below ID of 'What to track' with settings like 'Range Check'
3. Select enabled 'Hide Always'
4. For more logic you have to use 'Conditions' tab of this icon where you can click '+' and use any suggested conditions which you want
5. After conditions are done drag and move this icon to "Meta Icon" of the "Shown Group" and select from opened menu "Add to this meta"
6. Make sure what created icon has "read able" / supported texture for launcher

Which "Meta Icon" I have to use? 
Mostly for begin is enough #3 ([3]) which is Rotation, you can look 1. Introduction.lua about what and which meta does for explain

Priority:
Rotation is based on priority: 1. Spell > 2. Spell > 3. Spell > and etc.. 
To change it and edit whenver you need, you have to right click on "Meta Icon" which you used for adding created icons and there are you will see some kind of list which exactly does priority from top to down
You can move any elements there as you need 

Make sure what each "Meta Icon" in "Shown Main" has UNCHECKED "Hide always"

How to get at the middle of the center on my screen display of the next spell / action?
Create new group and create there icon with type "Meta Icon"
Drag from "Shown Main" required "Meta Icon" to created at the center "Meta Icon" and click "Add to meta"

Is that's all? 
Probably yes because for TellMeWhen no any guide or video movie education about how to because interface is 'click able to learn', you can ask help by people who use TMW about how to configure your conditions if you're confused
You also can use this guide to edit and modify existed profiles which uses by 'The Action' like [GGL] profiles
--]]

