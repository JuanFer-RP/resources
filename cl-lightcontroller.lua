
local hueXenon = 0
local hueUnderglow = 0
local xenonFlashState = false
local underglowFlashState = false
local lightControllerActive = true
local hasLightControllerItem = false
local currentVehicle = nil

local function hslToRgb(h, s, l)
    local r, g, b
    h = h * 360
    local c = (1 - math.abs(2 * l - 1)) * s
    local x = c * (1 - math.abs((h / 60) % 2 - 1))
    local m = l - c / 2

    if h >= 0 and h < 60 then
        r, g, b = c, x, 0
    elseif h >= 60 and h < 120 then
        r, g, b = x, c, 0
    elseif h >= 120 and h < 180 then
        r, g, b = 0, c, x
    elseif h >= 180 and h < 240 then
        r, g, b = 0, x, c
    elseif h >= 240 and h < 300 then
        r, g, b = x, 0, c
    else
        r, g, b = c, 0, x
    end

    r = math.floor((r + m) * 255)
    g = math.floor((g + m) * 255)
    b = math.floor((b + m) * 255)

    return r, g, b
end

RegisterNUICallback("install-light-controller", function(data, cb)
    if not hasLightControllerItem or not currentVehicle then
        return cb(false)
    end

    Framework.Client.ProgressBar(Locale.installingLightingController, 2000, false, false, function()
        setVehicleStatebag(currentVehicle, "lightingControllerInstalled", true, true)
        cb(true)
    end, function()
        cb(false)
    end)
end)

RegisterNUICallback("update-light-controller", function(data, cb)
    if not hasLightControllerItem or not currentVehicle then
        return cb(false)
    end

    local vehicleState = Entity(currentVehicle).state
    if not vehicleState.lightingControllerInstalled then
        return cb(false)
    end

    SetVehicleModKit(currentVehicle, 0)

   
    if data.xenons then
        ToggleVehicleMod(currentVehicle, 22, true)
        SetVehicleLights(currentVehicle, data.xenons.enabled and 2 or 0)
        
        if data.xenons.effect == "solid" then
            SetVehicleXenonLightsCustomColor(
                currentVehicle,
                data.xenons.colour.r,
                data.xenons.colour.g,
                data.xenons.colour.b
            )
        end
        
        setVehicleStatebag(currentVehicle, "xenons", data.xenons, true)
    end

    
    if data.underglow then
        if not data.underglow.enabled then
            for i = 0, 3 do
                SetVehicleNeonLightEnabled(currentVehicle, i, false)
            end
        end
        
        if data.underglow.effect == "solid" then
            SetVehicleNeonLightsColour(
                currentVehicle,
                data.underglow.colour.r,
                data.underglow.colour.g,
                data.underglow.colour.b
            )
        end
        
        setVehicleStatebag(currentVehicle, "underglowDirections", data.underglowDirections, true)
        setVehicleStatebag(currentVehicle, "underglow", data.underglow, true)
    end

    cb(true)
end)

RegisterNUICallback("sync-light-controller", function(data, cb)
    if not hasLightControllerItem or not currentVehicle then
        return cb(false)
    end

    local vehicleState = Entity(currentVehicle).state
    if not vehicleState.lightingControllerInstalled then
        return cb(false)
    end

    CreateThread(function()
        local xenonFlash = false
        local underglowFlash = false
        local xenonHue = 0
        local underglowHue = 0
        local active = true
        
        xenonFlashState = false
        underglowFlashState = false
        hueXenon = 0
        hueUnderglow = 0
        lightControllerActive = false
        
        Wait(500)
        lightControllerActive = true
        cb(true)
    end)
end)

RegisterNUICallback("close-light-controller", function(data, cb)
    hueXenon = 0
    hueUnderglow = 0
    xenonFlashState = false
    underglowFlashState = false
    lightControllerActive = true
    hasLightControllerItem = false
    currentVehicle = nil
    
    LocalPlayer.state:set("isBusy", false, true)
    SetNuiFocus(false, false)
    cb(true)
end)

