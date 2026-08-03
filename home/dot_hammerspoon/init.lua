local mxKeysVendorID = 0x046d          -- Logitech
local mxKeysProductID = 0x6000002d6340 -- MX Keys S (check yours via `hs.usb`)

local function isMXKeys(device)
  return device.vendorID == mxKeysVendorID and device.productID == mxKeysProductID
end

local function remapCtrlToFN()
  local fnKey = hs.keycodes.map.fn
  local ctrlKey = hs.keycodes.map.ctrl

  -- Create a key event listener for the Control key
  local ctrlListener = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local keyCode = event:getKeyCode()
    if keyCode == ctrlKey then
      -- Simulate the Fn key press
      local fnEvent = hs.eventtap.event.newKeyEvent(fnKey, true)
      fnEvent:post()
      -- Prevent the original Control key event from being processed
      return true
    end
    return false
  end)

  local fnListener = hs.eventtap.new({ hs.eventtap.event.types.keyDown }, function(event)
    local keyCode = event:getKeyCode()
    if keyCode == ctrlKey then
      hs.alert(keyCode)
      -- Simulate the Fn key press
      local fnEvent = hs.eventtap.event.newKeyEvent(fnKey, true)
      fnEvent:post()
      -- Prevent the original Control key event from being processed
      return true
    end
    return false
  end)

  -- Start the listener
  ctrlListener:start()
  fnListener:start()
end

-- remapCtrlToFN()

-- Monitor USB device connection
-- usbWatcher = hs.usb.watcher.new(function(event)
--   if event.eventType == "added" and isMXKeys(event) then
--     remapCtrlToFN()
--   elseif event.eventType == "removed" and isMXKeys(event) then
--     disableCtrlFnRemap()
--   end
-- end)

-- usbWatcher:start()

-- Optional: enable on start if keyboard is already connected
-- for _, device in pairs(hs.usb.attachedDevices()) do
  --if isMXKeys(device) then
--    remapCtrlToFN()
--    break
--  end
-- end

function reloadConfig(files)
  doReload = false
  for _, file in pairs(files) do
    if file:sub(-4) == ".lua" then
      doReload = true
    end
  end
  if doReload then
    hs.reload()
  end
end

myWatcher = hs.pathwatcher.new(os.getenv("HOME") .. "/.hammerspoon/", reloadConfig):start()
hs.alert.show("Hammerspoon config reloaded")

caffeine = hs.menubar.new()
function setCaffeineDisplay(state)
  if state then
    caffeine:setTitle("☕️")
  else
    caffeine:setTitle("😴")
  end
end

function caffeineClicked()
  setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
end

if caffeine then
  caffeine:setClickCallback(caffeineClicked)
  setCaffeineDisplay(hs.caffeinate.get("displayIdle"))
end

local toggleApp = function(appName)
  local app = hs.application.get(appName)
  if app then
    if app:isFrontmost() then
      app:hide()
    else
      app:activate()
      app:unhide()
    end
  else
    hs.application.launchOrFocus(appName)
  end
end

hs.hotkey.bind({ "rightalt" }, "´", function()
  toggleApp("iTerm2")
end)


hs.hotkey.bind({ "cmd", "shift" }, "´", function()
  -- Launch VSCode
  --local vsCode = hs.application.launchOrFocus("Visual Studio Code")

  -- Open a specific folder in VSCode
  hs.osascript.applescript('tell application "System Events" to keystroke "o" using {command down}', 0.5)
  hs.osascript.applescript('tell application "System Events" to keystroke "~/work"')
  hs.osascript.applescript('tell application "System Events" to key code 36') -- Enter key
end)

hs.hotkey.bind({ "cmd", "ctrl" }, "right", function()
  local win = hs.window.focusedWindow()
  --local f = win:frame()

  -- f.x = f.x - 10
  -- win:setFrame(f)
  hs.grid.pushWindowRight(window)
  win:moveOneScreenEast()
end)

hs.hotkey.bind({ "cmd", "ctrl" }, "left", function()
  local win = hs.window.focusedWindow()
  --local f = win:frame()

  hs.grid.pushWindowLeft(window)
  --win:setFrame(hs.layout.left50)
  win:moveOneScreenWest()
end)
