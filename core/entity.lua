-- ia_fake_player/entity.lua

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

