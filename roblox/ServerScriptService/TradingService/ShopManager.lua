-- ShopManager.lua — Robux shop: product catalog, purchase verification
-- Products must be created in Roblox Creator Dashboard.
-- Product IDs are placeholders until configured.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local ShopManager = {}

-- Product catalog (set real IDs after creating in Roblox dashboard)
local PRODUCTS = {
	extra_slots_2 = {
		id = "extra_slots_2",
		name = "+2 Portfolio Slots",
		description = "Expand your portfolio with 2 extra slots",
		robux = 199,
		productId = 0, -- SET IN ROBLOX DASHBOARD
		type = "perk",
		perk = "extra_slot_2",
		grant = function(playerData)
			local Perks = require(script.Parent.Perks)
			-- Grant perk bypassing level/cost requirements
			if not Perks.hasPerk(playerData, "extra_slot_2") then
				table.insert(playerData.perks, { name = "extra_slot_2", cost = 0, purchased = true, unlocked = os.time() })
			end
		end,
	},
	premium_data = {
		id = "premium_data",
		name = "Premium Data Pack",
		description = "Advanced charts, indicators, and market insights",
		robux = 299,
		productId = 0,
		type = "perk",
		perk = "data_premium",
		grant = function(playerData)
			local Perks = require(script.Parent.Perks)
			if not Perks.hasPerk(playerData, "data_premium") then
				table.insert(playerData.perks, { name = "data_premium", cost = 0, purchased = true, unlocked = os.time() })
			end
		end,
	},
	office_skin_modern = {
		id = "office_skin_modern",
		name = "Modern Office Skin",
		description = "Sleek glass-and-steel office aesthetic",
		robux = 149,
		productId = 0,
		type = "cosmetic",
		cosmeticType = "officeSkin",
		grant = function(playerData)
			playerData.officeSkin = "modern"
		end,
	},
	office_skin_classic = {
		id = "office_skin_classic",
		name = "Classic Wall Street Office",
		description = "Wood-paneled traditional trading floor",
		robux = 149,
		productId = 0,
		type = "cosmetic",
		cosmeticType = "officeSkin",
		grant = function(playerData)
			playerData.officeSkin = "classic"
		end,
	},
	name_color_gold = {
		id = "name_color_gold",
		name = "Gold Name Color",
		description = "Stand out in chat with a golden name",
		robux = 99,
		productId = 0,
		type = "cosmetic",
		cosmeticType = "nameColor",
		grant = function(playerData)
			playerData.nameColor = "gold"
		end,
	},
	badge_verified = {
		id = "badge_verified",
		name = "Verified Trader Badge",
		description = "Show you're serious with a verified badge",
		robux = 249,
		productId = 0,
		type = "cosmetic",
		cosmeticType = "badge",
		grant = function(playerData)
			playerData.badge = "verified_trader"
		end,
	},
}

function ShopManager.getProducts()
	local items = {}
	for _, product in pairs(PRODUCTS) do
		table.insert(items, {
			id = product.id,
			name = product.name,
			description = product.description,
			robux = product.robux,
			type = product.type,
		})
	end
	return items
end

-- Process a purchase (called from server after MarketplaceService verification)
function ShopManager.processPurchase(player, productId)
	-- productId is a number from Roblox MarketplaceService
	-- Find product by matching the Roblox productId field
	for key, product in pairs(PRODUCTS) do
		if product.productId == productId then
			return key
		end
	end
	return nil
end

-- Grant a product to a player
function ShopManager.grantProduct(playerData, productId)
	local product = PRODUCTS[productId]
	if not product then return false, "Unknown product" end
	product.grant(playerData)
	return true, "Purchased: " .. product.name
end

return ShopManager
