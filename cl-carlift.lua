local L0_1, L1_1, L2_1, L3_1, L4_1, L5_1, L6_1, L7_1, L8_1, L9_1
L0_1 = -1.025
L1_1 = 0.85
L2_1 = 0.01
L3_1 = nil
L4_1 = false
L5_1 = false
L6_1 = nil
L7_1 = RegisterNUICallback
L8_1 = "carlift-up"
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = L3_1
  if L2_2 then
    L2_2 = L4_1
    if not L2_2 then
      goto lbl_11
    end
  end
  L2_2 = A1_2
  L3_2 = false
  do return L2_2(L3_2) end
  ::lbl_11::
  L2_2 = A0_2.vAttach
  L3_2 = L3_1.platformProp
  L4_2 = GetEntityCoords
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2.z
  L6_2 = L3_1.coords
  L6_2 = L6_2.z
  L5_2 = L5_2 - L6_2
  L3_1.height = L5_2
  L5_2 = true
  L4_1 = L5_2
  L5_2 = lib
  L5_2 = L5_2.getClosestVehicle
  L6_2 = L4_2
  L7_2 = 3.0
  L8_2 = true
  L5_2, L6_2 = L5_2(L6_2, L7_2, L8_2)
  L7_2 = Framework
  L7_2 = L7_2.Client
  L7_2 = L7_2.PlaySound
  L8_2 = "hydraulic"
  L9_2 = vector3
  L10_2 = L3_1.coords
  L10_2 = L10_2.x
  L11_2 = L3_1.coords
  L11_2 = L11_2.y
  L12_2 = L3_1.coords
  L12_2 = L12_2.z
  L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2, L11_2, L12_2)
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L6_1 = L7_2
  L7_2 = CreateThread
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    while true do
      L0_3 = L4_1
      if not L0_3 then
        break
      end
      L0_3 = L3_1
      if not L0_3 then
        break
      end
      L0_3 = L3_1.height
      L1_3 = L1_1
      if not (L0_3 < L1_3) then
        break
      end
      L0_3 = L3_1.height
      L1_3 = L2_1
      L2_3 = L0_3 + L1_3
      L3_1.height = L2_3
      L0_3 = L3_1.coords
      L0_3 = L0_3.z
      L1_3 = L3_1.height
      L0_3 = L0_3 + L1_3
      L1_3 = SetEntityCoords
      L2_3 = L3_2
      L3_3 = L3_1.coords
      L3_3 = L3_3.x
      L4_3 = L3_1.coords
      L4_3 = L4_3.y
      L5_3 = L0_3
      L6_3 = false
      L7_3 = false
      L8_3 = false
      L9_3 = false
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
      L1_3 = L2_2
      if L1_3 then
        L1_3 = L5_2
        if L1_3 then
          L1_3 = L6_2
          if L1_3 then
            L1_3 = DoesEntityExist
            L2_3 = L5_2
            L1_3 = L1_3(L2_3)
            if L1_3 then
              L1_3 = SetEntityCoords
              L2_3 = L5_2
              L3_3 = L6_2.x
              L4_3 = L6_2.y
              L5_3 = L0_3
              L6_3 = false
              L7_3 = false
              L8_3 = false
              L9_3 = false
              L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
            end
          end
        end
      end
      L1_3 = Wait
      L2_3 = 25
      L1_3(L2_3)
    end
    L0_3 = L3_1
    if L0_3 then
      L0_3 = L3_1.height
      L1_3 = L1_1
      if not (L0_3 >= L1_3) then
        goto lbl_76
      end
    end
    L0_3 = L6_1
    if L0_3 then
      L0_3 = Framework
      L0_3 = L0_3.Client
      L0_3 = L0_3.StopSound
      L1_3 = L6_1
      L0_3(L1_3)
    end
    ::lbl_76::
  end
  L7_2(L8_2)
  L7_2 = A1_2
  L8_2 = true
  L7_2(L8_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterNUICallback
L8_1 = "carlift-down"
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2, L5_2, L6_2, L7_2, L8_2, L9_2, L10_2, L11_2, L12_2
  L2_2 = L3_1
  if L2_2 then
    L2_2 = L5_1
    if not L2_2 then
      goto lbl_11
    end
  end
  L2_2 = A1_2
  L3_2 = false
  do return L2_2(L3_2) end
  ::lbl_11::
  L2_2 = A0_2.vAttach
  L3_2 = L3_1.platformProp
  L4_2 = GetEntityCoords
  L5_2 = L3_2
  L4_2 = L4_2(L5_2)
  L5_2 = L4_2.z
  L6_2 = L3_1.coords
  L6_2 = L6_2.z
  L5_2 = L5_2 - L6_2
  L3_1.height = L5_2
  L5_2 = true
  L5_1 = L5_2
  L5_2 = lib
  L5_2 = L5_2.getClosestVehicle
  L6_2 = L4_2
  L7_2 = 3.0
  L8_2 = true
  L5_2, L6_2 = L5_2(L6_2, L7_2, L8_2)
  L7_2 = Framework
  L7_2 = L7_2.Client
  L7_2 = L7_2.PlaySound
  L8_2 = "hydraulic"
  L9_2 = vector3
  L10_2 = L3_1.coords
  L10_2 = L10_2.x
  L11_2 = L3_1.coords
  L11_2 = L11_2.y
  L12_2 = L3_1.coords
  L12_2 = L12_2.z
  L9_2, L10_2, L11_2, L12_2 = L9_2(L10_2, L11_2, L12_2)
  L7_2 = L7_2(L8_2, L9_2, L10_2, L11_2, L12_2)
  L6_1 = L7_2
  L7_2 = CreateThread
  function L8_2()
    local L0_3, L1_3, L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3
    while true do
      L0_3 = L5_1
      if not L0_3 then
        break
      end
      L0_3 = L3_1
      if not L0_3 then
        break
      end
      L0_3 = L3_1.height
      L1_3 = L0_1
      if not (L0_3 > L1_3) then
        break
      end
      L0_3 = L3_1.height
      L1_3 = L2_1
      L2_3 = L0_3 - L1_3
      L3_1.height = L2_3
      L0_3 = L3_1.coords
      L0_3 = L0_3.z
      L1_3 = L3_1.height
      L0_3 = L0_3 + L1_3
      L1_3 = SetEntityCoords
      L2_3 = L3_2
      L3_3 = L3_1.coords
      L3_3 = L3_3.x
      L4_3 = L3_1.coords
      L4_3 = L4_3.y
      L5_3 = L0_3
      L6_3 = false
      L7_3 = false
      L8_3 = false
      L9_3 = false
      L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
      L1_3 = L2_2
      if L1_3 then
        L1_3 = L5_2
        if L1_3 then
          L1_3 = L6_2
          if L1_3 then
            L1_3 = DoesEntityExist
            L2_3 = L5_2
            L1_3 = L1_3(L2_3)
            if L1_3 then
              L1_3 = SetEntityCoords
              L2_3 = L5_2
              L3_3 = L6_2.x
              L4_3 = L6_2.y
              L5_3 = L0_3
              L6_3 = false
              L7_3 = false
              L8_3 = false
              L9_3 = false
              L1_3(L2_3, L3_3, L4_3, L5_3, L6_3, L7_3, L8_3, L9_3)
            end
          end
        end
      end
      L1_3 = Wait
      L2_3 = 25
      L1_3(L2_3)
    end
    L0_3 = L3_1
    if L0_3 then
      L0_3 = L3_1.height
      L1_3 = L0_1
      if not (L0_3 <= L1_3) then
        goto lbl_76
      end
    end
    L0_3 = L6_1
    if L0_3 then
      L0_3 = Framework
      L0_3 = L0_3.Client
      L0_3 = L0_3.StopSound
      L1_3 = L6_1
      L0_3(L1_3)
    end
    ::lbl_76::
  end
  L7_2(L8_2)
  L7_2 = A1_2
  L8_2 = true
  L7_2(L8_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterNUICallback
L8_1 = "carlift-stop"
function L9_1(A0_2, A1_2)
  local L2_2, L3_2
  L2_2 = L3_1
  if L2_2 then
    L2_2 = L6_1
    if L2_2 then
      goto lbl_11
    end
  end
  L2_2 = A1_2
  L3_2 = false
  do return L2_2(L3_2) end
  ::lbl_11::
  L2_2 = Framework
  L2_2 = L2_2.Client
  L2_2 = L2_2.StopSound
  L3_2 = L6_1
  L2_2(L3_2)
  L2_2 = false
  L3_2 = false
  L5_1 = L3_2
  L4_1 = L2_2
  L2_2 = A1_2
  L3_2 = true
  L2_2(L3_2)
end
L7_1(L8_1, L9_1)
L7_1 = RegisterNUICallback
L8_1 = "hide-carlift-controls"
function L9_1(A0_2, A1_2)
  local L2_2, L3_2, L4_2
  L2_2 = SendNUIMessage
  L3_2 = {}
  L3_2.showCarLift = false
  L2_2(L3_2)
  L2_2 = SetNuiFocus
  L3_2 = false
  L4_2 = false
  L2_2(L3_2, L4_2)
  L2_2 = A1_2
  L3_2 = true
  L2_2(L3_2)
end
L7_1(L8_1, L9_1)
function L7_1()
  local L0_2, L1_2, L2_2
  L0_2 = SetNuiFocus
  L1_2 = true
  L2_2 = true
  L0_2(L1_2, L2_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.showCarLift = true
  L2_2 = Locale
  L1_2.locale = L2_2
  L0_2(L1_2)
end
function L8_1(A0_2)
  local L1_2, L2_2, L3_2, L4_2
  if not A0_2 then
    return
  end
  L1_2 = NetworkGetEntityFromNetworkId
  L2_2 = A0_2.platform
  L1_2 = L1_2(L2_2)
  L2_2 = NetworkGetEntityFromNetworkId
  L3_2 = A0_2.stand
  L2_2 = L2_2(L3_2)
  L3_2 = Framework
  L3_2 = L3_2.Client
  L3_2 = L3_2.ShowTextUI
  L4_2 = Config
  L4_2 = L4_2.UseCarLiftPrompt
  L3_2(L4_2)
  L3_2 = {}
  L3_2.platformProp = L1_2
  L3_2.standProp = L2_2
  L4_2 = A0_2.coords
  L3_2.coords = L4_2
  L3_2.height = 0
  L3_1 = L3_2
  L3_2 = CreateThread
  function L4_2()
    local L0_3, L1_3, L2_3
    while true do
      L0_3 = L3_1
      if not L0_3 then
        break
      end
      L0_3 = IsControlJustPressed
      L1_3 = 0
      L2_3 = Config
      L2_3 = L2_3.UseCarLiftKey
      L0_3 = L0_3(L1_3, L2_3)
      if L0_3 then
        L0_3 = L7_1
        L0_3()
      end
      L0_3 = Wait
      L1_3 = 0
      L0_3(L1_3)
    end
  end
  L3_2(L4_2)
end
onEnterCarliftZone = L8_1
function L8_1()
  local L0_2, L1_2, L2_2
  L0_2 = nil
  L3_1 = L0_2
  L0_2 = Framework
  L0_2 = L0_2.Client
  L0_2 = L0_2.HideTextUI
  L0_2()
  L0_2 = SetNuiFocus
  L1_2 = false
  L2_2 = false
  L0_2(L1_2, L2_2)
  L0_2 = SendNUIMessage
  L1_2 = {}
  L1_2.showCarLift = false
  L0_2(L1_2)
end
onExitCarliftZone = L8_1
