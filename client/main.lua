local L = Locales
local Debug = Debug

-- === Notifications ===
local function notify(msg, type, dur)
    lib.notify({ description = msg, type = type or 'inform', duration = dur or 3500 })
end

-- === Selling helpers ===
local function getPedInFront(maxDist)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local fwd = GetEntityForwardVector(ped)
    local dest = coords + (fwd * (maxDist or 2.5))

    local ray = StartShapeTestCapsule(coords, dest, 0.6, 12, ped, 7)
    local _, hit, _, _, entity = GetShapeTestResult(ray)
    if hit == 1 and DoesEntityExist(entity) and IsEntityAPed(entity)
        and not IsPedAPlayer(entity) and not IsPedDeadOrDying(entity, true) then
        return entity
    end
end

local function chooseItem()
    for itemName in pairs(Config.Items) do
        local count = exports.ox_inventory:Search('count', itemName)
        if (count or 0) > 0 then return itemName end
    end
end

-- === Ped Approach / Handoff Anim ===========================================

local function requestControl(entity, attempts, waitMs)
    attempts = attempts or 8
    waitMs   = waitMs or 60
    if not DoesEntityExist(entity) then return false end
    if NetworkHasControlOfEntity(entity) then return true end
    NetworkRequestControlOfEntity(entity)
    local ok = NetworkHasControlOfEntity(entity)
    local tries = 0
    while not ok and tries < attempts do
        Wait(waitMs)
        NetworkRequestControlOfEntity(entity)
        ok = NetworkHasControlOfEntity(entity)
        tries = tries + 1
    end
    return ok
end

local function loadAnimDict(dict)
    if HasAnimDictLoaded(dict) then return true end
    RequestAnimDict(dict)
    local timeout = GetGameTimer() + 1500
    while not HasAnimDictLoaded(dict) and GetGameTimer() < timeout do
        Wait(0)
    end
    return HasAnimDictLoaded(dict)
end

-- Gently step the NPC closer and face the player, then play a short handoff anim.
-- Fully optional; if anything fails, we proceed without it.
local function pedHandoffStep(ped)
    local cfg = Config.PedApproach
    if not (cfg and cfg.enabled) then return end
    if not DoesEntityExist(ped) or IsPedDeadOrDying(ped, true) then return end

    local me = PlayerPedId()
    local mePos = GetEntityCoords(me)
    local pedPos = GetEntityCoords(ped)

    local dist = #(mePos - pedPos)
    if dist <= (cfg.minDistance or 1.4) then
        -- Already close enough; optionally face & anim only
        if cfg.facePlayer then TaskTurnPedToFaceEntity(ped, me, 800) end
    else
        -- Step towards player up to maxStep; compute a target point slightly in front of player
        local fwd = GetEntityForwardVector(me)
        local desired = mePos - (fwd * 0.5) -- half meter in front of player
        -- Clamp step distance
        if #(desired - pedPos) > (cfg.maxStep or 2.5) then
            local dir = (desired - pedPos)
            local len = #(dir)
            if len > 0.01 then
                dir = dir / len
                desired = pedPos + dir * (cfg.maxStep or 2.5)
            end
        end

        if requestControl(ped) then
            ClearPedTasks(ped)
            TaskGoStraightToCoord(ped, desired.x, desired.y, desired.z, 1.0, (cfg.timeout or 2500), 0.0, 0.0)
            local endAt = GetGameTimer() + (cfg.timeout or 2500)
            -- Wait briefly for them to get closer OR timeout
            while GetGameTimer() < endAt do
                if #(GetEntityCoords(ped) - mePos) <= (cfg.minDistance or 1.4) then break end
                Wait(50)
            end
            if cfg.facePlayer then TaskTurnPedToFaceEntity(ped, me, 800) end
        end
    end

    -- Optional freeze (usually unnecessary)
    if cfg.pedFreeze then FreezeEntityPosition(ped, true) end

    -- Play NPC handoff anim (upper-body only) while our own progress bar runs
    local dict, clip, flag = cfg.anim.dict, cfg.anim.clip, cfg.anim.flag or 49
    if dict and clip and loadAnimDict(dict) then
        TaskPlayAnim(ped, dict, clip, 4.0, -4.0, -1, flag, 0.0, false, false, false)
    end

    -- Release freeze shortly after (in case of long progress times)
    if cfg.pedFreeze then
        SetTimeout(1200, function()
            if DoesEntityExist(ped) then FreezeEntityPosition(ped, false) end
        end)
    end
end

-- === Sale flow ==============================================================
RegisterNetEvent('gs_selldrugs:client:alert', function()
    notify(L.alert_sent, 'warning', 4000)
end)

