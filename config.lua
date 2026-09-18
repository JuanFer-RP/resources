Config = {}

-- Integraciones del Framework y Recursos de QBCore
Config.Framework = "QBCore"         -- (Debe ser con mayúsculas exactas "QBCore")
Config.Inventory = "qb-inventory"   -- o "ox_inventory" si usas OX
Config.Notifications = "qb"         -- Notificaciones nativas de QBCore
Config.ProgressBar = "qb"           -- Barra de progreso nativa de QBCore
Config.SkillCheck = "qb"            -- Requiere "qb-skillbar" (o cámbialo a "ox" si usas ox_lib)
Config.DrawText = "qb"              -- TextUI por defecto de QBCore
Config.SocietyBanking = "qb-management" -- o "qb-banking" según cuál uses
Config.Menus = "qb"

-- Configuración general
Config.Locale = "en"
Config.NumberAndDateFormat = "en-US"
Config.Currency = "USD"

-- Set to false to use built-in job system
Config.UseFrameworkJobs = true

-- Mechanic Tablet
Config.UseTabletCommand = "tablet" -- set to false to disable command
Config.TabletConnectionMaxDistance = 4.0

-- Shops
Config.Target = "qb-target" 
Config.UseSocietyFund = false
Config.PlayerBalance = "bank"

-- Skill Bars
Config.UseSkillbars = true -- set to false to use progress bars instead of skill bars for installations
Config.ProgressBarDuration = 10000 -- if not using skill bars, this is the progress bar duration in ms (10000 = 10 seconds)
Config.MaximumSkillCheckAttempts = 3 -- How many times the player can attempt a skill check before the skill check fails
Config.SkillCheckDifficulty = { "easy", "easy", "easy", "easy", "easy" } -- for ox only
Config.SkillCheckInputs = { "w", "a", "s", "d" } -- for ox only

-- Servicing
Config.EnableVehicleServicing = true
Config.ServiceRequiredThreshold = 20 -- [%] if any of the servicable parts hit this %, it will flag that the vehicle needs servicing 
Config.ServicingBlacklist = {
  "police", "police2" -- Vehicles that are excluded from servicing damage
}

-- Nitrous
Config.NitrousScreenEffects = true
Config.NitrousRearLightTrails = true -- Only really visible at night
Config.NitrousPowerIncreaseMult = 2.0
Config.NitrousDefaultKeyMapping = "RMENU"
Config.NitrousMaxBottlesPerVehicle = 3 -- The UI can't really handle more than 7, more than that would be unrealistic anyway
Config.NitrousBottleDuration = 10 -- [in seconds] How long a nitrous tank lasts
Config.NitrousBottleCooldown = 5 -- [in seconds] How long until player can start using the next bottle
Config.NitrousPurgeDrainRate = 0.1 -- purging drains bottle only 10% as fast as actually boosting - set to 1 to drain at the same rate 

-- Stancing
Config.StanceMinSuspensionHeight = -0.3
Config.StanceMaxSuspensionHeight = 0.3
Config.StanceMinCamber = 0.0
Config.StanceMaxCamber = 0.5
Config.StanceMinTrackWidth = 0.5
Config.StanceMaxTrackWidth = 1.25
Config.StanceNearbyVehiclesFreqMs = 500

-- Repairs
Config.AllowFixingAtOwnedMechanicsIfNoOneOnDuty = false
Config.DuctTapeMinimumEngineHealth = 100.0
Config.DuctTapeEngineHealthIncrease = 150.0

-- Tuning
Config.TuningGiveInstalledItemBackOnRemoval = false

-- Locations
Config.UseCarLiftPrompt = "[E] Use car lift"
Config.UseCarLiftKey = 38
Config.CustomiseVehiclePrompt = "[E] Customise vehicle"
Config.CustomiseVehicleKey = 38

-- Update vehicle props whenever they are changed [probably should not touch]
-- You can set to false to leave saving any usual props vehicle changes such as
-- GTA performance, cosmetic, colours, wheels, etc to the garage or other scripts
-- that persist the props data to the database. Additional data from this script,
-- such as engine swaps, servicing etc is not affected as it's saved differently
Config.UpdatePropsOnChange = true

