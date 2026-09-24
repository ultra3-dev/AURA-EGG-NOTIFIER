-- AURA EGG 2.0.2 ULTRA // LAST SEEN + CONFIG SERVICES
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
			return "Active Now"
		end
		return "<t:" .. tostring(math.floor(parsed)) .. ":R>"
	end
	return "*No registrada*"
end

local function buildLastSeenContainer(rarity)
	local style = LAST_SEEN_STYLES[rarity] or {emoji = "◈", color = 0xB48CFF, separator = ""}
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
					"## %s %s — Last Seen\n-# %d registradas",
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
			content = "-# Last Seen • AURA FAMILY X • Actualizado <t:"
				.. tostring(math.floor(tonumber(referenceTime) or os.time()))
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

local function upsertLastSeenMessage(payload, onDone)
if scriptStopped then
if onDone then onDone(false) end
return
end

	local baseUrl = getWebhookBaseUrl()
local webhookKey = getLastSeenWebhookKey(baseUrl)
local configuredMessageId = tostring(CONFIG.LastSeenMessageID or "")
local messageId = (configuredMessageId ~= "" and configuredMessageId or nil)
or lastSeenState.messageIds[webhookKey]
or lastSeenState.messageId

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

local function scheduleLastSeenUpdate()
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
scheduleLastSeenStateSave()
	scheduleLastSeenUpdate()
	if lastSeenRefreshScheduler then lastSeenRefreshScheduler(timestamp) end
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

local function refreshConfiguredEmojiLookup()
	for key in pairs(EGG_EMOJI_BY_KEY) do
		EGG_EMOJI_BY_KEY[key] = nil
	end
	for _, rarityEntries in pairs(LAST_SEEN_CATALOG) do
		for _, entry in ipairs(rarityEntries) do
			EGG_EMOJI_BY_KEY[entry.key] = entry.emoji
		end
	end
end

local function clearConfigEditor()
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
	configUi.rarityValue = entry.rarity
	configUi.rarityButton.Text = "RAREZA: " .. entry.rarity:upper()
	configUi.deleteButton.Text = "DELETE: " .. entry.name:upper()
end

local function renderConfigList()
	for _, child in ipairs(configUi.listBody:GetChildren()) do
		if child:IsA("GuiObject") then child:Destroy() end
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
			separator.Name = "RaritySeparator_" .. rarity
			separator.LayoutOrder = layoutOrder
			separator.Size = UDim2.new(1, -6, 0, 20)
			separator.BackgroundColor3 = Color3.fromRGB(38, 25, 61)
			separator.BorderSizePixel = 0
			separator.Text = "━━  " .. rarity:upper() .. "  //  " .. tostring(#catalog) .. " PETS  ━━"
			separator.TextColor3 = rarity == "Divine" and Color3.fromRGB(0, 198, 255)
				or rarity == "Eternal" and Color3.fromRGB(171, 92, 255)
				or rarity == "Secret" and Color3.fromRGB(245, 248, 255)
				or Color3.fromRGB(110, 180, 255)
			separator.Font = Enum.Font.Code
			separator.TextSize = 8
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
			row.Text = "◆  " .. entry.name .. "  //  " .. rarity
			row.TextColor3 = Color3.fromRGB(242, 235, 252)
			row.Font = Enum.Font.Code
			row.TextSize = 9
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
		empty.TextSize = 9
		empty.TextXAlignment = Enum.TextXAlignment.Left
		empty.Parent = configUi.listBody
	end

	configUi.listBody.Size = UDim2.new(1, -8, 0, math.max(30, configUi.listLayout.AbsoluteContentSize.Y))
	configUi.list.CanvasSize = UDim2.new(0, 0, 0, configUi.listLayout.AbsoluteContentSize.Y + 8)
end

configUi.listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	configUi.listBody.Size = UDim2.new(1, -6, 0, configUi.listLayout.AbsoluteContentSize.Y)
	configUi.list.CanvasSize = UDim2.new(0, 0, 0, configUi.listLayout.AbsoluteContentSize.Y + 5)
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
	local options = {"Secret", "Eternal", "Divine", "Mythical", "Legendary", "Cosmic"}
	local current = 1
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

