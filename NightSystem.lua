--!nocheck
--[[
	================================================================================
	NIGHT SYSTEM ("NightUI") — 1:1 Roblox Luau UI Library
	Design: Modern Dark-Theme / Glassmorphism (#0B0B0C / #111214 / #FFFFFF)
	Features:
	  - Fixed Built-In "Home" Tab with Live Player & Server Telemetry
	  - Dynamic Categories & Tabs via Window:CreateCategory() / Window:CreateTab()
	  - Automatic LayoutOrder Sorting & Smooth ScrollingFrame Canvas Sizing
	  - Full Widget Suite: Section, Toggle, Button, Dropdown (Single & Multi + Search),
	    Slider, Input/TextBox, Keybind (Toggle/Hold), ColorPicker (HSV + Hex/RGB),
	    Label, Paragraph, Divider, Toast Notification System & JSON Config Manager
	  - Executor & Studio Safe: gethui() -> CoreGui -> PlayerGui fallback
	================================================================================
]]

local Library = {}
Library.__index = Library
Library.Version = "3.0.0"
Library.Flags = {}
Library._ConfigElements = {}
Library._Connections = {}
Library._Notifications = {}
Library.ConfigFolder = "NightSystem_Configs"

-- // Roblox Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- // 1:1 Visual Color Palette (Matching Reference Image)
local THEME = {
	-- Outer Window & Containers
	WindowBg = Color3.fromHex("#0B0B0C"),
	WindowTransparency = 0.05,
	ContentBg = Color3.fromHex("#111214"),
	ContentGradTopRight = Color3.fromHex("#181C22"),
	ContentGradMiddle = Color3.fromHex("#111214"),
	ContentGradBottomLeft = Color3.fromHex("#0E0E10"),
	WindowStroke = Color3.fromHex("#222326"),

	-- TopBar Controls
	TopButtonBg = Color3.fromHex("#161618"),
	TopButtonHover = Color3.fromHex("#1F2024"),
	TopButtonStroke = Color3.fromHex("#262629"),
	DragPill = Color3.fromHex("#3A3A3E"),
	DragPillHover = Color3.fromHex("#525258"),

	-- Sidebar & Branding
	BrandCardBg = Color3.fromHex("#121214"),
	BrandCardStroke = Color3.fromHex("#242428"),
	TabActiveBg = Color3.fromHex("#151518"),
	TabHoverBg = Color3.fromHex("#121215"),
	TabActiveStroke = Color3.fromHex("#2A2A2E"),
	TabIndicator = Color3.fromHex("#FFFFFF"),
	SidebarFooterLine = Color3.fromHex("#1F1F23"),

	-- Home Tab & Dividers
	HomeHeaderTitle = Color3.fromHex("#52555E"),
	HomeHeaderSub = Color3.fromHex("#3E4149"),
	HomeAnnouncement = Color3.fromHex("#8A8E96"),
	HomeDivider = Color3.fromHex("#202225"),
	AvatarStroke = Color3.fromHex("#26282E"),

	-- Interactive Elements / Cards
	ElementBg = Color3.fromHex("#151619"),
	ElementHover = Color3.fromHex("#191B1F"),
	ElementInner = Color3.fromHex("#101113"),
	ElementStroke = Color3.fromHex("#222326"),
	ElementStrokeFocus = Color3.fromHex("#3E4047"),
	SectionHeader = Color3.fromHex("#7A7A82"),

	-- Accents & Text
	Accent = Color3.fromHex("#FFFFFF"),
	AccentDim = Color3.fromHex("#CFCFD6"),
	ToggleOffBg = Color3.fromHex("#202125"),
	ToggleKnobOff = Color3.fromHex("#7A7A82"),
	ToggleKnobOn = Color3.fromHex("#0B0B0C"),
	TextPrimary = Color3.fromHex("#FFFFFF"),
	TextSecondary = Color3.fromHex("#7A7A82"),
	TextMuted = Color3.fromHex("#585860"),
	TextValue = Color3.fromHex("#E4E4E8"),
	Danger = Color3.fromHex("#E04545"),
}

-- // Tween Presets
local TWEEN_FAST = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MEDIUM = TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.30, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- // Built-in Lucide / Roblox Asset Icon Map
local ICONS = {
	home = "rbxassetid://10723407389",
	house = "rbxassetid://10723407389",
	shield = "rbxassetid://10734951847",
	autorob = "rbxassetid://10734951847",
	robberies = "rbxassetid://10709782497",
	bag = "rbxassetid://10709782497",
	webhook = "rbxassetid://10709775704",
	bell = "rbxassetid://10709775704",
	settings = "rbxassetid://10734950309",
	gear = "rbxassetid://10734950309",
	themes = "rbxassetid://10734920149",
	palette = "rbxassetid://10734920149",
	user = "rbxassetid://10747373176",
	player = "rbxassetid://10747373176",
	combat = "rbxassetid://10734975486",
	sword = "rbxassetid://10734975486",
	target = "rbxassetid://10734977012",
	eye = "rbxassetid://10723346959",
	visuals = "rbxassetid://10723346959",
	zap = "rbxassetid://10709791437",
	teleport = "rbxassetid://10734886004",
	map = "rbxassetid://10734886004",
	car = "rbxassetid://10709789810",
	vehicle = "rbxassetid://10709789810",
	lock = "rbxassetid://10723434711",
	key = "rbxassetid://10723416652",
	folder = "rbxassetid://10723387563",
	star = "rbxassetid://10734966248",
	info = "rbxassetid://10723415903",
	check = "rbxassetid://10709790644",
	search = "rbxassetid://10734943674",
	external = "rbxassetid://10723374641",
	chevron_down = "rbxassetid://10709790948",
	chevron_right = "rbxassetid://10709791437",
	sliders = "rbxassetid://10734963400",
	code = "rbxassetid://10709810463",
	globe = "rbxassetid://10723404337",
	sparkles = "rbxassetid://10734966248",
}

-- // Utility Functions
local function resolveIcon(iconInput: any): string
	if type(iconInput) == "number" then
		return "rbxassetid://" .. tostring(iconInput)
	end
	if type(iconInput) == "string" and iconInput ~= "" then
		if iconInput:find("^rbxassetid://") or iconInput:find("^http") or iconInput:find("^rbxthumb://") then
			return iconInput
		end
		local numeric = tonumber(iconInput)
		if numeric then
			return "rbxassetid://" .. tostring(numeric)
		end
		local key = string.lower(iconInput)
		if ICONS[key] then
			return ICONS[key]
		end
	end
	return ICONS.folder
end

local function trackConnection(conn: RBXScriptConnection): RBXScriptConnection
	table.insert(Library._Connections, conn)
	return conn
end

local function disconnectAll()
	for _, conn in ipairs(Library._Connections) do
		if conn and conn.Connected then
			pcall(function()
				conn:Disconnect()
			end)
		end
	end
	table.clear(Library._Connections)
end

local function getSafeGuiParent(): Instance
	local ok, target = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		local coreGui = game:GetService("CoreGui")
		local _ = coreGui.Name
		return coreGui
	end)
	if ok and target then
		return target
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function tween(instance: Instance, info: TweenInfo, props: { [string]: any }): Tween
	local tw = TweenService:Create(instance, info, props)
	tw:Play()
	return tw
end

local function createCorner(parent: Instance, radius: number | UDim): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = if typeof(radius) == "UDim" then radius else UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.WindowStroke
	stroke.Thickness = thickness or 1
	stroke.Transparency = if transparency ~= nil then transparency else 0.2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function createPadding(parent: Instance, top: number, bottom: number, left: number, right: number): UIPadding
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, top)
	pad.PaddingBottom = UDim.new(0, bottom)
	pad.PaddingLeft = UDim.new(0, left)
	pad.PaddingRight = UDim.new(0, right)
	pad.Parent = parent
	return pad
end

local function formatKeyCode(key: EnumItem?): string
	if not key then
		return "None"
	end
	local name = key.Name
	local replacements = {
		RightShift = "RShift",
		LeftShift = "LShift",
		RightControl = "RCtrl",
		LeftControl = "LCtrl",
		RightAlt = "RAlt",
		LeftAlt = "LAlt",
		MouseButton1 = "MB1",
		MouseButton2 = "MB2",
		MouseButton3 = "MB3",
		Backspace = "Back",
		Return = "Enter",
	}
	return replacements[name] or name
end

local function color3ToHex(color: Color3): string
	return string.format(
		"#%02X%02X%02X",
		math.clamp(math.round(color.R * 255), 0, 255),
		math.clamp(math.round(color.G * 255), 0, 255),
		math.clamp(math.round(color.B * 255), 0, 255)
	)
end

local function hexToColor3(hex: string): Color3?
	local cleaned = hex:gsub("#", ""):gsub("%s+", "")
	if #cleaned == 6 then
		local r = tonumber(cleaned:sub(1, 2), 16)
		local g = tonumber(cleaned:sub(3, 4), 16)
		local b = tonumber(cleaned:sub(5, 6), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	end
	return nil
end

local function createRipple(button: GuiObject, mousePos: Vector2?)
	local ripple = Instance.new("Frame")
	ripple.Name = "Ripple"
	ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ripple.BackgroundTransparency = 0.86
	ripple.BorderSizePixel = 0
	ripple.ZIndex = button.ZIndex + 3
	ripple.AnchorPoint = Vector2.new(0.5, 0.5)
	createCorner(ripple, UDim.new(1, 0))

	local relX = 0.5
	local relY = 0.5
	if mousePos then
		local absPos = button.AbsolutePosition
		local absSize = button.AbsoluteSize
		if absSize.X > 0 and absSize.Y > 0 then
			relX = math.clamp((mousePos.X - absPos.X) / absSize.X, 0, 1)
			relY = math.clamp((mousePos.Y - absPos.Y) / absSize.Y, 0, 1)
		end
	end

	ripple.Position = UDim2.fromScale(relX, relY)
	ripple.Size = UDim2.fromOffset(0, 0)
	ripple.Parent = button

	local maxDim = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.6
	local tw = tween(ripple, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(maxDim, maxDim),
		BackgroundTransparency = 1,
	})
	tw.Completed:Connect(function()
		if ripple and ripple.Parent then
			ripple:Destroy()
		end
	end)
end

-- // Notification Container Helper
local NotificationGui: ScreenGui? = nil
local NotificationHolder: Frame? = nil

local function ensureNotificationHolder(): Frame
	if NotificationHolder and NotificationHolder.Parent then
		return NotificationHolder
	end

	local parent = getSafeGuiParent()
	local existing = parent:FindFirstChild("NightSystem_Notifications")
	if existing then
		pcall(function()
			existing:Destroy()
		end)
	end

	local gui = Instance.new("ScreenGui")
	gui.Name = "NightSystem_Notifications"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 999999
	gui.Parent = parent
	NotificationGui = gui

	local holder = Instance.new("Frame")
	holder.Name = "Holder"
	holder.AnchorPoint = Vector2.new(1, 1)
	holder.Position = UDim2.new(1, -20, 1, -20)
	holder.Size = UDim2.new(0, 300, 1, -40)
	holder.BackgroundTransparency = 1
	holder.Parent = gui

	local list = Instance.new("UIListLayout")
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.Padding = UDim.new(0, 8)
	list.Parent = holder

	NotificationHolder = holder
	return holder
end

-- // 13. Library:Notify(config)
function Library:Notify(config: { [string]: any })
	config = config or {}
	local titleText = tostring(config.Title or "Night System")
	local contentText = tostring(config.Content or config.Description or "")
	local duration = tonumber(config.Duration) or 4
	local iconAsset = if config.Icon then resolveIcon(config.Icon) else nil

	local holder = ensureNotificationHolder()

	local textBounds = TextService:GetTextSize(
		contentText,
		12,
		Enum.Font.GothamMedium,
		Vector2.new(if iconAsset then 230 else 260, 500)
	)
	local cardHeight = math.max(62, textBounds.Y + 42)

	local wrapper = Instance.new("Frame")
	wrapper.Name = "Notification"
	wrapper.Size = UDim2.fromOffset(300, cardHeight)
	wrapper.BackgroundTransparency = 1
	wrapper.Parent = holder

	local card = Instance.new("Frame")
	card.Name = "Card"
	card.Size = UDim2.fromScale(1, 1)
	card.Position = UDim2.fromOffset(330, 0)
	card.BackgroundColor3 = THEME.WindowBg
	card.BackgroundTransparency = 0.03
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = wrapper
	createCorner(card, 8)
	createStroke(card, THEME.WindowStroke, 1, 0.15)

	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.AnchorPoint = Vector2.new(0, 0.5)
	accentBar.Position = UDim2.new(0, 0, 0.5, 0)
	accentBar.Size = UDim2.new(0, 2, 1, -18)
	accentBar.BackgroundColor3 = THEME.Accent
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card
	createCorner(accentBar, UDim.new(1, 0))

	local textOffsetLeft = 14
	if iconAsset then
		local iconImg = Instance.new("ImageLabel")
		iconImg.Name = "Icon"
		iconImg.Position = UDim2.fromOffset(14, 14)
		iconImg.Size = UDim2.fromOffset(18, 18)
		iconImg.BackgroundTransparency = 1
		iconImg.Image = iconAsset
		iconImg.ImageColor3 = THEME.TextPrimary
		iconImg.Parent = card
		textOffsetLeft = 40
	end

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "Title"
	titleLbl.Position = UDim2.fromOffset(textOffsetLeft, 11)
	titleLbl.Size = UDim2.new(1, -(textOffsetLeft + 12), 0, 16)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.Text = titleText
	titleLbl.TextColor3 = THEME.TextPrimary
	titleLbl.TextSize = 13
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
	titleLbl.Parent = card

	local bodyLbl = Instance.new("TextLabel")
	bodyLbl.Name = "Content"
	bodyLbl.Position = UDim2.fromOffset(textOffsetLeft, 29)
	bodyLbl.Size = UDim2.new(1, -(textOffsetLeft + 12), 0, cardHeight - 38)
	bodyLbl.BackgroundTransparency = 1
	bodyLbl.Font = Enum.Font.GothamMedium
	bodyLbl.Text = contentText
	bodyLbl.TextColor3 = THEME.TextSecondary
	bodyLbl.TextSize = 12
	bodyLbl.TextWrapped = true
	bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
	bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
	bodyLbl.Parent = card

	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.AnchorPoint = Vector2.new(0, 1)
	progressBg.Position = UDim2.new(0, 0, 1, 0)
	progressBg.Size = UDim2.new(1, 0, 0, 2)
	progressBg.BackgroundColor3 = THEME.ElementStroke
	progressBg.BorderSizePixel = 0
	progressBg.Parent = card

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.fromScale(1, 1)
	progressFill.BackgroundColor3 = THEME.Accent
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg

	tween(card, TWEEN_SMOOTH, { Position = UDim2.fromOffset(0, 0) })
	tween(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) })

	task.delay(duration, function()
		if card and card.Parent then
			local out = tween(card, TWEEN_MEDIUM, { Position = UDim2.fromOffset(340, 0) })
			out.Completed:Wait()
			if wrapper and wrapper.Parent then
				wrapper:Destroy()
			end
		end
	end)
end

-- // 14. Config & Flag System (writefile / readfile + HttpService:JSONEncode)
local function ensureConfigFolder()
	pcall(function()
		if type(isfolder) == "function" and type(makefolder) == "function" then
			if not isfolder(Library.ConfigFolder) then
				makefolder(Library.ConfigFolder)
			end
		end
	end)
end

