Config = {}

-- Payout destination: 'black_money' (recommended) or 'cash'
Config.Account = 'black_money'

-- Jobs counted as police (lowercase)
Config.PoliceJobs = { 'police', 'sheriff', }

-- Minimum police online to allow selling (0 = disabled)
Config.MinCops = 0

-- Cooldowns (seconds)
Config.GlobalCooldown = 6
Config.PedCooldown    = 90
Config.PlayerCooldown = 60

-- Progress baseline (ms); randomized ±25% server-side
Config.BaseSellDuration = 4500

-- Max distance from target ped during/after progress
Config.MaxDistance = 8.0

-- Base chance (%) of a police ping on ATTEMPT, on top of item risk
Config.BasePoliceAlertChance = 4

-- Extra gameplay chances (percent)
Config.SnitchChancePercent   = 15  -- snitch during offer stage
Config.BadProductFailPercent = 15  -- rejects product after progress

-- Dispatch integration (auto-detects provider unless 'force' is set)
Config.Dispatch = {
    enabled = true,

    -- Providers priority: first running wins unless 'force' is set
    providers = { 'redutzu_mdt', 'cd_dispatch' },
    force = nil, -- 'redutzu_mdt' or 'cd_dispatch' to pin

    callOnAttempt = true,   -- alert when offer is requested (also where snitch can trigger)
    callOnSuccess = false,  -- alert after successful sale

    radius = 30.0,          -- cd_dispatch blip radius
    cooldown = 15,          -- per-player alert cooldown (seconds)

    redutzu = {
        code = '10-47',
        title = 'Drug Sale In Progress',
        sendPeriodicMessages = false
    },

    tracking = {
        enabled  = true,
        duration = 60,  -- seconds tracked
        interval = 5,   -- seconds between updates
        sprite   = 161,
        colour   = 1,
        scale    = 1.2,
        alpha    = 200,
        route    = false,
        name     = 'Drug Sale Suspect'
    }
}

-- Third-eye (ox_target) integration
Config.ThirdEye = {
    enabled  = true,
    provider = 'ox_target',
    label    = 'Offer Drugs',
    icon     = 'fa-solid fa-capsules',
    distance = 2.0
}

-- Handoff ped step/anim behavior (client-side)
Config.PedApproach = {
    enabled       = true,
    minDistance   = 1.4,
    maxStep       = 2.5,
    timeout       = 2000,     -- slightly shorter to be AC-friendly
    facePlayer    = true,
    pedFreeze     = false,
    anim = { dict = 'mp_common', clip = 'givetake1_a', flag = 49 }
}

-- Notify provider (ox_lib)
Config.NotifyProvider = 'ox'

-- Command/keybind (works without third-eye)
Config.Keybind = {
    command = 'selldrug',
    default = 'E',
}

-- Blacklist zones (no-sale areas)
Config.BlacklistZones = {
    -- { coords = vec3(441.88, -981.95, 30.69), radius = 60.0, reason = 'Police Station' }
}

