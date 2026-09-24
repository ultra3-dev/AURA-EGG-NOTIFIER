-- AURA EGG 2.0.2 ULTRA // BOOT + UI
--[[
	🥚 EGG DETECTOR - ULTRA MEGA HYPER-VELOCITY ADVANCED EDITION
	================================================================
	✓ Inicio INSTANTÁNEO - Alerta inmediata al ejecutar
	✓ Detección ULTRA-RÁPIDA - Sin latencia
	✓ Envío DIRECTO - Webhook inmediato sin colas
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local auraRuntime = (type(getgenv) == "function" and getgenv()) or _G
if type(auraRuntime.AURA_EGG_NOTIFIER_STOP) == "function" then
pcall(auraRuntime.AURA_EGG_NOTIFIER_STOP)
end
local scriptStopped = false
auraRuntime.AURA_EGG_NOTIFIER_STOP = function()
scriptStopped = true
end

local CONFIG = {
	WebhookURL = (type(getgenv) == "function" and getgenv().AURA_EGG_WEBHOOK)
		or "PASTE_A_NEW_DISCORD_WEBHOOK_HERE",
	LastSeenWebhookURL = (type(getgenv) == "function" and getgenv().AURA_EGG_LAST_SEEN_WEBHOOK)
		or "PASTE_A_LAST_SEEN_DISCORD_WEBHOOK_HERE",
LastSeenMessageID = "1552117304609738823",
	Keywords = {"egg", "huevo", "spawned", "appeared", "aparecido", "secret", "divine", "legendary", "mythical", "eternal", "cosmic"},
	Blacklist = {"[debug]", "eggtooldisplay", "placedeggrenderer", "guard", "trace", "anticheat", "jobid"},
	DisplayTime = 120,
	MaxNotifications = 2000,
	ConsoleMaxLines = 2500,
	PriorityWindow = 0.35,
	MaxPriorityQueue = 12,
	ServerRefreshInterval = 15,
	AccessKey = "#3003AURA-FAMILY-X333***#ULTRA",
	MaxAccessAttempts = 3,
	ImportantEternalKeywords = {
		"oni tiger",
		"gorilla king",
		"skeleton horse",
		"pegasus",
	},
	Version = "2.0.2 ULTRA"
}

local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local httpRequest = (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local eggSequence = 0
local recentProcessedText = {}
local unreadCount = 0
local panelOpen = true
local pendingEggs = {}
local priorityTimer = nil
local priorityVersion = 0
local lastJoinServerId = nil
local cachedPublicServerIds = {}
local serverCacheRefreshing = false
local promotionState = {
version = 1,
url = "",
label = "PROMOTION",
maxUses = 0,
used = 0,
intervalMinutes = 0,
	nextAvailableAt = 0,
	emoji = "",
	rarity = ""
}

local configState = {
version = 1,
entries = {},
webhooks = {main = "", lastSeen = ""}
}
local CONFIG_RARITY_OPTIONS = {"Secret", "Eternal", "Divine"}
local configSelectedKey = nil

if playerGui:FindFirstChild("EggDetectorStealth") then
	playerGui.EggDetectorStealth:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggDetectorStealth"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "EggLogPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0, 390, 0, 420)
panel.BackgroundColor3 = Color3.fromRGB(8, 14, 31)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Parent = screenGui

local panelScale = Instance.new("UIScale")
panelScale.Scale = 1
panelScale.Parent = panel

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(0, 174, 255)
panelStroke.Thickness = 2
panelStroke.Transparency = 0.08
panelStroke.Parent = panel

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 62)
topBar.BackgroundColor3 = Color3.fromRGB(20, 18, 54)
topBar.BorderSizePixel = 0
topBar.Parent = panel

local topBarCorner = Instance.new("UICorner")
topBarCorner.CornerRadius = UDim.new(0, 14)
topBarCorner.Parent = topBar

local topBarMask = Instance.new("Frame")
topBarMask.Size = UDim2.new(1, 0, 0, 16)
topBarMask.Position = UDim2.new(0, 0, 1, -16)
topBarMask.BackgroundColor3 = topBar.BackgroundColor3
topBarMask.BorderSizePixel = 0
topBarMask.Parent = topBar

local function createCanvasIcon(parent, kind, color, size, position, name)
	local root = Instance.new("Frame")
	root.Name = name or "CanvasIcon"
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = position or UDim2.new(0.5, 0, 0.5, 0)
	root.Size = size or UDim2.new(0, 18, 0, 18)
	root.BackgroundTransparency = 1
	root.BorderSizePixel = 0
	root.ZIndex = parent.ZIndex + 1
	root.Parent = parent

	local function shape(shapeName, shapeSize, shapePosition, rotation, transparency)
		local part = Instance.new("Frame")
		part.Name = shapeName
		part.AnchorPoint = Vector2.new(0.5, 0.5)
		part.Position = shapePosition
		part.Size = shapeSize
		part.BackgroundColor3 = color
		part.BackgroundTransparency = transparency or 0
		part.BorderSizePixel = 0
		part.Rotation = rotation or 0
		part.ZIndex = root.ZIndex
		part:SetAttribute("CanvasPart", true)
		part.Parent = root
		return part
	end

	local function round(part, radius)
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(radius or 0.35, 0)
		corner.Parent = part
	end

	local function outline(part, thickness)
		local stroke = Instance.new("UIStroke")
		stroke.Color = color
		stroke.Thickness = thickness or 1.2
		stroke.Transparency = 0
		stroke:SetAttribute("CanvasPart", true)
		stroke.Parent = part
	end

	if kind == "close" then
		shape("CloseLineA", UDim2.new(0, 2, 0, 15), UDim2.new(0.5, 0, 0.5, 0), 45)
		shape("CloseLineB", UDim2.new(0, 2, 0, 15), UDim2.new(0.5, 0, 0.5, 0), -45)
	elseif kind == "egg" then
		local egg = shape("EggShell", UDim2.new(0.58, 0, 0.76, 0), UDim2.new(0.5, 0, 0.53, 0))
		round(egg, 0.5)
		outline(egg, 1.25)
		local shine = shape("EggShine", UDim2.new(0.12, 0, 0.18, 0), UDim2.new(0.36, 0, 0.34, 0), 0, 0)
		round(shine, 0.5)
	elseif kind == "log" then
		local sheet = shape("LogSheet", UDim2.new(0.58, 0, 0.72, 0), UDim2.new(0.5, 0, 0.5, 0), 0, 1)
		round(sheet, 0.12)
		outline(sheet, 1.15)
		shape("LogLineA", UDim2.new(0.32, 0, 0, 1.5), UDim2.new(0.5, 0, 0.38, 0))
		shape("LogLineB", UDim2.new(0.32, 0, 0, 1.5), UDim2.new(0.5, 0, 0.53, 0))
		shape("LogLineC", UDim2.new(0.22, 0, 0, 1.5), UDim2.new(0.45, 0, 0.68, 0))
	elseif kind == "announce" then
		local barA = shape("AnnounceBarA", UDim2.new(0, 2.5, 0.32, 0), UDim2.new(0.25, 0, 0.68, 0))
		local barB = shape("AnnounceBarB", UDim2.new(0, 2.5, 0.52, 0), UDim2.new(0.5, 0, 0.58, 0))
		local barC = shape("AnnounceBarC", UDim2.new(0, 2.5, 0.72, 0), UDim2.new(0.75, 0, 0.48, 0))
		round(barA, 0.5)
		round(barB, 0.5)
		round(barC, 0.5)
	elseif kind == "spark" then
		local diamond = shape("SparkDiamond", UDim2.new(0.42, 0, 0.42, 0), UDim2.new(0.5, 0, 0.5, 0), 45)
		round(diamond, 0.12)
		shape("SparkCore", UDim2.new(0.15, 0, 0.15, 0), UDim2.new(0.5, 0, 0.5, 0), 0)
	elseif kind == "money" then
		local bill = shape("MoneyBill", UDim2.new(0.82, 0, 0.54, 0), UDim2.new(0.5, 0, 0.5, 0), -8, 1)
		round(bill, 0.14)
		outline(bill, 1.15)
		local seal = shape("MoneySeal", UDim2.new(0.22, 0, 0.22, 0), UDim2.new(0.5, 0, 0.5, 0))
		round(seal, 0.5)
		shape("MoneyStem", UDim2.new(0, 1.6, 0.30, 0), UDim2.new(0.5, 0, 0.5, 0))
		shape("MoneyTop", UDim2.new(0.14, 0, 0, 1.5), UDim2.new(0.5, 0, 0.37, 0))
		shape("MoneyBottom", UDim2.new(0.14, 0, 0, 1.5), UDim2.new(0.5, 0, 0.63, 0))
	elseif kind == "megaphone" then
		local horn = shape("MegaphoneHorn", UDim2.new(0.48, 0, 0.60, 0), UDim2.new(0.62, 0, 0.45, 0), -25, 1)
		round(horn, 0.16)
		outline(horn, 1.1)
		shape("MegaphoneHandle", UDim2.new(0.16, 0, 0.34, 0), UDim2.new(0.35, 0, 0.68, 0), -25)
		shape("MegaphoneSoundA", UDim2.new(0.18, 0, 0, 1.6), UDim2.new(0.80, 0, 0.31, 0), -25)
		shape("MegaphoneSoundB", UDim2.new(0.25, 0, 0, 1.6), UDim2.new(0.88, 0, 0.51, 0), -25)
	elseif kind == "system" then
		local ring = shape("SystemRing", UDim2.new(0.7, 0, 0.7, 0), UDim2.new(0.5, 0, 0.5, 0), 0, 1)
		round(ring, 0.5)
		outline(ring, 1.15)
		local core = shape("SystemCore", UDim2.new(0.22, 0, 0.22, 0), UDim2.new(0.5, 0, 0.5, 0))
		round(core, 0.5)
	elseif kind == "console" then
		local screen = shape("ConsoleScreen", UDim2.new(0.78, 0, 0.62, 0), UDim2.new(0.5, 0, 0.48, 0), 0, 1)
		round(screen, 0.12)
		outline(screen, 1.1)
		shape("ConsolePrompt", UDim2.new(0.18, 0, 0, 1.5), UDim2.new(0.31, 0, 0.52, 0))
		shape("ConsoleLineA", UDim2.new(0.36, 0, 0, 1.5), UDim2.new(0.56, 0, 0.39, 0))
		shape("ConsoleLineB", UDim2.new(0.28, 0, 0, 1.5), UDim2.new(0.52, 0, 0.63, 0))
	elseif kind == "sliders" then
		for index, data in ipairs({{0.34, 0.32}, {0.58, 0.50}, {0.78, 0.68}}) do
			local line = shape("SliderLine" .. index, UDim2.new(0.72, 0, 0, 1.5), UDim2.new(0.5, 0, data[1], 0))
			round(line, 0.5)
			local knob = shape("SliderKnob" .. index, UDim2.new(0.16, 0, 0.16, 0), UDim2.new(data[2], 0, data[1], 0))
			round(knob, 0.5)
		end
	elseif kind == "webhook" then
		local left = shape("WebhookLeft", UDim2.new(0.34, 0, 0.34, 0), UDim2.new(0.35, 0, 0.43, 0), 45, 1)
		local right = shape("WebhookRight", UDim2.new(0.34, 0, 0.34, 0), UDim2.new(0.65, 0, 0.57, 0), 45, 1)
		round(left, 0.25)
		round(right, 0.25)
		outline(left, 1.1)
		outline(right, 1.1)
		shape("WebhookBridge", UDim2.new(0.28, 0, 0, 2), UDim2.new(0.5, 0, 0.5, 0), -35)
	elseif kind == "terminal" then
		local terminal = shape("TerminalShell", UDim2.new(0.78, 0, 0.64, 0), UDim2.new(0.5, 0, 0.5, 0), 0, 1)
		round(terminal, 0.1)
		outline(terminal, 1.1)
		shape("TerminalChevronA", UDim2.new(0.16, 0, 0, 1.8), UDim2.new(0.34, 0, 0.48, 0), 35)
		shape("TerminalChevronB", UDim2.new(0.16, 0, 0, 1.8), UDim2.new(0.43, 0, 0.52, 0), -35)
		shape("TerminalCursor", UDim2.new(0.18, 0, 0, 1.8), UDim2.new(0.66, 0, 0.62, 0))
	elseif kind == "check" then
		shape("CheckA", UDim2.new(0, 2.2, 0, 8), UDim2.new(0.38, 0, 0.58, 0), -45)
		shape("CheckB", UDim2.new(0, 2.2, 0, 13), UDim2.new(0.62, 0, 0.43, 0), 45)
	elseif kind == "plus" then
		local horizontal = shape("PlusHorizontal", UDim2.new(0.68, 0, 0, 2.2), UDim2.new(0.5, 0, 0.5, 0))
		local vertical = shape("PlusVertical", UDim2.new(0, 2.2, 0.68, 0), UDim2.new(0.5, 0, 0.5, 0))
		round(horizontal, 0.5)
		round(vertical, 0.5)
	elseif kind == "trash" then
		local bin = shape("TrashBin", UDim2.new(0.52, 0, 0.58, 0), UDim2.new(0.5, 0, 0.57, 0))
		round(bin, 0.12)
		shape("TrashLid", UDim2.new(0.68, 0, 0, 2), UDim2.new(0.5, 0, 0.25, 0))
		shape("TrashHandle", UDim2.new(0.24, 0, 0, 2), UDim2.new(0.5, 0, 0.17, 0))
	elseif kind == "send" then
		local plane = shape("SendPlane", UDim2.new(0.7, 0, 0.42, 0), UDim2.new(0.52, 0, 0.48, 0), -25)
		round(plane, 0.12)
		shape("SendCut", UDim2.new(0.1, 0, 0.42, 0), UDim2.new(0.35, 0, 0.57, 0), 25, 0.35)
	elseif kind == "link" then
		local link = shape("LinkBody", UDim2.new(0.68, 0, 0.22, 0), UDim2.new(0.5, 0, 0.5, 0), -25, 1)
		round(link, 0.5)
		outline(link, 1.2)
		shape("LinkCut", UDim2.new(0.16, 0, 0.3, 0), UDim2.new(0.5, 0, 0.5, 0), -25, 1)
	elseif kind == "tag" then
		local tag = shape("TagBody", UDim2.new(0.62, 0, 0.56, 0), UDim2.new(0.47, 0, 0.52, 0), 0, 1)
		round(tag, 0.12)
		outline(tag, 1.1)
		local tagHole = shape("TagHole", UDim2.new(0.14, 0, 0.14, 0), UDim2.new(0.27, 0, 0.35, 0))
		round(tagHole, 0.5)
	elseif kind == "copy" then
		local back = shape("CopyBack", UDim2.new(0.54, 0, 0.62, 0), UDim2.new(0.58, 0, 0.42, 0), 0, 1)
		round(back, 0.1)
		outline(back, 1.1)
		local front = shape("CopyFront", UDim2.new(0.54, 0, 0.62, 0), UDim2.new(0.42, 0, 0.58, 0))
		round(front, 0.1)
	elseif kind == "clock" then
		local clock = shape("ClockRing", UDim2.new(0.76, 0, 0.76, 0), UDim2.new(0.5, 0, 0.5, 0), 0, 1)
		round(clock, 0.5)
		outline(clock, 1.1)
		shape("ClockHandA", UDim2.new(0, 1.7, 0.27, 0), UDim2.new(0.5, 0, 0.39, 0))
		shape("ClockHandB", UDim2.new(0.26, 0, 0, 1.7), UDim2.new(0.58, 0, 0.54, 0), 35)
	elseif kind == "route" then
		local routeLine = shape("RouteLine", UDim2.new(0.62, 0, 0, 2), UDim2.new(0.5, 0, 0.5, 0))
		round(routeLine, 0.5)
		local routeStart = shape("RouteStart", UDim2.new(0.2, 0, 0.2, 0), UDim2.new(0.2, 0, 0.5, 0))
		local routeEnd = shape("RouteEnd", UDim2.new(0.2, 0, 0.2, 0), UDim2.new(0.8, 0, 0.5, 0))
		round(routeStart, 0.5)
		round(routeEnd, 0.5)
	elseif kind == "broom" then
		shape("BroomHandle", UDim2.new(0, 2, 0.76, 0), UDim2.new(0.6, 0, 0.42, 0), 35)
		local brush = shape("BroomBrush", UDim2.new(0.52, 0, 0.18, 0), UDim2.new(0.3, 0, 0.68, 0), -20)
		round(brush, 0.35)
	elseif kind == "endpoint" then
		local node = shape("EndpointNode", UDim2.new(0.62, 0, 0.62, 0), UDim2.new(0.5, 0, 0.5, 0), 45, 1)
		round(node, 0.2)
		outline(node, 1.1)
		local endpointCore = shape("EndpointCore", UDim2.new(0.2, 0, 0.2, 0), UDim2.new(0.5, 0, 0.5, 0))
		round(endpointCore, 0.5)
	elseif kind == "power" then
		local ring = shape("PowerRing", UDim2.new(0.76, 0, 0.76, 0), UDim2.new(0.5, 0, 0.54, 0), 0, 1)
		round(ring, 0.5)
		outline(ring, 1.3)
		shape("PowerStem", UDim2.new(0, 2, 0.42, 0), UDim2.new(0.5, 0, 0.28, 0))
	end

	return root
end

local function tintCanvasIcon(root, color)
	for _, item in ipairs(root:GetDescendants()) do
		if item:GetAttribute("CanvasPart") then
			if item:IsA("Frame") then
				item.BackgroundColor3 = color
			elseif item:IsA("UIStroke") then
				item.Color = color
			end
		end
	end
end

local header = Instance.new("TextLabel")
header.Name = "Header"
header.Position = UDim2.new(0, 18, 0, 10)
header.Size = UDim2.new(1, -70, 0, 22)
header.BackgroundTransparency = 1
header.Text = "AURA EGG NOTIFIER ACTIVATED"
header.TextColor3 = Color3.fromRGB(235, 204, 255)
header.Font = Enum.Font.GothamBold
header.TextSize = 16
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.new(0, 19, 0, 34)
subtitle.Size = UDim2.new(1, -70, 0, 16)
subtitle.BackgroundTransparency = 1
subtitle.Text = "WEBHOOK 2.0.2 ULTRA  //  MODULAR LIVE"
subtitle.TextColor3 = Color3.fromRGB(151, 255, 204)
subtitle.Font = Enum.Font.Code
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = topBar

local panelClose = Instance.new("TextButton")
panelClose.Name = "Close"
panelClose.AnchorPoint = Vector2.new(1, 0)
panelClose.Position = UDim2.new(1, -12, 0, 10)
panelClose.Size = UDim2.new(0, 32, 0, 32)
panelClose.BackgroundColor3 = Color3.fromRGB(82, 40, 108)
panelClose.BackgroundTransparency = 0.1
panelClose.BorderSizePixel = 0
panelClose.Text = ""
panelClose.TextColor3 = Color3.fromRGB(255, 111, 151)
panelClose.Font = Enum.Font.GothamBold
panelClose.TextSize = 22
panelClose.AutoButtonColor = false
panelClose.Parent = topBar

createCanvasIcon(
	panelClose,
	"close",
	Color3.fromRGB(255, 111, 151),
	UDim2.new(0, 15, 0, 15),
	UDim2.new(0.5, 0, 0.5, 0)
)

local panelCloseCorner = Instance.new("UICorner")
panelCloseCorner.CornerRadius = UDim.new(0, 8)
panelCloseCorner.Parent = panelClose

local logPanel = Instance.new("ScrollingFrame")
logPanel.Name = "Log"
logPanel.Position = UDim2.new(0, 12, 0, 100)
logPanel.Size = UDim2.new(1, -24, 1, -150)
logPanel.BackgroundColor3 = Color3.fromRGB(7, 12, 26)
logPanel.BackgroundTransparency = 0.05
logPanel.BorderSizePixel = 0
logPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
logPanel.AutomaticCanvasSize = Enum.AutomaticSize.None
logPanel.ScrollBarThickness = 4
logPanel.ScrollBarImageColor3 = Color3.fromRGB(0, 174, 255)
logPanel.ScrollingDirection = Enum.ScrollingDirection.Y
logPanel.ClipsDescendants = true
logPanel.Parent = panel

local logCorner = Instance.new("UICorner")
logCorner.CornerRadius = UDim.new(0, 10)
logCorner.Parent = logPanel

local logPadding = Instance.new("UIPadding")
logPadding.PaddingTop = UDim.new(0, 10)
logPadding.PaddingBottom = UDim.new(0, 10)
logPadding.PaddingLeft = UDim.new(0, 8)
logPadding.PaddingRight = UDim.new(0, 8)
logPadding.Parent = logPanel

local logLayout = Instance.new("UIListLayout")
logLayout.SortOrder = Enum.SortOrder.LayoutOrder
logLayout.Padding = UDim.new(0, 7)
logLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
logLayout.Parent = logPanel

local logJumpButton = Instance.new("TextButton")
logJumpButton.Name = "LogJumpToLatest"
logJumpButton.AnchorPoint = Vector2.new(1, 1)
logJumpButton.Position = UDim2.new(1, -22, 1, -62)
logJumpButton.Size = UDim2.new(0, 32, 0, 32)
logJumpButton.BackgroundColor3 = Color3.fromRGB(122, 57, 177)
logJumpButton.BackgroundTransparency = 0.04
logJumpButton.BorderSizePixel = 0
logJumpButton.Text = "↓"
logJumpButton.TextColor3 = Color3.fromRGB(255, 240, 255)
logJumpButton.Font = Enum.Font.GothamBold
logJumpButton.TextSize = 20
logJumpButton.AutoButtonColor = false
logJumpButton.ZIndex = 10
logJumpButton.Parent = panel

local logJumpCorner = Instance.new("UICorner")
logJumpCorner.CornerRadius = UDim.new(1, 0)
logJumpCorner.Parent = logJumpButton

local logBody = Instance.new("TextLabel")
logBody.Name = "PersistentEggHistory"
logBody.Position = UDim2.new(0, 10, 0, 10)
logBody.Size = UDim2.new(1, -20, 0, 0)
logBody.AutomaticSize = Enum.AutomaticSize.Y
logBody.BackgroundTransparency = 1
logBody.Text = ""
logBody.TextColor3 = Color3.fromRGB(240, 240, 240)
logBody.Font = Enum.Font.Code
logBody.TextSize = 10
logBody.TextWrapped = true
logBody.TextXAlignment = Enum.TextXAlignment.Left
logBody.TextYAlignment = Enum.TextYAlignment.Top
logBody.Parent = logPanel
logLayout.Parent = nil

local function updateLogJumpVisibility()
	local maximum = math.max(0, logPanel.CanvasSize.Y.Offset - logPanel.AbsoluteWindowSize.Y)
	local current = logPanel.CanvasPosition.Y
	logJumpButton.Visible = logPanel.Visible
		and maximum > 120
		and current < maximum - 80
end

local function refreshLogCanvas()
	local contentHeight = math.max(logBody.AbsoluteSize.Y + 20, logPanel.AbsoluteWindowSize.Y + 1)
	logPanel.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
	updateLogJumpVisibility()
end

logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshLogCanvas)
logPanel:GetPropertyChangedSignal("CanvasPosition"):Connect(updateLogJumpVisibility)
logPanel:GetPropertyChangedSignal("CanvasSize"):Connect(updateLogJumpVisibility)
updateLogJumpVisibility()

