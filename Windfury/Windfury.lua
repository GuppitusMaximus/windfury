local ADDON, ns = ...

local C = {
  bg     = { 0.045, 0.055, 0.052 },
  panel  = { 0.075, 0.095, 0.086 },
  raised = { 0.125, 0.165, 0.143 },
  hover  = { 0.180, 0.235, 0.200 },
  line   = { 0.310, 0.275, 0.180 },
  accent = { 0.820, 0.660, 0.350 },
  text   = { 0.940, 0.920, 0.840 },
  dim    = { 0.640, 0.660, 0.590 },
  off    = { 0.380, 0.420, 0.370 },
}
local ACCENT_HEX = "|cffd1a859"

local function Fill(parent, layer, c, alpha, sub)
  local t = parent:CreateTexture(nil, layer, nil, sub)
  t:SetColorTexture(c[1], c[2], c[3], alpha or 1)
  return t
end

-- A one-pixel outline. Returns a function that recolours it.
local function Outline(f, c, alpha)
  local edges = {}
  for i, pts in ipairs({ { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
    local t = Fill(f, "BORDER", c, alpha)
    t:SetPoint(pts[1])
    t:SetPoint(pts[2])
    if i <= 2 then t:SetHeight(1) else t:SetWidth(1) end
    edges[i] = t
  end
  return function(col, a)
    for _, t in ipairs(edges) do t:SetColorTexture(col[1], col[2], col[3], a or 1) end
  end
end

local function Tip(widget, body, title)
  widget:HookScript("OnEnter", function()
    GameTooltip:SetOwner(widget, "ANCHOR_TOP")
    if title then GameTooltip:AddLine(title, C.accent[1], C.accent[2], C.accent[3]) end
    local fs = widget.GetFontString and widget:GetFontString()
    if not title and fs then
      local width, limit = fs:GetStringWidth(), fs:GetWidth()
      if width and limit and width > limit then
        GameTooltip:AddLine(fs:GetText() or "", C.text[1], C.text[2], C.text[3], true)
      end
    end
    GameTooltip:AddLine(body, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  widget:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- kind: nil (ordinary), "primary" (the main action), "danger", "quiet" (no
-- background until hovered) or "tab" (text with an underline when selected;
-- the selected tab is the disabled one).
local BUTTON_COLORS = {
  primary = { { 0.120, 0.340, 0.240 }, { 0.180, 0.460, 0.320 } },
  danger  = { { 0.500, 0.160, 0.160 }, { 0.680, 0.220, 0.220 } },
}
local function FlatButton(parent, text, w, h, kind)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  local bg = Fill(b, "BACKGROUND", C.raised)
  bg:SetAllPoints()
  if kind ~= "tab" and kind ~= "quiet" then Outline(b, C.line, 0.75) end
  local line
  if kind == "tab" then
    line = Fill(b, "ARTWORK", C.accent)
    line:SetPoint("BOTTOMLEFT", 2, 0)
    line:SetPoint("BOTTOMRIGHT", -2, 0)
    line:SetHeight(2)
  end
  local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  fs:SetPoint("CENTER", 0, kind == "tab" and 1 or 0)
  fs:SetWidth(math.max(1, w - (w <= 32 and 4 or 10)))
  fs:SetWordWrap(false)
  fs:SetMaxLines(1)
  fs:SetJustifyH("CENTER")
  b:SetFontString(fs)
  b:SetText(text)
  local over, down = false, false
  local function Paint()
    local on = b:IsEnabled()
    if kind == "tab" then
      bg:SetColorTexture(1, 1, 1, (on and over) and 0.06 or 0)
      line:SetShown(not on)
      local c = (not on and C.text) or (over and C.text) or C.dim
      fs:SetTextColor(c[1], c[2], c[3])
      return
    end
    local c
    if not on then
      c = kind == "quiet" and C.bg or C.panel
    elseif kind == "quiet" then
      c = over and BUTTON_COLORS.danger[2] or C.panel
    else
      local pair = BUTTON_COLORS[kind]
      c = pair and pair[over and 2 or 1] or (over and C.hover or C.raised)
    end
    bg:SetColorTexture(c[1], c[2], c[3], down and on and 0.7 or 1)
    local t = on and C.text or C.off
    fs:SetTextColor(t[1], t[2], t[3])
  end
  b:SetScript("OnEnter", function() over = true Paint() end)
  b:SetScript("OnLeave", function() over, down = false, false Paint() end)
  b:SetScript("OnMouseDown", function() down = true Paint() end)
  b:SetScript("OnMouseUp", function() down = false Paint() end)
  b:SetScript("OnEnable", Paint)
  b:SetScript("OnDisable", function() over, down = false, false Paint() end)
  b:SetScript("OnShow", Paint)
  -- Dynamic action labels (buy counts, list names) stay available in full.
  b:HookScript("OnEnter", function()
    local text = b:GetText()
    local width = fs:GetStringWidth()
    if text and width and width > math.max(1, w - 10) then
      GameTooltip:SetOwner(b, "ANCHOR_TOP")
      GameTooltip:AddLine(text, C.text[1], C.text[2], C.text[3], true)
      GameTooltip:Show()
    end
  end)
  b:HookScript("OnLeave", function() GameTooltip:Hide() end)
  Paint()
  return b
end

local function FlatCheck(parent, checked, onChange)
  local c = CreateFrame("CheckButton", nil, parent)
  c:SetSize(14, 14)
  local bg = Fill(c, "BACKGROUND", C.bg)
  bg:SetAllPoints()
  Outline(c, C.line)
  local mark = Fill(c, "ARTWORK", C.accent)
  mark:SetPoint("TOPLEFT", 3, -3)
  mark:SetPoint("BOTTOMRIGHT", -3, 3)
  c:SetChecked(checked and true or false)
  mark:SetShown(checked and true or false)
  c:SetScript("OnClick", function()
    local v = c:GetChecked() and true or false
    mark:SetShown(v)
    onChange(v)
  end)
  c.Set = function(v) -- show a value without it counting as a click
    c:SetChecked(v and true or false)
    mark:SetShown(v and true or false)
  end
  return c
end

-- Windfury: original celebration and settings, driven by the measured
-- Windfury Weapon cooldown event. /wf opens settings; /wf test previews.
---------------------------------------------------------------------------
-- Experimental amounts never trigger a celebration. UNIT_COMBAT supplies no
-- attacker or spell: these are nearby physical hits, NOT verified Windfury
-- damage. Keep amounts opaque and in memory only; diagnose public timing.
ns.windfurySlotDamage = (function()
  local api = { frame = CreateFrame("Frame") }
  local pending, lastBegin, lastCast
  local recent = {}
  local LEAD, WINDOW = 0.1, 1
  local function Enabled()
    local c = ns.cfg
    return c and c.wf ~= false and c.wfSlots ~= false and c.wfSlotDamage ~= false
  end
  local function CastSummary(cast, delay)
    return { delay = delay, spellID = cast.spellID, secret = cast.secret }
  end
  local function ClearRecent()
    recent = {}
    api.frame:SetScript("OnUpdate", nil)
  end
  local function PruneRecent(now)
    while recent[1] and now - recent[1].at > LEAD do table.remove(recent, 1) end
    if #recent == 0 then api.frame:SetScript("OnUpdate", nil) end
  end
  local function Record(now)
    if not ns.db then return end
    local d = ns.db.debug or {}
    ns.db.debug = d
    local log = d.windfurySlotDamage or { counts = {}, recent = {} }
    d.windfurySlotDamage = log
    log.version = "0.59.3"
    local row = { version = log.version, at = now, time = date("%H:%M:%S"), reason = "listening", hits = {}, prePhysical = 0, earlyPhysical = 0 }
    if lastCast and now - lastCast.at >= 0 and now - lastCast.at <= LEAD then
      row.nearbyCast = CastSummary(lastCast, now - lastCast.at)
    end
    log.recent[#log.recent + 1] = row
    while #log.recent > 20 do table.remove(log.recent, 1) end
    log.counts.started = (log.counts.started or 0) + 1
    return row
  end
  local function Finish(reason)
    if not pending then return end
    local row = pending.record
    if row then
      row.reason = reason
      row.finishedAt = GetTime()
      row.candidates = #pending.amounts
      local log = ns.db and ns.db.debug and ns.db.debug.windfurySlotDamage
      if log then log.counts[reason] = (log.counts[reason] or 0) + 1 end
    end
    pending = nil -- never persist amounts or retain a completed capture
  end
  local function AddCandidate(hit)
    pending.amounts[#pending.amounts + 1] = hit.amount -- opaque; never saved
    local row = pending.record
    if row then
      local delay = hit.at - pending.at
      row.hits[#row.hits + 1] = { delay = delay, secret = hit.secret }
      if delay < 0 then row.prePhysical = row.prePhysical + 1
      elseif delay < LEAD then row.earlyPhysical = row.earlyPhysical + 1 end
    end
    if #pending.amounts > 3 then Finish("too many candidate hits") end
  end
  function api.Cancel(reason, keepRecent)
    Finish(reason or "cancelled")
    if not keepRecent then ClearRecent() end
  end
  function api.Begin(token)
    local now = GetTime()
    api.Cancel("overlapping proc", true)
    if not Enabled() then ClearRecent(); return end
    PruneRecent(now)
    pending = { token = token, at = now, amounts = {}, record = Record(now) }
    local overlap = lastBegin and now - lastBegin < WINDOW
    lastBegin = now
    -- A preceding attack can itself proc Windfury. Record it without vetoing
    -- the capture; later casts still make the candidate hit window ambiguous.
    if overlap then Finish("overlapping proc"); ClearRecent(); return end
    -- The triggering hit can arrive just before the cooldown callback. Consume
    -- the short buffer once, in arrival order, without claiming hit identity.
    local preceding = recent
    ClearRecent()
    for _, hit in ipairs(preceding) do
      if pending then AddCandidate(hit) end
    end
  end
  function api.Update(now)
    if not pending then return end
    if not Enabled() then Finish("disabled"); return end
    if now - pending.at < WINDOW then return end
    if #pending.amounts == 0 then Finish("no candidate hits"); return end
    local ok, shown = pcall(ns.windfurySlots.SetDamage, pending.token, pending.amounts)
    Finish(ok and shown and "shown as estimates" or "display unavailable")
  end
  function api.OnEvent(_, event, unit, action, flag, amount, school)
    local now = GetTime()
    if event == "PLAYER_TARGET_CHANGED" then api.Cancel("target changed"); return end
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
      if ns.Secret(unit) then api.Cancel("secret cast classification"); return end
      if unit ~= "player" then return end
      -- For this event, action is castGUID and flag is spellID. Never inspect
      -- the GUID or persist a secret spell ID; only save public diagnostics.
      lastCast = { at = now, secret = ns.Secret(flag) and true or false }
      if not lastCast.secret and type(flag) == "number" and flag > 0 and flag < math.huge and flag % 1 == 0 then
        lastCast.spellID = flag
      end
      if pending and pending.record then
        pending.record.followingCast = CastSummary(lastCast, now - pending.at)
      end
      if pending then api.Cancel("player cast during capture") end
      return
    end
    if event ~= "UNIT_COMBAT" then return end
    if not Enabled() then api.Cancel("disabled"); return end
    if pending and now - pending.at >= WINDOW then api.Update(now) end
    if ns.Secret(unit) or ns.Secret(action) or ns.Secret(school) then api.Cancel("secret hit classification"); return end
    if unit ~= "target" or action ~= "WOUND" or school ~= 1 then return end
    local secret = ns.Secret(amount)
    if not secret and (type(amount) ~= "number" or amount ~= amount or amount < 0 or amount == math.huge) then
      api.Cancel("invalid hit amount"); return
    end
    local hit = { at = now, amount = amount, secret = secret and true or false }
    if pending then AddCandidate(hit); return end
    local slots = ns.windfurySlots
    if slots and (slots.moving or (slots.frame and slots.frame.active and slots.frame.demo)) then return end
    PruneRecent(now)
    recent[#recent + 1] = hit
    -- Keep a fourth candidate so a busy burst is rejected, not truncated.
    if #recent > 4 then table.remove(recent, 1) end
    api.frame:SetScript("OnUpdate", function()
      if not Enabled() then ClearRecent() else PruneRecent(GetTime()) end
    end)
  end
  api.frame:RegisterUnitEvent("UNIT_COMBAT", "target")
  api.frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
  api.frame:RegisterEvent("PLAYER_TARGET_CHANGED")
  api.frame:SetScript("OnEvent", api.OnEvent)
  return api
end)()

-- Reels use addon-owned frames and layered goblin art. Experimental hit amounts are
-- revealed whole: a protected number cannot be split into digits or totalled.
ns.windfurySlots = (function()
  local api = {}
  local serial = 0
  local LAND, END = 0.78, 2.5
  local SCALE = 1 / 3
  local ART = "Interface\\AddOns\\" .. ADDON .. "\\Art\\wf_goblin_"
  local icons = { "Interface\\Icons\\Spell_Nature_Cyclone",
    "Interface\\Icons\\Spell_Nature_Lightning", "Interface\\Icons\\Spell_Fire_FlameShock",
    "Interface\\Icons\\Spell_Nature_HealingWaveGreater" }
  local gold = { 1, 0.72, 0.20 }

  local function Position(f)
    local c = ns.cfg or {}
    local x, y = c.wfSlotX, c.wfSlotY
    if type(x) ~= "number" or x ~= x or math.abs(x) > 10000 then x = 0 end
    if type(y) ~= "number" or y ~= y or math.abs(y) > 10000 then y = 120 end
    f:ClearAllPoints()
    f:SetPoint("CENTER", UIParent, "CENTER", x / SCALE, y / SCALE)
  end

  function api.Stop(keepRecent)
    ns.windfurySlotDamage.Cancel("animation stopped", keepRecent)
    api.moving = false
    local f = api.frame
    if not f then return end
    f.active = false
    f.damageCount = 0
    for _, reel in ipairs(f.reels or {}) do
      if reel.amount then reel.amount:SetText(""); reel.amount:Hide() end
    end
    f:SetScript("OnUpdate", nil)
    f:StopMovingOrSizing()
    f:EnableMouse(false)
    f:Hide()
  end

  function api.Fail(err)
    api.Stop()
    api.failed = true -- a broken renderer must not retry every combat frame
    if ns.db then
      ns.db.debug = ns.db.debug or {}
      ns.db.debug.windfurySlotError = tostring(err):sub(1, 200)
    end
  end

  local function Build()
    local f = CreateFrame("Frame", nil, UIParent)
    api.frame = f -- even partial construction can be hidden after an error
    f:Hide()
    f:SetScale(SCALE)
    f:SetSize(208, 70)
    f:SetFrameStrata("HIGH")
    f:SetFrameLevel(100)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(false)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) if api.moving then self:StartMoving() end end)
    f:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      if not api.moving or not ns.db then return end
      local x, y = self:GetCenter()
      local cx, cy = UIParent:GetCenter()
      if ns.Secret(x) or ns.Secret(y) or ns.Secret(cx) or ns.Secret(cy) then return end
      if type(x) == "number" and type(y) == "number" and type(cx) == "number" and type(cy) == "number" then
        -- Saved offsets use UIParent units, independent of the art's scale.
        ns.db.cfg.wfSlotX, ns.db.cfg.wfSlotY = x * SCALE - cx, y * SCALE - cy
        Position(self)
      end
    end)
    -- Apply the requested above-character placement once; later drag choices
    -- remain user-owned. This is a HUD position, not a tracked unit anchor.
    if ns.cfg and ns.cfg.wfSlotArtPlacement ~= 1 then
      ns.cfg.wfSlotX, ns.cfg.wfSlotY, ns.cfg.wfSlotArtPlacement = 0, 120, 1
    end
    Position(f)
    f.fallback = CreateFrame("Frame", nil, f)
    f.fallback:SetAllPoints(f)
    f.fallback:SetFrameLevel(100)
    local bg = Fill(f.fallback, "BACKGROUND", { 0.025, 0.035, 0.055 }, 0.94)
    bg:SetAllPoints()
    Outline(f.fallback, gold)
    f.frontLayer = CreateFrame("Frame", nil, f)
    f.frontLayer:SetAllPoints(f)
    f.frontLayer:SetFrameLevel(103) -- above reel views (101) and strips (102)
    f.frontLayer:EnableMouse(false)
    f.particleLayer = CreateFrame("Frame", nil, f)
    f.particleLayer:SetAllPoints(f)
    f.particleLayer:SetFrameLevel(104)
    f.particleLayer:EnableMouse(false)
    local missing, missingSet = {}, {}
    local function Request(texture, suffix)
      local ok, result = pcall(texture.SetTexture, texture, ART .. suffix .. ".tga")
      if not ok or ns.Secret(result) or result == false then
        if not missingSet[suffix] then missing[#missing + 1] = suffix; missingSet[suffix] = true end
      end
    end
    local function Layer(parent, suffix, layer, sub, blend)
      local texture = parent:CreateTexture(nil, layer, nil, sub)
      texture:SetAllPoints(f)
      Request(texture, suffix)
      texture:SetBlendMode(blend or "BLEND")
      return texture
    end
    f.back = Layer(f, "back", "BACKGROUND", 0)
    f.bezel = Layer(f.frontLayer, "bezel", "ARTWORK", 0)
    f.green = Layer(f.frontLayer, "green", "OVERLAY", 0, "ADD")
    f.gold = Layer(f.frontLayer, "gold", "OVERLAY", 1, "ADD")
    f.green:SetAlpha(0)
    f.gold:SetAlpha(0)
    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.hint:SetPoint("TOP", f, "BOTTOM", 0, -6)
    f.hint:SetText("Drag to move. /wf move to lock.")
    f.hint:Hide()
    if C_Spell and type(C_Spell.GetSpellTexture) == "function" then
      local ok, icon = pcall(C_Spell.GetSpellTexture, 8232)
      if ok and not ns.Secret(icon) and (type(icon) == "number" or type(icon) == "string") then icons[1] = icon end
    end
    f.reels, f.coins = {}, {}
    for i = 1, 3 do
      local view = CreateFrame("Frame", nil, f)
      view:SetFrameLevel(101)
      view:SetSize(46, 46)
      view:SetPoint("CENTER", f, "CENTER", (i - 2) * 56, 1)
      view:SetClipsChildren(true)
      local strip = CreateFrame("Frame", nil, view)
      strip:SetFrameLevel(102)
      strip:SetSize(44, 144)
      strip:SetPoint("CENTER")
      local reel = { view = view, strip = strip, textures = {}, stop = 0.24 + i * 0.18 }
      f.reels[i] = reel
      reel.amount = view:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      reel.amount:SetPoint("CENTER")
      reel.amount:SetSize(64, 40)
      reel.amount:SetWordWrap(false)
      reel.amount:SetTextColor(1, 0.90, 0.45)
      if STANDARD_TEXT_FONT then reel.amount:SetFont(STANDARD_TEXT_FONT, 22, "OUTLINE") end
      reel.amount:Hide()
      for row = -1, 1 do
        local tex = strip:CreateTexture(nil, "ARTWORK")
        tex:SetSize(42, 42)
        tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        reel.textures[row + 2] = tex
      end
    end
    f.flatFlash = Fill(f.frontLayer, "OVERLAY", gold, 1, 2)
    f.flatFlash:SetAllPoints(f)
    f.flatFlash:SetAlpha(0)
    for i = 1, 18 do
      local tex = f.particleLayer:CreateTexture(nil, "OVERLAY", nil, 2)
      Request(tex, "coin")
      tex:SetBlendMode("BLEND")
      tex:Hide()
      local angle = (20 + (i - 1) * 140 / 17) * math.pi / 180
      local speed = 115 + (i % 4) * 26
      f.coins[i] = { texture = tex, vx = math.cos(angle) * speed,
        vy = math.sin(angle) * speed + 35, size = 16 + (i % 3) * 3, turn = i * 1.7 }
    end
    -- SetTexture acceptance is not proof of visible art. New files still need
    -- a full client restart. Explicit rejection gets a complete safe fallback.
    f.useGoblinArt = #missing == 0
    for _, texture in ipairs({ f.back, f.bezel, f.green, f.gold }) do texture:SetShown(f.useGoblinArt) end
    f.fallback:SetShown(not f.useGoblinArt)
    f.flatFlash:SetShown(not f.useGoblinArt)
    f.flash = f.useGoblinArt and f.gold or f.flatFlash
    if not f.useGoblinArt then
      for _, coin in ipairs(f.coins) do coin.texture:SetAtlas("coin-gold") end
      print("|cff33ccffWindfury|r: New Windfury art was unavailable. Fully quit and reopen WoW to load it.")
    end
    if ns.db then
      ns.db.debug = ns.db.debug or {}
      ns.db.debug.windfurySlotArt = { version = "0.59.3", state = f.useGoblinArt and "requested" or "fallback", missing = missing }
    end
    f.ready = true
    return f
  end

  local function Render(f, t)
    f:SetAlpha(t < f.fadeAt and 1 or math.max(0, (f.ends - t) / (f.ends - f.fadeAt)))
    for i, reel in ipairs(f.reels) do
      local p = math.min(1, t / reel.stop)
      local travel = (6 + i * 2) * (1 - p) ^ 3
      local step, fraction = math.floor(travel), travel % 1
      reel.landed = p == 1
      local showAmount = reel.landed and i <= (f.damageCount or 0)
      reel.amount:SetShown(showAmount)
      reel.strip:SetShown(not showAmount)
      for row = -1, 1 do
        local tex = reel.textures[row + 2]
        local index = (step + row) % #icons + 1
        if tex.slotIcon ~= index then tex:SetTexture(icons[index]); tex.slotIcon = index end
        tex:ClearAllPoints()
        tex:SetPoint("CENTER", reel.strip, "CENTER", 0, (row - fraction) * 48)
        tex:SetVertexColor(1, reel.landed and 1 or 0.86, reel.landed and 1 or 0.66)
      end
    end
    local age = t - f.land
    f.green:SetAlpha(f.useGoblinArt and (age < 0 and (0.14 + 0.12 * math.sin(t * 18) ^ 2)
      or 0.12 + 0.38 * math.exp(-age * 2.4) * (0.5 + 0.5 * math.cos(age * 14))) or 0)
    f.flash:SetAlpha(age >= 0 and math.max(0, (f.useGoblinArt and 0.55 or 0.24)
      * (1 - age / (f.useGoblinArt and 0.4 or 0.25))) or 0)
    for _, coin in ipairs(f.coins) do
      local tex = coin.texture
      if age < 0 then tex:Hide()
      else
        tex:Show()
        tex:ClearAllPoints()
        tex:SetPoint("CENTER", f, "CENTER", coin.vx * age - (f.useGoblinArt and 12 or 0),
          coin.vy * age - 150 * age * age - (f.useGoblinArt and 60 or 0))
        tex:SetSize(coin.size * (0.28 + 0.72 * math.abs(math.cos(age * 12 + coin.turn))), coin.size)
        tex:SetRotation(age * 5 + coin.turn)
        tex:SetAlpha(math.min(1, math.max(0, (1.65 - age) / 0.55)))
      end
    end
  end

  function api.SetDamage(token, amounts)
    local f = api.frame
    if not f or not f.active or f.token ~= token or not f.damageMode then return false end
    if #amounts > 3 then return false end
    for i = 1, #amounts do
      -- This C widget method accepts secret numbers. No tostring, Lua format,
      -- arithmetic, text measurement, saved values, or value-dependent layout.
      f.reels[i].amount:SetFormattedText("%s", amounts[i])
    end
    f.damageCount = #amounts
    return true
  end

  local function Layout(f, damage)
    f.land, f.ends, f.fadeAt = damage and 1.28 or LAND, damage and 3 or END, damage and 2.35 or 1.85
    f:SetSize(f.useGoblinArt and 384 or (damage and 256 or 208), f.useGoblinArt and 192 or 70)
    local centers = { { 0.228, 0.495 }, { 0.464, 0.505 }, { 0.705, 0.52 } }
    for i, reel in ipairs(f.reels) do
      reel.view:SetSize(f.useGoblinArt and 66 or (damage and 70 or 46), 46)
      reel.view:ClearAllPoints()
      if f.useGoblinArt then
        reel.view:SetPoint("CENTER", f, "CENTER", (centers[i][1] - 0.5) * 384, (0.5 - centers[i][2]) * 192)
      else
        reel.view:SetPoint("CENTER", f, "CENTER", (i - 2) * (damage and 78 or 56), 1)
      end
      reel.stop = damage and (0.92 + i * 0.12) or (0.24 + i * 0.18)
    end
  end

  function api.Start(how)
    if api.failed then return nil end
    api.Stop(how ~= "test")
    local f = api.frame or Build()
    serial = serial + 1
    f.token = serial
    f.damageMode = ns.cfg and ns.cfg.wfSlotDamage ~= false
    f.demo = how == "test"
    Layout(f, f.damageMode)
    f.born, f.active = GetTime(), true
    f.damageCount = 0
    if f.damageMode then
      if f.demo then api.SetDamage(f.token, { 123, 456, 789 })
      else ns.windfurySlotDamage.Begin(f.token) end
    end
    f.hint:Hide()
    Render(f, 0)
    f:SetScript("OnUpdate", function(self)
      local t = GetTime() - self.born
      ns.windfurySlotDamage.Update(GetTime())
      if t >= self.ends then api.Stop(true); return end
      local ok, err = pcall(Render, self, math.max(0, t))
      if not ok then api.Fail(err) end
    end)
    f:Show()
    return f.land
  end

  function api.Move()
    if api.moving then api.Stop(); return end
    if api.failed then return end
    api.Stop()
    local f = api.frame or Build()
    Layout(f, false)
    Render(f, LAND)
    for _, coin in ipairs(f.coins) do coin.texture:Hide() end
    f.flash:SetAlpha(0)
    f.green:SetAlpha(f.useGoblinArt and 0.14 or 0)
    f.hint:Show()
    api.moving = true
    f:EnableMouse(true)
    f:Show()
  end
  return api
end)()

ns.windfuryCelebration = (function()
  local SOUNDS = "Interface\\AddOns\\" .. ADDON .. "\\Sounds\\"
  local count = 0
  local burst, panel, syncs

  local function Note(what) -- a short tally of what the game showed, for tuning
    if not ns.db then return end
    ns.db.debug = ns.db.debug or {}
    local log = ns.db.debug.windfuryDetection or {}
    ns.db.debug.windfuryDetection = log
    if log[what] == nil then -- (no more than 120 different things are tallied)
      local n = 0
      for _ in pairs(log) do n = n + 1 end
      if n >= 120 then return end
    end
    log[what] = (log[what] or 0) + 1
  end

  -- A brief global world-text size change. This does not identify individual
  -- damage amounts. Keep the user's exact baseline and own only our change.
  local pulseFrame = CreateFrame("Frame")
  local pulse, nextRestore = nil, 0
  local PULSE_SECONDS, PULSE_FACTOR = 2, 3
  local function ScaleInfo(name)
    local get = C_CVar and C_CVar.GetCVarInfo or GetCVarInfo
    if type(get) ~= "function" then return nil, "API unavailable" end
    local ok, value, _, _, _, locked, secure, readOnly = pcall(get, name)
    if not ok then return nil, "read failed" end
    if ns.Secret(value) or ns.Secret(locked) or ns.Secret(secure) or ns.Secret(readOnly) then return nil, "secret setting" end
    if value == nil then return nil, "absent" end
    if type(value) ~= "string" and type(value) ~= "number" then return nil, "invalid setting" end
    local number = tonumber(value)
    if not number or number ~= number or number <= 0 or number >= 100 then return nil, "invalid scale" end
    return { raw = tostring(value), number = number, writable = locked == false and secure == false and readOnly == false }
  end
  local function SetScale(name, value)
    -- The current API requires a public, nonsecure, writable CVar. Check
    -- runtime flags each time, including when restoring during combat/logout.
    local info, why = ScaleInfo(name)
    if not info then return false, why end
    if not info.writable then return false, "setting locked" end
    local set = C_CVar and C_CVar.SetCVar or SetCVar
    if type(set) ~= "function" then return false, "write API unavailable" end
    local ok, accepted = pcall(set, name, value)
    if not ok then return false, "write failed" end
    if ns.Secret(accepted) then return false, "write result secret" end
    if accepted == false then return false, "write refused" end
    return true
  end
  local function SameScale(a, b) return math.abs(a - b) < 0.00001 end
  local function FinishPulse(reason)
    if pulse then
      pulse.pending, pulse.active, pulse.reason = false, false, reason
      pulse.finishedAt = GetTime()
    end
    pulseFrame:SetScript("OnUpdate", nil)
  end
  local function RestorePulse(reason)
    if not pulse or not pulse.pending then return end
    pulse.active = false
    local info, why = ScaleInfo(pulse.cvar)
    if not info then pulse.reason = why; return end
    if SameScale(info.number, pulse.beforeNumber) then FinishPulse(reason); return end
    if not SameScale(info.number, pulse.appliedNumber) then
      FinishPulse("changed elsewhere") -- a user or another addon owns the new value
      return
    end
    local ok, failure = SetScale(pulse.cvar, pulse.before)
    local after = ScaleInfo(pulse.cvar)
    if after and SameScale(after.number, pulse.beforeNumber) then
      FinishPulse(reason)
      Note("text pulse restored")
    else
      pulse.reason = failure or (ok and "restore not confirmed" or "restore failed")
    end
  end
  local function WatchPulse()
    pulseFrame:SetScript("OnUpdate", function()
      if not pulse or not pulse.pending then pulseFrame:SetScript("OnUpdate", nil); return end
      local now = GetTime()
      if now >= pulse.untilAt and now >= nextRestore then
        nextRestore = now + 1
        RestorePulse("expired")
      end
    end)
  end
  local function PulseNumbers()
    if not ns.db then return end
    if pulse and pulse.pending then
      local current = ScaleInfo(pulse.cvar)
      if pulse.active and current and SameScale(current.number, pulse.appliedNumber) then
        pulse.untilAt = GetTime() + PULSE_SECONDS
        return -- extend the pulse; never multiply an already enlarged scale
      end
      RestorePulse("before next pulse")
      if pulse.pending then return end
    end
    local name = "WorldTextScale_v2"
    local info, why = ScaleInfo(name)
    if not info and why == "absent" then name = "WorldTextScale"; info, why = ScaleInfo(name) end
    if not info or not info.writable then
      Note("text pulse skipped: " .. (why or "setting locked"))
      ns.db.debug = ns.db.debug or {}
      ns.db.debug.windfuryTextPulseCheck = { cvar = name, at = GetTime(), reason = why or "setting locked" }
      return
    end
    -- Five is a conservative visual cap, not an asserted engine limit. A user
    -- already at/above it keeps their chosen size.
    local target = math.min(5, info.number * PULSE_FACTOR)
    if target <= info.number then Note("text pulse skipped: size cap"); return end
    ns.db.debug = ns.db.debug or {}
    pulse = { version = "0.55.12", duration = PULSE_SECONDS, factor = PULSE_FACTOR,
      cvar = name, before = info.raw, beforeNumber = info.number,
      appliedNumber = tonumber(("%.3f"):format(target)), pending = true, active = false,
      startedAt = GetTime(), untilAt = GetTime() + PULSE_SECONDS }
    ns.db.debug.windfuryTextPulse = pulse -- recover a pending restore after /reload
    local ok, failure = SetScale(name, ("%.3f"):format(target))
    pulse.writeOK = ok
    local after = ScaleInfo(name)
    if after then
      if SameScale(after.number, info.number) then
        FinishPulse(failure or "size change ignored")
        Note("text pulse skipped: " .. pulse.reason)
        return
      end
      if not SameScale(after.number, pulse.appliedNumber) then
        FinishPulse("changed elsewhere") -- another addon may react within SetCVar
        Note("text pulse skipped: size changed elsewhere")
        return
      end
      pulse.applied = after.raw
      pulse.active = true
      Note("text pulse applied")
    else
      pulse.reason = failure or "size change not confirmed"
    end
    nextRestore = 0
    WatchPulse()
  end
  pulseFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" and not pulse then
      local saved = ns.db and ns.db.debug and ns.db.debug.windfuryTextPulse
      if type(saved) == "table" and saved.pending and
        (saved.cvar == "WorldTextScale_v2" or saved.cvar == "WorldTextScale") and
        type(saved.before) == "string" and type(saved.beforeNumber) == "number" and
        type(saved.appliedNumber) == "number" then
        pulse = saved
        pulse.untilAt, nextRestore = GetTime(), 0
        WatchPulse()
        RestorePulse("reload recovery")
      end
    elseif event == "PLAYER_LOGOUT" then RestorePulse("logout")
    elseif event == "PLAYER_REGEN_ENABLED" and pulse and pulse.pending and not pulse.active then RestorePulse("after combat") end
  end)
  for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_LOGOUT", "PLAYER_REGEN_ENABLED" }) do pulseFrame:RegisterEvent(event) end

  local function Burst()
    if not burst then
      burst = CreateFrame("Frame", nil, UIParent)
      burst:SetSize(600, 120)
      burst:SetPoint("CENTER", UIParent, "CENTER", 0, 150)
      burst:SetFrameStrata("HIGH")
      burst.text = burst:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
      burst.text:SetPoint("CENTER")
      pcall(function() burst.text:SetFont(STANDARD_TEXT_FONT, 52, "THICKOUTLINE") end)
      burst.text:SetText("WINDFURY!")
      burst.text:SetTextColor(1, 0.82, 0.2)
      burst.sub = burst:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
      burst.sub:SetPoint("TOP", burst.text, "BOTTOM", 0, -2)
      burst.sub:SetText("JACKPOT")
      burst.sub:SetTextColor(1, 1, 1)
      -- a wash of gold over the whole screen for an instant
      burst.flash = UIParent:CreateTexture(nil, "BACKGROUND")
      burst.flash:SetAllPoints(UIParent)
      burst.flash:SetColorTexture(1, 0.75, 0.15)
      pcall(function() burst.flash:SetBlendMode("ADD") end)
      burst.flash:Hide()
      burst:Hide()
      burst:SetScript("OnUpdate", function(self)
        local t = GetTime() - self.began
        if t >= 1.1 then
          self:Hide()
          self.flash:Hide()
          return
        end
        -- slams in big, settles, then drifts up and fades
        local scale = t < 0.09 and (1.7 - t / 0.09 * 0.7) or 1 + 0.04 * math.sin((t - 0.09) * 30) * math.max(0, 1 - t * 2)
        self:SetScale(scale)
        self:SetAlpha(t < 0.6 and 1 or math.max(0, 1 - (t - 0.6) / 0.5))
        self:ClearAllPoints()
        self:SetPoint("CENTER", UIParent, "CENTER", 0, (150 + math.max(0, t - 0.3) * 60) / scale)
        if self.flashOn then self.flash:SetAlpha(math.max(0, 0.22 * (1 - t / 0.28))) end
      end)
    end
    burst.began = GetTime()
    burst.flashOn = ns.cfg.wfFlash ~= false
    burst.flash:SetShown(burst.flashOn)
    burst:Show()
  end

  -- The game plays an addon's sound at one fixed loudness, so each sound comes
  -- in five recordings, quiet (1) to full (5), and the setting picks one.
  -- Fall back to the chosen full-loudness recording, then the original sound
  -- if the client has not discovered new files yet (a full restart is needed).
  -- The jackpot comes in several kinds; the setting picks one.
  local HITS = { "Original deep hit", "Two-handed axe", "Two-handed mace" }
  local function HitKind()
    local k = math.floor(tonumber(ns.cfg.wfHitKind) or 1)
    return HITS[k] and k or 1
  end
  local JACKPOTS = { "Bells and coins", "Slot machine: reels, then the win", "Cash register", "Coin shower", "Windfury storm" }
  local function JackpotKind()
    local k = math.floor(tonumber(ns.cfg.wfJackpotKind) or 1)
    return JACKPOTS[k] and k or 1
  end
  function ns.WindfurySound(which)
    if not PlaySoundFile then return end
    local level = math.max(1, math.min(5, math.floor(tonumber(ns.cfg[which == "hit" and "wfHitVolume" or "wfJackpotVolume"]) or 4)))
    local name = which
    if which == "hit" and HitKind() > 1 then name = "hit" .. HitKind() end
    if which == "jackpot" and JackpotKind() > 1 then name = "jackpot" .. JackpotKind() end
    local ok, will = pcall(PlaySoundFile, ("%swf_%s_%d.mp3"):format(SOUNDS, name, level), "Master")
    if not ok or will == false or will == nil then
      ok, will = pcall(PlaySoundFile, ("%swf_%s.mp3"):format(SOUNDS, name), "Master")
      if name ~= which and (not ok or will == false or will == nil) then
        pcall(PlaySoundFile, ("%swf_%s.mp3"):format(SOUNDS, which), "Master")
      end
    end
  end

  -- One notification is one celebration. The old swing-burst throttle is
  -- intentionally absent; this path uses the measured Windfury cooldown ID.
  local function Proc(how)
    local c = ns.cfg
    if not c or (c.wf == false and how ~= "test") then return end
    if how ~= "test" then
      count = count + 1
      Note("proc by " .. how)
      -- the last few, with the time and what set each off, so a wrong one can be traced
      local d = ns.db and ns.db.debug
      if d then
        d.windfuryProcs = d.windfuryProcs or {}
        table.insert(d.windfuryProcs, ("%s by %s"):format(date("%H:%M:%S"), how))
        while #d.windfuryProcs > 40 do table.remove(d.windfuryProcs, 1) end
      end
    end
    if c.wfTextPulse ~= false then PulseNumbers() end
    if c.wfHit ~= false then
      ns.WindfurySound("hit")
      -- One impact and two rapid echoes celebrate the three-hit burst.
      -- Keep these cosmetic repeats separate from proc detection and counting.
      local function ExtraHit()
        if ns.cfg.wfHit ~= false and (ns.cfg.wf ~= false or how == "test") then ns.WindfurySound("hit") end
      end
      C_Timer.After(0.1, ExtraHit)
      C_Timer.After(0.2, ExtraHit)
    end
    if c.wfJackpot ~= false then ns.WindfurySound("jackpot") end
    if c.wfSlots ~= false then
      local ok, err = pcall(ns.windfurySlots.Start, how)
      if not ok then ns.windfurySlots.Fail(err) end
    end
    if c.wfBurst ~= false then
      local ok, err = pcall(Burst)
      if not ok then -- say so in the record, and build it afresh next time
        Note("burst failed: " .. tostring(err):sub(1, 120))
        if burst then pcall(function() burst:Hide() end) end
        burst = nil
      end
    end
    -- and a line in the game's own floating combat text, where it is switched on
    if c.wfText ~= false and CombatText_AddMessage and CombatText_StandardScroll then
      pcall(CombatText_AddMessage, "WINDFURY!", CombatText_StandardScroll, 1, 0.82, 0.2, "crit", false)
    end
    if ns.WindfurySync then ns.WindfurySync() end
  end
  ns.WindfuryProc = Proc

  -- Observed on Forever 1.60.1.70938: two own Windfury episodes (one
  -- parried, one with two hits) each emitted (439440, nil, 0, 0, nil).
  -- Party attribution and broader completeness remain unverified. Never infer a proc from target hits.
  local listener = CreateFrame("Frame")
  ns.WindfuryListener = listener
  ns.IsShaman = false
  local function OnEvent(self, event, spellID, baseSpellID, category, startRecoveryCategory)
    if event == "PLAYER_ENTERING_WORLD" then
      if type(UnitClass) ~= "function" then return end
      local ok, _, class = pcall(UnitClass, "player")
      if not ok or ns.Secret(class) or type(class) ~= "string" then return end
      ns.IsShaman = class == "SHAMAN"
      local registered = false
      if ns.IsShaman then registered = pcall(self.RegisterEvent, self, "SPELL_UPDATE_COOLDOWN")
      else self:UnregisterEvent("SPELL_UPDATE_COOLDOWN") end
      if ns.db then
        ns.db.debug = ns.db.debug or {}
        ns.db.debug.windfuryListening = ns.IsShaman
          and (registered and "SPELL_UPDATE_COOLDOWN: Windfury Weapon 439440" or "Windfury cooldown event unavailable")
          or "Windfury automatic celebration is shaman-only"
      end
      return
    end
    if event ~= "SPELL_UPDATE_COOLDOWN" or not ns.IsShaman then return end
    if ns.Secret(spellID) or ns.Secret(category) or ns.Secret(startRecoveryCategory) then return end
    if spellID ~= 439440 or category ~= 0 or startRecoveryCategory ~= 0 then return end
    Note("signal 439440")
    Proc("cooldown 439440")
  end
  ns.WindfuryEvent = OnEvent
  listener:RegisterEvent("PLAYER_ENTERING_WORLD")
  listener:SetScript("OnEvent", OnEvent)

  local function Build()
    panel = CreateFrame("Frame", "WindfurySettingsPanel", UIParent)
    panel:SetSize(380, 534)
    panel:SetFrameStrata("DIALOG")
    panel:EnableMouse(true)
    panel:SetMovable(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetClampedToScreen(true)
    local bg = Fill(panel, "BACKGROUND", C.panel)
    bg:SetAllPoints()
    Outline(panel, C.accent)
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("Windfury")
    title:SetTextColor(C.accent[1], C.accent[2], C.accent[3])
    local close = FlatButton(panel, "x", 20, 20)
    close:SetPoint("TOPRIGHT", -8, -8)
    close:SetScript("OnClick", function() panel:Hide() end)
    if UISpecialFrames then table.insert(UISpecialFrames, "WindfurySettingsPanel") end
    local y = -44
    syncs = {}
    local function Toggle(key, text, tip, indent, startsOff)
      local function Get() if startsOff then return ns.cfg[key] == true end return ns.cfg[key] ~= false end
      local c = FlatCheck(panel, Get(), function(v)
        ns.db.cfg[key] = v
        if not v and (key == "wf" or key == "wfTextPulse") then RestorePulse("disabled") end
        if not v and (key == "wf" or key == "wfSlots" or key == "wfSlotDamage") then ns.windfurySlots.Stop() end
        ns.WindfurySync()
      end)
      c:SetPoint("TOPLEFT", 14 + (indent or 0), y - 2)
      local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      label:SetPoint("LEFT", c, "RIGHT", 7, 0)
      label:SetWidth(330 - (indent or 0))
      label:SetWordWrap(false)
      label:SetJustifyH("LEFT")
      label:SetText(text)
      if tip then Tip(c, tip) end
      syncs[#syncs + 1] = function() c.Set(Get()) end
      y = y - 26
    end
    Toggle("wf", "Celebrate when my Windfury goes off", "Off: nothing happens on a Windfury proc.")
    Toggle("wfHit", "A deep hit", "Three quick impacts for the Windfury burst.", 14)
    Toggle("wfJackpot", "A jackpot", "Plays your chosen celebration sound immediately alongside the first hit.", 14)
    Toggle("wfSlots", "Slot reels and a burst of coins", "Three reels land on Windfury, then gold coins fly out. Use Move reels to place it, and click again to lock it. Works independently of the large WINDFURY text.", 14)
    Toggle("wfSlotDamage", "Experimental hit numbers", "Shows up to three physical hit amounts around a proc, including the triggering hit: from 0.1 second before to 1 second after its signal. Timing can include another player's damage. Target changes, casts during capture and busy bursts keep the icons. Each reel shows a whole hit; missing amounts stay as icons and no total is calculated. Test uses example numbers 123, 456 and 789. Needs slot reels switched on.", 28)
    Toggle("wfBurst", "WINDFURY! across the screen", "Big gold text that slams in above your character and fades.", 14)
    Toggle("wfFlash", "A flash of gold over the screen", "A brief wash of gold with the text. Needs the text switched on.", 14)
    Toggle("wfTextPulse", "Briefly enlarge floating numbers", "3 times your usual size for 2 seconds. Affects all world text during the pulse, including other damage and healing. Your normal size is restored afterward.", 14)
    Toggle("wfText", "A line in the game's floating combat text", "Adds WINDFURY! to the game's own scrolling combat text, if you have that switched on.", 14)
    -- loudness of each sound: quieter, the level, louder (a click plays it at the new level)
    local function Volume(key, which, text)
      local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      label:SetPoint("TOPLEFT", 14, y - 6)
      label:SetWidth(150)
      label:SetJustifyH("LEFT")
      label:SetText(text)
      local down = FlatButton(panel, "-", 24, 22)
      down:SetPoint("TOPLEFT", 170, y - 1)
      local value = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      value:SetPoint("LEFT", down, "RIGHT", 0, 0)
      value:SetWidth(70)
      value:SetJustifyH("CENTER")
      local up = FlatButton(panel, "+", 24, 22)
      up:SetPoint("LEFT", value, "RIGHT", 0, 0)
      local function Step(by)
        local now = math.max(1, math.min(5, math.floor(tonumber(ns.cfg[key]) or 4)))
        ns.db.cfg[key] = math.max(1, math.min(5, now + by))
        ns.WindfurySync()
        ns.WindfurySound(which)
      end
      down:SetScript("OnClick", function() Step(-1) end)
      up:SetScript("OnClick", function() Step(1) end)
      Tip(down, "Quieter. Plays it at the new loudness.")
      Tip(up, "Louder. Plays it at the new loudness.")
      syncs[#syncs + 1] = function()
        local now = math.max(1, math.min(5, math.floor(tonumber(ns.cfg[key]) or 4)))
        value:SetText(("%d of 5"):format(now))
        down:SetEnabled(now > 1)
        up:SetEnabled(now < 5)
      end
      y = y - 28
    end
    y = y - 6
    do -- which jackpot: click to hear the next kind
      local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      label:SetPoint("TOPLEFT", 14, y - 6)
      label:SetWidth(100)
      label:SetJustifyH("LEFT")
      label:SetText("Jackpot sound")
      local pick = FlatButton(panel, "", 248, 22)
      pick:SetPoint("TOPLEFT", 118, y - 1)
      pick:SetScript("OnClick", function(_, button)
        local k = JackpotKind() + (button == "RightButton" and -1 or 1)
        ns.db.cfg.wfJackpotKind = (k - 1) % #JACKPOTS + 1
        ns.WindfurySync()
        ns.WindfurySound("jackpot")
      end)
      pcall(function() pick:RegisterForClicks("LeftButtonUp", "RightButtonUp") end)
      Tip(pick, "Click for the next kind of jackpot (right-click for the one before). Each click plays it.")
      syncs[#syncs + 1] = function() pick:SetText(("%s  (%d of %d)"):format(JACKPOTS[JackpotKind()], JackpotKind(), #JACKPOTS)) end
      y = y - 30
    end
    do -- hit choice is saved independently of equipped weapons
      local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      label:SetPoint("TOPLEFT", 14, y - 6)
      label:SetWidth(100)
      label:SetJustifyH("LEFT")
      label:SetText("Hit sound")
      local pick = FlatButton(panel, "", 248, 22)
      pick:SetPoint("TOPLEFT", 118, y - 1)
      pick:SetScript("OnClick", function(_, button)
        local k = HitKind() + (button == "RightButton" and -1 or 1)
        ns.db.cfg.wfHitKind = (k - 1) % #HITS + 1
        ns.WindfurySync()
        ns.WindfurySound("hit")
      end)
      pcall(function() pick:RegisterForClicks("LeftButtonUp", "RightButtonUp") end)
      Tip(pick, "Click for the next hit sound (right-click for the previous one). Each click previews it at your hit loudness.")
      syncs[#syncs + 1] = function() pick:SetText(("%s  (%d of %d)"):format(HITS[HitKind()], HitKind(), #HITS)) end
      y = y - 30
    end
    Volume("wfHitVolume", "hit", "Loudness of the hit")
    Volume("wfJackpotVolume", "jackpot", "Loudness of the jackpot")
    panel.status = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.status:SetPoint("BOTTOMLEFT", 14, 16)
    panel.status:SetWidth(185)
    panel.status:SetWordWrap(true)
    panel.status:SetJustifyH("LEFT")
    local test = FlatButton(panel, "Test", 60, 22)
    test:SetPoint("BOTTOMRIGHT", -12, 12)
    test:SetScript("OnClick", function() Proc("test") end)
    Tip(test, "Plays it as a proc would, with the parts you have ticked.")
    local move = FlatButton(panel, "Move reels", 86, 22)
    move:SetPoint("BOTTOMRIGHT", -80, 12)
    move:SetScript("OnClick", function() ns.WindfuryCommand("move") end)
    Tip(move, "Show the reels so you can drag them. Click again to lock their position.")
    syncs[#syncs + 1] = function() move:SetText(ns.windfurySlots.moving and "Lock reels" or "Move reels") end
  end

  function ns.WindfurySync()
    if not panel then return end
    for _, f in ipairs(syncs) do f() end
    panel.status:SetText(("%s | %d celebrations this session"):format(ns.cfg.wf == false and "Off" or "On", count))
  end

  function ns.WindfuryPanel(show)
    if not panel then
      local ok, err = pcall(Build)
      if not ok then
        panel = nil
        ns.Print("the Windfury settings could not be shown: " .. tostring(err))
        return
      end
      panel:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    elseif not show and panel:IsShown() then
      panel:Hide()
      return
    end
    panel:Show()
    ns.WindfurySync()
    return panel
  end

  function ns.WindfuryCommand(arg)
    if arg == "test" then Proc("test")
    elseif arg == "move" then
      local ok, err = pcall(ns.windfurySlots.Move)
      if not ok then ns.windfurySlots.Fail(err); ns.Print("The Windfury reels could not be shown.") end
      ns.WindfurySync()
    elseif arg == "status" then
      ns.Print(("Windfury celebration is %s; %d this session."):format(ns.cfg.wf == false and "off" or "on", count))
      local log = ns.db.debug and ns.db.debug.windfurySlotDamage
      local recent = log and log.recent
      if recent and #recent > 0 then ns.Print("Experimental hit numbers: " .. recent[#recent].reason .. ".") end
    elseif arg == "on" or arg == "off" then
      ns.db.cfg.wf = arg == "on"
      if arg == "off" then RestorePulse("disabled"); ns.windfurySlots.Stop() end
      ns.Print("Windfury celebration is " .. arg .. ".")
      ns.WindfurySync()
    else
      ns.WindfuryPanel()
    end
  end
  return { listener = listener, pulseFrame = pulseFrame }
end)()
