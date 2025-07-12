local _G, pairs, type, tostring, print =
	  _G, pairs, type, tostring, print
	  
function FindG(s)
	for k, v in pairs(_G) do 
		if type(s) == "string" and type(v) == "string" and v:lower():match(s:lower()) then 
			print(k .. " contain: " .. v)
		end 
		
		if type(s) == "number" and type(v) == "number" and s == v then 
			print(k .. " contain: " .. v)
		end 
	end 
end 

function FindGObj(s)
	for k, v in pairs(_G) do 
		if type(s) == "string" then 
			local current = tostring(k) 
			if current and current:lower():match(s:lower()) then 
				print(current .. " contain: " .. s)
			end 
		end 
	end 
end 

-- Frame's black list:
-- local cMetatableKeyBlackList = {"Hide", "Show", "SetShown", "CreateFontString", "ClearAllPoints", "DesaturateHierarchy", "CreateMaskTexture", "CreateAnimationGroup", "CreateLine", "CreateTexture", "GetRegions", "GetChildren", "GetParent"}
function tDump(toPush, fromPush, cMetatable, cMetatableKeyBlackList)
	-- Copies table with dumped function's return from metatables
	for k, v in pairs(fromPush) do
		if type(v) == "table" then 
			toPush[k] = tDump(type(toPush[k]) == "table" and toPush[k] or {}, v, cMetatable, cMetatableKeyBlackList)
		else 
			toPush[k] = v 
		end 
	end
	
	if cMetatable then 
		-- Dump and push all function returns 
		local mt = getmetatable(fromPush)
		if mt then 
			for k, v in pairs(mt.__index) do 
				if type(v) == "function" and (not cMetatableKeyBlackList or not tContains(cMetatableKeyBlackList, k)) then
					local t = { pcall(v, fromPush) }
					if t[1] then 
						table.remove(t, 1)
						for i = 1, select("#", t), -1 do
							local val = select(i, t)
							if val ~= nil and i > 1 then 
								toPush[k] = {}
								break 
							end 
						end 
						
						for i, val in ipairs(t) do 
							if val ~= nil then 
								if type(val) == "table" then 
									if next(val) then 
										if type(toPush[k]) == "table" then 
											toPush[k][i] = tDump({}, val, cMetatable, cMetatableKeyBlackList)
										else
											toPush[k] = tDump({}, val, cMetatable, cMetatableKeyBlackList)
										end 
									end 
								else 
									if type(toPush[k]) == "table" then 
										toPush[k][i] = val 
									else 
										toPush[k] = val
									end 
								end 
							end 
						end 
					end 
				end 
			end 
			
			setmetatable(toPush, mt) 
		end  
	end
	
	return toPush
end 

function tShrinkKeyValues(original, fromRemove)
	-- Removes in original table all same key-val fromRemove
	for k, v in pairs(fromRemove) do 
		if type(v) == "table" then 
			tShrinkKeyValues(original[k], v)
		elseif original[k] == v then 
			original[k] = nil 
		end 
	end 
end 

function tShrinkEmptyTables(t)
	-- Removes empty and userdata tables 
	for k, v in pairs(t) do 
		if type(v) == "table" then 
			local i, tabl = next(v)
			if not tabl or type(tabl) == "userdata" then 
				t[k] = nil
				tShrinkEmptyTables(t)
			else 
				tShrinkEmptyTables(t[k])
			end 
		end 
	end 
end 

function tDumpDiff(t1, t2, cMetatable, cMetatableKeyBlackList)
	local t = {}
	
	-- Leaves original 't1' and 't2' untouched
	tDump(t, t1, cMetatable, cMetatableKeyBlackList)
	tDump(t, t2, cMetatable, cMetatableKeyBlackList)
	
	-- Removes in original 't' table all same key-val from 't1'
	tShrinkKeyValues(t, t1)
	
	-- Removes empty tables 
	tShrinkEmptyTables(t)
	
	-- t1 + t2 = t - t1 = t  
	return t
end 