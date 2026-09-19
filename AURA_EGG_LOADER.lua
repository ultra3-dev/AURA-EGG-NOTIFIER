-- AURA EGG NOTIFIER • SMALL LOADER
-- Pega tu webhook solo localmente. No subas el webhook a GitHub.

local env = (type(getgenv) == "function" and getgenv()) or _G
env.AURA_EGG_WEBHOOK = env.AURA_EGG_WEBHOOK or "PASTE_A_NEW_DISCORD_WEBHOOK_HERE"

local source = game:HttpGet(
	"https://raw.githubusercontent.com/ultra3-dev/AURA-EGG-NOTIFIER/main/AURA_EGG_NOTIFIER.lua"
)

loadstring(source)()