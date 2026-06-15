
-- Register custom privilege for configuring the block
minetest.register_privilege("warper", {
    description = "Allows a player to configure custom warper blocks.",
    give_to_singleplayer = true,
})

---------------------------------------------------------
-- 1. THE NETHER PORTAL BLOCK (FIXED TEXTURE ANIMATION & GLOW)
---------------------------------------------------------
minetest.register_node("portal_warper:portal_block", {
    description = "Nether Portal Block",
    drawtype = "glasslike", -- Works best for translucent, animated sheets
    
    -- Combines your two files and configures them as an active animation loop
    tiles = {
        {
            name = "nether_portal.png^nether_portal_alt.png",
            animation = {
                type = "vertical_frames",
                aspect_w = 16,  -- Base width of a single frame
                aspect_h = 16,  -- Base height of a single frame
                length = 2.0,   -- Time in seconds to cycle through the whole strip
            },
        }
    },
    
    palette = "nether_portals_palette.png",
    paramtype = "light",
    paramtype2 = "color", 
    light_source = 12,    -- Beautiful high-illumination middle glow
    
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
    tiles = {"default_stone.png"}, 
    groups = {cracky = 3},
    
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
    if not minetest.check_player_privs(name, {warper = true}) then
        minetest.log("action", "[portal_warper] Unauthorized formspec submission from " .. name)
        return true
    end
    
    if fields.save and fields.dest_coords then
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
-- 3. JUMP DETECTION (FIXED TARGETING LOGIC)
---------------------------------------------------------
minetest.register_globalstep(function(dtime)
    for _, player in ipairs(minetest.get_connected_players()) do
        local controls = player:get_player_control()
        
        -- Run ONLY when jumping
        if controls.jump then
            local p_pos = player:get_pos()
            
            -- FIXED: Target exactly 1 unit down from player's mid-body 
            -- and round cleanly to integer space using vector API
            local under_pos = vector.round({x = p_pos.x, y = p_pos.y - 0.6, z = p_pos.z})
            local node_under = minetest.get_node_or_nil(under_pos)
            
            if node_under and node_under.name == "portal_warper:warper_block" then
                local meta = minetest.get_meta(under_pos)
                local dest_str = meta:get_string("dest")
                
                if dest_str and dest_str ~= "" then
                    local dx, dy, dz = string.match(dest_str, "([%d%-%.]+)%s*,%s*([%d%-%.]+)%s*,%s*([%d%-%.]+)")
                    if dx and dy and dz then
                        local target = {x = tonumber(dx), y = tonumber(dy), z = tonumber(dz)}
                        
                        -- Set position and instantly safe-load coordinates
                        player:set_pos(target)
                        
                        local name = player:get_player_name()
                        minetest.chat_send_player(name, "Teleported!")
                    end
                end
            end
        end
    end
end)
