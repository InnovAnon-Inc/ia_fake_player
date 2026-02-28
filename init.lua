ia_fake_player = {}

-- adapted from `feed_buckets`

-- fake player
function ia_fake_player:get_pos()
  return self.object:get_pos()
end
function ia_fake_player:set_pos(vel)
  return self.object:set_pos(vel)
end
function ia_fake_player:get_velocity()
  return self.object:get_velocity()
end
function ia_fake_player:add_velocity(vel)
  return self.object:add_velocity(vel)
end

function ia_fake_player:move_to(...)
  return self.object:move_to(...)
end
function ia_fake_player:punch(...)
  return self.object:punch(...)
end
function ia_fake_player:right_click(clicker)
  return self.object:right_click(clicker)
end

function ia_fake_player:get_wield_list()
  return self.object:get_wield_list()
end
function ia_fake_player:get_wield_index()
  return self.object:get_wield_index()
end

function ia_fake_player:get_armor_groups()
  return self.object:get_armor_groups()
end
function ia_fake_player:set_armor_groups(groups)
  return self.object:set_armor_groups(groups)
end

function ia_fake_player:get_animation()
  return self.object:get_animation()
end
function ia_fake_player:set_animation(...)
  return self.object:set_animation(...)
end

function ia_fake_player:set_animation_frame_speed(frame_speed)
  return self.object:set_animation_frame_speed(frame_speed)
end
function ia_fake_player:get_attach()
  return self.object:get_attach()
end
function ia_fake_player:set_attach(...)
  return self.object:set_attach(...)
end
function ia_fake_player:get_children()
  return self.object:get_children()
end
function ia_fake_player:set_detach()
  return self.object:set_detach()
end

function ia_fake_player:get_bone_position()
  return self.object:get_bone_position()
end
function ia_fake_player:set_bone_position(...)
  return self.object:set_bone_position(...)
end

function ia_fake_player:set_properties(vel)
  return self.object:set_properties(vel)
end

function ia_fake_player:get_nametag_attributes()
  return self.object:get_nametag_attributes()
end
function ia_fake_player:set_nametag_attributes(vel)
  return self.object:set_nametag_attributes(vel)
end

-- lua entity
function ia_fake_player:remove()
  return self.object:remove()
end

function ia_fake_player:set_velocity(vel)
  return self.object:set_velocity(vel)
end

function ia_fake_player:get_acceleration()
  return self.object:get_acceleration()
end
function ia_fake_player:set_acceleration(acc)
  return self.object:set_acceleration(acc)
end

function ia_fake_player:get_rotation()
  return self.object:get_rotation()
end
function ia_fake_player:set_rotation(rot)
  return self.object:set_rotation(rot)
end

function ia_fake_player:get_yaw()
  return self.object:get_yaw()
end
function ia_fake_player:set_yaw(yaw)
  return self.object:set_yaw(yaw)
end

function ia_fake_player:get_texture_mod()
  return self.object:get_texture_mod()
end
function ia_fake_player:set_texture_mod(mod)
  return self.object:set_texture_mod(mod)
end

function ia_fake_player:set_sprite(...)
  return self.object:set_sprite(...)
end

function ia_fake_player:get_luaentity()
  return self.object:get_luaentity()
end

-- player specific

function ia_fake_player:get_look_dir()
  return self.object:get_look_dir()
end
function ia_fake_player:get_look_vertical()
  return self.object:get_look_vertical()
end
function ia_fake_player:set_look_vertical(radians)
  return self.object:set_look_vertical(radians)
end
function ia_fake_player:get_look_horizontal()
  return self.object:get_look_horizontal()
end
function ia_fake_player:set_look_horizontal(radians)
  return self.object:set_look_horizontal(radians)
end

function ia_fake_player:get_breath()
  return self.object:get_breath()
end
function ia_fake_player:set_breath(value)
  return self.object:set_breath(value)
end

function ia_fake_player:get_fov()
  return self.object:get_fov()
end
function ia_fake_player:set_fov(fov, is_multiplier, transition_time)
  return self.object:set_fov(fov, is_multiplier, transition_time)
end

function ia_fake_player:get_meta()
  return self.object:get_meta()
end

