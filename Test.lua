-- Tracker functions
function huntTracker:Add()
	if gmcp.Char.Items.Add.location == "room" then
		local tempTable = gmcp.Char.Items.Add.item
		if tempTable.attrib == "m" and table.contains(huntVar.userAreaDenizens, tempTable.name) then
			local addID = tempTable.id
			for k, v in ipairs(huntVar.userAreaDenizens) do
				if tempTable.name == v then
					insertID(addID, k)
					break
				end
			end
			if huntVar.targetGone then
				targetSet()
			end
		end
	end
end

function huntTracker:Remove()
	if gmcp.Char.Items.Remove.location == "room" then
		local removeID = gmcp.Char.Items.Remove.item.id
		if huntVar.currentTarget == removeID then
			huntVar.targetGone = true
			if table.size(huntVar.targetQueue) >= 1 then
				targetSet()
			end -- end if table.size
		elseif table.contains(huntVar.targetQueue, removeID) then
			for k,v in pairs(huntVar.targetQueue) do
				if v == removeID then
					table.remove(huntVar.targetQueue, k)
					table.remove(huntVar.targetPriority, k)
					if target ~= huntVar.currentTarget then
						huntVar.targetGone = true
						insertID(huntVar.currentTarget, huntVar.currentPriority)
						targetSet()
					end
					break
				end -- end if v == removeID
			end -- end for k,v
		end -- end if huntVar.currentTarget == removeID
	end -- end if location == "room"
end -- end function huntTracker:Remove()

function huntTracker:List()
	if gmcp.Char.Items.List.location == "room" then	
		local tempTable = gmcp.Char.Items.List
		local size = table.size(tempTable.items)
		local targGot = false
		local targChange = true
		huntVar.targetGone = true
		huntVar.targetQueue = {}
		huntVar.targetPriority = {}
		for k,v in ipairs(tempTable.items) do
			local tempID = v.id
			if v.attrib == "m" and table.contains(huntVar.userAreaDenizens, v.name) then
				for ak, av in ipairs(huntVar.userAreaDenizens) do
					if huntVar.currentTarget == tempID then
						huntVar.targetGone = false
						targChange = false
					end -- end if huntVar.currentTarget
					if v.name == av and huntVar.currentTarget ~=tempID and not table.contains(huntVar.targetQueue, tempID) then
						insertID(tempID, ak)
						break
					end -- end if v.name
				end -- end for ak
			end -- end v.attrib
		end -- end for k
		if targChange then
			targetSet()
		end
	end -- end if location
end -- end function huntTracker:List()

function huntTracker:Info()
	if huntVar.currentArea ~= gmcp.Room.Info.area then
		huntVar.currentArea = gmcp.Room.Info.area
		if not table.contains(huntVar.userAreaList, huntVar.currentArea) and table.contains(fixedHuntVar.areaList, huntVar.currentArea) then
			table.insert(huntVar.userAreaList, huntVar.currentArea)
			huntVar.userAreaList[huntVar.currentArea] = huntTableCopy(fixedHuntVar.areaList[huntVar.currentArea])
		elseif not table.contains(fixedHuntVar.areaList, huntVar.currentArea) then
			fixedHuntVar.areaList[huntVar.currentArea] = {}
			huntVar.userAreaList[huntVar.currentArea] = {}
		end
		fixedHuntVar.areaDenizens = fixedHuntVar.areaList[huntVar.currentArea]
		huntVar.userAreaDenizens = huntVar.userAreaList[huntVar.currentArea] or {}
		huntTracker:List()
	end
end -- end function huntTracker:Info()

function huntTracker:sysLoadEvent()
	local sep
	local homeDir = getMudletHomeDir()
	if string.char(homeDir:byte()) == "/" then 
		sep = "/" else sep = "\\"
	end
	table.load(homeDir.. sep .. huntVar.fileName..".lua", huntVar.userAreaList)
	table.load(homeDir.. sep .. huntVar.fileNameFull..".lua", fixedHuntVar.areaList)
	huntTableCheck()
	cecho("<white>Hunting System Loaded\n")