local navigation = Instance.new("ScrollingFrame")
navigation.Name = "Navigation"
navigation.Position = UDim2.new(0, 12, 0, 64)
navigation.Size = UDim2.new(1, -24, 0, 28)
navigation.CanvasSize = UDim2.new(0, 430, 0, 0)
navigation.ScrollingEnabled = false
navigation.ScrollBarThickness = 0
navigation.ScrollingDirection = Enum.ScrollingDirection.X
navigation.ScrollingEnabled = true
navigation.BackgroundTransparency = 1
navigation.Parent = panel

local function styleTab(button, active)
	button.BackgroundColor3 = active
		and Color3.fromRGB(0, 128, 255)
		or Color3.fromRGB(16, 24, 48)
	button.TextColor3 = active
		and Color3.fromRGB(255, 235, 255)
		or Color3.fromRGB(137, 160, 198)

	local label = button:FindFirstChild("TabLabel")
	if label then
		label.TextColor3 = button.TextColor3
	end

	local icon = button:FindFirstChild("TabIcon")
	if icon then
		tintCanvasIcon(icon, button.TextColor3)
	end

	local gradient = button:FindFirstChild("TabGradient")
	if gradient then gradient:Destroy() end
	button.BackgroundColor3 = active and Color3.fromRGB(0, 128, 255) or Color3.fromRGB(16, 24, 48)

	local stroke = button:FindFirstChild("TabStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "TabStroke"
		stroke.Parent = button
	end
	stroke.Color = active and Color3.fromRGB(0, 198, 255) or Color3.fromRGB(38, 62, 101)
	stroke.Thickness = active and 1.5 or 1
	stroke.Transparency = active and 0.05 or 0.35
end

local logTab = Instance.new("TextButton")
logTab.Name = "LogTab"
logTab.Size = UDim2.new(0, 60, 1, 0)
logTab.BackgroundColor3 = Color3.fromRGB(122, 57, 177)
logTab.BorderSizePixel = 0
logTab.Text = ""
logTab.TextColor3 = Color3.fromRGB(255, 235, 255)
logTab.Font = Enum.Font.Code
logTab.TextSize = 14
logTab.TextXAlignment = Enum.TextXAlignment.Center
logTab.TextYAlignment = Enum.TextYAlignment.Center
logTab.AutoButtonColor = false
logTab.Parent = navigation

local logTabIcon = createCanvasIcon(
	logTab,
	"log",
	logTab.TextColor3,
	UDim2.new(0, 16, 0, 16),
	UDim2.new(0, 15, 0.5, 0),
	"TabIcon"
)
local logTabLabel = Instance.new("TextLabel")
logTabLabel.Name = "TabLabel"
logTabLabel.Position = UDim2.new(0, 30, 0, 0)
logTabLabel.Size = UDim2.new(1, -34, 1, 0)
logTabLabel.BackgroundTransparency = 1
logTabLabel.Text = "LOG"
logTabLabel.TextColor3 = logTab.TextColor3
logTabLabel.Font = Enum.Font.Code
logTabLabel.TextSize = 13
logTabLabel.TextXAlignment = Enum.TextXAlignment.Left
logTabLabel.TextYAlignment = Enum.TextYAlignment.Center
logTabLabel.Parent = logTab

local logTabCorner = Instance.new("UICorner")
logTabCorner.CornerRadius = UDim.new(0, 6)
logTabCorner.Parent = logTab

local promotionTab = Instance.new("TextButton")
promotionTab.Name = "PromotionsTab"
promotionTab.Position = UDim2.new(0, 62, 0, 0)
promotionTab.Size = UDim2.new(0, 72, 1, 0)
promotionTab.BackgroundColor3 = Color3.fromRGB(57, 34, 80)
promotionTab.BorderSizePixel = 0
promotionTab.Text = ""
promotionTab.TextColor3 = Color3.fromRGB(137, 160, 198)
promotionTab.Font = Enum.Font.Code
promotionTab.TextSize = 14
promotionTab.TextXAlignment = Enum.TextXAlignment.Center
promotionTab.TextYAlignment = Enum.TextYAlignment.Center
promotionTab.AutoButtonColor = false
promotionTab.Parent = navigation

local promotionTabIcon = createCanvasIcon(
promotionTab,
"money",
promotionTab.TextColor3,
UDim2.new(0, 16, 0, 16),
UDim2.new(0, 15, 0.5, 0),
"TabIcon"
)
local promotionTabLabel = Instance.new("TextLabel")
promotionTabLabel.Name = "TabLabel"
promotionTabLabel.Position = UDim2.new(0, 30, 0, 0)
promotionTabLabel.Size = UDim2.new(1, -34, 1, 0)
promotionTabLabel.BackgroundTransparency = 1
promotionTabLabel.Text = "PROMO"
promotionTabLabel.TextColor3 = promotionTab.TextColor3
promotionTabLabel.Font = Enum.Font.Code
promotionTabLabel.TextSize = 10
promotionTabLabel.TextXAlignment = Enum.TextXAlignment.Left
promotionTabLabel.TextYAlignment = Enum.TextYAlignment.Center
promotionTabLabel.Parent = promotionTab

local promotionTabCorner = Instance.new("UICorner")
promotionTabCorner.CornerRadius = UDim.new(0, 6)
promotionTabCorner.Parent = promotionTab

local announcerTab = Instance.new("TextButton")
announcerTab.Name = "AnnouncerTab"
announcerTab.Position = UDim2.new(0, 138, 0, 0)
announcerTab.Size = UDim2.new(0, 88, 1, 0)
announcerTab.BackgroundColor3 = Color3.fromRGB(57, 34, 80)
announcerTab.BorderSizePixel = 0
announcerTab.Text = ""
announcerTab.TextColor3 = Color3.fromRGB(137, 160, 198)
announcerTab.Font = Enum.Font.Code
announcerTab.TextSize = 14
announcerTab.TextXAlignment = Enum.TextXAlignment.Center
announcerTab.TextYAlignment = Enum.TextYAlignment.Center
announcerTab.AutoButtonColor = false
announcerTab.Parent = navigation

local announcerTabIcon = createCanvasIcon(
	announcerTab,
"megaphone",
	announcerTab.TextColor3,
	UDim2.new(0, 16, 0, 16),
	UDim2.new(0, 15, 0.5, 0),
	"TabIcon"
)
local announcerTabLabel = Instance.new("TextLabel")
announcerTabLabel.Name = "TabLabel"
announcerTabLabel.Position = UDim2.new(0, 30, 0, 0)
announcerTabLabel.Size = UDim2.new(1, -34, 1, 0)
announcerTabLabel.BackgroundTransparency = 1
announcerTabLabel.Text = "ANNOUNCER"
announcerTabLabel.TextColor3 = announcerTab.TextColor3
announcerTabLabel.Font = Enum.Font.Code
announcerTabLabel.TextSize = 9
announcerTabLabel.TextXAlignment = Enum.TextXAlignment.Left
announcerTabLabel.TextYAlignment = Enum.TextYAlignment.Center
announcerTabLabel.Parent = announcerTab

local announcerTabCorner = Instance.new("UICorner")
announcerTabCorner.CornerRadius = UDim.new(0, 6)
announcerTabCorner.Parent = announcerTab

local configUi = {}
configUi.tab = Instance.new("TextButton")
configUi.tab.Name = "ConfigTab"
configUi.tab.Position = UDim2.new(0, 230, 0, 0)
configUi.tab.Size = UDim2.new(0, 72, 1, 0)
configUi.tab.BackgroundColor3 = Color3.fromRGB(57, 34, 80)
configUi.tab.BorderSizePixel = 0
configUi.tab.Text = ""
configUi.tab.TextColor3 = Color3.fromRGB(137, 160, 198)
configUi.tab.Font = Enum.Font.Code
configUi.tab.TextSize = 14
configUi.tab.TextXAlignment = Enum.TextXAlignment.Center
configUi.tab.TextYAlignment = Enum.TextYAlignment.Center
configUi.tab.AutoButtonColor = false
configUi.tab.Parent = navigation

configUi.tabIcon = createCanvasIcon(
	configUi.tab,
	"sliders",
	configUi.tab.TextColor3,
	UDim2.new(0, 16, 0, 16),
	UDim2.new(0, 15, 0.5, 0),
	"TabIcon"
)
configUi.tabLabel = Instance.new("TextLabel")
configUi.tabLabel.Name = "TabLabel"
configUi.tabLabel.Position = UDim2.new(0, 30, 0, 0)
configUi.tabLabel.Size = UDim2.new(1, -34, 1, 0)
configUi.tabLabel.BackgroundTransparency = 1
configUi.tabLabel.Text = "CONFIG"
configUi.tabLabel.TextColor3 = configUi.tab.TextColor3
configUi.tabLabel.Font = Enum.Font.Code
configUi.tabLabel.TextSize = 9
configUi.tabLabel.TextXAlignment = Enum.TextXAlignment.Left
configUi.tabLabel.TextYAlignment = Enum.TextYAlignment.Center
configUi.tabLabel.Parent = configUi.tab

configUi.tabCorner = Instance.new("UICorner")
configUi.tabCorner.CornerRadius = UDim.new(0, 6)
configUi.tabCorner.Parent = configUi.tab

configUi.webhookTab = Instance.new("TextButton")
configUi.webhookTab.Name = "WebhookTab"
configUi.webhookTab.Position = UDim2.new(0, 306, 0, 0)
configUi.webhookTab.Size = UDim2.new(0, 88, 1, 0)
configUi.webhookTab.BackgroundColor3 = Color3.fromRGB(57, 34, 80)
configUi.webhookTab.BorderSizePixel = 0
configUi.webhookTab.Text = ""
configUi.webhookTab.TextColor3 = Color3.fromRGB(137, 160, 198)
configUi.webhookTab.Font = Enum.Font.Code
configUi.webhookTab.TextSize = 14
configUi.webhookTab.TextXAlignment = Enum.TextXAlignment.Center
configUi.webhookTab.TextYAlignment = Enum.TextYAlignment.Center
configUi.webhookTab.AutoButtonColor = false
configUi.webhookTab.Parent = navigation

configUi.webhookTabIcon = createCanvasIcon(configUi.webhookTab, "webhook", configUi.webhookTab.TextColor3, UDim2.new(0, 16, 0, 16), UDim2.new(0, 15, 0.5, 0), "TabIcon")
configUi.webhookTabLabel = Instance.new("TextLabel")
configUi.webhookTabLabel.Name = "TabLabel"
configUi.webhookTabLabel.Position = UDim2.new(0, 30, 0, 0)
configUi.webhookTabLabel.Size = UDim2.new(1, -34, 1, 0)
configUi.webhookTabLabel.BackgroundTransparency = 1
configUi.webhookTabLabel.Text = "WEBHOOK"
configUi.webhookTabLabel.TextColor3 = configUi.webhookTab.TextColor3
configUi.webhookTabLabel.Font = Enum.Font.Code
configUi.webhookTabLabel.TextSize = 8
configUi.webhookTabLabel.TextXAlignment = Enum.TextXAlignment.Left
configUi.webhookTabLabel.TextYAlignment = Enum.TextYAlignment.Center
configUi.webhookTabLabel.Parent = configUi.webhookTab

configUi.webhookTabCorner = Instance.new("UICorner")
configUi.webhookTabCorner.CornerRadius = UDim.new(0, 6)
configUi.webhookTabCorner.Parent = configUi.webhookTab


local consoleTab = Instance.new("TextButton")
consoleTab.Name = "ConsoleTab"
consoleTab.Position = UDim2.new(0, 398, 0, 0)
consoleTab.Size = UDim2.new(0, 24, 1, 0)
consoleTab.BackgroundColor3 = Color3.fromRGB(57, 34, 80)
consoleTab.BorderSizePixel = 0
consoleTab.Text = ""
consoleTab.TextColor3 = Color3.fromRGB(137, 160, 198)
consoleTab.AutoButtonColor = false
consoleTab.Parent = navigation

local consoleTabIcon = createCanvasIcon(
	consoleTab,
	"terminal",
	consoleTab.TextColor3,
	UDim2.new(0, 16, 0, 16),
	UDim2.new(0.5, 0, 0.5, 0),
	"TabIcon"
)

local consoleTabCorner = Instance.new("UICorner")
consoleTabCorner.CornerRadius = UDim.new(0, 6)
consoleTabCorner.Parent = consoleTab

local announcementPanel = Instance.new("Frame")
announcementPanel.Name = "AnnouncementBuilder"
announcementPanel.Position = UDim2.new(0, 12, 0, 100)
announcementPanel.Size = UDim2.new(1, -24, 1, -150)
announcementPanel.BackgroundColor3 = Color3.fromRGB(29, 19, 45)
announcementPanel.BackgroundTransparency = 0.05
announcementPanel.BorderSizePixel = 0
announcementPanel.Visible = false
announcementPanel.Parent = panel

local announcementCorner = Instance.new("UICorner")
announcementCorner.CornerRadius = UDim.new(0, 10)
announcementCorner.Parent = announcementPanel

local announcementHeader = Instance.new("TextLabel")
announcementHeader.Position = UDim2.new(0, 12, 0, 10)
announcementHeader.Size = UDim2.new(1, -24, 0, 18)
announcementHeader.BackgroundTransparency = 1
announcementHeader.Text = "EMBED BUILDER // ANNOUNCEMENT CHANNEL"
announcementHeader.TextColor3 = Color3.fromRGB(214, 165, 255)
announcementHeader.Font = Enum.Font.Code
announcementHeader.TextSize = 10
announcementHeader.TextXAlignment = Enum.TextXAlignment.Left
announcementHeader.Parent = announcementPanel

local announcementTitle = Instance.new("TextBox")
announcementTitle.Name = "AnnouncementTitle"
announcementTitle.Position = UDim2.new(0, 10, 0, 34)
announcementTitle.Size = UDim2.new(1, -20, 0, 30)
announcementTitle.BackgroundColor3 = Color3.fromRGB(54, 32, 78)
announcementTitle.BorderSizePixel = 0
announcementTitle.ClearTextOnFocus = false
announcementTitle.PlaceholderText = "ANNOUNCEMENT"
announcementTitle.PlaceholderColor3 = Color3.fromRGB(160, 133, 185)
announcementTitle.Text = ""
announcementTitle.TextColor3 = Color3.fromRGB(245, 235, 255)
announcementTitle.Font = Enum.Font.GothamBold
announcementTitle.TextSize = 12
announcementTitle.TextXAlignment = Enum.TextXAlignment.Left
announcementTitle.Parent = announcementPanel

local announcementTitleCorner = Instance.new("UICorner")
announcementTitleCorner.CornerRadius = UDim.new(0, 6)
announcementTitleCorner.Parent = announcementTitle

local announcementTitlePadding = Instance.new("UIPadding")
announcementTitlePadding.PaddingLeft = UDim.new(0, 8)
announcementTitlePadding.PaddingRight = UDim.new(0, 8)
announcementTitlePadding.Parent = announcementTitle

local announcementBody = Instance.new("TextBox")
announcementBody.Name = "AnnouncementBody"
announcementBody.Position = UDim2.new(0, 10, 0, 68)
announcementBody.Size = UDim2.new(1, -20, 0, 58)
announcementBody.BackgroundColor3 = Color3.fromRGB(54, 32, 78)
announcementBody.BorderSizePixel = 0
announcementBody.ClearTextOnFocus = false
announcementBody.MultiLine = true
announcementBody.PlaceholderText = "Escribe aquí el mensaje del embed..."
announcementBody.PlaceholderColor3 = Color3.fromRGB(160, 133, 185)
announcementBody.Text = ""
announcementBody.TextColor3 = Color3.fromRGB(245, 235, 255)
announcementBody.Font = Enum.Font.Gotham
announcementBody.TextSize = 11
announcementBody.TextWrapped = true
announcementBody.TextXAlignment = Enum.TextXAlignment.Left
announcementBody.TextYAlignment = Enum.TextYAlignment.Top
announcementBody.Parent = announcementPanel

local announcementBodyCorner = Instance.new("UICorner")
announcementBodyCorner.CornerRadius = UDim.new(0, 6)
announcementBodyCorner.Parent = announcementBody

local announcementBodyPadding = Instance.new("UIPadding")
announcementBodyPadding.PaddingTop = UDim.new(0, 6)
announcementBodyPadding.PaddingLeft = UDim.new(0, 8)
announcementBodyPadding.PaddingRight = UDim.new(0, 8)
announcementBodyPadding.Parent = announcementBody

local announcementHint = Instance.new("TextLabel")
announcementHint.Position = UDim2.new(0, 12, 0, 132)
announcementHint.Size = UDim2.new(1, -24, 0, 18)
announcementHint.BackgroundTransparency = 1
announcementHint.Text = "EMBED  //  PURPLE CHANNEL  //  READY TO DISPATCH"
announcementHint.TextColor3 = Color3.fromRGB(151, 255, 204)
announcementHint.Font = Enum.Font.Code
announcementHint.TextSize = 8
announcementHint.TextXAlignment = Enum.TextXAlignment.Left
announcementHint.Parent = announcementPanel

local sendAnnouncementButton = Instance.new("TextButton")
sendAnnouncementButton.Name = "SendAnnouncement"
sendAnnouncementButton.Position = UDim2.new(0, 10, 0, 153)
sendAnnouncementButton.Size = UDim2.new(1, -20, 0, 28)
sendAnnouncementButton.BackgroundColor3 = Color3.fromRGB(122, 57, 177)
sendAnnouncementButton.BorderSizePixel = 0
sendAnnouncementButton.Text = "  DISPATCH EMBED  //  WEBHOOK"
sendAnnouncementButton.TextColor3 = Color3.fromRGB(255, 240, 255)
sendAnnouncementButton.Font = Enum.Font.GothamBold
sendAnnouncementButton.TextSize = 11
sendAnnouncementButton.AutoButtonColor = false
sendAnnouncementButton.Parent = announcementPanel

local sendAnnouncementCorner = Instance.new("UICorner")
sendAnnouncementCorner.CornerRadius = UDim.new(0, 7)
sendAnnouncementCorner.Parent = sendAnnouncementButton

local promotionPanel = Instance.new("Frame")
promotionPanel.Name = "PromotionBuilder"
promotionPanel.Position = UDim2.new(0, 12, 0, 100)
promotionPanel.Size = UDim2.new(1, -24, 1, -150)
promotionPanel.BackgroundColor3 = Color3.fromRGB(29, 19, 45)
promotionPanel.BackgroundTransparency = 0.05
promotionPanel.BorderSizePixel = 0
promotionPanel.Visible = false
promotionPanel.Parent = panel

local promotionCorner = Instance.new("UICorner")
promotionCorner.CornerRadius = UDim.new(0, 10)
promotionCorner.Parent = promotionPanel

local promotionHeader = Instance.new("TextLabel")
promotionHeader.Position = UDim2.new(0, 12, 0, 8)
promotionHeader.Size = UDim2.new(1, -24, 0, 18)
promotionHeader.BackgroundTransparency = 1
promotionHeader.Text = "PROMOTIONS // LINK BUTTON"
promotionHeader.TextColor3 = Color3.fromRGB(214, 165, 255)
promotionHeader.Font = Enum.Font.Code
promotionHeader.TextSize = 10
promotionHeader.TextXAlignment = Enum.TextXAlignment.Left
promotionHeader.Parent = promotionPanel

local promotionUrlBox = Instance.new("TextBox")
promotionUrlBox.Name = "PromotionUrl"
promotionUrlBox.Position = UDim2.new(0, 10, 0, 30)
promotionUrlBox.Size = UDim2.new(1, -20, 0, 27)
promotionUrlBox.BackgroundColor3 = Color3.fromRGB(54, 32, 78)
promotionUrlBox.BorderSizePixel = 0
promotionUrlBox.ClearTextOnFocus = false
promotionUrlBox.ClipsDescendants = true
promotionUrlBox.PlaceholderText = "https://www.roblox.com/share/g/..."
promotionUrlBox.PlaceholderColor3 = Color3.fromRGB(160, 133, 185)
promotionUrlBox.Text = ""
promotionUrlBox.TextColor3 = Color3.fromRGB(245, 235, 255)
promotionUrlBox.Font = Enum.Font.Code
promotionUrlBox.TextSize = 10
promotionUrlBox.TextXAlignment = Enum.TextXAlignment.Left
promotionUrlBox.Parent = promotionPanel

local promotionUrlCorner = Instance.new("UICorner")
promotionUrlCorner.CornerRadius = UDim.new(0, 6)
promotionUrlCorner.Parent = promotionUrlBox

local promotionUrlPadding = Instance.new("UIPadding")
promotionUrlPadding.PaddingLeft = UDim.new(0, 8)
promotionUrlPadding.PaddingRight = UDim.new(0, 8)
promotionUrlPadding.Parent = promotionUrlBox

local promotionLabelBox = Instance.new("TextBox")
promotionLabelBox.Name = "PromotionButtonLabel"
promotionLabelBox.Position = UDim2.new(0, 10, 0, 62)
promotionLabelBox.Size = UDim2.new(1, -20, 0, 27)
promotionLabelBox.BackgroundColor3 = Color3.fromRGB(54, 32, 78)
promotionLabelBox.BorderSizePixel = 0
promotionLabelBox.ClearTextOnFocus = false
promotionLabelBox.PlaceholderText = "Nombre del botón (ej. JOIN PROMO)"
promotionLabelBox.PlaceholderColor3 = Color3.fromRGB(160, 133, 185)
promotionLabelBox.Text = ""
promotionLabelBox.TextColor3 = Color3.fromRGB(245, 235, 255)
promotionLabelBox.Font = Enum.Font.GothamBold
promotionLabelBox.TextSize = 10
promotionLabelBox.TextXAlignment = Enum.TextXAlignment.Left
promotionLabelBox.Parent = promotionPanel

local promotionLabelCorner = Instance.new("UICorner")
promotionLabelCorner.CornerRadius = UDim.new(0, 6)
promotionLabelCorner.Parent = promotionLabelBox

local promotionLabelPadding = Instance.new("UIPadding")
promotionLabelPadding.PaddingLeft = UDim.new(0, 8)
promotionLabelPadding.PaddingRight = UDim.new(0, 8)
promotionLabelPadding.Parent = promotionLabelBox

local promotionUsesBox = Instance.new("TextBox")
promotionUsesBox.Name = "PromotionUses"
promotionUsesBox.Position = UDim2.new(0, 10, 0, 126)
promotionUsesBox.Size = UDim2.new(0.5, -15, 0, 27)
promotionUsesBox.BackgroundColor3 = Color3.fromRGB(54, 32, 78)
promotionUsesBox.BorderSizePixel = 0
promotionUsesBox.ClearTextOnFocus = false
promotionUsesBox.PlaceholderText = "Veces (0 = ilimitado)"
promotionUsesBox.PlaceholderColor3 = Color3.fromRGB(160, 133, 185)
promotionUsesBox.Text = ""
promotionUsesBox.TextColor3 = Color3.fromRGB(245, 235, 255)
promotionUsesBox.Font = Enum.Font.Code
promotionUsesBox.TextSize = 9
promotionUsesBox.TextXAlignment = Enum.TextXAlignment.Left
promotionUsesBox.Parent = promotionPanel

local promotionUsesCorner = Instance.new("UICorner")
promotionUsesCorner.CornerRadius = UDim.new(0, 6)
promotionUsesCorner.Parent = promotionUsesBox

local promotionUsesPadding = Instance.new("UIPadding")
promotionUsesPadding.PaddingLeft = UDim.new(0, 8)
promotionUsesPadding.Parent = promotionUsesBox

local promotionEmojiBox = Instance.new("TextBox")
promotionEmojiBox.Name = "PromotionEmoji"
promotionEmojiBox.Position = UDim2.new(0, 10, 0, 94)
promotionEmojiBox.Size = UDim2.new(1, -20, 0, 27)
promotionEmojiBox.BackgroundColor3 = Color3.fromRGB(54, 32, 78)
promotionEmojiBox.BorderSizePixel = 0
promotionEmojiBox.ClearTextOnFocus = false
promotionEmojiBox.ClipsDescendants = true
promotionEmojiBox.PlaceholderText = "Emoji opcional (🔥 o <:Nombre:id>)"
promotionEmojiBox.PlaceholderColor3 = Color3.fromRGB(160, 133, 185)
promotionEmojiBox.Text = ""
promotionEmojiBox.TextColor3 = Color3.fromRGB(245, 235, 255)
promotionEmojiBox.Font = Enum.Font.Code
promotionEmojiBox.TextSize = 10
promotionEmojiBox.TextXAlignment = Enum.TextXAlignment.Left
promotionEmojiBox.Parent = promotionPanel

local promotionEmojiCorner = Instance.new("UICorner")
promotionEmojiCorner.CornerRadius = UDim.new(0, 6)
promotionEmojiCorner.Parent = promotionEmojiBox

local promotionEmojiPadding = Instance.new("UIPadding")
promotionEmojiPadding.PaddingLeft = UDim.new(0, 8)
promotionEmojiPadding.PaddingRight = UDim.new(0, 8)
promotionEmojiPadding.Parent = promotionEmojiBox

local promotionRarityButton = Instance.new("TextButton")
promotionRarityButton.Name = "PromotionRarity"
promotionRarityButton.Position = UDim2.new(0.5, 5, 0, 126)
promotionRarityButton.Size = UDim2.new(0.5, -15, 0, 27)
promotionRarityButton.BackgroundColor3 = Color3.fromRGB(54, 32, 78)
promotionRarityButton.BorderSizePixel = 0
promotionRarityButton.Text = "RAREZA: TODAS"
promotionRarityButton.TextColor3 = Color3.fromRGB(245, 235, 255)
promotionRarityButton.Font = Enum.Font.Code
promotionRarityButton.TextSize = 9
promotionRarityButton.TextXAlignment = Enum.TextXAlignment.Left
promotionRarityButton.AutoButtonColor = false
promotionRarityButton.Parent = promotionPanel

local promotionRarityPadding = Instance.new("UIPadding")
promotionRarityPadding.PaddingLeft = UDim.new(0, 8)
promotionRarityPadding.Parent = promotionRarityButton

local promotionRarityCorner = Instance.new("UICorner")
promotionRarityCorner.CornerRadius = UDim.new(0, 6)
promotionRarityCorner.Parent = promotionRarityButton

local promotionIntervalBox = Instance.new("TextBox")
promotionIntervalBox.Name = "PromotionInterval"
promotionIntervalBox.Position = UDim2.new(0, 10, 0, 158)
promotionIntervalBox.Size = UDim2.new(0.5, -15, 0, 27)
promotionIntervalBox.BackgroundColor3 = Color3.fromRGB(54, 32, 78)
promotionIntervalBox.BorderSizePixel = 0
promotionIntervalBox.ClearTextOnFocus = false
promotionIntervalBox.PlaceholderText = "Minutos (0 = cada huevo)"
promotionIntervalBox.PlaceholderColor3 = Color3.fromRGB(160, 133, 185)
promotionIntervalBox.Text = ""
promotionIntervalBox.TextColor3 = Color3.fromRGB(245, 235, 255)
promotionIntervalBox.Font = Enum.Font.Code
promotionIntervalBox.TextSize = 9
promotionIntervalBox.TextXAlignment = Enum.TextXAlignment.Left
promotionIntervalBox.Parent = promotionPanel

local promotionIntervalCorner = Instance.new("UICorner")
promotionIntervalCorner.CornerRadius = UDim.new(0, 6)
promotionIntervalCorner.Parent = promotionIntervalBox

local promotionIntervalPadding = Instance.new("UIPadding")
promotionIntervalPadding.PaddingLeft = UDim.new(0, 8)
promotionIntervalPadding.Parent = promotionIntervalBox

local promotionHint = Instance.new("TextLabel")
promotionHint.Position = UDim2.new(0, 12, 0, 190)
promotionHint.Size = UDim2.new(1, -24, 0, 18)
promotionHint.BackgroundTransparency = 1
promotionHint.Text = "EMOJI // RARITY LIMIT // CONFIG SAVED"
promotionHint.TextColor3 = Color3.fromRGB(151, 255, 204)
promotionHint.Font = Enum.Font.Code
promotionHint.TextSize = 8
promotionHint.TextXAlignment = Enum.TextXAlignment.Left
promotionHint.Parent = promotionPanel

local savePromotionButton = Instance.new("TextButton")
savePromotionButton.Name = "SavePromotion"
savePromotionButton.Position = UDim2.new(0, 10, 0, 215)
savePromotionButton.Size = UDim2.new(1, -20, 0, 28)
savePromotionButton.BackgroundColor3 = Color3.fromRGB(122, 57, 177)
savePromotionButton.BorderSizePixel = 0
savePromotionButton.Text = "  SAVE PROMOTION  //  READY"
savePromotionButton.TextColor3 = Color3.fromRGB(255, 240, 255)
savePromotionButton.Font = Enum.Font.GothamBold
savePromotionButton.TextSize = 10
savePromotionButton.AutoButtonColor = false
savePromotionButton.Parent = promotionPanel

local savePromotionCorner = Instance.new("UICorner")
savePromotionCorner.CornerRadius = UDim.new(0, 7)
savePromotionCorner.Parent = savePromotionButton

configUi.panel = Instance.new("Frame")
configUi.panel.Name = "ConfigPanel"
configUi.panel.Position = UDim2.new(0, 12, 0, 100)
configUi.panel.Size = UDim2.new(1, -24, 1, -150)
configUi.panel.BackgroundColor3 = Color3.fromRGB(9, 15, 32)
configUi.panel.BackgroundTransparency = 0
configUi.panel.BorderSizePixel = 0
configUi.panel.Visible = false
configUi.panel.Parent = panel

configUi.panelCorner = Instance.new("UICorner")
configUi.panelCorner.CornerRadius = UDim.new(0, 12)
configUi.panelCorner.Parent = configUi.panel

configUi.header = Instance.new("TextLabel")
configUi.header.Position = UDim2.new(0, 14, 0, 10)
configUi.header.Size = UDim2.new(1, -28, 0, 18)
configUi.header.BackgroundTransparency = 1
configUi.header.Text = "PET REGISTRY  //  CONFIGURATION"
configUi.header.TextColor3 = Color3.fromRGB(240, 225, 255)
configUi.header.Font = Enum.Font.GothamBold
configUi.header.TextSize = 12
configUi.header.TextXAlignment = Enum.TextXAlignment.Left
configUi.header.Parent = configUi.panel

configUi.help = Instance.new("TextLabel")
configUi.help.Position = UDim2.new(0, 14, 0, 30)
configUi.help.Size = UDim2.new(1, -28, 0, 14)
configUi.help.BackgroundTransparency = 1
configUi.help.Text = "CURRENT PETS  //  CLICK TO EDIT  //  SAVED LOCALLY"
configUi.help.TextColor3 = Color3.fromRGB(151, 255, 204)
configUi.help.Font = Enum.Font.Code
configUi.help.TextSize = 8
configUi.help.TextXAlignment = Enum.TextXAlignment.Left
configUi.help.Parent = configUi.panel

configUi.list = Instance.new("ScrollingFrame")
configUi.list.Name = "PetRegistry"
configUi.list.Position = UDim2.new(0, 10, 0, 49)
configUi.list.Size = UDim2.new(1, -20, 0, 72)
configUi.list.BackgroundColor3 = Color3.fromRGB(5, 9, 20)
configUi.list.BorderSizePixel = 0
configUi.list.CanvasSize = UDim2.new(0, 0, 0, 0)
configUi.list.ScrollBarThickness = 3
configUi.list.ScrollBarImageColor3 = Color3.fromRGB(181, 116, 255)
configUi.list.ScrollingDirection = Enum.ScrollingDirection.Y
configUi.list.Parent = configUi.panel

configUi.listCorner = Instance.new("UICorner")
configUi.listCorner.CornerRadius = UDim.new(0, 8)
configUi.listCorner.Parent = configUi.list

configUi.listBody = Instance.new("Frame")
configUi.listBody.Name = "RegistryRows"
configUi.listBody.Size = UDim2.new(1, -8, 0, 0)
configUi.listBody.BackgroundTransparency = 1
configUi.listBody.Parent = configUi.list

configUi.listLayout = Instance.new("UIListLayout")
configUi.listLayout.Padding = UDim.new(0, 3)
configUi.listLayout.SortOrder = Enum.SortOrder.LayoutOrder
configUi.listLayout.Parent = configUi.listBody

configUi.nameBox = Instance.new("TextBox")
configUi.nameBox.Name = "PetName"
configUi.nameBox.Position = UDim2.new(0, 10, 0, 128)
configUi.nameBox.Size = UDim2.new(0.5, -15, 0, 27)
configUi.nameBox.BackgroundColor3 = Color3.fromRGB(17, 24, 48)
configUi.nameBox.BorderSizePixel = 0
configUi.nameBox.ClearTextOnFocus = false
configUi.nameBox.PlaceholderText = "PET NAME  //  exact game text"
configUi.nameBox.PlaceholderColor3 = Color3.fromRGB(144, 121, 170)
configUi.nameBox.Text = ""
configUi.nameBox.TextColor3 = Color3.fromRGB(245, 235, 255)
configUi.nameBox.Font = Enum.Font.Code
configUi.nameBox.TextSize = 9
configUi.nameBox.TextXAlignment = Enum.TextXAlignment.Left
configUi.nameBox.Parent = configUi.panel

configUi.roleBox = Instance.new("TextBox")
configUi.roleBox.Name = "PetRoleId"
configUi.roleBox.Position = UDim2.new(0.5, 5, 0, 128)
configUi.roleBox.Size = UDim2.new(0.5, -15, 0, 27)
configUi.roleBox.BackgroundColor3 = Color3.fromRGB(17, 24, 48)
configUi.roleBox.BorderSizePixel = 0
configUi.roleBox.ClearTextOnFocus = false
configUi.roleBox.PlaceholderText = "ROLE ID  //  123456789 or <@&123456789>"
configUi.roleBox.PlaceholderColor3 = Color3.fromRGB(144, 121, 170)
configUi.roleBox.Text = ""
configUi.roleBox.TextColor3 = Color3.fromRGB(245, 235, 255)
configUi.roleBox.Font = Enum.Font.Code
configUi.roleBox.TextSize = 9
configUi.roleBox.TextXAlignment = Enum.TextXAlignment.Left
configUi.roleBox.Parent = configUi.panel

configUi.emojiBox = Instance.new("TextBox")
configUi.emojiBox.Name = "PetEmoji"
configUi.emojiBox.Position = UDim2.new(0, 10, 0, 159)
configUi.emojiBox.Size = UDim2.new(0.5, -15, 0, 27)
configUi.emojiBox.BackgroundColor3 = Color3.fromRGB(17, 24, 48)
configUi.emojiBox.BorderSizePixel = 0
configUi.emojiBox.ClearTextOnFocus = false
configUi.emojiBox.PlaceholderText = "EMOJI  //  <:Pet:id>"
configUi.emojiBox.PlaceholderColor3 = Color3.fromRGB(144, 121, 170)
configUi.emojiBox.Text = ""
configUi.emojiBox.TextColor3 = Color3.fromRGB(245, 235, 255)
configUi.emojiBox.Font = Enum.Font.Code
configUi.emojiBox.TextSize = 9
configUi.emojiBox.TextXAlignment = Enum.TextXAlignment.Left
configUi.emojiBox.Parent = configUi.panel

configUi.rarityButton = Instance.new("TextButton")
configUi.rarityButton.Name = "PetRarity"
configUi.rarityButton.Position = UDim2.new(0.5, 5, 0, 159)
configUi.rarityButton.Size = UDim2.new(0.5, -15, 0, 27)
configUi.rarityButton.BackgroundColor3 = Color3.fromRGB(17, 24, 48)
configUi.rarityButton.BorderSizePixel = 0
configUi.rarityButton.Text = "RAREZA: SECRET  >"
configUi.rarityButton.TextColor3 = Color3.fromRGB(245, 235, 255)
configUi.rarityButton.Font = Enum.Font.Code
configUi.rarityButton.TextSize = 9
configUi.rarityButton.TextXAlignment = Enum.TextXAlignment.Left
configUi.rarityButton.AutoButtonColor = false
configUi.rarityButton.Parent = configUi.panel

configUi.rarityPadding = Instance.new("UIPadding")
configUi.rarityPadding.PaddingLeft = UDim.new(0, 30)
configUi.rarityPadding.Parent = configUi.rarityButton

configUi.saveButton = Instance.new("TextButton")
configUi.saveButton.Name = "SavePetConfig"
configUi.saveButton.Position = UDim2.new(0, 10, 0, 190)
configUi.saveButton.Size = UDim2.new(0.5, -15, 0, 28)
configUi.saveButton.BackgroundColor3 = Color3.fromRGB(0, 132, 255)
configUi.saveButton.BorderSizePixel = 0
configUi.saveButton.Text = "  SAVE  //  APPLY"
configUi.saveButton.TextColor3 = Color3.fromRGB(255, 245, 255)
configUi.saveButton.Font = Enum.Font.GothamBold
configUi.saveButton.TextSize = 9
configUi.saveButton.AutoButtonColor = false
configUi.saveButton.Parent = configUi.panel

configUi.newButton = Instance.new("TextButton")
configUi.newButton.Name = "NewPetConfig"
configUi.newButton.Position = UDim2.new(0.5, 5, 0, 190)
configUi.newButton.Size = UDim2.new(0.5, -15, 0, 28)
configUi.newButton.BackgroundColor3 = Color3.fromRGB(28, 36, 68)
configUi.newButton.BorderSizePixel = 0
configUi.newButton.Text = "  NEW  //  CLEAR"
configUi.newButton.TextColor3 = Color3.fromRGB(245, 235, 255)
configUi.newButton.Font = Enum.Font.GothamBold
configUi.newButton.TextSize = 9
configUi.newButton.AutoButtonColor = false
configUi.newButton.Parent = configUi.panel

configUi.deleteButton = Instance.new("TextButton")
configUi.deleteButton.Name = "DeletePetConfig"
configUi.deleteButton.Position = UDim2.new(0, 10, 0, 222)
configUi.deleteButton.Size = UDim2.new(1, -20, 0, 24)
configUi.deleteButton.BackgroundColor3 = Color3.fromRGB(92, 20, 45)
configUi.deleteButton.BorderSizePixel = 0
configUi.deleteButton.Text = "RESET SELECTED OVERRIDE"
configUi.deleteButton.TextColor3 = Color3.fromRGB(255, 181, 205)
configUi.deleteButton.Font = Enum.Font.GothamBold
configUi.deleteButton.TextSize = 8
configUi.deleteButton.AutoButtonColor = false
configUi.deleteButton.Parent = configUi.panel

configUi.webhookPanel = Instance.new("Frame")
configUi.webhookPanel.Name = "WebhookPanel"
configUi.webhookPanel.Position = UDim2.new(0, 12, 0, 100)
configUi.webhookPanel.Size = UDim2.new(1, -24, 1, -150)
configUi.webhookPanel.BackgroundColor3 = Color3.fromRGB(9, 15, 32)
configUi.webhookPanel.BorderSizePixel = 0
configUi.webhookPanel.Visible = false
configUi.webhookPanel.Parent = panel

configUi.webhookPanelCorner = Instance.new("UICorner")
configUi.webhookPanelCorner.CornerRadius = UDim.new(0, 12)
configUi.webhookPanelCorner.Parent = configUi.webhookPanel

configUi.webhookHeader = Instance.new("TextLabel")
configUi.webhookHeader.Position = UDim2.new(0, 36, 0, 12)
configUi.webhookHeader.Size = UDim2.new(1, -50, 0, 20)
configUi.webhookHeader.BackgroundTransparency = 1
configUi.webhookHeader.Text = "WEBHOOK  //  DELIVERY ROUTING"
configUi.webhookHeader.TextColor3 = Color3.fromRGB(240, 225, 255)
configUi.webhookHeader.Font = Enum.Font.GothamBold
configUi.webhookHeader.TextSize = 12
configUi.webhookHeader.TextXAlignment = Enum.TextXAlignment.Left
configUi.webhookHeader.Parent = configUi.webhookPanel
createCanvasIcon(configUi.webhookPanel, "endpoint", Color3.fromRGB(0, 198, 255), UDim2.new(0, 18, 0, 18), UDim2.new(0, 20, 0, 22), "WebhookHeaderIcon")

configUi.webhookHelp = Instance.new("TextLabel")
configUi.webhookHelp.Position = UDim2.new(0, 14, 0, 36)
configUi.webhookHelp.Size = UDim2.new(1, -28, 0, 28)
configUi.webhookHelp.BackgroundTransparency = 1
configUi.webhookHelp.Text = "LOCAL ONLY  //  SAVED ON DEVICE  //  NEVER UPLOAD WEBHOOKS"
configUi.webhookHelp.TextColor3 = Color3.fromRGB(255, 193, 89)
configUi.webhookHelp.Font = Enum.Font.Code
configUi.webhookHelp.TextSize = 8
configUi.webhookHelp.TextWrapped = true
configUi.webhookHelp.TextXAlignment = Enum.TextXAlignment.Left
configUi.webhookHelp.Parent = configUi.webhookPanel

local function createWebhookInput(name, yOffset, placeholder, iconKind, iconColor)
	local shell = Instance.new("Frame")
	shell.Name = name .. "Shell"
	shell.Position = UDim2.new(0, 10, 0, yOffset)
	shell.Size = UDim2.new(1, -20, 0, 30)
	shell.BackgroundColor3 = Color3.fromRGB(17, 24, 48)
	shell.BorderSizePixel = 0
	shell.ClipsDescendants = true
	shell.Parent = configUi.webhookPanel

	local shellCorner = Instance.new("UICorner")
	shellCorner.CornerRadius = UDim.new(0, 6)
	shellCorner.Parent = shell

	local box = Instance.new("TextBox")
	box.Name = name
	box.Position = UDim2.new(0, 44, 0, 0)
	box.Size = UDim2.new(1, -52, 1, 0)
	box.BackgroundTransparency = 1
	box.BorderSizePixel = 0
	box.ClipsDescendants = true
	box.ClearTextOnFocus = false
	box.PlaceholderText = placeholder
	box.PlaceholderColor3 = Color3.fromRGB(144, 121, 170)
	box.Text = ""
	box.TextColor3 = Color3.fromRGB(245, 235, 255)
	box.Font = Enum.Font.Code
	box.TextSize = 8
	box.TextXAlignment = Enum.TextXAlignment.Left
	box.ZIndex = 1
	box.Parent = shell

	createCanvasIcon(
		shell,
		iconKind,
		iconColor,
		UDim2.new(0, 14, 0, 14),
		UDim2.new(0, 14, 0.5, 0),
		"WebhookInputIcon"
	)

	return box
end

configUi.mainWebhookBox = createWebhookInput(
	"MainWebhook",
	76,
	"MAIN WEBHOOK  //  https://discord.com/api/webhooks/...",
	"endpoint",
	Color3.fromRGB(0, 174, 255)
)

configUi.lastSeenWebhookBox = createWebhookInput(
	"LastSeenWebhook",
	121,
	"LAST SEEN WEBHOOK  //  https://discord.com/api/webhooks/...",
	"clock",
	Color3.fromRGB(171, 92, 255)
)

configUi.saveWebhookButton = Instance.new("TextButton")
configUi.saveWebhookButton.Position = UDim2.new(0, 10, 0, 166)
configUi.saveWebhookButton.Size = UDim2.new(0.5, -15, 0, 29)
configUi.saveWebhookButton.BackgroundColor3 = Color3.fromRGB(0, 132, 255)
configUi.saveWebhookButton.BorderSizePixel = 0
configUi.saveWebhookButton.Text = "  SAVE  //  WEBHOOKS"
configUi.saveWebhookButton.TextColor3 = Color3.fromRGB(255, 245, 255)
configUi.saveWebhookButton.Font = Enum.Font.GothamBold
configUi.saveWebhookButton.TextSize = 9
configUi.saveWebhookButton.AutoButtonColor = false
configUi.saveWebhookButton.Parent = configUi.webhookPanel

configUi.clearWebhookButton = Instance.new("TextButton")
configUi.clearWebhookButton.Position = UDim2.new(0.5, 5, 0, 166)
configUi.clearWebhookButton.Size = UDim2.new(0.5, -15, 0, 29)
configUi.clearWebhookButton.BackgroundColor3 = Color3.fromRGB(92, 20, 45)
configUi.clearWebhookButton.BorderSizePixel = 0
configUi.clearWebhookButton.Text = "  CLEAR  //  DISABLE"
configUi.clearWebhookButton.TextColor3 = Color3.fromRGB(255, 181, 205)
configUi.clearWebhookButton.Font = Enum.Font.GothamBold
configUi.clearWebhookButton.TextSize = 9
configUi.clearWebhookButton.AutoButtonColor = false
configUi.clearWebhookButton.Parent = configUi.webhookPanel

configUi.webhookStatus = Instance.new("TextLabel")
configUi.webhookStatus.Position = UDim2.new(0, 14, 0, 210)
configUi.webhookStatus.Size = UDim2.new(1, -28, 0, 38)
configUi.webhookStatus.BackgroundTransparency = 1
configUi.webhookStatus.Text = "STATUS // NOT CONFIGURED"
configUi.webhookStatus.TextColor3 = Color3.fromRGB(151, 255, 204)
configUi.webhookStatus.Font = Enum.Font.Code
configUi.webhookStatus.TextSize = 9
configUi.webhookStatus.TextWrapped = true
configUi.webhookStatus.TextXAlignment = Enum.TextXAlignment.Left
configUi.webhookStatus.Parent = configUi.webhookPanel

local consolePanel = Instance.new("Frame")
consolePanel.Name = "ConsolePanel"
consolePanel.Position = UDim2.new(0, 12, 0, 100)
consolePanel.Size = UDim2.new(1, -24, 1, -150)
consolePanel.BackgroundColor3 = Color3.fromRGB(20, 17, 31)
consolePanel.BackgroundTransparency = 0.02
consolePanel.BorderSizePixel = 0
consolePanel.Visible = false
consolePanel.Parent = panel

local consolePanelCorner = Instance.new("UICorner")
consolePanelCorner.CornerRadius = UDim.new(0, 10)
consolePanelCorner.Parent = consolePanel

local consoleHeader = Instance.new("TextLabel")
consoleHeader.Position = UDim2.new(0, 12, 0, 8)
consoleHeader.Size = UDim2.new(1, -116, 0, 18)
consoleHeader.BackgroundTransparency = 1
consoleHeader.Text = "CONSOLE // GAME + SCRIPT STREAM"
consoleHeader.TextColor3 = Color3.fromRGB(255, 111, 151)
consoleHeader.Font = Enum.Font.Code
consoleHeader.TextSize = 10
consoleHeader.TextXAlignment = Enum.TextXAlignment.Left
consoleHeader.Parent = consolePanel

local copyConsoleButton = Instance.new("TextButton")
copyConsoleButton.Name = "CopyConsole"
copyConsoleButton.AnchorPoint = Vector2.new(1, 0)
copyConsoleButton.Position = UDim2.new(1, -10, 0, 7)
copyConsoleButton.Size = UDim2.new(0, 92, 0, 22)
copyConsoleButton.BackgroundColor3 = Color3.fromRGB(74, 42, 98)
copyConsoleButton.BorderSizePixel = 0
copyConsoleButton.Text = "  COPY ALL"
copyConsoleButton.TextColor3 = Color3.fromRGB(238, 201, 255)
copyConsoleButton.Font = Enum.Font.GothamBold
copyConsoleButton.TextSize = 9
copyConsoleButton.AutoButtonColor = false
copyConsoleButton.Parent = consolePanel

local copyConsoleCorner = Instance.new("UICorner")
copyConsoleCorner.CornerRadius = UDim.new(0, 5)
copyConsoleCorner.Parent = copyConsoleButton

local consoleScroll = Instance.new("ScrollingFrame")
consoleScroll.Name = "ConsoleOutput"
consoleScroll.Position = UDim2.new(0, 10, 0, 36)
consoleScroll.Size = UDim2.new(1, -20, 1, -46)
consoleScroll.BackgroundColor3 = Color3.fromRGB(10, 9, 16)
consoleScroll.BackgroundTransparency = 0.08
consoleScroll.BorderSizePixel = 0
consoleScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
consoleScroll.AutomaticCanvasSize = Enum.AutomaticSize.None
consoleScroll.ScrollBarThickness = 4
consoleScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 92, 133)
consoleScroll.ScrollingDirection = Enum.ScrollingDirection.Y
consoleScroll.ClipsDescendants = true
consoleScroll.Parent = consolePanel

