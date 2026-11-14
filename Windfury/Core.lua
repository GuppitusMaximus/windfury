local ADDON, ns = ...

function ns.Secret(value)
  return issecretvalue ~= nil and issecretvalue(value) or false
end

function ns.Print(message)
  print("|cff33ccffShambaGamba WindFury Proc|r: " .. message)
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:SetScript("OnEvent", function(self, _, name)
  if name ~= ADDON then return end
  if type(WindfuryDB) ~= "table" then WindfuryDB = {} end
  if type(WindfuryDB.cfg) ~= "table" then WindfuryDB.cfg = {} end
  if type(WindfuryDB.debug) ~= "table" then WindfuryDB.debug = {} end
  local defaults = { wfJackpotKind = 5, wfHitKind = 1, wfSlots = false, wfBurst = false }
  for key, value in pairs(defaults) do
    if WindfuryDB.cfg[key] == nil then WindfuryDB.cfg[key] = value end
  end
  ns.db, ns.cfg = WindfuryDB, WindfuryDB.cfg
  self:UnregisterEvent("ADDON_LOADED")
end)

SLASH_WINDFURY1 = "/wf"
SLASH_WINDFURY2 = "/windfury"
SlashCmdList.WINDFURY = function(message)
  if not ns.cfg then return end
  local command = (message or ""):match("^%s*(.-)%s*$"):lower()
  if command == "help" then
    ns.Print("/wf: settings; /wf test: preview; /wf move: move/lock reels; /wf on, off, status.")
  else
    ns.WindfuryCommand(command)
  end
end
