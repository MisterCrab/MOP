local A 				= Action
local Unit 				= A.Unit
local print				= A.Print

local debugprofilestop 	= debugprofilestop

local TestNF 
function TestYesCache(n)
    local t = debugprofilestop()
    local guid
    for i = 1, (n or 100) do
        guid = Unit("target"):InCC()
    end
    print(debugprofilestop() - t)
	return guid 
end

local TestAF 
function TestNoCache(n)
    local t = debugprofilestop()
    local guid
    for i = 1, (n or 100) do
        local unitID = "target"
        guid = Unit("target"):TestInCC()
    end
    print(debugprofilestop() - t) 
	return guid 
end

local collectgarbage = collectgarbage
function TestMemClean(n)
    local t = debugprofilestop()
    for i = 1, (n or 100) do
        collectgarbage()
    end
    print(debugprofilestop() - t)    
end 

function TestCustom(n, func)
    local t = debugprofilestop()
    local f
    for i = 1, (n or 100) do
        f = func()
    end
    print(debugprofilestop() - t)    
	return f
end 