local consoleScrollCorner = Instance.new("UICorner")
consoleScrollCorner.CornerRadius = UDim.new(0, 7)
consoleScrollCorner.Parent = consoleScroll

local consoleBody = Instance.new("TextBox")
consoleBody.Name = "ConsoleText"
consoleBody.Position = UDim2.new(0, 8, 0, 8)
consoleBody.Size = UDim2.new(1, -16, 0, 0)
consoleBody.AutomaticSize = Enum.AutomaticSize.Y
consoleBody.BackgroundTransparency = 1
consoleBody.ClearTextOnFocus = false
consoleBody.MultiLine = true
consoleBody.TextEditable = false
consoleBody.Text = "AURA CONSOLE // READY\n"
consoleBody.TextColor3 = Color3.fromRGB(221, 211, 232)
consoleBody.Font = Enum.Font.Code
consoleBody.TextSize = 10
consoleBody.TextWrapped = true
consoleBody.TextXAlignment = Enum.TextXAlignment.Left
consoleBody.TextYAlignment = Enum.TextYAlignment.Top
consoleBody.Parent = consoleScroll

local consoleJumpButton = Instance.new("TextButton")
consoleJumpButton.Name = "ConsoleJumpToLatest"
consoleJumpButton.AnchorPoint = Vector2.new(1, 1)
consoleJumpButton.Position = UDim2.new(1, -10, 1, -10)
consoleJumpButton.Size = UDim2.new(0, 32, 0, 32)
consoleJumpButton.BackgroundColor3 = Color3.fromRGB(162, 54, 99)
consoleJumpButton.BackgroundTransparency = 0.04
consoleJumpButton.BorderSizePixel = 0
consoleJumpButton.Text = "↓"
consoleJumpButton.TextColor3 = Color3.fromRGB(255, 240, 255)
consoleJumpButton.Font = Enum.Font.GothamBold
consoleJumpButton.TextSize = 20
consoleJumpButton.AutoButtonColor = false
consoleJumpButton.ZIndex = 10
consoleJumpButton.Visible = false
consoleJumpButton.Parent = consolePanel