-- Items for sale
Config.Items = {
    cocaine          = { minQty = 1, maxQty = 2, minPrice = 45,  maxPrice = 55,  policeAlertChance = 15, sellAcceptChance = 75 },
    cokebaggy        = { minQty = 1, maxQty = 3, minPrice = 80,  maxPrice = 150, policeAlertChance = 15, sellAcceptChance = 75 },
    coke1g           = { minQty = 1, maxQty = 3, minPrice = 70,  maxPrice = 80,  policeAlertChance = 15, sellAcceptChance = 75 },
    crack1g          = { minQty = 1, maxQty = 2, minPrice = 250, maxPrice = 285, policeAlertChance = 20, sellAcceptChance = 70 },
    ecstasy          = { minQty = 1, maxQty = 5, minPrice = 30,  maxPrice = 40,  policeAlertChance = 10, sellAcceptChance = 80 },
    fentanyl         = { minQty = 1, maxQty = 2, minPrice = 250, maxPrice = 285, policeAlertChance = 25, sellAcceptChance = 65 },
    heroin1          = { minQty = 1, maxQty = 2, minPrice = 250, maxPrice = 285, policeAlertChance = 20, sellAcceptChance = 70 },
    heroin1_syringe  = { minQty = 1, maxQty = 3, minPrice = 50,  maxPrice = 60,  policeAlertChance = 15, sellAcceptChance = 75 },
    leancup          = { minQty = 1, maxQty = 2, minPrice = 250, maxPrice = 285, policeAlertChance = 15, sellAcceptChance = 75 },
    lsd1             = { minQty = 1, maxQty = 5, minPrice = 20,  maxPrice = 30,  policeAlertChance = 10, sellAcceptChance = 80 },
    lsd2             = { minQty = 1, maxQty = 5, minPrice = 20,  maxPrice = 30,  policeAlertChance = 10, sellAcceptChance = 80 },
    lsd3             = { minQty = 1, maxQty = 5, minPrice = 20,  maxPrice = 30,  policeAlertChance = 10, sellAcceptChance = 80 },
    lsd4             = { minQty = 1, maxQty = 5, minPrice = 20,  maxPrice = 30,  policeAlertChance = 10, sellAcceptChance = 80 },
    lsd5             = { minQty = 1, maxQty = 5, minPrice = 20,  maxPrice = 30,  policeAlertChance = 10, sellAcceptChance = 80 },
    meth             = { minQty = 1, maxQty = 3, minPrice = 120, maxPrice = 200, policeAlertChance = 15, sellAcceptChance = 75 },
    meth_syringe     = { minQty = 1, maxQty = 3, minPrice = 80,  maxPrice = 90,  policeAlertChance = 15, sellAcceptChance = 75 },
    n2o_watermelon   = { minQty = 1, maxQty = 2, minPrice = 250, maxPrice = 285, policeAlertChance = 20, sellAcceptChance = 70 },
    packed_coke      = { minQty = 1, maxQty = 2, minPrice = 240, maxPrice = 260, policeAlertChance = 20, sellAcceptChance = 70 },
    packed_meth      = { minQty = 1, maxQty = 2, minPrice = 240, maxPrice = 260, policeAlertChance = 20, sellAcceptChance = 70 },
    packed_weed      = { minQty = 1, maxQty = 2, minPrice = 240, maxPrice = 260, policeAlertChance = 15, sellAcceptChance = 75 },
    percs            = { minQty = 1, maxQty = 2, minPrice = 250, maxPrice = 285, policeAlertChance = 20, sellAcceptChance = 70 },
    rolled_weed      = { minQty = 1, maxQty = 5, minPrice = 15,  maxPrice = 25,  policeAlertChance = 10, sellAcceptChance = 80 },
    shrooms          = { minQty = 1, maxQty = 2, minPrice = 250, maxPrice = 285, policeAlertChance = 15, sellAcceptChance = 75 },
    tesla            = { minQty = 1, maxQty = 2, minPrice = 150, maxPrice = 185, policeAlertChance = 15, sellAcceptChance = 75 },
    weed4g           = { minQty = 1, maxQty = 5, minPrice = 35,  maxPrice = 45,  policeAlertChance = 10, sellAcceptChance = 80 },
    weed_purplehaze  = { minQty = 1, maxQty = 3, minPrice = 45,  maxPrice = 55,  policeAlertChance = 10, sellAcceptChance = 80 },
    weed_skunk       = { minQty = 1, maxQty = 3, minPrice = 45,  maxPrice = 55,  policeAlertChance = 10, sellAcceptChance = 80 },
    weed_whitewidow  = { minQty = 1, maxQty = 3, minPrice = 40,  maxPrice = 70,  policeAlertChance = 10, sellAcceptChance = 80 },
    xanaxpill        = { minQty = 1, maxQty = 5, minPrice = 30,  maxPrice = 40,  policeAlertChance = 10, sellAcceptChance = 80 }
}
