local activeCamera = nil
local cameras = {}
local isTransitioning = false
local currentCameraType = nil

function exitCamera()
    for _, camera in pairs(cameras) do
        DestroyCam(camera, true)
    end
    RenderScriptCams(false, false, 0, true, true)
    activeCamera = nil
    currentCameraType = nil
end

function toggleCamTemporarily(state)
    RenderScriptCams(state, false, 0, true, true)
end

function setupVehicleCamera(vehicle)
    local model = GetEntityModel(vehicle)
    local minDim, maxDim = GetModelDimensions(model)
    
    local length = (maxDim.y - minDim.y) * 0.9
    local width = (maxDim.x - minDim.x) * 0.9
    local height = (maxDim.z - minDim.z) * 0.9

    local defaultCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local frontCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local backCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local exhaustCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local sideCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local engineBayCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local roofCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local povCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local doorSpeakerCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    local interiorCam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)

    
    cameras = {
        default = defaultCam,
        frontCamera = frontCam,
        backCamera = backCam,
        exhaust = exhaustCam,
        sideCamera = sideCam,
        engineBay = engineBayCam,
        roof = roofCam,
        pov = povCam,
        doorSpeaker = doorSpeakerCam,
        interior = interiorCam
    }

    SetCamActive(defaultCam, true)
    RenderScriptCams(true, false, 0, true, true)
    activeCamera = defaultCam
    currentCameraType = "default"
end

function moveCameraToVehiclePreset(presetType)
    if not activeCamera then return false end
    if presetType == currentCameraType then return false end
    if not cameras[presetType] then return false end

    local newCamera = cameras[presetType]
    currentCameraType = presetType
    SetCamActiveWithInterp(newCamera, activeCamera, 500, 1, 1)
    SetCamActive(activeCamera, false)
    activeCamera = newCamera
    return true
end

function transitionCamera(presetType)
    CreateThread(function()
        while isTransitioning do
            Wait(100)
        end
        
        isTransitioning = true
        if moveCameraToVehiclePreset(presetType) then
            Wait(500)
        end
        isTransitioning = false
    end)
end