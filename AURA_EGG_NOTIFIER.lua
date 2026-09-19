--[[
    AURA EGG NOTIFIER
    ==================
    Detector de huevos Secret, Eternal y Divine para Steal an Egg.

    IMPORTANTE:
    1) El webhook del archivo original quedó expuesto. GENERA UNO NUEVO
       en Discord y pégalo en CONFIG.WebhookURL.
    2) No se hace ninguna petición a una wiki desde Roblox. Los valores
       de la tabla son solo fallback; si el mensaje del juego trae Money
       o Recommended Speed, esos valores vivos siempre tienen prioridad.
    3) El script no usa batching ni :Disconnect() sobre task.delay:
       cada evento se procesa una sola vez y con deduplicación segura.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local CONFIG = {
    Name = "AURA EGG NOTIFIER",
    WebhookURL = "PASTE_A_NEW_DISCORD_WEBHOOK_HERE",
    DisplayTime = 28,
    MaxNotifications = 6,
    DuplicateWindow = 8,
    NotifyOnlyConfiguredRarities = true,
}

local ROLE_IDS = {
    Secret = "1544734376640782346",
    Eternal = "1544734452054229173",
    Divine = "1544734510665699389",
}

local RARITIES = {
    Divine = {
        emoji = "✨",
        color = 16766720,
        uiColor = Color3.fromRGB(255, 205, 76),
        roleId = ROLE_IDS.Divine,
        aliases = {"divine", "divino"},
    },
    Eternal = {
        emoji = "🌌",
        color = 6046719,
        uiColor = Color3.fromRGB(96, 214, 255),
        roleId = ROLE_IDS.Eternal,
        aliases = {"eternal", "eterno"},
    },
    Secret = {
        emoji = "🔮",
        color = 12315285,
        uiColor = Color3.fromRGB(203, 105, 255),
        roleId = ROLE_IDS.Secret,
        aliases = {"secret", "secreto"},
    },
}

-- Fallbacks basados en datos públicos consultados. Los datos del mensaje
-- del juego tienen prioridad y sustituyen estos valores automáticamente.
local EGG_DATABASE = {
    ["el maja"] = {
        location = "Abyss Ocean",
        money = "$130M/s",
        speed = "2.5M (observado)",
    },
    ["mosasaurus"] = {
        location = "Prehistoric",
        money = "$180M/s",
        speed = "17M–18M (wiki est.)",
    },
}

local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local httpRequest = (syn and syn.request)
    or (http and http.request)
    or http_request
    or (fluxus and fluxus.request)
    or request

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Permite ejecutar el script otra vez sin dejar conexiones antiguas activas.
local runtimeEnv = (type(getgenv) == "function" and getgenv()) or _G
if runtimeEnv.AURA_EGG_NOTIFIER_STOP then
    pcall(runtimeEnv.AURA_EGG_NOTIFIER_STOP)
end

local connections = {}
local activeCards = {}
local recentEvents = {}
local detectionCount = 0
local shuttingDown = false

local oldGui = playerGui:FindFirstChild("AuraEggNotifier")
if oldGui then
    oldGui:Destroy()
end

local function connect(signal, callback)
    local ok, connection = pcall(function()
        return signal:Connect(callback)
    end)
    if ok and connection then
        table.insert(connections, connection)
        return connection
    end
    return nil
end

local function destroyAllCards()
    for _, card in ipairs(activeCards) do
        if card and card.Parent then
            card:Destroy()
        end
    end
    table.clear(activeCards)
end

local function shutdown()
    if shuttingDown then
        return
    end
    shuttingDown = true
    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end
    table.clear(connections)
    destroyAllCards()
    local gui = playerGui:FindFirstChild("AuraEggNotifier")
    if gui then
        gui:Destroy()
    end
    if runtimeEnv.AURA_EGG_NOTIFIER_STOP == shutdown then
        runtimeEnv.AURA_EGG_NOTIFIER_STOP = nil
    end
end

runtimeEnv.AURA_EGG_NOTIFIER_STOP = shutdown

local function trim(value)
    value = tostring(value or "")
    return value:match("^%s*(.-)%s*$") or ""
end

local function cleanText(value)
    value = tostring(value or "")
    value = value:gsub("<[^>]+>", "")
    value = value:gsub("[%c]", " ")
    return trim(value)
end

local function lower(value)
    return cleanText(value):lower()
end

local function safeDiscordText(value)
    value = cleanText(value)
    value = value:gsub("@", "＠")
    value = value:gsub("\\", "\\\\")
    value = value:gsub("%*", "\\*")
    value = value:gsub("_", "\\_")
    value = value:gsub("~", "\\~")
    value = value:gsub("`", "\\`")
    return value
