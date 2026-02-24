fx_version 'cerulean'

game 'gta5'

name 'Agency-Sit'
author 'AgencyScripts'
version '1.0.0'
description 'Advanced sit script with automatic chair detection'

-- Discord Support: https://discord.gg/zbG53tTUXR
-- Shop: https://agency-script.tebex.io
-- Agency-Notify: https://agency-script.tebex.io/package/6937769

lua54 'yes'

shared_scripts {
    'shared/config.lua',
    'shared/framework.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    'server/main.lua'
}
