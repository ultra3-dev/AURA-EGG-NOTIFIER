-- AURA EGG 2.0.0 // DELIVERY + EVENT LOOP
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

local function formatEggAlert(text, spawnedAt, count, joinUrl)
local message = replaceRarityWithMention(text)
local eggMentioned
message, eggMentioned = replaceEggNameWithMention(message)
local eggEmoji, eggMention = getEggDisplayData(text)
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
		"> %s\n━━━━━━━━━━━━━━━━━━━━\n- **Spawned:** <t:%d:R>\n━━━━━━━━━━━━━━━━━━━━%s",
		headline,
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

	local hits = 0
	for _, good in ipairs(CONFIG.Keywords) do
		if lower:find(good, 1, true) then hits = hits + 1 end
	end
	
	if hits >= 2 or (lower:find("egg") and lower:find("spawn")) then
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

createVisualCard("SYSTEM ONLINE\nListening to game logs // instant alerts enabled.")
appendConsoleEntry("SYSTEM ONLINE // CONSOLE READY", "MessageInfo", "SCRIPT")
updateStatus("Ready", Color3.fromRGB(99, 255, 154))
scheduleLastSeenUpdate()
print(":: EGG DETECTOR ULTRA-HYPER-VELOCITY READY ::")
end

runNotifierRuntime()
