-- Perks.lua — Perk definitions and unlock logic
-- Place in: ServerScriptService/TradingService/Perks

local XPManager = require(script.Parent.XPManager)

local Perks = {}

-- Perk definitions
local PERK_DEFS = {
	extra_slot_1 = {
		name = "Portfolio +1",
		description = "1 extra portfolio slot",
		cost = 1,
		minLevel = 1,
	},
	extra_slot_2 = {
		name = "Portfolio +3",
		description = "3 extra portfolio slots",
		cost = 3,
		minLevel = 5,
	},
	short_selling = {
		name = "Short Selling",
		description = "Profit when stocks go down",
		cost = 2,
		minLevel = 5,
	},
	limit_orders = {
		name = "Limit Orders",
		description = "Buy/sell at target price",
		cost = 2,
		minLevel = 10,
	},
	data_premium = {
		name = "Premium Data",
		description = "Advanced charts and indicators",
		cost = 3,
		minLevel = 5,
	},
	stop_loss = {
		name = "Stop-Loss",
		description = "Auto-sell if price drops to X",
		cost = 2,
		minLevel = 15,
	},
	take_profit = {
		name = "Take-Profit",
		description = "Auto-sell if price rises to X",
		cost = 1,
		minLevel = 15,
	},
	copy_trade_view = {
		name = "View Top Portfolios",
		description = "See leader portfolios (15min delay)",
		cost = 2,
		minLevel = 5,
	},
	club_create = {
		name = "Create Club",
		description = "Start your own trading club",
		cost = 5,
		minLevel = 10,
	},
	options_basic = {
		name = "Basic Options",
		description = "Calls and Puts trading",
		cost = 5,
		minLevel = 25,
	},
}

function Perks.getAllPerks()
	return PERK_DEFS
end

function Perks.getPerk(perkId)
	return PERK_DEFS[perkId]
end

-- Check if player has a specific perk
function Perks.hasPerk(playerData, perkId)
	for _, perk in ipairs(playerData.perks or {}) do
		if perk.name == perkId then
			return true
		end
	end
	return false
end

-- Get perks available for player to unlock
function Perks.getAvailablePerks(playerData)
	local available = {}
	local availablePoints = XPManager.getAvailablePerkPoints(playerData)

	for perkId, def in pairs(PERK_DEFS) do
		if not Perks.hasPerk(playerData, perkId) then
			local canAfford = availablePoints >= def.cost
			local meetsLevel = (playerData.level or 1) >= def.minLevel
			table.insert(available, {
				id = perkId,
				name = def.name,
				description = def.description,
				cost = def.cost,
				minLevel = def.minLevel,
				canUnlock = canAfford and meetsLevel,
				blockedReason = not meetsLevel and string.format("Requires level %d", def.minLevel)
					or not canAfford and string.format("Need %d more perk points", def.cost - availablePoints),
			})
		end
	end

	return available
end

-- Unlock a perk
function Perks.unlockPerk(playerData, perkId)
	local def = PERK_DEFS[perkId]
	if not def then
		return false, "Unknown perk: " .. tostring(perkId)
	end

	if Perks.hasPerk(playerData, perkId) then
		return false, "Perk already unlocked"
	end

	if (playerData.level or 1) < def.minLevel then
		return false, string.format("Requires level %d", def.minLevel)
	end

	local availablePoints = XPManager.getAvailablePerkPoints(playerData)
	if availablePoints < def.cost then
		return false, string.format("Need %d perk points (have %d)", def.cost, availablePoints)
	end

	table.insert(playerData.perks, { name = perkId, cost = def.cost, unlocked = os.time() })
	return true, string.format("Unlocked: %s!", def.name)
end

return Perks
