-- AURA EGG NOTIFIER // MODULAR LOADER 2.3.0
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
["AURA_EGG_BOOT.lua"] = "12,16,21,47,49,50,51,52,53,54,55,57,58,59,61,62,63,64,65,66,67,68,69,70,71,72,84,89,95,102,112,117,121,127,134,138,221,233,244,267,271,279,282,287,295,298,311,319,326,341,345,352,358,374,386,402,414,426,435,443,454,466,513,527,535,548,552,567,575,588,592,607,615,628,632,747,758,767,780,881,891,895,906,922,926,931,950,954,960,971,984,988,998,1002,1013,1030,1034,1039,1055,1059,1064,1080,1084,1088,1105,1109,1114,1128,1132,1136,1152,1156,1160,1171,1184,1393,1488,1498,1502,1513,1527,1531,1546,1550,1568,1585,1597,1607,1622,1626,1630,1638,1648,1658,1759,1864,1868,1878,1890,1904,1911,1929,1939,1943,1964,1978,1994,1995,2024,2025,2032,2035,2042,2054,2067,2078,2082,2096,2100,2105,2120,2128,2138,2144,2153,2157,2163,2171,2184,2196,2208,2220,2237,2242,2246,2260,2264,2276,2277,2278,2288,2290,2292,2304,2362,2363,2364,2365,2366,2367,2368,2369,2381,2388,2396,2460,2475,2484,2488,2534,2545,2555,2574,2595,2602,2620,2957,2958,2970,2998,2999,3000,3001,3002,3008,3018,3023,3032,3049,3061,3070",
["AURA_EGG_DETECTION.lua"] = "3,11,47,54,55,73,76,114,119,129,196,205,240,241,270,276,284,296,356,389",
["AURA_EGG_LAST_SEEN.lua"] = "2,13,15,73,77,87,99,124,128,150,151,152,154,167,218,256,262,268,273,279,294,335,355,370,424,474,550,551,552,621,649,672,683,702,726,783,807,815,853,883,1013",
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
local source = game:HttpGet(base .. fileName .. "?v=2.3.0-GOAT-2")
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