local consoleJumpCorner = Instance.new("UICorner")
consoleJumpCorner.CornerRadius = UDim.new(1, 0)
consoleJumpCorner.Parent = consoleJumpButton

local function updateConsoleJumpVisibility()
	local maximum = math.max(0, consoleScroll.CanvasSize.Y.Offset - consoleScroll.AbsoluteWindowSize.Y)
	local current = consoleScroll.CanvasPosition.Y
	consoleJumpButton.Visible = consolePanel.Visible and maximum > 120 and current < maximum - 80
end

consoleScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(updateConsoleJumpVisibility)
consoleScroll:GetPropertyChangedSignal("CanvasSize"):Connect(updateConsoleJumpVisibility)
updateConsoleJumpVisibility()

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "SystemStatus"
statusLabel.Position = UDim2.new(0, 12, 1, -50)
statusLabel.Size = UDim2.new(1, -24, 0, 38)
statusLabel.BackgroundColor3 = Color3.fromRGB(15, 23, 48)
statusLabel.BackgroundTransparency = 0.04
statusLabel.TextColor3 = Color3.fromRGB(99, 255, 154)
statusLabel.Font = Enum.Font.Code
statusLabel.TextSize = 13
statusLabel.RichText = true
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.TextYAlignment = Enum.TextYAlignment.Center
statusLabel.Text = '<font color="#D6A5FF">SYSTEM</font><font color="#FF4D67">:</font> <font color="#63FF9A">Ready</font>'
statusLabel.Parent = panel

