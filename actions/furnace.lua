-- ia_dunce/furnace.lua

--- Low-level: Is this node a furnace?
function ia_dunce.is_furnace(pos)
    local node = minetest.get_node(pos)
    return minetest.get_item_group(node.name, "furnace") > 0
end

--- Mid-level: Is the furnace accessible and ready for use?
function ia_dunce.can_use_furnace(self, pos)
    if not ia_dunce.is_furnace(pos) then return false end
    
    local meta = minetest.get_meta(pos)
    local owner = meta:get_string("owner")
    return owner == "" or owner == self.name
end

--- High-level: Could we smelt here if we crafted/placed a furnace?
function ia_dunce.could_smelt_here(self, pos)
    if ia_dunce.can_use_furnace(self, pos) then return true end
    
    if ia_dunce.is_buildable(pos) and ia_dunce.can_obtain_item(self, "default:furnace") then
        return true
    end
    return false
end

--- Level 1: Atomic Action - Manage furnace inventories
-- Uses the 'operations' pattern from your appliance code
function ia_dunce.operate_furnace(self, pos)
    minetest.log('ia_dunce.operate_furnace()')
    local node_meta = minetest.get_meta(pos)
    local node_inv = node_meta:get_inventory()
    local vil_inv = self.fake_player:get_inventory()

    -- 1. Take finished products from 'dst' (Output)
    ia_dunce._process_take(self, vil_inv, node_inv, pos, {
        list = "dst",
        take_func = function(s) return true end
    })

    -- 2. Put fuel into 'fuel' slot
    ia_dunce._process_put(self, vil_inv, node_inv, pos, {
        list = "fuel",
        is_put = true,
        put_func = function(self, stack) 
            return minetest.get_craft_result({method="fuel", width=1, items={stack}}).time > 0 
        end
    })

    -- 3. Put cookables into 'src' (Input)
    ia_dunce._process_put(self, vil_inv, node_inv, pos, {
        list = "src",
        is_put = true,
        put_func = function(self, stack)
            return minetest.get_craft_result({method="cooking", width=1, items={stack}}).time > 0
        end
    })
end

--- Level 2: Preparation + Action
function ia_dunce.place_and_smelt(self, pos)
    minetest.log('ia_dunce.place_and_smelt()')
    if ia_dunce.wield_by_condition(self, "default:furnace") then
        if ia_dunce.right_click(self, pos, false) then
            return ia_dunce.operate_furnace(self, pos)
        end
    end
    return false
end

--- Level 3: Provisioning + Preparation + Action
function ia_dunce.craft_and_smelt(self, pos)
    minetest.log('ia_dunce.craft_and_smelt()')
    if not ia_dunce.has_item(self, "default:furnace") then
        ia_dunce.craft_item(self, "default:furnace")
    end
    return ia_dunce.place_and_smelt(self, pos)
end
