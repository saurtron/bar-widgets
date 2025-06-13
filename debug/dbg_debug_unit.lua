
local widget = widget ---@type Widget

function widget:GetInfo()
	return {
		name      = "Debug unit",
		desc      = "Debug units",
		layer     = -999990,
		enabled   = true,
	}
end

-- for https://github.com/beyond-all-reason/RecoilEngine/issues/2379

local searchUnit = 16121
local uiSec = 0
local sSec = 0
local currentUnit = nil
local currentUnit2 = nil

local searchUnit2 = 31345

local prevOrderTag = nil
local prevPath = nil
local lastMoveData = nil
local ColorString = Spring.Utilities.Color.ToString

local function MarkUnit(unitID)
	local x, y, z = Spring.GetUnitPosition(unitID)
       	--Spring.MarkerAddPoint(x, y, z, ColorString(0.5, 1.0, 0.5) .. "Here", false)
       	Spring.MarkerAddPoint(x, y, z)
end

function widget:Initialize()
	if Spring.ValidUnitID(searchUnit) then
		Spring.Echo("Found", searchUnit)
		if not currentUnit then
			MarkUnit(searchUnit)
		end
		currentUnit = searchUnit
		--Spring.SelectUnit(searchUnit)
	end
	if Spring.ValidUnitID(searchUnit2) then
		if not currentUnit2 then
			Spring.Echo("Found Target", searchUnit2, Spring.GetUnitIsDead(searchUnit2), Spring.GetUnitDefID(searchUnit2), Spring.GetUnitPosition(searchUnit2))
			MarkUnit(searchUnit2)
			currentUnit2 = searchUnit2
			Spring.SelectUnit(searchUnit2)
		end
	end
end

function widget:Shutdown()
end

local function IsNewOrder(order)
	if not prevOrderTag or order.tag ~= prevOrderTag then
		prevOrderTag = order.tag
		return true
	end
end

local function IsNewPath(path)
	if not prevPath or #prevPath ~= #path or prevPath[1][1] ~= path[1][1] then
		prevPath = path
		return true
	end
end

local function PrintPath(path)
	local n = #path
	local p1 = path[1]
	local p2 = path[n]
	Spring.Echo("* path", p1[1], p1[3], "->", p2[1], p2[3])
end

local function PrintCommand(cmd)
	Spring.Echo(cmd.id, CMD[cmd.id], Json.encode(cmd.params), cmd.options and cmd.options.coded)

end

local function DrawUnitRing(unitID)
	gl.PushMatrix()
	local x, y, z = Spring.GetUnitPosition(unitID)
	gl.Color(1, 1, 1, 1)

	gl.Translate(x, y, z-5)
	gl.Billboard()
	gl.Translate(0, 0, 0)

	gl.LineWidth(1.0)
	local size = 80

	gl.BeginEnd(GL.LINE_STRIP, function()
		gl.Vertex(-size,-size, 10)
		gl.Vertex(-size,size, 10)
		gl.Vertex(size,size, 10)
		gl.Vertex(size,-size, 10)
		gl.Vertex(-size,-size, 10)
	end)
	gl.LineWidth(1.0)
	gl.PopMatrix()
end

function widget:DrawWorldPreUnit()
	if Spring.ValidUnitID(searchUnit) then
		DrawUnitRing(searchUnit)
	end
	if Spring.ValidUnitID(searchUnit2) then
		DrawUnitRing(searchUnit2)
	end
end

function widget:GameFrame(dt)
	if gf == 48101 then
		Spring.SendCommands("setspeed 1")
	end

	-- check if currentUnit is gone
	if currentUnit and not Spring.ValidUnitID(currentUnit) then
		Spring.Echo("Lost")
		currentUnit = nil
		prevPath = nil
		return
	end
	if currentUnit2 and not Spring.ValidUnitID(currentUnit2) then
		Spring.Echo("Lost Target", currentUnit2)
		currentUnit2 = nil
		return
	end
	--local targetUnit = currentUnit
	local targetUnit = searchUnit
	if not targetUnit or not Spring.ValidUnitID(targetUnit)then
		return
	end
	-- print commands
	local unitCommands = Spring.GetUnitCommands(targetUnit, 5)
	if #unitCommands > 0 then
		if IsNewOrder(unitCommands[1]) then
			PrintCommand(unitCommands[1])
		end
	end
	-- print path
	local path = Spring.GetUnitEstimatedPath(targetUnit)
	if path and #path > 2 and IsNewPath(path) then
		PrintPath(path)
	end
	-- print movedata
	local moveData = Json.encode(Spring.GetUnitMoveTypeData(targetUnit))
	if moveData and not lastMoveData or lastMoveData ~= moveData then
		Spring.Echo(moveData)
		lastMoveData = moveData
	end
end

function widget:Update(dt)
	uiSec = uiSec + dt

	if not currentUnit then
		widget:Initialize()
	end
end

function widget:SelectionChanged(sel)
	if currentUnit and currentUnit ~= searchUnit and #sel == 0 then
		Spring.Echo("Release", currentUnit)
		currentUnit = nil
		prevPath = nil
		return
	end
	if sel and next(sel) and #sel == 1 and not currentUnit then
		Spring.Echo(sel[1])
		Spring.Echo("Lock", sel[1])
		currentUnit = sel[1]
		MarkUnit(currentUnit)
	end
end

