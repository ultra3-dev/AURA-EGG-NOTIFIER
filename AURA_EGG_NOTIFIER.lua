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
    Keywords = {
        "egg",
        "huevo",
        "spawned",
        "appeared",
        "aparecido",
        "secret",
        "divine",
        "legendary",
        "mythical",
        "eternal",
        "cosmic",
    },
    Blacklist = {
        "[debug]",
        "eggtooldisplay",
        "placedeggrenderer",
        "guard",
        "trace",
        "anticheat",
        "jobid",
    },
}

local ROLE_IDS = {
    Secret = "1544734376640782346",
    Eternal = "1544734452054229173",
    Divine = "1544734510665699389",
}

local RARITIES = {
    Divine = {
        discordEmoji = "<:Divine:1548446386964406282>",
        badge = "D",
        color = 16766720,
        uiColor = Color3.fromRGB(255, 205, 76),
        roleId = ROLE_IDS.Divine,
        aliases = {"divine", "divino"},
    },
    Eternal = {
        discordEmoji = "<:Eternal:1548446341699477525>",
        badge = "E",
        color = 6046719,
        uiColor = Color3.fromRGB(96, 214, 255),
        roleId = ROLE_IDS.Eternal,
        aliases = {"eternal", "eterno"},
    },
    Secret = {
        discordEmoji = "<:Secret:1548446274616041645>",
        badge = "S",
        color = 12315285,
        uiColor = Color3.fromRGB(203, 105, 255),
        roleId = ROLE_IDS.Secret,
        aliases = {"secret", "secreto"},
    },
}

