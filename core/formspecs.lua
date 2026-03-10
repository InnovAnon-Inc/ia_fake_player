-- ia_fake_player/core/formspecs.lua

assert(minetest.get_modpath('ia_util'))
assert(ia_util ~= nil)
local modname                    = minetest.get_current_modname() or "ia_fake_player"

ia_fake_player.formspecs         = {}

local formspec_prefix = modname .. ":inv_"

local function get_formspec_id(modname, mob_id)
    if not mob_id then return formspec_prefix end
    return formspec_prefix .. mob_id
end

local function get_formspec_prefix(formname)
    return formname:sub(1, #formspec_prefix)
end

local function is_fake_player_formspec(formname)
    local prefix = get_formspec_prefix(formname)
    return (prefix == formspec_prefix)
end

local function strip_formspec_prefix(formname)
    return formname:sub(#formspec_prefix + 1)
end

-- Helper to safely get stats for the formspec
--function ia_fake_player.get_mob_stat(mob_id, attribute, default_val)
--    assert(minetest.get_modpath('hunger_ng'))
--    local val = hunger_ng.functions.get_data(mob_id, attribute)
--    return val or default_val or 0
--end

-- Helper for building status icons with text labels
function ia_fake_player.get_formspec_item(x, y, icon, label, value)
    assert(x     ~= nil)
    assert(y     ~= nil)
    assert(icon  ~= nil)
    assert(label ~= nil)
    assert(value ~= nil)
    return string.format("image[%f,%f;0.5,0.5;%s]label[%f,%f;%s: %s/20]",
        x, y, icon, x + 0.6, y, label, value)
end

local function increment_counters(x, dx, y, dy, count, mod)
    assert(x     ~= nil)
    assert(dx    ~= nil)
    assert(y     ~= nil)
    assert(dy    ~= nil)
    assert(count ~= nil)
    assert(mod   ~= nil)
    count             = (count + 1)
    if count % mod ~= 0 then
        x             = (x     + dx)
        return x, y, count
    end
    x                 = 0
    y                 = (y     + dy)
    return x, y, count
end

function ia_fake_player.get_formspec_items_hunger_ng(mob_id, x, y, count)
    minetest.log('ia_fake_player.get_formspec_items_hunger_ng(mob_id='..
        tostring(mob_id)..', x='..tostring(x)..', y='..tostring(y)..', count='..tostring(count)..')')
    assert(mob_id ~= nil)
    assert(x      ~= nil)
    assert(y      ~= nil)
    assert(count  ~= nil)
    if not minetest.get_modpath('hunger_ng') then return '' end
    assert(minetest.get_modpath('hunger_ng'))
    local hunger_info = hunger_ng.get_hunger_information(mob_id)
    local fs_hunger   = ""

    --if not hunger_ng.thirst_disabled(mob_id) then
        fs_hunger     = fs_hunger .. ia_fake_player.get_formspec_item(x, y, hunger_ng.thirst_bar_image, "Thirst", hunger_info.thirst.exact)
    x, y, count       = increment_counters(x, 2.6, y, 0.5, count, 3)
    --if not hunger_ng.hunger_disabled(mob_id) then
        fs_hunger     = fs_hunger .. ia_fake_player.get_formspec_item(x, y, hunger_ng.hunger_bar_image, "Hunger", hunger_info.hunger.exact)
    x, y, count       = increment_counters(x, 2.6, y, 0.5, count, 3)
    --if not hunger_ng.pee_disabled(mob_id) then
        fs_hunger     = fs_hunger .. ia_fake_player.get_formspec_item(x, y, hunger_ng.pee_bar_image,    "Pee", hunger_info.pee.exact)
    x, y, count       = increment_counters(x, 2.6, y, 0.5, count, 3)
    --if not hunger_ng.poop_disabled(mob_id) then
        fs_hunger     = fs_hunger .. ia_fake_player.get_formspec_item(x, y, hunger_ng.poop_bar_image,   "Poop", hunger_info.poop.exact)
    x, y, count       = increment_counters(x, 2.6, y, 0.5, count, 3)
    --if not hunger_ng.sleep_disabled(mob_id) then
        fs_hunger     = fs_hunger .. ia_fake_player.get_formspec_item(x, y, hunger_ng.sleep_bar_image,  "Sleep", hunger_info.sleep.exact)
    x, y, count       = increment_counters(x, 2.6, y, 0.5, count, 3)
    return fs_hunger, x, y, count
end

function ia_fake_player.get_formspec_item_hp(self, x, y, count)
    minetest.log('ia_fake_player.get_formspec_item_hp(x='..tostring(x)..', y='..tostring(y)..', count='..tostring(count)..')')
    assert(x      ~= nil)
    assert(y      ~= nil)
    assert(count  ~= nil)
    --local fs_hp                  = "label[0,0.5;Health: " .. hp .. "/" .. hp_max .. "]"
    local hp                     = self:get_hp()
    --local hp_max                 = self:get_properties().hp_max or 20
    local fs_hp                  = ia_fake_player.get_formspec_item(x, y, 'heart.png',  'Health', hp)
    x, y, count                  = increment_counters(x, 2.6, y, 0.5, count, 3)
    return fs_hp, x, y, count
end

function ia_fake_player.get_formspec_item_breath(self, x, y, count)
    minetest.log('ia_fake_player.get_formspec_item_breath(x='..tostring(x)..', y='..tostring(y)..', count='..tostring(count)..')')
    assert(x      ~= nil)
    assert(y      ~= nil)
    assert(count  ~= nil)
    --local fs_breath              = "label[0,1.0;Breath: " .. breath .. "/11]"
    local breath                 = self:get_breath() or 11
    local fs_breath              = ia_fake_player.get_formspec_item(x, y, 'bubble.png', 'Breath', breath)
    x, y, count                  = increment_counters(x, 2.6, y, 0.5, count, 3)
    return fs_breath, x, y, count
end

function ia_fake_player.get_formspec_item_hline(x, y)
    minetest.log('ia_fake_player.get_formspec_item_hline(x='..tostring(x)..', y='..tostring(y)..')')
    local h_line                 = "h_line["..x..","..y..";8]"
    x                            = 0
    y                            = (y +  .2)     -- 2.3
    return h_line, x, y
end

function ia_fake_player.get_formspec_item_main_wield(mob_id, x, y)
    minetest.log('ia_fake_player.get_formspec_item_main_wield(mob_id='..tostring(mob_id)..', x='..tostring(x)..', y='..tostring(y)..')')
    assert(mob_id ~= nil)
    assert(x      ~= nil)
    assert(y      ~= nil)
    local fs_main_wield_label    = "label["..x..","..y..";Main / Wield]"
    y                            = (y +  .5)     -- 2.8
    local fs_main_wield_value    = "list[detached:" .. minetest.formspec_escape(mob_id) .. ";main;"..x..","..y..";8,1;]"
    local fs_main_wield          = fs_main_wield_label .. fs_main_wield_value
    y                            = (y + 1.2)     -- 4.0
    return fs_main_wield, x, y
end

function ia_fake_player.get_formspec_item_armor(mob_id, x, y) -- TODO 3x2 like 3d_armor gui
    minetest.log('ia_fake_player.get_formspec_item_armor(mob_id='..tostring(mob_id)..', x='..tostring(x)..', y='..tostring(y)..')')
    assert(mob_id ~= nil)
    assert(x      ~= nil)
    assert(y      ~= nil)
    if not minetest.get_modpath('3d_armor') then return '' end
    assert(minetest.get_modpath('3d_armor'))
    local fs_armor_label         = "label["..x..","..y..";Armor]"
    y                            = y +  .5     -- 4.5
    local fs_armor_value         = "list[detached:" .. minetest.formspec_escape(mob_id) .. "_armor;armor;"..x..","..y..";6,1;]"
    y                            = y + 1.3     -- 5.8
    local fs_armor               = fs_armor_label .. fs_armor_value
    return fs_armor, x, y
end

function ia_fake_player.get_formspec_item_crafting(mob_id, x, y)
    minetest.log('ia_fake_player.get_formspec_item_crafting(mob_id='..tostring(mob_id)..', x='..tostring(x)..', y='..tostring(y)..')')
    assert(mob_id ~= nil)
    assert(x      ~= nil)
    assert(y      ~= nil)
    local fs_crafting_label      = "label["..x..","..y..";Crafting]"
    y                            = y +  .5     -- 6.3
    local fs_crafting_value      = "list[detached:" .. minetest.formspec_escape(mob_id) .. ";craft;"..x..","..y..";3,3;]"
    local fs_crafting            = fs_crafting_label .. fs_crafting_value
    x                            = x + 4
    return fs_crafting, x, y
end

function ia_fake_player.get_formspec_item_craftpreview(mob_id, x, y)
    minetest.log('ia_fake_player.get_formspec_item_craftpreview(mob_id='..tostring(mob_id)..', x='..tostring(x)..', y='..tostring(y)..')')
    assert(mob_id ~= nil)
    assert(x      ~= nil)
    assert(y      ~= nil)
    local fs_crafting_preview    = "list[detached:" .. minetest.formspec_escape(mob_id) .. ";craftpreview;"..x..","..y..";1,1;]"
    y                            = y + 1       -- 7.3
    return fs_crafting_preview, x, y
end

function ia_fake_player.get_formspec_page_status(self, mob_id, x, y)
    minetest.log('ia_fake_player.get_formspec_page_status(mob_id='..tostring(mob_id)..', x='..tostring(x)..', y='..tostring(y)..')')
    assert(mob_id ~= nil)
    assert(x      ~= nil)
    assert(y      ~= nil)

    --local                  x, y, count = 0, 0.5, 0
    local                        count = 0
    local fs_name,         x, _        = ia_fake_player.get_formspec_item_playername(self, mob_id, x, y)
    local fs_bday,         x, _        = ia_fake_player.get_formspec_item_age       (self, mob_id, x, y)
    local fs_gender,       x, y        = ia_fake_player.get_formspec_item_gender    (self, x, y)
    x                                  = 0
    local fs_hp,           x, y, count = ia_fake_player.get_formspec_item_hp    (self, x, y, count)
    local fs_breath,       x, y, count = ia_fake_player.get_formspec_item_breath(self, x, y, count)
    while count % 3 ~= 0 do -- extra padding to force newline
                           x, y, count = increment_counters(x, 2.6, y, 0.5, count, 3)
    end
    local fs_hunger,       x, y, count = ia_fake_player.get_formspec_items_hunger_ng(mob_id, x, y, count)

    local offset                       = (2.1 - 1.5) -- old magic numbers
    x                                  = 0
    y                                  = (y + offset)  -- 2.1
    local hline,           x, y        = ia_fake_player.get_formspec_item_hline(x, y)
    local fs_main_wield,   x, y        = ia_fake_player.get_formspec_item_main_wield(mob_id, x, y)
    local fs_armor,        x, y        = ia_fake_player.get_formspec_item_armor(mob_id, x, y)
    local fs_crafting,     x, y        = ia_fake_player.get_formspec_item_crafting(mob_id, x, y)
    local fs_craftpreview, x, y        = ia_fake_player.get_formspec_item_craftpreview(mob_id, x, y) -- TODO double check
    assert(y <= 10.5)
    --assert(y <= 11)
    x                                  = 0
    y                                  = 10.5 -- footer
    --y                                  = 11
    local clicker_inv,     x, y        = ia_fake_player.get_formspec_item_clicker_inventory(mob_id, x, y)
    assert(y == 11.5, 'y='..tostring(y))
    --assert(y == 11, 'y: '..tostring(y))
    local fs_status                    = fs_name       .. fs_bday         .. fs_gender       ..
                                         fs_hp         .. fs_breath       ..
                                         fs_hunger     ..
                                         hline         ..
                                         fs_main_wield ..
                                         fs_armor      ..
                                         fs_crafting   .. fs_craftpreview ..
	                                 clicker_inv
    return fs_status, x, y
end

function ia_fake_player.get_formspec_page_meta(self, mob_id, x, y) -- TODO some way to edit ?
    -- TODO group by mod/prefix ?
    minetest.log('ia_fake_player.get_formspec_page_meta(mob_id='..mob_id..', x='..tostring(x)..', y='..tostring(y)..')')
    assert(x      ~= nil)
    assert(y      ~= nil)
    local all_meta       = self:get_meta():to_table().fields
    local fs_meta_label  = "label["..x..","..y..";Entity Metadata]"
    y                    = (y + .5)
    assert(y == 0.5, 'y='..tostring(y))
    --local fs_meta_value  = "textlist["..x..","..y..";7.8,7;mob_meta_list;"
    local fs_meta_value  = "textlist["..x..","..y..";7.8,11.5;mob_meta_list;"
    y                    = (y + 11)
    assert(y == 11.5, 'y='..tostring(y))
    local fs_meta_header = fs_meta_label .. fs_meta_value
    
    local fs_meta_data   = ""
    for k, v in pairs(all_meta) do
        fs_meta_data     = fs_meta_data .. minetest.formspec_escape(k .. ": " .. tostring(v)) .. ","
    end
    fs_meta_data         = fs_meta_data:sub(1, -2) -- Remove trailing comma
    local fs_meta        = fs_meta_header .. fs_meta_data .. ";0;false]"
    return fs_meta, x, y
end

function ia_fake_player.get_formspec_page_extra_inv(self, mob_id, x, y)
    minetest.log('ia_fake_player.get_formspec_page_extra_inv(mob_id='..tostring(mob_id)..', x='..tostring(x)..', y='..tostring(y)..')')
    assert(mob_id ~= nil)
    assert(x      ~= nil)
    assert(y      ~= nil)
    --local inv              = minetest.get_inventory({type="detached", name=mob_id})
    --local inv              = minetest.get_inventory({type="detached", name=minetest.formspec_escape(mob_id)}) -- TODO testing
    local inv             = self:get_inventory()
    --local fs_extra_label   = "label["..x..","..y..";Extended Inventories]"
    --y                      = (y + .5)
    local fs_extra_value   = ''
    local fs_extra
    --assert(y == 0.5)
    if (not inv) then
        fs_extra_value     = "label["..x..","..y..";No inventory found.]"
        y                  = (y + .5)
	--fs_extra           = fs_extra_label .. fs_extra_value
	y                  = (y + 10.5) -- empty space
    y                      = (y + .5)
	--return fs_extra, x, y
	return fs_extra_value, x, y
    end
    assert(inv)
    --assert(y == 0.5)

    local known            = {main=1, craft=1, craftpreview=1, craftresult=1, armor=1}--, hand=1}
    local count            = 0
    --y                      = 1.2 -- empty space ?
    y                      = 0.2 -- empty space ?
    for listname, _ in pairs(inv:get_lists()) do
    --for _,listname in ipairs(inv:get_lists()) do
        local size         = inv:get_size(listname)
	minetest.log('ia_fake_player.get_formspec_page_extra_inv(mob_id='..mob_id..') listname='..listname..', size='..tostring(size)..', _='..tostring(_))
        if (not known[listname] and size == 0) then
	    minetest.log('ia_fake_player.get_formspec_page_extra_inv(mob_id='..mob_id..') anomoly: '..listname)
        end
        if (not known[listname] and size >  0) then
            -- TODO listname needs escape ?
	    local _size    = math.min(size, 8)
	    minetest.log('ia_fake_player.get_formspec_page_extra_inv(mob_id='..mob_id..') size: '..tostring(size))
            --fs_extra_value = fs_extra_value .. "label[0,"..y..";List: "..listname.." ("..size.." slots)]" ..
            fs_extra_value = fs_extra_value .. "label[0,"..y..";"..listname.." ("..size.." slots)]" ..
                 "list[detached:" .. minetest.formspec_escape(mob_id) .. ";" .. listname .. ";0," .. (y + 0.4) .. ";".._size..",1;]" -- TODO size aware
	    -- Change this line in your loop:
            --fs_extra_value = fs_extra_value .. "label[0,"..y..";List: "..listname.." ("..size.." slots)]" ..
            --     "list[current_player;" .. listname .. ";0," .. (y + 0.4) .. ";".._size..",1;]"
            -- TODO allow player to put/take/move
            y              = y + 1.6
	    count          = count + 1
        end
    end
    if (count == 0) then
	--assert(y == 1.2)
	--y                  = 0.5
	y                  = 0.0
        fs_extra_value     = "label["..x..","..y..";No inventory found.]"
        y                  = (y + .5)
	--fs_extra           = fs_extra_label .. fs_extra_value
	y                  = (y + 10.5) -- empty space
    y                      = (y + .5)
    y                      = (y + .5)
	--return fs_extra, x, y
	return fs_extra_value, x, y
    end
    assert(count ~= 0)
    assert(y <= 11.5)
    y        = 11.5 -- empty space
    --fs_extra = fs_extra_label .. fs_extra_value
    --return fs_extra, x, y
    return fs_extra_value, x, y
end

function ia_fake_player.get_formspec_item_playername(self, mob_id, x, y)
    minetest.log('ia_fake_player.get_formspec_item_playername(mob_id='..tostring(mob_id)..', x='..tostring(x)..', y='..tostring(y)..')')
    assert(mob_id ~= nil)
    assert(x      ~= nil)
    assert(y      ~= nil)
    --assert(self.display_name ~= nil) -- NOTE testing
    --local name     = "label[0,0;Mob: " .. (self.display_name or mob_id)
    local name     = "label["..x..","..y..";Name: " .. minetest.formspec_escape(mob_id) .. "]"
    --x              = (x + 6.0)
    x              = (x + 4.5) -- name > age > gender
    y              = (y +  .5)
    return name, x, y
end

-- TODO nodes dug and other stats
-- TODO searching, sorting, filtering

function ia_fake_player.get_formspec_item_gender_png(self)
    minetest.log('ia_fake_player.get_formspec_item_gender_png()')
    if not minetest.get_modpath('ia_gender') then return '' end
    assert(minetest.get_modpath('ia_gender'))
    local meta   = self:get_meta()
    assert(meta ~= nil)
    local gender = meta:get_string(ia_gender.attr)
    assert(gender ~= nil)
    if (gender == 'male') then
        return gender, 'ia_gender_male.png'
    end
    if (gender == 'female') then
        return gender, 'ia_gender_female.png'
    end
    error('submit feature request to support gender: '..tostring(gender))
end

function ia_fake_player.get_formspec_item_gender(self, x, y)
    minetest.log('ia_fake_player.get_formspec_item_gender(x='..tostring(x)..', y='..tostring(y)..')')
    assert(x      ~= nil)
    assert(y      ~= nil)
    if not minetest.get_modpath('ia_gender') then return '', x, y end
    assert(minetest.get_modpath('ia_gender'))
    local gender, icon    = ia_fake_player.get_formspec_item_gender_png(self)
    local fs_gender_label = "image["..x..","..y..";0.5,0.5;" .. icon .. "]"
    x                     = (x + .6)
    local fs_gender_value = "label["..x..","..y..";" .. gender .. "]"
    local fs_gender       = fs_gender_label .. fs_gender_value
    y                     = (y + .5)
    return fs_gender, x, y
end

function ia_fake_player.get_formspec_item_age(self, mob_id, x, y)
    minetest.log('ia_fake_player.get_formspec_item_age(mob_id='..tostring(mob_id)..', x='..tostring(x)..', y='..tostring(y)..')')
    assert(mob_id ~= nil)
    assert(x      ~= nil)
    assert(y      ~= nil)
    if not minetest.get_modpath('ia_bday') then return '', x, y end
    assert(minetest.get_modpath('ia_bday'))
    local age            = ia_bday.get_day_count_delta(mob_id)
    local fs_age         = "label["..x..","..y..";Age: " .. age .. "]"
    x                     = (x + 1.5) -- name > age > gender
    y                     = (y + .5)
    return fs_age, x, y
end

function ia_fake_player.get_formspec_item_clicker_inventory(mob_id, x, y) -- FIXME can't transfer between player & mob invs
    minetest.log('ia_fake_player.get_formspec_item_clicker_inventory(mob_id='..tostring(mob_id)..', x='..tostring(x)..', y='..tostring(y)..')')
    assert(mob_id ~= nil)
    assert(x      ~= nil)
    assert(y      ~= nil)
    local clicker_label = "label["..x..","..y..";Your Inventory]"
    y                   = (y + .5)
    local clicker_value = "list[current_player;main;"..x..","..y..";8,1;]"
    y                   = (y + .5)
    local _mob_id       = minetest.formspec_escape(mob_id)
    local dst_inv       = "listring[detached:" .. _mob_id .. ";main]"
    local src_inv       = "listring[current_player;main]"

    -- 1. When I click in PLAYER main, go to MOB main
    --local ring_to_mob   = "listring[current_player;main]listring[detached:" .. _mob_id .. ";main]"
    -- 2. When I click in MOB main, go to PLAYER main
    -- (This is often implicit if there are only two rings, but being explicit is safer)
    --local ring_to_player = "listring[detached:" .. _mob_id .. ";main]listring[current_player;main]"

    local clicker_inv   = clicker_label .. clicker_value .. dst_inv .. src_inv
    --local clicker_inv   = clicker_label .. clicker_value .. ring_to_mob .. ring_to_player
    minetest.log('INVENTORY: '..clicker_inv)
    return clicker_inv, x, y
end

function ia_fake_player.get_formspec_page_body(self, mob_id, tab_index)
    minetest.log('ia_fake_player.get_formspec_page_body(mob_id='..tostring(mob_id)..', tab_index='..tostring(tab_index)..')')
    assert(mob_id    ~= nil)
    assert(tab_index ~= nil)
    local            x, y = 0, 0
    local page            = ia_fake_player.formspecs.pages[tab_index]
    assert(page ~= nil)
    --local name            = page.name
    local func            = page.func
    assert(func ~= nil)
    return func(self, mob_id, x, y)
--    if (tab_index == 1) then
--        return ia_fake_player.get_formspec_page_status(self, mob_id, x, y)
--    end
--    if (tab_index == 2) then
--        return ia_fake_player.get_formspec_page_meta(self, x, y)
--    end
--    if (tab_index == 3) then
--	return ia_fake_player.get_formspec_page_extra_inv(self, mob_id, x, y)
--    end
--    error('tab_index: '..tostring(tab_index))
end

ia_fake_player.formspecs.pages   = {
    [1] = { name = "Status",   func = ia_fake_player.get_formspec_page_status },
    [2] = { name = "Metadata", func = ia_fake_player.get_formspec_page_meta   },
    [3] = { name = "Storage",  func = ia_fake_player.get_formspec_page_extra_inv },
    --[4] = { name = "Stats",    func = ia_fake_player.get_formspec_page_stats }, -- New!
    --[5] = { name = "Brain",    func = ia_fake_player.get_formspec_page_debug }, -- New!
    -- TODO one page per inv ?
}

function ia_fake_player.get_formspec_tab_names()
    local names = {}
    for _,page in ipairs(ia_fake_player.formspecs.pages) do
        table.insert(names, page.name)
    end
    return names
end

function ia_fake_player.get_formspec_tab_names_csv()
    local names  = ia_fake_player.get_formspec_tab_names()
    local result = ''
    for _,name in ipairs(names) do
        result   = result .. name .. ','
    end
    result       = result:sub(1, -2)
    return result
end

function ia_fake_player.get_formspec(self, mob_id, tab_index)
    minetest.log('ia_fake_player.get_formspec(mob_id='..tostring(mob_id)..', tab_index='..tostring(tab_index)..')')
    assert(mob_id ~= nil)
    tab_index             = (tonumber(tab_index) or 1)
    assert(tab_index > 0)
    local fs_size         = "size[8,12]"
    local fs_bg           = "background[5,5;1,1;gui_formbg.png;true]"
    local tabs            = ia_fake_player.get_formspec_tab_names_csv()
    --local fs_header       = "tabheader[0,0;mob_tabs;Status,Metadata,Storage;" .. tab_index .. ";true;false]"
    local fs_header       = "tabheader[0,0;mob_tabs;"..tabs..";" .. tab_index .. ";true;false]"
    local fs_body,   x, y = ia_fake_player.get_formspec_page_body(self, mob_id, tab_index)
    local formspec        = fs_size .. fs_bg .. fs_header .. fs_body
    assert(x == 0, 'x='..tostring(x))
    assert(y == 11.5, 'y='..tostring(y))
    --assert(y == 11)
    return formspec, x, y
end

function ia_fake_player.show_formspec(self, clicker, tab_index)
    minetest.log('ia_fake_player.show_formspec(tab_index='..tostring(tab_index)..')')
    assert(self      ~= nil)
    local mob_id          = self.mob_name
    assert(mob_id    ~= nil)
    assert(clicker   ~= nil)
    --assert(tab_index ~= nil)
    local clicker_name    = clicker:get_player_name()
    assert(clicker_name ~= nil)
    local fid             = get_formspec_id(modname, mob_id)
    assert(fid ~= nil)
    local formspec,  x, y = ia_fake_player.get_formspec(self, mob_id, tab_index)
    assert(formspec ~= nil)
    assert(x == 0, 'x='..tostring(x))
    assert(y == 11.5, 'y='..tostring(y))
    --assert(y == 11)
    minetest.show_formspec(clicker_name, fid, formspec)
end

function ia_fake_player.on_player_receive_fields(player, formname, fields)
    assert(formname ~= nil)
    if not is_fake_player_formspec(formname) then return end
    minetest.log('ia_fake_player.on_player_receive_fields(formname='..formname..')')
    local mob_id  = strip_formspec_prefix(formname)
    assert(mob_id   ~= nil)
    assert(mob_id   ~= "")
    local ent_obj = ia_fake_player.get_active_object(mob_id)
    if not ent_obj then
        minetest.log("info", "["..modname.."] Action on mob no longer active: " .. mob_id)
        return
    end
    assert(ent_obj  ~= nil)
    local self    = ent_obj:get_luaentity()
    assert(self     ~= nil)
    if not fields.mob_tabs then return end
    ia_fake_player.show_formspec(self, player, fields.mob_tabs)
end

minetest.register_on_player_receive_fields(ia_fake_player.on_player_receive_fields)

ia_fake_player.on_rightclick = function(self, clicker)
    if not (clicker and clicker:is_player()) then return end
    -- TODO check whether clicked by fake player ?
    ia_fake_player.show_formspec(self, clicker)
end
