--[[
	🥚 EGG DETECTOR - ULTRA MEGA HYPER-VELOCITY ADVANCED EDITION
	================================================================
	✓ Inicio INSTANTÁNEO - Alerta inmediata al ejecutar
	✓ Detección ULTRA-RÁPIDA - Sin latencia
	✓ Envío DIRECTO - Webhook inmediato sin colas
]]

if not game:IsLoaded() then game.Loaded:Wait() end

local CONFIG = {
	WebhookURL = (type(getgenv) == "function" and getgenv().AURA_EGG_WEBHOOK)
		or "PASTE_A_NEW_DISCORD_WEBHOOK_HERE",
	LastSeenWebhookURL = (type(getgenv) == "function" and getgenv().AURA_EGG_LAST_SEEN_WEBHOOK)
		or "PASTE_A_LAST_SEEN_DISCORD_WEBHOOK_HERE",
	Keywords = {"egg", "huevo", "spawned", "appeared", "aparecido", "secret", "divine", "legendary", "mythical", "eternal", "cosmic"},
	Blacklist = {"[debug]", "eggtooldisplay", "placedeggrenderer", "guard", "trace", "anticheat", "jobid"},
	DisplayTime = 120,
	MaxNotifications = 6,
	PriorityWindow = 0.05,
	MaxPriorityQueue = 12,
	ServerRefreshInterval = 15,
	ImportantEternalKeywords = {
		"oni tiger",
		"gorilla king",
		"skeleton horse",
		"pegasus",
	},
	Version = "WEBHOOK 1.1.0 RELEASE"
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
local lastText, lastTime = nil, 0
local unreadCount = 0
local panelOpen = true
local pendingEggs = {}
local priorityTimer = nil
local priorityVersion = 0
local lastJoinServerId = nil
local cachedPublicServerIds = {}
local serverCacheRefreshing = false

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
panel.Size = UDim2.new(0, 350, 0, 340)
panel.BackgroundColor3 = Color3.fromRGB(42, 25, 64)
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
panelStroke.Color = Color3.fromRGB(174, 85, 255)
panelStroke.Thickness = 2
panelStroke.Transparency = 0.08
panelStroke.Parent = panel

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 62)
topBar.BackgroundColor3 = Color3.fromRGB(60, 33, 91)
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
	elseif kind == "system" then
		local ring = shape("SystemRing", UDim2.new(0.7, 0, 0.7, 0), UDim2.new(0.5, 0, 0.5, 0), 0, 1)
		round(ring, 0.5)
		outline(ring, 1.15)
		local core = shape("SystemCore", UDim2.new(0.22, 0, 0.22, 0), UDim2.new(0.5, 0, 0.5, 0))
		round(core, 0.5)
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
subtitle.Text = "WEBHOOK 1.0.0 RELEASE  //  LIVE DETECTION"
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
logPanel.BackgroundColor3 = Color3.fromRGB(29, 19, 45)
logPanel.BackgroundTransparency = 0.05
logPanel.BorderSizePixel = 0
logPanel.CanvasSize = UDim2.new(0, 0, 0, 0)
logPanel.AutomaticCanvasSize = Enum.AutomaticSize.None
logPanel.ScrollBarThickness = 4
logPanel.ScrollBarImageColor3 = Color3.fromRGB(170, 80, 255)
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

local function refreshLogCanvas()
	local contentHeight = logLayout.AbsoluteContentSize.Y + 20
	logPanel.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
end

logLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(refreshLogCanvas)

local navigation = Instance.new("Frame")
navigation.Name = "Navigation"
navigation.Position = UDim2.new(0.5, -120, 0, 64)
navigation.Size = UDim2.new(0, 240, 0, 28)
navigation.BackgroundTransparency = 1
navigation.Parent = panel

local function styleTab(button, active)
	button.BackgroundColor3 = active
		and Color3.fromRGB(122, 57, 177)
		or Color3.fromRGB(57, 34, 80)
	button.TextColor3 = active
		and Color3.fromRGB(255, 235, 255)
		or Color3.fromRGB(171, 145, 198)

	local label = button:FindFirstChild("TabLabel")
	if label then
		label.TextColor3 = button.TextColor3
	end

	local icon = button:FindFirstChild("TabIcon")
	if icon then
		tintCanvasIcon(icon, button.TextColor3)
	end
end

local logTab = Instance.new("TextButton")
logTab.Name = "LogTab"
logTab.Size = UDim2.new(0, 102, 1, 0)
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

local announcerTab = Instance.new("TextButton")
announcerTab.Name = "AnnouncerTab"
announcerTab.Position = UDim2.new(0, 108, 0, 0)
announcerTab.Size = UDim2.new(0, 132, 1, 0)
announcerTab.BackgroundColor3 = Color3.fromRGB(57, 34, 80)
announcerTab.BorderSizePixel = 0
announcerTab.Text = ""
announcerTab.TextColor3 = Color3.fromRGB(171, 145, 198)
announcerTab.Font = Enum.Font.Code
announcerTab.TextSize = 14
announcerTab.TextXAlignment = Enum.TextXAlignment.Center
announcerTab.TextYAlignment = Enum.TextYAlignment.Center
announcerTab.AutoButtonColor = false
announcerTab.Parent = navigation