RegisterNetEvent("jg-mechanic:client:show-lighting-controller", function()
    hasLightControllerItem = lib.callback.await("jg-mechanic:server:has-item", 250, "lighting_controller")
    if not hasLightControllerItem then return end

    if not cache.vehicle then
        Framework.Client.Notify(Locale.notInsideVehicle, "error")
        return
    end

    currentVehicle = cache.vehicle
    local model = GetEntityModel(currentVehicle)
    
    if not IsThisModelACar(model) and not IsThisModelAQuadbike(model) then
        Framework.Client.Notify("ERR_VEHICLE_TYPE_INCOMPATIBLE", "error")
        return
    end

    local vehicleState = Entity(currentVehicle).state
    LocalPlayer.state:set("isBusy", true, true)
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = "show-lighting-controller",
        installed = vehicleState.lightingControllerInstalled or false,
        xenons = vehicleState.xenons,
        underglow = vehicleState.underglow,
        underglowDirections = vehicleState.underglowDirections,
        locale = Locale,
        config = Config
    })
end)


CreateThread(function()
    while true do
        local ped = cache.ped
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local vehicleState = Entity(vehicle).state
            
            if vehicleState.underglow then
                while IsPedInVehicle(ped, vehicle, false) and 
                      vehicleState.lightingControllerInstalled and 
                      vehicleState.underglow and 
                      vehicleState.underglow.enabled and 
                      lightControllerActive do
                    
              
                    for i = 0, 3 do
                        SetVehicleNeonLightEnabled(vehicle, i, vehicleState.underglowDirections[i + 1])
                    end
                    
                 
                    if vehicleState.underglow.effect == "solid" then
                        break
                    elseif vehicleState.underglow.effect == "rgb_cycle" then
                        hueUnderglow = (hueUnderglow + 0.01) % 1
                        local r, g, b = hslToRgb(hueUnderglow, 1, 1)
                        SetVehicleNeonLightsColour(vehicle, r, g, b)
                        Wait(50 / (vehicleState.underglow.speed or 1))
                    elseif vehicleState.underglow.effect == "flashing" then
                        if underglowFlashState then
                            SetVehicleNeonLightsColour(vehicle, 0, 0, 0)
                            underglowFlashState = false
                        else
                            SetVehicleNeonLightsColour(
                                vehicle,
                                vehicleState.underglow.colour.r,
                                vehicleState.underglow.colour.g,
                                vehicleState.underglow.colour.b
                            )
                            underglowFlashState = true
                        end
                        Wait(200 / (vehicleState.underglow.speed or 1))
                    else
                        Wait(500)
                    end
                    
                    vehicleState = Entity(vehicle).state
                end
            end
        end
        Wait(lightControllerActive and 1000 or 1)
    end
end)


CreateThread(function()
    while true do
        local ped = cache.ped
        if IsPedInAnyVehicle(ped, false) then
            local vehicle = GetVehiclePedIsIn(ped, false)
            local vehicleState = Entity(vehicle).state
            
            if vehicleState.xenons then
                while IsPedInVehicle(ped, vehicle, false) and 
                      vehicleState.lightingControllerInstalled and 
                      vehicleState.xenons and 
                      vehicleState.xenons.enabled and 
                      lightControllerActive do
                    
                 
                    if vehicleState.xenons.effect == "solid" then
                        break
                    elseif vehicleState.xenons.effect == "rgb_cycle" then
                        hueXenon = (hueXenon + 0.01) % 1
                        local r, g, b = hslToRgb(hueXenon, 1, 1)
                        SetVehicleXenonLightsCustomColor(vehicle, r, g, b)
                        Wait(50 / (vehicleState.xenons.speed or 1))
                    elseif vehicleState.xenons.effect == "flashing" then
                        if xenonFlashState then
                            SetVehicleXenonLightsCustomColor(vehicle, 0, 0, 0)
                            xenonFlashState = false
                        else
                            SetVehicleXenonLightsCustomColor(
                                vehicle,
                                vehicleState.xenons.colour.r,
                                vehicleState.xenons.colour.g,
                                vehicleState.xenons.colour.b
                            )
                            xenonFlashState = true
                        end
                        Wait(200 / (vehicleState.xenons.speed or 1))
                    else
                        Wait(500)
                    end
                    
                    vehicleState = Entity(vehicle).state
                end
            end
        end
        Wait(lightControllerActive and 1000 or 1)
    end
end)