end

local function removeTrailingPunctuation(value)
    value = trim(value)
    value = value:gsub("[!?,;%.]+$", "")
    return trim(value)
end

local function normalizeEggName(value)
    local key = lower(value)
    key = key:gsub("^big%s+", "")
    key = key:gsub("^huge%s+", "")
    key = key:gsub("^secret%s+", "")
    key = key:gsub("^eternal%s+", "")
    key = key:gsub("^divine%s+", "")
    key = key:gsub("%s+egg%s*$", "")
    return trim(key)
end

local function findAfterLabel(text, labels)
    local original = tostring(text or "")
    local textLower = original:lower()

    for _, label in ipairs(labels) do
        local labelLower = label:lower()
        local startIndex = textLower:find(labelLower, 1, true)
        if startIndex then
            local value = original:sub(startIndex + #label)
            value = value:gsub("^%s*[:%-]?%s*", "")
            value = value:match("^[^|\r\n]+") or value
            value = removeTrailingPunctuation(value)
            if value ~= "" then
                return value
            end
        end
    end

    return nil
end

local function detectRarity(text)
    local textLower = lower(text)
    local order = {"Divine", "Eternal", "Secret"}

    for _, rarityName in ipairs(order) do
        local rarity = RARITIES[rarityName]
        for _, alias in ipairs(rarity.aliases) do
            if textLower:find(alias, 1, true) then
                return rarityName
            end
        end
    end

    return nil
end

local function extractEggName(text)
    local eggName = findAfterLabel(text, {"egg"})

    if eggName then
        eggName = eggName:gsub("%s+[Ss][Pp][Aa][Ww][Nn][Ee][Dd].*$", "")
    end

    if not eggName or eggName == "" then
        eggName = text:match("([^|\r\n]+)%s+[Ss][Pp][Aa][Ww][Nn][Ee][Dd]")
    end

    if eggName then
        eggName = eggName:gsub("^%s*[Ee][Tt][Ee][Rr][Nn][Aa][Ll]%s+", "")
        eggName = eggName:gsub("^%s*[Dd][Ii][Vv][Ii][Nn][Ee]%s+", "")
        eggName = eggName:gsub("^%s*[Ss][Ee][Cc][Rr][Ee][Tt]%s+", "")
        eggName = eggName:gsub("^%s*[Ee][Gg][Gg]%s*[:%-]?%s*", "")
        eggName = eggName:gsub("%s+[Ee][Gg][Gg]%s*$", "")
        eggName = removeTrailingPunctuation(eggName)
    end

    -- Si el texto no incluye el nombre completo, busca nombres conocidos.
    if not eggName or #eggName < 2 then
        local textLower = lower(text)
        for name in pairs(EGG_DATABASE) do
            if textLower:find(name, 1, true) then
                eggName = name
                break
            end
        end
    end

    return safeDiscordText(eggName or "Unknown Egg")
end

local function extractLocation(text)
    local location = findAfterLabel(text, {"location", "biome", "zona"})
    if location then
        return safeDiscordText(location)
    end

    local textLower = tostring(text or ""):lower()
    local inIndex = textLower:find(" in ", 1, true)
    if inIndex then
        local value = tostring(text):sub(inIndex + 4)
        value = value:match("^[^!|\r\n]+") or value
        value = removeTrailingPunctuation(value)
        if value ~= "" then
            return safeDiscordText(value)
        end
    end

    return "Unknown location"
end

local function extractMoney(text)
    return safeDiscordText(findAfterLabel(text, {
        "money",
        "mps",
        "income",
        "cash",
    }) or "")
end

local function extractSpeed(text)
    return safeDiscordText(findAfterLabel(text, {
        "recommended speed",
        "required speed",
        "speed required",
        "speed",
    }) or "")
end

local function getJoinUrl()
    local placeId = tostring(game.PlaceId or "")
    local jobId = tostring(game.JobId or "")

    if placeId == "" or placeId == "0" then
        return nil
    end

    if jobId ~= "" then
        return "https://www.roblox.com/games/start?placeId="
            .. placeId
            .. "&gameInstanceId="
            .. jobId
    end

    return "https://www.roblox.com/games/start?placeId=" .. placeId
end

local function buildEvent(rawText)
    local text = cleanText(rawText)
    if text == "" then
        return nil
    end

    local rarityName = detectRarity(text)
    if not rarityName and CONFIG.NotifyOnlyConfiguredRarities then
        return nil
    end

    local rarity = RARITIES[rarityName]
    if not rarity then
        return nil
    end

    local eggName = extractEggName(text)
    local data = EGG_DATABASE[normalizeEggName(eggName)] or {}
    local liveLocation = extractLocation(text)
    local liveMoney = extractMoney(text)
    local liveSpeed = extractSpeed(text)

    local event = {
        raw = text,
        rarity = rarityName,
        rarityData = rarity,
        egg = eggName,
        location = liveLocation ~= "Unknown location"
            and liveLocation
            or safeDiscordText(data.location or "Unknown location"),
        money = liveMoney ~= "" and liveMoney or safeDiscordText(data.money or "Not listed"),
        speed = liveSpeed ~= "" and liveSpeed or safeDiscordText(data.speed or "Not listed"),
        source = (liveMoney ~= "" or liveSpeed ~= "") and "Live game data" or "Wiki fallback",
        joinUrl = getJoinUrl(),
        detectedAt = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        shortTime = os.date("%H:%M:%S"),
    }

    event.fingerprint = lower(event.rarity .. "|" .. event.egg .. "|" .. event.location)
    return event
end

-- =========================
-- UI LOCAL
-- =========================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AuraEggNotifier"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 9999
screenGui.Parent = playerGui

local root = Instance.new("Frame")
root.Name = "Panel"
root.AnchorPoint = Vector2.new(1, 0)
root.Position = UDim2.new(1, -18, 0, 58)
root.Size = UDim2.new(0, 380, 0, 450)
root.BackgroundColor3 = Color3.fromRGB(13, 15, 29)
root.BackgroundTransparency = 0.04
root.BorderSizePixel = 0
root.Parent = screenGui

local rootCorner = Instance.new("UICorner")
rootCorner.CornerRadius = UDim.new(0, 16)
rootCorner.Parent = root

local rootStroke = Instance.new("UIStroke")
rootStroke.Color = Color3.fromRGB(97, 108, 165)
rootStroke.Transparency = 0.35
rootStroke.Thickness = 1.5
rootStroke.Parent = root

local rootGradient = Instance.new("UIGradient")
rootGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(26, 29, 58)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(9, 11, 22)),
})
rootGradient.Rotation = 90
rootGradient.Parent = root