function ia_fake_player:get_inventory_formspec()
  return self.object:get_inventory_formspec()
end
function ia_fake_player:set_inventory_formspec(formspec)
  return self.object:set_inventory_formspec(formspec)
end
--function ia_fake_player:get_inventory()
--  return self.object:get_inventory()
--end

function ia_fake_player:get_formspec_prepend(formspec)
  return self.object:get_formspec_prepend(formspec)
end
function ia_fake_player:set_formspec_prepend(formspec)
  return self.object:set_formspec_prepend(formspec)
end

function ia_fake_player:get_player_control()
  return self.object:get_player_control()
end
function ia_fake_player:get_player_control_bits()
  return self.object:get_player_control_bits()
end

function ia_fake_player:get_physics_override()
  return self.object:get_physics_override()
end
function ia_fake_player:set_physics_override(override_table)
  return self.object:set_physics_override(override_table)
end

function ia_fake_player:hud_add(hud_definition)
  return self.object:hud_add(hud_definition)
end
function ia_fake_player:hud_remove(id)
  return self.object:hud_remove(id)
end
function ia_fake_player:hud_change(id, stat, value)
  return self.object:hud_change(id, stat, value)
end
function ia_fake_player:hud_get(id)
  return self.object:hud_get(id)
end

function ia_fake_player:hud_get_flags()
  return self.object:hud_get_flags()
end
function ia_fake_player:hud_set_flags(flags)
  return self.object:hud_set_flags(flags)
end

function ia_fake_player:hud_get_hotbar_itemcount()
  return self.object:hud_get_hotbar_itemcount()
end
function ia_fake_player:hud_set_hotbar_itemcount(count)
  return self.object:hud_set_hotbar_itemcount(count)
end

function ia_fake_player:hud_get_hotbar_image()
  return self.object:hud_get_hotbar_image()
end
function ia_fake_player:hud_set_hotbar_image(texturename)
  return self.object:hud_set_hotbar_image(texturename)
end

function ia_fake_player:hud_get_hotbar_selected_image()
  return self.object:hud_get_hotbar_selected_image()
end
function ia_fake_player:hud_set_hotbar_selected_image(texturename)
  return self.object:hud_set_hotbar_selected_image(texturename)
end

function ia_fake_player:set_minimap_modes(modes, selected_mode)
  return self.object:set_minimap_modes(modes, selected_mode)
end

function ia_fake_player:get_sky()
  return self.object:get_sky()
end
function ia_fake_player:set_sky(sky_parameters)
  return self.object:set_sky(sky_parameters)
end
function ia_fake_player:get_sky_color()
  return self.object:get_sky_color()
end

function ia_fake_player:get_sun()
  return self.object:get_sun()
end
function ia_fake_player:set_sun(sun_parameters)
  return self.object:set_sun(sun_parameters)
end

function ia_fake_player:get_moon()
  return self.object:get_moon()
end
function ia_fake_player:set_moon(moon_parameters)
  return self.object:set_moon(moon_parameters)
end

function ia_fake_player:get_stars()
  return self.object:get_stars()
end
function ia_fake_player:set_stars(stars_parameters)
  return self.object:set_stars(stars_parameters)
end

function ia_fake_player:get_clouds()
  return self.object:get_clouds()
end
function ia_fake_player:set_clouds(clouds_parameters)
  return self.object:set_clouds(clouds_parameters)
end

function ia_fake_player:get_day_night_ratio()
  return self.object:get_day_night_ratio()
end
function ia_fake_player:override_day_night_ratio(ratio)
  return self.object:override_day_night_ratio(ratio)
end

function ia_fake_player:get_local_animation()
  return self.object:get_local_animation()
end
function ia_fake_player:set_local_animation(...)
  return self.object:set_local_animation(...)
end

function ia_fake_player:get_eye_offset()
  return self.object:get_eye_offset()
end
function ia_fake_player:set_eye_offset(...)
  return self.object:set_eye_offset(...)
end

function ia_fake_player:send_mapblock(blockpos)
  return self.object:send_mapblock(blockpos)
end

function ia_fake_player.new(obj)
    return setmetatable({object = obj}, {__index = ia_fake_player})
end
