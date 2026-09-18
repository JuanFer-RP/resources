Config.Tuning = {
  
  engineSwaps = {
    [1] = {
      name = "I4 Turbo 2.5L",
      icon = "engine.svg",
      info = "A twin-turbo charged 2.5L engine. Can reach speeds of up to 100mph!",
      itemName = "i4_engine",
      price = 30000,
      audioNameHash = "sultan2",
      handlingOverwritesValues = false,
      handlingApplyOrder = 1,
      handling = {
        fInitialDriveForce = 0,
        fDriveInertia = 0,
        fInitialDriveMaxFlatVel = 0,
        fClutchChangeRateScaleUpShift = 0,
        fClutchChangeRateScaleDownShift = 0
      },
      restricted = "combustion",
    },
    [2] = {
      name = "V6 3.3L",
      icon = "engine.svg",
      audioNameHash = "comet4",
      info = "Tuned V6 engine - capable of speeds up to 120mph.",
      itemName = "v6_engine",
      price = 45000,
      handlingOverwritesValues = false,
      handlingApplyOrder = 1,
      handling = {
        fInitialDriveForce = 0,
        fDriveInertia = 0,
        fInitialDriveMaxFlatVel = 0,
        fClutchChangeRateScaleUpShift = 0,
        fClutchChangeRateScaleDownShift = 0
      },
      restricted = "combustion",
    },
    [3] = {
      name = "V8 6.5L",
      icon = "engine.svg",
      info = "Naturally aspirated 6.5L V8. Has awesome backfires and a crackling sound as you let off the gas. Sure to impress.",
      itemName = "v8_engine",
      price = 65000,
      audioNameHash = "jugular",
      handlingOverwritesValues = false,
      handlingApplyOrder = 1,
      handling = {
        fInitialDriveForce = 0,
        fDriveInertia = 0,
        fInitialDriveMaxFlatVel = 0,
        fClutchChangeRateScaleUpShift = 0,
        fClutchChangeRateScaleDownShift = 0
      },
      restricted = "combustion",
    },
    [4] = {
      name = "V12 6.0L",
      icon = "engine.svg",
      info = "A huge 6L V12 monster. Can reach speeds of over 130mph, be realistic and only put this in vehicles that could realistically fit a V12.",
      itemName = "v12_engine",
      price = 80000,
      audioNameHash = "schafter3",
      handlingOverwritesValues = false,
      handlingApplyOrder = 1,
      handling = {
        fInitialDriveForce = 0,
        fDriveInertia = 0,
        fInitialDriveMaxFlatVel = 0,
        fClutchChangeRateScaleUpShift = 0,
        fClutchChangeRateScaleDownShift = 0
      },
      restricted = "combustion",
      blacklist = {"panto"} -- Example of the blacklist feature - feel free to remove this (it couldn't fit a v12 though man, come on)
    },
  },

  --
  -- TYRES
  -- You can customise, or add new tyre options here.
  --
  tyres = {
    [1] = {
      name = "Semi-slicks",
      icon = "wheels/offroad.svg",
      info = false,
      itemName = "semi_slick_tyres",
      price = 25000,
      handlingOverwritesValues = true,
      handlingApplyOrder = 2,
      handling = {
        fTractionCurveMin = 2.4,
        fTractionCurveMax = 2.6
      },
    },
    [2] = {
      name = "Offroad",
      icon = "wheels/offroad.svg",
      info = false,
      itemName = "offroad_tyres",
      price = 25000,
      handlingOverwritesValues = true,
      handlingApplyOrder = 2,
      handling = {
        fTractionLossMult = 0.0
      },
    }
  },

  --
  -- BRAKES
  -- You can customise, or add new tyre options here.
  --
  brakes = {
    [1] = {
      name = "Ceramic",
      icon = "brakes.svg",
      info = "Powerful brakes with an immense stopping power",
      itemName = "ceramic_brakes",
      price = 25000,
      handlingOverwritesValues = true,
      handlingApplyOrder = 3,
      handling = {
        fBrakeForce = 1.5
      },
    }
  },

  --
  -- DRIVETRAINS
  -- You can customise, or add new drivetain options here.
  --
  drivetrains = {
    [1] = {
      name = "AWD",
      icon = "drivetrain.svg",
      info = false,
      itemName = "awd_drivetrain",
      price = 50000,
      handlingOverwritesValues = true,
      handlingApplyOrder = 4,
      handling = {
        fDriveBiasFront = 0.5
      },
    },
    [2] = {
      name = "RWD",
      icon = "drivetrain.svg",
      info = false,
      itemName = "rwd_drivetrain",
      price = 50000,
      handlingOverwritesValues = true,
      handlingApplyOrder = 4,
      handling = {
        fDriveBiasFront = 0.0
      },
    },
    [3] = {
      name = "FWD",
      icon = "drivetrain.svg",
      info = false,
      itemName = "fwd_drivetrain",
      price = 50000,
      handlingOverwritesValues = true,
      handlingApplyOrder = 4,
      handling = {
        fDriveBiasFront = 1.0
      },
    }
  },

  --
  -- TURBOCHARGING
  -- Note: This category is unique as it just enables/disables mod 18 (the standard GTA turbocharging option)
  -- You can't add additional turbocharging options, you can only adjust/remove the existing one.
  -- You can't add any handling changes. Make new items/other categories for that.
  --
  turbocharging = {
    [1] = {
      name = "Turbocharging",
      icon = "turbo.svg",
      info = false,
      itemName = "turbocharger",
      price = 35000,
      restricted = "combustion",
    }
  },

  --
  -- DRIFT TUNING
  -- You can't add additional drift tuning options, you can only adjust/remove the existing one.
  --
  driftTuning = {
    [1] = {
      name = "Drift Tuning",
      icon = "wheels/tuner.svg",
      info = false,
      itemName = "drift_tuning_kit",
      price = 25000,
      handlingOverwritesValues = true,
      handlingApplyOrder = 5,
      handling = {
        fInitialDragCoeff = 12.22,
        fInitialDriveForce = 3.0,
        fInitialDriveMaxFlatVel = 155.0,
        fSteeringLock = 58.0,
        fTractionCurveMax = 0.6,
        fTractionCurveMin = 1.3,
        fTractionCurveLateral = 21.0,
        fLowSpeedTractionLossMult = 0.5,
        fTractionBiasFront = 0.49
      },
    }
  },

  -- 
  -- GEARBOX (b3095 or newer)
  -- This is a unique category that updates flags, via the boolean 'manualGearbox' option.
  -- This allows you to toggle manual gearing, where the player must change gears themselves.
  -- Learn more: https://docs.jgscripts.com/mechanic/manual-transmissions-and-smooth-first-gear
  -- 
  gearboxes = {
    [1] = {
      name = "Manual Gearbox",
      icon = "transmission.svg",
      info = false,
      itemName = "manual_gearbox",
      price = 10000,
      manualGearbox = true,
      restricted = "combustion",
      minGameBuild = 3095
    }
  }

  --
  -- EXAMPLE CUSTOM NEW CATEGORY
  -- 
  -- ["Transmissions"] = {
  --   [1] = {
  --     name = "8 speed transmission",
  --     icon = "transmission.svg",
  --     info = "Testing making a new category",
  --     itemName = "transmission",
  --     price = 1000,
  --     handlingOverwritesValues = true,
  --     handling = {
  --       nInitialDriveGears = 8
  --     },
  --     restricted = false,
  --   }
  -- }
  --
  -- -- IMPORTANT NOTE --
  -- inside of the config.lua, inside of a mechanic location's "tuning" section, you will need to add an
  -- additional line in order for it to show & be enabled in the tablet 
  --
  -- ["Transmissions"] = { enabled = true, requiresItem = false },
}