end

function huntTracker:sysExitEvent()
	huntTableCheck()
	local sep 
	local homeDir = getMudletHomeDir()
	if string.char(homeDir:byte()) == "/" then 
		sep = "/" else sep = "\\"
	end
	table.save(homeDir.. sep .. huntVar.fileName..".lua", huntVar.userAreaList)
	table.save(homeDir.. sep .. huntVar.fileNameFull..".lua", fixedHuntVar.areaList)
	cecho("<white>Hunting System Saved\n")
end

function insertID(id, priority)
	local tableSize = table.size(huntVar.targetPriority)
	local inserted = false
	if not table.contains(huntVar.targetQueue, id) then
		if tableSize == 0 then
			table.insert(huntVar.targetQueue, id)
			table.insert(huntVar.targetPriority, priority)
		end
		if tableSize > 0 then
			for i = 1, tableSize do
				if priority < huntVar.targetPriority[i] then
					table.insert(huntVar.targetQueue, i, id)
					table.insert(huntVar.targetPriority, i, priority)
					inserted = true
					break
				end -- end if priority
			end -- end for
			if not inserted then
				table.insert(huntVar.targetQueue, id)
				table.insert(huntVar.targetPriority, priority)
			end -- end if inserted = false
		end -- end if not table.contains
	end -- end if tableSize
end -- end function

function targetSet()
	if not table.is_empty(huntVar.targetQueue) then				
		huntVar.currentTarget = huntVar.targetQueue[1]
		huntVar.currentPriority = huntVar.targetPriority[1]
		table.remove(huntVar.targetQueue, 1)
		table.remove(huntVar.targetPriority, 1)
		target = huntVar.currentTarget
		huntVar.targetGone = false
		if huntVar.echo then
			if huntVar.echoto == "" then
				cecho("<blue:green>Target: "..target)
				send("settarget " .. target)
				send('pt Target: '..target)
			else
				send(huntVar.echoto.." Target: "..target)
			end
		end
	end
end

function showHuntTargs()
	if table.contains(fixedHuntVar.areaList, huntVar.currentArea) and table.size(fixedHuntVar.areaList[huntVar.currentArea]) > 0 then
		for i, j in ipairs(fixedHuntVar.areaDenizens) do
			local check = "   "
			local raise = "   "
			local lower = "   "
			local checked = false
			if table.contains(huntVar.userAreaDenizens, j) then
				check = " X "
				checked = true
			end
			cecho("<dark_slate_gray>[")
			fg("white")
			echoLink(check, "toggleTarget(\""..j.."\")", "Click to add or remove "..j.." from the list!", true)
			cecho("<dark_slate_gray>] [")
			if i > 1 then
				raise = " U "
				echoLink(raise, "swapPriority("..i..", "..i.."-1)", "Click to move "..j.." up the priority list!", true)
			else
				echo(raise)
			end
			cecho("<dark_slate_gray>] [")
			if i < table.maxn(fixedHuntVar.areaDenizens) then
				lower = " D "
				echoLink(lower, "swapPriority("..i..", "..i.."+1)", "Click to move "..j.." down the priority list.", true)
			else
				echo(lower)
			end
			cecho("<dark_slate_gray>] ")
			if checked then
				cecho("<white>"..j.."\n")
			else
				cecho("<light_slate_grey>"..j.."\n")
			end
		end
		cecho("<dark_slate_gray>[")
		fg("green")
		echoLink(" Check All ", "toggleAll(\"on\")", "Click to check all targets in the area", true)
		cecho("<dark_slate_gray>] [")
		fg("red")
		echoLink(" Uncheck All ", "toggleAll(\"off\")", "Click to check all targets in the area", true)
		cecho("<dark_slate_gray>]\n")
		send(" ")
	else
		cecho("<white>No hunting list found for this area!\n")
	end
end

