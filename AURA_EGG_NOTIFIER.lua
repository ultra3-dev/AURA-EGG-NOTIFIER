
-- AURA EGG 2.2.8 ULTRA // BOOT + UI
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
 EggKeywords = {"egg", "huevo"},
 SpawnKeywords = {"spawn", "appear", "aparecid", "hatch", "found"},
 Blacklist = {"[debug]", "eggtooldisplay", "placedeggrenderer", "guard", "trace", "anticheat", "jobid", "infinite yield possible", "waitforchild"},
 DisplayTime = 120,
 MaxNotifications = 2000,
ConsoleMaxLines = 600,
 PriorityWindow = 0.121,
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
Version = "2.2.8"
}

local ACCESS_STATE_FILE = "AuraEggNotifier_Access.json"

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
local lastSeenState
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
local configSelectedKey = nil

if playerGui:FindFirstChild("EggDetectorStealth") then
 playerGui.EggDetectorStealth:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EggDetectorStealth"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = 9999
screenGui.IgnoreGuiInset = false
screenGui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "EggLogPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.new(0.5, 0, 0.5, 0)
panel.Size = UDim2.new(0, 880, 0, 540)
panel.BackgroundColor3 = Color3.fromRGB(8, 11, 23)
panel.BackgroundTransparency = 0.04
panel.BorderSizePixel = 0
panel.Parent = screenGui

local panelScale = Instance.new("UIScale")
panelScale.Scale = 1
panelScale.Parent = panel
auraRuntime.AURA_EGG_PANEL_TARGET_SCALE = 1

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 14)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(132, 78, 255)
panelStroke.Thickness = 1.5
panelStroke.Transparency = 0.08
panelStroke.Parent = panel

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 72)
topBar.BackgroundColor3 = Color3.fromRGB(17, 16, 39)
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

function createCanvasIcon(parent, kind, color, size, position, name)
 local root = Instance.new("Frame")
 root.Name = name or "CanvasIcon"
 root.AnchorPoint = Vector2.new(0.5, 0.5)
 root.Position = position or UDim2.new(0.5, 0, 0.5, 0)
 root.Size = size or UDim2.new(0, 18, 0, 18)
 root.BackgroundTransparency = 1
 root.BorderSizePixel = 0
 root.ZIndex = parent.ZIndex + 1
 root.Parent = parent

local emojiByKind = {
close = "❌",
egg = "🥚",
log = "📜",
announce = "📣",
spark = "✨",
money = "💰",
megaphone = "📢",
system = "🟢",
console = "🖥️",
sliders = "🎚️",
webhook = "🔗",
terminal = "💻",
check = "✅",
plus = "➕",
trash = "🗑️",
send = "📤",
link = "🔗",
tag = "🏷️",
copy = "📋",
clock = "🕒",
route = "🔀",
broom = "🧹",
endpoint = "📍",
power = "🔐",
down = "⬇️"
}

local emoji = Instance.new("TextLabel")
emoji.Name = "CanvasEmoji"
emoji.AnchorPoint = Vector2.new(0.5, 0.5)
emoji.Position = UDim2.new(0.5, 0, 0.5, 0)
emoji.Size = UDim2.new(1, 0, 1, 0)
emoji.BackgroundTransparency = 1
emoji.BorderSizePixel = 0
emoji.Text = emojiByKind[kind] or "•"
emoji.TextColor3 = color
emoji.Font = Enum.Font.GothamBold
emoji.TextScaled = false
emoji.TextSize = math.max(12, math.floor(((size and size.Y.Offset) or 18) * 0.95))
emoji.TextWrapped = false
emoji.TextXAlignment = Enum.TextXAlignment.Center
emoji.TextYAlignment = Enum.TextYAlignment.Center
emoji.TextStrokeTransparency = 1
emoji.ZIndex = root.ZIndex
emoji:SetAttribute("CanvasPart", true)
emoji.Parent = root

 return root
end

function tintCanvasIcon(root, color)
 for _, item in ipairs(root:GetDescendants()) do
 if item:GetAttribute("CanvasPart") then
if item:IsA("TextLabel") then
item.TextColor3 = color
elseif item:IsA("Frame") then
item.BackgroundColor3 = color
elseif item:IsA("UIStroke") then
item.Color = color
 end
 end
 end
end

local header = Instance.new("TextLabel")
header.Name = "Header"
header.Position = UDim2.new(0, 68, 0, 8)
header.Size = UDim2.new(1, -230, 0, 24)
header.BackgroundTransparency = 1
header.Text = "AURA EGG NOTIFIER // v" .. CONFIG.Version
header.TextColor3 = Color3.fromRGB(247, 242, 255)
header.Font = Enum.Font.GothamBold
header.TextSize = 22
header.TextXAlignment = Enum.TextXAlignment.Left
header.Parent = topBar

local subtitle = Instance.new("TextLabel")
subtitle.Position = UDim2.new(0, 70, 0, 36)
subtitle.Size = UDim2.new(1, -230, 0, 16)
subtitle.BackgroundTransparency = 1
subtitle.Text = "SYSTEM VERSION: " .. CONFIG.Version .. " // BY: ULTRA3_DEV"
subtitle.TextColor3 = Color3.fromRGB(169, 148, 224)
subtitle.Font = Enum.Font.Code
subtitle.TextSize = 16
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
panelClose.TextSize = 26
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

local liveChip = Instance.new("Frame")
liveChip.Name = "SystemLiveChip"
liveChip.AnchorPoint = Vector2.new(1, 0)
liveChip.Position = UDim2.new(1, -62, 0, 14)
liveChip.Size = UDim2.new(0, 70, 0, 24)
liveChip.BackgroundColor3 = Color3.fromRGB(14, 38, 47)
liveChip.BorderSizePixel = 0
liveChip.Parent = topBar
local liveChipCorner = Instance.new("UICorner")
liveChipCorner.CornerRadius = UDim.new(1, 0)
liveChipCorner.Parent = liveChip
local liveChipStroke = Instance.new("UIStroke")
liveChipStroke.Color = Color3.fromRGB(70, 222, 174)
liveChipStroke.Thickness = 1
liveChipStroke.Transparency = 0.45
liveChipStroke.Parent = liveChip
local liveChipDot = Instance.new("Frame")
liveChipDot.Name = "LiveDot"
liveChipDot.AnchorPoint = Vector2.new(0, 0.5)
liveChipDot.Position = UDim2.new(0, 8, 0.5, 0)
liveChipDot.Size = UDim2.new(0, 6, 0, 6)
liveChipDot.BackgroundColor3 = Color3.fromRGB(88, 255, 184)
liveChipDot.BorderSizePixel = 0
liveChipDot.Parent = liveChip
local liveChipDotCorner = Instance.new("UICorner")
liveChipDotCorner.CornerRadius = UDim.new(1, 0)
liveChipDotCorner.Parent = liveChipDot
local liveChipLabel = Instance.new("TextLabel")
liveChipLabel.Name = "LiveLabel"
liveChipLabel.Position = UDim2.new(0, 17, 0, 0)
liveChipLabel.Size = UDim2.new(1, -17, 1, 0)
liveChipLabel.BackgroundTransparency = 1
liveChipLabel.Text = "ONLINE"
liveChipLabel.TextColor3 = Color3.fromRGB(160, 255, 217)
liveChipLabel.Font = Enum.Font.GothamBold
liveChipLabel.TextSize = 15
liveChipLabel.TextXAlignment = Enum.TextXAlignment.Center
liveChipLabel.TextYAlignment = Enum.TextYAlignment.Center
liveChipLabel.Parent = liveChip

local topBarGradient = Instance.new("UIGradient")
topBarGradient.Color = ColorSequence.new({
 ColorSequenceKeypoint.new(0, Color3.fromRGB(17, 19, 47)),
 ColorSequenceKeypoint.new(0.56, Color3.fromRGB(22, 20, 55)),
 ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 26, 49))
})
topBarGradient.Rotation = 0
topBarGradient.Parent = topBar
local topBarStroke = Instance.new("UIStroke")
topBarStroke.Name = "HeaderStroke"
topBarStroke.Color = Color3.fromRGB(67, 79, 131)
topBarStroke.Thickness = 1
topBarStroke.Transparency = 0.52
topBarStroke.Parent = topBar

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
logJumpButton.Text = ""
logJumpButton.TextColor3 = Color3.fromRGB(255, 240, 255)
logJumpButton.Font = Enum.Font.GothamBold
logJumpButton.TextSize = 24
logJumpButton.AutoButtonColor = false
logJumpButton.ZIndex = 10
logJumpButton.Parent = panel

local logJumpCorner = Instance.new("UICorner")
logJumpCorner.CornerRadius = UDim.new(1, 0)
logJumpCorner.Parent = logJumpButton
createCanvasIcon(
logJumpButton,
"down",
Color3.fromRGB(255, 240, 255),
UDim2.new(0, 19, 0, 19),
UDim2.new(0.5, 0, 0.5, 0),
"JumpIcon"
)

local logBody = Instance.new("TextLabel")
logBody.Name = "PersistentEggHistory"
logBody.Position = UDim2.new(0, 10, 0, 58)
logBody.Size = UDim2.new(1, -20, 0, 0)
logBody.AutomaticSize = Enum.AutomaticSize.Y
logBody.BackgroundTransparency = 1
logBody.Text = ""
logBody.TextColor3 = Color3.fromRGB(240, 240, 240)
logBody.Font = Enum.Font.Code
logBody.TextSize = 16
logBody.TextWrapped = true
logBody.TextXAlignment = Enum.TextXAlignment.Left
logBody.TextYAlignment = Enum.TextYAlignment.Top
logBody.Parent = logPanel
logLayout.Parent = nil

