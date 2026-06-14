-- OfficeManager.lua — Office visual progression based on portfolio value
-- Place in: ServerScriptService/TradingService/OfficeManager

local OfficeManager = {}

-- Office level thresholds (total profit required)
local OFFICE_LEVELS = {
	{ level = 0, name = "Phone",       profitRequired = 0 },
	{ level = 1, name = "Laptop",      profitRequired = 1000 },
	{ level = 2, name = "Dual Screen", profitRequired = 10000 },
	{ level = 3, name = "Multi Screen",profitRequired = 100000 },
	{ level = 4, name = "Executive",   profitRequired = 1000000 },
}

function OfficeManager.getOfficeLevel(totalProfit)
	local current = OFFICE_LEVELS[1]
	for i = #OFFICE_LEVELS, 1, -1 do
		if totalProfit >= OFFICE_LEVELS[i].profitRequired then
			current = OFFICE_LEVELS[i]
			break
		end
	end
	return current
end

function OfficeManager.getOfficeInfo(playerData)
	local totalProfit = 0
	if playerData.stats then
		totalProfit = (playerData.stats.totalProfit or 0) - (playerData.stats.totalLoss or 0)
	end

	local current = OfficeManager.getOfficeLevel(totalProfit)
	local nextLevel
	for _, ol in ipairs(OFFICE_LEVELS) do
		if ol.level == current.level + 1 then
			nextLevel = ol
			break
		end
	end

	return {
		level = current.level,
		name = current.name,
		nextLevel = nextLevel,
		progress = nextLevel and (totalProfit - current.profitRequired) / math.max(nextLevel.profitRequired - current.profitRequired, 1) or 1,
		updated = os.time(),
	}
end

function OfficeManager.updateOffice(playerData)
	local info = OfficeManager.getOfficeInfo(playerData)
	if info.level ~= playerData.officeLevel then
		local oldLevel = playerData.officeLevel or 0
		playerData.officeLevel = info.level
		return {
			upgraded = true,
			oldLevel = oldLevel,
			newLevel = info.level,
			newName = info.name,
		}
	end
	return { upgraded = false }
end

return OfficeManager
