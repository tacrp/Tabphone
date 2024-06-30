if SERVER then return end

hook.Add( "PlayerBindPress", "TabPhone", function(ply, bind, pressed)
    local block = nil

    if pressed and bind == "+showscores" and !ply:KeyDown(IN_USE) then
        local wep = ply:GetWeapon("testphone")
        if IsValid(wep) then
            if wep == ply:GetActiveWeapon() then
                RunConsoleCommand("lastinv")
            else
                input.SelectWeapon(wep)
            end

            block = true
        end
    end

    return block
end)