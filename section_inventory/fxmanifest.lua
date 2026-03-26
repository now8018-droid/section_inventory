fx_version "cerulean"
game "gta5"

lua54 "yes"

ui_page "web/dist/index.html"

shared_script {
    'configuration/developer.lua',
    'configuration/*.lua',
    -- 'shared/*.lua',
}

server_script {
    '@oxmysql/lib/MySQL.lua',
    'server/functions.lua',
    'server/*.lua',
}

client_script {
    'client/functions.lua',
    'client/*.lua',
}



files {
    "web/dist/index.html",
    'web/dist/assets/*.js',
	'web/dist/assets/*.css',
	'web/dist/items/*.png',
	'web/dist/sounds/*.mp3',
	'web/dist/*.png',
	'web/dist/*.svg',
}