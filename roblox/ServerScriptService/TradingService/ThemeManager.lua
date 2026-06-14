-- ThemeManager.lua — Visual themes for UI customization

local ThemeManager = {}

local THEMES = {
	dark = {
		name = "Bloomberg Dark",
		bg = Color3.fromRGB(18, 22, 28),
		panel = Color3.fromRGB(22, 26, 32),
		topbar = Color3.fromRGB(26, 30, 36),
		accent = Color3.fromRGB(0, 200, 100),
		text = Color3.fromRGB(255, 255, 255),
		textSecondary = Color3.fromRGB(150, 155, 165),
		green = Color3.fromRGB(0, 200, 100),
		red = Color3.fromRGB(255, 80, 80),
		rowAlt = Color3.fromRGB(24, 28, 36),
	},
	light = {
		name = "Light Mode",
		bg = Color3.fromRGB(240, 242, 245),
		panel = Color3.fromRGB(255, 255, 255),
		topbar = Color3.fromRGB(245, 246, 248),
		accent = Color3.fromRGB(0, 140, 70),
		text = Color3.fromRGB(30, 30, 30),
		textSecondary = Color3.fromRGB(120, 125, 135),
		green = Color3.fromRGB(0, 160, 80),
		red = Color3.fromRGB(220, 50, 50),
		rowAlt = Color3.fromRGB(248, 250, 252),
	},
	matrix = {
		name = "Matrix",
		bg = Color3.fromRGB(5, 10, 5),
		panel = Color3.fromRGB(8, 15, 8),
		topbar = Color3.fromRGB(10, 18, 10),
		accent = Color3.fromRGB(0, 255, 65),
		text = Color3.fromRGB(0, 255, 65),
		textSecondary = Color3.fromRGB(0, 150, 40),
		green = Color3.fromRGB(0, 255, 65),
		red = Color3.fromRGB(255, 40, 40),
		rowAlt = Color3.fromRGB(12, 22, 12),
	},
	midnight = {
		name = "Midnight Blue",
		bg = Color3.fromRGB(10, 15, 30),
		panel = Color3.fromRGB(15, 22, 42),
		topbar = Color3.fromRGB(18, 26, 48),
		accent = Color3.fromRGB(60, 140, 255),
		text = Color3.fromRGB(220, 225, 240),
		textSecondary = Color3.fromRGB(130, 140, 170),
		green = Color3.fromRGB(50, 210, 120),
		red = Color3.fromRGB(255, 70, 80),
		rowAlt = Color3.fromRGB(18, 26, 48),
	},
	terminal = {
		name = "Terminal Green",
		bg = Color3.fromRGB(8, 12, 8),
		panel = Color3.fromRGB(12, 18, 12),
		topbar = Color3.fromRGB(14, 20, 14),
		accent = Color3.fromRGB(0, 230, 60),
		text = Color3.fromRGB(0, 230, 60),
		textSecondary = Color3.fromRGB(0, 140, 40),
		green = Color3.fromRGB(0, 230, 60),
		red = Color3.fromRGB(255, 50, 50),
		rowAlt = Color3.fromRGB(16, 24, 16),
	},
}

function ThemeManager.getTheme(themeId)
	return THEMES[themeId or "dark"] or THEMES.dark
end

function ThemeManager.getAllThemes()
	local list = {}
	for id, theme in pairs(THEMES) do
		table.insert(list, {
			id = id,
			name = theme.name,
		})
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

function ThemeManager.getDefaultTheme()
	return THEMES.dark
end

return ThemeManager