function toggleTarget(name)
	if table.contains(huntVar.userAreaDenizens, name) then
		for k, v in ipairs(huntVar.userAreaDenizens) do
			if v == name then
				table.remove(huntVar.userAreaDenizens, k)
			end
		end
	else
		local position = 0
		for i, j in ipairs(fixedHuntVar.areaDenizens) do
			if j == name then
				table.insert(huntVar.userAreaDenizens, position+1, name)
			elseif table.contains(huntVar.userAreaDenizens, j) then
				position = position + 1
			end
		end
	end
	showHuntTargs()
end

function swapPriority(numToSwap, num)
	local tempName = ""
	if fixedHuntVar.areaDenizens[numToSwap] == huntVar.userAreaDenizens[numToSwap] and fixedHuntVar.areaDenizens[num] == huntVar.userAreaDenizens[num] then
		tempName = huntVar.userAreaDenizens[numToSwap]
		huntVar.userAreaDenizens[numToSwap] = huntVar.userAreaDenizens[num]
		huntVar.userAreaDenizens[num] = tempName
	end
	tempName = fixedHuntVar.areaDenizens[numToSwap]
	fixedHuntVar.areaDenizens[numToSwap] = fixedHuntVar.areaDenizens[num]
	fixedHuntVar.areaDenizens[num] = tempName
	showHuntTargs()
end

function toggleAll(mode)
	if mode == "on" then
		for k, v in ipairs(fixedHuntVar.areaDenizens) do
			if huntVar.userAreaDenizens[k] ~= v then
				table.insert(huntVar.userAreaDenizens, k, v)
			end
		end
	else
		for i = 1, table.maxn(huntVar.userAreaDenizens) do
			table.remove(huntVar.userAreaDenizens, 1)
		end
	end	
	showHuntTargs()
end

function huntTableCheck()
	for k, v in pairs(areaList) do
		if not table.contains(huntVar.userAreaList, k) then
			fixedHuntVar.areaList[k] = huntTableCopy(areaList[k])
			huntVar.userAreaList[k] = huntTableCopy(areaList[k])
		end
	end
end

function huntTableCopy(t)
  local t2 = {}
  for k,v in pairs(t) do
    t2[k] = v
  end
  return t2
end

function huntToggle(mode)
	if mode == "on" then
		huntVar.on = true
		cecho("<white>Hunting Script has been turned on.\n")
	else
		huntVar.on = false
		cecho("<white>Hunting Script has been turned off.\n")
	end
end

function addTargets()
	cecho("<white>Denizens that can be added:")
	for k, v in ipairs(gmcp.Char.Items.List.items) do
		if v.attrib == "m" then
			if not table.contains(fixedHuntVar.areaList[huntVar.currentArea], v.name) then
				local add = " + "
				cecho("\n<dark_slate_gray>[")
				echoLink(add, [[addTarg("]]..v.name..[[")]], "Click to add "..v.name.." to the denizen table!", true)
				cecho("<dark_slate_gray>] <white>"..v.name)
			end
		end
	end
	send(" ")
end

function addTarg(fullName)
	table.insert(fixedHuntVar.areaList[huntVar.currentArea], fullName)
	table.insert(huntVar.userAreaList[huntVar.currentArea], fullName)
	addTargets()
end

function removeTargets()
	cecho("<white>Denizens that can be removed:")
	for k, v in ipairs(fixedHuntVar.areaList[huntVar.currentArea]) do
		local remove = " - "
		cecho("\n<dark_slate_gray>[")
		echoLink(remove, [[removeTarg("]]..v..[[")]], "Click to remove "..v.." from the denizen table!", true)
		cecho("<dark_slate_gray>] <white>"..v)
	end
	send(" ")
end

function removeTarg(name)
	local index = table.index_of(fixedHuntVar.areaList[huntVar.currentArea], name)
	table.remove(fixedHuntVar.areaList[huntVar.currentArea], index)
	table.remove(huntVar.userAreaList[huntVar.currentArea], index)
	removeTargets()
end
