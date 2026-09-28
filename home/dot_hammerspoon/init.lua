-- ~/.hammerspoon/init.lua
-- Managed by chezmoi

-- `hs -c '<lua>'` from a shell, e.g. to inspect state after a reload.
require("hs.ipc")

-- Watchers, taps and menubar items held only by locals are garbage
-- collected once this file returns; keep them reachable from here.
Keep = {}

-- ── Reload on save ───────────────────────────────────────────

Keep.reload = hs.pathwatcher.new(hs.configdir, function(files)
  for _, file in ipairs(files) do
    if file:sub(-4) == ".lua" then
      return hs.reload()
    end
  end
end):start()

-- ── Caffeine ─────────────────────────────────────────────────

-- Click toggles; Option-click picks a duration. The menubar shows the
-- minutes left, survives config reloads, and turns itself off when the
-- Mac runs low on battery.

local caffeine = { bar = hs.menubar.new() }
Keep.caffeine = caffeine

local LOW_BATTERY = 20

local function caffeineRender()
  local on = hs.caffeinate.get("displayIdle")
  local title = on and "☕️" or "😴"
  if on and caffeine.endsAt then
    title = title .. string.format(" %dm", math.ceil((caffeine.endsAt - os.time()) / 60))
  end
  caffeine.bar:setTitle(title)
  caffeine.bar:setTooltip(on and "Awake: display and Mac won't idle-sleep" or "Normal sleep")
end

local function caffeineSet(on, minutes)
  hs.caffeinate.set("displayIdle", on)
  if caffeine.timer then
    caffeine.timer:stop()
    caffeine.timer = nil
  end
  caffeine.endsAt = on and minutes and os.time() + minutes * 60 or nil
  if caffeine.endsAt then
    caffeine.timer = hs.timer.doEvery(30, function()
      if os.time() >= caffeine.endsAt then
        caffeineSet(false)
      else
        caffeineRender()
      end
    end)
  end
  hs.settings.set("caffeine", on and { endsAt = caffeine.endsAt } or nil)
  caffeineRender()
end

local function caffeineMenu()
  local on = hs.caffeinate.get("displayIdle")
  local items = {}
  for _, choice in ipairs({ { "30 minutes", 30 }, { "1 hour", 60 }, { "2 hours", 120 }, { "4 hours", 240 } }) do
    table.insert(items, { title = "Awake for " .. choice[1], fn = function() caffeineSet(true, choice[2]) end })
  end
  table.insert(items, { title = "Awake until turned off", fn = function() caffeineSet(true) end })
  table.insert(items, { title = "-" })
  table.insert(items, { title = "Off", disabled = not on, fn = function() caffeineSet(false) end })
  return items
end

if caffeine.bar then
  -- A menu function replaces the click callback, so a plain click toggles
  -- and returns no menu.
  caffeine.bar:setMenu(function(mods)
    if mods.alt then
      return caffeineMenu()
    end
    caffeineSet(not hs.caffeinate.get("displayIdle"))
    return {}
  end)

  local saved = hs.settings.get("caffeine")
  if saved and saved.endsAt and saved.endsAt > os.time() then
    caffeineSet(true, (saved.endsAt - os.time()) / 60)
  else
    caffeineSet(saved ~= nil and saved.endsAt == nil)
  end

  Keep.battery = hs.battery.watcher.new(function()
    if hs.caffeinate.get("displayIdle")
        and hs.battery.powerSource() == "Battery Power"
        and (hs.battery.percentage() or 100) < LOW_BATTERY then
      caffeineSet(false)
      hs.alert.show("Caffeine off: battery below " .. LOW_BATTERY .. "%")
    end
  end):start()
end

-- ── Ghostty toggle ───────────────────────────────────────────

-- Right Option + ´ shows or hides Ghostty. hs.hotkey cannot tell the two
-- Option keys apart, and left Option is Ghostty's Alt, so an event tap
-- checks the device flag for the right one. Needs Accessibility access.

local GHOSTTY = "com.mitchellh.ghostty"
local RIGHT_ALT = 0x40 -- NX_DEVICERALTKEYMASK
local acute = hs.keycodes.map["´"]

local function toggleGhostty()
  local app = hs.application.get(GHOSTTY)
  if app and app:isFrontmost() then
    app:hide()
  else
    hs.application.launchOrFocusByBundleID(GHOSTTY)
  end
end

Keep.ghostty = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
  if event:getKeyCode() ~= acute then
    return false
  end
  local flags = event:getFlags()
  if not flags.alt or flags.cmd or flags.ctrl or flags.shift then
    return false
  end
  if event:getRawEventData().CGEventData.flags & RIGHT_ALT == 0 then
    return false
  end
  toggleGhostty()
  return true
end):start()

-- ── VS Code: open ~/work ─────────────────────────────────────

hs.hotkey.bind({ "cmd", "shift" }, "´", function()
  hs.osascript.applescript('tell application "System Events" to keystroke "o" using {command down}')
  hs.osascript.applescript('tell application "System Events" to keystroke "~/work"')
  hs.osascript.applescript('tell application "System Events" to key code 36') -- Enter
end)

hs.alert.show("Hammerspoon config reloaded")
