--[[
    AURA EGG NOTIFIER • CLEAN REBUILD
    =================================
    Un solo archivo, pensado para ejecutores Roblox.

    Discord:
      Secret  -> gris
      Eternal -> morado
      Divine  -> amarillo

    El webhook anterior quedó expuesto. Genera uno nuevo y colócalo abajo.
]]

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local CONFIG = {
    Name = "AURA EGG NOTIFIER",
    WebhookURL = "PASTE_A_NEW_DISCORD_WEBHOOK_HERE",
    DuplicateWindow = 10,
    ToastSeconds = 12,
}

local ROLE_IDS = {
    Secret = "1544734376640782346",
    Eternal = "1544734452054229173",
    Divine = "1544734510665699389",
}

local RARITIES = {
    Secret = {
        color = 8421504,
        uiColor = Color3.fromRGB(143, 148, 158),
        emoji = "🔮",
        aliases = {"secret", "secreto"},
    },
    Eternal = {
        color = 9133302,
        uiColor = Color3.fromRGB(139, 92, 246),
        emoji = "🌌",
        aliases = {"eternal", "eterno"},
    },
    Divine = {
        color = 16106818,
        uiColor = Color3.fromRGB(245, 197, 66),
        emoji = "✨",
        aliases = {"divine", "divino"},
    },
}

-- Base de datos propia del notifier.
-- Money y velocidad son valores base de la zona; los datos encontrados
-- directamente en el mensaje del juego siempre tienen prioridad.
-- "No confirmado" evita inventar tiempos de eclosión.
local PET_DATA = {
    ["king snake"] = {
        name = "King Snake",
        rarity = "Secret",
        location = "Jungle",
        money = "$3.5M/s",
        hatch = "No confirmado",
        speed = "40K",
    },
    ["yeti"] = {
        name = "Yeti",
        rarity = "Secret",
        location = "Snow",
        money = "$5M/s",
        hatch = "No confirmado",
        speed = "170K",
    },
    ["cerberus"] = {
        name = "Cerberus",
        rarity = "Secret",
        location = "Volcano",
        money = "$8M/s",
        hatch = "No confirmado",
        speed = "700K",
    },
    ["kraken"] = {
        name = "Kraken",
        rarity = "Secret",
        location = "Abyss Ocean",
        money = "$15M/s",
        hatch = "No confirmado",
        speed = "2.5M",
    },
    ["t-rex"] = {
        name = "T-Rex",
        rarity = "Secret",
        location = "Prehistoric",
        money = "$25M/s",
        hatch = "No confirmado",
        speed = "17M–18M",
    },
    ["tralaledon"] = {
        name = "Tralaledon",
        rarity = "Secret",
        location = "Prehistoric",
        money = "$32M/s",
        hatch = "No confirmado",
        speed = "17M–18M",
    },
    ["cosmic skeleton boss"] = {
        name = "Cosmic Skeleton Boss",
        rarity = "Secret",
        location = "Cosmic",
        money = "$45M/s",
        hatch = "No confirmado",
        speed = "700M",
    },
    ["cosmic dragon"] = {
        name = "Cosmic Dragon",
        rarity = "Secret",
        location = "Cosmic",
        money = "$60M/s",
        hatch = "No confirmado",
        speed = "700M",
    },
    ["stag"] = {
        name = "Stag",
        rarity = "Secret",
        location = "Cherry Blossom",
        money = "$145M/s",
        hatch = "No confirmado",
        speed = "2.5B",
    },
    ["mutant shark"] = {
        name = "Mutant Shark",
        rarity = "Secret",
        location = "Titan Temple",
        money = "$215M/s",
        hatch = "No confirmado",
        speed = "7B",
    },
    ["ice dragon"] = {
        name = "Ice Dragon",
        rarity = "Eternal",
        location = "Snow",
        money = "$65M/s",
        hatch = "No confirmado",
        speed = "170K",
    },
    ["phoenix"] = {
        name = "Phoenix",
        rarity = "Eternal",
        location = "Volcano",
        money = "$85M/s",
        hatch = "No confirmado",
        speed = "700K",
    },
    ["lava dragon"] = {
        name = "Lava Dragon",
        rarity = "Eternal",
        location = "Volcano",
        money = "$100M/s",
        hatch = "No confirmado",
        speed = "700K",
    },
    ["el maja"] = {
        name = "El Maja",
        rarity = "Eternal",
        location = "Abyss Ocean",
        money = "$130M/s",
        hatch = "5h 30m",
        speed = "2.5M",
    },
    ["mosasaurus"] = {
        name = "Mosasaurus",
        rarity = "Eternal",
        location = "Prehistoric",
        money = "$180M/s",
        hatch = "6h",
        speed = "17M–18M",
    },
    ["eternal lunar dragon"] = {
        name = "Eternal Lunar Dragon",
        rarity = "Eternal",
        location = "Cosmic",
        money = "$250M/s",
        hatch = "No confirmado",
        speed = "700M",
    },
    ["oni tiger"] = {
        name = "Oni Tiger",
        rarity = "Eternal",
        location = "Cherry Blossom",
        money = "$600M/s",
        hatch = "No confirmado",
        speed = "2.5B",
    },
    ["gorilla king"] = {
        name = "Gorilla King",
        rarity = "Eternal",
        location = "Titan Temple",
        money = "$880M/s",
        hatch = "No confirmado",
        speed = "7B",
    },
    ["unicorn"] = {
        name = "Unicorn",
        rarity = "Divine",
        location = "Cosmic",
        money = "$1B/s",
        hatch = "No confirmado",
        speed = "700M",
    },
    ["kitsune"] = {
        name = "Kitsune",
        rarity = "Divine",
        location = "Cherry Blossom",
        money = "$1.8B/s",
        hatch = "No confirmado",
        speed = "2.5B",
    },
    ["nightflame"] = {
        name = "Nightflame",
        rarity = "Divine",
        location = "Titan Temple",
        money = "$3B/s",
        hatch = "No confirmado",
        speed = "7B",
    },
}

