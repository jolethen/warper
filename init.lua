-- Register custom privilege for configuring the block
minetest.register_privilege("warper", {
    description = "Allows a player to configure custom warper blocks.",
    give_to_singleplayer = true,
})

---------------------------------------------------------
-- 1. THE NETHER PORTAL BLOCK
---------------------------------------------------------
minetest.register_node("portal_warper:portal_block", {
    description = "Nether Portal Block",
    drawtype = "glasslike_framed", 
    
    -- Using your provided textures verbatim
    tiles = {
        "nether_portal.png^nether_portal_alt.png"
    },
    special_tiles = {},
    palette = "nether_portals_palette.png",
    color = "#ffffff",
    
    paramtype = "light",
    paramtype2 = "color", 
    light_source = 12,    -- Gives a nice glowing effect
    
    walkable = false,     -- Pass throughable
    pointable = true,
    diggable = true,
    climbable = false,
    buildable_to = true,
    
    groups = {cracky = 3, oddly_breakable_by_hand = 3},
})


---------------------------------------------------------
-- 2. THE CUSTOM STONE WARPER BLOCK
---------------------------------------------------------
minetest.register_node("portal_warper:warper_block", {
    description = "Custom Stone Warper Block",
    tiles = {"default_stone.png"}, -- Uses default game stone texture
    groups = {cracky = 3},
    
    -- Only players with 'warper' privilege can open and configure
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local name = clicker:get_player_name()
        if not minetest.check_player_privs(name, {warper = true}) then
            minetest.chat_send_player(name, "You do not have the 'warper' privilege to configure this.")
            return
        end
        
        local meta = minetest.get_meta(pos)
        local dest_str = meta:get_string("dest") or ""
        
        local formspec = "size[6,4]" ..
            "label[0.5,0.5;Set Warp Destination (X,Y,Z):]" ..
            "field[0.5,1.5;5,1;dest_coords;Coords (e.g. 100,20,-300);" .. dest_str .. "]" ..
            "button_exit[2,3;2,1;save;Save]"
            
        minetest.show_formspec(name, "portal_warper:config_" .. pos.x .. "_" .. pos.y .. "_" .. pos.z, formspec)
    end,
})

-- Handle Formspec Submissions securely
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if not string.find(formname, "portal_warper:config_") then return false end
    
    local name = player:get_player_name()
    
    -- Security Fix: Ensure a hacked client isn't spoofing data entry
    if not minetest.check_player_privs(name, {warper = true}) then
        minetest.log("action", "[portal_warper] Unauthorized formspec submission from " .. name)
        return true
    end
    
    if fields.save and fields.dest_coords then
        -- Extract block position out of formname
        local x, y, z = string.match(formname, "portal_warper:config_([%d%-]+)_([%d%-]+)_([%d%-]+)")
        local pos = {x = tonumber(x), y = tonumber(y), z = tonumber(z)}
        
        if pos then
            local meta = minetest.get_meta(pos)
            meta:set_string("dest", fields.dest_coords)
            minetest.chat_send_player(name, "Warp destination saved successfully!")
        end
        return true
    end
end)


---------------------------------------------------------
-- 3. JUMP DETECTION (ANY PLAYER CAN TELEPORT)
---------------------------------------------------------
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local controls = player:get_player_control()
        
        -- Logic triggers ONLY when a player presses the jump key
        if controls.jump then
            local p_pos = player:get_pos()
            
            -- Locate the block directly underneath the player's feet
            local under_pos = {x = math.floor(p_pos.x + 0.5), y = math.floor(p_pos.y - 0.5), z = math.floor(p_pos.z + 0.5)}
            local node_under = minetest.get_node(under_pos)
            
            -- No privilege requirement here anymore; open to all players
            if node_under.name == "portal_warper:warper_block" then
                local meta = minetest.get_meta(under_pos)
                local dest_str = meta:get_string("dest")
                
                if dest_str and dest_str ~= "" then
                    -- Parse "X,Y,Z" string pattern safely
                    local dx, dy, dz = string.match(dest_str, "([%d%-%.]+)%s*,%s*([%d%-%.]+)%s*,%s*([%d%-%.]+)")
                    if dx and dy and dz then
                        local target = {x = tonumber(dx), y = tonumber(dy), z = tonumber(dz)}
                        player:set_pos(target)
                        
                        local name = player:get_player_name()
                        minetest.chat_send_player(name, "Teleported!")
                    end
                end
            end
        end
    end
end)