-- Datos de Steal an Egg. Los datos vivos del mensaje del juego siempre
-- tienen prioridad; estos valores solo se usan como fallback del embed.
local EGG_DATABASE = {
    ["el maja"] = {
        displayName = "El Maja",
        discordEmoji = "<:El_Maja:1548441358493159474>",
        location = "Abyss Ocean",
        money = "$130M/s",
        speed = "Not listed",
    },
    ["mosasaurus"] = {
        displayName = "Mosasaurus",
        discordEmoji = "<:Mosasaurus:1548441957016273036>",
        location = "Prehistoric",
        money = "$180M/s",
        speed = "Not listed",
    },
    ["nightflame"] = {
        displayName = "Nightflame",
        discordEmoji = "<:Nightflame:1548444116873121832>",
        location = "Titan Temple",
        money = "$3B/s",
    },
    ["unicorn"] = {
        displayName = "Unicorn",
        discordEmoji = "<:Unicorn:1548443051322646548>",
        location = "Cosmic",
        money = "$1B/s",
    },
    ["kitsune"] = {
        displayName = "Kitsune",
        discordEmoji = "<:Kitsune:1548443441170620547>",
        location = "Cherry Blossom",
        money = "$1.8B/s",
    },
    ["archangel"] = {
        displayName = "ArchAngel",
        discordEmoji = "<:ArchAngel:1548495435897770045>",
        location = "Angels & Demons",
        money = "$5B/s",
    },
    ["world burner"] = {
        displayName = "World Burner",
        discordEmoji = "<:World_Burner:1548494788158820483>",
        location = "Angels & Demons",
        money = "$5B/s",
    },
    ["phoenix"] = {
        displayName = "Phoenix",
        discordEmoji = "<:Phoenix:1548440843591880724>",
        location = "Volcano",
        money = "$85M/s",
    },
    ["ice dragon"] = {
        displayName = "Ice Dragon",
        discordEmoji = "<:Ice_Dragon:1548440110239064174>",
        location = "Snow",
        money = "$65M/s",
    },
    ["gorilla king"] = {
        displayName = "Gorilla King",
        discordEmoji = "<:Gorilla_King:1548443784084459531>",
        location = "Titan Temple",
        money = "$880M/s",
    },
    ["oni tiger"] = {
        displayName = "Oni Tiger",
        discordEmoji = "<:Oni_Tiger:1548443291773566977>",
        location = "Cherry Blossom",
        money = "$600M/s",
    },
    ["eternal lunar dragon"] = {
        displayName = "Eternal Lunar Dragon",
        discordEmoji = "<:Eternal_Lunar_Dragon:1548442744123293766>",
        location = "Cosmic",
        money = "$250M/s",
    },
    ["lava dragon"] = {
        displayName = "Lava Dragon",
        discordEmoji = "<:Lava_Dragon:1548441030783668234>",
        location = "Volcano",
        money = "$100M/s",
    },
    ["skeleton horse"] = {
        displayName = "Skeleton Horse",
        discordEmoji = "<:Skeleton_Horse:1548491359990579250>",
        location = "Angels & Demons",
        money = "$1.3B/s",
    },
    ["pegasus"] = {
        displayName = "Pegasus",
        discordEmoji = "<:Pegasus:1548490925796495452>",
        location = "Angels & Demons",
        money = "$1.3B/s",
    },
    ["trex"] = {
        displayName = "TRex",
        discordEmoji = "<:TRex:1548441514550632508>",
        location = "Prehistoric",
        money = "$25M/s",
    },
    ["t-rex"] = {
        displayName = "TRex",
        discordEmoji = "<:TRex:1548441514550632508>",
        location = "Prehistoric",
        money = "$25M/s",
    },
    ["yeti"] = {
        displayName = "Yeti",
        discordEmoji = "<:Yeti:1548439856785395772>",
        location = "Snow",
        money = "$5M/s",
    },
    ["pure jellyfish"] = {
        displayName = "Pure Jellyfish",
        discordEmoji = "<:Pure_Jellyfish:1548480251321909278>",
        location = "Angels & Demons",
        money = "$225M/s",
    },
    ["tralaledon"] = {
        displayName = "Tralaledon",
        discordEmoji = "<:Tralaledon:1548441688446603435>",
        location = "Prehistoric",
        money = "$32M/s",
    },
    ["gargoyle"] = {
        displayName = "Gargoyle",
        discordEmoji = "<:Gargoyle:1548480842786021436>",
        location = "Angels & Demons",
        money = "$225M/s",
    },
    ["cosmic skeleton boss"] = {
        displayName = "Cosmic Skeleton Boss",
        discordEmoji = "<:Cosmic_Skeleton_Boss:1548442180018770041>",
        location = "Cosmic",
        money = "$45M/s",
    },
    ["razorfang"] = {
        displayName = "RazorFang",
        discordEmoji = "<:RazorFang:1548481759320997928>",
        location = "Angels & Demons",
        money = "$350M/s",
    },
    ["mutant shark"] = {
        displayName = "Mutant Shark",
        discordEmoji = "<:MutantShark:1548443702035353631>",
    },
    ["cerberus"] = {
        displayName = "Cerberus",
        discordEmoji = "<:Cerberus:1548440419107348591>",
        location = "Volcano",
        money = "$8M/s",
    },
    ["centaur"] = {
        displayName = "Centaur",
        discordEmoji = "<:Centaur:1548493515841871935>",
        location = "Angels & Demons",
        money = "$350M/s",
    },
    ["stag"] = {
        displayName = "Stag",
        discordEmoji = "<:Stag:1548443172806459494>",
        location = "Cherry Blossom",
        money = "$145M/s",
    },
    ["cosmic dragon"] = {
        displayName = "Cosmic Dragon",
        discordEmoji = "<:Cosmic_Dragon:1548442406959976579>",
        location = "Cosmic",
        money = "$60M/s",
    },
    ["kraken"] = {
        displayName = "Kraken",
        discordEmoji = "<:Kraken:1548441236476788786>",
        location = "Abyss Ocean",
        money = "$15M/s",
    },
    ["king snake"] = {
        displayName = "King Snake",
        discordEmoji = "<:King_Snake:1548439645849919682>",
        location = "Jungle",
        money = "$3.5M/s",
    },
}

