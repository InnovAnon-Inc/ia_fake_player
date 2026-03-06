-- ia_fake_player/common.lua

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

