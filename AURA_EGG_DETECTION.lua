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

	mosasaurus = 1790371303,
	onitiger = 1790374284,
	elmaja = 1790202668,
	gorillaking = 1790298134,
	eternallunardragon = 1790437810,
	icedragon = 1790407443,
	skeletonhorse = 1790371977,
	lavadragon = 1790413250,
	pegasus = 1790426196,
	phoenix = 1790412937,

	razorfang = 1790416968,
	kraken = 1790414758,
	tralaledon = 1790425469,
	cosmicskeletonboss = 1790437878,
	trex = 1790436430,
	purejellyfish = 1790436560,
	gargoyle = 1790435548,
	centaur = 1790369175,
	yeti = 1790436443,
	cosmicdragon = 1790409556,
	stag = 1790429309,
	mutantshark = 1790409393,
	cerberus = 1790408702,
	kingsnake = 1790325374
}

-- Baseline actualizado: solo se migra una vez a la versión 7.
local LAST_SEEN_INITIAL_TIMES_VERSION = 8
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

