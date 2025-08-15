fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'gs_selldrugs'
description 'Optimized NPC drug selling for ESX with ox_inventory/ox_lib, MDT dispatch (10-47), live tracking, third-eye support, anti-exploit locks, and polished ped handoff.'
author 'Gingr Snaps'
version '1.0.0'

dependencies {
    'es_extended',
    'ox_lib',
    'ox_inventory'
}

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/en.lua',
    'shared/debug.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/dispatch_bridge.lua',
    'server/main.lua'
}

client_scripts {
    'client/target.lua',
    'client/main.lua'
}
