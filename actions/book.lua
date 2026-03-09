-- ia_dunce/book.lua
-- Feature matrix for handling books and spellbooks.

-- CHANGE: Local mapping for book-related groups and names
local book_types = {
    names = {
        ["default:book"]        = true,
        ["default:book_open"]   = true,
        ["default:book_closed"] = true,
    },
    groups = {
        ["spellbook"] = true,
        ["book"]      = true,
    }
}

--- Low-level: Is the node at this position a valid book/spellbook?
function ia_dunce.is_readable(pos)
    local node = minetest.get_node(pos)
    if book_types.names[node.name] then return true end
    
    for group, _ in pairs(book_types.groups) do
        if minetest.get_item_group(node.name, group) > 0 then
            return true
        end
    end
    return false
end

--- Mid-level: Is the agent currently capable of interacting with this book?
function ia_dunce.can_read(self, pos)
    if not ia_dunce.is_readable(pos) then return false end
    
    -- Interaction usually requires being close enough
    return ia_dunce.is_within_reach(self, pos)
end

--- High-level: Could the agent read this if they moved or obtained necessary items?
function ia_dunce.could_read(self, pos)
    -- If it's a book, we can read it once we reach it.
    return ia_dunce.is_readable(pos)
end

--- Level 1: Atomic Action
-- Performs the right-click/use interaction on a book node.
function ia_dunce.read_book(self, pos)
    minetest.log('ia_dunce.read_book()')
    -- Right-clicking books usually opens their UI or triggers a spell.
    return ia_dunce.right_click(self, pos, false)
end

--- Level 2: Preparation + Action
-- Ensures the agent is looking at and ready to interact with the book.
function ia_dunce.equip_and_read(self, pos)
    minetest.log('ia_dunce.equip_and_read()')
    if not ia_dunce.can_read(self, pos) then
        return false, "out_of_reach_or_invalid"
    end

    ia_dunce.stop_and_look_at(self, pos)
    return ia_dunce.read_book(self, pos)
end

--- Level 3: Provisioning + Preparation + Action
-- Placeholder for complex book interactions (e.g. obtaining a magnifying glass or light).
-- Currently ensures the path is clear and interaction is executed.
function ia_dunce.obtain_and_read(self, pos)
    minetest.log('ia_dunce.obtain_and_read()')
    
    -- If we aren't at the book, we would usually trigger pathfinding here.
    -- Assuming the agent has reached the destination:
    return ia_dunce.equip_and_read(self, pos)
end

--- Helper: Check if an item in inventory is a book.
function ia_dunce.is_book_item(item_name)
    if book_types.names[item_name] then return true end
    for group, _ in pairs(book_types.groups) do
        if minetest.get_item_group(item_name, group) > 0 then
            return true
        end
    end
    return false
end
