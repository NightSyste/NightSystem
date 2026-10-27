# Night System (NightUI) — Standalone Roblox Luau UI Library

**Night System (`NightUI`)** ist eine vollständig eigenständige, tab-lose Roblox Luau UI-Library im **Night System (`#121212` / `#16181A` / `#FFFFFF`)** Design. Sie benötigt keinerlei externe Abhängigkeiten und rendert sämtliche UI-Komponenten vollautomatisch, sauber sortiert und ohne Überlappungen in einem einzigen scrollbaren Container.

---

## Schnellstart (Loadstring)

```luau
local NightSystem = loadstring(game:HttpGet("https://raw.githubusercontent.com/NightSyste/NightSystem/main/NightSystem.lua"))()
```

---

## Features & Architektur

- **Kein Tab-System (Single-Container Layout):** Alle Elemente werden direkt im rechten Hauptbereich in einem butterweichen `ScrollingFrame` (`AutomaticCanvasSize = Enum.AutomaticSize.Y`, `ScrollBarThickness = 2`) gerendert + Live-Suchfilter oben rechts.
- **Intelligentes Auto-Sorting (`AutoSort = true`):**
  - Gruppiert Elemente automatisch nach Sektionen (`CreateSection`) und sortiert sie innerhalb jeder Sektion nach Typ-Hierarchie:
    1. `Sections`
    2. `Labels` / `Paragraphs`
    3. `Toggles`
    4. `Sliders`
    5. `Dropdowns` / `ColorPickers`
    6. `Inputs` / `Keybinds`
    7. `Buttons`
    8. `Dividers`
  - Ist `AutoSort = false`, werden alle Elemente strikt in ihrer Erstellungsreihenfolge gerendert.
- **Dynamische Container-Höhenanpassung:** Ausklappbare `Dropdowns` und `ColorPicker` vergrößern ihre Kartenhöhe per `TweenService`, sodass alle darunterliegenden Elemente sauber nach unten gleiten und nichts überlappt.
- **Linke Spieler- & Info-Spalte (210px):**
  - **Discord Brand Card** oben mit Copy-Button (`setclipboard` + Toast-Notification).
  - **Spieler-Dashboard** mit `72x72px` HeadShot-Avatar, `DisplayName`, `@Username`, konfigurierbarem `IntroText`, dynamischer `Place ID` + Spielname (`MarketplaceService`) und Live-`Team`-Anzeige.
  - **User-Footer** unten mit `32x32px` rundem Avatar sowie **Live-FPS & Ping**-Anzeige.
- **Fenster-Steuerung:**
  - `X`: Schließt und zerstört die UI mit Fade-Out-Tween.
  - `□`: Maximiert/Restauriert die Fenstergröße per Tween (`740x460` ↔ `920x560`).
  - `≡`: Minimiert das Fenster zu einem verschiebbaren **Night System**-Floating-Badge (oder per `ToggleKey`, Standard: `RightShift`).

---

## API-Dokumentation

### 1. Fenster erstellen (`NightSystem:CreateWindow`)

```luau
local Window = NightSystem:CreateWindow({
	Title = "Night System",
	Subtitle = "discord.gg/4cZBCyDFmX",
	LogoId = "rbxassetid://10734950309",
	IntroText = "Welcome to Night System! Join discord.gg/4cZBCyDFmX for news, updates and support.",
	AutoSort = true,
	ToggleKey = Enum.KeyCode.RightShift,
})
```

---

### 2. Sektion (`Window:CreateSection`)

Erstellt eine optische Kategorie-Überschrift mit horizontaler Linie. Bei aktiviertem `AutoSort` bildet jede Sektion einen eigenen Sortier-Block.

```luau
local CombatSection = Window:CreateSection("Autorob & Farming")
-- Optional später umbenennen:
CombatSection:Set("Main Features")
```

---

### 3. Toggle (`Window:CreateToggle`)

Rechtsbündiger Pill-Switch (`#262626` → `#FFFFFF`), animiert via `TweenService`.

```luau
local AutoRobToggle = Window:CreateToggle({
	Name = "Enable AutoRob",
	Description = "Automatically farms available robberies on the map",
	Default = false,
	Flag = "AutoRob_Enabled",
	Callback = function(Value)
		print("AutoRob Status:", Value)
	end,
})

-- Methoden:
AutoRobToggle:Set(true)
print(AutoRobToggle:Get(), NightSystem.Flags["AutoRob_Enabled"])
```

---

### 4. Button (`Window:CreateButton`)

