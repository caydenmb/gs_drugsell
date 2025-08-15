fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'gs_selldrugs'
description 'Secure, optimized NPC drug selling for ESX using ox_inventory & ox_lib; dispatch via redutzu_mdt or cd_dispatch; live police tracking + snitch/bad-product + ped handoff animation'
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
    '@oxmysql/lib/MySQL.lua',  -- harmless if unused
    'server/dispatch_bridge.lua',
    'server/main.lua'
}

client_scripts {
    'client/target.lua',
    'client/main.lua'
}