local announcerTabIcon = createCanvasIcon(
	announcerTab,
	"announce",
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
announcerTabLabel.TextSize = 13
announcerTabLabel.TextXAlignment = Enum.TextXAlignment.Left
announcerTabLabel.TextYAlignment = Enum.TextYAlignment.Center
announcerTabLabel.Parent = announcerTab

local announcerTabCorner = Instance.new("UICorner")
announcerTabCorner.CornerRadius = UDim.new(0, 6)
announcerTabCorner.Parent = announcerTab

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
sendAnnouncementButton.Text = "SEND EMBED  >  WEBHOOK"
sendAnnouncementButton.TextColor3 = Color3.fromRGB(255, 240, 255)
sendAnnouncementButton.Font = Enum.Font.GothamBold
sendAnnouncementButton.TextSize = 11
sendAnnouncementButton.AutoButtonColor = false
sendAnnouncementButton.Parent = announcementPanel

local sendAnnouncementCorner = Instance.new("UICorner")
sendAnnouncementCorner.CornerRadius = UDim.new(0, 7)
sendAnnouncementCorner.Parent = sendAnnouncementButton

local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "SystemStatus"
statusLabel.Position = UDim2.new(0, 12, 1, -50)
statusLabel.Size = UDim2.new(1, -24, 0, 38)
statusLabel.BackgroundColor3 = Color3.fromRGB(58, 36, 82)
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
toggleButton.ZIndex = 20
toggleButton.Parent = screenGui

createCanvasIcon(
	toggleButton,
	"egg",
	Color3.fromRGB(238, 201, 255),
	UDim2.new(0, 24, 0, 24),
	UDim2.new(0.5, 0, 0.5, 0)
)

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

local POSITION_FILE = "AuraEggNotifier_ButtonPosition.json"
local LAST_SEEN_STATE_FILE = "AuraEggNotifier_LastSeen.json"
local localFileExists = isfile
local localFileRead = readfile
local localFileWrite = writefile

local lastSeenState = {
	version = 1,
	messageId = nil,
	entries = {}
}

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
	if type(decoded.entries) == "table" then
		lastSeenState.entries = decoded.entries
	elseif type(decoded.lastSeen) == "table" then
		-- Compatibilidad con la forma {messageId, lastSeen} usada por
		-- versiones intermedias del Last Seen.
		lastSeenState.entries = decoded.lastSeen
	end
end

local function saveLastSeenState()
	if type(localFileWrite) ~= "function" then
		return false
	end

	local ok = pcall(function()
		localFileWrite(LAST_SEEN_STATE_FILE, HttpService:JSONEncode(lastSeenState))
	end)
	return ok
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

local activeSection = "LOG"

local function setActiveSection(section)
	activeSection = section
	local showLog = section == "LOG"
	logPanel.Visible = showLog
	announcementPanel.Visible = not showLog
	styleTab(logTab, showLog)
	styleTab(announcerTab, not showLog)

	if showLog then
		updateStatus("MONITOR // LOG STREAM ACTIVE", Color3.fromRGB(99, 255, 154))
	else
		updateStatus("ANNOUNCER // EMBED BUILDER READY", Color3.fromRGB(214, 165, 255))
	end
end

logTab.MouseButton1Click:Connect(function()
	setActiveSection("LOG")
end)

announcerTab.MouseButton1Click:Connect(function()
	setActiveSection("ANNOUNCER")
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

-- Rango de mayor a menor rareza. Los empates conservan el orden detectado.
local RARITY_ORDER = {
	{keyword = "divine", rank = 1, roleId = "1544734510665699389"},
	{keyword = "eternal", rank = 2, roleId = "1544734452054229173"},
	{keyword = "secret", rank = 3, roleId = "1544734376640782346"},
	{keyword = "mythical", rank = 4},
	{keyword = "mythic", rank = 4},
	{keyword = "legendary", rank = 5},
	{keyword = "cosmic", rank = 6},
	{keyword = "rare", rank = 7},
	{keyword = "common", rank = 8}
}

-- Roles de cada huevo. El nombre se reemplaza por una mención real.
-- Los alias cubren las variantes que suelen aparecer en el texto del juego.
local EGG_ROLE_MENTIONS = {
	{name = "eternal lunar dragon", roleId = "1551573296632561754"},
	{name = "lunar dragon", roleId = "1551573296632561754"},
	{name = "cosmic skeleton boss", roleId = "1551573311681597520"},
	{name = "pure jellyfish", roleId = "1551573302139424868"},
	{name = "gorilla king", roleId = "1551573293734039582"},
	{name = "skeleton horse", roleId = "1551573288474517504"},
	{name = "lava dragon", roleId = "1551573295814545559"},
	{name = "oni tiger", roleId = "1551573294795333652"},
	{name = "mosasaurus", roleId = "1551573291745939557"},
	{name = "ice dragon", roleId = "1551573297806966794"},
	{name = "world burner", roleId = "1551573281860223027"},
	{name = "nightflame", roleId = "1551573284137734256"},
	{name = "archangel", roleId = "1551573285538500661"},
	{name = "razor fang", roleId = "1551573308854501416"},
	{name = "razorfang", roleId = "1551573308854501416"},
	{name = "mutant shark", roleId = "1551573303812952135"},
	{name = "cosmic dragon", roleId = "1551573313573359666"},
	{name = "king snake", roleId = "1551573312549814314"},
	{name = "unicorn", roleId = "1551573280039641170"},
	{name = "kitsune", roleId = "1551573285047640115"},
	{name = "el maja", roleId = "1551573298872189089"},
	{name = "pegasus", roleId = "1551573286943719595"},
	{name = "phoenix", roleId = "1551573292530274417"},
	{name = "stag", roleId = "1551573301153898496"},
	{name = "tralaledon", roleId = "1551573302558986312"},
	{name = "cerberus", roleId = "1551624633457975398"},
	{name = "gargoyle", roleId = "1551573304802812064"},
	{name = "t rex", roleId = "1551573310637084755"},
	{name = "trex", roleId = "1551573310637084755"},
	{name = "t-rex", roleId = "1551573310637084755"},
	{name = "yeti", roleId = "1551573307671715911"},
	{name = "kraken", roleId = "1551573309764669631"},
	{name = "centaur", roleId = "1551573300021567531"}
}

-- Catálogo fijo del Last Seen. Se muestran todos los huevos conocidos:
-- los que todavía no tienen fecha quedan como "No registrada".
local LAST_SEEN_RARITY_ORDER = {"Divine", "Eternal", "Secret"}
local LAST_SEEN_STYLES = {
	Divine = {
		emoji = "<:Divine:1548446386964406282>",
		color = 0xFFD700,
		separator = "divine"
	},
	Eternal = {
		emoji = "<:Eternal:1548446341699477525>",
		color = 0x9B30FF,
		separator = "eternal"
	},
	Secret = {
		emoji = "<:Secret:1548446274616041645>",
		color = 0x010101,
		separator = "secret"
	}
}

local LAST_SEEN_ASSET_BASE_URL =
	"https://raw.githubusercontent.com/ultra3-dev/AURA-EGG-NOTIFIER/main/assets/"

local LAST_SEEN_CATALOG = {
	Divine = {
		{name = "Nightflame", key = "nightflame", emoji = "<:Nightflame:1548444116873121832>"},
		{name = "Unicorn", key = "unicorn", emoji = "<:Unicorn:1548443051322646548>"},
		{name = "World Burner", key = "worldburner", emoji = "<:World_Burner:1548494788158820483>"},
		{name = "Kitsune", key = "kitsune", emoji = "<:Kitsune:1548443441170620547>"},
		{name = "ArchAngel", key = "archangel", emoji = "<:ArchAngel:1548495435897770045>"}
	},
	Eternal = {
		{name = "El Maja", key = "elmaja", emoji = "<:El_Maja:1548441358493159474>"},
		{name = "Oni Tiger", key = "onitiger", emoji = "<:Oni_Tiger:1548443291773566977>"},
		{name = "Phoenix", key = "phoenix", emoji = "<:Phoenix:1548440843591880724>"},
		{name = "Gorilla King", key = "gorillaking", emoji = "<:Gorilla_King:1548443784084459531>"},
		{name = "Skeleton Horse", key = "skeletonhorse", emoji = "<:Skeleton_Horse:1548491359990579250>"},
		{name = "Lava Dragon", key = "lavadragon", emoji = "<:Lava_Dragon:1548441030783668234>"},
		{name = "Pegasus", key = "pegasus", emoji = "<:Pegasus:1548490925796495452>"},
		{name = "Mosasaurus", key = "mosasaurus", emoji = "<:Mosasaurus:1548441957016273036>"},
		{name = "Eternal Lunar Dragon", key = "eternallunardragon", emoji = "<:Eternal_Lunar_Dragon:1548442744123293766>"},
		{name = "Ice Dragon", key = "icedragon", emoji = "<:Ice_Dragon:1548440110239064174>"}
	},
	Secret = {
		{name = "Stag", key = "stag", emoji = "<:Stag:1548443172806459494>"},
		{name = "Pure Jellyfish", key = "purejellyfish", emoji = "<:Pure_Jellyfish:1548480251321909278>"},
		{name = "RazorFang", key = "razorfang", emoji = "<:RazorFang:1548481759320997928>"},
		{name = "Gargoyle", key = "gargoyle", emoji = "<:Gargoyle:1548480842786021436>"},
		{name = "Cosmic Skeleton Boss", key = "cosmicskeletonboss", emoji = "<:Cosmic_Skeleton_Boss:1548442180018770041>"},
		{name = "Tralaledon", key = "tralaledon", emoji = "<:Tralaledon:1548441688446603435>"},
		{name = "Cerberus", key = "cerberus", emoji = "<:Cerberus:1548440419107348591>"},
		{name = "Mutant Shark", key = "mutantshark", emoji = "<:MutantShark:1548443702035353631>"},
		{name = "Cosmic Dragon", key = "cosmicdragon", emoji = "<:Cosmic_Dragon:1548442406959976579>"},
		{name = "TRex", key = "trex", emoji = "<:TRex:1548441514550632508>"},
		{name = "Yeti", key = "yeti", emoji = "<:Yeti:1548439856785395772>"},
		{name = "Kraken", key = "kraken", emoji = "<:Kraken:1548441236476788786>"},
		{name = "Centaur", key = "centaur", emoji = "<:Centaur:1548493515841871935>"},
		{name = "King Snake", key = "kingsnake", emoji = "<:King_Snake:1548439645849919682>"}
	}
}

local function getRarityRank(text)
	local lower = text:lower()
	for _, rarity in ipairs(RARITY_ORDER) do
		if lower:find(rarity.keyword, 1, true) then
			return rarity.rank
		end
	end
	return 99
end

-- Reemplaza "A [RAREZA]" por la mención del rol correspondiente.
-- También acepta separadores visuales como "[Secret]" o "(Secret)".
local function replaceRarityWithMention(text)
	local lower = text:lower()
	local articleStart, articleEnd = lower:find("^%s*a%s+")

	if not articleStart then
		return text
	end

	local function isRaritySeparator(value)
		if #value > 16 then
			return false
		end

		for index = 1, #value do
			local character = value:sub(index, index)
			if character ~= " "
				and character ~= "\t"
				and character ~= "["
				and character ~= "]"
				and character ~= "("
				and character ~= ")"
				and character ~= "*"
				and character ~= "_"
				and character ~= "-" then
				return false
			end
		end

		return true
	end

	for _, rarity in ipairs(RARITY_ORDER) do
		if rarity.roleId then
			local rarityStart, rarityEnd = lower:find(
				rarity.keyword,
				articleEnd + 1,
				true
			)

			if rarityStart then
				local separator = lower:sub(articleEnd + 1, rarityStart - 1)
				if isRaritySeparator(separator) then
					local replacementEnd = rarityEnd
					local closingCharacter = lower:sub(replacementEnd + 1, replacementEnd + 1)

					if closingCharacter == "]" or closingCharacter == ")" then
						replacementEnd = replacementEnd + 1
					end

					return text:sub(1, articleStart - 1)
						.. "A <@&" .. rarity.roleId .. ">"
						.. text:sub(replacementEnd + 1)
				end
			end
		end
	end

	return text
end

local function replaceEggNameWithMention(text)
	local lower = text:lower()
	local matches = {}

	for _, egg in ipairs(EGG_ROLE_MENTIONS) do
		local startPos, endPos = lower:find(egg.name, 1, true)
		if startPos then
			table.insert(matches, {
				startPos = startPos,
				endPos = endPos,
				roleId = egg.roleId
			})
		end
	end

	table.sort(matches, function(a, b)
		if a.startPos == b.startPos then
			return a.endPos > b.endPos
		end
		return a.startPos < b.startPos
	end)

	local match = matches[1]
	if not match then
		return text, false
	end

	return text:sub(1, match.startPos - 1)
		.. "<@&" .. match.roleId .. ">"
		.. text:sub(match.endPos + 1),
		true
end

local function sendWebhookPayload(payload, successText, onDone)
	if not httpRequest then
		updateStatus("HTTP unavailable", Color3.fromRGB(255, 92, 133))
		if onDone then onDone(false) end
		return
	end

	task.spawn(function()
		local webhookUrl = CONFIG.WebhookURL
		if payload.components then
			webhookUrl = webhookUrl
				.. (webhookUrl:find("?", 1, true) and "&" or "?")
				.. "with_components=true"
		end

		local success, response = pcall(function()
			return httpRequest({
				Url = webhookUrl,
				Method = "POST",
				Headers = {
					["Content-Type"] = "application/json",
					["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
				},
				Body = HttpService:JSONEncode(payload)
			})
		end)
		
		if success and response then
			local code = response.StatusCode or response.Status or 0
			if code >= 200 and code < 300 then
				updateStatus(successText, Color3.fromRGB(99, 255, 154))
				if onDone then onDone(true) end
			else
				updateStatus("ERR:" .. tostring(code), Color3.fromRGB(255, 50, 50))
				if onDone then onDone(false) end
			end
		else
			updateStatus("NET FAIL", Color3.fromRGB(255, 50, 50))
			if onDone then onDone(false) end
		end
	end)
end

local function normalizeLastSeenKey(value)
	return (tostring(value or ""):lower():gsub("[^a-z0-9]", ""))
end

local function getLastSeenRarity(text)
	local lower = tostring(text or ""):lower()
	for _, rarity in ipairs(LAST_SEEN_RARITY_ORDER) do
		if lower:find(rarity:lower(), 1, true) then
			return rarity
		end
	end
	return nil
end

local function getLastSeenEggCandidate(text)
	local lower = tostring(text or ""):lower()
	local afterArticle = lower:match("^%s*a%s+(.+)$")
	if not afterArticle then return nil end

	local beforeSpawn = afterArticle:match("^(.-)%s+egg%s+spawned")
		or afterArticle:match("^(.-)%s+spawned")
	if not beforeSpawn then return nil end

	return normalizeLastSeenKey(beforeSpawn)
end

local function findLastSeenEntry(text, rarity)
	local catalog = LAST_SEEN_CATALOG[rarity]
	if not catalog then return nil end

	local candidate = getLastSeenEggCandidate(text)
	if not candidate then return nil end

	local rarityKey = normalizeLastSeenKey(rarity)
	local withoutRarity = candidate
	local rarityPrefix = rarityKey .. ""
	if candidate:sub(1, #rarityPrefix) == rarityPrefix then
		withoutRarity = candidate:sub(#rarityPrefix + 1)
	end
	withoutRarity = withoutRarity:gsub("^%s+", "")

	for _, entry in ipairs(catalog) do
		local entryKey = normalizeLastSeenKey(entry.name)
		if candidate == entryKey or withoutRarity == entryKey then
			return entry
		end
	end

	return nil
end

local function getLastSeenAssetUrl(name)
	return LAST_SEEN_ASSET_BASE_URL .. "separator-" .. name .. ".png"
end

local function buildLastSeenSeparator(name)
	return {
		type = 12,
		items = {{
			media = {url = getLastSeenAssetUrl(name)},
			description = "AURA " .. tostring(name) .. " separator"
		}}
	}
end

local function formatLastSeenStatus(timestamp)
	local parsed = tonumber(timestamp)
	if parsed and parsed > 0 then
		return "<t:" .. tostring(math.floor(parsed)) .. ":R>"
	end
	return "*No registrada*"
end

local function buildLastSeenContainer(rarity)
	local style = LAST_SEEN_STYLES[rarity]
	local catalog = LAST_SEEN_CATALOG[rarity] or {}
	local lines = {}
	local registered = 0

	for _, entry in ipairs(catalog) do
		local timestamp = lastSeenState.entries[entry.key]
		if tonumber(timestamp) then
			registered = registered + 1
		end
		table.insert(
			lines,
			entry.emoji .. " **" .. entry.name .. "** — " .. formatLastSeenStatus(timestamp)
		)
	end

	return {
		type = 17,
		accent_color = style.color,
		components = {
			{
				type = 10,
				content = string.format(
					"## %s %s — Last Seen\n-# %d/%d registradas",
					style.emoji,
					rarity,
					registered,
					#catalog
				)
			},
			buildLastSeenSeparator(style.separator),
			{
				type = 10,
				content = table.concat(lines, "\n")
			},
			buildLastSeenSeparator(style.separator)
		}
	}
end

local function buildLastSeenPayload(referenceTime)
	local components = {
		{
			type = 10,
			content = "# 🥚 AURA — Last Seen"
		},
		buildLastSeenSeparator("glacian")
	}

	for _, rarity in ipairs(LAST_SEEN_RARITY_ORDER) do
		table.insert(components, buildLastSeenContainer(rarity))
	end

	table.insert(
		components,
		{
			type = 10,
			content = "-# AURA • AURA FAMILY X • Actualizado <t:"
				.. tostring(math.floor(tonumber(referenceTime) or os.time()))
				.. ":R>"
		}
	)

	return {
		flags = 32768,
		components = components
	}
end

local function getWebhookBaseUrl()
	return tostring(CONFIG.LastSeenWebhookURL or "")
		:gsub("%?.*$", "")
		:gsub("/+$", "")
end

local function isLastSeenWebhookConfigured()
	local url = getWebhookBaseUrl()
	return url ~= "" and not url:find("PASTE_", 1, true)
end

local function appendWebhookQuery(url, query)
	return url
		.. (url:find("?", 1, true) and "&" or "?")
		.. query
end

local function decodeWebhookResponse(response)
	local body = response and (response.Body or response.body)
	if type(body) == "table" then
		return body
	end
	if type(body) ~= "string" or body == "" then
		return nil
	end

	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(body)
	end)
	return ok and type(decoded) == "table" and decoded or nil
end

local function executeLastSeenRequest(method, url, payload, onDone)
	if not httpRequest then
		if onDone then onDone(false, 0, nil) end
		return
	end

	task.spawn(function()
		local requestOk, response = pcall(function()
			return httpRequest({
				Url = url,
				Method = method,
				Headers = {
					["Content-Type"] = "application/json",
					["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
				},
				Body = HttpService:JSONEncode(payload)
			})
		end)

		if not requestOk or not response then
			if onDone then onDone(false, 0, nil) end
			return
		end

		local statusCode = tonumber(response.StatusCode or response.Status) or 0
		local responseBody = decodeWebhookResponse(response)
		local ok = statusCode >= 200 and statusCode < 300
		if onDone then onDone(ok, statusCode, responseBody) end
	end)
end

local function upsertLastSeenMessage(payload, onDone)
	local baseUrl = getWebhookBaseUrl()
	local messageId = lastSeenState.messageId

	if messageId and messageId ~= "" then
		executeLastSeenRequest(
			"PATCH",
			appendWebhookQuery(baseUrl .. "/messages/" .. tostring(messageId), "with_components=true"),
			payload,
			function(ok, statusCode)
				if ok then
					if onDone then onDone(true) end
					return
				end

				-- Solo crea otro mensaje si el anterior ya no existe.
				-- Un error temporal no debe duplicar el Last Seen.
				if statusCode ~= 404 and statusCode ~= 10008 then
					if onDone then onDone(false) end
					return
				end

				lastSeenState.messageId = nil
				saveLastSeenState()
				upsertLastSeenMessage(payload, onDone)
			end
		)
		return
	end

	executeLastSeenRequest(
		"POST",
		appendWebhookQuery(baseUrl, "wait=true&with_components=true"),
		payload,
		function(ok, statusCode, responseBody)
			local newMessageId = responseBody and responseBody.id
			if ok and newMessageId then
				lastSeenState.messageId = tostring(newMessageId)
				saveLastSeenState()
				if onDone then onDone(true) end
				return
			end

			if onDone then onDone(false) end
		end
	)
end

local lastSeenUpdateInFlight = false
local lastSeenUpdateQueued = false

local function scheduleLastSeenUpdate()
	if not isLastSeenWebhookConfigured() then
		return
	end

	lastSeenUpdateQueued = true
	if lastSeenUpdateInFlight then return end

	lastSeenUpdateInFlight = true
	task.spawn(function()
		while lastSeenUpdateQueued do
			lastSeenUpdateQueued = false
			local finished = false
			local succeeded = false

			upsertLastSeenMessage(
				buildLastSeenPayload(os.time()),
				function(ok)
					succeeded = ok
					finished = true
				end
			)

			while not finished do
				task.wait()
			end

			if succeeded then
				updateStatus("LAST SEEN // UPDATED", Color3.fromRGB(151, 255, 204))
			else
				updateStatus("LAST SEEN // UPDATE FAILED", Color3.fromRGB(255, 92, 133))
			end
		end
		lastSeenUpdateInFlight = false
	end)
end

local function recordLastSeenSpawn(text, spawnedAt)
	local rarity = getLastSeenRarity(text)
	if not rarity then return end

	local entry = findLastSeenEntry(text, rarity)
	if not entry then return end

	local timestamp = tonumber(spawnedAt) or os.time()
	local previous = tonumber(lastSeenState.entries[entry.key])
	if previous and previous >= timestamp then return end

	lastSeenState.entries[entry.key] = timestamp
	saveLastSeenState()
	scheduleLastSeenUpdate()
end

-- Envío individual y secuencial: cada huevo conserva su propio webhook.
local function fireWebhookImmediate(description, onDone)
sendWebhookPayload(
{content = description},
"WEBHOOK RELEASE // SENT",
		onDone
	)
end

local function isDivineOrImportantEternal(text)
	local lower = text:lower()
	if lower:find("divine", 1, true) then
		return true
	end

	if not lower:find("eternal", 1, true) then
		return false
	end

	for _, keyword in ipairs(CONFIG.ImportantEternalKeywords) do
		if lower:find(keyword, 1, true) then
			return true
		end
	end

	return false
end

local function getRandomPublicServerUrl()
	local currentServerId = tostring(game.JobId or "")
	local candidates = {}

	for _, serverId in ipairs(cachedPublicServerIds) do
		if serverId ~= currentServerId and serverId ~= lastJoinServerId then
			table.insert(candidates, serverId)
		end
	end

	if #candidates == 0 then
		return nil
	end

	local selectedServerId = candidates[math.random(1, #candidates)]
	lastJoinServerId = selectedServerId

	return string.format(
		"https://www.roblox.com/games/start?placeId=%s&gameId=%s",
		tostring(game.PlaceId),
		selectedServerId
	)
end

local function refreshPublicServerCache()
	if not httpRequest or not game.PlaceId or serverCacheRefreshing then
		return
	end

	serverCacheRefreshing = true
	local serverListUrl = string.format(
		"https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=2&excludeFullGames=true&limit=100",
		tostring(game.PlaceId)
	)

	local requestOk, response = pcall(function()
		return httpRequest({
			Url = serverListUrl,
			Method = "GET",
			Headers = {
				["Accept"] = "application/json"
			}
		})
	end)

	if requestOk and response then
		local statusCode = tonumber(response.StatusCode or response.Status) or 0
		local rawBody = response.Body or response.body

		if statusCode >= 200 and statusCode < 300
			and type(rawBody) == "string"
			and rawBody ~= "" then
			local decodeOk, serverData = pcall(function()
				return HttpService:JSONDecode(rawBody)
			end)

			if decodeOk and type(serverData) == "table" and type(serverData.data) == "table" then
				local refreshedIds = {}
				for _, server in ipairs(serverData.data) do
					local serverId = type(server) == "table" and server.id
					local playing = type(server) == "table" and tonumber(server.playing)
					local maxPlayers = type(server) == "table" and tonumber(server.maxPlayers)
					local hasRoom = not playing or not maxPlayers or playing < maxPlayers

					if type(serverId) == "string"
						and serverId ~= ""
						and hasRoom then
						table.insert(refreshedIds, serverId)
					end
				end

				if #refreshedIds > 0 then
					cachedPublicServerIds = refreshedIds
				end
			end
		end
	end

	serverCacheRefreshing = false
end

local function getGameFallbackUrl()
	if not game.PlaceId then
		return nil
	end

	return string.format(
		"https://www.roblox.com/games/start?placeId=%s",
		tostring(game.PlaceId)
	)
end

task.spawn(function()
	while screenGui.Parent do
		refreshPublicServerCache()
		task.wait(CONFIG.ServerRefreshInterval)
	end
end)

local function sendEggAlert(description, sourceText, onDone)
	task.spawn(function()
		local payload = {
			content = description
		}

		-- Permite explícitamente solo el rol que aparece en este mensaje.
		-- Sin esto Discord puede mostrar el texto de la mención sin notificar.
		local roleIds = {}
		local seenRoleIds = {}
		for roleId in description:gmatch("<@&(%d+)>") do
			if not seenRoleIds[roleId] then
				seenRoleIds[roleId] = true
				table.insert(roleIds, roleId)
			end
		end

		if #roleIds > 0 then
			payload.allowed_mentions = {
				roles = roleIds
			}
		end

		local joinUrl = getRandomPublicServerUrl() or getGameFallbackUrl()
		if joinUrl then
			payload.components = {{
				type = 1,
				components = {{
					type = 2,
					style = 5,
					label = "¡JOIN NOW!",
					emoji = {name = "🔗"},
					url = joinUrl
				}}
			}}
		end

sendWebhookPayload(payload, "WEBHOOK RELEASE // SENT", onDone)
	end)
end

local function trimText(text)
	return (tostring(text):gsub("^%s+", ""):gsub("%s+$", ""))
end

sendAnnouncementButton.MouseButton1Click:Connect(function()
	local title = trimText(announcementTitle.Text)
	local description = trimText(announcementBody.Text)

	if description == "" then
		updateStatus("ANNOUNCER // MESSAGE REQUIRED", Color3.fromRGB(255, 111, 151))
		return
	end

	if title == "" then
			title = "ANNOUNCEMENT"
	end

	sendAnnouncementButton.Text = "DISPATCHING EMBED..."
	updateStatus("ANNOUNCER // DISPATCHING EMBED", Color3.fromRGB(214, 165, 255))

	local embedPayload = {
		embeds = {{
			title = title,
			description = description,
			color = 0xA855F7,
			timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
			footer = {
				text = CONFIG.Version .. "  //  AURA ANNOUNCER"
			}
		}}
	}

	sendWebhookPayload(embedPayload, "ANNOUNCER // EMBED SENT", function(success)
		if success then
			sendAnnouncementButton.Text = "SENT [OK]  // SEND ANOTHER"
			announcementBody.Text = ""
		else
			sendAnnouncementButton.Text = "RETRY EMBED  >  WEBHOOK"
		end
	end)
end)

-- ALERTA DE INICIO INMEDIATA
task.spawn(function()
	fireWebhookImmediate("**HELLO AURA FAMILY X, I'M READY;)**")
end)

local function formatEggAlert(text, spawnedAt)
local message = replaceRarityWithMention(text)
local eggMentioned
message, eggMentioned = replaceEggNameWithMention(message)
local rolePrefix, body = message:match("^(%s*A%s+<@&%d+>)%s+(.+)$")

if rolePrefix and body then
message = rolePrefix .. " — " .. body
else
local article, plainBody = message:match("^(%s*A)%s+(.+)$")
if article and plainBody then
message = article .. (eggMentioned and " " or " @") .. plainBody
end
end

return string.format(
"> ❗%s\n———\n-# **Spawned: <t:%d:R>**",
message,
tonumber(spawnedAt) or os.time()
)
end

local function sendPriorityQueue(queue, index)
	if index > #queue then
		updateStatus("MONITOR // READY", Color3.fromRGB(99, 255, 154))
		return
	end

	updateStatus(
"WEBHOOK RELEASE // SEND " .. tostring(index) .. "/" .. tostring(#queue),
		Color3.fromRGB(214, 165, 255)
	)

	local egg = queue[index]
sendEggAlert(formatEggAlert(egg.text, egg.spawnedAt), egg.text, function()
		sendPriorityQueue(queue, index + 1)
	end)
end

local function flushPriorityQueue()
	if #pendingEggs == 0 then return end

	local queue = pendingEggs
	pendingEggs = {}
	priorityTimer = nil
	priorityVersion = priorityVersion + 1

	table.sort(queue, function(a, b)
		if a.rank == b.rank then
			return a.sequence < b.sequence
		end
		return a.rank < b.rank
	end)

	sendPriorityQueue(queue, 1)
end

local function queueEgg(text, sequence, spawnedAt)
	if not sequence then
		eggSequence = eggSequence + 1
		sequence = eggSequence
	end

	unreadCount = unreadCount + 1
	updateBadge()
	updateStatus("LOG // PRIORITY QUEUED", Color3.fromRGB(214, 165, 255))

	table.insert(pendingEggs, {
		text = text,
		rank = getRarityRank(text),
sequence = sequence,
spawnedAt = spawnedAt or os.time()
	})

	if #pendingEggs >= CONFIG.MaxPriorityQueue then
		flushPriorityQueue()
	elseif not priorityTimer then
		priorityVersion = priorityVersion + 1
		local version = priorityVersion
		priorityTimer = task.delay(CONFIG.PriorityWindow, function()
			if version == priorityVersion then
				flushPriorityQueue()
			end
		end)
	end
end

local function getVisualMeta(text)
	local lower = text:lower()

	if lower:find("system online", 1, true) or lower:find("ultra-hyper", 1, true) then
		return "SYSTEM", "SYSTEM ONLINE // LISTENING", Color3.fromRGB(151, 255, 204), "system"
	elseif lower:find("eternal", 1, true) then
		return "ETERNAL", "GREAT NEWS // ETERNAL EGG", Color3.fromRGB(255, 204, 76), "spark"
	elseif lower:find("divine", 1, true) then
		return "DIVINE", "GREAT NEWS // DIVINE EGG", Color3.fromRGB(255, 126, 226), "spark"
	elseif lower:find("secret", 1, true) then
		return "SECRET", "JACKPOT // SECRET EGG", Color3.fromRGB(192, 126, 255), "spark"
	elseif lower:find("mythical", 1, true) or lower:find("mythic", 1, true) then
		return "MYTHICAL", "AMAZING FIND // MYTHICAL EGG", Color3.fromRGB(102, 210, 255), "spark"
	elseif lower:find("legendary", 1, true) then
		return "LEGENDARY", "AMAZING FIND // LEGENDARY EGG", Color3.fromRGB(255, 159, 78), "spark"
	elseif lower:find("cosmic", 1, true) then
		return "COSMIC", "COSMIC FIND // EGG SPAWNED", Color3.fromRGB(131, 151, 255), "spark"
	end

	return "NORMAL", "GOOD NEWS // EGG SPAWNED", Color3.fromRGB(151, 255, 204), "egg"
end

local function createVisualCard(text, sequence)
	layoutCounter = layoutCounter + 1
	local rarityName, titleText, accentColor, iconKind = getVisualMeta(text)
	local card = Instance.new("Frame")
	if sequence then
		card.LayoutOrder = getRarityRank(text) * 100000 + sequence
	else
		card.LayoutOrder = 0
	end
	card.BackgroundColor3 = Color3.fromRGB(53, 31, 78)
	card.BorderSizePixel = 0
	card.Size = UDim2.new(1, 0, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.Parent = logPanel

	local cardScale = Instance.new("UIScale")
	cardScale.Scale = 0.96
	cardScale.Parent = card

	local stroke = Instance.new("UIStroke")
	stroke.Color = accentColor
	stroke.Thickness = 1.25
	stroke.Transparency = 0.2
	stroke.Parent = card
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = card
	
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 8), UDim.new(0, 8)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
	pad.Parent = card

	local accent = Instance.new("Frame")
	accent.BackgroundColor3 = accentColor
	accent.BorderSizePixel = 0
	accent.Position = UDim2.new(0, 4, 0, 7)
	accent.Size = UDim2.new(0, 3, 1, -14)
	accent.Parent = card

	local accentCorner = Instance.new("UICorner")
	accentCorner.CornerRadius = UDim.new(1, 0)
	accentCorner.Parent = accent

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.new(0, 34, 0, 8)
	title.Size = UDim2.new(1, -72, 0, 18)
	title.Font = Enum.Font.GothamBold
	title.Text = titleText
	title.TextColor3 = accentColor
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextSize = 12
	title.Parent = card

	createCanvasIcon(
		card,
		iconKind,
		accentColor,
		UDim2.new(0, 14, 0, 14),
		UDim2.new(0, 20, 0, 16)
	)
	
	local close = Instance.new("TextButton")
	close.BackgroundTransparency = 1
	close.AnchorPoint = Vector2.new(1, 0)
	close.Size = UDim2.new(0, 22, 0, 22)
	close.Position = UDim2.new(1, -4, 0, 3)
	close.Text = ""
	close.TextColor3 = Color3.fromRGB(255, 92, 133)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 12
	close.AutoButtonColor = false
	close.Parent = card

	createCanvasIcon(
		close,
		"close",
		Color3.fromRGB(255, 92, 133),
		UDim2.new(0, 12, 0, 12),
		UDim2.new(0.5, 0, 0.5, 0)
	)

	local meta = Instance.new("TextLabel")
	meta.BackgroundTransparency = 1
meta.Size = UDim2.new(1, -28, 0, 14)
meta.Position = UDim2.new(0, 14, 0, 20)
	meta.Font = Enum.Font.Code
	meta.Text = CONFIG.Version
		.. "  //  EVENT #"
		.. string.format("%03d", sequence or 0)
		.. "  //  PRIORITY "
		.. rarityName
	meta.TextColor3 = Color3.fromRGB(173, 145, 203)
	meta.TextSize = 9
	meta.TextXAlignment = Enum.TextXAlignment.Left
	meta.Parent = card

	local body = Instance.new("TextLabel")
	body.BackgroundTransparency = 1
body.Size = UDim2.new(1, -28, 0, 0)
body.Position = UDim2.new(0, 14, 0, 38)
	body.AutomaticSize = Enum.AutomaticSize.Y
	body.Font = Enum.Font.Code
	body.Text = text
	body.TextColor3 = Color3.fromRGB(240, 240, 240)
	body.TextSize = 10
	body.TextWrapped = true
	body.TextXAlignment = Enum.TextXAlignment.Left
	body.Parent = card

	card.BackgroundTransparency = 1
	meta.TextTransparency = 1
	body.TextTransparency = 1
	title.TextTransparency = 1
	TweenService:Create(
		card,
		TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{BackgroundTransparency = 0}
	):Play()
	TweenService:Create(
		cardScale,
		TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Scale = 1}
	):Play()
	TweenService:Create(
		meta,
		TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	):Play()
	TweenService:Create(
		body,
		TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	):Play()
	TweenService:Create(
		title,
		TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{TextTransparency = 0}
	):Play()

	if #activeCards >= CONFIG.MaxNotifications then
		local old = table.remove(activeCards, 1)
		if old then old:Destroy() end
	end
	table.insert(activeCards, card)

	local dead = false
	local function kill()
		if dead then return end
		dead = true
		removeCard(card)
		TweenService:Create(
			card,
			TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
			{BackgroundTransparency = 1}
		):Play()
		task.wait(0.12)
		card:Destroy()
	end
	close.MouseButton1Click:Connect(kill)
	task.delay(CONFIG.DisplayTime, kill)
	task.defer(function()
		refreshLogCanvas()
		local scrollY = math.max(0, logLayout.AbsoluteContentSize.Y - logPanel.AbsoluteWindowSize.Y + 20)
		logPanel.CanvasPosition = Vector2.new(0, scrollY)
	end)
end

local function processText(raw)
	local clean = cleanText(raw)
	if clean == "" then return end
	local lower = clean:lower()

	for _, bad in ipairs(CONFIG.Blacklist) do
		if lower:find(bad, 1, true) then return end
	end

	local hits = 0
	for _, good in ipairs(CONFIG.Keywords) do
		if lower:find(good, 1, true) then hits = hits + 1 end
	end
	
	if hits >= 2 or (lower:find("egg") and lower:find("spawn")) then
		local now = tick()
		if clean == lastText and (now - lastTime) < 0.5 then return end
		lastText, lastTime = clean, now

		eggSequence = eggSequence + 1
local spawnedAt = os.time()
		recordLastSeenSpawn(clean, spawnedAt)
createVisualCard(clean, eggSequence)
queueEgg(clean, eggSequence, spawnedAt)
	end
end

LogService.MessageOut:Connect(function(msg) processText(msg) end)
TextChatService.MessageReceived:Connect(function(msg) if msg.Text then processText(msg.Text) end end)

createVisualCard("SYSTEM ONLINE\nListening to game logs // instant alerts enabled.")
updateStatus("Ready", Color3.fromRGB(99, 255, 154))
scheduleLastSeenUpdate()
print(":: EGG DETECTOR ULTRA-HYPER-VELOCITY READY ::")