local logHeader = Instance.new("TextLabel")
logHeader.Name = "LogSectionHeader"
logHeader.Position = UDim2.new(0, 38, 0, 8)
logHeader.Size = UDim2.new(1, -52, 0, 18)
logHeader.BackgroundTransparency = 1
logHeader.Text = "LIVE EGG MONITOR"
logHeader.TextColor3 = Color3.fromRGB(235, 240, 255)
logHeader.Font = Enum.Font.GothamBold
logHeader.TextSize = 17
logHeader.TextXAlignment = Enum.TextXAlignment.Left
logHeader.Parent = logPanel

local logMeta = Instance.new("TextLabel")
logMeta.Name = "LogSectionMeta"
logMeta.Position = UDim2.new(0, 38, 0, 28)
logMeta.Size = UDim2.new(1, -52, 0, 14)
logMeta.BackgroundTransparency = 1
logMeta.Text = "LATEST FIRST // DIVINE > ETERNAL > SECRET // BY: ULTRA3_DEV"
logMeta.TextColor3 = Color3.fromRGB(142, 171, 224)
logMeta.Font = Enum.Font.Code
logMeta.TextSize = 14
logMeta.TextXAlignment = Enum.TextXAlignment.Left
logMeta.Parent = logPanel

local logHeaderDivider = Instance.new("Frame")
logHeaderDivider.Name = "LogHeaderDivider"
logHeaderDivider.Position = UDim2.new(0, 10, 0, 48)
logHeaderDivider.Size = UDim2.new(1, -20, 0, 1)
logHeaderDivider.BackgroundColor3 = Color3.fromRGB(64, 80, 124)
logHeaderDivider.BackgroundTransparency = 0.45
logHeaderDivider.BorderSizePixel = 0
logHeaderDivider.Parent = logPanel

local function updateLogJumpVisibility()
 local maximum = math.max(0, logPanel.CanvasSize.Y.Offset - logPanel.AbsoluteWindowSize.Y)
 local current = logPanel.CanvasPosition.Y
 logJumpButton.Visible = logPanel.Visible
 and maximum > 120
 and current < maximum - 80
end

local function refreshLogCanvas()
 local contentHeight = math.max(logBody.AbsoluteSize.Y + 68, logPanel.AbsoluteWindowSize.Y + 1)
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
navigation.CanvasSize = UDim2.new(0, 598, 0, 0)
navigation.ScrollingEnabled = false
navigation.ScrollBarThickness = 0
navigation.ScrollingDirection = Enum.ScrollingDirection.X
navigation.ScrollingEnabled = true
navigation.BackgroundTransparency = 1
navigation.Parent = panel

local function styleTab(button, active)
 button.BackgroundColor3 = active
 and Color3.fromRGB(100, 63, 190)
 or Color3.fromRGB(15, 20, 37)
 button.TextColor3 = active
 and Color3.fromRGB(255, 255, 255)
 or Color3.fromRGB(157, 168, 198)

 local label = button:FindFirstChild("TabLabel")
 if label then
 label.TextColor3 = button.TextColor3
 end

 local icon = button:FindFirstChild("TabIcon")
 if icon then
 tintCanvasIcon(icon, button.TextColor3)
 end

 local gradient = button:FindFirstChild("TabGradient")
 if not gradient then
 gradient = Instance.new("UIGradient")
 gradient.Name = "TabGradient"
 gradient.Rotation = 90
 gradient.Parent = button
 end
 gradient.Color = active
 and ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(207, 220, 255))
 or ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(192, 204, 232))

 local stroke = button:FindFirstChild("TabStroke")
 if not stroke then
 stroke = Instance.new("UIStroke")
 stroke.Name = "TabStroke"
 stroke.Parent = button
 end
 stroke.Color = active and Color3.fromRGB(176, 137, 255) or Color3.fromRGB(43, 49, 72)
 stroke.Thickness = active and 1.25 or 1
 stroke.Transparency = active and 0.05 or 0.25

 local corner = button:FindFirstChildOfClass("UICorner")
 if not corner then
 corner = Instance.new("UICorner")
 corner.Parent = button
 end
 corner.CornerRadius = UDim.new(0, 8)
end

local logTab = Instance.new("TextButton")
logTab.Name = "LogTab"
logTab.Size = UDim2.new(0, 60, 1, 0)
logTab.BackgroundColor3 = Color3.fromRGB(122, 57, 177)
logTab.BorderSizePixel = 0
logTab.Text = ""
logTab.TextColor3 = Color3.fromRGB(255, 235, 255)
logTab.Font = Enum.Font.Code
logTab.TextSize = 18
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
logTabLabel.TextSize = 18
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
promotionTab.TextSize = 18
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
promotionTabLabel.TextSize = 16
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
announcerTab.TextSize = 18
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
announcerTabLabel.TextSize = 15
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
configUi.tab.TextSize = 18
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
configUi.tabLabel.TextSize = 15
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
configUi.webhookTab.TextSize = 18
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
configUi.webhookTabLabel.TextSize = 14
configUi.webhookTabLabel.TextXAlignment = Enum.TextXAlignment.Left
configUi.webhookTabLabel.TextYAlignment = Enum.TextYAlignment.Center
configUi.webhookTabLabel.Parent = configUi.webhookTab

configUi.webhookTabCorner = Instance.new("UICorner")
configUi.webhookTabCorner.CornerRadius = UDim.new(0, 6)
configUi.webhookTabCorner.Parent = configUi.webhookTab

configUi.shareTab = Instance.new("TextButton")
configUi.shareTab.Name = "ShareTab"
configUi.shareTab.Position = UDim2.new(0, 398, 0, 0)
configUi.shareTab.Size = UDim2.new(0, 100, 1, 0)
configUi.shareTab.BackgroundColor3 = Color3.fromRGB(57, 34, 80)
configUi.shareTab.BorderSizePixel = 0
configUi.shareTab.Text = ""
configUi.shareTab.TextColor3 = Color3.fromRGB(137, 160, 198)
configUi.shareTab.Font = Enum.Font.Code
configUi.shareTab.TextSize = 18
configUi.shareTab.TextXAlignment = Enum.TextXAlignment.Center
configUi.shareTab.TextYAlignment = Enum.TextYAlignment.Center
configUi.shareTab.AutoButtonColor = false
configUi.shareTab.Parent = navigation

configUi.shareTabIcon = createCanvasIcon(
configUi.shareTab,
"copy",
configUi.shareTab.TextColor3,
UDim2.new(0, 16, 0, 16),
UDim2.new(0, 15, 0.5, 0),
"TabIcon"
)
configUi.shareTabLabel = Instance.new("TextLabel")
configUi.shareTabLabel.Name = "TabLabel"
configUi.shareTabLabel.Position = UDim2.new(0, 30, 0, 0)
configUi.shareTabLabel.Size = UDim2.new(1, -34, 1, 0)
configUi.shareTabLabel.BackgroundTransparency = 1
configUi.shareTabLabel.Text = "BACKUP"
configUi.shareTabLabel.TextColor3 = configUi.shareTab.TextColor3
configUi.shareTabLabel.Font = Enum.Font.Code
configUi.shareTabLabel.TextSize = 15
configUi.shareTabLabel.TextXAlignment = Enum.TextXAlignment.Left
configUi.shareTabLabel.TextYAlignment = Enum.TextYAlignment.Center
configUi.shareTabLabel.Parent = configUi.shareTab

configUi.shareTabCorner = Instance.new("UICorner")
configUi.shareTabCorner.CornerRadius = UDim.new(0, 6)
configUi.shareTabCorner.Parent = configUi.shareTab

local consoleTab = Instance.new("TextButton")
consoleTab.Name = "ConsoleTab"
consoleTab.Position = UDim2.new(0, 504, 0, 0)
consoleTab.Size = UDim2.new(0, 92, 1, 0)
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
UDim2.new(0, 15, 0.5, 0),
 "TabIcon"
)

local consoleTabLabel = Instance.new("TextLabel")
consoleTabLabel.Name = "TabLabel"
consoleTabLabel.Position = UDim2.new(0, 30, 0, 0)
consoleTabLabel.Size = UDim2.new(1, -34, 1, 0)
consoleTabLabel.BackgroundTransparency = 1
consoleTabLabel.Text = "CONSOLE"
consoleTabLabel.TextColor3 = consoleTab.TextColor3
consoleTabLabel.Font = Enum.Font.Code
consoleTabLabel.TextSize = 15
consoleTabLabel.TextXAlignment = Enum.TextXAlignment.Left
consoleTabLabel.TextYAlignment = Enum.TextYAlignment.Center
consoleTabLabel.Parent = consoleTab

local consoleTabCorner = Instance.new("UICorner")
consoleTabCorner.CornerRadius = UDim.new(0, 6)
consoleTabCorner.Parent = consoleTab

configUi.sharePanel = Instance.new("Frame")
configUi.sharePanel.Name = "PortableBackupPanel"
configUi.sharePanel.Position = UDim2.new(0, 12, 0, 100)
configUi.sharePanel.Size = UDim2.new(1, -24, 1, -150)
configUi.sharePanel.BackgroundColor3 = Color3.fromRGB(9, 15, 32)
configUi.sharePanel.BorderSizePixel = 0
configUi.sharePanel.Visible = false
configUi.sharePanel.Parent = panel

configUi.sharePanelCorner = Instance.new("UICorner")
configUi.sharePanelCorner.CornerRadius = UDim.new(0, 12)
configUi.sharePanelCorner.Parent = configUi.sharePanel

configUi.shareHeader = Instance.new("TextLabel")
configUi.shareHeader.Position = UDim2.new(0, 36, 0, 12)
configUi.shareHeader.Size = UDim2.new(1, -50, 0, 20)
configUi.shareHeader.BackgroundTransparency = 1
configUi.shareHeader.Text = "BACKUP // PORTABLE CONFIGURATION"
configUi.shareHeader.TextColor3 = Color3.fromRGB(240, 225, 255)
configUi.shareHeader.Font = Enum.Font.GothamBold
configUi.shareHeader.TextSize = 18
configUi.shareHeader.TextXAlignment = Enum.TextXAlignment.Left
configUi.shareHeader.Parent = configUi.sharePanel

