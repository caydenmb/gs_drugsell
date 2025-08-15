CreateThread(function()
    local third = Config.ThirdEye
    if not third or not third.enabled then return end
    if third.provider ~= 'ox_target' then
        lib.print.warn(('[gs_selldrugs] ThirdEye.provider "%s" not supported'):format(third.provider or 'nil'))
        return
    end
    if GetResourceState('ox_target') ~= 'started' then
        lib.print.warn('[gs_selldrugs] ox_target configured but not running; third-eye disabled.')
        return
    end

    exports.ox_target:addGlobalPed({
        {
            name = 'gs_selldrugs_offer',
            icon = third.icon or 'fa-solid fa-handshake',
            label = third.label or 'Offer Product',
            distance = third.distance or 2.0,
            -- Keep canInteract light to avoid AC/devmode spam.
            canInteract = function(entity, distance)
                return distance <= (third.distance or 2.0)
                    and IsEntityAPed(entity)
                    and not IsPedAPlayer(entity)
                    and not IsPedDeadOrDying(entity, true)
            end,
            onSelect = function(data)
                local pedNet = NetworkGetNetworkIdFromEntity(data.entity)
                TriggerEvent('gs_selldrugs:client:trySell', pedNet)
            end
        }
    })

    lib.print.info('[gs_selldrugs] Third-eye (ox_target) enabled.')
end)
