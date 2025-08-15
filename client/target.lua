CreateThread(function()
    if GetResourceState('ox_target') ~= 'started' then return end

    exports.ox_target:addGlobalPed({
        {
            name = 'gs_selldrugs_offer',
            icon = 'fa-solid fa-handshake',
            label = 'Offer Product',
            canInteract = function(entity, distance)
                return distance <= 2.0 and IsEntityAPed(entity)
                    and not IsPedAPlayer(entity)
                    and not IsPedDeadOrDying(entity, true)
            end,
            onSelect = function(data)
                local ped = data.entity
                local pedNet = NetworkGetNetworkIdFromEntity(ped)
                TriggerEvent('gs_selldrugs:client:trySell', pedNet)
            end
        }
    })
end)