local statusPadding = Instance.new("UIPadding")
statusPadding.PaddingLeft = UDim.new(0, 12)
statusPadding.Parent = statusLabel

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = statusLabel

local toggleButton = Instance.new("TextButton")
toggleButton.Name = "ToggleButton"
toggleButton.AnchorPoint = Vector2.new(0.5, 0.5)
toggleButton.Position = UDim2.new(1, -48, 0.5, 0)
toggleButton.Size = UDim2.new(0, 50, 0, 50)
toggleButton.BackgroundColor3 = Color3.fromRGB(62, 31, 96)
toggleButton.BorderSizePixel = 0
toggleButton.Text = ""
toggleButton.TextColor3 = Color3.fromRGB(238, 201, 255)
toggleButton.Font = Enum.Font.GothamBold
toggleButton.TextSize = 24
toggleButton.AutoButtonColor = false
toggleButton.ClipsDescendants = true
toggleButton.ZIndex = 20
toggleButton.Parent = screenGui

local SCRIPT_ICON_URL = "https://raw.githubusercontent.com/ultra3-dev/AURA-EGG-NOTIFIER/151cc038510f603b832be34568d8097a66048c1a/assets/aura-egg-script-icon.png"
local function resolveScriptIconAsset()
	local assetResolver = getsynasset or getcustomasset
	if type(assetResolver) ~= "function" or type(writefile) ~= "function" then
		return nil
	end

	local localPath = "AURA_EGG_SCRIPT_ICON.png"
	local present = false
	if type(isfile) == "function" then
		pcall(function() present = isfile(localPath) end)
	end

	if not present and httpRequest then
		local downloaded, response = pcall(function()
			return httpRequest({
				Url = SCRIPT_ICON_URL,
				Method = "GET"
			})
		end)
		local body = downloaded and response and (response.Body or response.body)
		if type(body) == "string" and #body > 0 then
			pcall(writefile, localPath, body)
		end
	end

	local resolved, asset = pcall(assetResolver, localPath)
	return resolved and asset or nil