local Players = game:GetService("Players")
local LogService = game:GetService("LogService")
local TextChatService = game:GetService("TextChatService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")

local request = (syn and syn.request)
    or (http and http.request)
    or http_request
    or (fluxus and fluxus.request)
    or request

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local runtimeEnv = (type(getgenv) == "function" and getgenv()) or _G

if runtimeEnv.AURA_EGG_NOTIFIER_STOP then
    pcall(runtimeEnv.AURA_EGG_NOTIFIER_STOP)
end

local connections = {}
local recentEvents = {}
local currentToast
local toastVersion = 0
local shuttingDown = false

local function connect(signal, callback)
    local ok, connection = pcall(function()
        return signal:Connect(callback)
    end)
    if ok and connection then
        table.insert(connections, connection)
    end
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

    local gui = playerGui:FindFirstChild("AuraEggNotifier")
    if gui then
        gui:Destroy()
    end
end

runtimeEnv.AURA_EGG_NOTIFIER_STOP = shutdown

local function clean(value)
    value = tostring(value or "")
    value = value:gsub("<[^>]+>", "")
    value = value:gsub("[%c]", " ")
    return value:match("^%s*(.-)%s*$") or ""
end

local function lower(value)
    return clean(value):lower()
end

local function discordSafe(value)
    value = clean(value)
    value = value:gsub("@", "＠")
    value = value:gsub("`", "'")
    return value
end

local function trimPunctuation(value)
    return clean(value):gsub("[!?,;%.]+$", "")
end

local function findWholeWord(text, word)
    return text:find("%f[%a]" .. word .. "%f[%A]")
end

local function findSpawnIndex(text)
    local textLower = lower(text)
    local best

    for _, marker in ipairs({
        "spawned",
        "appeared",
        "spotted",
        "detected",
        "apareci",
    }) do
        local index = textLower:find(marker, 1, true)
        if index and (not best or index < best) then
            best = index
        end
    end

    return best
end

local function isSpawnMessage(text)
    local textLower = lower(text)
    local hasSpawn = findSpawnIndex(text) ~= nil
    local hasEventShape = textLower:find("spawned in", 1, true)
        or textLower:find("spawned:", 1, true)
        or textLower:find("egg spawned", 1, true)
        or textLower:find("appeared in", 1, true)
        or textLower:find("spotted in", 1, true)
        or textLower:find("detected in", 1, true)
        or textLower:find("huevo apareci", 1, true)

    return hasSpawn and hasEventShape ~= nil
end

local function findPet(text)
    local textLower = lower(text)
    local found
    local foundLength = 0

    for key, data in pairs(PET_DATA) do
        if #key > foundLength and textLower:find(key, 1, true) then
            found = data
            foundLength = #key
        end
    end

    if found then
        return found.name, found
    end

    local spawnIndex = findSpawnIndex(text)
    if spawnIndex then
        local beforeSpawn = text:sub(1, spawnIndex - 1)
        local candidate = beforeSpawn
            :gsub("^[%[%]%(%)%s%-:]+", "")
            :gsub("^[Ee][Tt][Ee][Rr][Nn][Aa][Ll]%s+", "")
            :gsub("^[Dd][Ii][Vv][Ii][Nn][Ee]%s+", "")
            :gsub("^[Ss][Ee][Cc][Rr][Ee][Tt]%s+", "")
            :gsub("[Ee][Gg][Gg]%s*$", "")
        candidate = trimPunctuation(candidate)
        if #candidate > 1 and #candidate < 80 then
            return discordSafe(candidate), nil
        end
    end

    return "Unknown Egg", nil