local header = Instance.new("Frame")
header.Name = "Header"
header.BackgroundTransparency = 1
header.Size = UDim2.new(1, -24, 0, 68)
header.Position = UDim2.new(0, 12, 0, 10)
header.Parent = root

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, 0, 0, 26)
title.Font = Enum.Font.GothamBold
title.Text = "AURA EGG NOTIFIER"
title.TextColor3 = Color3.fromRGB(245, 247, 255)
title.TextSize = 19
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.new(0, 0, 0, 27)
subtitle.Size = UDim2.new(1, 0, 0, 18)
subtitle.Font = Enum.Font.Gotham
subtitle.Text = "LIVE SPAWN INTELLIGENCE  •  SECURE MODE"
subtitle.TextColor3 = Color3.fromRGB(150, 164, 210)
subtitle.TextSize = 10
subtitle.TextXAlignment = Enum.TextXAlignment.Left
subtitle.Parent = header

local statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Position = UDim2.new(0, 0, 0, 48)
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.Font = Enum.Font.Code
statusLabel.Text = "● STARTING  •  0 detections"
statusLabel.TextColor3 = Color3.fromRGB(117, 255, 183)
statusLabel.TextSize = 11
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = header

local list = Instance.new("ScrollingFrame")
list.Name = "Notifications"
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.Position = UDim2.new(0, 10, 0, 84)
list.Size = UDim2.new(1, -20, 1, -126)
list.ScrollBarThickness = 3
list.ScrollBarImageColor3 = Color3.fromRGB(113, 126, 200)
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = root

local listPadding = Instance.new("UIPadding")
listPadding.PaddingLeft = UDim.new(0, 2)
listPadding.PaddingRight = UDim.new(0, 5)
listPadding.PaddingTop = UDim.new(0, 2)
listPadding.PaddingBottom = UDim.new(0, 4)
listPadding.Parent = list

local listLayout = Instance.new("UIListLayout")
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Padding = UDim.new(0, 8)
listLayout.Parent = list

local footer = Instance.new("TextLabel")
footer.Name = "Footer"
footer.BackgroundTransparency = 1
footer.Position = UDim2.new(0, 14, 1, -31)
footer.Size = UDim2.new(1, -28, 0, 18)
footer.Font = Enum.Font.Gotham
footer.Text = "Role routing: SECRET  •  ETERNAL  •  DIVINE"
footer.TextColor3 = Color3.fromRGB(119, 129, 169)
footer.TextSize = 10
footer.TextXAlignment = Enum.TextXAlignment.Left
footer.Parent = root