function Library:SaveConfig(configName: string): (boolean, string)
	local name = tostring(configName or "default"):gsub("[^%w_%-]", "")
	if name == "" then
		name = "default"
	end
	ensureConfigFolder()

	local payload = {}
	for flag, value in pairs(Library.Flags) do
		if typeof(value) == "Color3" then
			payload[flag] = { __type = "Color3", hex = color3ToHex(value) }
		elseif typeof(value) == "EnumItem" then
			payload[flag] = { __type = "EnumItem", enumType = tostring(value.EnumType), name = value.Name }
		else
			payload[flag] = value
		end
	end

	local okEncode, encoded = pcall(function()
		return HttpService:JSONEncode(payload)
	end)
	if not okEncode then
		return false, "JSONEncode failed"
	end

	local filePath = Library.ConfigFolder .. "/" .. name .. ".json"
	if type(writefile) == "function" then
		local okWrite, err = pcall(function()
			writefile(filePath, encoded)
		end)
		if okWrite then
			return true, filePath
		else
			return false, tostring(err)
		end
	end
	return false, "writefile is not supported in this environment"
end

function Library:LoadConfig(configName: string): (boolean, string)
	local name = tostring(configName or "default"):gsub("[^%w_%-]", "")
	if name == "" then
		name = "default"
	end
	local filePath = Library.ConfigFolder .. "/" .. name .. ".json"

	if type(readfile) ~= "function" then
		return false, "readfile is not supported in this environment"
	end
	if type(isfile) == "function" and not isfile(filePath) then
		return false, "Config file not found: " .. filePath
	end

	local okRead, content = pcall(function()
		return readfile(filePath)
	end)
	if not okRead or not content then
		return false, "Failed to read config file"
	end

	local okDecode, decoded = pcall(function()
		return HttpService:JSONDecode(content)
	end)
	if not okDecode or type(decoded) ~= "table" then
		return false, "Corrupted JSON in config file"
	end

	for flag, rawVal in pairs(decoded) do
		local parsedVal = rawVal
		if type(rawVal) == "table" and rawVal.__type == "Color3" and type(rawVal.hex) == "string" then
			parsedVal = hexToColor3(rawVal.hex) or Color3.fromRGB(255, 255, 255)
		elseif type(rawVal) == "table" and rawVal.__type == "EnumItem" and rawVal.name then
			if rawVal.enumType == "Enum.KeyCode" and Enum.KeyCode[rawVal.name] then
				parsedVal = Enum.KeyCode[rawVal.name]
			elseif rawVal.enumType == "Enum.UserInputType" and Enum.UserInputType[rawVal.name] then
				parsedVal = Enum.UserInputType[rawVal.name]
			end
		end

		Library.Flags[flag] = parsedVal
		local controller = Library._ConfigElements[flag]
		if controller and type(controller.Set) == "function" then
			pcall(function()
				controller:Set(parsedVal)
			end)
		end
	end

	return true, filePath
end

function Library:DeleteConfig(configName: string): boolean
	local name = tostring(configName or "default"):gsub("[^%w_%-]", "")
	local filePath = Library.ConfigFolder .. "/" .. name .. ".json"
	if type(delfile) == "function" and (type(isfile) ~= "function" or isfile(filePath)) then
		local ok = pcall(function()
			delfile(filePath)
		end)
		return ok
	end
	return false
end

function Library:GetConfigs(): { string }
	local results = {}
	ensureConfigFolder()
	if type(listfiles) == "function" then
		local ok, files = pcall(function()
			return listfiles(Library.ConfigFolder)
		end)
		if ok and type(files) == "table" then
			for _, file in ipairs(files) do
				local base = tostring(file):match("([^/\\]+)%.json$")
				if base then
					table.insert(results, base)
				end
			end
		end
	end
	if #results == 0 then
		table.insert(results, "default")
	end
	return results
end

