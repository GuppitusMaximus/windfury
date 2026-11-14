local D = arg[1] or "Windfury"
local NOW = 1794000000
time = function() return NOW end
date = os.date
wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
tinsert = table.insert
local printed = {}
local realprint = print
print = function(s) printed[#printed+1] = s realprint(s) end
local timers = {}
GetTime = function() return NOW end
hooksecurefunc = function(t, k, f) local o = t[k]; t[k] = function(...) o(...) f(...) end end
C_Timer = { After = function(d, f) timers[#timers+1] = f end }
local function runTimers() local t = timers timers = {} for _, f in ipairs(t) do f() end end
-- generic widget stub
local registeredEvents, forbiddenEventAttempts = {}, 0
local function Widget()
  local w = { shown = true }
  return setmetatable(w, { __index = function(t, k)
    if k == "HasFocus" then return function() return false end end
    if k == "IsShown" then return function(s) return s.shown end end
    if k == "Hide" then return function(s) s.shown = false end end
    if k == "Show" then return function(s) s.shown = true end end
    if k == "SetShown" then return function(s, v) s.shown = v; if v and s.onshow then s.onshow(s) end end end
    if k == "SetScript" then return function(s, n, f) if n == "OnShow" then s.onshow = f end; s["_"..n] = f end end
    if k == "RegisterEvent" or k == "RegisterUnitEvent" then return function(s, event, ...)
      registeredEvents[event] = { frame = s, units = { ... } }
      if event == "COMBAT_LOG_EVENT_UNFILTERED" or event == "COMBAT_LOG_EVENT" then
        forbiddenEventAttempts = forbiddenEventAttempts + 1
        error("forbidden combat log registration")
      end
    end end
    if k == "SetText" then return function(s, v) s.text = v end end
    if k == "CreateFontString" or k == "CreateTexture" then return function() return Widget() end end
    if k == "data" or k == "TitleText" then return nil end
    return function() end
  end })
end
local evFrame
local createdFrames = {}
CreateFrame = function(kind, name, parent)
  local w = Widget(); w.testKind, w.testName, w.testParent = kind, name, parent
  createdFrames[#createdFrames + 1] = w
  evFrame = evFrame or w; return w
end
UIParent = Widget(); UISpecialFrames = {}; SlashCmdList = {}
GameTooltip = Widget()

local ns = {}
local sounds = {}
PlaySoundFile = function(path)
  local relative = path:gsub("Interface\\AddOns\\Windfury\\", ""):gsub("\\", "/")
  local file = assert(io.open(D .. "/" .. relative, "rb"), "missing sound: " .. relative)
  file:close()
  sounds[#sounds+1] = relative
  return true
end
UnitClass = function() return "Shaman", "SHAMAN" end
assert(loadfile(D .. "/Core.lua"))("Windfury", ns)
local loader = createdFrames[1]
assert(loadfile(D .. "/Windfury.lua"))("Windfury", ns)
loader._OnEvent(loader, "ADDON_LOADED", "Other")
assert(ns.cfg == nil)
loader._OnEvent(loader, "ADDON_LOADED", "Windfury")
assert(ns.db == WindfuryDB and ns.cfg == WindfuryDB.cfg)
assert(ns.cfg.wfJackpotKind == 5 and ns.cfg.wfHitKind == 1)
assert(ns.cfg.wfSlots == false and ns.cfg.wfBurst == false)
ns.WindfuryEvent(ns.WindfuryListener, "PLAYER_ENTERING_WORLD")
assert(ns.IsShaman)
SlashCmdList.WINDFURY("")
assert(ns.WindfuryPanel(true), "settings must build")
SlashCmdList.WINDFURY("test")
runTimers()
assert(#sounds == 4 and not ns.windfurySlots.failed, "preview plays jackpot and three hits")
assert(not ns.db.debug.windfuryProcs, "preview does not count as proc")
assert(sounds[1] == "Sounds/wf_hit_4.mp3" and sounds[2] == "Sounds/wf_jackpot5_4.mp3")
assert(ns.windfurySlots.frame == nil, "default preview does not create reels")
-- Exercise the optional visual effects as well.
ns.cfg.wfSlots, ns.cfg.wfBurst = true, true
ns.WindfuryEvent(ns.WindfuryListener, "SPELL_UPDATE_COOLDOWN", 123, nil, 0, 0)
assert(not ns.db.debug.windfuryProcs)
ns.WindfuryEvent(ns.WindfuryListener, "SPELL_UPDATE_COOLDOWN", 439440, nil, 0, 0)
runTimers()
assert(#ns.db.debug.windfuryProcs == 1)
SlashCmdList.WINDFURY("off")
local before = #sounds
ns.WindfuryEvent(ns.WindfuryListener, "SPELL_UPDATE_COOLDOWN", 439440, nil, 0, 0)
runTimers()
assert(#sounds == before and #ns.db.debug.windfuryProcs == 1)
SlashCmdList.WINDFURY("test")
runTimers()
assert(#sounds == before + 4, "explicit preview works while disabled")
SlashCmdList.WINDFURY("on")
SlashCmdList.WINDFURY("move")
assert(ns.windfurySlots.moving)
SlashCmdList.WINDFURY("move")
assert(not ns.windfurySlots.moving)
for kind = 1, 3 do for level = 1, 5 do
  ns.cfg.wfHitKind, ns.cfg.wfHitVolume = kind, level
  ns.WindfurySound("hit")
end end
for kind = 1, 5 do for level = 1, 5 do
  ns.cfg.wfJackpotKind, ns.cfg.wfJackpotVolume = kind, level
  ns.WindfurySound("jackpot")
end end
UnitClass = function() return "Warrior", "WARRIOR" end
ns.WindfuryEvent(ns.WindfuryListener, "PLAYER_ENTERING_WORLD")
assert(not ns.IsShaman)
assert(forbiddenEventAttempts == 0)
assert(FishmongerDB == nil, "standalone must not create Fishmonger state")
print("Standalone loading, settings, effects, sounds, commands and detection: OK")

ns.cfg.wfJackpotKind, ns.cfg.wfHitKind = 2, 3
loader._OnEvent(loader, "ADDON_LOADED", "Windfury")
assert(ns.cfg.wfJackpotKind == 2 and ns.cfg.wfHitKind == 3)
assert(ns.cfg.wfSlots == true and ns.cfg.wfBurst == true, "saved choices survive initialization")
print("Fresh defaults and existing saved preferences: OK")