-- Stops vehicles from immediately going to redline, for a slightly more realistic feel and
-- reduced liklihood of wheelspin. Can make vehicle launch (slightly) slower.
-- No effect on electric vehicles!
-- May not work immediately for all vehicles; see: https://docs.jgscripts.com/mechanic/manual-transmissions-and-smooth-first-gear#smooth-first-gear
Config.SmoothFirstGear = false

-- If using a manual gearbox, show a notification with key binds when high RPMs 
-- have been detected for too long
Config.ManualHighRPMNotifications = true

-- Misc
Config.UniqueBlips = true
Config.ModsPricesAsPercentageOfVehicleValue = true -- Enable pricing tuning items as % of vehicle value - it tries jg-dealerships, then QBShared, then the vehicles meta file automagically for pricing data
Config.AdminsHaveEmployeePermissions = false -- admins can use tablet & interact with mechanics like an owner
Config.MechanicEmployeesCanSelfServiceMods = true -- CORREGIDO
Config.FullRepairAdminCommand = "vfix"
Config.MechanicAdminCommand = "mechanicadmin"
Config.ChangePlateDuringPreview = "PREVIEW"
Config.RequireManagementForOrderDeletion = false 
Config.UseCustomNamesInTuningMenu = false
Config.DisableNoPaymentOptionForEmployees = false

