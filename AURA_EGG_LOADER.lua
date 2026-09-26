-- AURA EGG NOTIFIER // MODULAR LOADER 2.2.8 (REGISTER-SAFE)
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

local compile = loadstring or load
if type(compile) ~= "function" then
	error("AURA EGG NOTIFIER: loadstring/load unavailable")
end

local promotedLocalLines = {
["AURA_EGG_BOOT.lua"] = "12,16,21,47,49,50,51,52,53,54,55,57,58,59,61,62,63,64,65,66,67,68,69,70,71,72,84,89,95,102,112,117,121,127,134,138,221,233,244,267,271,279,282,287,295,298,311,319,326,341,345,352,358,374,386,402,414,426,435,443,454,466,513,527,535,548,552,567,575,588,592,607,615,628,632,747,758,767,780,881,891,895,906,922,926,931,950,954,960,971,984,988,998,1002,1013,1030,1034,1039,1055,1059,1064,1080,1084,1088,1105,1109,1114,1128,1132,1136,1152,1156,1160,1171,1184,1393,1488,1498,1502,1513,1527,1531,1546,1550,1568,1585,1597,1607,1622,1626,1630,1638,1648,1658,1759,1847,1851,1861,1873,1887,1894,1912,1922,1926,1949,1965,1966,1995,1996,2003,2006,2013,2025,2038,2049,2053,2067,2071,2076,2091,2099,2109,2115,2124,2128,2134,2142,2155,2167,2179,2191,2208,2213,2217,2231,2235,2247,2248,2249,2259,2261,2263,2275,2333,2334,2335,2336,2337,2338,2339,2340,2352,2359,2367,2431,2446,2455,2459,2505,2516,2526,2545,2566,2573,2591,2928,2929,2941,2969,2970,2971,2972,2973,2979,2989,2994,3003,3020,3032,3041",
["AURA_EGG_DETECTION.lua"] = "4,12,48,55,56,74,77,115,120,130,197,206,241,242,271,277,285,297,357,390",
["AURA_EGG_LAST_SEEN.lua"] = "2,13,15,73,77,87,99,124,128,150,151,153,166,217,255,261,267,272,278,293,334,354,369,423,473,549,550,551,620,643,654,673,697,754,778,786,824,854,984",
["AURA_EGG_DELIVERY.lua"] = "2,39,141,180,201,219,261,279,285"
}

local function promoteModuleLocals(source, fileName)
local linesToPromote = {}
for lineNumber in (promotedLocalLines[fileName] or ""):gmatch("%d+") do
linesToPromote[tonumber(lineNumber)] = true
end

local output = {}
local lineNumber = 0
for line in (source .. "\n"):gmatch("([^\n]*)\n") do
lineNumber = lineNumber + 1
if linesToPromote[lineNumber] then
local indentation, variableName = line:match("^(%s*)local%s+([%a_][%w_]*)%s*$")
if indentation and variableName then
line = indentation .. variableName .. " = nil"
else
line = line:gsub("^(%s*)local%s+", "%1", 1)
end
end
table.insert(output, line)
end
return table.concat(output, "\n")
end

for _, fileName in ipairs(files) do
local source = game:HttpGet(base .. fileName .. "?v=20260926-2.2.8")
source = promoteModuleLocals(source, fileName)

local chunk, compileError = compile(source, "@AURA_EGG/" .. fileName)
if type(chunk) ~= "function" then
error("AURA EGG NOTIFIER compile error in " .. fileName .. ": " .. tostring(compileError))
end

local ok, runtimeError = pcall(chunk)
if not ok then
error("AURA EGG NOTIFIER runtime error in " .. fileName .. ": " .. tostring(runtimeError))
end
end