configUi.shareHelp = Instance.new("TextLabel")
configUi.shareHelp.Position = UDim2.new(0, 14, 0, 36)
configUi.shareHelp.Size = UDim2.new(1, -28, 0, 30)
configUi.shareHelp.BackgroundTransparency = 1
configUi.shareHelp.Text = "SAFE BACKUP // PET DATABASE + LAST SEEN + PROMOTION // WEBHOOKS AND KEYS EXCLUDED"
configUi.shareHelp.TextColor3 = Color3.fromRGB(151, 255, 204)
configUi.shareHelp.Font = Enum.Font.Code
configUi.shareHelp.TextSize = 14
configUi.shareHelp.TextWrapped = true
configUi.shareHelp.TextXAlignment = Enum.TextXAlignment.Left
configUi.shareHelp.Parent = configUi.sharePanel

configUi.shareInput = Instance.new("TextBox")
configUi.shareInput.Name = "PortableBackupText"
configUi.shareInput.Position = UDim2.new(0, 10, 0, 72)
configUi.shareInput.Size = UDim2.new(1, -20, 0, 104)
configUi.shareInput.BackgroundColor3 = Color3.fromRGB(15, 22, 40)
configUi.shareInput.BorderSizePixel = 0
configUi.shareInput.ClearTextOnFocus = false
configUi.shareInput.MultiLine = true
configUi.shareInput.PlaceholderText = "Exporta aquí tu backup seguro o pega un backup recibido..."
configUi.shareInput.PlaceholderColor3 = Color3.fromRGB(139, 143, 167)
configUi.shareInput.Text = ""
configUi.shareInput.TextColor3 = Color3.fromRGB(245, 242, 255)
configUi.shareInput.Font = Enum.Font.Code
configUi.shareInput.TextSize = 14
configUi.shareInput.TextWrapped = true
configUi.shareInput.TextXAlignment = Enum.TextXAlignment.Left
configUi.shareInput.TextYAlignment = Enum.TextYAlignment.Top
configUi.shareInput.Parent = configUi.sharePanel

configUi.shareStatus = Instance.new("TextLabel")
configUi.shareStatus.Position = UDim2.new(0, 14, 0, 218)
configUi.shareStatus.Size = UDim2.new(1, -28, 0, 28)
configUi.shareStatus.BackgroundTransparency = 1
configUi.shareStatus.Text = "STATUS // READY // NO WEBHOOKS IN BACKUP"
configUi.shareStatus.TextColor3 = Color3.fromRGB(255, 193, 89)
configUi.shareStatus.Font = Enum.Font.Code
configUi.shareStatus.TextSize = 14
configUi.shareStatus.TextWrapped = true
configUi.shareStatus.TextXAlignment = Enum.TextXAlignment.Left
configUi.shareStatus.Parent = configUi.sharePanel

configUi.exportBackupButton = Instance.new("TextButton")
configUi.exportBackupButton.Name = "ExportBackup"
configUi.exportBackupButton.Position = UDim2.new(0, 10, 0, 184)
configUi.exportBackupButton.Size = UDim2.new(0.5, -15, 0, 29)
configUi.exportBackupButton.BackgroundColor3 = Color3.fromRGB(0, 132, 255)
configUi.exportBackupButton.BorderSizePixel = 0
configUi.exportBackupButton.Text = "EXPORT // COPY"
configUi.exportBackupButton.TextColor3 = Color3.fromRGB(255, 245, 255)
configUi.exportBackupButton.Font = Enum.Font.GothamBold
configUi.exportBackupButton.TextSize = 15
configUi.exportBackupButton.AutoButtonColor = false
configUi.exportBackupButton.Parent = configUi.sharePanel

configUi.importBackupButton = Instance.new("TextButton")
configUi.importBackupButton.Name = "ImportBackup"
configUi.importBackupButton.Position = UDim2.new(0.5, 5, 0, 184)
configUi.importBackupButton.Size = UDim2.new(0.5, -15, 0, 29)
configUi.importBackupButton.BackgroundColor3 = Color3.fromRGB(75, 62, 120)
configUi.importBackupButton.BorderSizePixel = 0
configUi.importBackupButton.Text = "IMPORT // APPLY"
configUi.importBackupButton.TextColor3 = Color3.fromRGB(245, 235, 255)
configUi.importBackupButton.Font = Enum.Font.GothamBold
configUi.importBackupButton.TextSize = 15
configUi.importBackupButton.AutoButtonColor = false
configUi.importBackupButton.Parent = configUi.sharePanel

configUi.shareInputCorner = Instance.new("UICorner")
configUi.shareInputCorner.CornerRadius = UDim.new(0, 8)
configUi.shareInputCorner.Parent = configUi.shareInput

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
announcementHeader.TextSize = 16
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
announcementTitle.TextSize = 18
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
announcementBody.TextSize = 17
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
announcementHint.Text = "EMBED // PURPLE CHANNEL // READY TO DISPATCH"
announcementHint.TextColor3 = Color3.fromRGB(151, 255, 204)
announcementHint.Font = Enum.Font.Code
announcementHint.TextSize = 14
announcementHint.TextXAlignment = Enum.TextXAlignment.Left
announcementHint.Parent = announcementPanel

local sendAnnouncementButton = Instance.new("TextButton")
sendAnnouncementButton.Name = "SendAnnouncement"
sendAnnouncementButton.Position = UDim2.new(0, 10, 0, 153)
sendAnnouncementButton.Size = UDim2.new(1, -20, 0, 28)
sendAnnouncementButton.BackgroundColor3 = Color3.fromRGB(122, 57, 177)
sendAnnouncementButton.BorderSizePixel = 0
sendAnnouncementButton.Text = "DISPATCH EMBED // WEBHOOK"
sendAnnouncementButton.TextColor3 = Color3.fromRGB(255, 240, 255)
sendAnnouncementButton.Font = Enum.Font.GothamBold
sendAnnouncementButton.TextSize = 17
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
promotionHeader.TextSize = 16
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
promotionUrlBox.TextSize = 16
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
promotionLabelBox.TextSize = 16
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
promotionUsesBox.TextSize = 15
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
promotionEmojiBox.TextSize = 16
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
promotionRarityButton.TextSize = 15
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
promotionIntervalBox.TextSize = 15
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
promotionHint.TextSize = 14
promotionHint.TextXAlignment = Enum.TextXAlignment.Left
promotionHint.Parent = promotionPanel

local savePromotionButton = Instance.new("TextButton")
savePromotionButton.Name = "SavePromotion"
savePromotionButton.Position = UDim2.new(0, 10, 0, 215)
savePromotionButton.Size = UDim2.new(1, -20, 0, 28)
savePromotionButton.BackgroundColor3 = Color3.fromRGB(122, 57, 177)
savePromotionButton.BorderSizePixel = 0
savePromotionButton.Text = "SAVE PROMOTION // READY"
savePromotionButton.TextColor3 = Color3.fromRGB(255, 240, 255)
savePromotionButton.Font = Enum.Font.GothamBold
savePromotionButton.TextSize = 16
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
configUi.header.Text = "PET REGISTRY // CONFIGURATION"
configUi.header.TextColor3 = Color3.fromRGB(240, 225, 255)
configUi.header.Font = Enum.Font.GothamBold
configUi.header.TextSize = 18
configUi.header.TextXAlignment = Enum.TextXAlignment.Left
configUi.header.Parent = configUi.panel

configUi.help = Instance.new("TextLabel")
configUi.help.Position = UDim2.new(0, 14, 0, 30)
configUi.help.Size = UDim2.new(1, -28, 0, 14)
configUi.help.BackgroundTransparency = 1
configUi.help.Text = "CURRENT PETS // CLICK TO EDIT // SAVED LOCALLY"
configUi.help.TextColor3 = Color3.fromRGB(151, 255, 204)
configUi.help.Font = Enum.Font.Code
configUi.help.TextSize = 14
configUi.help.TextXAlignment = Enum.TextXAlignment.Left
configUi.help.Parent = configUi.panel

configUi.list = Instance.new("ScrollingFrame")
configUi.list.Name = "PetRegistry"
configUi.list.Position = UDim2.new(0, 10, 0, 49)
configUi.list.Size = UDim2.new(1, -20, 0, 72)
configUi.list.BackgroundColor3 = Color3.fromRGB(5, 9, 20)
configUi.list.BorderSizePixel = 0
configUi.list.CanvasSize = UDim2.new(0, 0, 0, 0)
configUi.list.AutomaticCanvasSize = Enum.AutomaticSize.Y
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
configUi.nameBox.PlaceholderText = "PET NAME // exact game text"
configUi.nameBox.PlaceholderColor3 = Color3.fromRGB(144, 121, 170)
configUi.nameBox.Text = ""
configUi.nameBox.TextColor3 = Color3.fromRGB(245, 235, 255)
configUi.nameBox.Font = Enum.Font.Code
configUi.nameBox.TextSize = 15
configUi.nameBox.TextXAlignment = Enum.TextXAlignment.Left
configUi.nameBox.Parent = configUi.panel

