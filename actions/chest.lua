-- ia_dunce/chest.lua

--- Low-level: Is this node a storage container?
function ia_dunce.is_chest(pos)
    local node = minetest.get_node(pos)
    return minetest.get_item_group(node.name, "chest") > 0 or 
           minetest.get_item_group(node.name, "container") > 0
end

--- Mid-level: Can we currently access and use this chest?
function ia_dunce.can_use_chest(self, pos)
    if not ia_dunce.is_chest(pos) then return false end
    
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("owner")
    -- Check for locked chests
    if owner ~= "" and owner ~= self.name then return false end
    
    return true
end

--- High-level: Could we store items here if we crafted/placed a chest?
function ia_dunce.could_store_here(self, pos)
    if ia_dunce.can_use_chest(self, pos) then return true end
    
    if ia_dunce.is_buildable(pos) and ia_dunce.can_obtain_item(self, "default:chest") then
        return true
    end
    return false
end

--- Level 1: Atomic Action (Dumps entire inventory into chest)
function ia_dunce.store_all(self, pos)
    minetest.log('ia_dunce.store_all()')
    local node_meta = minetest.get_meta(pos)
    local node_inv = node_meta:get_inventory()
    local vil_inv = self.fake_player:get_inventory()
    
    local op = {
        is_put = true,
        list = "main", -- The chest's list name
        put_func = function(self, stack) return true end -- Put everything
    }
    
    return ia_dunce._process_put(self, vil_inv, node_inv, pos, op)
end

--- Level 2: Preparation + Action (Wields chest, places it, then stores)
function ia_dunce.place_and_store(self, pos)
    minetest.log('ia_dunce.place_and_store()')
    local is_chest = function(n) return minetest.get_item_group(n, "chest") > 0 end
    
    if ia_dunce.wield_by_condition(self, is_chest) then
        local success = ia_dunce.right_click(self, pos, false)
        if success then
            return ia_dunce.store_all(self, pos)
        end
    end
    return false
end

--- Level 3: Provisioning + Preparation + Action
function ia_dunce.craft_and_store(self, pos)
    minetest.log('ia_dunce.craft_and_store()')
    if not ia_dunce.has_item(self, "default:chest") then
        ia_dunce.craft_item(self, "default:chest")
    end
    return ia_dunce.place_and_store(self, pos)
end
