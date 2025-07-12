--[[
-------------------------------------------------------------------------------
-- How to Export 
-------------------------------------------------------------------------------
When you finished making a profile and tested it you might want to share it with another people

1. Close game 
2. ProfileInstall > Export > select **World of Warcraft\WTF\Account\YOUR ACCOUNT NAME\SavedVariables\TellMeWhen.lua**
3. You will see created tree with checkboxes
4. Select 'Version' that's important or your groups after import can be disabled 
5. (optional) select in global:
5.1. CodeSnippets if you used in /tmw > Snippets > Global LUA Snippets and you want to share them 
5.2. NumGroups, Groups if you used in /tmw > Groups > Global groups and you want to share them. Doesn't recommended at all use Global groups because some old GGL profiles use them, it's not fully merged to Action yet
5.3. ShowGUIDs is just cosmetic setting in /tmw > General > Main Settings (or Main Options)
5.4. TextLayouts if you created different font in /tmw 
5.5. HelpSettings is just cosmetic setting in /tmw > General > Main Settings (or Main Options)
6. Make sure what you have UNCHECKED totally profileKeys because it does display YOUR GAME NICKNAME AND SERVER
7. Select in profiles only profiles which you want to share, please, don't select [Chesder] and mine [GGL] profiles to avoid conflicts with it 
8. Click Save and select path which you want to use to save a file, write name of file 'TellMeWhen.lua'

You can see option 'Skip import/export ActionDB', better have to enabled it. This don't will take in save DataBase of 'The Action' for exporting, so people who will import it will got default created this DB by ProfileUI instead of use your configure

-------------------------------------------------------------------------------
-- How to Import 
-------------------------------------------------------------------------------
1. Close game 
2. ProfileInstall > Import (from file) > Select file which was exported e.g. 'TellMeWhen.lua'
3. Select all checkboxes 
4. Click Save 
5. Answer 'Yes' on all questions 

You can see option 'Skip import/export ActionDB', it does nothing if in Export was selected it as enabled, otherwise it prevent write from exported file saved DataBase of 'The Action'
--]]