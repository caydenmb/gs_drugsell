local Debug = Debug or require 'shared/debug'
local Dispatch = require 'server.dispatch_bridge'
local ESX = exports['es_extended']:getSharedObject()

-- Offers[token] = { src, pedNet, item, qty, priceEach, total, expiresAt, snitched }
local Offers = {}
-- Active deal lock: src -> expiresAt (while a token is live)
local Active = {}
-- Cooldowns
local Cooldowns = { ped = {}, player = {}, globalAt = 0 }

-- Cached cop count (~5s)
local lastCopCount, lastCopCountAt = 0, 0
local function getCopCount()
    local now = GetGameTimer()
    if now - lastCopCountAt < 5000 then return lastCopCount end
    lastCopCountAt = now
    local count = 0
    if ESX and ESX.GetExtendedPlayers then
        local xPlayers = ESX.GetExtendedPlayers()
        local pj = {}
        for i=1, #Config.PoliceJobs do pj[Config.PoliceJobs[i]] = true end
        for i=1, #xPlayers do
            local job = xPlayers[i].getJob() and xPlayers[i].getJob().name
            if job and pj[job:lower()] then count = count + 1 end
        end
    end
    lastCopCount = count
    return count
end

local function inBlacklistZone(coords)
    local zones = Config.BlacklistZones
    if not zones or #zones == 0 then return false end
    for i=1, #zones do
        local z = zones[i]
        if #(coords - z.coords) <= (z.radius or 30.0) then
            return z.reason or true
        end
    end
    return false
end

local function token()
    return ('%d-%d'):format(os.time(), math.random(10^6, 10^7-1))
end

local function rollOffer(itemName)
    local cfg = Config.Items[itemName]
    if not cfg then return nil, 'unknown_item' end
    if math.random(100) > (cfg.sellAcceptChance or 100) then
        return nil, 'reject'
    end
    local qty = math.random(cfg.minQty, cfg.maxQty)
    local priceEach = math.random(cfg.minPrice, cfg.maxPrice)
    local duration = math.floor((Config.BaseSellDuration or 4500) * (0.75 + math.random() * 0.5))
    return { qty = qty, priceEach = priceEach, total = qty * priceEach, duration = duration }
end

-- Expired-offer sweep: free active locks cleanly
CreateThread(function()
    while true do
        Wait(10000)
        local now = os.time()
        for t, o in pairs(Offers) do
            if now > (o.expiresAt or 0) then
                Active[o.src] = nil
                Offers[t] = nil
                Debug.log.dbg('Offer expired & cleared for %s', o.src)
            end
        end
        for src, untilAt in pairs(Active) do
            if now > untilAt then Active[src] = nil end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local src = source
    -- Clear offers and lock for the dropped player
    for t, o in pairs(Offers) do
        if o.src == src then Offers[t] = nil end
    end
    Active[src] = nil
end)

-- Stage 1: request offer (no inventory change yet)
lib.callback.register('gs_selldrugs:requestOffer', function(src, data)
    local pedNet = data and data.ped
    local item = data and data.item
    if not pedNet or not item then
        Debug.log.warn('requestOffer invalid args from %s', src)
        return { ok = false, reason = 'invalid' }
    end

    local nowSec = os.time()

    -- ACTIVE DEAL LOCK (anti-restart exploit)
    if Active[src] and nowSec < Active[src] then
        return { ok = false, reason = 'busy' }
    end

    -- Cooldowns
    if nowSec - (Cooldowns.globalAt or 0) < (Config.GlobalCooldown or 5) then
        return { ok = false, reason = 'cooldown' }
    end
    if nowSec - (Cooldowns.player[src] or 0) < (Config.PlayerCooldown or 30) then
        return { ok = false, reason = 'cooldown' }
    end
    if nowSec - (Cooldowns.ped[pedNet] or 0) < (Config.PedCooldown or 90) then
        return { ok = false, reason = 'cooldown' }
    end

    if (Config.MinCops or 0) > 0 and getCopCount() < Config.MinCops then
        return { ok = false, reason = 'cops' }
    end

    -- Quick has-item check
    local count = exports.ox_inventory:Search(src, 'count', item)
    if (count or 0) <= 0 then
        return { ok = false, reason = 'no_items' }
    end

    local pPed  = GetPlayerPed(src)
    local coords = GetEntityCoords(pPed)
    local zoneReason = inBlacklistZone(coords)
    if zoneReason then
        Debug.log.info('Blocked by zone: %s', zoneReason ~= true and zoneReason or '')
        return { ok = false, reason = 'zone' }
    end

    local offer, why = rollOffer(item)
    if not offer then
        return { ok = false, reason = why or 'reject' }
    end

    -- Resolve street once
    local _, streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local street = streetHash and GetStreetNameFromHashKey(streetHash) or 'Unknown'

    -- Ambient attempt-stage alert
    local baseAlert = Config.BasePoliceAlertChance or 0
    local itemAlert = (Config.Items[item].policeAlertChance or 0)
    if (Config.Dispatch.callOnAttempt) and math.random(100) <= (baseAlert + math.floor(itemAlert/3)) then
        Dispatch.alertPolice(src, coords, street, 'Suspicious loitering')
        TriggerClientEvent('gs_selldrugs:client:alert', src)
    end

    -- Snitch (independent)
    local snitch = (Config.SnitchChancePercent or 0) > 0 and math.random(100) <= Config.SnitchChancePercent
    if snitch then
        Dispatch.alertPolice(src, coords, street, 'Witness report: hand-to-hand')
        TriggerClientEvent('gs_selldrugs:client:alert', src)
        Debug.log.info('SNITCH: %s reported near %s', src, street)
    end

    -- Create pending offer + lock
    local t = token()
    local exp = nowSec + 30
    Offers[t] = {
        src = src, pedNet = pedNet, item = item,
        qty = offer.qty, priceEach = offer.priceEach, total = offer.total,
        expiresAt = exp,
        snitched = snitch
    }
    Active[src] = exp   -- lock player until token expires or completes

    Debug.log.dbg('Offer %s: %s x%d @ %d = %d (snitch=%s)', t, item, offer.qty, offer.priceEach, offer.total, tostring(snitch))
    return { ok = true, token = t, qty = offer.qty, priceEach = offer.priceEach, total = offer.total, duration = offer.duration, snitched = snitch }
end)