end

local scriptIconAsset = resolveScriptIconAsset()
if scriptIconAsset then
	local scriptIcon = Instance.new("ImageLabel")
	scriptIcon.Name = "AURAEggScriptIcon"
	scriptIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	scriptIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	scriptIcon.Size = UDim2.new(1, -6, 1, -6)
	scriptIcon.BackgroundTransparency = 1
	scriptIcon.BorderSizePixel = 0
	scriptIcon.Image = scriptIconAsset
	scriptIcon.ScaleType = Enum.ScaleType.Fit
	scriptIcon.ZIndex = toggleButton.ZIndex + 1
	scriptIcon.Parent = toggleButton
	local scriptIconCorner = Instance.new("UICorner")
	scriptIconCorner.CornerRadius = UDim.new(1, 0)
	scriptIconCorner.Parent = scriptIcon
else
	createCanvasIcon(
		toggleButton,
		"egg",
		Color3.fromRGB(238, 201, 255),
		UDim2.new(0, 24, 0, 24),
		UDim2.new(0.5, 0, 0.5, 0)
	)
end

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = toggleButton

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Color = Color3.fromRGB(190, 90, 255)
toggleStroke.Thickness = 2
toggleStroke.Parent = toggleButton

local badge = Instance.new("TextLabel")
badge.Name = "NotificationBadge"
badge.AnchorPoint = Vector2.new(1, 0)
badge.Position = UDim2.new(1, 5, 0, -5)
badge.Size = UDim2.new(0, 22, 0, 22)
badge.BackgroundColor3 = Color3.fromRGB(235, 40, 70)
badge.BorderSizePixel = 0
badge.Text = "0"
badge.TextColor3 = Color3.fromRGB(255, 255, 255)
badge.Font = Enum.Font.GothamBold
badge.TextSize = 12
badge.Visible = false
badge.ZIndex = 21
badge.Parent = toggleButton

local badgeCorner = Instance.new("UICorner")
badgeCorner.CornerRadius = UDim.new(1, 0)
badgeCorner.Parent = badge

panel.Visible = false
panelOpen = false
toggleButton.Visible = false

local accessOverlay = Instance.new("Frame")
accessOverlay.Name = "SystemAccess"
accessOverlay.Size = UDim2.new(1, 0, 1, 0)
accessOverlay.BackgroundColor3 = Color3.fromRGB(5, 7, 15)
accessOverlay.BackgroundTransparency = 0.08
accessOverlay.BorderSizePixel = 0
accessOverlay.Active = true
accessOverlay.ZIndex = 100
accessOverlay.Parent = screenGui

local accessGrid = Instance.new("Frame")
accessGrid.Size = UDim2.new(1, 0, 1, 0)
accessGrid.BackgroundTransparency = 1
accessGrid.ZIndex = 100
accessGrid.Parent = accessOverlay

local accessCard = Instance.new("Frame")
accessCard.AnchorPoint = Vector2.new(0.5, 0.5)
accessCard.Position = UDim2.new(0.5, 0, 0.5, 0)
accessCard.Size = UDim2.new(0, 360, 0, 244)
accessCard.BackgroundColor3 = Color3.fromRGB(14, 18, 35)
accessCard.BorderSizePixel = 0
accessCard.ZIndex = 101
accessCard.Parent = accessGrid

local accessCardCorner = Instance.new("UICorner")
accessCardCorner.CornerRadius = UDim.new(0, 12)
accessCardCorner.Parent = accessCard

local accessCardStroke = Instance.new("UIStroke")
accessCardStroke.Color = Color3.fromRGB(92, 191, 255)
accessCardStroke.Thickness = 1.5
accessCardStroke.Transparency = 0.16
accessCardStroke.Parent = accessCard

local accessAccent = Instance.new("Frame")
accessAccent.Position = UDim2.new(0, 0, 0, 0)
accessAccent.Size = UDim2.new(1, 0, 0, 4)
accessAccent.BackgroundColor3 = Color3.fromRGB(94, 205, 255)
accessAccent.BorderSizePixel = 0
accessAccent.ZIndex = 102
accessAccent.Parent = accessCard

local accessAccentCorner = Instance.new("UICorner")
accessAccentCorner.CornerRadius = UDim.new(0, 12)
accessAccentCorner.Parent = accessAccent

local accessEyebrow = Instance.new("TextLabel")
accessEyebrow.Position = UDim2.new(0, 24, 0, 22)
accessEyebrow.Size = UDim2.new(1, -48, 0, 16)
accessEyebrow.BackgroundTransparency = 1
accessEyebrow.Text = "SYSTEM // AUTHORIZATION GATE"
accessEyebrow.TextColor3 = Color3.fromRGB(94, 205, 255)
accessEyebrow.Font = Enum.Font.Code
accessEyebrow.TextSize = 10
accessEyebrow.TextXAlignment = Enum.TextXAlignment.Left
accessEyebrow.ZIndex = 102
accessEyebrow.Parent = accessCard

local accessTitle = Instance.new("TextLabel")
accessTitle.Position = UDim2.new(0, 22, 0, 45)
accessTitle.Size = UDim2.new(1, -44, 0, 28)
accessTitle.BackgroundTransparency = 1
accessTitle.Text = "SHADOW MONARCH KEY REQUIRED"
accessTitle.TextColor3 = Color3.fromRGB(236, 246, 255)
accessTitle.Font = Enum.Font.GothamBold
accessTitle.TextSize = 19
accessTitle.TextXAlignment = Enum.TextXAlignment.Left
accessTitle.ZIndex = 102
accessTitle.Parent = accessCard

local accessDescription = Instance.new("TextLabel")
accessDescription.Position = UDim2.new(0, 24, 0, 78)
accessDescription.Size = UDim2.new(1, -48, 0, 18)
accessDescription.BackgroundTransparency = 1
accessDescription.Text = "IDENTITY CHECK REQUIRED // 3 ATTEMPTS"
accessDescription.TextColor3 = Color3.fromRGB(159, 170, 202)
accessDescription.Font = Enum.Font.Code
accessDescription.TextSize = 9
accessDescription.TextXAlignment = Enum.TextXAlignment.Left
accessDescription.ZIndex = 102
accessDescription.Parent = accessCard

local accessInput = Instance.new("TextBox")
accessInput.Name = "AccessKey"
accessInput.Position = UDim2.new(0, 22, 0, 111)
accessInput.Size = UDim2.new(1, -44, 0, 34)
accessInput.BackgroundColor3 = Color3.fromRGB(24, 31, 55)
accessInput.BorderSizePixel = 0
accessInput.ClearTextOnFocus = false
accessInput.PlaceholderText = "ENTER ACCESS KEY"
accessInput.PlaceholderColor3 = Color3.fromRGB(108, 126, 166)
accessInput.Text = ""
accessInput.TextColor3 = Color3.fromRGB(236, 246, 255)
accessInput.Font = Enum.Font.Code
accessInput.TextSize = 11
accessInput.TextXAlignment = Enum.TextXAlignment.Left
accessInput.ZIndex = 102
accessInput.Parent = accessCard

local accessInputPadding = Instance.new("UIPadding")
accessInputPadding.PaddingLeft = UDim.new(0, 10)
accessInputPadding.PaddingRight = UDim.new(0, 10)
accessInputPadding.Parent = accessInput

local accessInputCorner = Instance.new("UICorner")
accessInputCorner.CornerRadius = UDim.new(0, 6)
accessInputCorner.Parent = accessInput

local accessButton = Instance.new("TextButton")
accessButton.Name = "Authorize"
accessButton.Position = UDim2.new(0, 22, 0, 154)
accessButton.Size = UDim2.new(1, -44, 0, 32)
accessButton.BackgroundColor3 = Color3.fromRGB(39, 113, 164)
accessButton.BorderSizePixel = 0
accessButton.Text = "AUTHORIZE  >  ENTER SYSTEM"
accessButton.TextColor3 = Color3.fromRGB(239, 251, 255)
accessButton.Font = Enum.Font.GothamBold
accessButton.TextSize = 10
accessButton.AutoButtonColor = false
accessButton.ZIndex = 102
accessButton.Parent = accessCard

local accessButtonCorner = Instance.new("UICorner")
accessButtonCorner.CornerRadius = UDim.new(0, 6)
accessButtonCorner.Parent = accessButton

local accessStatus = Instance.new("TextLabel")
accessStatus.Position = UDim2.new(0, 24, 0, 197)
accessStatus.Size = UDim2.new(1, -48, 0, 22)
accessStatus.BackgroundTransparency = 1
accessStatus.Text = "STATUS: LOCKED"
accessStatus.TextColor3 = Color3.fromRGB(255, 193, 89)
accessStatus.Font = Enum.Font.Code
accessStatus.TextSize = 9
accessStatus.TextXAlignment = Enum.TextXAlignment.Left
accessStatus.ZIndex = 102
accessStatus.Parent = accessCard

local accessAttempts = 0
local accessUnlocked = false

local function submitAccessKey()
	if accessUnlocked then return end

	if accessInput.Text == CONFIG.AccessKey then
		accessUnlocked = true
		accessStatus.Text = "STATUS: AUTHORIZED // WELCOME, AURA"
		accessStatus.TextColor3 = Color3.fromRGB(151, 255, 204)
		accessButton.Text = "ACCESS GRANTED"
		accessButton.BackgroundColor3 = Color3.fromRGB(38, 145, 117)
		toggleButton.Visible = true
		panel.Visible = true
		panelOpen = true
		accessOverlay.Visible = false
		accessOverlay.Active = false
		accessInput:ReleaseFocus()
	else
		accessAttempts = accessAttempts + 1
		local remaining = math.max(0, CONFIG.MaxAccessAttempts - accessAttempts)
		accessInput.Text = ""

		if remaining <= 0 then
			accessStatus.Text = "STATUS: ACCESS DENIED // SESSION TERMINATED"
			accessStatus.TextColor3 = Color3.fromRGB(255, 92, 133)
			task.delay(0.65, function()
				if player and player.Parent then
					player:Kick("AURA SYSTEM: authorization failed.")
				end
			end)
		else
			accessStatus.Text = "STATUS: INVALID KEY // "
				.. tostring(remaining)
				.. " ATTEMPT"
				.. (remaining == 1 and "" or "S")
				.. " REMAINING"
			accessStatus.TextColor3 = Color3.fromRGB(255, 193, 89)
		end
	end
end

accessButton.MouseButton1Click:Connect(submitAccessKey)
accessInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then
		submitAccessKey()
	end
end)

local POSITION_FILE = "AuraEggNotifier_ButtonPosition.json"
local LAST_SEEN_STATE_FILE = "AuraEggNotifier_LastSeen.json"
local PROMOTION_STATE_FILE = "AuraEggNotifier_Promotion.json"
local CONFIG_STATE_FILE = "AuraEggNotifier_Config.json"
local localFileExists = isfile
local localFileRead = readfile
local localFileWrite = writefile
local lastSeenSaveScheduled = false

local lastSeenState = {
version = 2,
	messageId = nil,
messageIds = {},
	entries = {},
	seeded = false,
	seedVersion = 0
}

