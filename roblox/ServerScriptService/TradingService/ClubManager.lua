-- ClubManager.lua — Trading clubs: creation, membership, ranking
-- DataStore: club_{clubId}

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local ClubManager = {}

local clubStore = DataStoreService:GetDataStore("Clubs")
local MAX_MEMBERS = 20

function ClubManager.generateId()
	return "club_" .. tostring(os.time()) .. "_" .. tostring(math.random(10000, 99999))
end

function ClubManager.createClub(ownerId, name)
	if not name or #name < 3 or #name > 30 then
		return false, "Name must be 3-30 characters"
	end

	-- Sanitize: strip control characters, limit to alphanumeric + spaces
	name = name:gsub("[^%w%s%-]", ""):sub(1, 30)
	if #name < 3 then
		return false, "Name must be 3-30 characters"
	end

	local club = {
		id = ClubManager.generateId(),
		name = name,
		created = os.time(),
		ownerId = ownerId,
		members = { ownerId },
		admins = {},
		invites = {},
		chat = {}, -- { {userId, username, message, timestamp}, ... } max 200
		stats = {
			totalValue = 0,
			weeklyProfit = 0,
			weeklyProfitPercent = 0,
		},
	}

	local ok, err = pcall(function()
		clubStore:SetAsync(club.id, club)
	end)

	if not ok then
		return false, "Failed to save club: " .. tostring(err)
	end

	return true, "Club created!", club.id
end

function ClubManager.loadClub(clubId)
	local ok, data = pcall(function()
		return clubStore:GetAsync(clubId)
	end)
	if ok and data then
		return data
	end
	return nil
end

function ClubManager.saveClub(club)
	pcall(function()
		clubStore:SetAsync(club.id, club)
	end)
end

function ClubManager.invite(club, inviterUserId, targetUserId)
	if club.ownerId ~= inviterUserId and not table.find(club.admins or {}, inviterUserId) then
		return false, "Only owner or admins can invite"
	end
	if #club.members >= MAX_MEMBERS then
		return false, "Club is full (max " .. MAX_MEMBERS .. ")"
	end
	if table.find(club.members, targetUserId) then
		return false, "Already a member"
	end
	if not club.invites then club.invites = {} end
	table.insert(club.invites, targetUserId)
	return true, "Invited!"
end

function ClubManager.acceptInvite(club, userId)
	if not club.invites then return false, "No pending invite" end
	local idx = table.find(club.invites, userId)
	if not idx then return false, "No pending invite" end

	table.remove(club.invites, idx)
	if #club.members >= MAX_MEMBERS then
		return false, "Club is full"
	end
	table.insert(club.members, userId)
	return true, "Joined club!"
end

function ClubManager.leaveClub(club, userId)
	if club.ownerId == userId then
		return false, "Owner cannot leave. Transfer ownership first."
	end
	local idx = table.find(club.members, userId)
	if idx then
		table.remove(club.members, idx)
	end
	return true, "Left club"
end

function ClubManager.kick(club, kickerUserId, targetUserId)
	if club.ownerId ~= kickerUserId and not table.find(club.admins or {}, kickerUserId) then
		return false, "Only owner or admins can kick"
	end
	if targetUserId == club.ownerId then return false, "Cannot kick owner" end

	local idx = table.find(club.members, targetUserId)
	if idx then
		table.remove(club.members, idx)
	end
	return true, "Kicked"
end

function ClubManager.sendChat(club, userId, username, message)
	if not club.chat then club.chat = {} end
	table.insert(club.chat, {
		userId = userId,
		username = username,
		message = message,
		timestamp = os.time(),
	})
	-- Keep last 200 messages
	while #club.chat > 200 do
		table.remove(club.chat, 1)
	end
	return club.chat
end

function ClubManager.updateStats(club, allPlayerData)
	local totalValue = 0
	local totalProfit = 0
	for _, memberId in ipairs(club.members or {}) do
		local data = allPlayerData[memberId]
		if data then
			local balance = data.balance or 0
			for _, pos in pairs(data.positions or {}) do
				balance = balance + (pos.totalCost or 0)
			end
			totalValue = totalValue + balance
			totalProfit = totalProfit + ((data.stats or {}).totalProfit or 0)
		end
	end
	club.stats = club.stats or {}
	club.stats.totalValue = totalValue
	club.stats.weeklyProfit = totalProfit
end

return ClubManager
