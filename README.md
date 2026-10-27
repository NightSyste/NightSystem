# Night System (`NightUI`) — Roblox Luau UI Library

Eine vollständige, professionelle und 100 % eigenständige **Roblox Luau UI Library** im 1:1 **Night System** Dark-/Glassmorphism-Design (`#0B0B0C` / `#111214` / `#FFFFFF`).

---

## Schnellstart (Loadstring)

```luau
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/NightSyste/NightSystem/main/source.lua"))()
```

*(Alternativ ist dieselbe Datei auch unter `NightUI.lua` erreichbar: `https://raw.githubusercontent.com/NightSyste/NightSystem/main/NightUI.lua`)*

---

## Highlights & Design-Merkmale

- **1:1 Night System Design:**
  - Äußeres Fenster (`#0B0B0C`, `BackgroundTransparency = 0.05`, `12px` Corner, `#222326` Stroke).
  - Rechter Content-Container (`#111214` mit subtilem `-35°` `UIGradient` von `#181C22` oben rechts bis `#0E0E10` unten links).
  - Top-Bar mit `X` (Smooth Fade-Out Close), `⛶` (Maximize Toggle), `≡` (Minimize + `RightShift` Keybind) und zentrierter `40x4px` Drag-Pill.
- **Linke Sidebar:**
  - **Brand-Card** oben mit Logo, Titel (`Night System`), Discord-Invite und One-Click Copy-Button (`setclipboard` + Notification).
  - **Standardmäßig NUR der `Home`-Tab:** Keine unnötigen Dummy-Tabs. Eigene Kategorien (`Window:CreateCategory`) und Tabs (`Window:CreateTab`) werden dynamisch darunter einsortiert.
  - **Spieler-Footer** unten mit Live-HeadShot-Avatar, `DisplayName` und `@Username`.
- **Fester `Home`-Tab mit Live-Daten:**
  - Begrüßung (`Welcome back, @Username`), großes `80x80px` Charakter-HeadShot-Profil, anpassbarer `AnnouncementText` sowie Live-Server-Statistiken (`Place ID` + Spielname via `MarketplaceService` und automatisches `Your Team`-Update).
- **Automatisches Layout & Scrolling:**
  - Alle Elemente in einem Tab erhalten inkrementelle `LayoutOrder`-Werte in der Reihenfolge ihres Aufrufs und passen ihre `ScrollingFrame`-Größe vollautomatisch an (`AutomaticCanvasSize = Enum.AutomaticSize.Y` + `AbsoluteContentSize`-Listener).

---

## Vollständige API-Dokumentation

### 1. Hauptfenster erstellen (`Library:CreateWindow`)

```luau
local Window = Library:CreateWindow({
	Title = "Night System",
	DiscordInvite = "discord.gg/4cZBCyDFmX",
	LogoId = "", -- Optional: "rbxassetid://..."
	AnnouncementText = "Autorob is free for a few days so you can test it! Enjoy it and let us know what you think. Join discord.gg/4cZBCyDFmX for news, updates and support.",
	ToggleKey = Enum.KeyCode.RightShift,
})
```

### 2. Sidebar-Kategorie erstellen (`Window:CreateCategory`)

```luau
Window:CreateCategory("AUTOROB")
```

### 3. Tab erstellen (`Window:CreateTab`)

Unterstützt eingebaute Icon-Namen (`"home"`, `"shield"`, `"eye"`, `"settings"`, `"palette"`, `"bell"`, `"user"`, `"car"`, `"lock"`, `"folder"`, `"sliders"`, `"zap"`, `"sparkles"`) oder jede `"rbxassetid://..."`-ID.

```luau
local Tab = Window:CreateTab({
	Name = "AutoRob",
	Icon = "shield",
})
```

### 4. Sektion erstellen (`Tab:CreateSection`)

```luau
local Section = Tab:CreateSection("Main Controls")
```

### 5. Toggle erstellen (`Tab:CreateToggle`)

