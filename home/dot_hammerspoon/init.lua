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