-- Stage 2: complete sale
lib.callback.register('gs_selldrugs:completeSale', function(src, data)
    local t = data and data.token
    local pedNet = data and data.ped
    local offer = t and Offers[t]
    if not offer then
        Active[src] = nil
        return { ok = false, reason = 'invalid' }
    end

    if offer.src ~= src or offer.pedNet ~= pedNet or os.time() > (offer.expiresAt or 0) then
        Offers[t] = nil
        Active[src] = nil
        return { ok = false, reason = 'expired' }
    end

    local ped = NetworkGetEntityFromNetworkId(offer.pedNet)
    if not DoesEntityExist(ped) then
        Offers[t] = nil; Active[src] = nil
        return { ok = false, reason = 'no_ped' }
    end

    local pPed = GetPlayerPed(src)
    if #(GetEntityCoords(pPed) - GetEntityCoords(ped)) > (Config.MaxDistance or 8.0) then
        Offers[t] = nil; Active[src] = nil
        return { ok = false, reason = 'too_far' }
    end

    -- Bad Product roll (after progress, before item removal/payment)
    local badProduct = (Config.BadProductFailPercent or 0) > 0 and math.random(100) <= Config.BadProductFailPercent
    if badProduct then
        local nowSec = os.time()
        Cooldowns.globalAt = nowSec
        Cooldowns.player[src] = nowSec
        Cooldowns.ped[offer.pedNet] = nowSec
        Offers[t] = nil; Active[src] = nil
        Debug.log.info('BAD PRODUCT: ped %s refused %s from %s', tostring(offer.pedNet), offer.item, src)
        return { ok = false, reason = 'bad_product' }  -- items kept
    end

    -- Proceed with normal sale
    local have = exports.ox_inventory:Search(src, 'count', offer.item)
    if (have or 0) < offer.qty then
        Offers[t] = nil; Active[src] = nil
        return { ok = false, reason = 'no_items' }
    end

    if not exports.ox_inventory:RemoveItem(src, offer.item, offer.qty) then
        Offers[t] = nil; Active[src] = nil
        Debug.log.warn('RemoveItem failed for %s x%d from %s', offer.item, offer.qty, src)
        return { ok = false, reason = 'fail' }
    end

    local xPlayer = ESX.GetPlayerFromId(src)
    if not xPlayer then
        Offers[t] = nil; Active[src] = nil
        return { ok = false, reason = 'fail' }
    end

    if (Config.Account or 'black_money') == 'cash' then
        xPlayer.addMoney(offer.total)
    else
        xPlayer.addAccountMoney(Config.Account or 'black_money', offer.total)
    end

    local nowSec = os.time()
    Cooldowns.globalAt = nowSec
    Cooldowns.player[src] = nowSec
    Cooldowns.ped[offer.pedNet] = nowSec

    -- Optional success-stage alert for higher-risk items
    local risk = (Config.Items[offer.item].policeAlertChance or 0)
    if risk >= 15 and Config.Dispatch.callOnSuccess then
        local coords = GetEntityCoords(pPed)
        local _, streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
        local street = streetHash and GetStreetNameFromHashKey(streetHash) or 'Unknown'
        Dispatch.alertPolice(src, coords, street, 'Possible hand-to-hand transaction')
        TriggerClientEvent('gs_selldrugs:client:alert', src)
    end

    Offers[t] = nil; Active[src] = nil
    Debug.log.info('Sold %s x%d to ped %s for $%d', offer.item, offer.qty, tostring(offer.pedNet), offer.total)
    return { ok = true, total = offer.total }
end)
