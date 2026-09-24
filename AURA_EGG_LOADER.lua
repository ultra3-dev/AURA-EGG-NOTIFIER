-- AURA EGG NOTIFIER // MODULAR LOADER 2.0.0
-- Mantén los webhooks solo localmente. No los publiques.

local env = (type(getgenv) == "function" and getgenv()) or _G
env.AURA_EGG_WEBHOOK = env.AURA_EGG_WEBHOOK or "PASTE_MAIN_DISCORD_WEBHOOK_HERE"
env.AURA_EGG_LAST_SEEN_WEBHOOK = env.AURA_EGG_LAST_SEEN_WEBHOOK or "PASTE_LAST_SEEN_DISCORD_WEBHOOK_HERE"

local base = "https://raw.githubusercontent.com/ultra3-dev/AURA-EGG-NOTIFIER/main/"
local files = {
	"AURA_EGG_BOOT.lua",
	"AURA_EGG_DETECTION.lua",
	"AURA_EGG_LAST_SEEN.lua",
	"AURA_EGG_DELIVERY.lua"
}

local source = ""
for _, fileName in ipairs(files) do
	source = source .. "\n" .. game:HttpGet(base .. fileName .. "?v=2.0.0-webhook4")
end

local compile = loadstring or load
if type(compile) ~= "function" then
	error("AURA EGG NOTIFIER: loadstring/load unavailable")
end

local chunk, compileError = compile(source)
if type(chunk) ~= "function" then
	error("AURA EGG NOTIFIER compile error: " .. tostring(compileError))
end

chunk()