-- Mechanic Locations
Config.MechanicLocations = {
  bloodline = {
    type = "owned",
    job = "underground",
    jobManagementRanks={4},
    logo = "underground.png", 
    commission = 0,
    locations = {
      {coords = vector3(-933.7552, -763.6011, 13.6673), size = 7.0, showBlip = true },
      {coords = vector3(-924.4932, -764.7715, 13.6673), size = 7.0, showBlip = false }, 
      {coords = vector3(-915.3063, -764.1320, 15.0744), size = 7.0, showBlip = false },
      {coords = vector3(-905.8101, -764.4349, 15.0744), size = 7.0, showBlip = false },
      {coords = vector3(-903.2737, -783.5189, 15.0744), size = 7.0, showBlip = false },
      {coords = vector3(-913.5577, -783.4934, 15.0744), size = 7.0, showBlip = false },
      {coords = vector3(-926.8594, -754.8454, 21.4024), size = 7.0, showBlip = false },
      {coords = vector3(-921.3184, -755.0591, 21.4025), size = 7.0, showBlip = false },
      {coords = vector3(-916.1533, -755.0880, 21.4030), size = 7.0, showBlip = false },
    },
    blip = {
      id = 446,
      color = 47,
      scale = 0.8
    },
    mods = {
      repair           = { enabled = true, price = 500, percentVehVal = 0.01 },
      performance      = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      cosmetics        = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      stance           = { enabled = true, price = 500, percentVehVal = 0.01 },
      respray          = { enabled = true, price = 500, percentVehVal = 0.01 },
      wheels           = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      neonLights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      headlights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      tyreSmoke        = { enabled = true, price = 500, percentVehVal = 0.01 },
      bulletproofTyres = { enabled = true, price = 500, percentVehVal = 0.01 },
      extras           = { enabled = true, price = 500, percentVehVal = 0.01 }
    },
    tuning = {
      engineSwaps   = { enabled = true, requiresItem = true },
      drivetrains   = { enabled = true, requiresItem = true },
      turbocharging = { enabled = true, requiresItem = true },
      tyres         = { enabled = true, requiresItem = true },
      brakes        = { enabled = true, requiresItem = true },
      driftTuning   = { enabled = true, requiresItem = true },
      gearboxes     = { enabled = true, requiresItem = true },
    },
    carLifts = {
      vector4(-913.1591, -784.1082, 15.0744, 358.0020)
    },
    shops = {
      {
        name = "Servicing Supplies",
        coords = vector3(-940.6425, -770.6912, 15.0744),
        size = 2.0,
        usePed = false,
        pedModel = "s_m_m_lathandy_01",
        marker = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 } },
        items = {
          { name = "engine_oil", label = "Engine Oil", price = 50 },
          { name = "tyre_replacement", label = "Tyre Replacement", price = 2500 },
          { name = "clutch_replacement", label = "Clutch Replacement", price = 3000 },
          { name = "air_filter", label = "Air Filter", price = 300 },
          { name = "spark_plug", label = "Spark Plug", price = 100 },
          { name = "suspension_parts", label = "Suspension Parts", price = 2500 },
          { name = "brakepad_replacement", label = "Brakepad Replacement", price = 1500 },
        },
      }
    },
    stashes = {
      {
        name = "Parts Bin",
        coords = vector3(-945.7545, -765.4412, 15.0744),
        size = 2.0,
        slots = 10,
        weight = 50000,
      }
    }
  },

  evo = {
    type = "owned",
    job = "evomotors",
    jobManagementRanks = {4},
    logo = "evo.png",
    commission = 0,
    locations = {
      { coords = vector3(83.7710, -1756.8114, 29.2867), size = 7.0, showBlip = true },
      { coords = vector3(89.6453, -1761.3136, 29.2842), size = 7.0, showBlip = false },
      { coords = vector3(95.1887, -1766.1652, 29.2910), size = 7.0, showBlip = false },
      { coords = vector3(100.9986, -1771.2322, 29.2835), size = 7.0, showBlip = false },
      { coords = vector3(106.8938, -1775.9592, 29.2894), size = 7.0, showBlip = false },
      { coords = vector3(112.5617, -1780.8124, 29.2888), size = 7.0, showBlip = false },
      { coords = vector3(90.6062, -1805.4741, 29.2865), size = 7.0, showBlip = false },
      { coords = vector3(66.5324, -1789.1587, 29.2866), size = 7.0, showBlip = false },
      { coords = vector3(60.5859, -1784.3386, 29.2882), size = 7.0, showBlip = false },
    },
    blip = {
      id = 446,
      color = 25,
      scale = 0.7
    },
    mods = {
      repair           = { enabled = true, price = 500, percentVehVal = 0.01 },
      performance      = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      cosmetics        = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      stance           = { enabled = true, price = 500, percentVehVal = 0.01 },
      respray          = { enabled = true, price = 500, percentVehVal = 0.01 },
      wheels           = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      neonLights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      headlights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      tyreSmoke        = { enabled = true, price = 500, percentVehVal = 0.01 },
      bulletproofTyres = { enabled = true, price = 500, percentVehVal = 0.01 },
      extras           = { enabled = true, price = 500, percentVehVal = 0.01 }
    },
    tuning = {
      engineSwaps   = { enabled = true, requiresItem = true },
      drivetrains   = { enabled = true, requiresItem = true },
      turbocharging = { enabled = true, requiresItem = true },
      tyres         = { enabled = true, requiresItem = true },
      brakes        = { enabled = true, requiresItem = true },
      driftTuning   = { enabled = true, requiresItem = true },
      gearboxes     = { enabled = true, requiresItem = true },
    },
    carLifts = {
      vector4(66.5507, -1766.7595, 29.1189, 52.1595)
    },
    shops = {
      {
        name = "Servicing Supplies",
        coords = vector3(86.4297, -1754.3663, 29.1198),
        size = 2.0,
        usePed = false,
        pedModel = "s_m_m_lathandy_01",
        marker = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 } },
        items = {
          { name = "engine_oil", label = "Engine Oil", price = 50 },
          { name = "tyre_replacement", label = "Tyre Replacement", price = 2500 },
          { name = "clutch_replacement", label = "Clutch Replacement", price = 3000 },
          { name = "air_filter", label = "Air Filter", price = 300 },
          { name = "spark_plug", label = "Spark Plug", price = 100 },
          { name = "suspension_parts", label = "Suspension Parts", price = 2500 },
          { name = "brakepad_replacement", label = "Brakepad Replacement", price = 1500 },
        },
      }
    },
    stashes = {
      {
        name = "Parts Bin",
        coords = vector3(81.3684, -1752.3099, 29.1189),
        size = 2.0,
        slots = 10,
        weight = 50000,
      }
    }
  },

  srt = {
    type = "owned",
    job = "srt",
    jobManagementRanks = {4},
    logo = "srt.png",
    commission = 0,
    locations = {
      { coords = vector3(-1118.4952, -2054.4150, 13.4070), size = 7.0, showBlip = true },
      { coords = vector3(-1125.3860, -2060.6482, 13.2632), size = 7.0, showBlip = false },
      { coords = vector3(-1132.1057, -2067.2603, 13.2619), size = 7.0, showBlip = false },
      { coords = vector3(-1138.1377, -2074.2896, 13.4122), size = 7.0, showBlip = false },
      { coords = vector3(-1145.0187, -2080.4822, 13.2619), size = 7.0, showBlip = false },
      { coords = vector3(-1158.1689, -2104.4714, 13.3639), size = 7.0, showBlip = false },
      { coords = vector3(-1155.5981, -2107.4875, 13.3639), size = 7.0, showBlip = false },
      { coords = vector3(-1152.0315, -2110.7183, 13.3639), size = 7.0, showBlip = false },
      { coords = vector3(-1149.3461, -2113.6128, 13.3682), size = 7.0, showBlip = false },
      { coords = vector3(-1146.3909, -2116.4099, 13.3640), size = 7.0, showBlip = false },
      { coords = vector3(-1143.1735, -2119.8875, 13.3640), size = 7.0, showBlip = false },
      { coords = vector3(-1140.4115, -2122.5613, 13.3645), size = 7.0, showBlip = false },
      { coords = vector3(-1137.5367, -2125.5940, 13.3639), size = 7.0, showBlip = false },
      { coords = vector3(-1134.2633, -2128.3040, 13.3643), size = 7.0, showBlip = false },
      { coords = vector3(-1131.4689, -2131.3174, 13.3672), size = 7.0, showBlip = false },
      { coords = vector3(-1128.5825, -2134.1919, 13.3668), size = 7.0, showBlip = false },
      { coords = vector3(-1114.2773, -2142.1875, 13.2894), size = 7.0, showBlip = false },
      { coords = vector3(-1109.4937, -2138.9734, 13.2894), size = 7.0, showBlip = false },
      { coords = vector3(-1106.0087, -2135.1946, 13.2619), size = 7.0, showBlip = false },
      { coords = vector3(-1102.1902, -2131.6045, 13.2619), size = 7.0, showBlip = false },
      { coords = vector3(-1098.4905, -2127.6028, 13.2894), size = 7.0, showBlip = false },
      { coords = vector3(-1098.4596, -2127.6123, 13.2894), size = 7.0, showBlip = false },
      { coords = vector3(-1095.1912, -2123.7825, 13.2619), size = 7.0, showBlip = false },
      { coords = vector3(-1095.1744, -2123.7913, 13.2619), size = 7.0, showBlip = false },
      { coords = vector3(-1091.3127, -2120.3242, 13.2619), size = 7.0, showBlip = false },
      { coords = vector3(-1087.5557, -2116.3281, 13.2894), size = 7.0, showBlip = false },
      { coords = vector3(-1087.5529, -2116.3413, 13.2894), size = 7.0, showBlip = false },
      { coords = vector3(-1087.6154, -2116.2808, 13.2894), size = 7.0, showBlip = false },
      { coords = vector3(-1083.7938, -2112.8406, 13.2620), size = 7.0, showBlip = false },
      { coords = vector3(-1084.4270, -2112.1797, 13.2619), size = 7.0, showBlip = false },
      { coords = vector3(-1079.9878, -2109.3721, 13.2619), size = 7.0, showBlip = false },
    },
    blip = {
      id = 446,
      color = 25,
      scale = 0.7
    },
    mods = {
      repair           = { enabled = true, price = 500, percentVehVal = 0.01 },
      performance      = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      cosmetics        = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      stance           = { enabled = true, price = 500, percentVehVal = 0.01 },
      respray          = { enabled = true, price = 500, percentVehVal = 0.01 },
      wheels           = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      neonLights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      headlights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      tyreSmoke        = { enabled = true, price = 500, percentVehVal = 0.01 },
      bulletproofTyres = { enabled = true, price = 500, percentVehVal = 0.01 },
      extras           = { enabled = true, price = 500, percentVehVal = 0.01 }
    },
    tuning = {
      engineSwaps   = { enabled = true, requiresItem = true },
      drivetrains   = { enabled = true, requiresItem = true },
      turbocharging = { enabled = true, requiresItem = true },
      tyres         = { enabled = true, requiresItem = true },
      brakes        = { enabled = true, requiresItem = true },
      driftTuning   = { enabled = true, requiresItem = true },
      gearboxes     = { enabled = true, requiresItem = true },
    },
    carLifts = {
      vector4(66.5507, -1766.7595, 29.1189, 52.1595)
    },
    shops = {
      {
        name = "Servicing Supplies",
        coords = vector3(86.4297, -1754.3663, 29.1198),
        size = 2.0,
        usePed = false,
        pedModel = "s_m_m_lathandy_01",
        marker = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 } },
        items = {
          { name = "engine_oil", label = "Engine Oil", price = 50 },
          { name = "tyre_replacement", label = "Tyre Replacement", price = 2500 },
          { name = "clutch_replacement", label = "Clutch Replacement", price = 3000 },
          { name = "air_filter", label = "Air Filter", price = 300 },
          { name = "spark_plug", label = "Spark Plug", price = 100 },
          { name = "suspension_parts", label = "Suspension Parts", price = 2500 },
          { name = "brakepad_replacement", label = "Brakepad Replacement", price = 1500 },
        },
      }
    },
    stashes = {
      {
        name = "Parts Bin",
        coords = vector3(81.3684, -1752.3099, 29.1189),
        size = 2.0,
        slots = 10,
        weight = 50000,
      }
    }
  },

  overspeed = {
    type = "owned",
    job = "overspeed",
    jobManagementRanks = {4},
    logo = "overspeed.png",
    commission = 0,
    locations = {
      { coords = vector3(945.9171, -979.8175, 43.1158), size = 7.0, showBlip = true },
      { coords = vector3(935.4048, -980.2704, 43.1158), size = 7.0, showBlip = false },
      { coords = vector3(925.1685, -980.1713, 43.1158), size = 7.0, showBlip = false },
      { coords = vector3(914.6049, -980.1729, 43.1158), size = 7.0, showBlip = false },
      { coords = vector3(904.0433, -971.9833, 43.1185), size = 7.0, showBlip = false },
      { coords = vector3(903.7382, -961.5803, 43.1185), size = 7.0, showBlip = false },
      { coords = vector3(903.8400, -951.3180, 43.1184), size = 7.0, showBlip = false },
      { coords = vector3(904.2324, -940.6866, 43.1185), size = 7.0, showBlip = false },
      { coords = vector3(904.4747, -930.4725, 43.1184), size = 7.0, showBlip = false },
      { coords = vector3(904.2184, -919.9454, 43.1183), size = 7.0, showBlip = false },
      { coords = vector3(928.0751, -926.9810, 42.9506), size = 7.0, showBlip = false },
      { coords = vector3(923.4235, -927.1557, 42.9540), size = 7.0, showBlip = false },
      { coords = vector3(946.0128, -980.0449, 50.5056), size = 7.0, showBlip = false },
      { coords = vector3(935.5580, -980.3072, 50.5056), size = 7.0, showBlip = false },
      { coords = vector3(925.2438, -980.0444, 50.5057), size = 7.0, showBlip = false },
      { coords = vector3(914.7380, -980.4086, 50.5056), size = 7.0, showBlip = false },
      { coords = vector3(903.8362, -971.9912, 50.5057), size = 7.0, showBlip = false },
      { coords = vector3(903.8989, -961.6224, 50.5057), size = 7.0, showBlip = false },
      { coords = vector3(904.0169, -951.2189, 50.5057), size = 7.0, showBlip = false },
      { coords = vector3(903.7148, -940.6639, 50.5056), size = 7.0, showBlip = false },
      { coords = vector3(958.6329, -958.0079, 50.3413), size = 7.0, showBlip = false },
      { coords = vector3(959.5114, -964.9072, 50.3413), size = 7.0, showBlip = false },
      { coords = vector3(959.2191, -971.4750, 50.3414), size = 7.0, showBlip = false },
      { coords = vector3(955.4951, -972.2084, 59.1083), size = 7.0, showBlip = false },
      { coords = vector3(937.5998, -972.2431, 59.1083), size = 7.0, showBlip = false },
    },
    blip = {
      id = 446,
      color = 25,
      scale = 0.7
    },
    mods = {
      repair           = { enabled = true, price = 500, percentVehVal = 0.01 },
      performance      = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      cosmetics        = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      stance           = { enabled = true, price = 500, percentVehVal = 0.01 },
      respray          = { enabled = true, price = 500, percentVehVal = 0.01 },
      wheels           = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      neonLights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      headlights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      tyreSmoke        = { enabled = true, price = 500, percentVehVal = 0.01 },
      bulletproofTyres = { enabled = true, price = 500, percentVehVal = 0.01 },
      extras           = { enabled = true, price = 500, percentVehVal = 0.01 }
    },
    tuning = {
      engineSwaps   = { enabled = true, requiresItem = true },
      drivetrains   = { enabled = true, requiresItem = true },
      turbocharging = { enabled = true, requiresItem = true },
      tyres         = { enabled = true, requiresItem = true },
      brakes        = { enabled = true, requiresItem = true },
      driftTuning   = { enabled = true, requiresItem = true },
      gearboxes     = { enabled = true, requiresItem = true },
    },
    carLifts = {
      vector4(948.4467, -964.0865, 42.9538, 88.5545)
    },
    shops = {
      {
        name = "Servicing Supplies",
        coords = vector3(905.6043, -985.6821, 42.9541),
        size = 2.0,
        usePed = false,
        pedModel = "s_m_m_lathandy_01",
        marker = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 } },
        items = {
          { name = "engine_oil", label = "Engine Oil", price = 50 },
          { name = "tyre_replacement", label = "Tyre Replacement", price = 2500 },
          { name = "clutch_replacement", label = "Clutch Replacement", price = 3000 },
          { name = "air_filter", label = "Air Filter", price = 300 },
          { name = "spark_plug", label = "Spark Plug", price = 100 },
          { name = "suspension_parts", label = "Suspension Parts", price = 2500 },
          { name = "brakepad_replacement", label = "Brakepad Replacement", price = 1500 },
        },
      }
    },
    stashes = {
      {
        name = "Parts Bin",
        coords = vector3(907.7701, -984.1897, 42.9541),
        size = 2.0,
        slots = 10,
        weight = 50000,
      }
    }
  },

  westcoast = {
    type = "owned",
    job = "west",
    jobManagementRanks = {4},
    logo = "west.png",
    commission = 0,
    locations = {
      { coords = vector3(-319.7383, -1309.2667, 31.6883), size = 7.0, showBlip = true },
      { coords = vector3(-319.3004, -1316.9574, 31.6883), size = 7.0, showBlip = false },
      { coords = vector3(-319.5808, -1323.6188, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-318.8095, -1329.4659, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-319.2792, -1335.0034, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-318.1316, -1340.8776, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-319.3831, -1347.6544, 31.6883), size = 7.0, showBlip = false },
      { coords = vector3(-319.2720, -1355.4121, 31.6883), size = 7.0, showBlip = false },
      { coords = vector3(-334.4151, -1323.6063, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-334.1724, -1329.5602, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-334.5097, -1336.0343, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-334.7342, -1341.4646, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-334.2910, -1347.3043, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-333.8495, -1353.6007, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-354.9002, -1369.5281, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-349.3331, -1369.9226, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-355.7966, -1352.3710, 31.8811), size = 7.0, showBlip = false },
      { coords = vector3(-355.8640, -1344.6694, 31.8811), size = 7.0, showBlip = false },
      { coords = vector3(-355.6372, -1336.8424, 31.8811), size = 7.0, showBlip = false },
      { coords = vector3(-354.9953, -1329.4905, 31.7058), size = 7.0, showBlip = false },
      { coords = vector3(-355.0232, -1321.9270, 31.7058), size = 7.0, showBlip = false },
      { coords = vector3(-355.2999, -1314.0460, 31.7058), size = 7.0, showBlip = false },
      { coords = vector3(-340.6400, -1322.8424, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-340.3668, -1329.0916, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-340.2469, -1335.3730, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-339.9457, -1341.5863, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-340.1440, -1347.4468, 31.6802), size = 7.0, showBlip = false },
      { coords = vector3(-339.7362, -1353.8630, 31.6802), size = 7.0, showBlip = false },
    },
    blip = {
      id = 446,
      color = 25,
      scale = 0.7
    },
    mods = {
      repair           = { enabled = true, price = 500, percentVehVal = 0.01 },
      performance      = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      cosmetics        = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      stance           = { enabled = true, price = 500, percentVehVal = 0.01 },
      respray          = { enabled = true, price = 500, percentVehVal = 0.01 },
      wheels           = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      neonLights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      headlights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      tyreSmoke        = { enabled = true, price = 500, percentVehVal = 0.01 },
      bulletproofTyres = { enabled = true, price = 500, percentVehVal = 0.01 },
      extras           = { enabled = true, price = 500, percentVehVal = 0.01 }
    },
    tuning = {
      engineSwaps   = { enabled = true, requiresItem = true },
      drivetrains   = { enabled = true, requiresItem = true },
      turbocharging = { enabled = true, requiresItem = true },
      tyres         = { enabled = true, requiresItem = true },
      brakes        = { enabled = true, requiresItem = true },
      driftTuning   = { enabled = true, requiresItem = true },
      gearboxes     = { enabled = true, requiresItem = true },
    },
    carLifts = {
      vector4(-338.6507, -1317.7656, 31.6802, 48.3611),
    },
    shops = {
      {
        name = "Servicing Supplies",
        coords = vector3(-354.4041, -1309.9181, 31.6802),
        size = 2.0,
        usePed = false,
        pedModel = "s_m_m_lathandy_01",
        marker = { id = 21, size = { x = 0.3, y = 0.3, z = 0.3 }, color = { r = 255, g = 255, b = 255, a = 120 } },
        items = {
          { name = "engine_oil", label = "Engine Oil", price = 50 },
          { name = "tyre_replacement", label = "Tyre Replacement", price = 2500 },
          { name = "clutch_replacement", label = "Clutch Replacement", price = 3000 },
          { name = "air_filter", label = "Air Filter", price = 300 },
          { name = "spark_plug", label = "Spark Plug", price = 100 },
          { name = "suspension_parts", label = "Suspension Parts", price = 2500 },
          { name = "brakepad_replacement", label = "Brakepad Replacement", price = 1500 },
        },
      }
    },
    stashes = {
      {
        name = "Parts Bin",
        coords = vector3(-356.3440, -1304.2516, 31.6802),
        size = 2.0,
        slots = 10,
        weight = 50000,
      }
    }
  },

  lsc = {
    type = "owned",
    job = "lsc",
    jobManagementRanks = {4},
    logo = "ls_customs.png",
    commission = 0,
    locations = {
      { coords = vector3(-317.2297, -92.9123, 38.7394), size = 7.0, showBlip = true },
      { coords = vector3(-325.5426, -89.6109, 38.6836), size = 7.0, showBlip = false },
      { coords = vector3(-333.6572, -86.5433, 38.6836), size = 7.0, showBlip = false },
      { coords = vector3(-341.8437, -83.7838, 38.7089), size = 7.0, showBlip = false },
      { coords = vector3(-350.3809, -80.4105, 38.6836), size = 7.0, showBlip = false },
      { coords = vector3(-358.3906, -77.5960, 38.6836), size = 7.0, showBlip = false },
      { coords = vector3(-366.5508, -74.4170, 38.6836), size = 7.0, showBlip = false },
      { coords = vector3(-368.0662, -98.1156, 38.7119), size = 7.0, showBlip = false },
      { coords = vector3(-361.8477, -100.6879, 38.7119), size = 7.0, showBlip = false },
      { coords = vector3(-355.8269, -103.1508, 38.7119), size = 7.0, showBlip = false },
      { coords = vector3(-349.5493, -105.6250, 38.7119), size = 7.0, showBlip = false },
      { coords = vector3(-318.9962, -122.3707, 38.6964), size = 7.0, showBlip = false },
      { coords = vector3(-321.1140, -128.2420, 38.6964), size = 7.0, showBlip = false },
      { coords = vector3(-323.1327, -134.3164, 38.6867), size = 7.0, showBlip = false },
    },
    blip = {
      id = 446,
      color = 25,
      scale = 0.7
    },
    mods = {
      repair           = { enabled = true, price = 500, percentVehVal = 0.01 },
      performance      = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      cosmetics        = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      stance           = { enabled = true, price = 500, percentVehVal = 0.01 },
      respray          = { enabled = true, price = 500, percentVehVal = 0.01 },
      wheels           = { enabled = true, price = 500, percentVehVal = 0.01, priceMult = 0.1 },
      neonLights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      headlights       = { enabled = true, price = 500, percentVehVal = 0.01 },
      tyreSmoke        = { enabled = true, price = 500, percentVehVal = 0.01 },
      bulletproofTyres = { enabled = true, price = 500, percentVehVal = 0.01 },
      extras           = { enabled = true, price = 500, percentVehVal = 0.01 }
    },
    tuning = {
      engineSwaps   = { enabled = true, requiresItem = true },
      drivetrains   = { enabled = true, requiresItem = true },
      turbocharging = { enabled = true, requiresItem = true },
      tyres         = { enabled = true, requiresItem = true },
      brakes        = { enabled = true, requiresItem = true },
      driftTuning   = { enabled = true, requiresItem = true },
      gearboxes     = { enabled = true, requiresItem = true },
    },
    carLifts = {
      vector4(-342.8394, -108.3258, 38.6836, 336.9738)
    },
    shops = {
      {
        name = "Servicing Supplies",
        coords = vector3(-349.4290, -126.1338, 39.0122),
        size = 2.0,
        usePed = false,
        pedModel = "s_m_m_lathandy_01",
        marker = {
          id = 21,
          size = { x = 0.3, y = 0.3, z = 0.3 },
          color = { r = 255, g = 255, b = 255, a = 120 }
        },
        items = {
          { name = "engine_oil", label = "Engine Oil", price = 50 },
          { name = "tyre_replacement", label = "Tyre Replacement", price = 2500 },
          { name = "clutch_replacement", label = "Clutch Replacement", price = 3000 },
          { name = "air_filter", label = "Air Filter", price = 300 },
          { name = "spark_plug", label = "Spark Plug", price = 100 },
          { name = "suspension_parts", label = "Suspension Parts", price = 2500 },
          { name = "brakepad_replacement", label = "Brakepad Replacement", price = 1500 },
        },
      }
    },
    stashes = {
      {
        name = "Parts Bin",
        coords = vector3(-350.2771, -128.4275, 39.0123),
        size = 2.0,
        slots = 10,
        weight = 50000,
      }
    }
  }
}

-- Add electric vehicles to disable combustion engine features
-----------------------------------------------------------------------
-- PLEASE NOTE: In b3258 (Bottom Dollar Bounties) and newer, electric
-- vehicles are detected automatically, so this list is not used! 
Config.ElectricVehicles = {
  "Airtug",     "buffalo5",   "caddy",
  "Caddy2",     "caddy3",     "coureur",
  "cyclone",    "cyclone2",   "imorgon",
  "inductor",   "iwagen",     "khamelion",
  "metrotrain", "minitank",   "neon",
  "omnisegt",   "powersurge", "raiden",
  "rcbandito",  "surge",      "tezeract",
  "virtue",     "vivanite",   "voltic",
  "voltic2",
}

-- Nerd options
Config.DisableSound = false
Config.AutoRunSQL = true
Config.Debug = false