
local widget = widget ---@type Widget

function widget:GetInfo()
	return {
		name = "Dgun no deselect",
		desc = "Dont deselect the commander if it dgunned recently",
		license = "GNU GPL, v2 or later",
		layer = 0,
		enabled = true
	}
end

local lastDGun = 0
local lastCommanderID = 0
local marginTime = 0.5 -- seconds

local CMD_DGUN = CMD.DGUN
local spGetUnitDefID = Spring.GetUnitDefID
local clock = os.clock

local commanderDefs = {}


function widget:Initialize()
	for uDefID, uDef in pairs(UnitDefs) do
		if uDef.customParams and uDef.customParams.iscommander == '1' then
			commanderDefs[uDefID] = true
		end
	end
end

function widget:SelectionChanged(sel)
	local selectionSize = #sel
	if selectionSize == 1 and commanderDefs[spGetUnitDefID(sel[1])] then
		lastCommanderID = sel[1]
	elseif (selectionSize == 0) and lastCommanderID and (clock() - lastDGun < marginTime) then
		return {lastCommanderID}
	else
		lastCommanderID = nil
	end
end

function widget:CommandNotify(cmdID, cmdParams, cmdOpts)
	if cmdID == CMD_DGUN then
		lastDGun = clock()
	end
end
