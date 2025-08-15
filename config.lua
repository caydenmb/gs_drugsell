Config = {}

-- Payout destination: 'black_money' (recommended) or 'cash'
Config.Account = 'black_money'

-- Sellable items (names must match ox_inventory)
Config.Items = {
    -- itemName = { label, minPrice, maxPrice, minQty, maxQty, policeAlertChance, sellAcceptChance }
    weed_bag = { label = 'Weed Bag', minPrice = 120, maxPrice = 220, minQty = 1, maxQty = 3, policeAlertChance = 10, sellAcceptChance = 75 },
    coke_bag = { label = 'Cocaine Bag', minPrice = 500, maxPrice = 800, minQty = 1, maxQty = 2, policeAlertChance = 15, sellAcceptChance = 65 },
    meth_bag = { label = 'Meth Bag',   minPrice = 350, maxPrice = 600, minQty = 1, maxQty = 2, policeAlertChance = 18, sellAcceptChance = 60 },
    oxy      = { label = 'Oxy',        minPrice = 150, maxPrice = 250, minQty = 1, maxQty = 4, policeAlertChance = 12, sellAcceptChance = 70 },
}

-- Jobs counted as police (lowercase)
Config.PoliceJobs = { 'police', 'sheriff', 'state', 'trooper' }

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

-- NEW: Extra gameplay chances (percent)
Config.SnitchChancePercent   = 15  -- snitch during offer stage
Config.BadProductFailPercent = 15  -- rejects product after progress

-- Dispatch integration (auto-detects provider unless 'force' is set)
Config.Dispatch = {
    enabled = true,

    -- Providers priority: we pick the first that is running unless 'force' is set
    providers = { 'redutzu_mdt', 'cd_dispatch' },
    force = nil, -- 'redutzu_mdt' or 'cd_dispatch' to pin

    callOnAttempt = true,   -- alert when offer is requested (also where snitch can trigger)
    callOnSuccess = false,  -- alert after successful sale

    radius = 30.0,          -- cd_dispatch blip radius
    cooldown = 15,          -- per-player alert cooldown (seconds)

    -- Redutzu MDT: set to 10-47 per request
    redutzu = {
        code = '10-47',
        title = 'Drug Sale In Progress',
        sendPeriodicMessages = false
    },

    -- Live police tracking (performed by this resource; no external edits)
    tracking = {
        enabled  = true,
        duration = 60,  -- seconds to track suspect
        interval = 5,   -- seconds between position updates
        sprite   = 161,
        colour   = 1,
        scale    = 1.2,
        alpha    = 200,
        route    = false,
        name     = 'Drug Sale Suspect'
    }
}

-- NEW: Handoff ped step/anim behavior (client-side)
Config.PedApproach = {
    enabled       = true,   -- turn the feature on/off
    minDistance   = 1.4,    -- we try to bring the NPC within this distance of player
    maxStep       = 2.5,    -- maximum step NPC will take (meters)
    timeout       = 2500,   -- ms to allow the walk step before giving up
    facePlayer    = true,   -- rotate NPC to face the player
    pedFreeze     = false,  -- freeze ped during anim (usually not needed)
    -- Handoff anim (NPC plays once while player progress runs)
    anim = { dict = 'mp_common', clip = 'givetake1_a', flag = 49 } -- 49 = upperbody only + freeze movement
}

-- Notify provider (ox_lib)
Config.NotifyProvider = 'ox'

-- Command/keybind for selling (works without ox_target)
Config.Keybind = {
    command = 'selldrug',
    default = 'E',
}

-- Blacklist zones (no-sale areas)
Config.BlacklistZones = {
    -- { coords = vec3(441.88, -981.95, 30.69), radius = 60.0, reason = 'Police Station' }
}