```luau
local MyToggle = Tab:CreateToggle({
	Name = "Enable Feature",
	Description = "Optional subtitle description",
	Default = false,
	Flag = "FeatureToggle",
	Callback = function(state)
		print("Toggle state:", state)
	end,
})

-- Methoden:
MyToggle:Set(true)
print(MyToggle:Get(), Library.Flags["FeatureToggle"])
```

### 6. Button erstellen (`Tab:CreateButton`)

```luau
Tab:CreateButton({
	Name = "Execute Action",
	Description = "Triggers an immediate action with ripple animation",
	Callback = function()
		print("Button clicked!")
	end,
})
```

### 7. Dropdown erstellen (`Tab:CreateDropdown`)

Unterstützt sowohl **Single-Select** (`Multi = false`) als auch **Multi-Select** (`Multi = true`) inklusive integrierter Suchleiste:

```luau
local MyDropdown = Tab:CreateDropdown({
	Name = "Select Mode",
	Options = { "Fast", "Safe", "Stealth" },
	Multi = false,
	Default = "Safe",
	Flag = "ModeDropdown",
	Callback = function(value)
		print("Selected:", value)
	end,
})

-- Methoden:
MyDropdown:Set("Fast")
MyDropdown:Refresh({ "Mode A", "Mode B", "Mode C" }, false)
```

### 8. Slider erstellen (`Tab:CreateSlider`)

```luau
local MySlider = Tab:CreateSlider({
	Name = "WalkSpeed",
	Min = 16,
	Max = 200,
	Default = 50,
	Increment = 0.5,
	Suffix = " studs",
	Flag = "WalkSpeedSlider",
	Callback = function(val)
		print("Value:", val)
	end,
})

-- Methode:
MySlider:Set(100)
```

### 9. Input / TextBox erstellen (`Tab:CreateInput` / `Tab:CreateTextBox`)

```luau
local MyInput = Tab:CreateInput({
	Name = "Webhook URL",
	Placeholder = "https://discord.com/api/webhooks/...",
	Default = "",
	NumericOnly = false,
	Flag = "WebhookInput",
	Callback = function(text)
		print("Input text:", text)
	end,
})

-- Methode:
MyInput:Set("New text")
```

### 10. Keybind erstellen (`Tab:CreateKeybind`)

```luau
local MyKeybind = Tab:CreateKeybind({
	Name = "Toggle Action",
	Default = Enum.KeyCode.E,
	Mode = "Toggle", -- "Toggle" oder "Hold"
	Flag = "ActionBind",
	Callback = function(state, key)
		print("Keybind triggered:", state, key)
	end,
})

-- Methode:
MyKeybind:Set(Enum.KeyCode.F)
```

### 11. ColorPicker erstellen (`Tab:CreateColorPicker`)

```luau
local MyColor = Tab:CreateColorPicker({
	Name = "Accent Color",
	Default = Color3.fromRGB(255, 255, 255),
	Flag = "AccentColorFlag",
	Callback = function(color)
		print("Color:", color)
	end,
})

-- Methode:
MyColor:Set(Color3.fromRGB(120, 180, 255))
```

### 12. Label, Paragraph & Divider

```luau
local MyLabel = Tab:CreateLabel("Server Status: Online")
MyLabel:Set("Server Status: Active")

local MyParagraph = Tab:CreateParagraph({
	Title = "Changelog",
	Content = "Added full HSV ColorPicker, Multi-Dropdown search and JSON config system.",
})
MyParagraph:Set({ Title = "Updated Title", Content = "Updated paragraph content." })

Tab:CreateDivider()
```

### 13. Notification-System (`Library:Notify`)

```luau
Library:Notify({
	Title = "Night System",
	Content = "Configuration loaded successfully!",
	Duration = 4,
	Icon = "check",
})
```

### 14. Config- & Flag-System

```luau
-- Direktes Auslesen über Library.Flags:
print(Library.Flags["FeatureToggle"])

-- Speichern & Laden über writefile / readfile (HttpService:JSONEncode):
Library:SaveConfig("my_profile")
Library:LoadConfig("my_profile")
```