local sharedLastSeenMessageId = auraRuntime.AURA_EGG_NOTIFIER_LAST_SEEN_MESSAGE_ID
if type(sharedLastSeenMessageId) == "string" and sharedLastSeenMessageId ~= "" then
lastSeenState.messageId = sharedLastSeenMessageId
end

-- Cada webhook tiene su propio mensaje de Last Seen. El hash evita guardar
-- el token privado del webhook dentro del archivo local de estado.
local function getLastSeenWebhookKey(url)
local hash = 7
for index = 1, #url do
hash = (hash * 31 + string.byte(url, index)) % 2147483647
end
return tostring(hash)
end

local function loadLastSeenState()
	if type(localFileExists) ~= "function" or type(localFileRead) ~= "function" then
		return
	end

	local existsOk, exists = pcall(function()
		return localFileExists(LAST_SEEN_STATE_FILE)
	end)
	if not existsOk or not exists then return end

	local readOk, raw = pcall(function()
		return localFileRead(LAST_SEEN_STATE_FILE)
	end)
	if not readOk or not raw or raw == "" then return end

	local decodeOk, decoded = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not decodeOk or type(decoded) ~= "table" then return end

	if type(decoded.messageId) == "string" and decoded.messageId ~= "" then
		lastSeenState.messageId = decoded.messageId
	end
if type(decoded.messageIds) == "table" then
for webhookKey, messageId in pairs(decoded.messageIds) do
if type(webhookKey) == "string" and type(messageId) == "string" and messageId ~= "" then
lastSeenState.messageIds[webhookKey] = messageId
end
end
elseif lastSeenState.messageId then
-- Migra el formato anterior al webhook configurado actualmente.
local configuredWebhook = tostring(CONFIG.LastSeenWebhookURL or "")
:gsub("%?.*$", "")
:gsub("/+$", "")
if configuredWebhook ~= "" and not configuredWebhook:find("PASTE_", 1, true) then
lastSeenState.messageIds[getLastSeenWebhookKey(configuredWebhook)] = lastSeenState.messageId
end
end
	if type(decoded.entries) == "table" then
		lastSeenState.entries = decoded.entries
	elseif type(decoded.lastSeen) == "table" then
		-- Compatibilidad con la forma {messageId, lastSeen} usada por
		-- versiones intermedias del Last Seen.
		lastSeenState.entries = decoded.lastSeen
	end
	if type(decoded.seeded) == "boolean" then
		lastSeenState.seeded = decoded.seeded
	end
	if tonumber(decoded.seedVersion) then
		lastSeenState.seedVersion = tonumber(decoded.seedVersion)
	end
end

local function saveLastSeenState()
if lastSeenState.messageId and lastSeenState.messageId ~= "" then
auraRuntime.AURA_EGG_NOTIFIER_LAST_SEEN_MESSAGE_ID = tostring(lastSeenState.messageId)
end

	if type(localFileWrite) ~= "function" then
		return false
	end

	local ok = pcall(function()
		localFileWrite(LAST_SEEN_STATE_FILE, HttpService:JSONEncode(lastSeenState))
	end)
	return ok
end

local function scheduleLastSeenStateSave()
if lastSeenSaveScheduled then return end
lastSeenSaveScheduled = true
task.delay(3, function()
lastSeenSaveScheduled = false
saveLastSeenState()
end)
end