local function updateStatus(text, color)
    statusLabel.Text = "● " .. tostring(text) .. "  •  " .. tostring(detectionCount) .. " detections"
    if color then
        statusLabel.TextColor3 = color
    end
end

local function removeCard(card)
    for index, value in ipairs(activeCards) do
        if value == card then
            table.remove(activeCards, index)
            break
        end
    end
end

local function createVisualCard(event)
    local isSystemCard = event.isSystem == true
    if not isSystemCard then
        detectionCount = detectionCount + 1
    end
    updateStatus("MONITORING", Color3.fromRGB(117, 255, 183))

    local card = Instance.new("Frame")
    card.Name = "SpawnCard"
    card.LayoutOrder = isSystemCard and 0 or -detectionCount
    card.Size = UDim2.new(1, 0, 0, 132)
    card.BackgroundColor3 = Color3.fromRGB(30, 32, 60)
    card.BackgroundTransparency = 0.08
    card.BorderSizePixel = 0
    card.Parent = list

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = card

    local stroke = Instance.new("UIStroke")
    stroke.Color = event.rarityData.uiColor
    stroke.Transparency = 0.15
    stroke.Thickness = 1.5
    stroke.Parent = card

    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = event.rarityData.uiColor
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(0, 4, 1, -18)
    accent.Position = UDim2.new(0, 8, 0, 9)
    accent.Parent = card

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accent

    local cardTitle = Instance.new("TextLabel")
    cardTitle.BackgroundTransparency = 1
    cardTitle.Position = UDim2.new(0, 23, 0, 10)
    cardTitle.Size = UDim2.new(1, -32, 0, 21)
    cardTitle.Font = Enum.Font.GothamBold
    cardTitle.Text = event.rarityData.emoji .. "  " .. event.rarity:upper() .. " EGG SPAWNED"
    cardTitle.TextColor3 = event.rarityData.uiColor
    cardTitle.TextSize = 14
    cardTitle.TextXAlignment = Enum.TextXAlignment.Left
    cardTitle.Parent = card

    local cardBody = Instance.new("TextLabel")
    cardBody.BackgroundTransparency = 1
    cardBody.Position = UDim2.new(0, 23, 0, 38)
    cardBody.Size = UDim2.new(1, -32, 0, 76)
    cardBody.Font = Enum.Font.Gotham
    cardBody.Text = string.format(
        "🥚  %s\n📍  %s\n💰  %s\n⚡  %s\n🕒  Spotted just now",
        event.egg,
        event.location,
        event.money,
        event.speed
    )
    cardBody.TextColor3 = Color3.fromRGB(232, 235, 247)
    cardBody.TextSize = 12
    cardBody.TextWrapped = true
    cardBody.TextXAlignment = Enum.TextXAlignment.Left
    cardBody.TextYAlignment = Enum.TextYAlignment.Top
    cardBody.Parent = card

    table.insert(activeCards, card)
    if #activeCards > CONFIG.MaxNotifications then
        local oldest = table.remove(activeCards, 1)
        if oldest then
            oldest:Destroy()
        end
    end

    card.BackgroundTransparency = 1
    cardTitle.TextTransparency = 1
    cardBody.TextTransparency = 1

    TweenService:Create(card, TweenInfo.new(0.22), {
        BackgroundTransparency = 0.08,
    }):Play()
    TweenService:Create(cardTitle, TweenInfo.new(0.22), {
        TextTransparency = 0,
    }):Play()
    TweenService:Create(cardBody, TweenInfo.new(0.22), {
        TextTransparency = 0,
    }):Play()

    local removed = false
    local function expire()
        if removed then
            return
        end
        removed = true
        removeCard(card)
        if card.Parent then
            local tween = TweenService:Create(card, TweenInfo.new(0.2), {
                BackgroundTransparency = 1,
            })
            tween:Play()
            task.delay(0.22, function()
                if card then
                    card:Destroy()
                end
            end)
        end
    end

    task.delay(CONFIG.DisplayTime, expire)
end

-- =========================
-- WEBHOOK DISCORD
-- =========================

local function webhookReady()
    return type(CONFIG.WebhookURL) == "string"
        and #CONFIG.WebhookURL > 50
        and not CONFIG.WebhookURL:find("PASTE_", 1, true)
end