RegisterNetEvent('gs_selldrugs:client:trySell', function(pedNet)
    local item = chooseItem()
    if not item then return notify(L.no_items, 'error') end

    local ped = pedNet and NetworkGetEntityFromNetworkId(pedNet) or getPedInFront(2.2)
    if not ped then return notify(L.no_ped, 'inform') end

    local offer = lib.callback.await('gs_selldrugs:requestOffer', false, {
        ped = NetworkGetNetworkIdFromEntity(ped),
        item = item
    })
    if not offer or not offer.ok then
        local r = offer and offer.reason or 'fail'
        if     r == 'reject'   then notify(L.not_interested, 'inform')
        elseif r == 'cooldown' then notify(L.cooldown, 'inform')
        elseif r == 'cops'     then notify(L.cops_low, 'inform')
        elseif r == 'zone'     then notify(L.zone_block, 'inform')
        elseif r == 'no_items' then notify(L.no_items, 'error')
        else                        notify(L.failed, 'error') end
        return
    end

    -- If server rolled a snitch, give a subtle warning to the player
    if offer.snitched then
        notify(L.snitched, 'warning', 4500)
    end

    -- NEW: ask NPC to step closer & face us; play their handoff anim
    pedHandoffStep(ped)

    local success = lib.progressBar({
        duration = offer.duration or 4000,
        label = L.selling,
        useWhileDead = false,
        canCancel = true,
        disable = { move = true, car = true, combat = true },
        anim = { dict = 'mp_common', clip = 'givetake1_a' }, -- player anim
    })
    if not success then return notify(L.canceled, 'inform') end

    if #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(ped)) > (Config.MaxDistance or 8.0) then
        return notify(L.too_far, 'error')
    end

    local done = lib.callback.await('gs_selldrugs:completeSale', false, {
        token = offer.token,
        ped = NetworkGetNetworkIdFromEntity(ped)
    })
    if not done or not done.ok then
        local r = done and done.reason or 'fail'
        if     r == 'no_items'   then notify(L.no_items, 'error')
        elseif r == 'too_far'    then notify(L.too_far, 'error')
        elseif r == 'invalid' or r == 'expired' then notify(L.invalid, 'error')
        elseif r == 'bad_product' then notify(L.bad_product, 'error')
        else                           notify(L.failed, 'error') end
        return
    end

    notify(L.sold:format(done.total), 'success', 3500)
end)

-- Fallback command/keybind
RegisterCommand(Config.Keybind.command, function()
    TriggerEvent('gs_selldrugs:client:trySell')
end, false)

if Config.Keybind.default and Config.Keybind.default ~= '' then
    RegisterKeyMapping(Config.Keybind.command, 'Sell to nearby pedestrian', 'keyboard', Config.Keybind.default)
end

-- === Police Live Tracking (client) ==========================================

local Tracks = {}  -- id -> blip

local function makeBlip(info)
    local blip = AddBlipForCoord(info.coords.x, info.coords.y, info.coords.z)
    SetBlipSprite(blip, info.sprite or 161)
    SetBlipColour(blip, info.colour or 1)
    SetBlipScale(blip, info.scale or 1.2)
    SetBlipAlpha(blip, info.alpha or 200)
    SetBlipAsShortRange(blip, false)
    if info.route then
        SetBlipRoute(blip, true)
        SetBlipRouteColour(blip, info.colour or 1)
    end
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(info.name or 'Drug Sale Suspect')
    EndTextCommandSetBlipName(blip)
    return blip
end

RegisterNetEvent('gs_selldrugs:policeTrackStart', function(info)
    if not info or not info.id or not info.coords then return end
    local existing = Tracks[info.id]
    if existing and DoesBlipExist(existing) then RemoveBlip(existing) end
    local blip = makeBlip(info)
    Tracks[info.id] = blip

    -- Auto-remove after configured duration (no polling loop)
    local duration = (Config.Dispatch.tracking and Config.Dispatch.tracking.duration or 60) * 1000
    SetTimeout(duration + 500, function()
        local b = Tracks[info.id]
        if b and DoesBlipExist(b) then RemoveBlip(b) end
        Tracks[info.id] = nil
        Debug.log.warn('Police tracking auto-cleared: %s', info.id)
    end)
    Debug.log.info('Police tracking started: %s', info.id)
end)

RegisterNetEvent('gs_selldrugs:policeTrackUpdate', function(id, coords)
    local blip = Tracks[id]
    if not blip or not DoesBlipExist(blip) then return end
    SetBlipCoords(blip, coords.x, coords.y, coords.z)
end)

RegisterNetEvent('gs_selldrugs:policeTrackStop', function(id)
    local blip = Tracks[id]
    if blip and DoesBlipExist(blip) then RemoveBlip(blip) end
    Tracks[id] = nil
    Debug.log.info('Police tracking stopped: %s', id)
end)