-- // 1. Library:CreateWindow(config)
function Library:CreateWindow(config: { [string]: any }?)
	config = config or {}

	local windowTitle = tostring(config.Title or "Night System")
	local rawDiscord = tostring(config.DiscordInvite or config.Subtitle or "discord.gg/4cZBCyDFmX")
	local discordDisplay = rawDiscord:gsub("^https?://", "")
	local discordFullUrl = if rawDiscord:find("^https?://") then rawDiscord else "https://" .. discordDisplay
	local logoId = config.LogoId or config.Logo or nil
	local announcementText = tostring(
		config.AnnouncementText
			or config.IntroText
			or ("Autorob is free for a few days so you can test it! Enjoy it and let us know what you think. Join " .. discordDisplay .. " for news, updates and support.")
	)
	local toggleKey: EnumItem = config.ToggleKey or Enum.KeyCode.RightShift
	if config.ConfigFolder then
		Library.ConfigFolder = tostring(config.ConfigFolder)
	end

	-- Cleanup any previous NightSystem UI instance
	disconnectAll()
	local guiParent = getSafeGuiParent()
	local oldGui = guiParent:FindFirstChild("NightSystem_UI")
	if oldGui then
		pcall(function()
			oldGui:Destroy()
		end)
	end

	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "NightSystem_UI"
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = true
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.DisplayOrder = 999990
	ScreenGui.Parent = guiParent

	-- Window dimensions & states
	local normalSize = config.Size or UDim2.fromOffset(750, 470)
	local maximizedSize = UDim2.fromOffset(920, 570)
	local isMaximized = false
	local isMinimized = false

	-- Outer Main Window (#0B0B0C, Transparency 0.05, Corner 12px, Stroke #222326)
	local MainWindow = Instance.new("Frame")
	MainWindow.Name = "MainWindow"
	MainWindow.AnchorPoint = Vector2.new(0.5, 0.5)
	MainWindow.Position = UDim2.fromScale(0.5, 0.5)
	MainWindow.Size = normalSize
	MainWindow.BackgroundColor3 = THEME.WindowBg
	MainWindow.BackgroundTransparency = THEME.WindowTransparency
	MainWindow.BorderSizePixel = 0
	MainWindow.ClipsDescendants = true
	MainWindow.Parent = ScreenGui
	createCorner(MainWindow, 12)
	createStroke(MainWindow, THEME.WindowStroke, 1, 0.2)

	-- Floating Restore Pill (shown when minimized via '≡' or ToggleKey)
	local RestorePill = Instance.new("TextButton")
	RestorePill.Name = "RestorePill"
	RestorePill.AnchorPoint = Vector2.new(0.5, 0)
	RestorePill.Position = UDim2.new(0.5, 0, 0, 14)
	RestorePill.Size = UDim2.fromOffset(170, 32)
	RestorePill.BackgroundColor3 = THEME.WindowBg
	RestorePill.BackgroundTransparency = 0.05
	RestorePill.BorderSizePixel = 0
	RestorePill.AutoButtonColor = false
	RestorePill.Visible = false
	RestorePill.Text = ""
	RestorePill.Parent = ScreenGui
	createCorner(RestorePill, UDim.new(1, 0))
	createStroke(RestorePill, THEME.WindowStroke, 1, 0.15)

	local RestoreDot = Instance.new("Frame")
	RestoreDot.AnchorPoint = Vector2.new(0, 0.5)
	RestoreDot.Position = UDim2.new(0, 12, 0.5, 0)
	RestoreDot.Size = UDim2.fromOffset(6, 6)
	RestoreDot.BackgroundColor3 = THEME.Accent
	RestoreDot.BorderSizePixel = 0
	RestoreDot.Parent = RestorePill
	createCorner(RestoreDot, UDim.new(1, 0))

	local RestoreLabel = Instance.new("TextLabel")
	RestoreLabel.Position = UDim2.fromOffset(26, 0)
	RestoreLabel.Size = UDim2.new(1, -34, 1, 0)
	RestoreLabel.BackgroundTransparency = 1
	RestoreLabel.Font = Enum.Font.GothamBold
	RestoreLabel.Text = windowTitle .. " • [" .. formatKeyCode(toggleKey) .. "]"
	RestoreLabel.TextColor3 = THEME.TextPrimary
	RestoreLabel.TextSize = 11
	RestoreLabel.TextXAlignment = Enum.TextXAlignment.Left
	RestoreLabel.Parent = RestorePill

	-- // A. Top-Bar Controls (Oben links & Mitte)
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 40)
	TopBar.BackgroundTransparency = 1
	TopBar.Parent = MainWindow

	-- Center Drag-Pill (40x4px, #3A3A3E, UICorner = Full)
	local DragPill = Instance.new("Frame")
	DragPill.Name = "DragPill"
	DragPill.AnchorPoint = Vector2.new(0.5, 0.5)
	DragPill.Position = UDim2.new(0.5, 0, 0, 14)
	DragPill.Size = UDim2.fromOffset(40, 4)
	DragPill.BackgroundColor3 = THEME.DragPill
	DragPill.BorderSizePixel = 0
	DragPill.Parent = TopBar
	createCorner(DragPill, UDim.new(1, 0))

	-- Top-Left Controls Holder (3 buttons: 24x24px, #161618, Stroke #262629)
	local TopControls = Instance.new("Frame")
	TopControls.Name = "TopControls"
	TopControls.Position = UDim2.fromOffset(12, 10)
	TopControls.Size = UDim2.fromOffset(84, 24)
	TopControls.BackgroundTransparency = 1
	TopControls.Parent = TopBar

	local TopControlsLayout = Instance.new("UIListLayout")
	TopControlsLayout.FillDirection = Enum.FillDirection.Horizontal
	TopControlsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TopControlsLayout.Padding = UDim.new(0, 6)
	TopControlsLayout.Parent = TopControls

	local function createTopButton(name: string, order: number): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.LayoutOrder = order
		btn.Size = UDim2.fromOffset(24, 24)
		btn.BackgroundColor3 = THEME.TopButtonBg
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.Parent = TopControls
		createCorner(btn, 6)
		local stroke = createStroke(btn, THEME.TopButtonStroke, 1, 0.15)

		btn.MouseEnter:Connect(function()
			tween(btn, TWEEN_FAST, { BackgroundColor3 = THEME.TopButtonHover })
			tween(stroke, TWEEN_FAST, { Color = THEME.ElementStrokeFocus })
		end)
		btn.MouseLeave:Connect(function()
			tween(btn, TWEEN_FAST, { BackgroundColor3 = THEME.TopButtonBg })
			tween(stroke, TWEEN_FAST, { Color = THEME.TopButtonStroke })
		end)
		return btn
	end

	-- 1. Close Button ("X")
	local CloseBtn = createTopButton("CloseButton", 1)
	local CloseIcon = Instance.new("TextLabel")
	CloseIcon.Size = UDim2.fromScale(1, 1)
	CloseIcon.BackgroundTransparency = 1
	CloseIcon.Font = Enum.Font.GothamBold
	CloseIcon.Text = "×"
	CloseIcon.TextColor3 = THEME.TextSecondary
	CloseIcon.TextSize = 16
	CloseIcon.Parent = CloseBtn

	-- 2. Maximize Button ("⛶")
	local MaxBtn = createTopButton("MaximizeButton", 2)
	local MaxBox = Instance.new("Frame")
	MaxBox.AnchorPoint = Vector2.new(0.5, 0.5)
	MaxBox.Position = UDim2.fromScale(0.5, 0.5)
	MaxBox.Size = UDim2.fromOffset(9, 9)
	MaxBox.BackgroundTransparency = 1
	MaxBox.Parent = MaxBtn
	createCorner(MaxBox, 2)
	local MaxBoxStroke = createStroke(MaxBox, THEME.TextSecondary, 1.3, 0)

	-- 3. Minimize Button ("≡")
	local MinBtn = createTopButton("MinimizeButton", 3)
	for i = 1, 3 do
		local line = Instance.new("Frame")
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.Position = UDim2.new(0.5, 0, 0, 6 + (i * 3))
		line.Size = UDim2.fromOffset(10, 1.4)
		line.BackgroundColor3 = THEME.TextSecondary
		line.BorderSizePixel = 0
		line.Parent = MinBtn
		createCorner(line, UDim.new(1, 0))
	end

	-- Smooth Window Dragging (via TopBar or DragPill)
	do
		local dragging = false
		local dragInput: InputObject? = nil
		local dragStart = Vector2.zero
		local startPos = MainWindow.Position

		trackConnection(TopBar.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true
				dragStart = Vector2.new(input.Position.X, input.Position.Y)
				startPos = MainWindow.Position
				tween(DragPill, TWEEN_FAST, { BackgroundColor3 = THEME.DragPillHover, Size = UDim2.fromOffset(48, 4) })

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						dragging = false
						tween(DragPill, TWEEN_FAST, { BackgroundColor3 = THEME.DragPill, Size = UDim2.fromOffset(40, 4) })
					end
				end)
			end
		end))

		trackConnection(TopBar.InputChanged:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end))

		trackConnection(UserInputService.InputChanged:Connect(function(input: InputObject)
			if input == dragInput and dragging then
				local delta = Vector2.new(input.Position.X, input.Position.Y) - dragStart
				local targetPos = UDim2.new(
					startPos.X.Scale,
					startPos.X.Offset + delta.X,
					startPos.Y.Scale,
					startPos.Y.Offset + delta.Y
				)
				tween(MainWindow, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = targetPos,
				})
			end
		end))
	end

	-- Toggle Minimize / Maximize / Close logic
	local function setMinimized(state: boolean)
		isMinimized = state
		if isMinimized then
			RestorePill.Visible = true
			local currentSize = if isMaximized then maximizedSize else normalSize
			local tw = tween(MainWindow, TWEEN_MEDIUM, {
				Size = UDim2.fromOffset(currentSize.X.Offset, 0),
				BackgroundTransparency = 1,
			})
			tw.Completed:Connect(function()
				if isMinimized then
					MainWindow.Visible = false
				end
			end)
		else
			RestorePill.Visible = false
			MainWindow.Visible = true
			local targetSize = if isMaximized then maximizedSize else normalSize
			tween(MainWindow, TWEEN_SMOOTH, {
				Size = targetSize,
				BackgroundTransparency = THEME.WindowTransparency,
			})
		end
	end

	MinBtn.MouseButton1Click:Connect(function()
		setMinimized(true)
	end)

	RestorePill.MouseButton1Click:Connect(function()
		setMinimized(false)
	end)

	MaxBtn.MouseButton1Click:Connect(function()
		isMaximized = not isMaximized
		local targetSize = if isMaximized then maximizedSize else normalSize
		tween(MainWindow, TWEEN_SMOOTH, { Size = targetSize })
		tween(MaxBoxStroke, TWEEN_FAST, {
			Color = if isMaximized then THEME.Accent else THEME.TextSecondary,
		})
	end)

	CloseBtn.MouseButton1Click:Connect(function()
		disconnectAll()
		local tw = tween(MainWindow, TWEEN_MEDIUM, {
			Size = UDim2.fromOffset(normalSize.X.Offset * 0.92, 0),
			BackgroundTransparency = 1,
		})
		tw.Completed:Wait()
		if ScreenGui and ScreenGui.Parent then
			ScreenGui:Destroy()
		end
	end)

	trackConnection(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed or UserInputService:GetFocusedTextBox() then
			return
		end
		if input.KeyCode == toggleKey or input.UserInputType == toggleKey then
			setMinimized(not isMinimized)
		end
	end))

	-- // B. Left Sidebar (Navigation & Branding)
	local Sidebar = Instance.new("Frame")
	Sidebar.Name = "Sidebar"
	Sidebar.Position = UDim2.fromOffset(12, 42)
	Sidebar.Size = UDim2.new(0, 204, 1, -54)
	Sidebar.BackgroundTransparency = 1
	Sidebar.Parent = MainWindow

	-- 1. Server-/Brand-Card (Oben in der Sidebar: #121214, UIStroke #242428)
	local BrandCard = Instance.new("Frame")
	BrandCard.Name = "BrandCard"
	BrandCard.Size = UDim2.new(1, 0, 0, 54)
	BrandCard.BackgroundColor3 = THEME.BrandCardBg
	BrandCard.BorderSizePixel = 0
	BrandCard.Parent = Sidebar
	createCorner(BrandCard, 8)
	createStroke(BrandCard, THEME.BrandCardStroke, 1, 0.15)

	-- Brand Logo Container (Left)
	local LogoFrame = Instance.new("Frame")
	LogoFrame.Name = "LogoFrame"
	LogoFrame.AnchorPoint = Vector2.new(0, 0.5)
	LogoFrame.Position = UDim2.new(0, 10, 0.5, 0)
	LogoFrame.Size = UDim2.fromOffset(36, 36)
	LogoFrame.BackgroundColor3 = Color3.fromHex("#0D0D0F")
	LogoFrame.BorderSizePixel = 0
	LogoFrame.ClipsDescendants = true
	LogoFrame.Parent = BrandCard
	createCorner(LogoFrame, 8)
	createStroke(LogoFrame, Color3.fromHex("#28282D"), 1, 0.2)

	-- Styled "N" monogram fallback + optional custom LogoId ImageLabel
	local LogoMonogram = Instance.new("TextLabel")
	LogoMonogram.Name = "Monogram"
	LogoMonogram.Size = UDim2.fromScale(1, 1)
	LogoMonogram.BackgroundTransparency = 1
	LogoMonogram.Font = Enum.Font.GothamBlack
	LogoMonogram.Text = "N"
	LogoMonogram.TextColor3 = THEME.TextPrimary
	LogoMonogram.TextSize = 20
	LogoMonogram.Parent = LogoFrame

	local LogoRedDot = Instance.new("Frame")
	LogoRedDot.AnchorPoint = Vector2.new(1, 1)
	LogoRedDot.Position = UDim2.new(1, -5, 1, -5)
	LogoRedDot.Size = UDim2.fromOffset(4, 4)
	LogoRedDot.BackgroundColor3 = THEME.Danger
	LogoRedDot.BorderSizePixel = 0
	LogoRedDot.Parent = LogoFrame
	createCorner(LogoRedDot, UDim.new(1, 0))

	if logoId and tostring(logoId) ~= "" then
		local LogoImage = Instance.new("ImageLabel")
		LogoImage.Name = "LogoImage"
		LogoImage.Size = UDim2.fromScale(1, 1)
		LogoImage.BackgroundTransparency = 1
		LogoImage.Image = resolveIcon(logoId)
		LogoImage.ScaleType = Enum.ScaleType.Fit
		LogoImage.ZIndex = 2
		LogoImage.Parent = LogoFrame
	end

	-- Brand Title & Discord Subtitle (Middle)
	local BrandTitle = Instance.new("TextLabel")
	BrandTitle.Name = "BrandTitle"
	BrandTitle.Position = UDim2.fromOffset(54, 11)
	BrandTitle.Size = UDim2.new(1, -86, 0, 16)
	BrandTitle.BackgroundTransparency = 1
	BrandTitle.Font = Enum.Font.GothamBold
	BrandTitle.Text = windowTitle
	BrandTitle.TextColor3 = THEME.TextPrimary
	BrandTitle.TextSize = 14
	BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
	BrandTitle.TextTruncate = Enum.TextTruncate.AtEnd
	BrandTitle.Parent = BrandCard

	local BrandSubtitle = Instance.new("TextLabel")
	BrandSubtitle.Name = "BrandSubtitle"
	BrandSubtitle.Position = UDim2.fromOffset(54, 28)
	BrandSubtitle.Size = UDim2.new(1, -86, 0, 14)
	BrandSubtitle.BackgroundTransparency = 1
	BrandSubtitle.Font = Enum.Font.GothamMedium
	BrandSubtitle.Text = discordDisplay
	BrandSubtitle.TextColor3 = THEME.TextSecondary
	BrandSubtitle.TextSize = 11
	BrandSubtitle.TextXAlignment = Enum.TextXAlignment.Left
	BrandSubtitle.TextTruncate = Enum.TextTruncate.AtEnd
	BrandSubtitle.Parent = BrandCard

	-- External Link Button (Right: copies Discord link via setclipboard + Notify)
	local DiscordCopyBtn = Instance.new("TextButton")
	DiscordCopyBtn.Name = "DiscordCopyButton"
	DiscordCopyBtn.AnchorPoint = Vector2.new(1, 0.5)
	DiscordCopyBtn.Position = UDim2.new(1, -8, 0.5, 0)
	DiscordCopyBtn.Size = UDim2.fromOffset(24, 24)
	DiscordCopyBtn.BackgroundTransparency = 1
	DiscordCopyBtn.AutoButtonColor = false
	DiscordCopyBtn.Text = ""
	DiscordCopyBtn.Parent = BrandCard

	local ExternalIcon = Instance.new("ImageLabel")
	ExternalIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	ExternalIcon.Position = UDim2.fromScale(0.5, 0.5)
	ExternalIcon.Size = UDim2.fromOffset(14, 14)
	ExternalIcon.BackgroundTransparency = 1
	ExternalIcon.Image = ICONS.external
	ExternalIcon.ImageColor3 = THEME.TextSecondary
	ExternalIcon.Parent = DiscordCopyBtn

	DiscordCopyBtn.MouseEnter:Connect(function()
		tween(ExternalIcon, TWEEN_FAST, { ImageColor3 = THEME.TextPrimary })
	end)
	DiscordCopyBtn.MouseLeave:Connect(function()
		tween(ExternalIcon, TWEEN_FAST, { ImageColor3 = THEME.TextSecondary })
	end)
	DiscordCopyBtn.MouseButton1Click:Connect(function()
		pcall(function()
			if type(setclipboard) == "function" then
				setclipboard(discordFullUrl)
			elseif type(toclipboard) == "function" then
				toclipboard(discordFullUrl)
			end
		end)
		Library:Notify({
			Title = windowTitle,
			Content = "Copied " .. discordFullUrl .. " to clipboard!",
			Duration = 3,
			Icon = "check",
		})
	end)

	-- 2. Sidebar Tab-Bereich (Scrollable container for Home Tab + Dynamic Categories/Tabs)
	local TabScroll = Instance.new("ScrollingFrame")
	TabScroll.Name = "TabContainer"
	TabScroll.Position = UDim2.fromOffset(0, 64)
	TabScroll.Size = UDim2.new(1, 0, 1, -122)
	TabScroll.BackgroundTransparency = 1
	TabScroll.BorderSizePixel = 0
	TabScroll.ScrollBarThickness = 0
	TabScroll.CanvasSize = UDim2.fromOffset(0, 0)
	TabScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	TabScroll.ScrollingDirection = Enum.ScrollingDirection.Y
	TabScroll.Parent = Sidebar

	local TabListLayout = Instance.new("UIListLayout")
	TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	TabListLayout.Padding = UDim.new(0, 4)
	TabListLayout.Parent = TabScroll

	trackConnection(TabListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		TabScroll.CanvasSize = UDim2.fromOffset(0, TabListLayout.AbsoluteContentSize.Y + 6)
	end))

	-- 3. Spieler-Profil Footer (Unten links in der Sidebar)
	local SidebarFooter = Instance.new("Frame")
	SidebarFooter.Name = "PlayerFooter"
	SidebarFooter.AnchorPoint = Vector2.new(0, 1)
	SidebarFooter.Position = UDim2.new(0, 0, 1, 0)
	SidebarFooter.Size = UDim2.new(1, 0, 0, 50)
	SidebarFooter.BackgroundTransparency = 1
	SidebarFooter.Parent = Sidebar

	local FooterLine = Instance.new("Frame")
	FooterLine.Name = "DividerLine"
	FooterLine.Position = UDim2.fromOffset(0, 0)
	FooterLine.Size = UDim2.new(1, 0, 0, 1)
	FooterLine.BackgroundColor3 = THEME.SidebarFooterLine
	FooterLine.BorderSizePixel = 0
	FooterLine.Parent = SidebarFooter

	local FooterAvatar = Instance.new("ImageLabel")
	FooterAvatar.Name = "Avatar"
	FooterAvatar.Position = UDim2.fromOffset(4, 11)
	FooterAvatar.Size = UDim2.fromOffset(34, 34)
	FooterAvatar.BackgroundColor3 = THEME.BrandCardBg
	FooterAvatar.BorderSizePixel = 0
	FooterAvatar.Image = ""
	FooterAvatar.Parent = SidebarFooter
	createCorner(FooterAvatar, UDim.new(1, 0))
	createStroke(FooterAvatar, THEME.BrandCardStroke, 1, 0.2)

	local FooterDisplayName = Instance.new("TextLabel")
	FooterDisplayName.Name = "DisplayName"
	FooterDisplayName.Position = UDim2.fromOffset(46, 12)
	FooterDisplayName.Size = UDim2.new(1, -50, 0, 16)
	FooterDisplayName.BackgroundTransparency = 1
	FooterDisplayName.Font = Enum.Font.GothamBold
	FooterDisplayName.Text = LocalPlayer.DisplayName
	FooterDisplayName.TextColor3 = THEME.TextPrimary
	FooterDisplayName.TextSize = 13
	FooterDisplayName.TextXAlignment = Enum.TextXAlignment.Left
	FooterDisplayName.TextTruncate = Enum.TextTruncate.AtEnd
	FooterDisplayName.Parent = SidebarFooter

	local FooterUsername = Instance.new("TextLabel")
	FooterUsername.Name = "Username"
	FooterUsername.Position = UDim2.fromOffset(46, 28)
	FooterUsername.Size = UDim2.new(1, -50, 0, 14)
	FooterUsername.BackgroundTransparency = 1
	FooterUsername.Font = Enum.Font.GothamMedium
	FooterUsername.Text = "@" .. LocalPlayer.Name
	FooterUsername.TextColor3 = THEME.TextSecondary
	FooterUsername.TextSize = 11
	FooterUsername.TextXAlignment = Enum.TextXAlignment.Left
	FooterUsername.TextTruncate = Enum.TextTruncate.AtEnd
	FooterUsername.Parent = SidebarFooter

	-- // C. Right Content-Area (#111214 + Subtle UIGradient to #0E0E10, Corner 10px, Stroke #222326)
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Name = "ContentContainer"
	ContentContainer.Position = UDim2.fromOffset(226, 42)
	ContentContainer.Size = UDim2.new(1, -238, 1, -54)
	-- Base white so UIGradient renders exact hex colors without dark multiplication
	ContentContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ContentContainer.BorderSizePixel = 0
	ContentContainer.ClipsDescendants = true
	ContentContainer.Parent = MainWindow
	createCorner(ContentContainer, 10)
	createStroke(ContentContainer, THEME.WindowStroke, 1, 0.2)

	local ContentGradient = Instance.new("UIGradient")
	ContentGradient.Rotation = -35
	ContentGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.ContentGradBottomLeft),
		ColorSequenceKeypoint.new(0.55, THEME.ContentGradMiddle),
		ColorSequenceKeypoint.new(1, THEME.ContentGradTopRight),
	})
	ContentGradient.Parent = ContentContainer

	-- // Tab Management State
	local WindowObj = {
		ScreenGui = ScreenGui,
		MainWindow = MainWindow,
		Tabs = {},
		ActiveTab = nil,
		_SidebarOrder = 0,
	}

	local function getNextSidebarOrder(): number
		WindowObj._SidebarOrder += 1
		return WindowObj._SidebarOrder
	end

	local function activateTab(tabEntry: { [string]: any })
		if WindowObj.ActiveTab == tabEntry then
			return
		end

		-- Deactivate previous tab
		if WindowObj.ActiveTab then
			local prev = WindowObj.ActiveTab
			tween(prev.Button, TWEEN_FAST, { BackgroundTransparency = 1 })
			tween(prev.Stroke, TWEEN_FAST, { Transparency = 1 })
			tween(prev.Indicator, TWEEN_FAST, { Size = UDim2.fromOffset(2, 0), BackgroundTransparency = 1 })
			tween(prev.Icon, TWEEN_FAST, { ImageColor3 = THEME.TextSecondary })
			tween(prev.Label, TWEEN_FAST, { TextColor3 = THEME.TextSecondary })
			prev.Page.Visible = false
		end

		-- Activate new tab
		WindowObj.ActiveTab = tabEntry
		tween(tabEntry.Button, TWEEN_FAST, {
			BackgroundColor3 = THEME.TabActiveBg,
			BackgroundTransparency = 0,
		})
		tween(tabEntry.Stroke, TWEEN_FAST, {
			Color = THEME.TabActiveStroke,
			Transparency = 0.15,
		})
		tween(tabEntry.Indicator, TWEEN_MEDIUM, {
			Size = UDim2.fromOffset(2, 14),
			BackgroundTransparency = 0,
		})
		tween(tabEntry.Icon, TWEEN_FAST, { ImageColor3 = THEME.TextPrimary })
		tween(tabEntry.Label, TWEEN_FAST, { TextColor3 = THEME.TextPrimary })

		tabEntry.Page.Position = UDim2.fromOffset(0, 6)
		tabEntry.Page.Visible = true
		tween(tabEntry.Page, TWEEN_MEDIUM, { Position = UDim2.fromOffset(0, 0) })
	end

	local function createSidebarTabButton(tabName: string, iconInput: any): { [string]: any }
		local order = getNextSidebarOrder()
		local btn = Instance.new("TextButton")
		btn.Name = "Tab_" .. tabName
		btn.LayoutOrder = order
		btn.Size = UDim2.new(1, 0, 0, 34)
		btn.BackgroundColor3 = THEME.TabActiveBg
		btn.BackgroundTransparency = 1
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Text = ""
		btn.Parent = TabScroll
		createCorner(btn, 8)

		local stroke = createStroke(btn, THEME.TabActiveStroke, 1, 1)

		-- Left Vertical White Glow Indicator (2x14px, #FFFFFF, rounded)
		local indicator = Instance.new("Frame")
		indicator.Name = "ActiveIndicator"
		indicator.AnchorPoint = Vector2.new(0, 0.5)
		indicator.Position = UDim2.new(0, 0, 0.5, 0)
		indicator.Size = UDim2.fromOffset(2, 0)
		indicator.BackgroundColor3 = THEME.TabIndicator
		indicator.BackgroundTransparency = 1
		indicator.BorderSizePixel = 0
		indicator.Parent = btn
		createCorner(indicator, UDim.new(1, 0))

		local icon = Instance.new("ImageLabel")
		icon.Name = "Icon"
		icon.AnchorPoint = Vector2.new(0, 0.5)
		icon.Position = UDim2.new(0, 12, 0.5, 0)
		icon.Size = UDim2.fromOffset(16, 16)
		icon.BackgroundTransparency = 1
		icon.Image = resolveIcon(iconInput)
		icon.ImageColor3 = THEME.TextSecondary
		icon.Parent = btn

		local lbl = Instance.new("TextLabel")
		lbl.Name = "Title"
		lbl.Position = UDim2.fromOffset(36, 0)
		lbl.Size = UDim2.new(1, -44, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamMedium
		lbl.Text = tabName
		lbl.TextColor3 = THEME.TextSecondary
		lbl.TextSize = 13
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Parent = btn

		local page = Instance.new("Frame")
		page.Name = "Page_" .. tabName
		page.Size = UDim2.fromScale(1, 1)
		page.BackgroundTransparency = 1
		page.Visible = false
		page.Parent = ContentContainer

		local entry = {
			Name = tabName,
			Button = btn,
			Stroke = stroke,
			Indicator = indicator,
			Icon = icon,
			Label = lbl,
			Page = page,
		}

		btn.MouseEnter:Connect(function()
			if WindowObj.ActiveTab ~= entry then
				tween(btn, TWEEN_FAST, {
					BackgroundColor3 = THEME.TabHoverBg,
					BackgroundTransparency = 0.3,
				})
				tween(lbl, TWEEN_FAST, { TextColor3 = THEME.AccentDim })
				tween(icon, TWEEN_FAST, { ImageColor3 = THEME.AccentDim })
			end
		end)

		btn.MouseLeave:Connect(function()
			if WindowObj.ActiveTab ~= entry then
				tween(btn, TWEEN_FAST, { BackgroundTransparency = 1 })
				tween(lbl, TWEEN_FAST, { TextColor3 = THEME.TextSecondary })
				tween(icon, TWEEN_FAST, { ImageColor3 = THEME.TextSecondary })
			end
		end)

		btn.MouseButton1Click:Connect(function()
			activateTab(entry)
		end)

		table.insert(WindowObj.Tabs, entry)
		return entry
	end

	-- // Built-In "Home" Tab (ONLY Tab Created By Default!)
	local HomeEntry = createSidebarTabButton("Home", ICONS.home)
	local HomePage = HomeEntry.Page
	createPadding(HomePage, 22, 22, 24, 24)

	-- 1. Top Header ("Home" dimmed + "Welcome back, @Username")
	local HomeTitle = Instance.new("TextLabel")
	HomeTitle.Name = "HomeTitle"
	HomeTitle.Position = UDim2.fromOffset(0, 0)
	HomeTitle.Size = UDim2.new(1, 0, 0, 20)
	HomeTitle.BackgroundTransparency = 1
	HomeTitle.Font = Enum.Font.GothamBold
	HomeTitle.Text = "Home"
	HomeTitle.TextColor3 = THEME.HomeHeaderTitle
	HomeTitle.TextSize = 18
	HomeTitle.TextXAlignment = Enum.TextXAlignment.Left
	HomeTitle.Parent = HomePage

	local HomeWelcome = Instance.new("TextLabel")
	HomeWelcome.Name = "HomeWelcome"
	HomeWelcome.Position = UDim2.fromOffset(0, 22)
	HomeWelcome.Size = UDim2.new(1, 0, 0, 16)
	HomeWelcome.BackgroundTransparency = 1
	HomeWelcome.Font = Enum.Font.GothamMedium
	HomeWelcome.Text = "Welcome back, @" .. LocalPlayer.Name
	HomeWelcome.TextColor3 = THEME.HomeHeaderSub
	HomeWelcome.TextSize = 13
	HomeWelcome.TextXAlignment = Enum.TextXAlignment.Left
	HomeWelcome.Parent = HomePage

	-- 2. Large Profile Section (80x80px rounded square + DisplayName + @Username)
	local ProfileSection = Instance.new("Frame")
	ProfileSection.Name = "ProfileSection"
	ProfileSection.Position = UDim2.fromOffset(0, 58)
	ProfileSection.Size = UDim2.new(1, 0, 0, 80)
	ProfileSection.BackgroundTransparency = 1
	ProfileSection.Parent = HomePage

	local LargeAvatar = Instance.new("ImageLabel")
	LargeAvatar.Name = "LargeAvatar"
	LargeAvatar.Size = UDim2.fromOffset(80, 80)
	LargeAvatar.BackgroundColor3 = THEME.BrandCardBg
	LargeAvatar.BorderSizePixel = 0
	LargeAvatar.Image = ""
	LargeAvatar.Parent = ProfileSection
	createCorner(LargeAvatar, 8)
	createStroke(LargeAvatar, THEME.AvatarStroke, 1, 0.15)

	local LargeDisplayName = Instance.new("TextLabel")
	LargeDisplayName.Name = "DisplayName"
	LargeDisplayName.Position = UDim2.fromOffset(96, 18)
	LargeDisplayName.Size = UDim2.new(1, -100, 0, 26)
	LargeDisplayName.BackgroundTransparency = 1
	LargeDisplayName.Font = Enum.Font.GothamBold
	LargeDisplayName.Text = LocalPlayer.DisplayName
	LargeDisplayName.TextColor3 = THEME.TextPrimary
	LargeDisplayName.TextSize = 24
	LargeDisplayName.TextXAlignment = Enum.TextXAlignment.Left
	LargeDisplayName.TextTruncate = Enum.TextTruncate.AtEnd
	LargeDisplayName.Parent = ProfileSection

	local LargeUsername = Instance.new("TextLabel")
	LargeUsername.Name = "Username"
	LargeUsername.Position = UDim2.fromOffset(96, 46)
	LargeUsername.Size = UDim2.new(1, -100, 0, 18)
	LargeUsername.BackgroundTransparency = 1
	LargeUsername.Font = Enum.Font.GothamMedium
	LargeUsername.Text = "@" .. LocalPlayer.Name
	LargeUsername.TextColor3 = THEME.TextSecondary
	LargeUsername.TextSize = 14
	LargeUsername.TextXAlignment = Enum.TextXAlignment.Left
	LargeUsername.TextTruncate = Enum.TextTruncate.AtEnd
	LargeUsername.Parent = ProfileSection

	-- 3. Info / Announcement Text Block
	local AnnouncementLabel = Instance.new("TextLabel")
	AnnouncementLabel.Name = "AnnouncementText"
	AnnouncementLabel.Position = UDim2.fromOffset(0, 156)
	AnnouncementLabel.Size = UDim2.new(1, -10, 0, 56)
	AnnouncementLabel.BackgroundTransparency = 1
	AnnouncementLabel.Font = Enum.Font.GothamMedium
	AnnouncementLabel.Text = announcementText
	AnnouncementLabel.TextColor3 = THEME.HomeAnnouncement
	AnnouncementLabel.TextSize = 13
	AnnouncementLabel.LineHeight = 1.25
	AnnouncementLabel.TextWrapped = true
	AnnouncementLabel.TextXAlignment = Enum.TextXAlignment.Left
	AnnouncementLabel.TextYAlignment = Enum.TextYAlignment.Top
	AnnouncementLabel.Parent = HomePage

	-- 4. Live Server Telemetry / Statistics (Bottom of Home Tab)
	local StatsContainer = Instance.new("Frame")
	StatsContainer.Name = "StatsContainer"
	StatsContainer.AnchorPoint = Vector2.new(0, 1)
	StatsContainer.Position = UDim2.new(0, 0, 1, 0)
	StatsContainer.Size = UDim2.new(1, 0, 0, 76)
	StatsContainer.BackgroundTransparency = 1
	StatsContainer.Parent = HomePage

	local TopDivider = Instance.new("Frame")
	TopDivider.Position = UDim2.fromOffset(0, 0)
	TopDivider.Size = UDim2.new(1, 0, 0, 1)
	TopDivider.BackgroundColor3 = THEME.HomeDivider
	TopDivider.BorderSizePixel = 0
	TopDivider.Parent = StatsContainer

	-- Row 1: Place ID
	local PlaceRow = Instance.new("Frame")
	PlaceRow.Position = UDim2.fromOffset(0, 1)
	PlaceRow.Size = UDim2.new(1, 0, 0, 36)
	PlaceRow.BackgroundTransparency = 1
	PlaceRow.Parent = StatsContainer

	local PlaceKey = Instance.new("TextLabel")
	PlaceKey.Size = UDim2.new(0.35, 0, 1, 0)
	PlaceKey.BackgroundTransparency = 1
	PlaceKey.Font = Enum.Font.GothamMedium
	PlaceKey.Text = "Place ID"
	PlaceKey.TextColor3 = THEME.TextSecondary
	PlaceKey.TextSize = 13
	PlaceKey.TextXAlignment = Enum.TextXAlignment.Left
	PlaceKey.Parent = PlaceRow

	local PlaceValue = Instance.new("TextLabel")
	PlaceValue.Position = UDim2.fromScale(0.35, 0)
	PlaceValue.Size = UDim2.new(0.65, 0, 1, 0)
	PlaceValue.BackgroundTransparency = 1
	PlaceValue.Font = Enum.Font.GothamMedium
	PlaceValue.Text = tostring(game.PlaceId) .. " - Loading..."
	PlaceValue.TextColor3 = THEME.TextValue
	PlaceValue.TextSize = 13
	PlaceValue.TextXAlignment = Enum.TextXAlignment.Right
	PlaceValue.TextTruncate = Enum.TextTruncate.AtEnd
	PlaceValue.Parent = PlaceRow

	local MidDivider = Instance.new("Frame")
	MidDivider.Position = UDim2.fromOffset(0, 38)
	MidDivider.Size = UDim2.new(1, 0, 0, 1)
	MidDivider.BackgroundColor3 = THEME.HomeDivider
	MidDivider.BorderSizePixel = 0
	MidDivider.Parent = StatsContainer

	-- Row 2: Your Team
	local TeamRow = Instance.new("Frame")
	TeamRow.Position = UDim2.fromOffset(0, 39)
	TeamRow.Size = UDim2.new(1, 0, 0, 36)
	TeamRow.BackgroundTransparency = 1
	TeamRow.Parent = StatsContainer

	local TeamKey = Instance.new("TextLabel")
	TeamKey.Size = UDim2.new(0.35, 0, 1, 0)
	TeamKey.BackgroundTransparency = 1
	TeamKey.Font = Enum.Font.GothamMedium
	TeamKey.Text = "Your Team"
	TeamKey.TextColor3 = THEME.TextSecondary
	TeamKey.TextSize = 13
	TeamKey.TextXAlignment = Enum.TextXAlignment.Left
	TeamKey.Parent = TeamRow

	local TeamValue = Instance.new("TextLabel")
	TeamValue.Position = UDim2.fromScale(0.35, 0)
	TeamValue.Size = UDim2.new(0.65, 0, 1, 0)
	TeamValue.BackgroundTransparency = 1
	TeamValue.Font = Enum.Font.GothamMedium
	TeamValue.Text = if LocalPlayer.Team then LocalPlayer.Team.Name else "None"
	TeamValue.TextColor3 = THEME.TextValue
	TeamValue.TextSize = 13
	TeamValue.TextXAlignment = Enum.TextXAlignment.Right
	TeamValue.TextTruncate = Enum.TextTruncate.AtEnd
	TeamValue.Parent = TeamRow

	-- Activate Home tab by default on start
	activateTab(HomeEntry)

	-- Fetch Live Player Avatar Headshot (Async)
	task.spawn(function()
		local ok, thumb = pcall(function()
			return Players:GetUserThumbnailAsync(
				LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size420x420
			)
		end)
		if ok and thumb then
			FooterAvatar.Image = thumb
			LargeAvatar.Image = thumb
		end
	end)

	-- Fetch Live Place Name via MarketplaceService (Async)
	task.spawn(function()
		local placeId = game.PlaceId
		local gameName = game.Name
		if placeId and placeId > 0 then
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(placeId)
			end)
			if ok and type(info) == "table" and info.Name then
				gameName = tostring(info.Name)
			end
		end
		PlaceValue.Text = tostring(placeId) .. " - " .. tostring(gameName)
	end)

	-- Live Team Change Listener
	local function refreshTeam()
		TeamValue.Text = if LocalPlayer.Team and LocalPlayer.Team.Name ~= "" then LocalPlayer.Team.Name else "None"
	end
	refreshTeam()
	trackConnection(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(refreshTeam))

	function WindowObj:SetAnnouncement(newText: string)
		AnnouncementLabel.Text = tostring(newText or "")
	end

	function WindowObj:Notify(notifyConfig: { [string]: any })
		Library:Notify(notifyConfig)
	end

	-- // 2. Window:CreateCategory(name)
	function WindowObj:CreateCategory(name: string)
		local catText = string.upper(tostring(name or "CATEGORY"))
		local order = getNextSidebarOrder()

		local holder = Instance.new("Frame")
		holder.Name = "Category_" .. catText
		holder.LayoutOrder = order
		holder.Size = UDim2.new(1, 0, 0, 22)
		holder.BackgroundTransparency = 1
		holder.Parent = TabScroll

		local lbl = Instance.new("TextLabel")
		lbl.Position = UDim2.fromOffset(8, 6)
		lbl.Size = UDim2.new(1, -12, 0, 14)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamBold
		lbl.Text = catText
		lbl.TextColor3 = THEME.TextMuted
		lbl.TextSize = 10
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.Parent = holder

		local CategoryController = {}
		function CategoryController:Set(newName: string)
			lbl.Text = string.upper(tostring(newName or ""))
		end
		return CategoryController
	end

	-- // 3. Window:CreateTab(config)
	function WindowObj:CreateTab(tabConfig: any, optionalIcon: any)
		local tabName = "Tab"
		local tabIcon = optionalIcon

		if type(tabConfig) == "string" then
			tabName = tabConfig
		elseif type(tabConfig) == "table" then
			tabName = tostring(tabConfig.Name or tabConfig.Title or "Tab")
			tabIcon = tabConfig.Icon or tabConfig.Image or optionalIcon
		end

		local tabEntry = createSidebarTabButton(tabName, tabIcon or tabName)
		local Page = tabEntry.Page

		-- Top Page Header (Tab Title + Quick Search Filter)
		local PageHeader = Instance.new("Frame")
		PageHeader.Name = "PageHeader"
		PageHeader.Position = UDim2.fromOffset(20, 14)
		PageHeader.Size = UDim2.new(1, -40, 0, 30)
		PageHeader.BackgroundTransparency = 1
		PageHeader.Parent = Page

		local PageTitle = Instance.new("TextLabel")
		PageTitle.Name = "PageTitle"
		PageTitle.Size = UDim2.new(1, -170, 1, 0)
		PageTitle.BackgroundTransparency = 1
		PageTitle.Font = Enum.Font.GothamBold
		PageTitle.Text = tabName
		PageTitle.TextColor3 = THEME.TextPrimary
		PageTitle.TextSize = 16
		PageTitle.TextXAlignment = Enum.TextXAlignment.Left
		PageTitle.TextTruncate = Enum.TextTruncate.AtEnd
		PageTitle.Parent = PageHeader

		-- Search Bar inside Tab Header
		local SearchBoxFrame = Instance.new("Frame")
		SearchBoxFrame.Name = "SearchBar"
		SearchBoxFrame.AnchorPoint = Vector2.new(1, 0.5)
		SearchBoxFrame.Position = UDim2.new(1, 0, 0.5, 0)
		SearchBoxFrame.Size = UDim2.fromOffset(155, 26)
		SearchBoxFrame.BackgroundColor3 = THEME.ElementInner
		SearchBoxFrame.BorderSizePixel = 0
		SearchBoxFrame.Parent = PageHeader
		createCorner(SearchBoxFrame, 6)
		local SearchStroke = createStroke(SearchBoxFrame, THEME.ElementStroke, 1, 0.2)

		local SearchIcon = Instance.new("ImageLabel")
		SearchIcon.AnchorPoint = Vector2.new(0, 0.5)
		SearchIcon.Position = UDim2.new(0, 8, 0.5, 0)
		SearchIcon.Size = UDim2.fromOffset(12, 12)
		SearchIcon.BackgroundTransparency = 1
		SearchIcon.Image = ICONS.search
		SearchIcon.ImageColor3 = THEME.TextMuted
		SearchIcon.Parent = SearchBoxFrame

		local SearchInput = Instance.new("TextBox")
		SearchInput.Name = "SearchInput"
		SearchInput.Position = UDim2.fromOffset(26, 0)
		SearchInput.Size = UDim2.new(1, -32, 1, 0)
		SearchInput.BackgroundTransparency = 1
		SearchInput.Font = Enum.Font.GothamMedium
		SearchInput.PlaceholderText = "Search..."
		SearchInput.PlaceholderColor3 = THEME.TextMuted
		SearchInput.Text = ""
		SearchInput.TextColor3 = THEME.TextPrimary
		SearchInput.TextSize = 11
		SearchInput.TextXAlignment = Enum.TextXAlignment.Left
		SearchInput.ClearTextOnFocus = false
		SearchInput.Parent = SearchBoxFrame

		SearchInput.Focused:Connect(function()
			tween(SearchStroke, TWEEN_FAST, { Color = THEME.ElementStrokeFocus })
		end)
		SearchInput.FocusLost:Connect(function()
			tween(SearchStroke, TWEEN_FAST, { Color = THEME.ElementStroke })
		end)

		local HeaderDivider = Instance.new("Frame")
		HeaderDivider.Position = UDim2.fromOffset(20, 48)
		HeaderDivider.Size = UDim2.new(1, -40, 0, 1)
		HeaderDivider.BackgroundColor3 = THEME.HomeDivider
		HeaderDivider.BorderSizePixel = 0
		HeaderDivider.Parent = Page

		-- Scrollable Elements Container with Auto-Sorting & Auto-CanvasSize
		local ElementScroll = Instance.new("ScrollingFrame")
		ElementScroll.Name = "ElementsScrollingFrame"
		ElementScroll.Position = UDim2.fromOffset(0, 52)
		ElementScroll.Size = UDim2.new(1, 0, 1, -56)
		ElementScroll.BackgroundTransparency = 1
		ElementScroll.BorderSizePixel = 0
		ElementScroll.ScrollBarThickness = 2
		ElementScroll.ScrollBarImageColor3 = THEME.DragPill
		ElementScroll.CanvasSize = UDim2.fromOffset(0, 0)
		ElementScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		ElementScroll.ScrollingDirection = Enum.ScrollingDirection.Y
		ElementScroll.Parent = Page
		createPadding(ElementScroll, 6, 16, 20, 20)

		local ElementList = Instance.new("UIListLayout")
		ElementList.SortOrder = Enum.SortOrder.LayoutOrder
		ElementList.Padding = UDim.new(0, 8)
		ElementList.Parent = ElementScroll

		trackConnection(ElementList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			ElementScroll.CanvasSize = UDim2.fromOffset(0, ElementList.AbsoluteContentSize.Y + 24)
		end))

		-- Search Filtering Logic
		local searchableItems: { { Frame: GuiObject, Keywords: string } } = {}
		SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
			local query = string.lower(SearchInput.Text):gsub("^%s+", ""):gsub("%s+$", "")
			for _, item in ipairs(searchableItems) do
				if query == "" then
					item.Frame.Visible = true
				else
					item.Frame.Visible = string.find(item.Keywords, query, 1, true) ~= nil
				end
			end
		end)

		local TabObj = {
			_Order = 0,
			ScrollingFrame = ElementScroll,
		}

		local function nextLayoutOrder(): number
			TabObj._Order += 1
			return TabObj._Order
		end

		local function registerSearchable(frame: GuiObject, title: string?, desc: string?)
			local combined = string.lower(tostring(title or "") .. " " .. tostring(desc or ""))
			table.insert(searchableItems, {
				Frame = frame,
				Keywords = combined,
			})
		end

		-- // 4. Tab:CreateSection(name)
		function TabObj:CreateSection(sectionConfig: any)
			local secName = if type(sectionConfig) == "table"
				then tostring(sectionConfig.Name or sectionConfig.Title or "Section")
				else tostring(sectionConfig or "Section")

			local holder = Instance.new("Frame")
			holder.Name = "Section_" .. secName
			holder.LayoutOrder = nextLayoutOrder()
			holder.Size = UDim2.new(1, 0, 0, 26)
			holder.BackgroundTransparency = 1
			holder.Parent = ElementScroll

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Position = UDim2.fromOffset(0, 6)
			titleLbl.Size = UDim2.new(1, 0, 0, 16)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamBold
			titleLbl.Text = secName
			titleLbl.TextColor3 = THEME.SectionHeader
			titleLbl.TextSize = 12
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.Parent = holder

			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0, 1)
			line.Position = UDim2.new(0, 0, 1, 0)
			line.Size = UDim2.new(1, 0, 0, 1)
			line.BackgroundColor3 = THEME.HomeDivider
			line.BorderSizePixel = 0
			line.Parent = holder

			registerSearchable(holder, secName, "")

			-- Allow chaining element creation methods directly on Section OR on Tab
			local SectionObj = setmetatable({}, { __index = TabObj })
			function SectionObj:Set(newTitle: string)
				titleLbl.Text = tostring(newTitle or "")
			end
			return SectionObj
		end

		-- // 5. Tab:CreateToggle(config)
		function TabObj:CreateToggle(cfg: { [string]: any })
			cfg = cfg or {}
			local name = tostring(cfg.Name or cfg.Title or "Toggle")
			local desc = if cfg.Description and cfg.Description ~= "" then tostring(cfg.Description) else nil
			local state = cfg.Default == true
			local flag = cfg.Flag
			local callback = cfg.Callback or function() end

			local height = if desc then 52 else 40
			local card = Instance.new("TextButton")
			card.Name = "Toggle_" .. name
			card.LayoutOrder = nextLayoutOrder()
			card.Size = UDim2.new(1, 0, 0, height)
			card.BackgroundColor3 = THEME.ElementBg
			card.BorderSizePixel = 0
			card.AutoButtonColor = false
			card.Text = ""
			card.ClipsDescendants = true
			card.Parent = ElementScroll
			createCorner(card, 8)
			local stroke = createStroke(card, THEME.ElementStroke, 1, 0.2)

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Position = UDim2.fromOffset(14, if desc then 8 else 0)
			titleLbl.Size = UDim2.new(1, -74, 0, if desc then 18 else height)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamMedium
			titleLbl.Text = name
			titleLbl.TextColor3 = THEME.TextPrimary
			titleLbl.TextSize = 13
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
			titleLbl.Parent = card

			if desc then
				local descLbl = Instance.new("TextLabel")
				descLbl.Position = UDim2.fromOffset(14, 26)
				descLbl.Size = UDim2.new(1, -74, 0, 16)
				descLbl.BackgroundTransparency = 1
				descLbl.Font = Enum.Font.Gotham
				descLbl.Text = desc
				descLbl.TextColor3 = THEME.TextSecondary
				descLbl.TextSize = 11
				descLbl.TextXAlignment = Enum.TextXAlignment.Left
				descLbl.TextTruncate = Enum.TextTruncate.AtEnd
				descLbl.Parent = card
			end

			local switchBg = Instance.new("Frame")
			switchBg.Name = "Switch"
			switchBg.AnchorPoint = Vector2.new(1, 0.5)
			switchBg.Position = UDim2.new(1, -14, 0.5, 0)
			switchBg.Size = UDim2.fromOffset(38, 20)
			switchBg.BackgroundColor3 = if state then THEME.Accent else THEME.ToggleOffBg
			switchBg.BorderSizePixel = 0
			switchBg.Parent = card
			createCorner(switchBg, UDim.new(1, 0))
			local switchStroke = createStroke(switchBg, THEME.ElementStroke, 1, if state then 1 else 0.2)

			local knob = Instance.new("Frame")
			knob.Name = "Knob"
			knob.AnchorPoint = Vector2.new(0, 0.5)
			knob.Position = if state then UDim2.new(1, -17, 0.5, 0) else UDim2.new(0, 3, 0.5, 0)
			knob.Size = UDim2.fromOffset(14, 14)
			knob.BackgroundColor3 = if state then THEME.ToggleKnobOn else THEME.ToggleKnobOff
			knob.BorderSizePixel = 0
			knob.Parent = switchBg
			createCorner(knob, UDim.new(1, 0))

			local ToggleController = {}

			local function applyState(newState: boolean, fireCallback: boolean)
				state = newState == true
				if flag and flag ~= "" then
					Library.Flags[flag] = state
				end

				tween(switchBg, TWEEN_MEDIUM, {
					BackgroundColor3 = if state then THEME.Accent else THEME.ToggleOffBg,
				})
				tween(switchStroke, TWEEN_MEDIUM, {
					Transparency = if state then 1 else 0.2,
				})
				tween(knob, TWEEN_MEDIUM, {
					Position = if state then UDim2.new(1, -17, 0.5, 0) else UDim2.new(0, 3, 0.5, 0),
					BackgroundColor3 = if state then THEME.ToggleKnobOn else THEME.ToggleKnobOff,
				})

				if fireCallback then
					task.spawn(callback, state)
				end
			end

			card.MouseEnter:Connect(function()
				tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.ElementHover })
				tween(stroke, TWEEN_FAST, { Color = THEME.ElementStrokeFocus })
			end)
			card.MouseLeave:Connect(function()
				tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.ElementBg })
				tween(stroke, TWEEN_FAST, { Color = THEME.ElementStroke })
			end)

			card.MouseButton1Click:Connect(function()
				applyState(not state, true)
			end)

			function ToggleController:Set(bool: boolean)
				applyState(bool, true)
			end

			function ToggleController:Get(): boolean
				return state
			end

			if flag and flag ~= "" then
				Library.Flags[flag] = state
				Library._ConfigElements[flag] = ToggleController
			end
			if state then
				task.spawn(callback, state)
			end

			registerSearchable(card, name, desc)
			return ToggleController
		end

		-- // 6. Tab:CreateButton(config)
		function TabObj:CreateButton(cfg: { [string]: any })
			cfg = cfg or {}
			local name = tostring(cfg.Name or cfg.Title or "Button")
			local desc = if cfg.Description and cfg.Description ~= "" then tostring(cfg.Description) else nil
			local callback = cfg.Callback or function() end

			local height = if desc then 52 else 40
			local card = Instance.new("TextButton")
			card.Name = "Button_" .. name
			card.LayoutOrder = nextLayoutOrder()
			card.Size = UDim2.new(1, 0, 0, height)
			card.BackgroundColor3 = THEME.ElementBg
			card.BorderSizePixel = 0
			card.AutoButtonColor = false
			card.Text = ""
			card.ClipsDescendants = true
			card.Parent = ElementScroll
			createCorner(card, 8)
			local stroke = createStroke(card, THEME.ElementStroke, 1, 0.2)

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Position = UDim2.fromOffset(14, if desc then 8 else 0)
			titleLbl.Size = UDim2.new(1, -52, 0, if desc then 18 else height)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamMedium
			titleLbl.Text = name
			titleLbl.TextColor3 = THEME.TextPrimary
			titleLbl.TextSize = 13
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
			titleLbl.Parent = card

			local descLbl: TextLabel? = nil
			if desc then
				descLbl = Instance.new("TextLabel")
				descLbl.Position = UDim2.fromOffset(14, 26)
				descLbl.Size = UDim2.new(1, -52, 0, 16)
				descLbl.BackgroundTransparency = 1
				descLbl.Font = Enum.Font.Gotham
				descLbl.Text = desc
				descLbl.TextColor3 = THEME.TextSecondary
				descLbl.TextSize = 11
				descLbl.TextXAlignment = Enum.TextXAlignment.Left
				descLbl.TextTruncate = Enum.TextTruncate.AtEnd
				descLbl.Parent = card
			end

			local clickBadge = Instance.new("Frame")
			clickBadge.AnchorPoint = Vector2.new(1, 0.5)
			clickBadge.Position = UDim2.new(1, -14, 0.5, 0)
			clickBadge.Size = UDim2.fromOffset(22, 22)
			clickBadge.BackgroundColor3 = THEME.ElementInner
			clickBadge.BorderSizePixel = 0
			clickBadge.Parent = card
			createCorner(clickBadge, 6)
			createStroke(clickBadge, THEME.ElementStroke, 1, 0.3)

			local chevron = Instance.new("ImageLabel")
			chevron.AnchorPoint = Vector2.new(0.5, 0.5)
			chevron.Position = UDim2.fromScale(0.5, 0.5)
			chevron.Size = UDim2.fromOffset(13, 13)
			chevron.BackgroundTransparency = 1
			chevron.Image = ICONS.chevron_right
			chevron.ImageColor3 = THEME.TextSecondary
			chevron.Parent = clickBadge

			card.MouseEnter:Connect(function()
				tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.ElementHover })
				tween(stroke, TWEEN_FAST, { Color = THEME.ElementStrokeFocus })
				tween(chevron, TWEEN_FAST, { ImageColor3 = THEME.TextPrimary })
			end)
			card.MouseLeave:Connect(function()
				tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.ElementBg })
				tween(stroke, TWEEN_FAST, { Color = THEME.ElementStroke })
				tween(chevron, TWEEN_FAST, { ImageColor3 = THEME.TextSecondary })
			end)

			card.MouseButton1Click:Connect(function()
				local mousePos = UserInputService:GetMouseLocation()
				createRipple(card, mousePos)
				task.spawn(callback)
			end)

			local ButtonController = {}
			function ButtonController:SetText(newTitle: string, newDesc: string?)
				titleLbl.Text = tostring(newTitle or name)
				if descLbl and newDesc ~= nil then
					descLbl.Text = tostring(newDesc)
				end
			end
			function ButtonController:Fire()
				task.spawn(callback)
			end

			registerSearchable(card, name, desc)
			return ButtonController
		end

		-- // 7. Tab:CreateDropdown(config) (Single- & Multi-Select + Search + Smooth Resize)
		function TabObj:CreateDropdown(cfg: { [string]: any })
			cfg = cfg or {}
			local name = tostring(cfg.Name or cfg.Title or "Dropdown")
			local desc = if cfg.Description and cfg.Description ~= "" then tostring(cfg.Description) else nil
			local options: { any } = if type(cfg.Options) == "table" then table.clone(cfg.Options) else {}
			local multi = cfg.Multi == true
			local flag = cfg.Flag
			local callback = cfg.Callback or function() end

			local isOpen = false
			local selectedSingle: string? = nil
			local selectedMulti: { [string]: boolean } = {}

			if multi then
				if type(cfg.Default) == "table" then
					for k, v in pairs(cfg.Default) do
						if type(k) == "number" then
							selectedMulti[tostring(v)] = true
						elseif v == true then
							selectedMulti[tostring(k)] = true
						end
					end
				elseif type(cfg.Default) == "string" and cfg.Default ~= "" then
					selectedMulti[cfg.Default] = true
				end
			else
				if cfg.Default ~= nil then
					selectedSingle = tostring(cfg.Default)
				elseif #options > 0 then
					selectedSingle = tostring(options[1])
				end
			end

			local collapsedHeight = if desc then 54 else 42
			local card = Instance.new("Frame")
			card.Name = "Dropdown_" .. name
			card.LayoutOrder = nextLayoutOrder()
			card.Size = UDim2.new(1, 0, 0, collapsedHeight)
			card.BackgroundColor3 = THEME.ElementBg
			card.BorderSizePixel = 0
			card.ClipsDescendants = true
			card.Parent = ElementScroll
			createCorner(card, 8)
			local stroke = createStroke(card, THEME.ElementStroke, 1, 0.2)

			local headerBtn = Instance.new("TextButton")
			headerBtn.Name = "Header"
			headerBtn.Size = UDim2.new(1, 0, 0, collapsedHeight)
			headerBtn.BackgroundTransparency = 1
			headerBtn.AutoButtonColor = false
			headerBtn.Text = ""
			headerBtn.Parent = card

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Position = UDim2.fromOffset(14, if desc then 8 else 0)
			titleLbl.Size = UDim2.new(0.52, -14, 0, if desc then 18 else collapsedHeight)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamMedium
			titleLbl.Text = name
			titleLbl.TextColor3 = THEME.TextPrimary
			titleLbl.TextSize = 13
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
			titleLbl.Parent = headerBtn

			if desc then
				local descLbl = Instance.new("TextLabel")
				descLbl.Position = UDim2.fromOffset(14, 26)
				descLbl.Size = UDim2.new(0.52, -14, 0, 16)
				descLbl.BackgroundTransparency = 1
				descLbl.Font = Enum.Font.Gotham
				descLbl.Text = desc
				descLbl.TextColor3 = THEME.TextSecondary
				descLbl.TextSize = 11
				descLbl.TextXAlignment = Enum.TextXAlignment.Left
				descLbl.TextTruncate = Enum.TextTruncate.AtEnd
				descLbl.Parent = headerBtn
			end

			local valueBox = Instance.new("Frame")
			valueBox.AnchorPoint = Vector2.new(1, 0.5)
			valueBox.Position = UDim2.new(1, -14, 0.5, 0)
			valueBox.Size = UDim2.new(0.44, 0, 0, 26)
			valueBox.BackgroundColor3 = THEME.ElementInner
			valueBox.BorderSizePixel = 0
			valueBox.Parent = headerBtn
			createCorner(valueBox, 6)
			createStroke(valueBox, THEME.ElementStroke, 1, 0.2)

			local selectedLbl = Instance.new("TextLabel")
			selectedLbl.Position = UDim2.fromOffset(10, 0)
			selectedLbl.Size = UDim2.new(1, -30, 1, 0)
			selectedLbl.BackgroundTransparency = 1
			selectedLbl.Font = Enum.Font.GothamMedium
			selectedLbl.Text = "None"
			selectedLbl.TextColor3 = THEME.TextValue
			selectedLbl.TextSize = 12
			selectedLbl.TextXAlignment = Enum.TextXAlignment.Left
			selectedLbl.TextTruncate = Enum.TextTruncate.AtEnd
			selectedLbl.Parent = valueBox

			local arrowIcon = Instance.new("ImageLabel")
			arrowIcon.AnchorPoint = Vector2.new(1, 0.5)
			arrowIcon.Position = UDim2.new(1, -8, 0.5, 0)
			arrowIcon.Size = UDim2.fromOffset(13, 13)
			arrowIcon.BackgroundTransparency = 1
			arrowIcon.Image = ICONS.chevron_down
			arrowIcon.ImageColor3 = THEME.TextSecondary
			arrowIcon.Parent = valueBox

			-- Dropdown Expandable Body (Search + Option Rows)
			local dropBody = Instance.new("Frame")
			dropBody.Name = "DropdownBody"
			dropBody.Position = UDim2.fromOffset(12, collapsedHeight)
			dropBody.Size = UDim2.new(1, -24, 0, 160)
			dropBody.BackgroundTransparency = 1
			dropBody.Parent = card

			local optSearchFrame = Instance.new("Frame")
			optSearchFrame.Size = UDim2.new(1, 0, 0, 26)
			optSearchFrame.BackgroundColor3 = THEME.ElementInner
			optSearchFrame.BorderSizePixel = 0
			optSearchFrame.Parent = dropBody
			createCorner(optSearchFrame, 6)
			createStroke(optSearchFrame, THEME.ElementStroke, 1, 0.25)

			local optSearchIcon = Instance.new("ImageLabel")
			optSearchIcon.AnchorPoint = Vector2.new(0, 0.5)
			optSearchIcon.Position = UDim2.new(0, 8, 0.5, 0)
			optSearchIcon.Size = UDim2.fromOffset(12, 12)
			optSearchIcon.BackgroundTransparency = 1
			optSearchIcon.Image = ICONS.search
			optSearchIcon.ImageColor3 = THEME.TextMuted
			optSearchIcon.Parent = optSearchFrame

			local optSearchBox = Instance.new("TextBox")
			optSearchBox.Position = UDim2.fromOffset(26, 0)
			optSearchBox.Size = UDim2.new(1, -32, 1, 0)
			optSearchBox.BackgroundTransparency = 1
			optSearchBox.Font = Enum.Font.GothamMedium
			optSearchBox.PlaceholderText = "Filter options..."
			optSearchBox.PlaceholderColor3 = THEME.TextMuted
			optSearchBox.Text = ""
			optSearchBox.TextColor3 = THEME.TextPrimary
			optSearchBox.TextSize = 11
			optSearchBox.TextXAlignment = Enum.TextXAlignment.Left
			optSearchBox.ClearTextOnFocus = false
			optSearchBox.Parent = optSearchFrame

			local optScroll = Instance.new("ScrollingFrame")
			optScroll.Position = UDim2.fromOffset(0, 32)
			optScroll.Size = UDim2.new(1, 0, 1, -38)
			optScroll.BackgroundTransparency = 1
			optScroll.BorderSizePixel = 0
			optScroll.ScrollBarThickness = 2
			optScroll.ScrollBarImageColor3 = THEME.DragPill
			optScroll.CanvasSize = UDim2.fromOffset(0, 0)
			optScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
			optScroll.ScrollingDirection = Enum.ScrollingDirection.Y
			optScroll.Parent = dropBody

			local optLayout = Instance.new("UIListLayout")
			optLayout.SortOrder = Enum.SortOrder.LayoutOrder
			optLayout.Padding = UDim.new(0, 4)
			optLayout.Parent = optScroll

			local optionButtons: { [string]: { Button: TextButton, Label: TextLabel, Check: Frame, Stroke: UIStroke } } = {}

			local function getOutputValue(): any
				if multi then
					local list = {}
					for _, opt in ipairs(options) do
						local key = tostring(opt)
						if selectedMulti[key] then
							table.insert(list, key)
						end
					end
					return list
				else
					return selectedSingle
				end
			end

			local function updateVisuals()
				if multi then
					local activeNames = {}
					for _, opt in ipairs(options) do
						local key = tostring(opt)
						if selectedMulti[key] then
							table.insert(activeNames, key)
						end
					end
					selectedLbl.Text = if #activeNames > 0 then table.concat(activeNames, ", ") else "None"
				else
					selectedLbl.Text = selectedSingle or "None"
				end

				for optKey, ui in pairs(optionButtons) do
					local active = if multi then (selectedMulti[optKey] == true) else (selectedSingle == optKey)
					tween(ui.Button, TWEEN_FAST, {
						BackgroundColor3 = if active then THEME.TabActiveBg else THEME.ElementInner,
					})
					tween(ui.Stroke, TWEEN_FAST, {
						Color = if active then THEME.TabActiveStroke else THEME.ElementStroke,
						Transparency = if active then 0.1 else 0.35,
					})
					tween(ui.Label, TWEEN_FAST, {
						TextColor3 = if active then THEME.TextPrimary else THEME.TextSecondary,
					})
					tween(ui.Check, TWEEN_FAST, {
						BackgroundTransparency = if active then 0 else 1,
					})
				end
			end

			local function computeExpandedHeight(): number
				local visibleCount = 0
				for _, ui in pairs(optionButtons) do
					if ui.Button.Visible then
						visibleCount += 1
					end
				end
				local listHeight = math.clamp(visibleCount * 30, 30, 140)
				return collapsedHeight + 32 + listHeight + 10
			end

			local function updateOpenState()
				local targetHeight = if isOpen then computeExpandedHeight() else collapsedHeight
				dropBody.Size = UDim2.new(1, -24, 0, targetHeight - collapsedHeight)
				tween(card, TWEEN_MEDIUM, { Size = UDim2.new(1, 0, 0, targetHeight) })
				tween(arrowIcon, TWEEN_MEDIUM, { Rotation = if isOpen then 180 else 0 })
			end

			local function rebuildOptionRows()
				for _, child in ipairs(optScroll:GetChildren()) do
					if child:IsA("GuiObject") then
						child:Destroy()
					end
				end
				table.clear(optionButtons)

				for idx, rawOpt in ipairs(options) do
					local optKey = tostring(rawOpt)
					local row = Instance.new("TextButton")
					row.Name = "Option_" .. optKey
					row.LayoutOrder = idx
					row.Size = UDim2.new(1, 0, 0, 26)
					row.BackgroundColor3 = THEME.ElementInner
					row.BorderSizePixel = 0
					row.AutoButtonColor = false
					row.Text = ""
					row.Parent = optScroll
					createCorner(row, 6)
					local rowStroke = createStroke(row, THEME.ElementStroke, 1, 0.35)

					local ind = Instance.new("Frame")
					ind.AnchorPoint = Vector2.new(0, 0.5)
					ind.Position = UDim2.new(0, 8, 0.5, 0)
					ind.Size = UDim2.fromOffset(2, 12)
					ind.BackgroundColor3 = THEME.Accent
					ind.BackgroundTransparency = 1
					ind.BorderSizePixel = 0
					ind.Parent = row
					createCorner(ind, UDim.new(1, 0))

					local lbl = Instance.new("TextLabel")
					lbl.Position = UDim2.fromOffset(18, 0)
					lbl.Size = UDim2.new(1, -26, 1, 0)
					lbl.BackgroundTransparency = 1
					lbl.Font = Enum.Font.GothamMedium
					lbl.Text = optKey
					lbl.TextColor3 = THEME.TextSecondary
					lbl.TextSize = 12
					lbl.TextXAlignment = Enum.TextXAlignment.Left
					lbl.TextTruncate = Enum.TextTruncate.AtEnd
					lbl.Parent = row

					optionButtons[optKey] = {
						Button = row,
						Label = lbl,
						Check = ind,
						Stroke = rowStroke,
					}

					row.MouseButton1Click:Connect(function()
						if multi then
							selectedMulti[optKey] = not selectedMulti[optKey]
						else
							selectedSingle = optKey
							isOpen = false
							updateOpenState()
						end
						updateVisuals()
						local out = getOutputValue()
						if flag and flag ~= "" then
							Library.Flags[flag] = out
						end
						task.spawn(callback, out)
					end)
				end

				updateVisuals()
				if isOpen then
					updateOpenState()
				end
			end

			optSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
				local q = string.lower(optSearchBox.Text):gsub("^%s+", ""):gsub("%s+$", "")
				for optKey, ui in pairs(optionButtons) do
					ui.Button.Visible = (q == "") or (string.find(string.lower(optKey), q, 1, true) ~= nil)
				end
				if isOpen then
					updateOpenState()
				end
			end)

			headerBtn.MouseEnter:Connect(function()
				tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.ElementHover })
				tween(stroke, TWEEN_FAST, { Color = THEME.ElementStrokeFocus })
			end)
			headerBtn.MouseLeave:Connect(function()
				tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.ElementBg })
				tween(stroke, TWEEN_FAST, { Color = THEME.ElementStroke })
			end)

			headerBtn.MouseButton1Click:Connect(function()
				isOpen = not isOpen
				updateOpenState()
			end)

			rebuildOptionRows()

			local DropdownController = {}

			function DropdownController:Set(val: any)
				if multi then
					table.clear(selectedMulti)
					if type(val) == "table" then
						for k, v in pairs(val) do
							if type(k) == "number" then
								selectedMulti[tostring(v)] = true
							elseif v == true then
								selectedMulti[tostring(k)] = true
							end
						end
					elseif type(val) == "string" and val ~= "" then
						selectedMulti[val] = true
					end
				else
					selectedSingle = if val ~= nil then tostring(val) else nil
				end
				updateVisuals()
				local out = getOutputValue()
				if flag and flag ~= "" then
					Library.Flags[flag] = out
				end
				task.spawn(callback, out)
			end

			function DropdownController:Refresh(newOptions: { any }, keepSelection: boolean?)
				options = if type(newOptions) == "table" then table.clone(newOptions) else {}
				if not keepSelection then
					table.clear(selectedMulti)
					selectedSingle = if #options > 0 then tostring(options[1]) else nil
				end
				rebuildOptionRows()
			end

			function DropdownController:Get(): any
				return getOutputValue()
			end

			local initialOut = getOutputValue()
			if flag and flag ~= "" then
				Library.Flags[flag] = initialOut
				Library._ConfigElements[flag] = DropdownController
			end

			registerSearchable(card, name, desc)
			return DropdownController
		end

		-- // 8. Tab:CreateSlider(config)
		function TabObj:CreateSlider(cfg: { [string]: any })
			cfg = cfg or {}
			local name = tostring(cfg.Name or cfg.Title or "Slider")
			local desc = if cfg.Description and cfg.Description ~= "" then tostring(cfg.Description) else nil
			local minVal = tonumber(cfg.Min) or 0
			local maxVal = tonumber(cfg.Max) or 100
			local increment = tonumber(cfg.Increment) or 1
			local suffix = tostring(cfg.Suffix or cfg.ValueName or "")
			local currentVal = math.clamp(tonumber(cfg.Default) or minVal, minVal, maxVal)
			local flag = cfg.Flag
			local callback = cfg.Callback or function() end

			local decimals = 0
			local incStr = tostring(increment)
			local dotIdx = string.find(incStr, "%.")
			if dotIdx then
				decimals = #incStr - dotIdx
			end

			local height = if desc then 64 else 52
			local card = Instance.new("Frame")
			card.Name = "Slider_" .. name
			card.LayoutOrder = nextLayoutOrder()
			card.Size = UDim2.new(1, 0, 0, height)
			card.BackgroundColor3 = THEME.ElementBg
			card.BorderSizePixel = 0
			card.Parent = ElementScroll
			createCorner(card, 8)
			local stroke = createStroke(card, THEME.ElementStroke, 1, 0.2)

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Position = UDim2.fromOffset(14, 8)
			titleLbl.Size = UDim2.new(1, -110, 0, 16)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamMedium
			titleLbl.Text = name
			titleLbl.TextColor3 = THEME.TextPrimary
			titleLbl.TextSize = 13
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
			titleLbl.Parent = card

			if desc then
				local descLbl = Instance.new("TextLabel")
				descLbl.Position = UDim2.fromOffset(14, 24)
				descLbl.Size = UDim2.new(1, -110, 0, 14)
				descLbl.BackgroundTransparency = 1
				descLbl.Font = Enum.Font.Gotham
				descLbl.Text = desc
				descLbl.TextColor3 = THEME.TextSecondary
				descLbl.TextSize = 11
				descLbl.TextXAlignment = Enum.TextXAlignment.Left
				descLbl.TextTruncate = Enum.TextTruncate.AtEnd
				descLbl.Parent = card
			end

			local valueLbl = Instance.new("TextLabel")
			valueLbl.AnchorPoint = Vector2.new(1, 0)
			valueLbl.Position = UDim2.new(1, -14, 0, 8)
			valueLbl.Size = UDim2.fromOffset(90, 16)
			valueLbl.BackgroundTransparency = 1
			valueLbl.Font = Enum.Font.GothamBold
			valueLbl.TextColor3 = THEME.TextValue
			valueLbl.TextSize = 12
			valueLbl.TextXAlignment = Enum.TextXAlignment.Right
			valueLbl.Parent = card

			local trackBtn = Instance.new("TextButton")
			trackBtn.Name = "Track"
			trackBtn.AnchorPoint = Vector2.new(0, 1)
			trackBtn.Position = UDim2.new(0, 14, 1, -12)
			trackBtn.Size = UDim2.new(1, -28, 0, 6)
			trackBtn.BackgroundColor3 = THEME.ToggleOffBg
			trackBtn.BorderSizePixel = 0
			trackBtn.AutoButtonColor = false
			trackBtn.Text = ""
			trackBtn.Parent = card
			createCorner(trackBtn, UDim.new(1, 0))

			local fill = Instance.new("Frame")
			fill.Name = "Fill"
			fill.Size = UDim2.fromScale(0, 1)
			fill.BackgroundColor3 = THEME.Accent
			fill.BorderSizePixel = 0
			fill.Parent = trackBtn
			createCorner(fill, UDim.new(1, 0))

			local knob = Instance.new("Frame")
			knob.Name = "Knob"
			knob.AnchorPoint = Vector2.new(0.5, 0.5)
			knob.Position = UDim2.fromScale(1, 0.5)
			knob.Size = UDim2.fromOffset(12, 12)
			knob.BackgroundColor3 = THEME.Accent
			knob.BorderSizePixel = 0
			knob.Parent = fill
			createCorner(knob, UDim.new(1, 0))

			local function formatValue(val: number): string
				if decimals > 0 then
					return string.format("%." .. tostring(decimals) .. "f%s", val, suffix)
				end
				return tostring(math.round(val)) .. suffix
			end

			local function setSliderValue(rawVal: number, fireCallback: boolean)
				local stepped = minVal + math.round((rawVal - minVal) / increment) * increment
				local factor = 10 ^ decimals
				stepped = math.floor(stepped * factor + 0.5) / factor
				currentVal = math.clamp(stepped, minVal, maxVal)

				local alpha = if maxVal > minVal then (currentVal - minVal) / (maxVal - minVal) else 0
				tween(fill, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Size = UDim2.fromScale(alpha, 1),
				})
				valueLbl.Text = formatValue(currentVal)

				if flag and flag ~= "" then
					Library.Flags[flag] = currentVal
				end
				if fireCallback then
					task.spawn(callback, currentVal)
				end
			end

			local sliding = false
			local function updateFromInput(inputPos: Vector3)
				local absPos = trackBtn.AbsolutePosition.X
				local absWidth = math.max(trackBtn.AbsoluteSize.X, 1)
				local alpha = math.clamp((inputPos.X - absPos) / absWidth, 0, 1)
				local raw = minVal + (maxVal - minVal) * alpha
				setSliderValue(raw, true)
			end

			trackBtn.InputBegan:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = true
					updateFromInput(input.Position)
				end
			end)

			trackConnection(UserInputService.InputChanged:Connect(function(input: InputObject)
				if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromInput(input.Position)
				end
			end))

			trackConnection(UserInputService.InputEnded:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					sliding = false
				end
			end))

			card.MouseEnter:Connect(function()
				tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.ElementHover })
				tween(stroke, TWEEN_FAST, { Color = THEME.ElementStrokeFocus })
			end)
			card.MouseLeave:Connect(function()
				tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.ElementBg })
				tween(stroke, TWEEN_FAST, { Color = THEME.ElementStroke })
			end)

			setSliderValue(currentVal, false)

			local SliderController = {}
			function SliderController:Set(val: number)
				setSliderValue(tonumber(val) or minVal, true)
			end
			function SliderController:Get(): number
				return currentVal
			end

			if flag and flag ~= "" then
				Library.Flags[flag] = currentVal
				Library._ConfigElements[flag] = SliderController
			end

			registerSearchable(card, name, desc)
			return SliderController
		end

		-- // 9. Tab:CreateInput(config) / Tab:CreateTextBox(config)
		function TabObj:CreateInput(cfg: { [string]: any })
			cfg = cfg or {}
			local name = tostring(cfg.Name or cfg.Title or "Input")
			local desc = if cfg.Description and cfg.Description ~= "" then tostring(cfg.Description) else nil
			local placeholder = tostring(cfg.Placeholder or cfg.PlaceholderText or "Enter text...")
			local currentText = tostring(cfg.Default or "")
			local numericOnly = cfg.NumericOnly == true
			local clearOnFocus = cfg.ClearTextOnFocus == true
			local flag = cfg.Flag
			local callback = cfg.Callback or function() end

			local height = if desc then 54 else 42
			local card = Instance.new("Frame")
			card.Name = "Input_" .. name
			card.LayoutOrder = nextLayoutOrder()
			card.Size = UDim2.new(1, 0, 0, height)
			card.BackgroundColor3 = THEME.ElementBg
			card.BorderSizePixel = 0
			card.Parent = ElementScroll
			createCorner(card, 8)
			local stroke = createStroke(card, THEME.ElementStroke, 1, 0.2)

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Position = UDim2.fromOffset(14, if desc then 8 else 0)
			titleLbl.Size = UDim2.new(0.52, -14, 0, if desc then 18 else height)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamMedium
			titleLbl.Text = name
			titleLbl.TextColor3 = THEME.TextPrimary
			titleLbl.TextSize = 13
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
			titleLbl.Parent = card

			if desc then
				local descLbl = Instance.new("TextLabel")
				descLbl.Position = UDim2.fromOffset(14, 26)
				descLbl.Size = UDim2.new(0.52, -14, 0, 16)
				descLbl.BackgroundTransparency = 1
				descLbl.Font = Enum.Font.Gotham
				descLbl.Text = desc
				descLbl.TextColor3 = THEME.TextSecondary
				descLbl.TextSize = 11
				descLbl.TextXAlignment = Enum.TextXAlignment.Left
				descLbl.TextTruncate = Enum.TextTruncate.AtEnd
				descLbl.Parent = card
			end

			local inputHolder = Instance.new("Frame")
			inputHolder.AnchorPoint = Vector2.new(1, 0.5)
			inputHolder.Position = UDim2.new(1, -14, 0.5, 0)
			inputHolder.Size = UDim2.new(0.44, 0, 0, 26)
			inputHolder.BackgroundColor3 = THEME.ElementInner
			inputHolder.BorderSizePixel = 0
			inputHolder.Parent = card
			createCorner(inputHolder, 6)
			local inputStroke = createStroke(inputHolder, THEME.ElementStroke, 1, 0.2)

			local textBox = Instance.new("TextBox")
			textBox.Position = UDim2.fromOffset(10, 0)
			textBox.Size = UDim2.new(1, -20, 1, 0)
			textBox.BackgroundTransparency = 1
			textBox.Font = Enum.Font.GothamMedium
			textBox.PlaceholderText = placeholder
			textBox.PlaceholderColor3 = THEME.TextMuted
			textBox.Text = currentText
			textBox.TextColor3 = THEME.TextPrimary
			textBox.TextSize = 12
			textBox.TextXAlignment = Enum.TextXAlignment.Left
			textBox.TextTruncate = Enum.TextTruncate.AtEnd
			textBox.ClearTextOnFocus = clearOnFocus
			textBox.Parent = inputHolder

			if numericOnly then
				textBox:GetPropertyChangedSignal("Text"):Connect(function()
					local filtered = textBox.Text:gsub("[^%d%.%-]", "")
					if filtered ~= textBox.Text then
						textBox.Text = filtered
					end
				end)
			end

			textBox.Focused:Connect(function()
				tween(inputStroke, TWEEN_FAST, { Color = THEME.Accent, Transparency = 0.1 })
			end)

			textBox.FocusLost:Connect(function()
				tween(inputStroke, TWEEN_FAST, { Color = THEME.ElementStroke, Transparency = 0.2 })
				currentText = textBox.Text
				if flag and flag ~= "" then
					Library.Flags[flag] = currentText
				end
				task.spawn(callback, currentText)
			end)

			local InputController = {}
			function InputController:Set(newVal: string)
				currentText = tostring(newVal or "")
				textBox.Text = currentText
				if flag and flag ~= "" then
					Library.Flags[flag] = currentText
				end
				task.spawn(callback, currentText)
			end
			function InputController:Get(): string
				return currentText
			end

			if flag and flag ~= "" then
				Library.Flags[flag] = currentText
				Library._ConfigElements[flag] = InputController
			end

			registerSearchable(card, name, desc)
			return InputController
		end

		TabObj.CreateTextBox = TabObj.CreateInput

		-- // 10. Tab:CreateKeybind(config)
		function TabObj:CreateKeybind(cfg: { [string]: any })
			cfg = cfg or {}
			local name = tostring(cfg.Name or cfg.Title or "Keybind")
			local desc = if cfg.Description and cfg.Description ~= "" then tostring(cfg.Description) else nil
			local currentKey: EnumItem? = cfg.Default or Enum.KeyCode.E
			local mode = tostring(cfg.Mode or "Toggle") -- "Toggle" | "Hold"
			local flag = cfg.Flag
			local callback = cfg.Callback or function() end
			local changedCallback = cfg.ChangedCallback or function() end

			local binding = false
			local toggleActive = false

			local height = if desc then 52 else 40
			local card = Instance.new("Frame")
			card.Name = "Keybind_" .. name
			card.LayoutOrder = nextLayoutOrder()
			card.Size = UDim2.new(1, 0, 0, height)
			card.BackgroundColor3 = THEME.ElementBg
			card.BorderSizePixel = 0
			card.Parent = ElementScroll
			createCorner(card, 8)
			createStroke(card, THEME.ElementStroke, 1, 0.2)

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Position = UDim2.fromOffset(14, if desc then 8 else 0)
			titleLbl.Size = UDim2.new(1, -110, 0, if desc then 18 else height)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamMedium
			titleLbl.Text = name
			titleLbl.TextColor3 = THEME.TextPrimary
			titleLbl.TextSize = 13
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
			titleLbl.Parent = card

			if desc then
				local descLbl = Instance.new("TextLabel")
				descLbl.Position = UDim2.fromOffset(14, 26)
				descLbl.Size = UDim2.new(1, -110, 0, 16)
				descLbl.BackgroundTransparency = 1
				descLbl.Font = Enum.Font.Gotham
				descLbl.Text = desc
				descLbl.TextColor3 = THEME.TextSecondary
				descLbl.TextSize = 11
				descLbl.TextXAlignment = Enum.TextXAlignment.Left
				descLbl.TextTruncate = Enum.TextTruncate.AtEnd
				descLbl.Parent = card
			end

			local bindBtn = Instance.new("TextButton")
			bindBtn.AnchorPoint = Vector2.new(1, 0.5)
			bindBtn.Position = UDim2.new(1, -14, 0.5, 0)
			bindBtn.Size = UDim2.fromOffset(72, 24)
			bindBtn.BackgroundColor3 = THEME.ElementInner
			bindBtn.BorderSizePixel = 0
			bindBtn.AutoButtonColor = false
			bindBtn.Font = Enum.Font.GothamBold
			bindBtn.Text = "[" .. formatKeyCode(currentKey) .. "]"
			bindBtn.TextColor3 = THEME.TextValue
			bindBtn.TextSize = 11
			bindBtn.Parent = card
			createCorner(bindBtn, 6)
			local bindStroke = createStroke(bindBtn, THEME.ElementStroke, 1, 0.2)

			local function updateKeyDisplay()
				local txt = "[" .. formatKeyCode(currentKey) .. "]"
				bindBtn.Text = txt
				local bounds = TextService:GetTextSize(txt, 11, Enum.Font.GothamBold, Vector2.new(200, 24))
				bindBtn.Size = UDim2.fromOffset(math.max(64, bounds.X + 20), 24)
			end
			updateKeyDisplay()

			bindBtn.MouseButton1Click:Connect(function()
				binding = true
				bindBtn.Text = "[ ... ]"
				tween(bindStroke, TWEEN_FAST, { Color = THEME.Accent })
			end)

			trackConnection(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
				if binding then
					if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
						currentKey = nil
					elseif input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
						currentKey = input.KeyCode
					elseif
						input.UserInputType == Enum.UserInputType.MouseButton1
						or input.UserInputType == Enum.UserInputType.MouseButton2
						or input.UserInputType == Enum.UserInputType.MouseButton3
					then
						currentKey = input.UserInputType
					else
						return
					end

					binding = false
					tween(bindStroke, TWEEN_FAST, { Color = THEME.ElementStroke })
					updateKeyDisplay()
					if flag and flag ~= "" then
						Library.Flags[flag] = currentKey
					end
					task.spawn(changedCallback, currentKey)
					return
				end

				if gameProcessed or UserInputService:GetFocusedTextBox() or not currentKey then
					return
				end

				if input.KeyCode == currentKey or input.UserInputType == currentKey then
					if string.lower(mode) == "hold" then
						toggleActive = true
						task.spawn(callback, true, currentKey)
					else
						toggleActive = not toggleActive
						task.spawn(callback, toggleActive, currentKey)
					end
				end
			end))

			trackConnection(UserInputService.InputEnded:Connect(function(input: InputObject)
				if not binding and currentKey and string.lower(mode) == "hold" then
					if input.KeyCode == currentKey or input.UserInputType == currentKey then
						toggleActive = false
						task.spawn(callback, false, currentKey)
					end
				end
			end))

			local KeybindController = {}
			function KeybindController:Set(newKey: EnumItem?)
				currentKey = newKey
				updateKeyDisplay()
				if flag and flag ~= "" then
					Library.Flags[flag] = currentKey
				end
				task.spawn(changedCallback, currentKey)
			end
			function KeybindController:Get(): EnumItem?
				return currentKey
			end

			if flag and flag ~= "" then
				Library.Flags[flag] = currentKey
				Library._ConfigElements[flag] = KeybindController
			end

			registerSearchable(card, name, desc)
			return KeybindController
		end

		-- // 11. Tab:CreateColorPicker(config) (Full HSV Picker + Hex/RGB Inputs)
		function TabObj:CreateColorPicker(cfg: { [string]: any })
			cfg = cfg or {}
			local name = tostring(cfg.Name or cfg.Title or "Color Picker")
			local desc = if cfg.Description and cfg.Description ~= "" then tostring(cfg.Description) else nil
			local currentColor: Color3 = cfg.Default or Color3.fromRGB(255, 255, 255)
			local flag = cfg.Flag
			local callback = cfg.Callback or function() end

			local h, s, v = currentColor:ToHSV()
			local isOpen = false

			local collapsedHeight = if desc then 52 else 40
			local expandedHeight = collapsedHeight + 156

			local card = Instance.new("Frame")
			card.Name = "ColorPicker_" .. name
			card.LayoutOrder = nextLayoutOrder()
			card.Size = UDim2.new(1, 0, 0, collapsedHeight)
			card.BackgroundColor3 = THEME.ElementBg
			card.BorderSizePixel = 0
			card.ClipsDescendants = true
			card.Parent = ElementScroll
			createCorner(card, 8)
			local stroke = createStroke(card, THEME.ElementStroke, 1, 0.2)

			local headerBtn = Instance.new("TextButton")
			headerBtn.Size = UDim2.new(1, 0, 0, collapsedHeight)
			headerBtn.BackgroundTransparency = 1
			headerBtn.AutoButtonColor = false
			headerBtn.Text = ""
			headerBtn.Parent = card

			local titleLbl = Instance.new("TextLabel")
			titleLbl.Position = UDim2.fromOffset(14, if desc then 8 else 0)
			titleLbl.Size = UDim2.new(1, -110, 0, if desc then 18 else collapsedHeight)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamMedium
			titleLbl.Text = name
			titleLbl.TextColor3 = THEME.TextPrimary
			titleLbl.TextSize = 13
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
			titleLbl.Parent = headerBtn

			if desc then
				local descLbl = Instance.new("TextLabel")
				descLbl.Position = UDim2.fromOffset(14, 26)
				descLbl.Size = UDim2.new(1, -110, 0, 16)
				descLbl.BackgroundTransparency = 1
				descLbl.Font = Enum.Font.Gotham
				descLbl.Text = desc
				descLbl.TextColor3 = THEME.TextSecondary
				descLbl.TextSize = 11
				descLbl.TextXAlignment = Enum.TextXAlignment.Left
				descLbl.TextTruncate = Enum.TextTruncate.AtEnd
				descLbl.Parent = headerBtn
			end

			local previewHexLbl = Instance.new("TextLabel")
			previewHexLbl.AnchorPoint = Vector2.new(1, 0.5)
			previewHexLbl.Position = UDim2.new(1, -48, 0.5, 0)
			previewHexLbl.Size = UDim2.fromOffset(64, 20)
			previewHexLbl.BackgroundTransparency = 1
			previewHexLbl.Font = Enum.Font.GothamMedium
			previewHexLbl.Text = color3ToHex(currentColor)
			previewHexLbl.TextColor3 = THEME.TextSecondary
			previewHexLbl.TextSize = 11
			previewHexLbl.TextXAlignment = Enum.TextXAlignment.Right
			previewHexLbl.Parent = headerBtn

			local colorSwatch = Instance.new("Frame")
			colorSwatch.AnchorPoint = Vector2.new(1, 0.5)
			colorSwatch.Position = UDim2.new(1, -14, 0.5, 0)
			colorSwatch.Size = UDim2.fromOffset(26, 18)
			colorSwatch.BackgroundColor3 = currentColor
			colorSwatch.BorderSizePixel = 0
			colorSwatch.Parent = headerBtn
			createCorner(colorSwatch, 5)
			createStroke(colorSwatch, THEME.ElementStrokeFocus, 1, 0.1)

			-- Picker Body
			local pickerBody = Instance.new("Frame")
			pickerBody.Position = UDim2.fromOffset(14, collapsedHeight + 4)
			pickerBody.Size = UDim2.new(1, -28, 0, 142)
			pickerBody.BackgroundTransparency = 1
			pickerBody.Parent = card

			-- Saturation / Value 2D Canvas
			local svCanvas = Instance.new("TextButton")
			svCanvas.Name = "SVCanvas"
			svCanvas.Position = UDim2.fromOffset(0, 0)
			svCanvas.Size = UDim2.new(1, -135, 0, 110)
			svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svCanvas.BorderSizePixel = 0
			svCanvas.AutoButtonColor = false
			svCanvas.Text = ""
			svCanvas.ClipsDescendants = true
			svCanvas.Parent = pickerBody
			createCorner(svCanvas, 6)
			createStroke(svCanvas, THEME.ElementStroke, 1, 0.2)

			local satOverlay = Instance.new("Frame")
			satOverlay.Size = UDim2.fromScale(1, 1)
			satOverlay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			satOverlay.BorderSizePixel = 0
			satOverlay.Parent = svCanvas
			createCorner(satOverlay, 6)

			local satGrad = Instance.new("UIGradient")
			satGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			})
			satGrad.Parent = satOverlay

			local valOverlay = Instance.new("Frame")
			valOverlay.Size = UDim2.fromScale(1, 1)
			valOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			valOverlay.BorderSizePixel = 0
			valOverlay.ZIndex = 2
			valOverlay.Parent = svCanvas
			createCorner(valOverlay, 6)

			local valGrad = Instance.new("UIGradient")
			valGrad.Rotation = 90
			valGrad.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(1, 0),
			})
			valGrad.Parent = valOverlay

			local svCursor = Instance.new("Frame")
			svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
			svCursor.Position = UDim2.fromScale(s, 1 - v)
			svCursor.Size = UDim2.fromOffset(10, 10)
			svCursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			svCursor.BorderSizePixel = 0
			svCursor.ZIndex = 4
			svCursor.Parent = svCanvas
			createCorner(svCursor, UDim.new(1, 0))
			createStroke(svCursor, Color3.fromRGB(0, 0, 0), 1.5, 0)

			-- Horizontal Hue Bar
			local hueBar = Instance.new("TextButton")
			hueBar.Name = "HueBar"
			hueBar.Position = UDim2.fromOffset(0, 118)
			hueBar.Size = UDim2.new(1, -135, 0, 14)
			hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			hueBar.BorderSizePixel = 0
			hueBar.AutoButtonColor = false
			hueBar.Text = ""
			hueBar.Parent = pickerBody
			createCorner(hueBar, UDim.new(1, 0))
			createStroke(hueBar, THEME.ElementStroke, 1, 0.2)

			local hueGrad = Instance.new("UIGradient")
			hueGrad.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
			})
			hueGrad.Parent = hueBar

			local hueKnob = Instance.new("Frame")
			hueKnob.AnchorPoint = Vector2.new(0.5, 0.5)
			hueKnob.Position = UDim2.fromScale(h, 0.5)
			hueKnob.Size = UDim2.fromOffset(8, 16)
			hueKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			hueKnob.BorderSizePixel = 0
			hueKnob.Parent = hueBar
			createCorner(hueKnob, UDim.new(1, 0))
			createStroke(hueKnob, Color3.fromRGB(0, 0, 0), 1.2, 0)

			-- Right-Side Hex & RGB Inputs
			local inputsPanel = Instance.new("Frame")
			inputsPanel.AnchorPoint = Vector2.new(1, 0)
			inputsPanel.Position = UDim2.new(1, 0, 0, 0)
			inputsPanel.Size = UDim2.fromOffset(125, 132)
			inputsPanel.BackgroundTransparency = 1
			inputsPanel.Parent = pickerBody

			local function createMiniField(label: string, yPos: number): TextBox
				local row = Instance.new("Frame")
				row.Position = UDim2.fromOffset(0, yPos)
				row.Size = UDim2.new(1, 0, 0, 28)
				row.BackgroundColor3 = THEME.ElementInner
				row.BorderSizePixel = 0
				row.Parent = inputsPanel
				createCorner(row, 6)
				createStroke(row, THEME.ElementStroke, 1, 0.25)

				local tag = Instance.new("TextLabel")
				tag.Position = UDim2.fromOffset(8, 0)
				tag.Size = UDim2.fromOffset(28, 28)
				tag.BackgroundTransparency = 1
				tag.Font = Enum.Font.GothamBold
				tag.Text = label
				tag.TextColor3 = THEME.TextSecondary
				tag.TextSize = 10
				tag.TextXAlignment = Enum.TextXAlignment.Left
				tag.Parent = row

				local box = Instance.new("TextBox")
				box.Position = UDim2.fromOffset(38, 0)
				box.Size = UDim2.new(1, -44, 1, 0)
				box.BackgroundTransparency = 1
				box.Font = Enum.Font.GothamMedium
				box.Text = ""
				box.TextColor3 = THEME.TextPrimary
				box.TextSize = 11
				box.TextXAlignment = Enum.TextXAlignment.Right
				box.ClearTextOnFocus = false
				box.Parent = row
				return box
			end

			local hexBox = createMiniField("HEX", 0)
			local rBox = createMiniField("R", 34)
			local gBox = createMiniField("G", 68)
			local bBox = createMiniField("B", 102)

			local function syncColorVisuals(fireCallback: boolean)
				currentColor = Color3.fromHSV(h, s, v)
				colorSwatch.BackgroundColor3 = currentColor
				svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
				svCursor.Position = UDim2.fromScale(s, 1 - v)
				hueKnob.Position = UDim2.fromScale(h, 0.5)

				local hexStr = color3ToHex(currentColor)
				previewHexLbl.Text = hexStr
				hexBox.Text = hexStr
				rBox.Text = tostring(math.round(currentColor.R * 255))
				gBox.Text = tostring(math.round(currentColor.G * 255))
				bBox.Text = tostring(math.round(currentColor.B * 255))

				if flag and flag ~= "" then
					Library.Flags[flag] = currentColor
				end
				if fireCallback then
					task.spawn(callback, currentColor)
				end
			end

			local draggingSV = false
			local draggingHue = false

			local function updateSV(pos: Vector3)
				local absPos = svCanvas.AbsolutePosition
				local absSize = svCanvas.AbsoluteSize
				s = math.clamp((pos.X - absPos.X) / math.max(absSize.X, 1), 0, 1)
				v = 1 - math.clamp((pos.Y - absPos.Y) / math.max(absSize.Y, 1), 0, 1)
				syncColorVisuals(true)
			end

			local function updateHue(pos: Vector3)
				local absPos = hueBar.AbsolutePosition
				local absSize = hueBar.AbsoluteSize
				h = math.clamp((pos.X - absPos.X) / math.max(absSize.X, 1), 0, 1)
				syncColorVisuals(true)
			end

			svCanvas.InputBegan:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					draggingSV = true
					updateSV(input.Position)
				end
			end)

			hueBar.InputBegan:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					draggingHue = true
					updateHue(input.Position)
				end
			end)

			trackConnection(UserInputService.InputChanged:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
					if draggingSV then
						updateSV(input.Position)
					elseif draggingHue then
						updateHue(input.Position)
					end
				end
			end))

			trackConnection(UserInputService.InputEnded:Connect(function(input: InputObject)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					draggingSV = false
					draggingHue = false
				end
			end))

			hexBox.FocusLost:Connect(function()
				local parsed = hexToColor3(hexBox.Text)
				if parsed then
					h, s, v = parsed:ToHSV()
					syncColorVisuals(true)
				else
					hexBox.Text = color3ToHex(currentColor)
				end
			end)

			local function onRgbEdited()
				local r = math.clamp(tonumber(rBox.Text) or 0, 0, 255)
				local g = math.clamp(tonumber(gBox.Text) or 0, 0, 255)
				local b = math.clamp(tonumber(bBox.Text) or 0, 0, 255)
				local c = Color3.fromRGB(r, g, b)
				h, s, v = c:ToHSV()
				syncColorVisuals(true)
			end
			rBox.FocusLost:Connect(onRgbEdited)
			gBox.FocusLost:Connect(onRgbEdited)
			bBox.FocusLost:Connect(onRgbEdited)

			headerBtn.MouseButton1Click:Connect(function()
				isOpen = not isOpen
				tween(card, TWEEN_MEDIUM, {
					Size = UDim2.new(1, 0, 0, if isOpen then expandedHeight else collapsedHeight),
				})
			end)

			headerBtn.MouseEnter:Connect(function()
				tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.ElementHover })
				tween(stroke, TWEEN_FAST, { Color = THEME.ElementStrokeFocus })
			end)
			headerBtn.MouseLeave:Connect(function()
				tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.ElementBg })
				tween(stroke, TWEEN_FAST, { Color = THEME.ElementStroke })
			end)

			syncColorVisuals(false)

			local ColorPickerController = {}
			function ColorPickerController:Set(newColor: Color3)
				if typeof(newColor) == "Color3" then
					h, s, v = newColor:ToHSV()
					syncColorVisuals(true)
				end
			end
			function ColorPickerController:Get(): Color3
				return currentColor
			end

			if flag and flag ~= "" then
				Library.Flags[flag] = currentColor
				Library._ConfigElements[flag] = ColorPickerController
			end

			registerSearchable(card, name, desc)
			return ColorPickerController
		end

		-- // 12a. Tab:CreateLabel(text)
		function TabObj:CreateLabel(textInput: any)
			local labelText = if type(textInput) == "table"
				then tostring(textInput.Text or textInput.Name or textInput.Title or "")
				else tostring(textInput or "")

			local card = Instance.new("Frame")
			card.Name = "Label"
			card.LayoutOrder = nextLayoutOrder()
			card.Size = UDim2.new(1, 0, 0, 34)
			card.BackgroundColor3 = THEME.ElementBg
			card.BorderSizePixel = 0
			card.Parent = ElementScroll
			createCorner(card, 8)
			createStroke(card, THEME.ElementStroke, 1, 0.25)

			local dot = Instance.new("Frame")
			dot.AnchorPoint = Vector2.new(0, 0.5)
			dot.Position = UDim2.new(0, 14, 0.5, 0)
			dot.Size = UDim2.fromOffset(4, 4)
			dot.BackgroundColor3 = THEME.TextSecondary
			dot.BorderSizePixel = 0
			dot.Parent = card
			createCorner(dot, UDim.new(1, 0))

			local lbl = Instance.new("TextLabel")
			lbl.Position = UDim2.fromOffset(26, 0)
			lbl.Size = UDim2.new(1, -38, 1, 0)
			lbl.BackgroundTransparency = 1
			lbl.Font = Enum.Font.GothamMedium
			lbl.Text = labelText
			lbl.TextColor3 = THEME.TextValue
			lbl.TextSize = 12
			lbl.TextXAlignment = Enum.TextXAlignment.Left
			lbl.TextTruncate = Enum.TextTruncate.AtEnd
			lbl.Parent = card

			local LabelController = {}
			function LabelController:Set(newText: string)
				lbl.Text = tostring(newText or "")
			end
			function LabelController:Get(): string
				return lbl.Text
			end

			registerSearchable(card, labelText, "")
			return LabelController
		end

		-- // 12b. Tab:CreateParagraph({Title, Content})
		function TabObj:CreateParagraph(cfg: { [string]: any })
			cfg = cfg or {}
			local titleText = tostring(cfg.Title or cfg.Name or "Information")
			local contentText = tostring(cfg.Content or cfg.Description or "")

			local card = Instance.new("Frame")
			card.Name = "Paragraph_" .. titleText
			card.LayoutOrder = nextLayoutOrder()
			card.Size = UDim2.new(1, 0, 0, 64)
			card.AutomaticSize = Enum.AutomaticSize.Y
			card.BackgroundColor3 = THEME.ElementBg
			card.BorderSizePixel = 0
			card.Parent = ElementScroll
			createCorner(card, 8)
			createStroke(card, THEME.ElementStroke, 1, 0.2)
			createPadding(card, 10, 12, 14, 14)

			local layout = Instance.new("UIListLayout")
			layout.SortOrder = Enum.SortOrder.LayoutOrder
			layout.Padding = UDim.new(0, 4)
			layout.Parent = card

			local titleLbl = Instance.new("TextLabel")
			titleLbl.LayoutOrder = 1
			titleLbl.Size = UDim2.new(1, 0, 0, 16)
			titleLbl.BackgroundTransparency = 1
			titleLbl.Font = Enum.Font.GothamBold
			titleLbl.Text = titleText
			titleLbl.TextColor3 = THEME.TextPrimary
			titleLbl.TextSize = 13
			titleLbl.TextXAlignment = Enum.TextXAlignment.Left
			titleLbl.Parent = card

			local contentLbl = Instance.new("TextLabel")
			contentLbl.LayoutOrder = 2
			contentLbl.Size = UDim2.new(1, 0, 0, 0)
			contentLbl.AutomaticSize = Enum.AutomaticSize.Y
			contentLbl.BackgroundTransparency = 1
			contentLbl.Font = Enum.Font.GothamMedium
			contentLbl.Text = contentText
			contentLbl.TextColor3 = THEME.TextSecondary
			contentLbl.TextSize = 12
			contentLbl.LineHeight = 1.25
			contentLbl.TextWrapped = true
			contentLbl.TextXAlignment = Enum.TextXAlignment.Left
			contentLbl.TextYAlignment = Enum.TextYAlignment.Top
			contentLbl.Parent = card

			local ParagraphController = {}
			function ParagraphController:Set(newCfg: any)
				if type(newCfg) == "table" then
					if newCfg.Title then
						titleLbl.Text = tostring(newCfg.Title)
					end
					if newCfg.Content then
						contentLbl.Text = tostring(newCfg.Content)
					end
				elseif type(newCfg) == "string" then
					contentLbl.Text = newCfg
				end
			end

			registerSearchable(card, titleText, contentText)
			return ParagraphController
		end

		-- // 12c. Tab:CreateDivider()
		function TabObj:CreateDivider()
			local holder = Instance.new("Frame")
			holder.Name = "Divider"
			holder.LayoutOrder = nextLayoutOrder()
			holder.Size = UDim2.new(1, 0, 0, 10)
			holder.BackgroundTransparency = 1
			holder.Parent = ElementScroll

			local line = Instance.new("Frame")
			line.AnchorPoint = Vector2.new(0, 0.5)
			line.Position = UDim2.new(0, 0, 0.5, 0)
			line.Size = UDim2.new(1, 0, 0, 1)
			line.BackgroundColor3 = THEME.HomeDivider
			line.BorderSizePixel = 0
			line.Parent = holder

			return holder
		end

		return TabObj
	end

	return WindowObj
end

return Library
