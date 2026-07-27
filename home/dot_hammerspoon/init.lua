function ToggleApplicationActive(appName)
  local app = hs.application.get(appName)
  if not app then
    return hs.application.launchOrFocus(appName .. '.app')
  end

  if app:isFrontmost() then
    app:hide()
  else
    app:activate()
  end
end

hs.hotkey.bind({ "rightalt" }, "´", function()
  ToggleApplicationActive("iTerm")
end)
