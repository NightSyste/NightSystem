--[[
	NIGHT SYSTEM ("NightUI") — Complete Example Script
	Demonstrates loading the library via loadstring and using all UI elements:
	Window (with built-in Home Tab), Categories, Tabs, Sections, Toggles,
	Buttons, Dropdowns (Single & Multi), Sliders, Inputs, Keybinds,
	ColorPickers, Labels, Paragraphs, Dividers, Notifications & Config System.
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/NightSyste/NightSystem/main/source.lua"))()

-- 1. Create Main Window (Only the "Home" tab is built-in by default!)
local Window = Library:CreateWindow({
	Title = "Night System",
	DiscordInvite = "discord.gg/4cZBCyDFmX",
	LogoId = "", -- Optional custom rbxassetid:// logo
	AnnouncementText = "Autorob is free for a few days so you can test it! Enjoy it and let us know what you think. Join discord.gg/4cZBCyDFmX for news, updates and support.",
	ToggleKey = Enum.KeyCode.RightShift,
})

-- 2. Create Dynamic Sidebar Category & Tabs
Window:CreateCategory("MAIN")

local MainTab = Window:CreateTab({
	Name = "Main Features",
	Icon = "shield",
})

local VisualsTab = Window:CreateTab({
	Name = "Visuals",
	Icon = "eye",
})

Window:CreateCategory("CONFIGURATION")

local SettingsTab = Window:CreateTab({
	Name = "Settings",
	Icon = "settings",
})

-- 3. Populate "Main Features" Tab (Auto-sorted top-to-bottom via LayoutOrder)
MainTab:CreateSection("Automation")

local AutoFarmToggle = MainTab:CreateToggle({
	Name = "Enable AutoFarm",
	Description = "Automatically completes objectives in the current server",
	Default = false,
	Flag = "AutoFarmToggle",
	Callback = function(state)
		print("AutoFarm state:", state)
	end,
})

local SpeedSlider = MainTab:CreateSlider({
	Name = "Movement Speed",
	Description = "Adjust movement velocity multiplier",
	Min = 16,
	Max = 250,
	Default = 60,
	Increment = 1,
	Suffix = " studs/s",
	Flag = "SpeedSlider",
	Callback = function(value)
		print("Speed set to:", value)
	end,
})

local TargetDropdown = MainTab:CreateDropdown({
	Name = "Target Priority",
	Description = "Select which objective to prioritize first",
	Options = { "Nearest", "Highest Value", "Lowest Risk", "Random" },
	Multi = false,
	Default = "Nearest",
	Flag = "TargetPriority",
	Callback = function(selected)
		print("Selected Priority:", selected)
	end,
})

local FilterDropdown = MainTab:CreateDropdown({
	Name = "Active Filters",
	Description = "Multi-select example with search support",
	Options = { "Cash Register", "Jewelry Case", "Bank Vault", "Airdrop", "Safe", "ATM" },
	Multi = true,
	Default = { "Bank Vault", "Airdrop" },
	Flag = "ActiveFilters",
	Callback = function(selectedTable)
		print("Active Filters:", table.concat(selectedTable, ", "))
	end,
})

MainTab:CreateDivider()
MainTab:CreateSection("Actions & Binds")

MainTab:CreateButton({
	Name = "Refresh Objectives",
	Description = "Rescans the map and updates available targets",
	Callback = function()
		Library:Notify({
			Title = "Night System",
			Content = "Objectives refreshed! AutoFarm is currently: " .. tostring(Library.Flags["AutoFarmToggle"]),
			Duration = 3,
			Icon = "check",
		})
	end,
})

MainTab:CreateKeybind({
	Name = "Quick Toggle Keybind",
	Description = "Press key to toggle AutoFarm state",
	Default = Enum.KeyCode.F,
	Mode = "Toggle",
	Flag = "QuickToggleBind",
	Callback = function(active)
		AutoFarmToggle:Set(active)
	end,
})

-- 4. Populate "Visuals" Tab
VisualsTab:CreateSection("Highlight & Colors")

VisualsTab:CreateColorPicker({
	Name = "Highlight Accent Color",
	Description = "Full HSV ColorPicker with Hex & RGB inputs",
	Default = Color3.fromRGB(255, 255, 255),
	Flag = "HighlightColor",
	Callback = function(color)
		print("Picked color:", color)
	end,
})

local StatusLabel = VisualsTab:CreateLabel("Status: Rendering active (60 FPS)")

local InfoParagraph = VisualsTab:CreateParagraph({
	Title = "Visuals Overview",
	Content = "All UI elements are automatically ordered in call sequence using UIListLayout and AutomaticCanvasSize.",
})

-- 5. Populate "Settings" Tab (Input & Config Save/Load)
SettingsTab:CreateSection("Profile Configuration")

local ConfigNameInput = SettingsTab:CreateInput({
	Name = "Config Name",
	Description = "Enter file name for saving or loading settings",
	Placeholder = "default",
	Default = "default",
	NumericOnly = false,
	Flag = "ConfigName",
	Callback = function(text)
		print("Config name:", text)
	end,
})

SettingsTab:CreateButton({
	Name = "Save Configuration",
	Description = "Writes all Flags as JSON via writefile",
	Callback = function()
		local name = Library.Flags["ConfigName"] or "default"
		local ok, msg = Library:SaveConfig(name)
		Library:Notify({
			Title = if ok then "Config Saved" else "Save Error",
			Content = msg,
			Duration = 3,
			Icon = "folder",
		})
	end,
})

SettingsTab:CreateButton({
	Name = "Load Configuration",
	Description = "Loads JSON config via readfile and updates UI elements",
	Callback = function()
		local name = Library.Flags["ConfigName"] or "default"
		local ok, msg = Library:LoadConfig(name)
		Library:Notify({
			Title = if ok then "Config Loaded" else "Load Error",
			Content = msg,
			Duration = 3,
			Icon = "folder",
		})
	end,
})

-- Initial startup notification
Library:Notify({
	Title = "Night System Loaded",
	Content = "Press RightShift or click '≡' to toggle the interface.",
	Duration = 4,
	Icon = "sparkles",
})
