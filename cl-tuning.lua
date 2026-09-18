local currentVehicle

function getVehicleTuningConfig(vehicle, overrideConfig)
  local tuningState = {}
  for key, value in pairs(overrideConfig or Config.Tuning) do
    if not overrideConfig then value = false end

    if key == "turbocharging" then
      if IsToggleModOn(vehicle, 18) then
        value = 1
      end
    end

    if key == "gearboxes" then
      local advFlags = getVehicleHandlingValue(vehicle, "CCarHandlingData", "strAdvancedFlags")
      if hasFlag(advFlags, ADV_HANDLING_FLAGS.MANUAL) then
        value = 1
      end
    end

    tuningState[key] = value
  end
  return tuningState
end

local function setVehicleTuningConfigStatebag(vehicle, tuningConfig)
  if not (vehicle and tuningConfig and type(tuningConfig) == "table") then
    print("^1[ERROR] Could not set vehicle tuning data statebag")
  end
  return setVehicleStatebag(vehicle, "tuningConfig", tuningConfig, true)
end

local function handleInstallTune(data, cb)
  local tuneKey = data.tune
  local optionKey = data.option
  local currentOption = data.currentOption
  local installed = data.installed
  local tuningConfig = data.tuningConfig

  local tuneDef = Config.Tuning[tuneKey]
  if tuneDef then tuneDef = tuneDef[optionKey] end
  if not tuneDef then return cb(false) end

  local tabletVehicle = LocalPlayer.state.tabletConnectedVehicle
  local vehicle = tabletVehicle and tabletVehicle.vehicleEntity
  local plate = tabletVehicle and tabletVehicle.plate
  if not DoesEntityExist(vehicle) then return cb(false) end

  if Config.Debug then
    print(("[jg-mechanic][INSTALL-TUNE] Request received | tune=%s option=%s installed=%s plate=%s"):format(tostring(tuneKey), tostring(optionKey), tostring(installed), tostring(plate)))
  end

  local minigameType = "prop"
  local minigameData = { prop = "spanner" }
  if tuneKey == "engineSwaps" then minigameType = "engineSwap" end
  if tuneKey == "tyres" then minigameData = { prop = "wheel" } end


  hideTabletToShowInteractionPrompt(Locale.installingPart or "Installing part...")
  SetNuiFocus(false, false)

  playMinigame(vehicle, minigameType, minigameData, function(success)
    
    showTabletAfterInteractionPrompt()
    SetNuiFocus(true, true)
    if not success then return cb(false) end

    if installed then
      local ok = lib.callback.await("jg-mechanic:server:pay-for-tune", false, tuneKey, optionKey, currentOption, plate)
      if not ok then 
        Framework.Client.Notify("Failed to install part", "error")
        return cb(false) 
      end
      Framework.Client.Notify(Locale.partInstalled:format(tuneDef.name), "success")
    else
      local ok = lib.callback.await("jg-mechanic:server:remove-tune", false, tuneKey, optionKey, plate)
      if not ok then 
        Framework.Client.Notify("Failed to remove part", "error")
        return cb(false) 
      end
      Framework.Client.Notify(Locale.partRemoved:format(tuneDef.name), "success")
    end

    local ok = setVehicleTuningConfigStatebag(vehicle, tuningConfig)
    if ok then return cb(true) end
    return cb(false)
  end)
end

RegisterNUICallback("install-tune", handleInstallTune)