local PET_RARITIES = {
    ["nightflame"] = "Divine",
    ["unicorn"] = "Divine",
    ["kitsune"] = "Divine",
    ["archangel"] = "Divine",
    ["world burner"] = "Divine",
    ["phoenix"] = "Eternal",
    ["ice dragon"] = "Eternal",
    ["mosasaurus"] = "Eternal",
    ["gorilla king"] = "Eternal",
    ["el maja"] = "Eternal",
    ["oni tiger"] = "Eternal",
    ["eternal lunar dragon"] = "Eternal",
    ["lava dragon"] = "Eternal",
    ["skeleton horse"] = "Eternal",
    ["pegasus"] = "Eternal",
    ["trex"] = "Secret",
    ["t-rex"] = "Secret",
    ["yeti"] = "Secret",
    ["pure jellyfish"] = "Secret",
    ["tralaledon"] = "Secret",
    ["gargoyle"] = "Secret",
    ["cosmic skeleton boss"] = "Secret",
    ["razorfang"] = "Secret",
    ["mutant shark"] = "Secret",
    ["cerberus"] = "Secret",
    ["centaur"] = "Secret",
    ["stag"] = "Secret",
    ["cosmic dragon"] = "Secret",
    ["kraken"] = "Secret",
    ["king snake"] = "Secret",
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
local guiParent = playerGui

-- Algunos ejecutores ocultan los ScreenGui que se parentan directamente
-- en PlayerGui. gethui() mantiene el HUD visible sin cambiar su comportamiento.
if type(gethui) == "function" then
    local ok, hiddenUi = pcall(gethui)
    if ok and hiddenUi then
        guiParent = hiddenUi
    end
end

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

for _, parent in ipairs({playerGui, guiParent}) do
    local oldGui = parent:FindFirstChild("AuraEggNotifier")
    if oldGui then
        oldGui:Destroy()
    end
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
    for _, parent in ipairs({playerGui, guiParent}) do
        local gui = parent:FindFirstChild("AuraEggNotifier")
        if gui then
            gui:Destroy()
        end
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

local function findKnownPet(text)
    local textLower = lower(text)
    local names = {}

    for name in pairs(EGG_DATABASE) do
        table.insert(names, name)
    end

    -- Comprueba primero los nombres largos para no cortar "Cosmic Skeleton Boss"
    -- como si fuera un nombre más corto.
    table.sort(names, function(a, b)
        return #a > #b
    end)

    for _, name in ipairs(names) do
        if textLower:find(name, 1, true) then
            local data = EGG_DATABASE[name]
            return safeDiscordText(data.displayName or name)
        end
    end

    return nil
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
    local knownPet = findKnownPet(text)
    if knownPet then
        return knownPet
    end

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

    local textLower = text:lower()
    for _, badWord in ipairs(CONFIG.Blacklist) do
        if textLower:find(badWord, 1, true) then
            return nil
        end
    end

    local keywordHits = 0
    for _, keyword in ipairs(CONFIG.Keywords) do
        if textLower:find(keyword, 1, true) then
            keywordHits = keywordHits + 1
        end
    end

    local eggName = extractEggName(text)
    local normalizedEggName = normalizeEggName(eggName)
    local data = EGG_DATABASE[normalizedEggName] or {}
    local rarityName = detectRarity(text) or PET_RARITIES[normalizedEggName]
    local stableMatch = keywordHits >= 2
        or (textLower:find("egg", 1, true) and textLower:find("spawn", 1, true))
        or data.displayName ~= nil

    if not stableMatch or (not rarityName and CONFIG.NotifyOnlyConfiguredRarities) then
        return nil
    end

    local rarity = RARITIES[rarityName]
    if not rarity then
        return nil
    end

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
        source = (liveMoney ~= "" or liveSpeed ~= "")
            and "Live game data"
            or "Steal an Egg wiki fallback",
        petEmoji = data.discordEmoji or rarity.discordEmoji,
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
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true
screenGui.Parent = guiParent

local root = Instance.new("Frame")
root.Name = "Panel"
root.AnchorPoint = Vector2.new(0.5, 0)
root.Position = UDim2.new(0.5, 0, 0, 18)
root.Size = UDim2.new(1, -24, 0, 450)
root.BackgroundColor3 = Color3.fromRGB(13, 15, 29)
root.BackgroundTransparency = 0.04
root.BorderSizePixel = 0
root.ClipsDescendants = true
root.Parent = screenGui

local rootConstraint = Instance.new("UISizeConstraint")
rootConstraint.MinSize = Vector2.new(280, 360)
rootConstraint.MaxSize = Vector2.new(380, 520)
rootConstraint.Parent = root

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
list.AutomaticCanvasSize = Enum.AutomaticSize.None
list.ScrollingDirection = Enum.ScrollingDirection.Y
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

local function updateListCanvas()
    list.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end

connect(listLayout:GetPropertyChangedSignal("AbsoluteContentSize"), updateListCanvas)
updateListCanvas()

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
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.ClipsDescendants = true
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

    -- Las fuentes de Roblox no renderizan todos los emojis Unicode.
    -- Un badge de texto evita cuadros vacíos y conserva la identidad visual.
    local badge = Instance.new("TextLabel")
    badge.Name = "RarityBadge"
    badge.BackgroundColor3 = event.rarityData.uiColor
    badge.BorderSizePixel = 0
    badge.Position = UDim2.new(0, 18, 0, 10)
    badge.Size = UDim2.new(0, 28, 0, 28)
    badge.Font = Enum.Font.GothamBold
    badge.Text = event.rarityData.badge or "!"
    badge.TextColor3 = Color3.fromRGB(14, 16, 30)
    badge.TextSize = 13
    badge.TextXAlignment = Enum.TextXAlignment.Center
    badge.TextYAlignment = Enum.TextYAlignment.Center
    badge.Parent = card

    local badgeCorner = Instance.new("UICorner")
    badgeCorner.CornerRadius = UDim.new(1, 0)
    badgeCorner.Parent = badge

    local cardTitle = Instance.new("TextLabel")
    cardTitle.BackgroundTransparency = 1
    cardTitle.Position = UDim2.new(0, 54, 0, 10)
    cardTitle.Size = UDim2.new(1, -63, 0, 21)
    cardTitle.Font = Enum.Font.GothamBold
    cardTitle.Text = event.rarity:upper() .. "  |  EGG SPAWNED"
    cardTitle.TextColor3 = event.rarityData.uiColor
    cardTitle.TextSize = 14
    cardTitle.TextXAlignment = Enum.TextXAlignment.Left
    cardTitle.Parent = card

    local cardBody = Instance.new("TextLabel")
    cardBody.BackgroundTransparency = 1
    cardBody.Position = UDim2.new(0, 23, 0, 38)
    cardBody.Size = UDim2.new(1, -32, 0, 0)
    cardBody.AutomaticSize = Enum.AutomaticSize.Y
    cardBody.Font = Enum.Font.Gotham
    cardBody.Text = string.format(
        "[EGG]  %s\n[LOC]  %s\n[CASH]  %s\n[SPEED]  %s\n[TIME]  Spotted just now",
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
    badge.TextTransparency = 1
    cardTitle.TextTransparency = 1
    cardBody.TextTransparency = 1

    TweenService:Create(card, TweenInfo.new(0.22), {
        BackgroundTransparency = 0.08,
    }):Play()
    TweenService:Create(badge, TweenInfo.new(0.22), {
        TextTransparency = 0,
        BackgroundTransparency = 0,
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
    local petEmoji = event.petEmoji or event.rarityData.discordEmoji
    local joinValue = event.joinUrl
        and "[**Click here to join the server**](" .. event.joinUrl .. ")"
        or "`Join link unavailable`"

    return {
        username = CONFIG.Name,
        content = string.format(
            "%s %s\n**%s spawned in %s!**",
            roleMention,
            petEmoji,
            event.egg,
            event.location
        ),
        allowed_mentions = {
            parse = {},
            roles = {event.rarityData.roleId},
        },
        embeds = {{
            author = {
                name = "AURA EGG NOTIFIER  •  STEAL AN EGG TRACKER",
            },
            title = petEmoji .. "  " .. event.egg .. " spotted!",
            url = event.joinUrl,
            description = string.format(
                "## %s %s\n> A **%s** pet was detected in **%s**.\n> This alert was routed automatically to the **%s** role.",
                petEmoji,
                event.egg,
                event.rarity,
                event.location,
                event.rarity
            ),
            color = event.rarityData.color,
            fields = {
                {
                    name = petEmoji .. " Pet",
                    value = "**" .. event.egg .. "**",
                    inline = true,
                },
                {
                    name = event.rarityData.discordEmoji .. " Rarity",
                    value = "`" .. event.rarity .. "`",
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
        badge = "!",
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