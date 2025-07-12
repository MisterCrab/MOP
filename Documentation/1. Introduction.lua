--[[
-------------------------------------------------------------------------------
-- Introduction 
-------------------------------------------------------------------------------
This documentation describes the behavior and methods of writing user profiles 


-------------------------------------------------------------------------------
-- Conception and Basics
-------------------------------------------------------------------------------
TellMeWhen initiates the frame editor with self API, and 'The Action' loads own API

API (Application Programming Interface)
Both TellMeWhen and The Action API's are used for profiles and they are shared between themselves
You can't edit these addons (but you can edit API through own snippets) because in the next time of the update through ProfileInstall they will be overwritten by original version
If you want to use original updates and at the same time own changes in the addons or API then you have to use 'Global Snippets' (look about that below, in the title 'About profile')

About TMW.db
This is DataBase is used to store your profile and his settings for TellMeWhen 

About DataBase 
DataBase stores on the following path **World of Warcraft\WTF\Account\YOUR ACCOUNT NAME\SavedVariables\TellMeWhen.lua** which is used to Export and share your all profiles, settings with other people by ProfileInstall and they can Import it by your exported file (we will return to this moment at the end of the documentation steps)

About profile 
When you login in game you can open TMW by chat command /tmw options and enter in TMW interface. Then go to 'General' tab then 'Main Options' (or 'Main Settings') and here is at the top you will see dropdown menu with current name of profile and below options 'Write Name' (to create new profile), 'Copy', 'Delete'. This is TMW.db
Also there are 'LUA Snippets' (or just 'Snippets') tab which will be used for 'The Action' and you're not limited to use it only for that, you can use it for HeroLib API and any your own lua. This is optional because you can create profile without known lua skills 
Snippets are 'Profile Snippets' and 'Global Snippets':
* 'Profile Snippets' is local which means what they are attached only to their profile 
* 'Global Snippets' is super global (TMW.db.global) which means they are attached for any profile / all profiles! 
If you want to use custom API which spreads between your profiles then you have to use 'Global Snippets', make sure what your code written in global doesn't conflict and loads with other (not yours) profiles otherwise it can create conflict, errors, incorrect behavior..


Profile must have specific one local group. The groups are same like 'Profile Snippets' and 'Global Snippets' - groups are local (for this profile) and global (for all profiles)
This specific group must have name "Shown Main" without quotes, it must contain at least 8 icons inside and should be in the upper left corner of the screen, like [1][2][3][4][5][6][7][8] ([1]-[8] columns in the single one row), type of group must be "Icon"
* [1] is AntiFake CC rotation
* [2] is AntiFake Interrupt rotation 	( @target, @focus, @mouseover, @targettarget, @focustarget; 											supports: racial and class's interrupts			                                 )
* [3] is Rotation 						( @target, @focus, @mouseover, @targettarget, @focustarget; 											supports: all actions + Universal1-10			                                 )
* [4] is Secondary rotation 			( @target, @focus, @mouseover, @targettarget, @focustarget; 											supports: all actions + Universal1-10			                                 )
* [5] is Trinket rotation 				( @player; 																								supports: racial and class spells which can remove CC                            )
* [6] is Passive rotation 				( 1th unit index: @arena1, @raid1, @party1, @arenapet1, @raidpet1, @partypet1 + Universal1-10 Unit1 + additional abilities that may appear in the launcher with note meta slot 6 or A[6] )
* [7] is Passive / Active rotation 		( 2th unit index: @arena2, @raid2, @party2, @arenapet2, @raidpet2, @partypet2 + Universal1-10 Unit2) / AntiFake CC Focus rotation
* [8] is Passive / Active rotation 		( 3th unit index: @arena3, @raid3, @party3, @arenapet3, @raidpet3, @partypet3 + Universal1-10 Unit3) / AntiFake Interrupt Focus rotation
* [9] is Passive / Active rotation 		( 4th unit index: @arena4, @raid4, @party4, @arenapet4, @raidpet4, @partypet4 + Universal1-10 Unit4) / AntiFake CC2 rotation
* [10] is Passive / Active rotation 	( 5th unit index: @arena5, @raid5, @player, @arenapet5, @raidpet5, @pet 	  + Universal1-10 Unit5) / AntiFake CC2 Focus rotation
Passive rotation doesn't require START button use like it does [1] -> [5] or Active rotations in [7] -> [10]
"Shown Main" in group settings must have x-29, y12, scale 60% and both padding to the left upper corner 

This group must be first group at the top of group list e.g. TellMeWhen_Group1 ("Shown Main"). Rest after that doesn't matter at all, you can use own groups like to display at the middle of the center on your screen next rotation action to use with graphic mode PvE PvP and etc 
Each icon in TellMeWhen_Group1 group must be as 'meta icon' type (this is green eye)

Also your name of profile must be different than that ProfileInstall Import (from server) has, because if your name will be same it will be overwritten by server version, use own name, like "[AUTHOR] My Profile"


Hard to figure? 
Let's make it easier, I prepared template profile named '[GGL] Template', you can create new profile with own name and then use 'Copy' from '[GGL] Template' which will make for you prepared for 'The Action' API that group. So when all done you can build own routine now.
You can download this profile via Profile Install > Import (from server) but if this button is not enabled you can import any other profile to cut and paste specified requirements into new profile or just contact us.


-------------------------------------------------------------------------------
-- Summarize
-------------------------------------------------------------------------------
Begin starts by profile create: Write in chat /tmw options go to 'General' then 'Main Options' (or 'Main Settings') and there are at the top you will see dropdown menu with current name of profile and below options 'Write Name' (to create new profile), 'Copy'

Use template profile named '[GGL] Template' with own name either keep in mind and follow by the next tips:
1. Your profile name must be different than it have loaded from ProfileInstall > Import (*) TellMeWhen, otherwise it will be overwritten
2. Your profile must have first group with name "Shown Main"
3. "Shown Main" must have 8 or more icons with types "meta icon" and group type "Icon" in only 1 row at the left upper corner of your screen
4. "Shown Main" in group settings must have x-29, y12, scale 60% and both paddings to the left upper corner 
--]]