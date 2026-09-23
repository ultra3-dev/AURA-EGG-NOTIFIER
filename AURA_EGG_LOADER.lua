-- AURA EGG NOTIFIER • SMALL LOADER
-- Pega tu webhook solo localmente. No subas el webhook a GitHub.

local env = (type(getgenv) == "function" and getgenv()) or _G
env.AURA_EGG_WEBHOOK = env.AURA_EGG_WEBHOOK or "PASTE_A_NEW_DISCORD_WEBHOOK_HERE"

local source = game:HttpGet(
	"https://raw.githubusercontent.com/ultra3-dev/AURA-EGG-NOTIFIER/main/AURA_EGG_NOTIFIER.lua?v=c35fbd7c023c4863da9764e0fd7bb02ceef468ab"
)

local compile = loadstring or load
if type(compile) ~= "function" then
	error("AURA EGG NOTIFIER: this executor does not expose loadstring or load")
end

local chunk, compileError = compile(source)
if type(chunk) ~= "function" then
	error("AURA EGG NOTIFIER compile error: " .. tostring(compileError))
end

chunk()