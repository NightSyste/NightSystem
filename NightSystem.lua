--!nocheck
--[[
	================================================================================
	NIGHT SYSTEM (NightUI) - Standalone Roblox Luau UI Library
	Design: 1:1 Night System Dark Matte (#121212 / #16181A / #FFFFFF Accent)
	Architecture: Single-Container Auto-Sorting Layout (Tabless)
	Compatibility: CoreGui / gethui() / PlayerGui (Studio & Executors)
	================================================================================
]]

local NightSystem = {}
NightSystem.__index = NightSystem
NightSystem.Version = "2.0.0"
NightSystem.Flags = {}
NightSystem._Connections = {}

-- // Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local StatsService = game:GetService("Stats")
local TextService = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- // Theme Palette (1:1 Night System Specification)
local THEME = {
	MainBackground = Color3.fromHex("#121212"),
	SidebarBackground = Color3.fromHex("#121212"),
	ContentBase = Color3.fromHex("#16181A"),
	ContentGradTopRight = Color3.fromHex("#1E2528"),
	ContentGradBottomLeft = Color3.fromHex("#141517"),

	CardBackground = Color3.fromHex("#1A1D20"),
	CardHover = Color3.fromHex("#202428"),
	CardInner = Color3.fromHex("#141618"),
	DiscordBoxBg = Color3.fromHex("#161616"),
	ControlBtnBg = Color3.fromHex("#1A1A1A"),
	ControlBtnHover = Color3.fromHex("#252525"),

	Stroke = Color3.fromHex("#262626"),
	StrokeActive = Color3.fromHex("#2A2A2A"),
	DividerFooter = Color3.fromHex("#222222"),
	DragPill = Color3.fromHex("#3A3A3A"),

	Accent = Color3.fromHex("#FFFFFF"),
	AccentMuted = Color3.fromHex("#CFCFCF"),
	AccentRed = Color3.fromHex("#E03E3E"),

	TextPrimary = Color3.fromHex("#FFFFFF"),
	TextSecondary = Color3.fromHex("#7A7A7A"),
	TextMuted = Color3.fromHex("#8A8A8A"),
	TextInfo = Color3.fromHex("#8E9297"),
	TextStatValue = Color3.fromHex("#B0B0B0"),
	TextHeaderTitle = Color3.fromHex("#4A525A"),
	TextHeaderSub = Color3.fromHex("#3A424A"),
}

-- // Tween Presets
local TWEEN_FAST = TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MEDIUM = TweenInfo.new(0.24, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SMOOTH = TweenInfo.new(0.32, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

-- // Auto-Sort Type Priorities
local TYPE_PRIORITY = {
	Section = 0,
	Label = 100,
	Paragraph = 150,
	Toggle = 200,
	Slider = 300,
	Dropdown = 400,
	ColorPicker = 450,
	Input = 500,
	Keybind = 550,
	Button = 600,
	Divider = 700,
}

-- // Asset IDs
local ASSETS = {
	DefaultLogo = "rbxassetid://10734950309",
	ExternalLink = "rbxassetid://10723374641",
	ChevronDown = "rbxassetid://10709790948",
	ChevronRight = "rbxassetid://10709791437",
	Search = "rbxassetid://10734943674",
	Check = "rbxassetid://10709790644",
	Circle = "rbxassetid://10709798174",
	WhiteSquare = "rbxassetid://10709790644",
}

-- // Internal Helpers
local function trackConnection(conn: RBXScriptConnection): RBXScriptConnection
	table.insert(NightSystem._Connections, conn)
	return conn
end

local function disconnectAll()
	for _, conn in ipairs(NightSystem._Connections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(NightSystem._Connections)
end

local function getGuiParent(): Instance
	local ok, result = pcall(function()
		if type(gethui) == "function" then
			return gethui()
		end
		local coreGui = game:GetService("CoreGui")
		local _ = coreGui.Name
		return coreGui
	end)
	if ok and result then
		return result
	end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local function createCorner(parent: Instance, radius: number): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function createStroke(parent: Instance, color: Color3?, thickness: number?, transparency: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or THEME.Stroke
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

local function tween(instance: Instance, info: TweenInfo, props: { [string]: any }): Tween
	local tw = TweenService:Create(instance, info, props)
	tw:Play()
	return tw
end

local function formatKeyName(key: EnumItem?): string
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

local function colorToHex(color: Color3): string
	local r = math.clamp(math.round(color.R * 255), 0, 255)
	local g = math.clamp(math.round(color.G * 255), 0, 255)
	local b = math.clamp(math.clamp(math.round(color.B * 255), 0, 255), 0, 255)
	return string.format("#%02X%02X%02X", r, g, b)
end

local function hexToColor(hex: string): Color3?
	local cleaned = string.gsub(hex, "#", "")
	cleaned = string.gsub(cleaned, "%s+", "")
	if #cleaned == 6 then
		local r = tonumber(string.sub(cleaned, 1, 2), 16)
		local g = tonumber(string.sub(cleaned, 3, 4), 16)
		local b = tonumber(string.sub(cleaned, 5, 6), 16)
		if r and g and b then
			return Color3.fromRGB(r, g, b)
		end
	end
	return nil
end

local function safeCallback(fn: ((...any) -> ())?, ...: any)
	if type(fn) == "function" then
		local ok, err = pcall(fn, ...)
		if not ok then
			warn("[NightSystem Callback Error]:", err)
		end
	end
end

-- ============================================================================
-- NOTIFICATION CONTAINER (Global for NightSystem:Notify)
-- ============================================================================
local NotificationGui: ScreenGui? = nil
local NotificationHolder: Frame? = nil

local function ensureNotificationHolder()
	if NotificationGui and NotificationGui.Parent and NotificationHolder then
		return NotificationHolder
	end

	local parent = getGuiParent()
	local oldNotif = parent:FindFirstChild("NightSystem_Notifications")
	if oldNotif then
		oldNotif:Destroy()
	end

	NotificationGui = Instance.new("ScreenGui")
	NotificationGui.Name = "NightSystem_Notifications"
	NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	NotificationGui.ResetOnSpawn = false
	NotificationGui.DisplayOrder = 999
	NotificationGui.Parent = parent

	NotificationHolder = Instance.new("Frame")
	NotificationHolder.Name = "NotificationHolder"
	NotificationHolder.Size = UDim2.new(0, 300, 1, -32)
	NotificationHolder.Position = UDim2.new(1, -16, 1, -16)
	NotificationHolder.AnchorPoint = Vector2.new(1, 1)
	NotificationHolder.BackgroundTransparency = 1
	NotificationHolder.Parent = NotificationGui

	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.HorizontalAlignment = Enum.HorizontalAlignment.Right
	list.VerticalAlignment = Enum.VerticalAlignment.Bottom
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, 8)
	list.Parent = NotificationHolder

	return NotificationHolder
end

function NightSystem:Notify(options: { Title: string?, Content: string?, Duration: number? } | string)
	local opts = if type(options) == "string" then { Title = "Night System", Content = options, Duration = 4 } else (options or {})
	local titleText = tostring(opts.Title or "Night System")
	local contentText = tostring(opts.Content or "")
	local duration = tonumber(opts.Duration) or 4

	local holder = ensureNotificationHolder()

	local textBounds = TextService:GetTextSize(
		contentText,
		12,
		Enum.Font.GothamMedium,
		Vector2.new(244, 500)
	)
	local cardHeight = math.max(62, textBounds.Y + 42)

	local wrapper = Instance.new("Frame")
	wrapper.Name = "ToastWrapper"
	wrapper.Size = UDim2.new(0, 290, 0, cardHeight)
	wrapper.BackgroundTransparency = 1
	wrapper.Parent = holder

	local card = Instance.new("Frame")
	card.Name = "ToastCard"
	card.Size = UDim2.new(1, 0, 1, 0)
	card.Position = UDim2.new(1, 320, 0, 0)
	card.BackgroundColor3 = THEME.MainBackground
	card.BorderSizePixel = 0
	card.ClipsDescendants = true
	card.Parent = wrapper
	createCorner(card, 8)
	createStroke(card, THEME.Stroke, 1, 0.15)

	local accentBar = Instance.new("Frame")
	accentBar.Name = "AccentBar"
	accentBar.Size = UDim2.new(0, 3, 1, -16)
	accentBar.Position = UDim2.new(0, 8, 0, 8)
	accentBar.BackgroundColor3 = THEME.Accent
	accentBar.BorderSizePixel = 0
	accentBar.Parent = card
	createCorner(accentBar, 2)

	local titleLbl = Instance.new("TextLabel")
	titleLbl.Name = "Title"
	titleLbl.Size = UDim2.new(1, -48, 0, 16)
	titleLbl.Position = UDim2.new(0, 20, 0, 10)
	titleLbl.BackgroundTransparency = 1
	titleLbl.Font = Enum.Font.GothamBold
	titleLbl.Text = titleText
	titleLbl.TextColor3 = THEME.TextPrimary
	titleLbl.TextSize = 13
	titleLbl.TextXAlignment = Enum.TextXAlignment.Left
	titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
	titleLbl.Parent = card

	local closeBtn = Instance.new("TextButton")
	closeBtn.Name = "Close"
	closeBtn.Size = UDim2.new(0, 20, 0, 20)
	closeBtn.Position = UDim2.new(1, -8, 0, 8)
	closeBtn.AnchorPoint = Vector2.new(1, 0)
	closeBtn.BackgroundTransparency = 1
	closeBtn.Font = Enum.Font.GothamBold
	closeBtn.Text = "×"
	closeBtn.TextColor3 = THEME.TextSecondary
	closeBtn.TextSize = 16
	closeBtn.Parent = card

	local bodyLbl = Instance.new("TextLabel")
	bodyLbl.Name = "Content"
	bodyLbl.Size = UDim2.new(1, -32, 1, -36)
	bodyLbl.Position = UDim2.new(0, 20, 0, 28)
	bodyLbl.BackgroundTransparency = 1
	bodyLbl.Font = Enum.Font.GothamMedium
	bodyLbl.Text = contentText
	bodyLbl.TextColor3 = THEME.TextInfo
	bodyLbl.TextSize = 12
	bodyLbl.TextWrapped = true
	bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
	bodyLbl.TextYAlignment = Enum.TextYAlignment.Top
	bodyLbl.Parent = card

	local progressBg = Instance.new("Frame")
	progressBg.Name = "ProgressBg"
	progressBg.Size = UDim2.new(1, 0, 0, 2)
	progressBg.Position = UDim2.new(0, 0, 1, -2)
	progressBg.BackgroundColor3 = THEME.Stroke
	progressBg.BorderSizePixel = 0
	progressBg.Parent = card

	local progressFill = Instance.new("Frame")
	progressFill.Name = "ProgressFill"
	progressFill.Size = UDim2.new(1, 0, 1, 0)
	progressFill.BackgroundColor3 = THEME.Accent
	progressFill.BorderSizePixel = 0
	progressFill.Parent = progressBg

	local closed = false
	local function dismiss()
		if closed then
			return
		end
		closed = true
		local outTween = tween(card, TWEEN_MEDIUM, { Position = UDim2.new(1, 320, 0, 0) })
		tween(wrapper, TWEEN_MEDIUM, { Size = UDim2.new(0, 290, 0, 0) })
		outTween.Completed:Connect(function()
			if wrapper.Parent then
				wrapper:Destroy()
			end
		end)
	end

	closeBtn.MouseButton1Click:Connect(dismiss)

	tween(card, TWEEN_SMOOTH, { Position = UDim2.new(0, 0, 0, 0) })
	tween(progressFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		Size = UDim2.new(0, 0, 1, 0),
	})

	task.delay(duration, dismiss)
end

-- ============================================================================
-- WINDOW CREATION (NightSystem:CreateWindow)
-- ============================================================================
function NightSystem:CreateWindow(config: {
	Title: string?,
	Subtitle: string?,
	LogoId: string?,
	IntroText: string?,
	AutoSort: boolean?,
	ToggleKey: Enum.KeyCode?,
}?)
	local cfg = config or {}
	local windowTitle = tostring(cfg.Title or "Night System")
	local windowSubtitle = tostring(cfg.Subtitle or "discord.gg/4cZBCyDFmX")
	local logoId = tostring(cfg.LogoId or ASSETS.DefaultLogo)
	local introText = tostring(
		cfg.IntroText
			or "Welcome to Night System! Join discord.gg/4cZBCyDFmX for news, updates and support."
	)
	local autoSort = if cfg.AutoSort ~= nil then cfg.AutoSort else true
	local toggleKey = cfg.ToggleKey or Enum.KeyCode.RightShift

	-- Clean up previous UI instances to prevent duplicates
	disconnectAll()
	local parent = getGuiParent()
	for _, childName in ipairs({ "NightSystem_UI", "NightSystemUI" }) do
		local existing = parent:FindFirstChild(childName)
		if existing then
			existing:Destroy()
		end
	end

	-- Main ScreenGui
	local ScreenGui = Instance.new("ScreenGui")
	ScreenGui.Name = "NightSystem_UI"
	ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ScreenGui.ResetOnSpawn = false
	ScreenGui.IgnoreGuiInset = false
	ScreenGui.Parent = parent

	-- Floating Minimized Badge ("≡" button restores/minimizes to this badge)
	local FloatingBadge = Instance.new("TextButton")
	FloatingBadge.Name = "FloatingBadge"
	FloatingBadge.Size = UDim2.new(0, 154, 0, 38)
	FloatingBadge.Position = UDim2.new(0.5, 0, 0, 28)
	FloatingBadge.AnchorPoint = Vector2.new(0.5, 0)
	FloatingBadge.BackgroundColor3 = THEME.MainBackground
	FloatingBadge.BorderSizePixel = 0
	FloatingBadge.AutoButtonColor = false
	FloatingBadge.Text = ""
	FloatingBadge.Visible = false
	FloatingBadge.Parent = ScreenGui
	createCorner(FloatingBadge, 10)
	createStroke(FloatingBadge, THEME.Stroke, 1, 0.15)

	local BadgeLogo = Instance.new("Frame")
	BadgeLogo.Size = UDim2.new(0, 24, 0, 24)
	BadgeLogo.Position = UDim2.new(0, 8, 0.5, 0)
	BadgeLogo.AnchorPoint = Vector2.new(0, 0.5)
	BadgeLogo.BackgroundColor3 = Color3.fromHex("#1E1E22")
	BadgeLogo.BorderSizePixel = 0
	BadgeLogo.Parent = FloatingBadge
	createCorner(BadgeLogo, 6)

	local BadgeLetter = Instance.new("TextLabel")
	BadgeLetter.Size = UDim2.new(1, 0, 1, 0)
	BadgeLetter.BackgroundTransparency = 1
	BadgeLetter.Font = Enum.Font.GothamBold
	BadgeLetter.Text = "N"
	BadgeLetter.TextColor3 = THEME.TextPrimary
	BadgeLetter.TextSize = 13
	BadgeLetter.Parent = BadgeLogo

	local BadgeRedDot = Instance.new("Frame")
	BadgeRedDot.Size = UDim2.new(0, 5, 0, 5)
	BadgeRedDot.Position = UDim2.new(1, -3, 0, 3)
	BadgeRedDot.AnchorPoint = Vector2.new(0.5, 0.5)
	BadgeRedDot.BackgroundColor3 = THEME.AccentRed
	BadgeRedDot.BorderSizePixel = 0
	BadgeRedDot.Parent = BadgeLogo
	createCorner(BadgeRedDot, 4)

	local BadgeLabel = Instance.new("TextLabel")
	BadgeLabel.Size = UDim2.new(1, -44, 1, 0)
	BadgeLabel.Position = UDim2.new(0, 38, 0, 0)
	BadgeLabel.BackgroundTransparency = 1
	BadgeLabel.Font = Enum.Font.GothamBold
	BadgeLabel.Text = windowTitle
	BadgeLabel.TextColor3 = THEME.TextPrimary
	BadgeLabel.TextSize = 13
	BadgeLabel.TextXAlignment = Enum.TextXAlignment.Left
	BadgeLabel.TextTruncate = Enum.TextTruncate.AtEnd
	BadgeLabel.Parent = FloatingBadge

	-- Main Window Frame (740x460px, UICorner 12px, #121212)
	local normalSize = UDim2.new(0, 740, 0, 460)
	local maximizedSize = UDim2.new(0, 920, 0, 560)

	local MainFrame = Instance.new("Frame")
	MainFrame.Name = "MainFrame"
	MainFrame.Size = normalSize
	MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundColor3 = THEME.MainBackground
	MainFrame.BorderSizePixel = 0
	MainFrame.ClipsDescendants = true
	MainFrame.Parent = ScreenGui
	createCorner(MainFrame, 12)
	createStroke(MainFrame, THEME.Stroke, 1, 0.2)

	-- ========================================================================
	-- TOPBAR & WINDOW CONTROLS
	-- ========================================================================
	local TopBar = Instance.new("Frame")
	TopBar.Name = "TopBar"
	TopBar.Size = UDim2.new(1, 0, 0, 42)
	TopBar.BackgroundTransparency = 1
	TopBar.Parent = MainFrame

	-- Center Drag Indicator Pill (36x4px, #3A3A3A)
	local DragPill = Instance.new("Frame")
	DragPill.Name = "DragIndicator"
	DragPill.Size = UDim2.new(0, 36, 0, 4)
	DragPill.Position = UDim2.new(0.5, 0, 0, 12)
	DragPill.AnchorPoint = Vector2.new(0.5, 0)
	DragPill.BackgroundColor3 = THEME.DragPill
	DragPill.BorderSizePixel = 0
	DragPill.Parent = TopBar
	createCorner(DragPill, 4)

	-- Top-Left Control Buttons (3x 24x24px, #1A1A1A, UICorner 6px, UIStroke #262626)
	local ControlsHolder = Instance.new("Frame")
	ControlsHolder.Name = "WindowControls"
	ControlsHolder.Size = UDim2.new(0, 84, 0, 24)
	ControlsHolder.Position = UDim2.new(0, 12, 0, 10)
	ControlsHolder.BackgroundTransparency = 1
	ControlsHolder.Parent = TopBar

	local ControlsList = Instance.new("UIListLayout")
	ControlsList.FillDirection = Enum.FillDirection.Horizontal
	ControlsList.HorizontalAlignment = Enum.HorizontalAlignment.Left
	ControlsList.VerticalAlignment = Enum.VerticalAlignment.Center
	ControlsList.Padding = UDim.new(0, 6)
	ControlsList.Parent = ControlsHolder

	local function createControlBtn(name: string, text: string, size: number): TextButton
		local btn = Instance.new("TextButton")
		btn.Name = name
		btn.Size = UDim2.new(0, 24, 0, 24)
		btn.BackgroundColor3 = THEME.ControlBtnBg
		btn.BorderSizePixel = 0
		btn.AutoButtonColor = false
		btn.Font = Enum.Font.GothamBold
		btn.Text = text
		btn.TextColor3 = THEME.TextSecondary
		btn.TextSize = size
		btn.Parent = ControlsHolder
		createCorner(btn, 6)
		createStroke(btn, THEME.Stroke, 1, 0.2)

		btn.MouseEnter:Connect(function()
			tween(btn, TWEEN_FAST, {
				BackgroundColor3 = THEME.ControlBtnHover,
				TextColor3 = THEME.TextPrimary,
			})
		end)

		btn.MouseLeave:Connect(function()
			tween(btn, TWEEN_FAST, {
				BackgroundColor3 = THEME.ControlBtnBg,
				TextColor3 = THEME.TextSecondary,
			})
		end)

		return btn
	end

	local CloseBtn = createControlBtn("CloseButton", "X", 11)
	local MaximizeBtn = createControlBtn("MaximizeButton", "□", 13)
	local MinimizeBtn = createControlBtn("MinimizeButton", "≡", 14)

	-- Smooth Dragging Logic (MainFrame & FloatingBadge)
	local function makeDraggable(handle: GuiObject, target: GuiObject, onPill: Frame?)
		local isDragging = false
		local dragInput: InputObject? = nil
		local dragStart = Vector2.zero
		local startPos = target.Position

		handle.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				isDragging = true
				dragStart = input.Position
				startPos = target.Position
				if onPill then
					tween(onPill, TWEEN_FAST, { BackgroundColor3 = THEME.TextPrimary })
				end

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						isDragging = false
						if onPill then
							tween(onPill, TWEEN_FAST, { BackgroundColor3 = THEME.DragPill })
						end
					end
				end)
			end
		end)

		handle.InputChanged:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				dragInput = input
			end
		end)

		trackConnection(UserInputService.InputChanged:Connect(function(input: InputObject)
			if input == dragInput and isDragging then
				local delta = input.Position - dragStart
				tween(target, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					Position = UDim2.new(
						startPos.X.Scale,
						startPos.X.Offset + delta.X,
						startPos.Y.Scale,
						startPos.Y.Offset + delta.Y
					),
				})
			end
		end))
	end

	makeDraggable(TopBar, MainFrame, DragPill)
	makeDraggable(FloatingBadge, FloatingBadge, nil)

	-- Window State Controls (Close, Maximize, Minimize, RightShift Toggle)
	local isMaximized = false
	local isMinimized = false
	local isHidden = false

	local function setWindowMinimized(state: boolean)
		isMinimized = state
		if isMinimized then
			local shrink = tween(MainFrame, TWEEN_MEDIUM, {
				Size = UDim2.new(0, 740, 0, 0),
				BackgroundTransparency = 1,
			})
			shrink.Completed:Connect(function()
				if isMinimized then
					MainFrame.Visible = false
					FloatingBadge.Visible = true
				end
			end)
		else
			FloatingBadge.Visible = false
			MainFrame.Visible = true
			tween(MainFrame, TWEEN_SMOOTH, {
				Size = if isMaximized then maximizedSize else normalSize,
				BackgroundTransparency = 0,
			})
		end
	end

	local function toggleVisibility()
		if isMinimized then
			setWindowMinimized(false)
			return
		end
		isHidden = not isHidden
		if isHidden then
			local hideTw = tween(MainFrame, TWEEN_MEDIUM, {
				Size = UDim2.new(0, 700, 0, 0),
				BackgroundTransparency = 1,
			})
			hideTw.Completed:Connect(function()
				if isHidden then
					MainFrame.Visible = false
				end
			end)
		else
			MainFrame.Visible = true
			tween(MainFrame, TWEEN_SMOOTH, {
				Size = if isMaximized then maximizedSize else normalSize,
				BackgroundTransparency = 0,
			})
		end
	end

	CloseBtn.MouseButton1Click:Connect(function()
		disconnectAll()
		local fadeOut = tween(MainFrame, TWEEN_MEDIUM, {
			Size = UDim2.new(0, 680, 0, 0),
			BackgroundTransparency = 1,
		})
		fadeOut.Completed:Connect(function()
			if ScreenGui.Parent then
				ScreenGui:Destroy()
			end
		end)
	end)

	MaximizeBtn.MouseButton1Click:Connect(function()
		isMaximized = not isMaximized
		tween(MainFrame, TWEEN_SMOOTH, {
			Size = if isMaximized then maximizedSize else normalSize,
		})
	end)

	MinimizeBtn.MouseButton1Click:Connect(function()
		setWindowMinimized(true)
	end)

	FloatingBadge.MouseButton1Click:Connect(function()
		setWindowMinimized(false)
	end)

	trackConnection(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if not gameProcessed and input.KeyCode == toggleKey then
			toggleVisibility()
		end
	end))

	-- ========================================================================
	-- LEFT INFO & PROFILE COLUMN (Width: 210px, Tabless Dashboard)
	-- ========================================================================
	local LeftColumn = Instance.new("Frame")
	LeftColumn.Name = "LeftColumn"
	LeftColumn.Size = UDim2.new(0, 210, 1, -42)
	LeftColumn.Position = UDim2.new(0, 0, 0, 42)
	LeftColumn.BackgroundColor3 = THEME.SidebarBackground
	LeftColumn.BorderSizePixel = 0
	LeftColumn.Parent = MainFrame

	-- 1. Discord Brand Box (Top: 190x54px, #161616, UIStroke #262626)
	local DiscordBox = Instance.new("Frame")
	DiscordBox.Name = "DiscordBrandCard"
	DiscordBox.Size = UDim2.new(0, 190, 0, 54)
	DiscordBox.Position = UDim2.new(0, 12, 0, 2)
	DiscordBox.BackgroundColor3 = THEME.DiscordBoxBg
	DiscordBox.BorderSizePixel = 0
	DiscordBox.Parent = LeftColumn
	createCorner(DiscordBox, 8)
	createStroke(DiscordBox, THEME.Stroke, 1, 0.2)

	local LogoIcon = Instance.new("ImageLabel")
	LogoIcon.Name = "Logo"
	LogoIcon.Size = UDim2.new(0, 36, 0, 36)
	LogoIcon.Position = UDim2.new(0, 9, 0.5, 0)
	LogoIcon.AnchorPoint = Vector2.new(0, 0.5)
	LogoIcon.BackgroundColor3 = Color3.fromHex("#1E1E22")
	LogoIcon.BorderSizePixel = 0
	LogoIcon.Image = logoId
	LogoIcon.ImageTransparency = if logoId == ASSETS.DefaultLogo then 0.85 else 0
	LogoIcon.Parent = DiscordBox
	createCorner(LogoIcon, 8)
	createStroke(LogoIcon, Color3.fromHex("#2E2E34"), 1, 0.15)

	local LogoGrad = Instance.new("UIGradient")
	LogoGrad.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromHex("#2C2D32")),
		ColorSequenceKeypoint.new(1, Color3.fromHex("#141416")),
	})
	LogoGrad.Rotation = 45
	LogoGrad.Parent = LogoIcon

	local LogoText = Instance.new("TextLabel")
	LogoText.Name = "NBadge"
	LogoText.Size = UDim2.new(1, 0, 1, 0)
	LogoText.BackgroundTransparency = 1
	LogoText.Font = Enum.Font.GothamBold
	LogoText.Text = if logoId == ASSETS.DefaultLogo then "N" else ""
	LogoText.TextColor3 = THEME.TextPrimary
	LogoText.TextSize = 20
	LogoText.Parent = LogoIcon

	local RedDot = Instance.new("Frame")
	RedDot.Name = "RedAccent"
	RedDot.Size = UDim2.new(0, 6, 0, 6)
	RedDot.Position = UDim2.new(1, -5, 0, 5)
	RedDot.AnchorPoint = Vector2.new(0.5, 0.5)
	RedDot.BackgroundColor3 = THEME.AccentRed
	RedDot.BorderSizePixel = 0
	RedDot.Parent = LogoIcon
	createCorner(RedDot, 6)

	local BrandTitle = Instance.new("TextLabel")
	BrandTitle.Name = "Title"
	BrandTitle.Size = UDim2.new(1, -80, 0, 16)
	BrandTitle.Position = UDim2.new(0, 53, 0, 11)
	BrandTitle.BackgroundTransparency = 1
	BrandTitle.Font = Enum.Font.GothamBold
	BrandTitle.Text = windowTitle
	BrandTitle.TextColor3 = THEME.TextPrimary
	BrandTitle.TextSize = 14
	BrandTitle.TextXAlignment = Enum.TextXAlignment.Left
	BrandTitle.TextTruncate = Enum.TextTruncate.AtEnd
	BrandTitle.Parent = DiscordBox

	local BrandSub = Instance.new("TextLabel")
	BrandSub.Name = "Subtitle"
	BrandSub.Size = UDim2.new(1, -80, 0, 14)
	BrandSub.Position = UDim2.new(0, 53, 0, 28)
	BrandSub.BackgroundTransparency = 1
	BrandSub.Font = Enum.Font.GothamMedium
	BrandSub.Text = windowSubtitle
	BrandSub.TextColor3 = THEME.TextSecondary
	BrandSub.TextSize = 11
	BrandSub.TextXAlignment = Enum.TextXAlignment.Left
	BrandSub.TextTruncate = Enum.TextTruncate.AtEnd
	BrandSub.Parent = DiscordBox

	local CopyDiscordBtn = Instance.new("TextButton")
	CopyDiscordBtn.Name = "ExternalLinkBtn"
	CopyDiscordBtn.Size = UDim2.new(0, 24, 0, 24)
	CopyDiscordBtn.Position = UDim2.new(1, -8, 0.5, 0)
	CopyDiscordBtn.AnchorPoint = Vector2.new(1, 0.5)
	CopyDiscordBtn.BackgroundTransparency = 1
	CopyDiscordBtn.Text = ""
	CopyDiscordBtn.Parent = DiscordBox

	local ExtIcon = Instance.new("ImageLabel")
	ExtIcon.Size = UDim2.new(0, 14, 0, 14)
	ExtIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	ExtIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	ExtIcon.BackgroundTransparency = 1
	ExtIcon.Image = ASSETS.ExternalLink
	ExtIcon.ImageColor3 = THEME.TextSecondary
	ExtIcon.Parent = CopyDiscordBtn

	CopyDiscordBtn.MouseEnter:Connect(function()
		tween(ExtIcon, TWEEN_FAST, { ImageColor3 = THEME.TextPrimary })
	end)
	CopyDiscordBtn.MouseLeave:Connect(function()
		tween(ExtIcon, TWEEN_FAST, { ImageColor3 = THEME.TextSecondary })
	end)
	CopyDiscordBtn.MouseButton1Click:Connect(function()
		local clip = (getfenv() :: any).setclipboard or (getfenv() :: any).toclipboard
		if type(clip) == "function" then
			pcall(clip, "https://discord.gg/4cZBCyDFmX")
		end
		NightSystem:Notify({
			Title = windowTitle,
			Content = "Discord-Link kopiert! (https://discord.gg/4cZBCyDFmX)",
			Duration = 3,
		})
	end)

	-- 2. Compact Player Dashboard (Middle of Left Column)
	local DashboardCard = Instance.new("Frame")
	DashboardCard.Name = "PlayerDashboard"
	DashboardCard.Size = UDim2.new(0, 190, 1, -128)
	DashboardCard.Position = UDim2.new(0, 12, 0, 66)
	DashboardCard.BackgroundColor3 = THEME.DiscordBoxBg
	DashboardCard.BackgroundTransparency = 0.35
	DashboardCard.BorderSizePixel = 0
	DashboardCard.Parent = LeftColumn
	createCorner(DashboardCard, 8)
	createStroke(DashboardCard, THEME.Stroke, 1, 0.2)
	createPadding(DashboardCard, 12, 12, 12, 12)

	-- Large Player Avatar (72x72px, UICorner 10px, UIStroke #2A2A2A)
	local DashAvatar = Instance.new("ImageLabel")
	DashAvatar.Name = "PlayerAvatar"
	DashAvatar.Size = UDim2.new(0, 72, 0, 72)
	DashAvatar.Position = UDim2.new(0, 0, 0, 0)
	DashAvatar.BackgroundColor3 = THEME.MainBackground
	DashAvatar.BorderSizePixel = 0
	DashAvatar.Parent = DashboardCard
	createCorner(DashAvatar, 10)
	createStroke(DashAvatar, THEME.StrokeActive, 1, 0)

	local DashDisplayName = Instance.new("TextLabel")
	DashDisplayName.Name = "DisplayName"
	DashDisplayName.Size = UDim2.new(1, -82, 0, 22)
	DashDisplayName.Position = UDim2.new(0, 82, 0, 14)
	DashDisplayName.BackgroundTransparency = 1
	DashDisplayName.Font = Enum.Font.GothamBold
	DashDisplayName.Text = LocalPlayer.DisplayName
	DashDisplayName.TextColor3 = THEME.TextPrimary
	DashDisplayName.TextSize = 18
	DashDisplayName.TextXAlignment = Enum.TextXAlignment.Left
	DashDisplayName.TextTruncate = Enum.TextTruncate.AtEnd
	DashDisplayName.Parent = DashboardCard

	local DashUsername = Instance.new("TextLabel")
	DashUsername.Name = "Username"
	DashUsername.Size = UDim2.new(1, -82, 0, 16)
	DashUsername.Position = UDim2.new(0, 82, 0, 38)
	DashUsername.BackgroundTransparency = 1
	DashUsername.Font = Enum.Font.GothamMedium
	DashUsername.Text = "@" .. LocalPlayer.Name
	DashUsername.TextColor3 = THEME.TextMuted
	DashUsername.TextSize = 12
	DashUsername.TextXAlignment = Enum.TextXAlignment.Left
	DashUsername.TextTruncate = Enum.TextTruncate.AtEnd
	DashUsername.Parent = DashboardCard

	-- Configurable Intro / Welcome Text Block (#8E9297, 12px, TextWrapped)
	local IntroLabel = Instance.new("TextLabel")
	IntroLabel.Name = "IntroText"
	IntroLabel.Size = UDim2.new(1, 0, 0, 66)
	IntroLabel.Position = UDim2.new(0, 0, 0, 82)
	IntroLabel.BackgroundTransparency = 1
	IntroLabel.Font = Enum.Font.GothamMedium
	IntroLabel.Text = introText
	IntroLabel.TextColor3 = THEME.TextInfo
	IntroLabel.TextSize = 12
	IntroLabel.TextWrapped = true
	IntroLabel.TextXAlignment = Enum.TextXAlignment.Left
	IntroLabel.TextYAlignment = Enum.TextYAlignment.Top
	IntroLabel.LineHeight = 1.2
	IntroLabel.Parent = DashboardCard

	-- Live Statistics Rows (Place ID & Your Team) at bottom of DashboardCard
	local StatsBlock = Instance.new("Frame")
	StatsBlock.Name = "StatsBlock"
	StatsBlock.Size = UDim2.new(1, 0, 0, 66)
	StatsBlock.Position = UDim2.new(0, 0, 1, 0)
	StatsBlock.AnchorPoint = Vector2.new(0, 1)
	StatsBlock.BackgroundTransparency = 1
	StatsBlock.Parent = DashboardCard

	local StatLine1 = Instance.new("Frame")
	StatLine1.Size = UDim2.new(1, 0, 0, 1)
	StatLine1.Position = UDim2.new(0, 0, 0, 0)
	StatLine1.BackgroundColor3 = THEME.Stroke
	StatLine1.BackgroundTransparency = 0.2
	StatLine1.BorderSizePixel = 0
	StatLine1.Parent = StatsBlock

	local PlaceRow = Instance.new("Frame")
	PlaceRow.Size = UDim2.new(1, 0, 0, 31)
	PlaceRow.Position = UDim2.new(0, 0, 0, 1)
	PlaceRow.BackgroundTransparency = 1
	PlaceRow.Parent = StatsBlock

	local PlaceKey = Instance.new("TextLabel")
	PlaceKey.Size = UDim2.new(0, 52, 1, 0)
	PlaceKey.BackgroundTransparency = 1
	PlaceKey.Font = Enum.Font.GothamMedium
	PlaceKey.Text = "Place ID"
	PlaceKey.TextColor3 = THEME.TextSecondary
	PlaceKey.TextSize = 11
	PlaceKey.TextXAlignment = Enum.TextXAlignment.Left
	PlaceKey.Parent = PlaceRow

	local PlaceVal = Instance.new("TextLabel")
	PlaceVal.Size = UDim2.new(1, -54, 1, 0)
	PlaceVal.Position = UDim2.new(0, 54, 0, 0)
	PlaceVal.BackgroundTransparency = 1
	PlaceVal.Font = Enum.Font.GothamMedium
	PlaceVal.Text = tostring(game.PlaceId > 0 and game.PlaceId or 7711635737)
	PlaceVal.TextColor3 = THEME.TextStatValue
	PlaceVal.TextSize = 11
	PlaceVal.TextXAlignment = Enum.TextXAlignment.Right
	PlaceVal.TextTruncate = Enum.TextTruncate.AtEnd
	PlaceVal.Parent = PlaceRow

	local StatLine2 = Instance.new("Frame")
	StatLine2.Size = UDim2.new(1, 0, 0, 1)
	StatLine2.Position = UDim2.new(0, 0, 0, 33)
	StatLine2.BackgroundColor3 = THEME.Stroke
	StatLine2.BackgroundTransparency = 0.2
	StatLine2.BorderSizePixel = 0
	StatLine2.Parent = StatsBlock

	local TeamRow = Instance.new("Frame")
	TeamRow.Size = UDim2.new(1, 0, 0, 31)
	TeamRow.Position = UDim2.new(0, 0, 0, 34)
	TeamRow.BackgroundTransparency = 1
	TeamRow.Parent = StatsBlock

	local TeamKey = Instance.new("TextLabel")
	TeamKey.Size = UDim2.new(0, 62, 1, 0)
	TeamKey.BackgroundTransparency = 1
	TeamKey.Font = Enum.Font.GothamMedium
	TeamKey.Text = "Your Team"
	TeamKey.TextColor3 = THEME.TextSecondary
	TeamKey.TextSize = 11
	TeamKey.TextXAlignment = Enum.TextXAlignment.Left
	TeamKey.Parent = TeamRow

	local TeamVal = Instance.new("TextLabel")
	TeamVal.Size = UDim2.new(1, -64, 1, 0)
	TeamVal.Position = UDim2.new(0, 64, 0, 0)
	TeamVal.BackgroundTransparency = 1
	TeamVal.Font = Enum.Font.GothamMedium
	TeamVal.Text = if LocalPlayer.Team then LocalPlayer.Team.Name else "Citizen"
	TeamVal.TextColor3 = THEME.TextStatValue
	TeamVal.TextSize = 11
	TeamVal.TextXAlignment = Enum.TextXAlignment.Right
	TeamVal.TextTruncate = Enum.TextTruncate.AtEnd
	TeamVal.Parent = TeamRow

	-- 3. Bottom User Footer (Divider #222222, 32x32 Avatar, DisplayName, @Username, Live FPS/Ping)
	local UserFooter = Instance.new("Frame")
	UserFooter.Name = "UserFooter"
	UserFooter.Size = UDim2.new(0, 190, 0, 52)
	UserFooter.Position = UDim2.new(0, 12, 1, -54)
	UserFooter.BackgroundTransparency = 1
	UserFooter.Parent = LeftColumn

	local FooterDivider = Instance.new("Frame")
	FooterDivider.Size = UDim2.new(1, 0, 0, 1)
	FooterDivider.BackgroundColor3 = THEME.DividerFooter
	FooterDivider.BorderSizePixel = 0
	FooterDivider.Parent = UserFooter

	local SmallAvatar = Instance.new("ImageLabel")
	SmallAvatar.Name = "SmallAvatar"
	SmallAvatar.Size = UDim2.new(0, 32, 0, 32)
	SmallAvatar.Position = UDim2.new(0, 0, 0, 12)
	SmallAvatar.BackgroundColor3 = THEME.DiscordBoxBg
	SmallAvatar.BorderSizePixel = 0
	SmallAvatar.Parent = UserFooter
	local roundCorner = Instance.new("UICorner")
	roundCorner.CornerRadius = UDim.new(1, 0)
	roundCorner.Parent = SmallAvatar

	local FooterName = Instance.new("TextLabel")
	FooterName.Size = UDim2.new(1, -92, 0, 15)
	FooterName.Position = UDim2.new(0, 38, 0, 12)
	FooterName.BackgroundTransparency = 1
	FooterName.Font = Enum.Font.GothamBold
	FooterName.Text = LocalPlayer.DisplayName
	FooterName.TextColor3 = THEME.TextPrimary
	FooterName.TextSize = 12
	FooterName.TextXAlignment = Enum.TextXAlignment.Left
	FooterName.TextTruncate = Enum.TextTruncate.AtEnd
	FooterName.Parent = UserFooter

	local FooterHandle = Instance.new("TextLabel")
	FooterHandle.Size = UDim2.new(1, -92, 0, 13)
	FooterHandle.Position = UDim2.new(0, 38, 0, 27)
	FooterHandle.BackgroundTransparency = 1
	FooterHandle.Font = Enum.Font.GothamMedium
	FooterHandle.Text = "@" .. LocalPlayer.Name
	FooterHandle.TextColor3 = THEME.TextSecondary
	FooterHandle.TextSize = 10
	FooterHandle.TextXAlignment = Enum.TextXAlignment.Left
	FooterHandle.TextTruncate = Enum.TextTruncate.AtEnd
	FooterHandle.Parent = UserFooter

	local PerfBadge = Instance.new("TextLabel")
	PerfBadge.Name = "PerfMetrics"
	PerfBadge.Size = UDim2.new(0, 52, 0, 28)
	PerfBadge.Position = UDim2.new(1, 0, 0, 14)
	PerfBadge.AnchorPoint = Vector2.new(1, 0)
	PerfBadge.BackgroundTransparency = 1
	PerfBadge.Font = Enum.Font.GothamMedium
	PerfBadge.Text = "60 FPS\n-- ms"
	PerfBadge.TextColor3 = THEME.TextSecondary
	PerfBadge.TextSize = 10
	PerfBadge.TextXAlignment = Enum.TextXAlignment.Right
	PerfBadge.Parent = UserFooter

	-- Load Dynamic Player Thumbnail, Place Info & Live FPS/Ping
	task.spawn(function()
		local uid = if LocalPlayer.UserId > 0 then LocalPlayer.UserId else 1
		local ok, thumb = pcall(function()
			return Players:GetUserThumbnailAsync(uid, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		end)
		if ok and thumb then
			DashAvatar.Image = thumb
			SmallAvatar.Image = thumb
		end
	end)

	task.spawn(function()
		if game.PlaceId and game.PlaceId > 0 then
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(game.PlaceId)
			end)
			if ok and type(info) == "table" and info.Name then
				PlaceVal.Text = string.format("%d - %s", game.PlaceId, tostring(info.Name))
				return
			end
		end
		PlaceVal.Text = "7711635737 - Notruf Hamburg"
	end)

	local function refreshTeam()
		local t = LocalPlayer.Team
		TeamVal.Text = if t and t.Name ~= "" then t.Name else "Citizen"
	end
	refreshTeam()
	trackConnection(LocalPlayer:GetPropertyChangedSignal("Team"):Connect(refreshTeam))

	-- Live FPS & Ping Updater
	do
		local frameCount = 0
		local lastUpdate = os.clock()
		trackConnection(RunService.RenderStepped:Connect(function()
			frameCount += 1
			local now = os.clock()
			if now - lastUpdate >= 1 then
				local fps = math.clamp(math.round(frameCount / (now - lastUpdate)), 1, 999)
				frameCount = 0
				lastUpdate = now

				local pingStr = "-- ms"
				pcall(function()
					local net = StatsService:FindFirstChild("Network")
					local serverStats = net and net:FindFirstChild("ServerStatsItem")
					local dataPing = serverStats and serverStats:FindFirstChild("Data Ping")
					if dataPing then
						pingStr = string.format("%d ms", math.round(dataPing:GetValue()))
					end
				end)
				PerfBadge.Text = string.format("%d FPS\n%s", fps, pingStr)
			end
		end))
	end

	-- ========================================================================
	-- RIGHT MAIN CONTENT CONTAINER (Single-View Auto-Sorting ScrollingFrame)
	-- ========================================================================
	local ContentContainer = Instance.new("Frame")
	ContentContainer.Name = "ContentContainer"
	ContentContainer.Size = UDim2.new(1, -224, 1, -54)
	ContentContainer.Position = UDim2.new(0, 212, 0, 42)
	-- Pure white base so UIGradient renders exact #141517 -> #16181A -> #1E2528 colors
	ContentContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	ContentContainer.BorderSizePixel = 0
	ContentContainer.ClipsDescendants = true
	ContentContainer.Parent = MainFrame
	createCorner(ContentContainer, 10)
	createStroke(ContentContainer, THEME.Stroke, 1, 0.2)

	local ContentGradient = Instance.new("UIGradient")
	ContentGradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, THEME.ContentGradBottomLeft),
		ColorSequenceKeypoint.new(0.5, THEME.ContentBase),
		ColorSequenceKeypoint.new(1, THEME.ContentGradTopRight),
	})
	ContentGradient.Rotation = -45
	ContentGradient.Parent = ContentContainer

	-- Top Header inside Content Container
	local ContentHeader = Instance.new("Frame")
	ContentHeader.Name = "ContentHeader"
	ContentHeader.Size = UDim2.new(1, -40, 0, 42)
	ContentHeader.Position = UDim2.new(0, 20, 0, 16)
	ContentHeader.BackgroundTransparency = 1
	ContentHeader.Parent = ContentContainer

	local HeaderTitle = Instance.new("TextLabel")
	HeaderTitle.Name = "Title"
	HeaderTitle.Size = UDim2.new(0.6, 0, 0, 20)
	HeaderTitle.Position = UDim2.new(0, 0, 0, 0)
	HeaderTitle.BackgroundTransparency = 1
	HeaderTitle.Font = Enum.Font.GothamBold
	HeaderTitle.Text = windowTitle
	HeaderTitle.TextColor3 = THEME.TextHeaderTitle
	HeaderTitle.TextSize = 18
	HeaderTitle.TextXAlignment = Enum.TextXAlignment.Left
	HeaderTitle.Parent = ContentHeader

	local HeaderSub = Instance.new("TextLabel")
	HeaderSub.Name = "Subtitle"
	HeaderSub.Size = UDim2.new(0.6, 0, 0, 16)
	HeaderSub.Position = UDim2.new(0, 0, 0, 21)
	HeaderSub.BackgroundTransparency = 1
	HeaderSub.Font = Enum.Font.GothamMedium
	HeaderSub.Text = "Welcome back, @" .. LocalPlayer.Name
	HeaderSub.TextColor3 = THEME.TextHeaderSub
	HeaderSub.TextSize = 13
	HeaderSub.TextXAlignment = Enum.TextXAlignment.Left
	HeaderSub.Parent = ContentHeader

	-- Quick Filter Search Box in Top-Right of Content Header
	local FilterBoxHolder = Instance.new("Frame")
	FilterBoxHolder.Name = "FilterBoxHolder"
	FilterBoxHolder.Size = UDim2.new(0, 165, 0, 28)
	FilterBoxHolder.Position = UDim2.new(1, 0, 0.5, 0)
	FilterBoxHolder.AnchorPoint = Vector2.new(1, 0.5)
	FilterBoxHolder.BackgroundColor3 = THEME.MainBackground
	FilterBoxHolder.BorderSizePixel = 0
	FilterBoxHolder.Parent = ContentHeader
	createCorner(FilterBoxHolder, 7)
	local FilterStroke = createStroke(FilterBoxHolder, THEME.Stroke, 1, 0.2)

	local FilterIcon = Instance.new("ImageLabel")
	FilterIcon.Size = UDim2.new(0, 13, 0, 13)
	FilterIcon.Position = UDim2.new(0, 9, 0.5, 0)
	FilterIcon.AnchorPoint = Vector2.new(0, 0.5)
	FilterIcon.BackgroundTransparency = 1
	FilterIcon.Image = ASSETS.Search
	FilterIcon.ImageColor3 = THEME.TextSecondary
	FilterIcon.Parent = FilterBoxHolder

	local FilterInput = Instance.new("TextBox")
	FilterInput.Name = "FilterInput"
	FilterInput.Size = UDim2.new(1, -32, 1, 0)
	FilterInput.Position = UDim2.new(0, 27, 0, 0)
	FilterInput.BackgroundTransparency = 1
	FilterInput.Font = Enum.Font.GothamMedium
	FilterInput.PlaceholderText = "Search elements..."
	FilterInput.PlaceholderColor3 = THEME.TextSecondary
	FilterInput.Text = ""
	FilterInput.TextColor3 = THEME.TextPrimary
	FilterInput.TextSize = 12
	FilterInput.TextXAlignment = Enum.TextXAlignment.Left
	FilterInput.ClearTextOnFocus = false
	FilterInput.Parent = FilterBoxHolder

	FilterInput.Focused:Connect(function()
		tween(FilterStroke, TWEEN_FAST, { Color = THEME.Accent, Transparency = 0.1 })
	end)
	FilterInput.FocusLost:Connect(function()
		tween(FilterStroke, TWEEN_FAST, { Color = THEME.Stroke, Transparency = 0.2 })
	end)

	-- Butter-smooth ScrollingFrame (AutomaticCanvasSize = Y, ScrollBarThickness = 2)
	local ScrollContainer = Instance.new("ScrollingFrame")
	ScrollContainer.Name = "ElementScroll"
	ScrollContainer.Size = UDim2.new(1, -24, 1, -74)
	ScrollContainer.Position = UDim2.new(0, 12, 0, 64)
	ScrollContainer.BackgroundTransparency = 1
	ScrollContainer.BorderSizePixel = 0
	ScrollContainer.ScrollBarThickness = 2
	ScrollContainer.ScrollBarImageColor3 = THEME.Accent
	ScrollContainer.ScrollBarImageTransparency = 0.35
	ScrollContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
	ScrollContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
	ScrollContainer.ScrollingDirection = Enum.ScrollingDirection.Y
	ScrollContainer.Parent = ContentContainer
	createPadding(ScrollContainer, 2, 14, 8, 10)

	local ElementListLayout = Instance.new("UIListLayout")
	ElementListLayout.FillDirection = Enum.FillDirection.Vertical
	ElementListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	ElementListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	ElementListLayout.Padding = UDim.new(0, 8)
	ElementListLayout.Parent = ScrollContainer

	-- Search Filtering Logic
	local searchableItems: { { Frame: GuiObject, Title: string } } = {}
	FilterInput:GetPropertyChangedSignal("Text"):Connect(function()
		local query = string.lower(string.gsub(FilterInput.Text, "^%s*(.-)%s*$", "%1"))
		for _, item in ipairs(searchableItems) do
			if query == "" then
				item.Frame.Visible = true
			else
				item.Frame.Visible = string.find(string.lower(item.Title), query, 1, true) ~= nil
			end
		end
	end)

	-- ========================================================================
	-- AUTO-SORTING ENGINE
	-- ========================================================================
	local Window = {}
	Window.__index = Window
	Window._CreationCount = 0
	Window._SectionBlock = 0
	Window._AutoSort = autoSort
	Window.Flags = NightSystem.Flags

	local function computeLayoutOrder(elementType: string, manualOrder: number?): number
		if type(manualOrder) == "number" then
			return manualOrder
		end
		Window._CreationCount += 1
		if elementType == "Section" then
			Window._SectionBlock += 10000
			return Window._SectionBlock
		end
		if Window._AutoSort then
			local typeWeight = TYPE_PRIORITY[elementType] or 650
			return Window._SectionBlock + typeWeight + Window._CreationCount
		else
			return Window._SectionBlock + Window._CreationCount
		end
	end

	local function registerSearchable(frame: GuiObject, title: string)
		table.insert(searchableItems, { Frame = frame, Title = title })
	end

	local function createBaseCard(
		elementType: string,
		title: string,
		description: string?,
		baseHeight: number,
		manualOrder: number?
	): (Frame, UIStroke, TextLabel)
		local hasDesc = description ~= nil and description ~= ""
		local cardHeight = if hasDesc then math.max(baseHeight, 54) else baseHeight

		local card = Instance.new("Frame")
		card.Name = elementType .. "_" .. title
		card.Size = UDim2.new(1, 0, 0, cardHeight)
		card.BackgroundColor3 = THEME.CardBackground
		card.BorderSizePixel = 0
		card.ClipsDescendants = true
		card.LayoutOrder = computeLayoutOrder(elementType, manualOrder)
		card.Parent = ScrollContainer
		createCorner(card, 8)
		local stroke = createStroke(card, THEME.Stroke, 1, 0.2)

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Name = "Title"
		titleLbl.Size = UDim2.new(1, -160, 0, 16)
		titleLbl.Position = UDim2.new(0, 14, 0, if hasDesc then 10 else math.floor((cardHeight - 16) / 2))
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.Text = title
		titleLbl.TextColor3 = THEME.TextPrimary
		titleLbl.TextSize = 13
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.TextTruncate = Enum.TextTruncate.AtEnd
		titleLbl.Parent = card

		if hasDesc then
			local descLbl = Instance.new("TextLabel")
			descLbl.Name = "Description"
			descLbl.Size = UDim2.new(1, -160, 0, 14)
			descLbl.Position = UDim2.new(0, 14, 0, 28)
			descLbl.BackgroundTransparency = 1
			descLbl.Font = Enum.Font.GothamMedium
			descLbl.Text = tostring(description)
			descLbl.TextColor3 = THEME.TextSecondary
			descLbl.TextSize = 11
			descLbl.TextXAlignment = Enum.TextXAlignment.Left
			descLbl.TextTruncate = Enum.TextTruncate.AtEnd
			descLbl.Parent = card
		end

		card.MouseEnter:Connect(function()
			tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.CardHover })
		end)
		card.MouseLeave:Connect(function()
			tween(card, TWEEN_FAST, { BackgroundColor3 = THEME.CardBackground })
		end)

		registerSearchable(card, title .. " " .. tostring(description or ""))
		return card, stroke, titleLbl
	end

	-- ========================================================================
	-- 1. Window:CreateSection(Title)
	-- ========================================================================
	function Window:CreateSection(sectionConfig: string | { Name: string?, Title: string?, LayoutOrder: number? })
		local title = if type(sectionConfig) == "table"
			then tostring(sectionConfig.Name or sectionConfig.Title or "Section")
			else tostring(sectionConfig or "Section")
		local manualOrder = if type(sectionConfig) == "table" then sectionConfig.LayoutOrder else nil

		local secFrame = Instance.new("Frame")
		secFrame.Name = "Section_" .. title
		secFrame.Size = UDim2.new(1, 0, 0, 26)
		secFrame.BackgroundTransparency = 1
		secFrame.LayoutOrder = computeLayoutOrder("Section", manualOrder)
		secFrame.Parent = ScrollContainer

		local secLabel = Instance.new("TextLabel")
		secLabel.Name = "SectionTitle"
		secLabel.AutomaticSize = Enum.AutomaticSize.X
		secLabel.Size = UDim2.new(0, 0, 1, 0)
		secLabel.Position = UDim2.new(0, 2, 0, 4)
		secLabel.BackgroundTransparency = 1
		secLabel.Font = Enum.Font.GothamBold
		secLabel.Text = string.upper(title)
		secLabel.TextColor3 = THEME.TextSecondary
		secLabel.TextSize = 11
		secLabel.TextXAlignment = Enum.TextXAlignment.Left
		secLabel.Parent = secFrame

		local line = Instance.new("Frame")
		line.Name = "Line"
		line.Size = UDim2.new(1, -110, 0, 1)
		line.Position = UDim2.new(1, 0, 0.5, 2)
		line.AnchorPoint = Vector2.new(1, 0.5)
		line.BackgroundColor3 = THEME.Stroke
		line.BackgroundTransparency = 0.2
		line.BorderSizePixel = 0
		line.Parent = secFrame

		local function updateLineWidth()
			local textW = secLabel.AbsoluteSize.X
			line.Size = UDim2.new(1, -(textW + 14), 0, 1)
		end
		task.defer(updateLineWidth)
		secLabel:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateLineWidth)

		registerSearchable(secFrame, title)

		local SectionObj = {}
		function SectionObj:Set(newTitle: string)
			secLabel.Text = string.upper(tostring(newTitle))
		end
		return SectionObj
	end

	-- ========================================================================
	-- 2. Window:CreateToggle(...)
	-- ========================================================================
	function Window:CreateToggle(options: {
		Name: string?,
		Description: string?,
		Default: boolean?,
		Flag: string?,
		LayoutOrder: number?,
		Callback: ((boolean) -> ())?,
	})
		local opts = options or {}
		local name = tostring(opts.Name or "Toggle")
		local desc = opts.Description
		local state = opts.Default == true
		local flag = opts.Flag or name
		local callback = opts.Callback

		local card = createBaseCard("Toggle", name, desc, 44, opts.LayoutOrder)

		-- Pill Switch on the right (40x20px, #262626 -> #FFFFFF)
		local switchBg = Instance.new("Frame")
		switchBg.Name = "SwitchBg"
		switchBg.Size = UDim2.new(0, 40, 0, 20)
		switchBg.Position = UDim2.new(1, -14, 0.5, 0)
		switchBg.AnchorPoint = Vector2.new(1, 0.5)
		switchBg.BackgroundColor3 = if state then THEME.Accent else THEME.Stroke
		switchBg.BorderSizePixel = 0
		switchBg.Parent = card
		createCorner(switchBg, 10)
		local switchStroke = createStroke(switchBg, if state then THEME.Accent else THEME.StrokeActive, 1, 0.15)

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.Size = UDim2.new(0, 14, 0, 14)
		knob.Position = if state then UDim2.new(1, -17, 0.5, 0) else UDim2.new(0, 3, 0.5, 0)
		knob.AnchorPoint = Vector2.new(0, 0.5)
		knob.BackgroundColor3 = if state then THEME.MainBackground else THEME.TextMuted
		knob.BorderSizePixel = 0
		knob.Parent = switchBg
		createCorner(knob, 7)

		local clickZone = Instance.new("TextButton")
		clickZone.Name = "ClickArea"
		clickZone.Size = UDim2.new(1, 0, 1, 0)
		clickZone.BackgroundTransparency = 1
		clickZone.Text = ""
		clickZone.Parent = card

		local ToggleObj = { Value = state }
		NightSystem.Flags[flag] = state

		function ToggleObj:Set(newValue: boolean, silent: boolean?)
			state = newValue == true
			ToggleObj.Value = state
			NightSystem.Flags[flag] = state

			tween(switchBg, TWEEN_FAST, {
				BackgroundColor3 = if state then THEME.Accent else THEME.Stroke,
			})
			tween(switchStroke, TWEEN_FAST, {
				Color = if state then THEME.Accent else THEME.StrokeActive,
				Transparency = if state then 0 else 0.2,
			})
			tween(knob, TWEEN_FAST, {
				Position = if state then UDim2.new(1, -17, 0.5, 0) else UDim2.new(0, 3, 0.5, 0),
				BackgroundColor3 = if state then THEME.MainBackground else THEME.TextMuted,
			})

			if not silent then
				safeCallback(callback, state)
			end
		end

		function ToggleObj:Get(): boolean
			return state
		end

		clickZone.MouseButton1Click:Connect(function()
			ToggleObj:Set(not state)
		end)

		if state then
			task.defer(function()
				safeCallback(callback, state)
			end)
		end

		return ToggleObj
	end

	-- ========================================================================
	-- 3. Window:CreateButton(...)
	-- ========================================================================
	function Window:CreateButton(options: {
		Name: string?,
		Description: string?,
		LayoutOrder: number?,
		Callback: (() -> ())?,
	})
		local opts = options or {}
		local name = tostring(opts.Name or "Button")
		local desc = opts.Description
		local callback = opts.Callback

		local card, stroke, titleLbl = createBaseCard("Button", name, desc, 44, opts.LayoutOrder)

		local actionBadge = Instance.new("Frame")
		actionBadge.Name = "ActionBadge"
		actionBadge.Size = UDim2.new(0, 26, 0, 26)
		actionBadge.Position = UDim2.new(1, -14, 0.5, 0)
		actionBadge.AnchorPoint = Vector2.new(1, 0.5)
		actionBadge.BackgroundColor3 = THEME.CardInner
		actionBadge.BorderSizePixel = 0
		actionBadge.Parent = card
		createCorner(actionBadge, 6)
		createStroke(actionBadge, THEME.Stroke, 1, 0.2)

		local arrowIcon = Instance.new("ImageLabel")
		arrowIcon.Size = UDim2.new(0, 14, 0, 14)
		arrowIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		arrowIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		arrowIcon.BackgroundTransparency = 1
		arrowIcon.Image = ASSETS.ChevronRight
		arrowIcon.ImageColor3 = THEME.TextSecondary
		arrowIcon.Parent = actionBadge

		local clickBtn = Instance.new("TextButton")
		clickBtn.Size = UDim2.new(1, 0, 1, 0)
		clickBtn.BackgroundTransparency = 1
		clickBtn.Text = ""
		clickBtn.Parent = card

		clickBtn.MouseEnter:Connect(function()
			tween(arrowIcon, TWEEN_FAST, { ImageColor3 = THEME.Accent })
			tween(actionBadge, TWEEN_FAST, { BackgroundColor3 = THEME.Stroke })
		end)
		clickBtn.MouseLeave:Connect(function()
			tween(arrowIcon, TWEEN_FAST, { ImageColor3 = THEME.TextSecondary })
			tween(actionBadge, TWEEN_FAST, { BackgroundColor3 = THEME.CardInner })
		end)

		local function trigger()
			tween(stroke, TWEEN_FAST, { Color = THEME.Accent, Transparency = 0.1 })
			tween(actionBadge, TWEEN_FAST, { BackgroundColor3 = THEME.Accent })
			tween(arrowIcon, TWEEN_FAST, { ImageColor3 = THEME.MainBackground })
			task.delay(0.16, function()
				if stroke.Parent then
					tween(stroke, TWEEN_FAST, { Color = THEME.Stroke, Transparency = 0.2 })
					tween(actionBadge, TWEEN_FAST, { BackgroundColor3 = THEME.CardInner })
					tween(arrowIcon, TWEEN_FAST, { ImageColor3 = THEME.TextSecondary })
				end
			end)
			safeCallback(callback)
		end

		clickBtn.MouseButton1Click:Connect(trigger)

		local ButtonObj = {}
		function ButtonObj:Set(newName: string)
			titleLbl.Text = tostring(newName)
		end
		function ButtonObj:Fire()
			trigger()
		end
		return ButtonObj
	end

	-- ========================================================================
	-- 4. Window:CreateSlider(...)
	-- ========================================================================
	function Window:CreateSlider(options: {
		Name: string?,
		Description: string?,
		Min: number?,
		Max: number?,
		Default: number?,
		Increment: number?,
		Suffix: string?,
		Flag: string?,
		LayoutOrder: number?,
		Callback: ((number) -> ())?,
	})
		local opts = options or {}
		local name = tostring(opts.Name or "Slider")
		local desc = opts.Description
		local minVal = tonumber(opts.Min) or 0
		local maxVal = tonumber(opts.Max) or 100
		local increment = tonumber(opts.Increment) or 1
		local suffix = tostring(opts.Suffix or "")
		local currentVal = math.clamp(tonumber(opts.Default) or minVal, minVal, maxVal)
		local flag = opts.Flag or name
		local callback = opts.Callback

		local hasDesc = desc ~= nil and desc ~= ""
		local cardHeight = if hasDesc then 72 else 60
		local card = createBaseCard("Slider", name, desc, cardHeight, opts.LayoutOrder)

		-- Direct Value TextBox on Top-Right
		local valueInput = Instance.new("TextBox")
		valueInput.Name = "ValueBox"
		valueInput.Size = UDim2.new(0, 68, 0, 22)
		valueInput.Position = UDim2.new(1, -14, 0, 10)
		valueInput.AnchorPoint = Vector2.new(1, 0)
		valueInput.BackgroundColor3 = THEME.CardInner
		valueInput.BorderSizePixel = 0
		valueInput.Font = Enum.Font.GothamBold
		valueInput.Text = tostring(currentVal) .. suffix
		valueInput.TextColor3 = THEME.TextPrimary
		valueInput.TextSize = 11
		valueInput.ClearTextOnFocus = false
		valueInput.Parent = card
		createCorner(valueInput, 5)
		local valStroke = createStroke(valueInput, THEME.Stroke, 1, 0.2)

		-- Slider Track at Bottom
		local trackBtn = Instance.new("TextButton")
		trackBtn.Name = "SliderTrack"
		trackBtn.Size = UDim2.new(1, -28, 0, 6)
		trackBtn.Position = UDim2.new(0, 14, 1, -14)
		trackBtn.AnchorPoint = Vector2.new(0, 1)
		trackBtn.BackgroundColor3 = THEME.CardInner
		trackBtn.BorderSizePixel = 0
		trackBtn.AutoButtonColor = false
		trackBtn.Text = ""
		trackBtn.Parent = card
		createCorner(trackBtn, 3)
		createStroke(trackBtn, THEME.Stroke, 1, 0.3)

		local initialPercent = if maxVal > minVal then (currentVal - minVal) / (maxVal - minVal) else 0

		local fillBar = Instance.new("Frame")
		fillBar.Name = "Fill"
		fillBar.Size = UDim2.new(initialPercent, 0, 1, 0)
		fillBar.BackgroundColor3 = THEME.Accent
		fillBar.BorderSizePixel = 0
		fillBar.Parent = trackBtn
		createCorner(fillBar, 3)

		local knob = Instance.new("Frame")
		knob.Name = "Knob"
		knob.Size = UDim2.new(0, 12, 0, 12)
		knob.Position = UDim2.new(initialPercent, 0, 0.5, 0)
		knob.AnchorPoint = Vector2.new(0.5, 0.5)
		knob.BackgroundColor3 = THEME.Accent
		knob.BorderSizePixel = 0
		knob.Parent = trackBtn
		createCorner(knob, 6)
		createStroke(knob, THEME.MainBackground, 2, 0)

		local SliderObj = { Value = currentVal }
		NightSystem.Flags[flag] = currentVal

		local function roundToIncrement(raw: number): number
			local snapped = minVal + math.round((raw - minVal) / increment) * increment
			-- Avoid floating point precision artifacts
			local decimals = 0
			local incStr = tostring(increment)
			local dotPos = string.find(incStr, ".", 1, true)
			if dotPos then
				decimals = #incStr - dotPos
			end
			local factor = 10 ^ decimals
			return math.clamp(math.round(snapped * factor) / factor, minVal, maxVal)
		end

		function SliderObj:Set(val: number, silent: boolean?)
			local clamped = roundToIncrement(tonumber(val) or minVal)
			currentVal = clamped
			SliderObj.Value = clamped
			NightSystem.Flags[flag] = clamped

			local pct = if maxVal > minVal then (clamped - minVal) / (maxVal - minVal) else 0
			tween(fillBar, TWEEN_FAST, { Size = UDim2.new(pct, 0, 1, 0) })
			tween(knob, TWEEN_FAST, { Position = UDim2.new(pct, 0, 0.5, 0) })
			valueInput.Text = tostring(clamped) .. suffix

			if not silent then
				safeCallback(callback, clamped)
			end
		end

		function SliderObj:Get(): number
			return currentVal
		end

		local sliding = false
		local function updateFromMouse(inputPos: Vector2)
			local trackX = trackBtn.AbsolutePosition.X
			local trackW = math.max(1, trackBtn.AbsoluteSize.X)
			local rel = math.clamp((inputPos.X - trackX) / trackW, 0, 1)
			local rawValue = minVal + (maxVal - minVal) * rel
			SliderObj:Set(rawValue)
		end

		trackBtn.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				sliding = true
				tween(knob, TWEEN_FAST, { Size = UDim2.new(0, 15, 0, 15) })
				updateFromMouse(Vector2.new(input.Position.X, input.Position.Y))

				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						sliding = false
						tween(knob, TWEEN_FAST, { Size = UDim2.new(0, 12, 0, 12) })
					end
				end)
			end
		end)

		trackConnection(UserInputService.InputChanged:Connect(function(input: InputObject)
			if sliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
				updateFromMouse(Vector2.new(input.Position.X, input.Position.Y))
			end
		end))

		valueInput.Focused:Connect(function()
			tween(valStroke, TWEEN_FAST, { Color = THEME.Accent, Transparency = 0 })
			valueInput.Text = tostring(currentVal)
		end)
		valueInput.FocusLost:Connect(function()
			tween(valStroke, TWEEN_FAST, { Color = THEME.Stroke, Transparency = 0.2 })
			local num = tonumber(valueInput.Text)
			if num then
				SliderObj:Set(num)
			else
				valueInput.Text = tostring(currentVal) .. suffix
			end
		end)

		return SliderObj
	end

	-- ========================================================================
	-- 5. Window:CreateDropdown(...)
	-- ========================================================================
	function Window:CreateDropdown(options: {
		Name: string?,
		Description: string?,
		Options: { string }?,
		Default: (string | { string })?,
		Multi: boolean?,
		Searchable: boolean?,
		Flag: string?,
		LayoutOrder: number?,
		Callback: ((any) -> ())?,
	})
		local opts = options or {}
		local name = tostring(opts.Name or "Dropdown")
		local desc = opts.Description
		local optionList: { string } = opts.Options or {}
		local isMulti = opts.Multi == true
		local isSearchable = if opts.Searchable ~= nil then opts.Searchable else true
		local flag = opts.Flag or name
		local callback = opts.Callback

		local hasDesc = desc ~= nil and desc ~= ""
		local closedHeight = if hasDesc then 54 else 44
		local card, cardStroke = createBaseCard("Dropdown", name, desc, closedHeight, opts.LayoutOrder)

		-- Selection State
		local selectedSingle: string = ""
		local selectedMulti: { [string]: boolean } = {}

		if isMulti then
			if type(opts.Default) == "table" then
				for _, item in ipairs(opts.Default) do
					selectedMulti[tostring(item)] = true
				end
			elseif type(opts.Default) == "string" and opts.Default ~= "" then
				selectedMulti[opts.Default] = true
			end
		else
			if type(opts.Default) == "string" then
				selectedSingle = opts.Default
			elseif #optionList > 0 then
				selectedSingle = tostring(optionList[1])
			end
		end

		local function getDisplaySummary(): string
			if isMulti then
				local active = {}
				for _, opt in ipairs(optionList) do
					if selectedMulti[tostring(opt)] then
						table.insert(active, tostring(opt))
					end
				end
				if #active == 0 then
					return "None"
				end
				return table.concat(active, ", ")
			else
				return if selectedSingle ~= "" then selectedSingle else "Select..."
			end
		end

		-- Header Pill Button on the Right
		local headerBtn = Instance.new("TextButton")
		headerBtn.Name = "DropdownHeaderBtn"
		headerBtn.Size = UDim2.new(0, 155, 0, 26)
		headerBtn.Position = UDim2.new(1, -14, 0, if hasDesc then 14 else 9)
		headerBtn.AnchorPoint = Vector2.new(1, 0)
		headerBtn.BackgroundColor3 = THEME.CardInner
		headerBtn.BorderSizePixel = 0
		headerBtn.AutoButtonColor = false
		headerBtn.Text = ""
		headerBtn.Parent = card
		createCorner(headerBtn, 6)
		createStroke(headerBtn, THEME.Stroke, 1, 0.2)

		local selectedLabel = Instance.new("TextLabel")
		selectedLabel.Name = "SelectedText"
		selectedLabel.Size = UDim2.new(1, -30, 1, 0)
		selectedLabel.Position = UDim2.new(0, 10, 0, 0)
		selectedLabel.BackgroundTransparency = 1
		selectedLabel.Font = Enum.Font.GothamMedium
		selectedLabel.Text = getDisplaySummary()
		selectedLabel.TextColor3 = THEME.TextPrimary
		selectedLabel.TextSize = 12
		selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
		selectedLabel.TextTruncate = Enum.TextTruncate.AtEnd
		selectedLabel.Parent = headerBtn

		local arrow = Instance.new("ImageLabel")
		arrow.Name = "Arrow"
		arrow.Size = UDim2.new(0, 14, 0, 14)
		arrow.Position = UDim2.new(1, -8, 0.5, 0)
		arrow.AnchorPoint = Vector2.new(1, 0.5)
		arrow.BackgroundTransparency = 1
		arrow.Image = ASSETS.ChevronDown
		arrow.ImageColor3 = THEME.TextSecondary
		arrow.Parent = headerBtn

		-- Drawer Container inside the Card (expands dynamically via TweenService)
		local drawerFrame = Instance.new("Frame")
		drawerFrame.Name = "Drawer"
		drawerFrame.Size = UDim2.new(1, -28, 0, 160)
		drawerFrame.Position = UDim2.new(0, 14, 0, closedHeight + 4)
		drawerFrame.BackgroundColor3 = THEME.CardInner
		drawerFrame.BorderSizePixel = 0
		drawerFrame.ClipsDescendants = true
		drawerFrame.Parent = card
		createCorner(drawerFrame, 7)
		createStroke(drawerFrame, THEME.Stroke, 1, 0.2)

		local searchOffset = 0
		local searchInput: TextBox? = nil

		if isSearchable then
			searchOffset = 34
			local searchBar = Instance.new("Frame")
			searchBar.Name = "SearchBar"
			searchBar.Size = UDim2.new(1, -12, 0, 26)
			searchBar.Position = UDim2.new(0, 6, 0, 6)
			searchBar.BackgroundColor3 = THEME.MainBackground
			searchBar.BorderSizePixel = 0
			searchBar.Parent = drawerFrame
			createCorner(searchBar, 5)
			createStroke(searchBar, THEME.Stroke, 1, 0.25)

			local sIcon = Instance.new("ImageLabel")
			sIcon.Size = UDim2.new(0, 12, 0, 12)
			sIcon.Position = UDim2.new(0, 8, 0.5, 0)
			sIcon.AnchorPoint = Vector2.new(0, 0.5)
			sIcon.BackgroundTransparency = 1
			sIcon.Image = ASSETS.Search
			sIcon.ImageColor3 = THEME.TextSecondary
			sIcon.Parent = searchBar

			local sBox = Instance.new("TextBox")
			sBox.Size = UDim2.new(1, -28, 1, 0)
			sBox.Position = UDim2.new(0, 24, 0, 0)
			sBox.BackgroundTransparency = 1
			sBox.Font = Enum.Font.GothamMedium
			sBox.PlaceholderText = "Search options..."
			sBox.PlaceholderColor3 = THEME.TextSecondary
			sBox.Text = ""
			sBox.TextColor3 = THEME.TextPrimary
			sBox.TextSize = 11
			sBox.TextXAlignment = Enum.TextXAlignment.Left
			sBox.ClearTextOnFocus = false
			sBox.Parent = searchBar
			searchInput = sBox
		end

		local optionsScroll = Instance.new("ScrollingFrame")
		optionsScroll.Name = "OptionsList"
		optionsScroll.Size = UDim2.new(1, -8, 1, -(searchOffset + 8))
		optionsScroll.Position = UDim2.new(0, 4, 0, searchOffset + 4)
		optionsScroll.BackgroundTransparency = 1
		optionsScroll.BorderSizePixel = 0
		optionsScroll.ScrollBarThickness = 2
		optionsScroll.ScrollBarImageColor3 = THEME.Accent
		optionsScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
		optionsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
		optionsScroll.Parent = drawerFrame
		createPadding(optionsScroll, 2, 2, 2, 4)

		local optLayout = Instance.new("UIListLayout")
		optLayout.FillDirection = Enum.FillDirection.Vertical
		optLayout.SortOrder = Enum.SortOrder.LayoutOrder
		optLayout.Padding = UDim.new(0, 4)
		optLayout.Parent = optionsScroll

		local isOpen = false
		local optionButtons: { { Btn: TextButton, Label: TextLabel, Indicator: Frame, OptionValue: string } } = {}

		local function getDrawerHeight(): number
			local visibleCount = 0
			for _, entry in ipairs(optionButtons) do
				if entry.Btn.Visible then
					visibleCount += 1
				end
			end
			local listHeight = math.clamp(visibleCount * 30, 30, 132)
			return searchOffset + listHeight + 10
		end

		local function updateOpenHeight()
			if isOpen then
				local dHeight = getDrawerHeight()
				drawerFrame.Size = UDim2.new(1, -28, 0, dHeight)
				tween(card, TWEEN_MEDIUM, { Size = UDim2.new(1, 0, 0, closedHeight + dHeight + 14) })
				tween(arrow, TWEEN_FAST, { Rotation = 180, ImageColor3 = THEME.Accent })
				tween(cardStroke, TWEEN_FAST, { Color = THEME.StrokeActive, Transparency = 0 })
			else
				tween(card, TWEEN_MEDIUM, { Size = UDim2.new(1, 0, 0, closedHeight) })
				tween(arrow, TWEEN_FAST, { Rotation = 0, ImageColor3 = THEME.TextSecondary })
				tween(cardStroke, TWEEN_FAST, { Color = THEME.Stroke, Transparency = 0.2 })
			end
		end

		local function updateVisualSelection()
			selectedLabel.Text = getDisplaySummary()
			for _, item in ipairs(optionButtons) do
				local active = if isMulti
					then (selectedMulti[item.OptionValue] == true)
					else (selectedSingle == item.OptionValue)
				tween(item.Btn, TWEEN_FAST, {
					BackgroundColor3 = if active then THEME.CardHover else THEME.MainBackground,
					BackgroundTransparency = if active then 0 else 0.4,
				})
				tween(item.Label, TWEEN_FAST, {
					TextColor3 = if active then THEME.Accent else THEME.TextSecondary,
				})
				tween(item.Indicator, TWEEN_FAST, {
					BackgroundTransparency = if active then 0 else 1,
				})
			end
		end

		local function emitValue(silent: boolean?)
			local outValue: any
			if isMulti then
				local copy = {}
				for k, v in pairs(selectedMulti) do
					if v then
						copy[k] = true
					end
				end
				outValue = copy
			else
				outValue = selectedSingle
			end
			NightSystem.Flags[flag] = outValue
			if not silent then
				safeCallback(callback, outValue)
			end
		end

		local function rebuildOptionButtons()
			for _, child in ipairs(optionsScroll:GetChildren()) do
				if child:IsA("TextButton") then
					child:Destroy()
				end
			end
			table.clear(optionButtons)

			for idx, rawOpt in ipairs(optionList) do
				local optStr = tostring(rawOpt)
				local optBtn = Instance.new("TextButton")
				optBtn.Name = "Option_" .. optStr
				optBtn.Size = UDim2.new(1, 0, 0, 26)
				optBtn.BackgroundColor3 = THEME.MainBackground
				optBtn.BackgroundTransparency = 0.4
				optBtn.BorderSizePixel = 0
				optBtn.AutoButtonColor = false
				optBtn.Text = ""
				optBtn.LayoutOrder = idx
				optBtn.Parent = optionsScroll
				createCorner(optBtn, 5)

				local ind = Instance.new("Frame")
				ind.Size = UDim2.new(0, 3, 0, 12)
				ind.Position = UDim2.new(0, 4, 0.5, 0)
				ind.AnchorPoint = Vector2.new(0, 0.5)
				ind.BackgroundColor3 = THEME.Accent
				ind.BackgroundTransparency = 1
				ind.BorderSizePixel = 0
				ind.Parent = optBtn
				createCorner(ind, 2)

				local lbl = Instance.new("TextLabel")
				lbl.Size = UDim2.new(1, -24, 1, 0)
				lbl.Position = UDim2.new(0, 14, 0, 0)
				lbl.BackgroundTransparency = 1
				lbl.Font = Enum.Font.GothamMedium
				lbl.Text = optStr
				lbl.TextColor3 = THEME.TextSecondary
				lbl.TextSize = 12
				lbl.TextXAlignment = Enum.TextXAlignment.Left
				lbl.TextTruncate = Enum.TextTruncate.AtEnd
				lbl.Parent = optBtn

				optBtn.MouseButton1Click:Connect(function()
					if isMulti then
						selectedMulti[optStr] = not selectedMulti[optStr]
						updateVisualSelection()
						emitValue(false)
					else
						selectedSingle = optStr
						updateVisualSelection()
						emitValue(false)
						isOpen = false
						updateOpenHeight()
					end
				end)

				table.insert(optionButtons, {
					Btn = optBtn,
					Label = lbl,
					Indicator = ind,
					OptionValue = optStr,
				})
			end
			updateVisualSelection()
			if isOpen then
				updateOpenHeight()
			end
		end

		if searchInput then
			searchInput:GetPropertyChangedSignal("Text"):Connect(function()
				local q = string.lower(string.gsub(searchInput.Text, "^%s*(.-)%s*$", "%1"))
				for _, entry in ipairs(optionButtons) do
					entry.Btn.Visible = (q == "") or (string.find(string.lower(entry.OptionValue), q, 1, true) ~= nil)
				end
				if isOpen then
					updateOpenHeight()
				end
			end)
		end

		headerBtn.MouseButton1Click:Connect(function()
			isOpen = not isOpen
			updateOpenHeight()
		end)

		rebuildOptionButtons()
		emitValue(true)

		local DropdownObj = {}
		function DropdownObj:Set(val: any, silent: boolean?)
			if isMulti then
				table.clear(selectedMulti)
				if type(val) == "table" then
					for k, v in pairs(val) do
						if type(k) == "number" then
							selectedMulti[tostring(v)] = true
						elseif v then
							selectedMulti[tostring(k)] = true
						end
					end
				elseif type(val) == "string" then
					selectedMulti[val] = true
				end
			else
				selectedSingle = tostring(val or "")
			end
			updateVisualSelection()
			emitValue(silent)
		end

		function DropdownObj:Refresh(newOptions: { string }, keepSelection: boolean?)
			optionList = newOptions or {}
			if not keepSelection then
				table.clear(selectedMulti)
				selectedSingle = if #optionList > 0 then tostring(optionList[1]) else ""
			end
			rebuildOptionButtons()
			emitValue(true)
		end

		function DropdownObj:Get(): any
			return NightSystem.Flags[flag]
		end

		return DropdownObj
	end

	-- ========================================================================
	-- 6. Window:CreateInput(...)
	-- ========================================================================
	function Window:CreateInput(options: {
		Name: string?,
		Description: string?,
		Placeholder: string?,
		Default: string?,
		ClearTextOnFocus: boolean?,
		Flag: string?,
		LayoutOrder: number?,
		Callback: ((string) -> ())?,
	})
		local opts = options or {}
		local name = tostring(opts.Name or "Input")
		local desc = opts.Description
		local placeholder = tostring(opts.Placeholder or "Enter text...")
		local defaultText = tostring(opts.Default or "")
		local clearOnFocus = opts.ClearTextOnFocus == true
		local flag = opts.Flag or name
		local callback = opts.Callback

		local card = createBaseCard("Input", name, desc, 46, opts.LayoutOrder)

		local inputHolder = Instance.new("Frame")
		inputHolder.Name = "InputHolder"
		inputHolder.Size = UDim2.new(0, 170, 0, 26)
		inputHolder.Position = UDim2.new(1, -14, 0.5, 0)
		inputHolder.AnchorPoint = Vector2.new(1, 0.5)
		inputHolder.BackgroundColor3 = THEME.CardInner
		inputHolder.BorderSizePixel = 0
		inputHolder.Parent = card
		createCorner(inputHolder, 6)
		local boxStroke = createStroke(inputHolder, THEME.Stroke, 1, 0.2)

		local textBox = Instance.new("TextBox")
		textBox.Name = "TextBox"
		textBox.Size = UDim2.new(1, -16, 1, 0)
		textBox.Position = UDim2.new(0, 8, 0, 0)
		textBox.BackgroundTransparency = 1
		textBox.Font = Enum.Font.GothamMedium
		textBox.PlaceholderText = placeholder
		textBox.PlaceholderColor3 = THEME.TextSecondary
		textBox.Text = defaultText
		textBox.TextColor3 = THEME.TextPrimary
		textBox.TextSize = 12
		textBox.TextXAlignment = Enum.TextXAlignment.Left
		textBox.TextTruncate = Enum.TextTruncate.AtEnd
		textBox.ClearTextOnFocus = clearOnFocus
		textBox.Parent = inputHolder

		NightSystem.Flags[flag] = defaultText
		local InputObj = { Value = defaultText }

		function InputObj:Set(newText: string, silent: boolean?)
			local str = tostring(newText or "")
			textBox.Text = str
			InputObj.Value = str
			NightSystem.Flags[flag] = str
			if not silent then
				safeCallback(callback, str)
			end
		end

		function InputObj:Get(): string
			return InputObj.Value
		end

		textBox.Focused:Connect(function()
			tween(boxStroke, TWEEN_FAST, { Color = THEME.Accent, Transparency = 0 })
		end)

		textBox.FocusLost:Connect(function()
			tween(boxStroke, TWEEN_FAST, { Color = THEME.Stroke, Transparency = 0.2 })
			InputObj.Value = textBox.Text
			NightSystem.Flags[flag] = textBox.Text
			safeCallback(callback, textBox.Text)
		end)

		return InputObj
	end

	-- ========================================================================
	-- 7. Window:CreateKeybind(...)
	-- ========================================================================
	function Window:CreateKeybind(options: {
		Name: string?,
		Description: string?,
		Default: EnumItem?,
		Mode: string?,
		Flag: string?,
		LayoutOrder: number?,
		Callback: ((EnumItem?) -> ())?,
	})
		local opts = options or {}
		local name = tostring(opts.Name or "Keybind")
		local desc = opts.Description
		local currentKey: EnumItem? = opts.Default or Enum.KeyCode.E
		local mode = tostring(opts.Mode or "Toggle")
		local flag = opts.Flag or name
		local callback = opts.Callback

		local card = createBaseCard("Keybind", name, desc, 44, opts.LayoutOrder)

		local bindBtn = Instance.new("TextButton")
		bindBtn.Name = "BindButton"
		bindBtn.AutomaticSize = Enum.AutomaticSize.X
		bindBtn.Size = UDim2.new(0, 64, 0, 24)
		bindBtn.Position = UDim2.new(1, -14, 0.5, 0)
		bindBtn.AnchorPoint = Vector2.new(1, 0.5)
		bindBtn.BackgroundColor3 = THEME.CardInner
		bindBtn.BorderSizePixel = 0
		bindBtn.AutoButtonColor = false
		bindBtn.Font = Enum.Font.GothamBold
		bindBtn.Text = "[ " .. formatKeyName(currentKey) .. " ]"
		bindBtn.TextColor3 = THEME.TextPrimary
		bindBtn.TextSize = 11
		bindBtn.Parent = card
		createCorner(bindBtn, 6)
		createPadding(bindBtn, 0, 0, 10, 10)
		local bindStroke = createStroke(bindBtn, THEME.Stroke, 1, 0.2)

		local isBinding = false
		NightSystem.Flags[flag] = currentKey
		local KeybindObj = { Value = currentKey, Mode = mode }

		function KeybindObj:Set(newKey: EnumItem?)
			currentKey = newKey
			KeybindObj.Value = newKey
			NightSystem.Flags[flag] = newKey
			bindBtn.Text = "[ " .. formatKeyName(currentKey) .. " ]"
		end

		function KeybindObj:Get(): EnumItem?
			return currentKey
		end

		bindBtn.MouseButton1Click:Connect(function()
			if isBinding then
				return
			end
			isBinding = true
			bindBtn.Text = "[ ... ]"
			tween(bindStroke, TWEEN_FAST, { Color = THEME.Accent, Transparency = 0 })
		end)

		trackConnection(UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
			if isBinding then
				if input.UserInputType == Enum.UserInputType.Keyboard then
					if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
						KeybindObj:Set(nil)
					else
						KeybindObj:Set(input.KeyCode)
					end
					isBinding = false
					tween(bindStroke, TWEEN_FAST, { Color = THEME.Stroke, Transparency = 0.2 })
				elseif
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.MouseButton2
					or input.UserInputType == Enum.UserInputType.MouseButton3
				then
					KeybindObj:Set(input.UserInputType)
					isBinding = false
					tween(bindStroke, TWEEN_FAST, { Color = THEME.Stroke, Transparency = 0.2 })
				end
				return
			end

			if gameProcessed or UserInputService:GetFocusedTextBox() then
				return
			end

			if currentKey then
				local matched = (input.KeyCode == currentKey) or (input.UserInputType == currentKey)
				if matched then
					safeCallback(callback, currentKey)
				end
			end
		end))

		return KeybindObj
	end

	-- ========================================================================
	-- 8. Window:CreateColorPicker(...)
	-- ========================================================================
	function Window:CreateColorPicker(options: {
		Name: string?,
		Description: string?,
		Default: Color3?,
		Flag: string?,
		LayoutOrder: number?,
		Callback: ((Color3) -> ())?,
	})
		local opts = options or {}
		local name = tostring(opts.Name or "Color Picker")
		local desc = opts.Description
		local currentColor = opts.Default or Color3.fromRGB(255, 255, 255)
		local flag = opts.Flag or name
		local callback = opts.Callback

		local h, s, v = currentColor:ToHSV()
		local hasDesc = desc ~= nil and desc ~= ""
		local closedHeight = if hasDesc then 54 else 44
		local expandedHeight = closedHeight + 158

		local card, cardStroke = createBaseCard("ColorPicker", name, desc, closedHeight, opts.LayoutOrder)

		-- Right Preview Pill (Hex + Color Swatch)
		local previewBtn = Instance.new("TextButton")
		previewBtn.Name = "PreviewButton"
		previewBtn.Size = UDim2.new(0, 108, 0, 26)
		previewBtn.Position = UDim2.new(1, -14, 0, if hasDesc then 14 else 9)
		previewBtn.AnchorPoint = Vector2.new(1, 0)
		previewBtn.BackgroundColor3 = THEME.CardInner
		previewBtn.BorderSizePixel = 0
		previewBtn.AutoButtonColor = false
		previewBtn.Text = ""
		previewBtn.Parent = card
		createCorner(previewBtn, 6)
		createStroke(previewBtn, THEME.Stroke, 1, 0.2)

		local hexPreviewLabel = Instance.new("TextLabel")
		hexPreviewLabel.Size = UDim2.new(1, -36, 1, 0)
		hexPreviewLabel.Position = UDim2.new(0, 8, 0, 0)
		hexPreviewLabel.BackgroundTransparency = 1
		hexPreviewLabel.Font = Enum.Font.GothamBold
		hexPreviewLabel.Text = colorToHex(currentColor)
		hexPreviewLabel.TextColor3 = THEME.TextSecondary
		hexPreviewLabel.TextSize = 11
		hexPreviewLabel.TextXAlignment = Enum.TextXAlignment.Left
		hexPreviewLabel.Parent = previewBtn

		local swatch = Instance.new("Frame")
		swatch.Name = "Swatch"
		swatch.Size = UDim2.new(0, 20, 0, 16)
		swatch.Position = UDim2.new(1, -6, 0.5, 0)
		swatch.AnchorPoint = Vector2.new(1, 0.5)
		swatch.BackgroundColor3 = currentColor
		swatch.BorderSizePixel = 0
		swatch.Parent = previewBtn
		createCorner(swatch, 4)
		createStroke(swatch, THEME.Stroke, 1, 0.1)

		-- Expandable HSV Drawer
		local pickerDrawer = Instance.new("Frame")
		pickerDrawer.Name = "PickerDrawer"
		pickerDrawer.Size = UDim2.new(1, -28, 0, 144)
		pickerDrawer.Position = UDim2.new(0, 14, 0, closedHeight + 4)
		pickerDrawer.BackgroundColor3 = THEME.CardInner
		pickerDrawer.BorderSizePixel = 0
		pickerDrawer.Parent = card
		createCorner(pickerDrawer, 8)
		createStroke(pickerDrawer, THEME.Stroke, 1, 0.2)

		-- Saturation / Value Box (2D Canvas)
		local svCanvas = Instance.new("TextButton")
		svCanvas.Name = "SVCanvas"
		svCanvas.Size = UDim2.new(1, -150, 0, 96)
		svCanvas.Position = UDim2.new(0, 10, 0, 10)
		svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		svCanvas.BorderSizePixel = 0
		svCanvas.AutoButtonColor = false
		svCanvas.Text = ""
		svCanvas.ClipsDescendants = true
		svCanvas.Parent = pickerDrawer
		createCorner(svCanvas, 6)
		createStroke(svCanvas, THEME.Stroke, 1, 0.2)

		local satLayer = Instance.new("Frame")
		satLayer.Size = UDim2.new(1, 0, 1, 0)
		satLayer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		satLayer.BorderSizePixel = 0
		satLayer.Parent = svCanvas
		createCorner(satLayer, 6)

		local satGrad = Instance.new("UIGradient")
		satGrad.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
		satGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0),
			NumberSequenceKeypoint.new(1, 1),
		})
		satGrad.Parent = satLayer

		local valLayer = Instance.new("Frame")
		valLayer.Size = UDim2.new(1, 0, 1, 0)
		valLayer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		valLayer.BorderSizePixel = 0
		valLayer.Parent = svCanvas
		createCorner(valLayer, 6)

		local valGrad = Instance.new("UIGradient")
		valGrad.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
		valGrad.Rotation = 90
		valGrad.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(1, 0),
		})
		valGrad.Parent = valLayer

		local svCursor = Instance.new("Frame")
		svCursor.Name = "Cursor"
		svCursor.Size = UDim2.new(0, 10, 0, 10)
		svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		svCursor.BackgroundColor3 = THEME.Accent
		svCursor.BorderSizePixel = 0
		svCursor.ZIndex = 4
		svCursor.Parent = svCanvas
		createCorner(svCursor, 5)
		createStroke(svCursor, THEME.MainBackground, 2, 0)

		-- Rainbow Hue Bar underneath SV Canvas
		local hueBar = Instance.new("TextButton")
		hueBar.Name = "HueBar"
		hueBar.Size = UDim2.new(1, -150, 0, 14)
		hueBar.Position = UDim2.new(0, 10, 0, 116)
		hueBar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		hueBar.BorderSizePixel = 0
		hueBar.AutoButtonColor = false
		hueBar.Text = ""
		hueBar.Parent = pickerDrawer
		createCorner(hueBar, 4)
		createStroke(hueBar, THEME.Stroke, 1, 0.2)

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

		local hueCursor = Instance.new("Frame")
		hueCursor.Size = UDim2.new(0, 6, 1, 4)
		hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
		hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
		hueCursor.BackgroundColor3 = THEME.Accent
		hueCursor.BorderSizePixel = 0
		hueCursor.Parent = hueBar
		createCorner(hueCursor, 3)
		createStroke(hueCursor, THEME.MainBackground, 1, 0)

		-- Right Side Inputs: HEX, R, G, B
		local inputsPanel = Instance.new("Frame")
		inputsPanel.Name = "InputsPanel"
		inputsPanel.Size = UDim2.new(0, 124, 0, 120)
		inputsPanel.Position = UDim2.new(1, -10, 0, 10)
		inputsPanel.AnchorPoint = Vector2.new(1, 0)
		inputsPanel.BackgroundTransparency = 1
		inputsPanel.Parent = pickerDrawer

		local function createSmallField(labelStr: string, yPos: number): TextBox
			local row = Instance.new("Frame")
			row.Size = UDim2.new(1, 0, 0, 26)
			row.Position = UDim2.new(0, 0, 0, yPos)
			row.BackgroundColor3 = THEME.MainBackground
			row.BorderSizePixel = 0
			row.Parent = inputsPanel
			createCorner(row, 5)
			createStroke(row, THEME.Stroke, 1, 0.2)

			local tag = Instance.new("TextLabel")
			tag.Size = UDim2.new(0, 34, 1, 0)
			tag.Position = UDim2.new(0, 8, 0, 0)
			tag.BackgroundTransparency = 1
			tag.Font = Enum.Font.GothamBold
			tag.Text = labelStr
			tag.TextColor3 = THEME.TextSecondary
			tag.TextSize = 10
			tag.TextXAlignment = Enum.TextXAlignment.Left
			tag.Parent = row

			local box = Instance.new("TextBox")
			box.Size = UDim2.new(1, -44, 1, 0)
			box.Position = UDim2.new(0, 40, 0, 0)
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

		local hexBox = createSmallField("HEX", 0)
		local rBox = createSmallField("R", 31)
		local gBox = createSmallField("G", 62)
		local bBox = createSmallField("B", 93)

		local ColorPickerObj = { Value = currentColor }
		NightSystem.Flags[flag] = currentColor

		local function syncColorVisuals(silent: boolean?)
			currentColor = Color3.fromHSV(h, s, v)
			ColorPickerObj.Value = currentColor
			NightSystem.Flags[flag] = currentColor

			local hexStr = colorToHex(currentColor)
			swatch.BackgroundColor3 = currentColor
			hexPreviewLabel.Text = hexStr
			svCanvas.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
			hueCursor.Position = UDim2.new(h, 0, 0.5, 0)

			hexBox.Text = hexStr
			rBox.Text = tostring(math.round(currentColor.R * 255))
			gBox.Text = tostring(math.round(currentColor.G * 255))
			bBox.Text = tostring(math.round(currentColor.B * 255))

			if not silent then
				safeCallback(callback, currentColor)
			end
		end

		function ColorPickerObj:Set(newColor: Color3, silent: boolean?)
			if typeof(newColor) == "Color3" then
				h, s, v = newColor:ToHSV()
				syncColorVisuals(silent)
			end
		end

		function ColorPickerObj:Get(): Color3
			return currentColor
		end

		local draggingSV = false
		local draggingHue = false

		local function updateSV(pos: Vector2)
			local x = math.clamp((pos.X - svCanvas.AbsolutePosition.X) / math.max(1, svCanvas.AbsoluteSize.X), 0, 1)
			local y = math.clamp((pos.Y - svCanvas.AbsolutePosition.Y) / math.max(1, svCanvas.AbsoluteSize.Y), 0, 1)
			s = x
			v = 1 - y
			syncColorVisuals(false)
		end

		local function updateHue(pos: Vector2)
			local x = math.clamp((pos.X - hueBar.AbsolutePosition.X) / math.max(1, hueBar.AbsoluteSize.X), 0, 1)
			h = x
			syncColorVisuals(false)
		end

		svCanvas.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingSV = true
				updateSV(Vector2.new(input.Position.X, input.Position.Y))
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						draggingSV = false
					end
				end)
			end
		end)

		hueBar.InputBegan:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
				draggingHue = true
				updateHue(Vector2.new(input.Position.X, input.Position.Y))
				input.Changed:Connect(function()
					if input.UserInputState == Enum.UserInputState.End then
						draggingHue = false
					end
				end)
			end
		end)

		trackConnection(UserInputService.InputChanged:Connect(function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
				local p = Vector2.new(input.Position.X, input.Position.Y)
				if draggingSV then
					updateSV(p)
				elseif draggingHue then
					updateHue(p)
				end
			end
		end))

		hexBox.FocusLost:Connect(function()
			local parsed = hexToColor(hexBox.Text)
			if parsed then
				ColorPickerObj:Set(parsed, false)
			else
				syncColorVisuals(true)
			end
		end)

		local function onRgbEdited()
			local r = math.clamp(tonumber(rBox.Text) or math.round(currentColor.R * 255), 0, 255)
			local g = math.clamp(tonumber(gBox.Text) or math.round(currentColor.G * 255), 0, 255)
			local b = math.clamp(tonumber(bBox.Text) or math.round(currentColor.B * 255), 0, 255)
			ColorPickerObj:Set(Color3.fromRGB(r, g, b), false)
		end
		rBox.FocusLost:Connect(onRgbEdited)
		gBox.FocusLost:Connect(onRgbEdited)
		bBox.FocusLost:Connect(onRgbEdited)

		local isExpanded = false
		previewBtn.MouseButton1Click:Connect(function()
			isExpanded = not isExpanded
			if isExpanded then
				tween(card, TWEEN_MEDIUM, { Size = UDim2.new(1, 0, 0, expandedHeight) })
				tween(cardStroke, TWEEN_FAST, { Color = THEME.StrokeActive, Transparency = 0 })
			else
				tween(card, TWEEN_MEDIUM, { Size = UDim2.new(1, 0, 0, closedHeight) })
				tween(cardStroke, TWEEN_FAST, { Color = THEME.Stroke, Transparency = 0.2 })
			end
		end)

		syncColorVisuals(true)
		return ColorPickerObj
	end

	-- ========================================================================
	-- 9. Window:CreateLabel(Text)
	-- ========================================================================
	function Window:CreateLabel(labelConfig: string | { Text: string?, Name: string?, LayoutOrder: number? })
		local text = if type(labelConfig) == "table"
			then tostring(labelConfig.Text or labelConfig.Name or "")
			else tostring(labelConfig or "")
		local manualOrder = if type(labelConfig) == "table" then labelConfig.LayoutOrder else nil

		local card = Instance.new("Frame")
		card.Name = "Label_" .. string.sub(text, 1, 16)
		card.Size = UDim2.new(1, 0, 0, 34)
		card.BackgroundColor3 = THEME.CardBackground
		card.BackgroundTransparency = 0.25
		card.BorderSizePixel = 0
		card.LayoutOrder = computeLayoutOrder("Label", manualOrder)
		card.Parent = ScrollContainer
		createCorner(card, 7)
		createStroke(card, THEME.Stroke, 1, 0.25)

		local dot = Instance.new("Frame")
		dot.Size = UDim2.new(0, 5, 0, 5)
		dot.Position = UDim2.new(0, 14, 0.5, 0)
		dot.AnchorPoint = Vector2.new(0, 0.5)
		dot.BackgroundColor3 = THEME.Accent
		dot.BorderSizePixel = 0
		dot.Parent = card
		createCorner(dot, 3)

		local lbl = Instance.new("TextLabel")
		lbl.Size = UDim2.new(1, -36, 1, 0)
		lbl.Position = UDim2.new(0, 26, 0, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font = Enum.Font.GothamMedium
		lbl.Text = text
		lbl.TextColor3 = THEME.TextInfo
		lbl.TextSize = 12
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextTruncate = Enum.TextTruncate.AtEnd
		lbl.Parent = card

		registerSearchable(card, text)

		local LabelObj = {}
		function LabelObj:Set(newText: string)
			lbl.Text = tostring(newText)
		end
		return LabelObj
	end

	-- ========================================================================
	-- 10. Window:CreateParagraph({ Title = "...", Content = "..." })
	-- ========================================================================
	function Window:CreateParagraph(options: { Title: string?, Content: string?, LayoutOrder: number? })
		local opts = options or {}
		local title = tostring(opts.Title or "Information")
		local content = tostring(opts.Content or "")

		local card = Instance.new("Frame")
		card.Name = "Paragraph_" .. title
		card.AutomaticSize = Enum.AutomaticSize.Y
		card.Size = UDim2.new(1, 0, 0, 56)
		card.BackgroundColor3 = THEME.CardBackground
		card.BorderSizePixel = 0
		card.LayoutOrder = computeLayoutOrder("Paragraph", opts.LayoutOrder)
		card.Parent = ScrollContainer
		createCorner(card, 8)
		createStroke(card, THEME.Stroke, 1, 0.2)
		createPadding(card, 12, 12, 14, 14)

		local pLayout = Instance.new("UIListLayout")
		pLayout.FillDirection = Enum.FillDirection.Vertical
		pLayout.SortOrder = Enum.SortOrder.LayoutOrder
		pLayout.Padding = UDim.new(0, 4)
		pLayout.Parent = card

		local titleLbl = Instance.new("TextLabel")
		titleLbl.Name = "Title"
		titleLbl.Size = UDim2.new(1, 0, 0, 16)
		titleLbl.BackgroundTransparency = 1
		titleLbl.Font = Enum.Font.GothamBold
		titleLbl.Text = title
		titleLbl.TextColor3 = THEME.TextPrimary
		titleLbl.TextSize = 13
		titleLbl.TextXAlignment = Enum.TextXAlignment.Left
		titleLbl.LayoutOrder = 1
		titleLbl.Parent = card

		local contentLbl = Instance.new("TextLabel")
		contentLbl.Name = "Content"
		contentLbl.AutomaticSize = Enum.AutomaticSize.Y
		contentLbl.Size = UDim2.new(1, 0, 0, 16)
		contentLbl.BackgroundTransparency = 1
		contentLbl.Font = Enum.Font.GothamMedium
		contentLbl.Text = content
		contentLbl.TextColor3 = THEME.TextInfo
		contentLbl.TextSize = 12
		contentLbl.TextWrapped = true
		contentLbl.TextXAlignment = Enum.TextXAlignment.Left
		contentLbl.TextYAlignment = Enum.TextYAlignment.Top
		contentLbl.LineHeight = 1.25
		contentLbl.LayoutOrder = 2
		contentLbl.Parent = card

		registerSearchable(card, title .. " " .. content)

		local ParagraphObj = {}
		function ParagraphObj:Set(newOpts: { Title: string?, Content: string? })
			if newOpts.Title then
				titleLbl.Text = tostring(newOpts.Title)
			end
			if newOpts.Content then
				contentLbl.Text = tostring(newOpts.Content)
			end
		end
		return ParagraphObj
	end

	-- ========================================================================
	-- 11. Window:CreateDivider()
	-- ========================================================================
	function Window:CreateDivider(manualOrder: number?)
		local divHolder = Instance.new("Frame")
		divHolder.Name = "Divider"
		divHolder.Size = UDim2.new(1, 0, 0, 10)
		divHolder.BackgroundTransparency = 1
		divHolder.LayoutOrder = computeLayoutOrder("Divider", manualOrder)
		divHolder.Parent = ScrollContainer

		local line = Instance.new("Frame")
		line.Size = UDim2.new(1, -8, 0, 1)
		line.Position = UDim2.new(0.5, 0, 0.5, 0)
		line.AnchorPoint = Vector2.new(0.5, 0.5)
		line.BackgroundColor3 = THEME.Stroke
		line.BackgroundTransparency = 0.2
		line.BorderSizePixel = 0
		line.Parent = divHolder

		return divHolder
	end

	function Window:Notify(notifOpts: { Title: string?, Content: string?, Duration: number? } | string)
		NightSystem:Notify(notifOpts)
	end

	function Window:Destroy()
		disconnectAll()
		if ScreenGui and ScreenGui.Parent then
			ScreenGui:Destroy()
		end
	end

	return setmetatable(Window, Window)
end

return NightSystem
