local Debug = Debug or require 'shared/debug'
local bridge = {}

-- Cached provider choice & state
local chosenProvider = nil

-- Cooldowns per suspect
bridge._cooldowns = bridge._cooldowns or {}

-- Active tracks: suspectSrc -> { id, endAt, nextAt }
bridge._tracks = bridge._tracks or {}

-- Single manager loop guard
bridge._managerRunning = bridge._managerRunning or false

-- Cached police roster for quick broadcasts
local policeSet = policeSet or {}   -- [src] = true
local policeList = policeList or {} -- array

-- === ESX helpers ============================================================

local function ESX() return exports['es_extended']:getSharedObject() end

local function isPoliceJob(name)
    if not name then return false end
    name = name:lower()
    for i=1, #Config.PoliceJobs do
        if Config.PoliceJobs[i] == name then return true end
    end
    return false
end

local function rebuildPoliceRoster()
    table.wipe = table.wipe or function(t) for k in pairs(t) do t[k]=nil end end
    table.wipe(policeSet); table.wipe(policeList)
    local esx = ESX()
    if not esx or not esx.GetExtendedPlayers then return end
    local players = esx.GetExtendedPlayers()
    for i=1, #players do
        local xP = players[i]
        local job = xP.getJob() and xP.getJob().name
        if isPoliceJob(job) then
            policeSet[xP.source] = true
        end
    end
    for src in pairs(policeSet) do
        policeList[#policeList+1] = src
    end
    Debug.log.info('Police roster rebuilt (%d officers)', #policeList)
end

RegisterNetEvent('esx:playerLoaded', function(src, xPlayer)
    local job = xPlayer and xPlayer.job and xPlayer.job.name
    if isPoliceJob(job) and not policeSet[src] then
        policeSet[src] = true; policeList[#policeList+1] = src
    end
end)

RegisterNetEvent('esx:setJob', function(job)
    local src = source
    local was = policeSet[src] and true or false
    local now = isPoliceJob(job and job.name)
    if was == now then return end
    if now then
        policeSet[src] = true; policeList[#policeList+1] = src
    else
        policeSet[src] = nil
        policeList = {}
        for s in pairs(policeSet) do policeList[#policeList+1] = s end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    policeSet[src] = nil
    local tr = bridge._tracks[src]
    if tr then tr.endAt = 0 end
end)

CreateThread(function()
    while true do
        Wait(60000) -- 60s
        rebuildPoliceRoster()
    end
end)

-- === Provider detection =====================================================

local function isResourceStarted(name)
    local st = GetResourceState(name)
    return st == 'started' or st == 'starting'
end

local function detectProvider()
    if Config.Dispatch.force and Config.Dispatch.force ~= '' then
        chosenProvider = Config.Dispatch.force
        Debug.log.info('Dispatch provider forced: %s', chosenProvider)
        return chosenProvider
    end
    local providers = Config.Dispatch.providers or {}
    for i=1, #providers do
        local p = providers[i]
        if p == 'redutzu_mdt' and (isResourceStarted('redutzu_mdt') or isResourceStarted('redutzu-mdt')) then
            chosenProvider = 'redutzu_mdt'
            Debug.log.info('Dispatch provider: redutzu_mdt')
            return chosenProvider
        elseif p == 'cd_dispatch' and isResourceStarted('cd_dispatch') then
            chosenProvider = 'cd_dispatch'
            Debug.log.info('Dispatch provider: cd_dispatch')
            return chosenProvider
        end
    end
    chosenProvider = 'fallback'
    Debug.log.warn('No dispatch provider; using fallback chat.')
    return chosenProvider
end

-- === Broadcasts to police ===================================================

local function broadcastToCops(event, ...)
    for i=1, #policeList do
        TriggerClientEvent(event, policeList[i], ...)
    end
end

-- === Provider sends =========================================================

local function toRedutzuMDT(coords, street, hint)
    local red = Config.Dispatch.redutzu or {}
    local payload = {
        code   = red.code  or '10-47',
        title  = red.title or 'Drug Sale In Progress',
        street = street or 'Unknown',
        message = hint or 'Possible hand-to-hand transaction',
        coords  = { x = coords.x, y = coords.y, z = coords.z }
    }
    TriggerEvent('redutzu-mdt:server:addDispatchToMDT', payload)
end

local function toCdDispatch(coords, street, hint)
    TriggerEvent('cd_dispatch:AddNotification', {
        job_table = Config.PoliceJobs,
        coords = coords,
        title = 'Drug Sale In Progress',
        message = hint or ('Suspicious activity near '..(street or 'unknown')),
        flash = 0,
        unique_id = tostring(math.random(10000, 99999)),
        blip = {
            sprite = 66, scale = 1.1, colour = 1, flashes = false,
            text = 'Drug Sale In Progress', time = 5, sound = 1,
            radius = Config.Dispatch.radius or 30.0
        }
    })
end

-- === Live tracking manager ==================================================

local function ensureTrackingManager()
    if bridge._managerRunning then return end
    bridge._managerRunning = true

    CreateThread(function()
        local interval = (Config.Dispatch.tracking and Config.Dispatch.tracking.interval or 5) * 1000
        if interval < 1000 then interval = 1000 end

        while bridge._managerRunning do
            local now = GetGameTimer()
            for suspectSrc, tr in pairs(bridge._tracks) do
                if tr.endAt <= now then
                    broadcastToCops('gs_selldrugs:policeTrackStop', tr.id)
                    bridge._tracks[suspectSrc] = nil
                    Debug.log.info('Tracking ended for %s (%s)', suspectSrc, tr.id)
                else
                    if now >= tr.nextAt then
                        local ped = GetPlayerPed(suspectSrc)
                        if ped ~= 0 then
                            local pos = GetEntityCoords(ped)
                            broadcastToCops('gs_selldrugs:policeTrackUpdate', tr.id, { x = pos.x, y = pos.y, z = pos.z })
                        end
                        tr.nextAt = now + interval
                    end
                end
            end
            Wait(1000) -- 1s heartbeat
        end
    end)
end

local function startLiveTracking(suspectSrc, initialCoords)
    local tcfg = Config.Dispatch.tracking
    if not (tcfg and tcfg.enabled) then return end

    local id = ('trk-%d-%d'):format(suspectSrc, os.time())
    local now = GetGameTimer()
    local duration = (tcfg.duration or 60) * 1000

    bridge._tracks[suspectSrc] = {
        id = id,
        endAt = now + duration,
        nextAt = now,
    }

    broadcastToCops('gs_selldrugs:policeTrackStart', {
        id     = id,
        name   = tcfg.name or 'Drug Sale Suspect',
        sprite = tcfg.sprite or 161,
        colour = tcfg.colour or 1,
        scale  = tcfg.scale  or 1.2,
        alpha  = tcfg.alpha  or 200,
        route  = tcfg.route  or false,
        coords = { x = initialCoords.x, y = initialCoords.y, z = initialCoords.z }
    })

    ensureTrackingManager()
end

-- === Public API =============================================================

function bridge.alertPolice(suspectSrc, coords, street, hint)
    if not Config.Dispatch.enabled then return end

    -- Rate limit per suspect
    local now = os.time()
    local key = ('alert_cool_%s'):format(suspectSrc)
    if bridge._cooldowns[key] and now - bridge._cooldowns[key] < (Config.Dispatch.cooldown or 15) then
        Debug.log.trace('Dispatch rate-limited for %s', suspectSrc)
        return
    end
    bridge._cooldowns[key] = now

    local provider = chosenProvider or detectProvider()
    if Debug.level >= 2 then
        Debug.log.info(('Dispatch %s @ %.1f,%.1f,%0.1f (%s) via %s'):format(
            suspectSrc, coords.x, coords.y, coords.z, street or 'unknown', provider))
    end

    if provider == 'redutzu_mdt' then
        toRedutzuMDT(coords, street, hint)
    elseif provider == 'cd_dispatch' then
        toCdDispatch(coords, street, hint)
    else
        for i=1, #policeList do
            TriggerClientEvent('chat:addMessage', policeList[i], { args = {'^1Dispatch', ('Drug sale reported near %s'):format(street or 'unknown')} })
        end
    end

    -- Start in-resource live tracking
    startLiveTracking(suspectSrc, coords)
end

return bridge