configUi.roleBox = Instance.new("TextBox")
configUi.roleBox.Name = "PetRoleId"
configUi.roleBox.Position = UDim2.new(0.5, 5, 0, 128)
configUi.roleBox.Size = UDim2.new(0.5, -15, 0, 27)
configUi.roleBox.BackgroundColor3 = Color3.fromRGB(17, 24, 48)
configUi.roleBox.BorderSizePixel = 0
configUi.roleBox.ClearTextOnFocus = false
configUi.roleBox.PlaceholderText = "ROLE ID // 123456789 or <@&123456789>"
configUi.roleBox.PlaceholderColor3 = Color3.fromRGB(144, 121, 170)
configUi.roleBox.Text = ""
configUi.roleBox.TextColor3 = Color3.fromRGB(245, 235, 255)
configUi.roleBox.Font = Enum.Font.Code
configUi.roleBox.TextSize = 15
configUi.roleBox.TextXAlignment = Enum.TextXAlignment.Left
configUi.roleBox.Parent = configUi.panel

configUi.emojiBox = Instance.new("TextBox")
configUi.emojiBox.Name = "PetEmoji"
configUi.emojiBox.Position = UDim2.new(0, 10, 0, 159)
configUi.emojiBox.Size = UDim2.new(0.5, -15, 0, 27)
configUi.emojiBox.BackgroundColor3 = Color3.fromRGB(17, 24, 48)
configUi.emojiBox.BorderSizePixel = 0
configUi.emojiBox.ClearTextOnFocus = false
configUi.emojiBox.PlaceholderText = "EMOJI // <:Pet:id>"
configUi.emojiBox.PlaceholderColor3 = Color3.fromRGB(144, 121, 170)
configUi.emojiBox.Text = ""
configUi.emojiBox.TextColor3 = Color3.fromRGB(245, 235, 255)
configUi.emojiBox.Font = Enum.Font.Code
configUi.emojiBox.TextSize = 15
configUi.emojiBox.TextXAlignment = Enum.TextXAlignment.Left
configUi.emojiBox.Parent = configUi.panel