end

local function findAfterLabel(text, labels)
    local original = tostring(text or "")
    local textLower = original:lower()

    for _, label in ipairs(labels) do
        local startIndex = textLower:find(label, 1, true)
        if startIndex then
            local value = original:sub(startIndex + #label)
            value = value:gsub("^%s*[:%-]?%s*", "")
            value = value:match("^[^|\r\n]+") or value
            value = value:gsub("%s+[Ll]ocation%s*:.*$", "")
            value = value:gsub("%s+[Ss]pawned.*$", "")
            value = trimPunctuation(value)
            if value ~= "" then
                return value
            end
        end
    end

    return nil
end

local function explicitRarity(text)
    local textLower = lower(text)
    local spawnIndex = findSpawnIndex(text)
    if not spawnIndex then
        return nil
    end

    local prefix = textLower:sub(1, spawnIndex - 1)
    local selectedName
    local selectedIndex

    for _, rarityName in ipairs({"Secret", "Eternal", "Divine"}) do
        for _, alias in ipairs(RARITIES[rarityName].aliases) do
            local index = findWholeWord(prefix, alias)
            if index and (not selectedIndex or index > selectedIndex) then
                selectedName = rarityName
                selectedIndex = index
            end
        end
    end

    return selectedName
end

local function extractLocation(text)
    local value = findAfterLabel(text, {"location", "biome", "zona"})
    if value then
        return discordSafe(value)
    end

    local textLower = lower(text)
    local inIndex = textLower:find(" in ", 1, true)
    if inIndex then
        value = text:sub(inIndex + 4)
        value = value:match("^[^!|\r\n]+") or value
        return discordSafe(trimPunctuation(value))
    end

    return nil
end

local function extractMoney(text)
    local value = findAfterLabel(text, {
        "money",
        "mps",
        "income",
        "cash",
    })
    if not value then
        return nil
    end
    return discordSafe(value)
end

local function extractSpeed(text)
    local value = findAfterLabel(text, {
        "recommended speed",
        "required speed",
        "speed required",
    })
    if not value then
        return nil
    end
    return discordSafe(value)
end

local function extractHatchTime(text)
    local value = findAfterLabel(text, {
        "hatch time",
        "grow time",
        "hatching time",
        "eclosion",
    })
    if not value then
        return nil
    end
    return discordSafe(value)
end

local function buildEvent(rawText)
    local text = clean(rawText)
    if text == "" or not isSpawnMessage(text) then
        return nil
    end

    local petName, data = findPet(text)
    local rarityName = data and data.rarity or explicitRarity(text)
    local rarity = rarityName and RARITIES[rarityName]
    if not rarity then
        return nil
    end

    local location = extractLocation(text) or (data and data.location) or "Unknown"
    local money = extractMoney(text) or (data and data.money) or "Not listed"
    local hatch = extractHatchTime(text) or (data and data.hatch) or "Not listed"
    local speed = extractSpeed(text) or (data and data.speed) or "Not listed"

    return {
        pet = discordSafe(petName),
        rarity = rarityName,
        rarityData = rarity,
        location = discordSafe(location),
        money = discordSafe(money),
        hatch = discordSafe(hatch),
        speed = discordSafe(speed),
        time = os.date("%H:%M:%S"),
        timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ"),
        fingerprint = lower(rarityName .. "|" .. petName .. "|" .. location),
    }
end

local function getWebhook()
    return type(CONFIG.WebhookURL) == "string"
        and #CONFIG.WebhookURL > 50
        and not CONFIG.WebhookURL:find("PASTE_", 1, true)
end

local function postWebhook(event)
    if not request or not getWebhook() then
        return
    end

    local roleId = ROLE_IDS[event.rarity]
    local payload = {
        username = CONFIG.Name,
        content = string.format(
            "<@&%s>\n**%s %s spawned in %s!**",
            roleId,
            event.rarity:upper(),
            event.pet,
            event.location
        ),
        allowed_mentions = {
            parse = {},
            roles = {roleId},
        },
        embeds = {{
            title = string.format("%s  %s Egg Spawned", event.rarityData.emoji, event.rarity),
            description = "**" .. event.pet .. "**",
            color = event.rarityData.color,
            fields = {
                {
                    name = "📍 Ubicación",
                    value = "`" .. event.location .. "`",
                    inline = true,
                },
                {
                    name = "🕒 Spawneo",
                    value = "`" .. event.time .. "`",
                    inline = true,
                },
                {
                    name = "💰 Money",
                    value = "`" .. event.money .. "`",
                    inline = true,
                },
                {
                    name = "🥚 Tiempo de eclosión",
                    value = "`" .. event.hatch .. "`",
                    inline = true,
                },
                {
                    name = "⚡ Velocidad recomendada",
                    value = "`" .. event.speed .. "`",
                    inline = true,
                },
            },
            footer = {
                text = "AURA EGG NOTIFIER",
            },
            timestamp = event.timestamp,
        }},
    }

    task.spawn(function()
        pcall(function()
            request({
                Url = CONFIG.WebhookURL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                },
                Body = HttpService:JSONEncode(payload),
            })
        end)
    end)
