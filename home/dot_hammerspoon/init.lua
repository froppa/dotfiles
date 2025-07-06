function ToggleApplicationActive(appName)
  local app = hs.application.get(appName)
  if not app then
    return hs.application.launchOrFocus(appName .. '.app')
  end

  if app:isHidden() then
    app:activate()
  else
    app:hide()
  end
end

hs.hotkey.bind({ "rightalt" }, "´", function()
  ToggleApplicationActive("iTerm")
end)