configUi.rarityButton = Instance.new("TextButton")
configUi.rarityButton.Name = "PetRarity"
configUi.rarityButton.Position = UDim2.new(0.5, 5, 0, 159)
configUi.rarityButton.Size = UDim2.new(0.5, -15, 0, 27)
configUi.rarityButton.BackgroundColor3 = Color3.fromRGB(17, 24, 48)
configUi.rarityButton.BorderSizePixel = 0
configUi.rarityButton.Text = "RAREZA: SECRET >"
configUi.rarityButton.TextColor3 = Color3.fromRGB(245, 235, 255)
configUi.rarityButton.Font = Enum.Font.Code
configUi.rarityButton.TextSize = 15
configUi.rarityButton.TextXAlignment =
…[truncated]
-- AURA EGG 2.2.8 ULTRA // DETECTION + CATALOG
-- Rango de mayor a menor rareza. Los empates conservan el orden detectado.
local function runNotifierRuntime()
local RARITY_ORDER = {
 {keyword = "divine", rank = 1, roleId = "1544734510665699389"},
 {keyword = "eternal", rank = 2, roleId = "1544734452054229173"},
 {keyword = "secret", rank = 3, roleId = "1544734376640782346"}
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

local EGG_ROLE_ID_SET = {}
for _, eggRole in ipairs(EGG_ROLE_MENTIONS) do
EGG_ROLE_ID_SET[eggRole.roleId] = true
end

-- Catálogo fijo del Last Seen. Se muestran todos los huevos conocidos:
-- los que todavía no tienen fecha quedan como "No registrada".
local LAST_SEEN_RARITY_ORDER = {"Divine", "Eternal", "Secret"}
local LAST_SEEN_STYLES = {
Divine = {
emoji = "<:Divine:1551677739411574794>",
 color = 0xFFD700,
 separator = "divine"
 },
 Eternal = {
 emoji = "<:Eternal:1551677658327162940>",
 color = 0x9B30FF,
 separator = "eternal"
 },
 Secret = {
 emoji = "<:Secret:1551677570389643395>",
 color = 0x010101,
 separator = "secret"
 }
}

local LAST_SEEN_ASSET_BASE_URL =
 "https://raw.githubusercontent.com/ultra3-dev/AURA-EGG-NOTIFIER/main/assets/"

local LAST_SEEN_CATALOG = {
 Divine = {
 {name = "Nightflame", key = "nightflame", emoji = "<:Nightflame:1551671258419044443>"},
 {name = "Unicorn", key = "unicorn", emoji = "<:Unicorn:1551671338048032898>"},
 {name = "World Burner", key = "worldburner", emoji = "<:World_Burner:1551671096422572222>"},
 {name = "Kitsune", key = "kitsune", emoji = "<:Kitsune:1551671214408204438>"},
 {name = "ArchAngel", key = "archangel", emoji = "<:ArchAngel:1551671132652839032>"}
 },
 Eternal = {
 {name = "El Maja", key = "elmaja", emoji = "<:El_Maja:1551670796710187128>"},
 {name = "Oni Tiger", key = "onitiger", emoji = "<:Oni_Tiger:1551670714241650698>"},
 {name = "Phoenix", key = "phoenix", emoji = "<:Phoenix:1551671600523386890>"},
 {name = "Gorilla King", key = "gorillaking", emoji = "<:Gorilla_King:1551670961906913280>"},
 {name = "Skeleton Horse", key = "skeletonhorse", emoji = "<:Skeleton_Horse:1551670754125283328>"},
 {name = "Lava Dragon", key = "lavadragon", emoji = "<:Lava_Dragon:1551670919846436975>"},
 {name = "Pegasus", key = "pegasus", emoji = "<:Pegasus:1551670885033836605>"},
 {name = "Mosasaurus", key = "mosasaurus", emoji = "<:Mosasaurus:1551671548019081316>"},
 {name = "Eternal Lunar Dragon", key = "eternallunardragon", emoji = "<:Eternal_Lunar_Dragon:1551671047118528683>"},
 {name = "Ice Dragon", key = "icedragon", emoji = "<:Ice_Dragon:1551670998003351682>"}
 },
 Secret = {
 {name = "Stag", key = "stag", emoji = "<:Stag:1551670264050352188>"},
 {name = "Pure Jellyfish", key = "purejellyfish", emoji = "<:Pure_Jellyfish:1551670502186291241>"},
 {name = "RazorFang", key = "razorfang", emoji = "<:RazorFang:1551670065387020359>"},
 {name = "Gargoyle", key = "gargoyle", emoji = "<:Gargoyle:1551670608280944640>"},
 {name = "Cosmic Skeleton Boss", key = "cosmicskeletonboss", emoji = "<:Cosmic_Skeleton_Boss:1551670370203861102>"},
 {name = "Tralaledon", key = "tralaledon", emoji = "<:Tralaledon:1551670147801026672>"},
 {name = "Cerberus", key = "cerberus", emoji = "<:Cerberus:1551670182680731709>"},
 {name = "Mutant Shark", key = "mutantshark", emoji = "<:MutantShark:1551670224493744258>"},
 {name = "Cosmic Dragon", key = "cosmicdragon", emoji = "<:Cosmic_Dragon:1551670415972241458>"},
 {name = "TRex", key = "trex", emoji = "<:TRex:1551670552232595618>"},
 {name = "Yeti", key = "yeti", emoji = "<:Yeti:1551670658897940481>"},
 {name = "Kraken", key = "kraken", emoji = "<:Kraken:1551670466090111027>"},
 {name = "Centaur", key = "centaur", emoji = "<:Centaur:1551670291749670922>"},
 {name = "King Snake", key = "kingsnake", emoji = "<:King_Snake:1551670106675879936>"}
 }
}

local BASE_LAST_SEEN_RARITY_ORDER = {}
for _, rarity in ipairs(LAST_SEEN_RARITY_ORDER) do
 table.insert(BASE_LAST_SEEN_RARITY_ORDER, rarity)
end

local BASE_LAST_SEEN_CATALOG = {}
for rarity, entries in pairs(LAST_SEEN_CATALOG) do
 BASE_LAST_SEEN_CATALOG[rarity] = {}
 for _, entry in ipairs(entries) do
 BASE_LAST_SEEN_CATALOG[rarity][#BASE_LAST_SEEN_CATALOG[rarity] + 1] = {
 name = entry.name, key = entry.key, emoji = entry.emoji
 }
 end
end

local BASE_EGG_ROLE_MENTIONS = {}
for _, entry in ipairs(EGG_ROLE_MENTIONS) do
 BASE_EGG_ROLE_MENTIONS[#BASE_EGG_ROLE_MENTIONS + 1] = {
 name = entry.name, roleId = entry.roleId
 }
end

function rebuildConfiguredCatalog()
 for rarity in pairs(LAST_SEEN_CATALOG) do
 LAST_SEEN_CATALOG[rarity] = nil
 end
 for _, rarity in ipairs(BASE_LAST_SEEN_RARITY_ORDER) do
 LAST_SEEN_CATALOG[rarity] = {}
 for _, entry in ipairs(BASE_LAST_SEEN_CATALOG[rarity] or {}) do
 LAST_SEEN_CATALOG[rarity][#LAST_SEEN_CATALOG[rarity] + 1] = {
 name = entry.name, key = entry.key, emoji = entry.emoji
 }
 end
 end
 for rarity in pairs(LAST_SEEN_STYLES) do
 local isBase = false
 for _, baseRarity in ipairs(BASE_LAST_SEEN_RARITY_ORDER) do
 if baseRarity == rarity then isBase = true break end
 end
 if not isBase then LAST_SEEN_STYLES[rarity] = nil end
 end
 LAST_SEEN_RARITY_ORDER = {}
 for _, rarity in ipairs(BASE_LAST_SEEN_RARITY_ORDER) do
 table.insert(LAST_SEEN_RARITY_ORDER, rarity)
 end
 for index = #EGG_ROLE_MENTIONS, 1, -1 do
 table.remove(EGG_ROLE_MENTIONS, index)
 end
 for _, entry in ipairs(BASE_EGG_ROLE_MENTIONS) do
 EGG_ROLE_MENTIONS[#EGG_ROLE_MENTIONS + 1] = {name = entry.name, roleId = entry.roleId}
 end
 for roleId in pairs(EGG_ROLE_ID_SET) do EGG_ROLE_ID_SET[roleId] = nil end
 for _, entry in ipairs(EGG_ROLE_MENTIONS) do EGG_ROLE_ID_SET[entry.roleId] = true end

 for _, configured in ipairs(configState.entries) do
 local rarity = configured.rarity
 local key = configured.key
 if not LAST_SEEN_CATALOG[rarity] then
 LAST_SEEN_CATALOG[rarity] = {}
 table.insert(LAST_SEEN_RARITY_ORDER, rarity)
 LAST_SEEN_STYLES[rarity] = {emoji = "◈", color = 0xB48CFF, separator = ""}
 end
 for currentRarity, entries in pairs(LAST_SEEN_CATALOG) do
 for index = #entries, 1, -1 do
 if entries[index].key == key then table.remove(entries, index) end
 end
 end
 table.insert(LAST_SEEN_CATALOG[rarity], {
 name = configured.name, key = key, emoji = configured.emoji
 })
 for index = #EGG_ROLE_MENTIONS, 1, -1 do
 if EGG_ROLE_MENTIONS[index].name:lower():gsub("[^a-z0-9]", "") == key then
 table.remove(EGG_ROLE_MENTIONS, index)
 end
 end
 table.insert(EGG_ROLE_MENTIONS, {name = configured.name, roleId = configured.roleId})
 EGG_ROLE_ID_SET[configured.roleId] = true
 end
end

rebuildConfiguredCatalog()

local EGG_EMOJI_BY_KEY = {}
for _, rarityEntries in pairs(LAST_SEEN_CATALOG) do
 for _, entry in ipairs(rarityEntries) do
 EGG_EMOJI_BY_KEY[entry.key] = entry.emoji
 end
end

-- Estado inicial solicitado. Solo se aplica una vez; después los valores
-- quedan en AuraEggNotifier_LastSeen.json y cada spawn nuevo los reemplaza.
local LAST_SEEN_INITIAL_TIMES = {
 kitsune = 1790161802,
 worldburner = 1790247303,
 nightflame = 1790241903,
 unicorn = 1789980058,
 archangel = 1789440624,

 mosasaurus = 1790262603,
 onitiger = 1790265003,
 elmaja = 1790202602,
 gorillaking = 1790237703,
 eternallunardragon = 1790258402,
 icedragon = 1790248503,
 skeletonhorse = 1790262903,
 lavadragon = 1790116272,
 pegasus = 1790112971,
 phoenix = 1790251504,

 razorfang = 1790265302,
 kraken = 1790260803,
 tralaledon = 1790248503,
 cosmicskeletonboss = 1790256903,
 trex = 1790264103,
 purejellyfish = 1790267404,
 gargoyle = 1790264103,
 centaur = 1790264703,
 yeti = 1790267104,
 cosmicdragon = 1790264103,
 stag = 1790259903,
 mutantshark = 1790264703,
 cerberus = 1790265603,
 kingsnake = 1790227502
}

-- Baseline actualizado: solo se migra una vez a la versión 7.
local LAST_SEEN_INITIAL_TIMES_VERSION = 7
local LAST_SEEN_ACTIVE_WINDOW = 300

function seedLastSeenState()
 local needsInitialTimeMigration =
 tonumber(lastSeenState.seedVersion) ~= LAST_SEEN_INITIAL_TIMES_VERSION
 if lastSeenState.seeded and not needsInitialTimeMigration then return end

 for _, rarity in ipairs(LAST_SEEN_RARITY_ORDER) do
 for _, entry in ipairs(LAST_SEEN_CATALOG[rarity] or {}) do
 local existing = tonumber(lastSeenState.entries[entry.key])
 local initial = LAST_SEEN_INITIAL_TIMES[entry.key]
 if initial then
 if not lastSeenState.seeded then
 if existing == nil then
 lastSeenState.entries[entry.key] = initial
 end
 elseif needsInitialTimeMigration then
 -- Usa los nuevos valores sin retroceder una detección más reciente.
 lastSeenState.entries[entry.key] = math.max(existing or initial, initial)
 end
 end
 end
 end

 lastSeenState.seeded = true
 lastSeenState.seedVersion = LAST_SEEN_INITIAL_TIMES_VERSION
 saveLastSeenState()
end

local RARITY_EMOJI_BY_KEY = {
 divine = "<:Divine:1551677739411574794>",
 eternal = "<:Eternal:1551677658327162940>",
 secret = "<:Secret:1551677570389643395>"
}

local function getRarityEmoji(text)
 local lower = tostring(text or ""):lower()
 if lower:find("divine", 1, true) then return RARITY_EMOJI_BY_KEY.divine end
 if lower:find("eternal", 1, true) then return RARITY_EMOJI_BY_KEY.eternal end
 if lower:find("secret", 1, true) then return RARITY_EMOJI_BY_KEY.secret end
 return ""
end

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
.. "A **" .. text:sub(rarityStart, rarityEnd) .. "**"
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

local function getEggDisplayData(text)
local lower = tostring(text or ""):lower()
local selected = nil

for _, egg in ipairs(EGG_ROLE_MENTIONS) do
if lower:find(egg.name, 1, true)
and (not selected or #egg.name > #selected.name) then
selected = egg
end
end

if not selected then
return nil, nil
end

local eggKey = selected.name:lower():gsub("[^a-z0-9]", "")
return EGG_EMOJI_BY_KEY[eggKey], "<@&" .. selected.roleId .. ">"
end


-- AURA EGG 2.2.8 ULTRA // LAST SEEN + CONFIG SERVICES
local function getHttpStatusCode(response)
local rawStatus = response and (response.StatusCode or response.statusCode or response.Status)
local statusCode = tonumber(rawStatus)
if statusCode then
return statusCode
end

local numericStatus = tostring(rawStatus or ""):match("%d%d%d")
return tonumber(numericStatus) or 0
end

local getConfiguredMainWebhookUrl

local function sendWebhookPayload(payload, successText, onDone)
if scriptStopped then
if onDone then onDone(false) end
return
end

 if not httpRequest then
 updateStatus("HTTP unavailable", Color3.fromRGB(255, 92, 133))
 if onDone then onDone(false) end
 return
 end

 task.spawn(function()
if scriptStopped then
if onDone then onDone(false) end
return
end

 local webhookUrl = tostring(getConfiguredMainWebhookUrl() or "")
 if webhookUrl == "" or string.find(webhookUrl, "PASTE_", 1, true) then
 updateStatus("WEBHOOK // MAIN URL NOT CONFIGURED", Color3.fromRGB(255, 92, 133))
 if onDone then onDone(false) end
 return
 end
 if payload.components then
 webhookUrl = webhookUrl
 .. (string.find(tostring(webhookUrl), "?", 1, true) and "&" or "?")
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
local code = getHttpStatusCode(response)
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
 if name == "aura" then
 return {
 type = 12,
 items = {{
 media = {url = getLastSeenAssetUrl("glacian")},
 description = "AURA separator"
 }}
 }
 end
 if not name or name == "" then
 return {type = 10, content = "━━━━━━━━━━━━━━━━━━━━━━━━"}
 end
 return {
 type = 12,
 items = {{
 media = {url = getLastSeenAssetUrl(name)},
 description = "AURA " .. tostring(name) .. " separator"
 }}
 }
end

local lastSeenRefreshScheduler
local lastSeenRefreshTimers = {}

local function formatLastSeenStatus(timestamp)
 local parsed = tonumber(timestamp)
 if parsed and parsed > 0 then
 local now = os.time()
 if parsed >= now - LAST_SEEN_ACTIVE_WINDOW and parsed <= now + LAST_SEEN_ACTIVE_WINDOW then
 if lastSeenRefreshScheduler then lastSeenRefreshScheduler(parsed) end
 return "**Active Now**"
 end
 return "<t:" .. tostring(math.floor(parsed)) .. ":R>"
 end
 return "*No registrada*"
end

local function buildLastSeenContainer(rarity)
 local style = LAST_SEEN_STYLES[rarity] or {emoji = "◈", color = 0xB48CFF, separator = ""}
 local catalog = LAST_SEEN_CATALOG[rarity] or {}
 local orderedEntries = {}
 local lines = {}
 local registered = 0

 for index, entry in ipairs(catalog) do
 local timestamp = tonumber(lastSeenState.entries[entry.key]) or 0
 table.insert(orderedEntries, {entry = entry, timestamp = timestamp, index = index})
 end
 table.sort(orderedEntries, function(a, b)
 if a.timestamp == b.timestamp then
 return a.index < b.index
 end
 return a.timestamp > b.timestamp
 end)

 for _, row in ipairs(orderedEntries) do
 local entry = row.entry
 local timestamp = row.timestamp > 0 and row.timestamp or nil
 if timestamp then registered = registered + 1 end
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
"# %s %s — Last Seen\n-# %d registradas",
 style.emoji,
 rarity,
 registered
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
 local updatedAt = tonumber(lastSeenState.lastUpdatedAt)
 if not updatedAt or updatedAt <= 0 then
 updatedAt = tonumber(referenceTime) or os.time()
 end

 local components = {
 buildLastSeenSeparator("aura")
 }

 for _, rarity in ipairs(LAST_SEEN_RARITY_ORDER) do
 table.insert(components, buildLastSeenContainer(rarity))
 end

 table.insert(components, buildLastSeenSeparator("aura"))

 table.insert(
 components,
 {
 type = 10,
 content = "-# Last Seen • AURA FAMILY X • Actualizado <t:"
 .. tostring(math.floor(updatedAt))
 .. ":R>"
 }
 )

 return {
 flags = 32768,
 components = components
 }
end

getConfiguredMainWebhookUrl = function()
 local configured = tostring(configState.webhooks.main or "")
 if configured ~= "" and not string.find(configured, "PASTE_", 1, true) then return configured end
 return tostring(CONFIG.WebhookURL or "")
end

local function getConfiguredLastSeenWebhookUrl()
 local configured = tostring(configState.webhooks.lastSeen or "")
 if configured ~= "" and not string.find(configured, "PASTE_", 1, true) then return configured end
 return tostring(CONFIG.LastSeenWebhookURL or "")
end

local function getWebhookBaseUrl()
 return getConfiguredLastSeenWebhookUrl()
 :gsub("%?.*$", "")
 :gsub("/+$", "")
end

local function isLastSeenWebhookConfigured()
 local url = getWebhookBaseUrl()
 return url ~= "" and not string.find(url, "PASTE_", 1, true)
end

local function appendWebhookQuery(url, query)
 return url
 .. (string.find(tostring(url), "?", 1, true) and "&" or "?")
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
if scriptStopped then
if onDone then onDone(false, 0, nil) end
return
end

 if not httpRequest then
 if onDone then onDone(false, 0, nil) end
 return
 end

 task.spawn(function()
if scriptStopped then
if onDone then onDone(false, 0, nil) end
return
end

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

local statusCode = getHttpStatusCode(response)
 local responseBody = decodeWebhookResponse(response)
 local ok = statusCode >= 200 and statusCode < 300
 if onDone then onDone(ok, statusCode, responseBody) end
 end)
end

local function getRemoteMessageTimestamp(message)
local rawTimestamp = type(message) == "table"
and (message.edited_timestamp or message.timestamp)
or nil
if type(rawTimestamp) ~= "string" or rawTimestamp == "" then
return 0
end

if DateTime and type(DateTime.fromIsoDate) == "function" then
local ok, dateTime = pcall(function()
return DateTime.fromIsoDate(rawTimestamp)
end)
if ok and dateTime then
return tonumber(dateTime.UnixTimestamp) or 0
end
end

return 0
end

local function collectRemoteTextDisplays(components, output)
if type(components) ~= "table" then return end

for _, component in pairs(components) do
if type(component) == "table" then
if type(component.content) == "string" then
table.insert(output, component.content)
end
if type(component.components) == "table" then
collectRemoteTextDisplays(component.components, output)
end
end
end
end

local function mergeRemoteLastSeenContent(message)
if type(message) ~= "table" then return false end

local remoteEditedAt = getRemoteMessageTimestamp(message)
local now = os.time()
local remoteActiveAt = 0
if remoteEditedAt > 0
and math.abs(remoteEditedAt - now) <= LAST_SEEN_ACTIVE_WINDOW then
remoteActiveAt = remoteEditedAt
end

local textDisplays = {}
collectRemoteTextDisplays(message.components, textDisplays)
local changed = false

for _, content in ipairs(textDisplays) do
local footerTimestamp = tonumber(content:match("Actualizado%s+<t:(%d+):R>"))
if footerTimestamp
and footerTimestamp > (tonumber(lastSeenState.lastUpdatedAt) or 0) then
lastSeenState.lastUpdatedAt = footerTimestamp
changed = true
end

for line in content:gmatch("[^\r\n]+") do
local timestamp = tonumber(line:match("<t:(%d+):R>"))
if not timestamp
and line:find("Active Now", 1, true)
and remoteActiveAt > 0 then
timestamp = remoteActiveAt
end

if timestamp and timestamp > 0 then
for _, rarity in ipairs(LAST_SEEN_RARITY_ORDER) do
for _, entry in ipairs(LAST_SEEN_CATALOG[rarity] or {}) do
if line:find(entry.name, 1, true) then
local localTimestamp = tonumber(lastSeenState.entries[entry.key]) or 0
if timestamp > localTimestamp then
lastSeenState.entries[entry.key] = timestamp
lastSeenState.lastUpdatedAt = math.max(
tonumber(lastSeenState.lastUpdatedAt) or 0,
timestamp
)
changed = true
end
end
end
end
end
end
end

return changed
end

local function syncLastSeenStateFromRemote()
if scriptStopped or not isLastSeenWebhookConfigured() then
return false
end

local baseUrl = getWebhookBaseUrl()
local webhookKey = getLastSeenWebhookKey(baseUrl)
local configuredMessageId = tostring(CONFIG.LastSeenMessageID or "")
local messageId = lastSeenState.messageIds[webhookKey]
or lastSeenState.messageId
or (configuredMessageId ~= "" and configuredMessageId or nil)
if not messageId or messageId == "" then
return false
end

local requestOk, response = pcall(function()
return httpRequest({
Url = baseUrl .. "/messages/" .. tostring(messageId),
Method = "GET",
Headers = {
["Accept"] = "application/json",
["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
}
})
end)
if not requestOk or not response then
return false
end

local statusCode = getHttpStatusCode(response)
if statusCode < 200 or statusCode >= 300 then
return false
end

local remoteMessage = decodeWebhookResponse(response)
if not remoteMessage then
return false
end

lastSeenState.messageId = tostring(messageId)
lastSeenState.messageIds[webhookKey] = tostring(messageId)
local changed = mergeRemoteLastSeenContent(remoteMessage)
if changed then
saveLastSeenState()
else
scheduleLastSeenStateSave()
end
return true
end

local function upsertLastSeenMessage(payload, onDone)
if scriptStopped then
if onDone then onDone(false) end
return
end

 local baseUrl = getWebhookBaseUrl()
local webhookKey = getLastSeenWebhookKey(baseUrl)
local configuredMessageId = tostring(CONFIG.LastSeenMessageID or "")
local messageId = lastSeenState.messageIds[webhookKey]
or lastSeenState.messageId
or (configuredMessageId ~= "" and configuredMessageId or nil)

 if messageId and messageId ~= "" then
lastSeenState.messageId = tostring(messageId)
lastSeenState.messageIds[webhookKey] = tostring(messageId)
 executeLastSeenRequest(
 "PATCH",
 appendWebhookQuery(baseUrl .. "/messages/" .. tostring(messageId), "with_components=true"),
 payload,
function(ok, statusCode)
 if ok then
lastSeenState.messageIds[webhookKey] = tostring(messageId)
lastSeenState.messageId = tostring(messageId)
scheduleLastSeenStateSave()
if onDone then onDone(true, statusCode) end
 return
 end

 -- Solo crea otro mensaje si el anterior ya no existe.
 -- Un error temporal no debe duplicar el Last Seen.
 if statusCode ~= 404 and statusCode ~= 10008 then
if onDone then onDone(false, statusCode) end
 return
 end

if configuredMessageId ~= "" then
-- El mensaje permanente está configurado explícitamente. No se crea
-- un mensaje nuevo si Discord no encuentra ese ID.
if onDone then onDone(false, statusCode) end
return
end

lastSeenState.messageIds[webhookKey] = nil
if lastSeenState.messageId == tostring(messageId) then
lastSeenState.messageId = nil
end
scheduleLastSeenStateSave()
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
if not newMessageId and responseBody and responseBody.message then
newMessageId = responseBody.message.id
end
 if ok and newMessageId then
lastSeenState.messageId = tostring(newMessageId)
lastSeenState.messageIds[webhookKey] = tostring(newMessageId)
scheduleLastSeenStateSave()
if onDone then onDone(true, statusCode) end
 return
 end

if onDone then onDone(false, statusCode) end
 end
 )
end

local lastSeenUpdateInFlight = false
local lastSeenUpdateQueued = false
local lastSeenRetryAfter = 0

function scheduleLastSeenUpdate()
if scriptStopped or not isLastSeenWebhookConfigured() then
 return
 end

if os.time() < lastSeenRetryAfter then
return
end

 lastSeenUpdateQueued = true
 if lastSeenUpdateInFlight then return end

 lastSeenUpdateInFlight = true
task.spawn(function()
while lastSeenUpdateQueued and not scriptStopped do
 lastSeenUpdateQueued = false
 local finished = false
 local succeeded = false
local failureStatus = 0

syncLastSeenStateFromRemote()
upsertLastSeenMessage(
buildLastSeenPayload(os.time()),
function(ok, statusCode)
 succeeded = ok
failureStatus = tonumber(statusCode) or 0
 finished = true
 end
 )

while not finished and not scriptStopped do
 task.wait()
 end

if scriptStopped then
return
end

 if succeeded then
lastSeenRetryAfter = 0
 updateStatus("LAST SEEN // UPDATED", Color3.fromRGB(151, 255, 204))
 else
lastSeenRetryAfter = os.time() + 30
updateStatus(
"LAST SEEN // UPDATE FAILED"
.. (failureStatus > 0 and (" [" .. tostring(failureStatus) .. "]") or ""),
Color3.fromRGB(255, 92, 133)
)
 end
 end
 lastSeenUpdateInFlight = false
 end)
end

lastSeenRefreshScheduler = function(timestamp)
 local parsed = tonumber(timestamp)
 if not parsed or parsed <= 0 then return end
 local timerKey = tostring(math.floor(parsed))
 if lastSeenRefreshTimers[timerKey] then return end
 lastSeenRefreshTimers[timerKey] = true
 local delaySeconds = math.max(1, parsed + LAST_SEEN_ACTIVE_WINDOW + 1 - os.time())
 task.delay(delaySeconds, function()
 lastSeenRefreshTimers[timerKey] = nil
 if not scriptStopped then scheduleLastSeenUpdate() end
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
 lastSeenState.lastUpdatedAt = math.max(tonumber(lastSeenState.lastUpdatedAt) or 0, timestamp)
 -- Guardado inmediato: el historial no depende de que el scheduler alcance a ejecutarse.
 saveLastSeenState()
 scheduleLastSeenUpdate()
 if lastSeenRefreshScheduler then lastSeenRefreshScheduler(timestamp) end
end

syncLastSeenStateFromRemote()
seedLastSeenState()

-- Envío individual y secuencial: cada huevo conserva su propio webhook.
local function fireWebhookImmediate(payload, onDone)
local requestPayload = type(payload) == "table" and payload or {
content = tostring(payload or "")
}
sendWebhookPayload(
requestPayload,
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

 local jobId = tostring(game.JobId or "")
 if jobId ~= "" then
 return string.format(
 "https://www.roblox.com/games/start?placeId=%s&gameId=%s",
 tostring(game.PlaceId),
 jobId
 )
 end

 return string.format(
 "https://www.roblox.com/games/start?placeId=%s",
 tostring(game.PlaceId)
 )
end

-- No se refresca la lista pública en segundo plano: esa consulta HTTP
-- periódica provocaba congelamientos visibles durante la partida.
-- Join Game siempre usa el servidor actual para que el enlace sea correcto.

local function getPromotionRarity(text)
 local lower = tostring(text or ""):lower()
 if lower:find("divine", 1, true) then return "DIVINE" end
 if lower:find("eternal", 1, true) then return "ETERNAL" end
 if lower:find("secret", 1, true) then return "SECRET" end
 return ""
end

local function getPromotionButton(sourceText)
if type(promotionState.url) ~= "string"
or promotionState.url == ""
or not promotionState.url:match("^https?://%S+$") then
return nil
end

if promotionState.rarity ~= ""
and getPromotionRarity(sourceText) ~= promotionState.rarity then
return nil
end

local now = os.time()
if promotionState.maxUses > 0 and promotionState.used >= promotionState.maxUses then
return nil
end

if now < (tonumber(promotionState.nextAvailableAt) or 0) then
return nil
end

local button = {
 type = 2,
 style = 5,
 label = promotionState.label ~= "" and promotionState.label or "PROMOTION",
 url = promotionState.url
}
local emoji = parsePromotionEmoji(promotionState.emoji)
if emoji then
button.emoji = emoji
end

return {{
type = 1,
components = {button}
}}
end

local function registerPromotionUse()
promotionState.used = promotionState.used + 1
promotionState.nextAvailableAt = os.time()
 + math.floor((tonumber(promotionState.intervalMinutes) or 0) * 60)
savePromotionState()
end

configUi.rarityValue = "Secret"

function refreshConfiguredEmojiLookup()
 for key in pairs(EGG_EMOJI_BY_KEY) do
 EGG_EMOJI_BY_KEY[key] = nil
 end
 for _, rarityEntries in pairs(LAST_SEEN_CATALOG) do
 for _, entry in ipairs(rarityEntries) do
 EGG_EMOJI_BY_KEY[entry.key] = entry.emoji
 end
 end
end

function clearConfigEditor()
 configSelectedKey = nil
 configUi.nameBox.Text = ""
 configUi.roleBox.Text = ""
 configUi.emojiBox.Text = ""
 configUi.rarityValue = "Secret"
 configUi.rarityButton.Text = "RAREZA: SECRET"
 configUi.deleteButton.Text = "DELETE SELECTED CONFIG"
end

local function selectConfigEntry(entry)
 configSelectedKey = entry.key
 configUi.nameBox.Text = entry.name
 configUi.roleBox.Text = entry.roleId
 configUi.emojiBox.Text = entry.emoji
 configUi.rarityValue = normalizeConfiguredRarity(entry.rarity)
 configUi.rarityButton.Text = "RAREZA: " .. configUi.rarityValue:upper()
 configUi.deleteButton.Text = "DELETE: " .. entry.name:upper()
end

function renderConfigList()
 for _, child in ipairs(configUi.listBody:GetChildren()) do
 if child:IsA("GuiObject") then child:Destroy() end
 end

local function refreshConfigListCanvas()
local contentHeight = math.max(30, configUi.listLayout.AbsoluteContentSize.Y + 8)
configUi.listBody.Size = UDim2.new(1, -6, 0, contentHeight)
configUi.list.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
end

 local layoutOrder = 0
 local totalEntries = 0
 local function getRoleId(entryKey)
 for _, roleEntry in ipairs(EGG_ROLE_MENTIONS) do
 local roleKey = roleEntry.name:lower():gsub("[^a-z0-9]", "")
 if roleKey == entryKey then return roleEntry.roleId end
 end
 return ""
 end

 for _, rarity in ipairs(LAST_SEEN_RARITY_ORDER) do
 local catalog = LAST_SEEN_CATALOG[rarity] or {}
 if #catalog > 0 then
 layoutOrder = layoutOrder + 1
 local separator = Instance.new("TextLabel")
 local rarityColor = rarity == "Divine" and Color3.fromRGB(255, 215, 0)
 or rarity == "Eternal" and Color3.fromRGB(171, 92, 255)
 or rarity == "Secret" and Color3.fromRGB(184, 190, 200)
 or Color3.fromRGB(110, 180, 255)
 separator.Name = "RaritySeparator_" .. rarity
 separator.LayoutOrder = layoutOrder
 separator.Size = UDim2.new(1, -6, 0, 20)
 separator.BackgroundColor3 = Color3.fromRGB(38, 25, 61)
 separator.BorderSizePixel = 0
 separator.Text = "━━ " .. rarity:upper() .. " // " .. tostring(#catalog) .. " PETS ━━"
 separator.TextColor3 = rarityColor
 separator.Font = Enum.Font.Code
 separator.TextSize = 20
 separator.TextXAlignment = Enum.TextXAlignment.Left
 separator.Parent = configUi.listBody
 local separatorPadding = Instance.new("UIPadding")
 separatorPadding.PaddingLeft = UDim.new(0, 8)
 separatorPadding.Parent = separator
 end

 for _, catalogEntry in ipairs(catalog) do
 layoutOrder = layoutOrder + 1
 totalEntries = totalEntries + 1
 local entry = {
 name = catalogEntry.name,
 key = catalogEntry.key,
 emoji = catalogEntry.emoji,
 rarity = rarity,
 roleId = getRoleId(catalogEntry.key)
 }
 local row = Instance.new("TextButton")
 row.Name = "Pet_" .. entry.key
 row.LayoutOrder = layoutOrder
 row.Size = UDim2.new(1, -6, 0, 25)
 row.BackgroundColor3 = configSelectedKey == entry.key
 and Color3.fromRGB(101, 51, 144)
 or Color3.fromRGB(29, 21, 45)
 row.BorderSizePixel = 0
row.RichText = true
local displayRarity = escapeRichText(rarity)
 local rarityHex = rarity == "Divine" and "#FFD700"
 or rarity == "Eternal" and "#AB5CFF"
 or rarity == "Secret" and "#B8BEC8"
 or "#6EB4FF"
 if rarity then
 displayRarity = ' ' .. displayRarity .. " "
end
row.Text = "◆ "
.. escapeRichText(entry.name)
.. " // "
.. displayRarity
 row.TextColor3 = Color3.fromRGB(242, 235, 252)
 row.Font = Enum.Font.Code
row.TextSize = 14
 row.TextXAlignment = Enum.TextXAlignment.Left
 row.AutoButtonColor = false
 row.Parent = configUi.listBody
 local rowPadding = Instance.new("UIPadding")
 rowPadding.PaddingLeft = UDim.new(0, 8)
 rowPadding.PaddingRight = UDim.new(0, 8)
 rowPadding.Parent = row
 local rowCorner = Instance.new("UICorner")
 rowCorner.CornerRadius = UDim.new(0, 5)
 rowCorner.Parent = row
 row.MouseButton1Click:Connect(function()
 selectConfigEntry(entry)
 updateStatus("CONFIG // EDITING " .. entry.name, Color3.fromRGB(214, 165, 255))
 end)
 end
 end

 if totalEntries == 0 then
 local empty = Instance.new("TextLabel")
 empty.Size = UDim2.new(1, -8, 0, 27)
 empty.BackgroundTransparency = 1
 empty.Text = "NO PETS REGISTERED // ADD ONE BELOW"
 empty.TextColor3 = Color3.fromRGB(160, 133, 185)
 empty.Font = Enum.Font.Code
empty.TextSize = 11
 empty.TextXAlignment = Enum.TextXAlignment.Left
 empty.Parent = configUi.listBody
 end

refreshConfigListCanvas()
end

configUi.listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
task.defer(function()
local contentHeight = math.max(30, configUi.listLayout.AbsoluteContentSize.Y + 8)
configUi.listBody.Size = UDim2.new(1, -6, 0, contentHeight)
configUi.list.CanvasSize = UDim2.new(0, 0, 0, contentHeight)
end)
end)

local function saveConfigEditor()
 local entry = normalizeConfiguredEntry({
 name = configUi.nameBox.Text,
 roleId = configUi.roleBox.Text,
 emoji = configUi.emojiBox.Text,
 rarity = configUi.rarityValue
 })
 if not entry then
 updateStatus("CONFIG // NAME + ROLE ID REQUIRED", Color3.fromRGB(255, 92, 133))
 return
 end
 for index = #configState.entries, 1, -1 do
 if configState.entries[index].key == entry.key
 or (configSelectedKey and configState.entries[index].key == configSelectedKey) then
 table.remove(configState.entries, index)
 end
 end
 table.insert(configState.entries, entry)
 table.sort(configState.entries, function(a, b)
 return a.rarity .. a.name < b.rarity .. b.name
 end)
 configSelectedKey = entry.key
 rebuildConfiguredCatalog()
 refreshConfiguredEmojiLookup()
 saveConfigState()
 renderConfigList()
 selectConfigEntry(entry)
 scheduleLastSeenUpdate()
 updateStatus("CONFIG // SAVED " .. entry.name, Color3.fromRGB(151, 255, 204))
end

configUi.rarityButton.MouseButton1Click:Connect(function()
 local current = 1
 local options = {"Secret", "Eternal", "Divine"}
 for index, value in ipairs(options) do
 if value == configUi.rarityValue then current = index break end
 end
 configUi.rarityValue = options[current % #options + 1]
 configUi.rarityButton.Text = "RAREZA: " .. configUi.rarityValue:upper()
end)

configUi.saveButton.MouseButton1Click:Connect(saveConfigEditor)
configUi.newButton.MouseButton1Click:Connect(function()
 clearConfigEditor()
 updateStatus("CONFIG // NEW PET READY", Color3.fromRGB(214, 165, 255))
end)

configUi.deleteButton.MouseButton1Click:Connect(function()
 if not configSelectedKey then
 updateStatus("CONFIG // SELECT A PET FIRST", Color3.fromRGB(255, 193, 89))
 return
 end
 for index = #configState.entries, 1, -1 do
 if configState.entries[index].key == configSelectedKey then
 table.remove(configState.entries, index)
 break
 end
 end
 rebuildConfiguredCatalog()
 refreshConfiguredEmojiLookup()
 saveConfigState()
 clearConfigEditor()
 renderConfigList()
 scheduleLastSeenUpdate()
 updateStatus("CONFIG // PET REMOVED", Color3.fromRGB(255, 181, 205))
end)

renderConfigList()


-- AURA EGG 2.2.8 ULTRA // DELIVERY + EVENT LOOP
local function sendEggAlert(description, sourceText, onDone)
 task.spawn(function()
 local payload = {
 content = description,
 flags = 4 -- SUPPRESS_EMBEDS: solo texto, sin preview de Roblox
 }
-- Permite explícitamente solo el rol de la mascota.
-- La mención de rareza se conserva como decoración, pero no genera ping.
 local roleIds = {}
 local seenRoleIds = {}
 for roleId in description:gmatch("<@&(%d+)>") do
if EGG_ROLE_ID_SET[roleId] and not seenRoleIds[roleId] then
 seenRoleIds[roleId] = true
 table.insert(roleIds, roleId)
 end
 end

if #roleIds > 0 then
payload.allowed_mentions = {
roles = roleIds
}
 end

 local promotionButton = getPromotionButton(sourceText)
if promotionButton then
payload.components = promotionButton
end

sendWebhookPayload(payload, "WEBHOOK RELEASE // SENT", function(success)
if success and promotionButton then
registerPromotionUse()
end
if onDone then onDone(success) end
end)
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
 text = CONFIG.Version .. " // AURA ANNOUNCER"
 }
 }}
 }

 sendWebhookPayload(embedPayload, "ANNOUNCER // EMBED SENT", function(success)
 if success then
 sendAnnouncementButton.Text = "SENT [OK] // SEND ANOTHER"
 announcementBody.Text = ""
 else
 sendAnnouncementButton.Text = "RETRY EMBED > WEBHOOK"
 end
 end)
end)

task.spawn(function()
local startupServerName = tostring(game.Name or "CURRENT SERVER")
local startupPayload = {
flags = 32768,
components = {{
type = 17,
accent_color = 0x8B5CF6,
components = {
{
type = 10,
content = "## 🟢 AURA EGG NOTIFIER ACTIVATED"
},
{
type = 10,
content = "> **HELLO AURA FAMILY X, I'M READY :)**"
},
{
type = 14,
divider = true,
spacing = 2
},
{
type = 10,
content = "**AURA EGG NOTIFIER IS READY TO SEND NOTIFICATIONS IN** `"
.. startupServerName
.. "`\n"
.. "__SYSTEM VERSION:__ `"
.. CONFIG.Version
.. "`"
},
{
type = 10,
content = "-# *Fast detection* • **clean delivery** • __local state__"
},
{
type = 10,
content = "> `Markdown online` ~~legacy boot text retired~~"
},
{
type = 10,
content = "```js\n"
.. "console.log(\"AURA EGG NOTIFIER ACTIVATED\");\n"
.. "console.log(\"Ready to send notifications\");\n"
.. "```"
},
{
type = 14,
divider = true,
spacing = 2
},
{
type = 10,
content = "**By: ULTRA3_DEV**"
}
}
}}
}
fireWebhookImmediate(startupPayload)
end)

local function formatEggAlert(text, spawnedAt, count, joinUrl)
local message = replaceRarityWithMention(text)
local eggMentioned
message, eggMentioned = replaceEggNameWithMention(message)
local eggEmoji, eggMention = getEggDisplayData(text)
 local rarityEmoji = getRarityEmoji(text)
 local countValue = math.max(1, math.floor(tonumber(count) or 1))
 local countPrefix = "X" .. tostring(countValue) .. " "

local spawnedDescription = tostring(text or ""):match("[Ee]gg%s+[Ss]pawned%s+(.+)$")
if spawnedDescription then
spawnedDescription = "Egg spawned " .. spawnedDescription
else
spawnedDescription = "Egg spawned!"
end

local headline
if eggMention and eggEmoji then
 headline = countPrefix .. eggEmoji .. " | " .. eggMention .. " **" .. spawnedDescription .. "**"
elseif eggMention then
 headline = countPrefix .. eggMention .. " **" .. spawnedDescription .. "**"
else
 headline = countPrefix .. message
end

 local joinLine = ""
 if type(joinUrl) == "string" and joinUrl ~= "" then
 joinLine = "\n-# Join Game: **[¡CLICK HERE!](" .. joinUrl .. ")**"
 end

return string.format(
 "> %s\n━━━━━━━━━━━━━━━━━━━━\n- %s **Spawned:** <t:%d:R>\n━━━━━━━━━━━━━━━━━━━━%s",
 headline,
 rarityEmoji,
 tonumber(spawnedAt) or os.time(),
 joinLine
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
 sendEggAlert(
 formatEggAlert(egg.text, egg.spawnedAt, egg.count, getGameFallbackUrl()),
 egg.text,
 function()
 sendPriorityQueue(queue, index + 1)
 end
 )
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

 local aggregationKey = normalizeLastSeenKey(text)
 local timestamp = spawnedAt or os.time()
 for _, queuedEgg in ipairs(pendingEggs) do
 if queuedEgg.aggregationKey == aggregationKey
 and math.abs((tonumber(queuedEgg.spawnedAt) or timestamp) - timestamp) <= 1 then
 queuedEgg.count = (queuedEgg.count or 1) + 1
 return
 end
 end

 table.insert(pendingEggs, {
 text = text,
 rank = getRarityRank(text),
 sequence = sequence,
 spawnedAt = timestamp,
 aggregationKey = aggregationKey,
 count = 1
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

if lower:find("system online", 1, true)
or lower:find("aura egg notifier activated", 1, true)
or lower:find("ultra-hyper", 1, true) then
 return "SYSTEM", "SYSTEM ONLINE // LISTENING", Color3.fromRGB(151, 255, 204), "system"
 elseif lower:find("eternal", 1, true) then
 return "ETERNAL", "GREAT NEWS // ETERNAL EGG", Color3.fromRGB(255, 204, 76), "spark"
 elseif lower:find("divine", 1, true) then
 return "DIVINE", "GREAT NEWS // DIVINE EGG", Color3.fromRGB(255, 126, 226), "spark"
 elseif lower:find("secret", 1, true) then
 return "SECRET", "JACKPOT // SECRET EGG", Color3.fromRGB(192, 126, 255), "spark"
 end

 return "NORMAL", "GOOD NEWS // EGG SPAWNED", Color3.fromRGB(151, 255, 204), "egg"
end

local function createVisualCard(text, sequence)
 layoutCounter = layoutCounter + 1
 local rarityName = getVisualMeta(text)
 appendLogHistory(text, sequence, rarityName)
end

local function processText(raw, source)
if scriptStopped then return end

 local clean = cleanText(raw)
 if clean == "" then return end
 local lower = clean:lower()

 for _, bad in ipairs(CONFIG.Blacklist) do
 if lower:find(bad, 1, true) then return end
 end

 local function containsAnyKeyword(keywords)
 for _, keyword in ipairs(keywords) do
 if lower:find(keyword, 1, true) then
 return true
 end
 end
 return false
 end

 local hasEgg = containsAnyKeyword(CONFIG.EggKeywords)
 local hasSpawnEvent = containsAnyKeyword(CONFIG.SpawnKeywords)
 local hasTrackedRarity = getRarityRank(lower) <= #RARITY_ORDER

 if hasEgg and hasSpawnEvent and hasTrackedRarity then
 local now = tick()
 source = source or "unknown"
 local otherSource = source == "log" and "chat" or "log"
 local otherRecent = recentProcessedText[otherSource]
 if otherRecent
 and otherRecent.text == clean
 and (now - otherRecent.time) < 0.15 then
 return
 end
 recentProcessedText[source] = {
 text = clean,
 time = now
 }

 eggSequence = eggSequence + 1
 local spawnedAt = os.time()
 recordLastSeenSpawn(clean, spawnedAt)
 createVisualCard(clean, eggSequence)
 queueEgg(clean, eggSequence, spawnedAt)
 end
end

LogService.MessageOut:Connect(function(msg, messageType)
 appendConsoleEntry(msg, messageType, "GAME")
 processText(msg, "log")
end)
TextChatService.MessageReceived:Connect(function(msg)
 if msg.Text then processText(msg.Text, "chat") end
end)

createVisualCard("AURA EGG NOTIFIER ACTIVATED\nListening to game logs // instant alerts enabled.")
appendConsoleEntry("AURA EGG NOTIFIER ACTIVATED", "MessageInfo", "SCRIPT")
updateStatus("SYSTEM VERSION: " .. CONFIG.Version .. " // READY", Color3.fromRGB(99, 255, 154))
scheduleLastSeenUpdate()
print("AURA EGG NOTIFIER ACTIVATED")
end

runNotifierRuntime()