local function buildWebhookPayload(event)
    local roleMention = "<@&" .. event.rarityData.roleId .. ">"
    local joinValue = event.joinUrl
        and "[**Click here to join the server**](" .. event.joinUrl .. ")"
        or "`Join link unavailable`"

    return {
        username = CONFIG.Name,
        content = string.format(
            "%s\n**%s %s spawned in %s!**",
            roleMention,
            event.rarity:upper(),
            event.egg,
            event.location
        ),
        allowed_mentions = {
            parse = {},
            roles = {event.rarityData.roleId},
        },
        embeds = {{
            author = {
                name = "AURA EGG NOTIFIER  •  LIVE SPAWN TRACKER",
            },
            title = event.rarityData.emoji .. "  " .. event.rarity .. " Egg Spotted!",
            url = event.joinUrl,
            description = string.format(
                "## %s\n> A high-value egg has been detected in **%s**.\n> This alert was routed automatically to the **%s** role.",
                event.egg,
                event.location,
                event.rarity
            ),
            color = event.rarityData.color,
            fields = {
                {
                    name = "🥚 Egg",
                    value = "`" .. event.egg .. "`",
                    inline = true,
                },
                {
                    name = "📍 Location",
                    value = "`" .. event.location .. "`",
                    inline = true,
                },
                {
                    name = "💰 Money / second",
                    value = "**" .. event.money .. "**",
                    inline = true,
                },
                {
                    name = "⚡ Recommended speed",
                    value = "**" .. event.speed .. "**",
                    inline = true,
                },
                {
                    name = "🕒 Spotted",
                    value = "Just now • `" .. event.shortTime .. "`",
                    inline = true,
                },
                {
                    name = "🎮 Join Game",
                    value = joinValue,
                    inline = true,
                },
                {
                    name = "📊 Data source",
                    value = "`" .. event.source .. "`",
                    inline = false,
                },
            },
            footer = {
                text = "AURA EGG NOTIFIER  •  " .. tostring(player.Name),
            },
            timestamp = event.detectedAt,
        }},
    }
end

local function postWebhook(event)
    if not httpRequest then
        updateStatus("HTTP API NOT FOUND", Color3.fromRGB(255, 104, 104))
        return
    end

    if not webhookReady() then
        updateStatus("CONFIGURE WEBHOOK", Color3.fromRGB(255, 205, 76))
        return
    end

    local payload = buildWebhookPayload(event)
    task.spawn(function()
        local ok, response = pcall(function()
            return httpRequest({
                Url = CONFIG.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                },
                Body = HttpService:JSONEncode(payload),
            })
        end)

        if not ok or not response then
            updateStatus("WEBHOOK NETWORK ERROR", Color3.fromRGB(255, 104, 104))
            return
        end

        local statusCode = tonumber(
            response.StatusCode
                or response.Status
                or response.status_code
                or 0
        ) or 0

        if statusCode >= 200 and statusCode < 300 then
            updateStatus("WEBHOOK SENT", Color3.fromRGB(117, 255, 183))
        elseif statusCode == 429 then
            updateStatus("DISCORD RATE LIMITED", Color3.fromRGB(255, 205, 76))
        else
            updateStatus("WEBHOOK ERROR " .. tostring(statusCode), Color3.fromRGB(255, 104, 104))
        end
    end)
end

-- =========================
-- DETECCIÓN
-- =========================

local function processText(rawText)
    if shuttingDown then
        return
    end

    local event = buildEvent(rawText)
    if not event then
        return
    end

    local now = os.clock()
    local previous = recentEvents[event.fingerprint]
    if previous and now - previous < CONFIG.DuplicateWindow then
        return
    end
    recentEvents[event.fingerprint] = now

    createVisualCard(event)
    postWebhook(event)
end

connect(LogService.MessageOut, function(message)
    processText(message)
end)

connect(TextChatService.MessageReceived, function(message)
    if message and message.Text then
        processText(message.Text)
    end
end)

createVisualCard({
    isSystem = true,
    rarity = "SYSTEM",
    rarityData = {
        emoji = "◈",
        uiColor = Color3.fromRGB(117, 255, 183),
    },
    egg = "Monitoring active",
    location = "All supported channels",
    money = "Awaiting live data",
    speed = "Ready",
})

updateStatus(
    webhookReady() and "MONITORING" or "WEBHOOK REQUIRED",
    webhookReady() and Color3.fromRGB(117, 255, 183) or Color3.fromRGB(255, 205, 76)
)

print("[AURA EGG NOTIFIER] Ready • Secret / Eternal / Divine routing enabled")