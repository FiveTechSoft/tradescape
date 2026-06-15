-- EventManager.lua — Market events triggered by real market conditions
-- Badge rewards for surviving/winning events

local ProxyClient = require(script.Parent.Parent.ProxyClient)
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local EventManager = {}
local eventStore = DataStoreService:GetDataStore("Events")

-- Active event state
local activeEvent = nil
local lastCheck = 0

-- Event definitions
local EVENTS = {
	crash_survival = {
		name = "Market Crash Survival",
		description = "S&P 500 dropped over 2% today! Protect your portfolio.",
		badgeId = "badge_crash_survivor",
		xpReward = 200,
		trigger = function()
			-- Check if S&P 500 (^GSPC) dropped >2% today
			local quote = ProxyClient.getQuote("^GSPC")
			if quote and quote.cp and quote.cp < -2 then
				return true
			end
			return false
		end,
		duration = 86400, -- 24 hours
		objective = "Lowest drawdown %",
		metric = "minDrawdown",
	},
	earnings_season = {
		name = "Earnings Season",
		description = "5 big tech companies reporting this week. Predict their direction!",
		badgeId = "badge_earnings_oracle",
		xpReward = 150,
		trigger = function()
			-- Manual: triggered by admin or every 90 days
			local now = os.time()
			-- Check if it's been >90 days since last earnings event
			return false -- Manual trigger for now
		end,
		duration = 5 * 86400,
		objective = "Most correct predictions",
		metric = "correctPredictions",
	},
	bull_run = {
		name = "Bull Run Challenge",
		description = "S&P 500 up 10% in 30 days! Maximize your gains!",
		badgeId = "badge_bull_master",
		xpReward = 300,
		trigger = function()
			local quote = ProxyClient.getQuote("^GSPC")
			if quote and quote.cp and quote.cp > 2 then
				-- Use 2% daily as proxy for bull market
				return true
			end
			return false
		end,
		duration = 7 * 86400,
		objective = "Highest profit %",
		metric = "profitPercent",
	},
}

function EventManager.getActiveEvent()
	return activeEvent
end

function EventManager.checkEvents()
	local now = os.time()
	if now - lastCheck < 300 then -- Check every 5 min
		return
	end
	lastCheck = now

	-- If there's an active event, check if it expired
	if activeEvent and now > activeEvent.expires then
		-- Award participants
		EventManager.awardEvent(activeEvent)
		activeEvent = nil
	end

	-- If no active event, try to trigger one
	if not activeEvent then
		for eventId, event in pairs(EVENTS) do
			local ok, triggered = pcall(event.trigger)
			if ok and triggered then
				activeEvent = {
					id = eventId,
					name = event.name,
					description = event.description,
					badgeId = event.badgeId,
					xpReward = event.xpReward,
					started = now,
					expires = now + event.duration,
					objective = event.objective,
					participants = {},
				}
				print("[EventManager] Event started:", event.name)
				break
			end
		end
	end
end

function EventManager.joinEvent(userId, playerData)
	if not activeEvent then return false, "No active event" end

	if activeEvent.participants[userId] then
		return false, "Already joined"
	end

	-- Record starting portfolio for comparison
	activeEvent.participants[userId] = {
		startBalance = playerData.balance or 0,
		startValue = 0,
		predictions = {},
	}

	return true, "Joined " .. activeEvent.name
end

function EventManager.awardEvent(event)
	print("[EventManager] Event ended:", event.name)
	-- Award top X players with badges (handled in NetworkHandler)
end

-- Check if S&P dropped significantly (for UI highlight)
function EventManager.getMarketMood()
	local quote = ProxyClient.getQuote("^GSPC")
	if not quote or not quote.cp then return "neutral" end

	if quote.cp < -2 then return "crash"
	elseif quote.cp < -0.5 then return "bearish"
	elseif quote.cp > 2 then return "bull"
	elseif quote.cp > 0.5 then return "bullish"
	end
	return "neutral"
end

return EventManager
