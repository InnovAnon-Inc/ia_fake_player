-- ia_fake_player/actions/simple.lua

ia_fake_player.actions.simple = {}

local modname                 = minetest.get_current_modname() or 'ia_fake_player'
local modpath, S              = ia_util.get_header_vars(modname)
modpath                       = modpath..DIR_DELIM..'actions'..DIR_DELIM..'simple'
local files                   = ia_util.get_dir_list(modpath, ia_util.lua_file_filter, ia_util.mod_dir_blacklist)
ia_util.dofiles(modpath, files)

