if SERVER then return end

CreateClientConVar("tabphone_ringtone", "16", true, true)
CreateClientConVar("tabphone_notiftone", "51", true, true)
CreateClientConVar("tabphone_volume", "5", true, true)
CreateClientConVar("tabphone_24h", "0", true, true)
CreateClientConVar("tabphone_dnd", "0", true, true)
CreateClientConVar("tabphone_silent", "0", true, true)

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