end

local function showToast(event)
    toastVersion = toastVersion + 1
    local thisVersion = toastVersion

    if currentToast then
        currentToast:Destroy()
        currentToast = nil
    end

    local gui = playerGui:FindFirstChild("AuraEggNotifier")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "AuraEggNotifier"
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.DisplayOrder = 9999
        gui.Parent = playerGui
    end

    local toast = Instance.new("Frame")
    toast.Name = "Alert"
    toast.AnchorPoint = Vector2.new(1, 0)
    toast.Position = UDim2.new(1, -18, 0, 72)
    toast.Size = UDim2.new(0, 330, 0, 170)
    toast.BackgroundColor3 = Color3.fromRGB(20, 21, 30)
    toast.BackgroundTransparency = 1
    toast.BorderSizePixel = 0
    toast.Parent = gui
    currentToast = toast

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = toast

    local stroke = Instance.new("UIStroke")
    stroke.Color = event.rarityData.uiColor
    stroke.Thickness = 2
    stroke.Transparency = 0.1
    stroke.Parent = toast

    local accent = Instance.new("Frame")
    accent.BackgroundColor3 = event.rarityData.uiColor
    accent.BorderSizePixel = 0
    accent.Size = UDim2.new(0, 5, 1, -22)
    accent.Position = UDim2.new(0, 9, 0, 11)
    accent.Parent = toast

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(1, 0)
    accentCorner.Parent = accent

    local title = Instance.new("TextLabel")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 25, 0, 12)
    title.Size = UDim2.new(1, -35, 0, 24)
    title.Font = Enum.Font.GothamBold
    title.Text = event.rarityData.emoji .. "  " .. event.rarity:upper() .. " EGG"
    title.TextColor3 = event.rarityData.uiColor
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = toast

    local body = Instance.new("TextLabel")
    body.BackgroundTransparency = 1
    body.Position = UDim2.new(0, 25, 0, 42)
    body.Size = UDim2.new(1, -35, 0, 112)
    body.Font = Enum.Font.Gotham
    body.Text = string.format(
        "%s\n📍 %s\n🕒 %s\n💰 %s\n🥚 %s\n⚡ %s",
        event.pet,
        event.location,
        event.time,
        event.money,
        event.hatch,
        event.speed
    )
    body.TextColor3 = Color3.fromRGB(235, 237, 245)
    body.TextSize = 12
    body.TextWrapped = true
    body.TextXAlignment = Enum.TextXAlignment.Left
    body.TextYAlignment = Enum.TextYAlignment.Top
    body.Parent = toast

    TweenService:Create(toast, TweenInfo.new(0.2), {
        BackgroundTransparency = 0.04,
    }):Play()

    task.delay(CONFIG.ToastSeconds, function()
        if thisVersion ~= toastVersion or not toast.Parent then
            return
        end
        local fade = TweenService:Create(toast, TweenInfo.new(0.2), {
            BackgroundTransparency = 1,
        })
        fade:Play()
        task.delay(0.22, function()
            if toast then
                toast:Destroy()
            end
        end)
    end)
end

local function processText(rawText)
    if shuttingDown then
        return
    end

    local event = buildEvent(rawText)
    if not event then
        return
    end

    local now = os.clock()
    if recentEvents[event.fingerprint]
        and now - recentEvents[event.fingerprint] < CONFIG.DuplicateWindow then
        return
    end
    recentEvents[event.fingerprint] = now

    showToast(event)
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

print("[AURA EGG NOTIFIER] Clean rebuild ready")