local function cleanPromotionInput(value)
return (tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

local function loadPromotionState()
if type(localFileExists) ~= "function" or type(localFileRead) ~= "function" then
return
end

local existsOk, exists = pcall(function()
return localFileExists(PROMOTION_STATE_FILE)
end)
if not existsOk or not exists then return end

local readOk, raw = pcall(function()
return localFileRead(PROMOTION_STATE_FILE)
end)
if not readOk or not raw or raw == "" then return end

local decodeOk, decoded = pcall(function()
return HttpService:JSONDecode(raw)
end)
if not decodeOk or type(decoded) ~= "table" then return end

if type(decoded.url) == "string" then
promotionState.url = decoded.url
end
if type(decoded.label) == "string" then
promotionState.label = decoded.label
end
if tonumber(decoded.maxUses) then
promotionState.maxUses = math.max(0, math.floor(tonumber(decoded.maxUses)))
end
if tonumber(decoded.used) then
promotionState.used = math.max(0, math.floor(tonumber(decoded.used)))
end
if tonumber(decoded.intervalMinutes) then
promotionState.intervalMinutes = math.max(0, tonumber(decoded.intervalMinutes))
end
if tonumber(decoded.nextAvailableAt) then
promotionState.nextAvailableAt = tonumber(decoded.nextAvailableAt)
end
if type(decoded.emoji) == "string" then
promotionState.emoji = decoded.emoji
end
if type(decoded.rarity) == "string" then
promotionState.rarity = decoded.rarity
end
end

local function savePromotionState()
if type(localFileWrite) ~= "function" then
return false
end

local ok = pcall(function()
localFileWrite(PROMOTION_STATE_FILE, HttpService:JSONEncode(promotionState))
end)
return ok
end

local function normalizeConfiguredRarity(value)
	local raw = tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if raw == "" then return "Secret" end
	local lower = raw:lower()
	if lower == "divine" then return "Divine" end
	if lower == "eternal" then return "Eternal" end
	if lower == "secret" then return "Secret" end
	return "Secret"
end

local function normalizeConfiguredEntry(raw)
	if type(raw) ~= "table" then return nil end
	local name = tostring(raw.name or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local key = name:lower():gsub("[^a-z0-9]", "")
	local roleId = tostring(raw.roleId or raw.role or "")
		:gsub("<@&", "")
		:gsub(">", "")
		:gsub("%D", "")
	local emoji = tostring(raw.emoji or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if name == "" or key == "" or roleId == "" then return nil end
	return {
		name = name:sub(1, 48),
		key = key,
		roleId = roleId,
		emoji = emoji ~= "" and emoji:sub(1, 80) or "🐾",
		rarity = normalizeConfiguredRarity(raw.rarity)
	}
end

local function loadConfigState()
	if type(localFileExists) ~= "function" or type(localFileRead) ~= "function" then return end
	local existsOk, exists = pcall(function() return localFileExists(CONFIG_STATE_FILE) end)
	if not existsOk or not exists then return end
	local readOk, raw = pcall(function() return localFileRead(CONFIG_STATE_FILE) end)
	if not readOk or not raw or raw == "" then return end
	local decodeOk, decoded = pcall(function() return HttpService:JSONDecode(raw) end)
	if not decodeOk or type(decoded) ~= "table" then return end
	local source = decoded.entries or decoded
	if type(source) ~= "table" then return end
	configState.entries = {}
	for _, value in pairs(source) do
		local entry = normalizeConfiguredEntry(value)
		if entry then table.insert(configState.entries, entry) end
	end
	if type(decoded.webhooks) == "table" then
		if type(decoded.webhooks.main) == "string" then configState.webhooks.main = decoded.webhooks.main end
		if type(decoded.webhooks.lastSeen) == "string" then configState.webhooks.lastSeen = decoded.webhooks.lastSeen end
	end
end

local function saveConfigState()
	if type(localFileWrite) ~= "function" then return false end
	return pcall(function()
		localFileWrite(CONFIG_STATE_FILE, HttpService:JSONEncode(configState))
	end)
end

local function saveTogglePosition()
	if type(localFileWrite) ~= "function" then return end

	local viewport = screenGui.AbsoluteSize
	if viewport.X <= 0 or viewport.Y <= 0 then return end

	local absolutePosition = toggleButton.AbsolutePosition
	local absoluteSize = toggleButton.AbsoluteSize
	local position = {
		x = (absolutePosition.X + absoluteSize.X / 2) / viewport.X,
		y = (absolutePosition.Y + absoluteSize.Y / 2) / viewport.Y
	}

	pcall(function()
		localFileWrite(POSITION_FILE, HttpService:JSONEncode(position))
	end)
end

local function loadTogglePosition()
	if type(localFileExists) ~= "function" or type(localFileRead) ~= "function" then
		return
	end

	local existsOk, exists = pcall(function()
		return localFileExists(POSITION_FILE)
	end)
	if not existsOk or not exists then return end

	local ok, raw = pcall(function()
		return localFileRead(POSITION_FILE)
	end)
	if not ok or not raw or raw == "" then return end

	local decodedOk, position = pcall(function()
		return HttpService:JSONDecode(raw)
	end)
	if not decodedOk or type(position) ~= "table" then return end

	local x = tonumber(position.x)
	local y = tonumber(position.y)
	if not x or not y then return end

	x = math.max(0.05, math.min(0.95, x))
	y = math.max(0.08, math.min(0.92, y))
	toggleButton.Position = UDim2.new(x, 0, y, 0)
end

loadTogglePosition()
loadLastSeenState()
loadPromotionState()
loadConfigState()

-- Migra también archivos creados por versiones anteriores. Nunca permitas
-- que una rareza antigua vuelva a aparecer en el editor de configuración.
local configStateChanged = false
for _, entry in ipairs(configState.entries) do
	local normalizedRarity = normalizeConfiguredRarity(entry.rarity)
	if entry.rarity ~= normalizedRarity then
		entry.rarity = normalizedRarity
		configStateChanged = true
	end
end
if configStateChanged then saveConfigState() end

configUi.mainWebhookBox.Text = configState.webhooks.main or ""
configUi.lastSeenWebhookBox.Text = configState.webhooks.lastSeen or ""
if configState.webhooks.main ~= "" or configState.webhooks.lastSeen ~= "" then
	configUi.webhookStatus.Text = "STATUS // SAVED LOCALLY  //  READY"
end

configUi.saveWebhookButton.MouseButton1Click:Connect(function()
	local main = tostring(configUi.mainWebhookBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	local lastSeen = tostring(configUi.lastSeenWebhookBox.Text or ""):gsub("^%s+", ""):gsub("%s+$", "")
	if main ~= "" and not main:match("^https://") then
		updateStatus("WEBHOOK // MAIN URL INVALID", Color3.fromRGB(255, 92, 133))
		return
	end
	if lastSeen ~= "" and not lastSeen:match("^https://") then
		updateStatus("WEBHOOK // LAST SEEN URL INVALID", Color3.fromRGB(255, 92, 133))
		return
	end
	configState.webhooks.main = main
	configState.webhooks.lastSeen = lastSeen
	saveConfigState()
	configUi.webhookStatus.Text = "STATUS // SAVED LOCALLY  //  READY"
	updateStatus("WEBHOOK // SAVED ON DEVICE", Color3.fromRGB(151, 255, 204))
end)

configUi.clearWebhookButton.MouseButton1Click:Connect(function()
	configState.webhooks.main = ""
	configState.webhooks.lastSeen = ""
	configUi.mainWebhookBox.Text = ""
	configUi.lastSeenWebhookBox.Text = ""
	configUi.webhookStatus.Text = "STATUS // DISABLED  //  USING LOADER ENV"
	saveConfigState()
	updateStatus("WEBHOOK // LOCAL VALUES CLEARED", Color3.fromRGB(255, 193, 89))
end)

promotionUrlBox.Text = promotionState.url
promotionLabelBox.Text = promotionState.label
promotionEmojiBox.Text = promotionState.emoji
promotionUsesBox.Text = tostring(promotionState.maxUses)
promotionIntervalBox.Text = tostring(promotionState.intervalMinutes)

-- ULTRA button system: gradients, neon edge, tactile press state and compact icons.
local function enhanceButton(button, accent, iconKind)
	if not button then return end
	button.AutoButtonColor = false
	button.ClipsDescendants = true
	button.TextColor3 = Color3.fromRGB(248, 250, 255)

	button.BackgroundColor3 = accent
	button.BackgroundTransparency = 0.04

	local stroke = button:FindFirstChild("UltraStroke")
	if not stroke then
		stroke = Instance.new("UIStroke")
		stroke.Name = "UltraStroke"
		stroke.Parent = button
	end
	stroke.Color = accent
	stroke.Thickness = 1.25
	stroke.Transparency = 0.08

	local corner = button:FindFirstChildOfClass("UICorner")
	if not corner then
		corner = Instance.new("UICorner")
		corner.Parent = button
	end
	corner.CornerRadius = UDim.new(0, 8)

	if iconKind then
		local textPadding = button:FindFirstChildOfClass("UIPadding")
		if not textPadding then
			textPadding = Instance.new("UIPadding")
			textPadding.Name = "IconTextPadding"
			textPadding.Parent = button
		end
		textPadding.PaddingLeft = UDim.new(0, 36)
		textPadding.PaddingRight = UDim.new(0, 8)
		button.TextXAlignment = Enum.TextXAlignment.Left

		local icon = button:FindFirstChild("UltraButtonIcon")
		if not icon then
			icon = createCanvasIcon(
				button,
				iconKind,
				Color3.fromRGB(255, 255, 255),
				UDim2.new(0, 16, 0, 16),
				UDim2.new(0, 16, 0.5, 0),
				"UltraButtonIcon"
			)
		end
		icon.ZIndex = button.ZIndex + 2
	end

	local function setPressed(pressed)
		button.BackgroundTransparency = pressed and 0.16 or 0.04
		stroke.Thickness = pressed and 2 or 1.25
		stroke.Transparency = pressed and 0 or 0.08
	end
	button.MouseButton1Down:Connect(function() setPressed(true) end)
	button.MouseButton1Up:Connect(function() setPressed(false) end)
	button.MouseLeave:Connect(function() setPressed(false) end)
end

enhanceButton(panelClose, Color3.fromRGB(255, 78, 128), nil)
enhanceButton(sendAnnouncementButton, Color3.fromRGB(156, 78, 255), "send")
enhanceButton(savePromotionButton, Color3.fromRGB(0, 151, 255), "link")
enhanceButton(configUi.rarityButton, Color3.fromRGB(102, 73, 215), "tag")
enhanceButton(configUi.saveButton, Color3.fromRGB(0, 151, 255), "check")
enhanceButton(configUi.newButton, Color3.fromRGB(94, 73, 184), "plus")
enhanceButton(configUi.deleteButton, Color3.fromRGB(218, 35, 78), "trash")
enhanceButton(configUi.saveWebhookButton, Color3.fromRGB(0, 151, 255), "route")
enhanceButton(configUi.clearWebhookButton, Color3.fromRGB(218, 35, 78), "broom")
enhanceButton(copyConsoleButton, Color3.fromRGB(156, 78, 255), "copy")
enhanceButton(logJumpButton, Color3.fromRGB(156, 78, 255), nil)
enhanceButton(consoleJumpButton, Color3.fromRGB(218, 35, 78), nil)

local activeCards = {}
local layoutCounter = 0

local function cleanText(text)
	if not text then return "" end
	return (text
		:gsub("<[^>]+>", "")
		:gsub("🥚", "")
		:gsub("👋", "")
		:gsub("✦", "")
		:gsub("▣", ""))
end

local function removeCard(card)
	for i, c in ipairs(activeCards) do
		if c == card then table.remove(activeCards, i) break end
	end
end

local function colorToHex(color)
	return string.format(
		"#%02X%02X%02X",
		math.floor(color.R * 255 + 0.5),
		math.floor(color.G * 255 + 0.5),
		math.floor(color.B * 255 + 0.5)
	)
end

local function escapeRichText(text)
	return (tostring(text):gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

local function updateStatus(text, color)
	local statusColor = color or Color3.fromRGB(99, 255, 154)
	statusLabel.Text = string.format(
		'<font color="#D6A5FF">SYSTEM</font><font color="#FF4D67">:</font> <font color="%s">%s</font>',
		colorToHex(statusColor),
		escapeRichText(text)
	)
end

local logEntries = {}
local consoleEntries = {}
local logRenderScheduled = false
local consoleRenderScheduled = false

local function getClockTime()
	return os.date("!%H:%M:%S")
end

local function scrollToLatest(scrollingFrame)
	task.defer(function()
		local maximum = math.max(
			0,
			scrollingFrame.CanvasSize.Y.Offset - scrollingFrame.AbsoluteWindowSize.Y
		)
		scrollingFrame.CanvasPosition = Vector2.new(0, maximum)
	end)
end

local function renderPersistentLog()
	logBody.Text = table.concat(logEntries, "\n\n")
	task.defer(refreshLogCanvas)
end

local function schedulePersistentLogRender()
	if logRenderScheduled then return end
	logRenderScheduled = true
	task.defer(function()
		logRenderScheduled = false
		renderPersistentLog()
	end)
end

local function appendLogHistory(text, sequence, rarityName)
	local safeText = tostring(text or "")
	local prefix = string.format(
		"[%s]  EVENT #%03d  //  %s",
		getClockTime(),
		tonumber(sequence) or 0,
		tostring(rarityName or "NORMAL")
	)
	table.insert(logEntries, prefix .. "\n" .. safeText)

	while #logEntries > CONFIG.MaxNotifications do
		table.remove(logEntries, 1)
	end

	schedulePersistentLogRender()
end

local function renderConsole()
	consoleBody.Text = table.concat(consoleEntries, "\n")
	task.defer(function()
		local height = math.max(consoleBody.AbsoluteSize.Y + 16, consoleScroll.AbsoluteWindowSize.Y + 1)
		consoleScroll.CanvasSize = UDim2.new(0, 0, 0, height)
	end)
end

local function scheduleConsoleRender()
	if consoleRenderScheduled then return end
	consoleRenderScheduled = true
	task.defer(function()
		consoleRenderScheduled = false
		renderConsole()
	end)
end

local function appendConsoleEntry(message, messageType, source)
	local cleanMessage = tostring(message or ""):gsub("\r", "")
	if cleanMessage == "" then return end

	local typeName = tostring(messageType or ""):upper()
	local lowerMessage = cleanMessage:lower()
	local severity = "INFO"
	if typeName:find("ERROR", 1, true)
		or lowerMessage:find("error", 1, true)
		or lowerMessage:find("failed", 1, true)
		or lowerMessage:find("exception", 1, true) then
		severity = "ERROR"
	elseif typeName:find("WARN", 1, true)
		or lowerMessage:find("warning", 1, true) then
		severity = "WARN"
	end

	local origin = source or "GAME"
	table.insert(
		consoleEntries,
		string.format("[%s] [%s] [%s] %s", getClockTime(), severity, origin, cleanMessage)
	)

	while #consoleEntries > CONFIG.ConsoleMaxLines do
		table.remove(consoleEntries, 1)
	end

	scheduleConsoleRender()
end

copyConsoleButton.MouseButton1Click:Connect(function()
	local fullText = table.concat(consoleEntries, "\n")
	local clipboard = setclipboard or toclipboard or set_clipboard
	if type(clipboard) == "function" then
		local ok = pcall(function()
			clipboard(fullText)
		end)
		if ok then
			copyConsoleButton.Text = "COPIED [OK]"
			updateStatus("CONSOLE // COPIED TO CLIPBOARD", Color3.fromRGB(151, 255, 204))
			task.delay(1.2, function()
				if copyConsoleButton.Parent then
					copyConsoleButton.Text = "  COPY ALL"
				end
			end)
			return
		end
	end

	updateStatus("CONSOLE // CLIPBOARD UNAVAILABLE", Color3.fromRGB(255, 193, 89))
end)

logJumpButton.MouseButton1Click:Connect(function()
	scrollToLatest(logPanel)
end)

consoleJumpButton.MouseButton1Click:Connect(function()
	scrollToLatest(consoleScroll)
end)

local PROMOTION_RARITIES = {"", "DIVINE", "ETERNAL", "SECRET"}
local promotionDraftRarity = promotionState.rarity

local function getPromotionRarityLabel(rarity)
	if rarity == "DIVINE" then return "DIVINE" end
	if rarity == "ETERNAL" then return "ETERNAL" end
	if rarity == "SECRET" then return "SECRET" end
	return "TODAS"
end

local function updatePromotionControls()
	local rarityLabel = getPromotionRarityLabel(promotionDraftRarity)
	promotionRarityButton.Text = "RAREZA: " .. rarityLabel
	if promotionDraftRarity ~= "" then
		promotionIntervalBox.TextEditable = false
		promotionIntervalBox.Text = "0"
		promotionIntervalBox.PlaceholderText = "DESACTIVADO // RAREZA"
		promotionIntervalBox.TextColor3 = Color3.fromRGB(143, 128, 165)
	else
		promotionIntervalBox.TextEditable = true
		promotionIntervalBox.PlaceholderText = "Minutos (0 = cada huevo)"
		promotionIntervalBox.TextColor3 = Color3.fromRGB(245, 235, 255)
	end
end

local function parsePromotionEmoji(value)
	local cleaned = cleanPromotionInput(value)
	if cleaned == "" then return nil end

	local animated, customName, customId
	customName, customId = cleaned:match("^<a:([%w_]+):(%d+)>$")
	if customName then
		animated = true
	else
		customName, customId = cleaned:match("^<:([%w_]+):(%d+)>$")
		animated = false
	end
	if customName and customId then
		return {
			name = customName,
			id = customId,
			animated = animated
		}
	end

	if cleaned:find("[<>]") or #cleaned > 32 then
		return nil
	end

	return {name = cleaned}
end

updatePromotionControls()

promotionRarityButton.MouseButton1Click:Connect(function()
	local currentIndex = 1
	for index, rarity in ipairs(PROMOTION_RARITIES) do
		if rarity == promotionDraftRarity then
			currentIndex = index
			break
		end
	end

	local nextIndex = currentIndex % #PROMOTION_RARITIES + 1
	promotionDraftRarity = PROMOTION_RARITIES[nextIndex]
	updatePromotionControls()
end)

savePromotionButton.MouseButton1Click:Connect(function()
local url = cleanPromotionInput(promotionUrlBox.Text)
local label = cleanPromotionInput(promotionLabelBox.Text)
local emojiText = cleanPromotionInput(promotionEmojiBox.Text)
local maxUsesText = cleanPromotionInput(promotionUsesBox.Text)
local intervalText = cleanPromotionInput(promotionIntervalBox.Text)
local maxUses = maxUsesText == "" and 0 or tonumber(maxUsesText)
local intervalMinutes = intervalText == "" and 0 or tonumber(intervalText)
local emoji = parsePromotionEmoji(emojiText)
local selectedRarity = promotionDraftRarity

if url ~= "" and not url:match("^https?://%S+$") then
updateStatus("PROMOTIONS // INVALID URL", Color3.fromRGB(255, 92, 133))
return
end

if #label > 80 then
updateStatus("PROMOTIONS // BUTTON NAME TOO LONG", Color3.fromRGB(255, 92, 133))
return
end

if emojiText ~= "" and not emoji then
updateStatus("PROMOTIONS // INVALID EMOJI FORMAT", Color3.fromRGB(255, 92, 133))
return
end

if not maxUses
or not intervalMinutes
or maxUses ~= maxUses
or intervalMinutes ~= intervalMinutes
or maxUses < 0
or intervalMinutes < 0
or maxUses % 1 ~= 0 then
updateStatus("PROMOTIONS // VALUES MUST BE POSITIVE", Color3.fromRGB(255, 92, 133))
return
end

if selectedRarity ~= "" and maxUses < 1 then
updateStatus("PROMOTIONS // RARITY NEEDS A POSITIVE LIMIT", Color3.fromRGB(255, 92, 133))
return
end

promotionState.url = url
promotionState.label = label ~= "" and label or "PROMOTION"
promotionState.emoji = emojiText
promotionState.rarity = selectedRarity
promotionState.maxUses = math.floor(maxUses)
promotionState.used = 0
promotionState.intervalMinutes = intervalMinutes
promotionState.nextAvailableAt = 0
savePromotionState()
updatePromotionControls()

if url == "" then
savePromotionButton.Text = "SAVE PROMOTION  >  DISABLED"
updateStatus("PROMOTIONS // BUTTON DISABLED", Color3.fromRGB(214, 165, 255))
else
savePromotionButton.Text = "SAVED [OK]  // NEXT EGG"
updateStatus("PROMOTIONS // BUTTON READY", Color3.fromRGB(151, 255, 204))
end
end)

local activeSection = "LOG"

local function setActiveSection(section)
	activeSection = section
	local showLog = section == "LOG"
	local showPromotions = section == "PROMOTIONS"
	local showConfig = section == "CONFIG"
	local showWebhook = section == "WEBHOOK"
	logPanel.Visible = showLog
	updateLogJumpVisibility()
	promotionPanel.Visible = showPromotions
	configUi.panel.Visible = showConfig
	configUi.webhookPanel.Visible = showWebhook
	announcementPanel.Visible = section == "ANNOUNCER"
	consolePanel.Visible = section == "CONSOLE"
	updateConsoleJumpVisibility()
	styleTab(logTab, showLog)
	styleTab(promotionTab, showPromotions)
	styleTab(announcerTab, section == "ANNOUNCER")
	styleTab(configUi.tab, showConfig)
	styleTab(configUi.webhookTab, showWebhook)
	styleTab(consoleTab, section == "CONSOLE")

	if showLog then
		updateStatus("MONITOR // LOG STREAM ACTIVE", Color3.fromRGB(99, 255, 154))
	elseif showPromotions then
		updateStatus("PROMOTIONS // CONFIGURATION READY", Color3.fromRGB(214, 165, 255))
	elseif showConfig then
		updateStatus("CONFIG // SAVED PETS READY", Color3.fromRGB(151, 255, 204))
	elseif showWebhook then
		updateStatus("WEBHOOK // LOCAL ROUTING READY", Color3.fromRGB(255, 193, 89))
	elseif section == "CONSOLE" then
		updateStatus("CONSOLE // STREAM READY", Color3.fromRGB(255, 111, 151))
	else
		updateStatus("ANNOUNCER // EMBED BUILDER READY", Color3.fromRGB(214, 165, 255))
	end
end

logTab.MouseButton1Click:Connect(function()
	setActiveSection("LOG")
end)

promotionTab.MouseButton1Click:Connect(function()
setActiveSection("PROMOTIONS")
end)

announcerTab.MouseButton1Click:Connect(function()
	setActiveSection("ANNOUNCER")
end)

configUi.tab.MouseButton1Click:Connect(function()
	setActiveSection("CONFIG")
end)

configUi.webhookTab.MouseButton1Click:Connect(function()
	setActiveSection("WEBHOOK")
end)

consoleTab.MouseButton1Click:Connect(function()
	setActiveSection("CONSOLE")
end)

local function updateBadge()
	if unreadCount <= 0 then
		badge.Visible = false
		return
	end

	badge.Visible = true
	badge.Text = unreadCount > 9 and "9+" or tostring(unreadCount)
end

local function setPanelVisible(visible)
	panelOpen = visible
	if visible then
		panel.Visible = true
		panelScale.Scale = 0.92
		TweenService:Create(
			panelScale,
			TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{Scale = 1}
		):Play()
		unreadCount = 0
		updateBadge()
	else
		local closingPanel = panel
		local animation = TweenService:Create(
			panelScale,
			TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{Scale = 0.92}
		)
		animation:Play()
		task.delay(0.15, function()
			if not panelOpen and closingPanel == panel then
				panel.Visible = false
			end
		end)
	end
end

local draggingToggle = false
local dragMoved = false
local dragStart = nil
local dragOrigin = nil
local targetTogglePosition = toggleButton.Position

toggleButton.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		draggingToggle = true
		dragMoved = false
		dragStart = input.Position
		dragOrigin = toggleButton.Position
		targetTogglePosition = toggleButton.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if not draggingToggle then return end
	if input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if not dragStart or not dragOrigin then return end

	local delta = input.Position - dragStart
	if math.abs(delta.X) > 5 or math.abs(delta.Y) > 5 then
		dragMoved = true
	end

	targetTogglePosition = UDim2.new(
		dragOrigin.X.Scale,
		dragOrigin.X.Offset + delta.X,
		dragOrigin.Y.Scale,
		dragOrigin.Y.Offset + delta.Y
	)
end)

local dragRenderConnection
dragRenderConnection = RunService.RenderStepped:Connect(function(deltaTime)
	if not draggingToggle or not targetTogglePosition then return end

	local current = toggleButton.Position
	local smoothing = math.min(1, deltaTime * 30)
	toggleButton.Position = UDim2.new(
		current.X.Scale,
		current.X.Offset + (targetTogglePosition.X.Offset - current.X.Offset) * smoothing,
		current.Y.Scale,
		current.Y.Offset + (targetTogglePosition.Y.Offset - current.Y.Offset) * smoothing
	)
end)

screenGui.Destroying:Connect(function()
	if dragRenderConnection then
		dragRenderConnection:Disconnect()
		dragRenderConnection = nil
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	if not draggingToggle then return end

	draggingToggle = false
	toggleButton.Position = targetTogglePosition
	if dragMoved then
		saveTogglePosition()
	else
		setPanelVisible(not panelOpen)
	end
	dragStart = nil
	dragOrigin = nil
end)

panelClose.MouseButton1Click:Connect(function()
	setPanelVisible(false)
end)

toggleButton.MouseEnter:Connect(function()
	TweenService:Create(
		toggleButton,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 56, 0, 56)}
	):Play()
end)

toggleButton.MouseLeave:Connect(function()
	TweenService:Create(
		toggleButton,
		TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{Size = UDim2.new(0, 50, 0, 50)}
	):Play()
end)

task.spawn(function()
	while screenGui.Parent do
		TweenService:Create(
			toggleStroke,
			TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{Transparency = 0.48}
		):Play()
		task.wait(0.8)
		TweenService:Create(
			toggleStroke,
			TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{Transparency = 0.05}
		):Play()
		task.wait(0.8)
	end
end)