Klickbare Karte mit Hover-/Click-Animation und Action-Chevron rechts.

```luau
local TeleportBtn = Window:CreateButton({
	Name = "Teleport to Criminal Base",
	Description = "Instantly moves your character to the safezone",
	Callback = function()
		print("Teleported!")
	end,
})

-- Methoden:
TeleportBtn:Set("Teleport to Bank")
TeleportBtn:Fire()
```

---

### 5. Slider (`Window:CreateSlider`)

Ziehbarer Schieberegler mit Live-Wert-Anzeige und direkter Zahleneingabe (`TextBox`) oben rechts.

```luau
local SpeedSlider = Window:CreateSlider({
	Name = "Vehicle Flight Speed",
	Description = "Adjust movement velocity during autorob transit",
	Min = 50,
	Max = 400,
	Default = 180,
	Increment = 5,
	Suffix = " studs/s",
	Flag = "Flight_Speed",
	Callback = function(Value)
		print("New Speed:", Value)
	end,
})

-- Methoden:
SpeedSlider:Set(220)
print(SpeedSlider:Get())
```

---

### 6. Dropdown (`Window:CreateDropdown`)

Ausklappbares Menü mit integrierter Suchleiste (`Searchable = true`), Einzel- und Mehrfachauswahl (`Multi = true`) sowie dynamischer Größenanpassung.

```luau
local TargetDropdown = Window:CreateDropdown({
	Name = "Target Locations",
	Description = "Select which robberies to prioritize",
	Options = { "Jewelry Store", "Central Bank", "Museum", "Power Plant", "Casino" },
	Default = "Central Bank",
	Multi = false,
	Searchable = true,
	Flag = "Target_Location",
	Callback = function(Value)
		print("Selected target:", Value)
	end,
})

-- Methoden:
TargetDropdown:Set("Casino")
TargetDropdown:Refresh({ "Jewelry Store", "Central Bank", "Cargo Train" }, true)
```

---

### 7. Input (`Window:CreateInput`)

Abgerundetes Textfeld (`TextBox`) mit weißer Fokus-Rahmen-Animation.

```luau
local WebhookInput = Window:CreateInput({
	Name = "Discord Webhook URL",
	Description = "Paste your webhook to receive live robbery logs",
	Placeholder = "https://discord.com/api/webhooks/...",
	Default = "",
	ClearTextOnFocus = false,
	Flag = "Webhook_URL",
	Callback = function(Text)
		print("Webhook updated:", Text)
	end,
})

-- Methoden:
WebhookInput:Set("https://discord.com/api/webhooks/example")
```

---

### 8. Keybind (`Window:CreateKeybind`)

Interaktiver Keybind-Picker (zeigt `[ ... ]` beim Binden, unterstützt Tastatur- & Maustasten, `ESC`/`Backspace` löscht die Belegung).

```luau
local PanicKey = Window:CreateKeybind({
	Name = "Emergency Eject Key",
	Description = "Quickly stops all active routines when pressed",
	Default = Enum.KeyCode.E,
	Mode = "Toggle",
	Flag = "Panic_Keybind",
	Callback = function(Key)
		print("Triggered Keybind:", Key)
	end,
})

-- Methoden:
PanicKey:Set(Enum.KeyCode.F)
```

---

### 9. ColorPicker (`Window:CreateColorPicker`)

Ausklappbarer 2D-HSV-Farbwähler mit Regenbogen-Hue-Slider sowie direkten `HEX`-, `R`-, `G`- und `B`-Eingabefeldern.

```luau
local EspColor = Window:CreateColorPicker({
	Name = "Highlight Accent Color",
	Description = "Choose the 3D box & tracer color",
	Default = Color3.fromRGB(255, 255, 255),
	Flag = "ESP_Color",
	Callback = function(Color)
		print("Selected Color:", Color)
	end,
})

-- Methoden:
EspColor:Set(Color3.fromRGB(224, 62, 62))
```

---

### 10. Label, Paragraph & Divider

```luau
local StatusLabel = Window:CreateLabel("Server Status: Undetected & Operational")
StatusLabel:Set("Server Status: Farming Active")

local InfoBox = Window:CreateParagraph({
	Title = "Autorob Trial Information",
	Content = "Autorob is free for a few days so you can test it! Enjoy it and let us know what you think.",
})

Window:CreateDivider()
```

---

### 11. Toast-Benachrichtigungen (`NightSystem:Notify`)

```luau
NightSystem:Notify({
	Title = "Night System",
	Content = "Configuration loaded successfully!",
	Duration = 4,
})
```
