--[[
    Minetest Random Teleport Mod
    Version: 1.0.4
    License: GNU Affero General Public License version 3 (AGPLv3)
]]--

local players = {}

-- Register rtp privilege
core.register_privilege("rtp", {
    description = "Allows use of random teleportation (/rtp)",
    give_to_singleplayer = false,  -- Give in singleplayer
    give_to_admin = false,         -- Give to admins by default
})

-- Register the random teleport command "/rtp".
core.register_chatcommand("rtp", {
    description = "Random Teleport",
    privs = {
        rtp = true,  -- Requires rtp privilege
    },
    func = function(name)
        -- Privilege check (additional check just in case)
        if not core.check_player_privs(name, {rtp = true}) then
            core.chat_send_player(name, "Error: You don't have permission to use random teleportation!")
            return false
        end

        local teleporting = false

        -- Check if the player's name exists in the cooldown timer table.
        for k, v in pairs(players) do
            if v == name then
                teleporting = true
                break
            end
        end

        if teleporting == false then
            table.insert(players, name) -- Insert the player's name into the cooldown timer table.
            local player = core.get_player_by_name(name) -- The player who entered the command.

            if not player then
                -- Remove player from table if not found
                for k, v in pairs(players) do
                    if v == name then
                        table.remove(players, k)
                        break
                    end
                end
                return
            end

            local old_pos = player:get_pos() -- The current position of the player.

            -- Create a random position.
            local x = math.random(-30000, 30000)
            local y = 0
            local z = math.random(-30000, 30000)
            local pos = vector.new(x, y, z)
            local failed = false

            -- Move the player to the random position.
            player:set_pos(pos)

            core.chat_send_player(name, "Teleporting...")

            -- Wait 3 seconds for the world to generate around the player, then move the player to the surface.
            core.after(3, function()
                -- Re-check if player exists
                local player = core.get_player_by_name(name)
                if not player then
                    -- Remove player from table if they logged out
                    for k, v in pairs(players) do
                        if v == name then
                            table.remove(players, k)
                            break
                        end
                    end
                    return
                end

                local player_pos = player:get_pos()
                if player_pos then
                    local target_node = core.get_node(player_pos)
                    if target_node then
                        local node_name = target_node.name -- Get the name of the node at the player's position.
                        if node_name then
                            while node_name ~= "air" do
                                -- Move the player up 1 node on the y axis and update the node_name variable.
                                y = y + 1
                                local pos = vector.new(x, y, z)
                                player:set_pos(pos)
                                node_name = core.get_node(player:get_pos()).name
                                -- If the player is not at the surface after moving up 500 nodes, return the player to their original position.
                                if y > 500 then
                                    player:set_pos(old_pos)
                                    failed = true
                                    break
                                end
                            end
                            if failed == true then
                                core.chat_send_player(name, "Teleportation failed! Returned to " .. core.pos_to_string(player:get_pos()) .. ".")
                            else
                                core.chat_send_player(name, "Teleported to " .. core.pos_to_string(player:get_pos()) .. ".")
                            end
                        end
                    end
                end
            end)

            -- Remove the player's name from the cooldown timer table after 10 seconds.
            core.after(10, function()
                for k, v in pairs(players) do
                    if v == name then
                        table.remove(players, k)
                        break
                    end
                end
            end)

        else
            core.chat_send_player(name, "Please wait a few seconds before using /rtp again.")
        end
    end,
})
