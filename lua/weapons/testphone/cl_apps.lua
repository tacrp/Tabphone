local cameratex = GetRenderTarget("TabPhoneRTCam", 512, 512, false)
local thumbtex = GetRenderTarget("TabPhoneRTCamThumb", 64, 64, false)

local camMat = CreateMaterial("TabPhoneRTCam", "UnlitGeneric", {
    ["$basetexture"] = cameratex:GetName(),
})

local COL_FG = Color(76, 104, 79)
local COL_BG = color_black
local IMAGE_MESSAGE = Material("fesiug/tabphone/message.png")
local BARRIER_FLIPPHONE = 404

local function GetApps()
    local Sortedapps = {}

    for i, v in pairs(TabPhone.Apps) do
        if v.Hidden then continue end
        table.insert(Sortedapps, i)
    end

    if not TabMemory.Selected then
        TabMemory.Selected = 1
    end

    table.sort(Sortedapps, function(a, b)
        a = a or ""
        b = b or ""
        if a == "" or b == "" then return true end
        local tbl_a = TabPhone.Apps[a]
        local tbl_b = TabPhone.Apps[b]
        local order_a = 0
        local order_b = 0
        order_a = tbl_a.SortOrder or order_a
        order_b = tbl_b.SortOrder or order_b
        if order_a == order_b then return (tbl_a.Name or "") < (tbl_b.Name or "") end

        return order_a < order_b
    end)

    return Sortedapps
end

local function AppCount()
    local Sortedapps = {}

    for i, v in pairs(TabPhone.Apps) do
        if v.Hidden then continue end
        table.insert(Sortedapps, i)
    end

    return table.Count(Sortedapps)
end

local mat_profile = Material("fesiug/tabphone/profile.png")
TabPhone.Apps = {}

TabPhone.Apps["mainmenu"] = {
    Name = "Main Menu",
    Hidden = true,
    Icon = Material("fesiug/tabphone/contact.png"),
    SortOrder = 0,
    Func_Enter = function()
        TabMemory.Has_Unread = table.HasValue(TabMemory.UnreadMessages, true)
    end,
    Func_Leave = function() end,
    Func_Primary = function()
        local Sortedapps = GetApps()
        TabMemory.ContactsMode = "contact"
        TabPhone.EnterApp(Sortedapps[TabMemory.Selected])
    end,
    Func_Secondary = function()
        local p = LocalPlayer()
        local w = p:GetPreviousWeapon()

        if w:IsValid() and w:IsWeapon() then
            input.SelectWeapon(w)
        end
    end,
    Func_Scroll = function(level)
        TabPhone.Scroll(level, "Selected", AppCount())
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h)
        TabMemory.RightText = "QUIT"
        local Sortedapps = GetApps()
        -- Scroll math
        local longestscroll = 0

        for i, prev in ipairs(Sortedapps) do
            local sel = i == TabMemory.Selected
            local Sy = ((i - 1) * (48 + 8)) + 48 + 8

            if Sy > (512 - 48 - 40) then
                longestscroll = math.max(-((512 - 48 - 40 - 8) - Sy), longestscroll)
            end

            if sel then
                if (Sy + TabMemory.TotalScroll) > (512 - 48 - 40) then
                    TabMemory.TotalScroll = (512 - 48 - 40 - 8) - Sy
                elseif (Sy + TabMemory.TotalScroll) <= (48 + 8) then
                    TabMemory.TotalScroll = (48 + 8) - Sy
                end
            end
        end

        local TotalScroll = TabMemory.TotalScroll

        -- App logic
        for i, prev in ipairs(Sortedapps) do
            local v = TabPhone.Apps[prev]
            local sel = i == TabMemory.Selected
            surface.SetDrawColor(COL_BG)

            if sel then
                surface.DrawRect(8, TotalScroll + ((i - 1) * (48 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8 - 8, 52)
            else
                surface.DrawOutlinedRect(8, TotalScroll + ((i - 1) * (48 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8 - 8, 52, 4)
            end

            draw.SimpleText(v.Name, "TabPhone32", 8 + 8 + 8 + 8 + 8 + 32, TotalScroll + ((i - 1) * (48 + 8)) + 48 + 8 + 8, sel and COL_FG or COL_BG)
            surface.SetDrawColor(sel and COL_FG or COL_BG)
            local icon = v.Icon

            if v.Func_GetIcon then
                icon = v.Func_GetIcon()
            end

            if icon then
                surface.SetMaterial(icon)
            end
            surface.DrawTexturedRect(8 + 8 + 4 + 4, TotalScroll + ((i - 1) * (48 + 8)) + 48 + 8 + 8 + 2, 32, 32)
        end

        -- Scroll logic
        local fulllength = 512 - 48 - 40 - 8 - 8
        local annoyingmath = (512 - 48 - 40 - 8) / ((512 - 48 - 40 - 8) - longestscroll)
        local length = fulllength / annoyingmath
        local s_per

        if longestscroll <= 0 then
            s_per = 0
        else
            s_per = (-TotalScroll) / longestscroll
        end

        local endpos = ((48 + 8) + (512 - 48 - 40 - 8 - 4) * s_per) - length * s_per
        surface.SetDrawColor(COL_BG)
        surface.DrawRect(BARRIER_FLIPPHONE - 12, endpos, 6, length)
    end,
}

cachedplayers = cachedplayers or {}
local pfpdatafile = "arcrp_pfp.dat"

local function savepfps()
    local json = util.TableToJSON(TabMemory.ProfilePictures)
    file.Write(pfpdatafile, json)
end

local function loadpfps()
    if not file.Exists(pfpdatafile, "DATA") then return end
    local content = file.Read(pfpdatafile, "DATA")
    TabMemory.ProfilePictures = util.JSONToTable(content)
end

local function GetProfilePic(id)
    if TabMemory.ProfilePicturesMats[id] then return TabMemory.ProfilePicturesMats[id] end
    local pfp = TabMemory.ProfilePictures[id]

    if pfp then
        if file.Exists("arcrp_photos/" .. pfp, "DATA") then
            TabMemory.ProfilePicturesMats[id] = Material("data/arcrp_photos/" .. pfp)
        else
            return nil
        end
    end

    return TabMemory.ProfilePicturesMats[id]
end

local function GetMessageHistory(id)
    return TabMemory.MessageHistory[id] or {}
end

TabPhone.NPCContacts = {
    ["assassins"] = {
        name = "???",
        hide_if_nomsg = true
    }
}

TabPhone.Apps["contacts"] = {
    Name = "Contacts",
    Icon = Material("fesiug/tabphone/contact.png"),
    SortOrder = -1009,
    Func_Enter = function()
        loadpfps()
    end,
    Func_Leave = function()
        TabMemory.ContactsMode = "contact"
    end,
    Func_Primary = function()
        local ply = cachedplayers[TabMemory.SelectedPlayer]
        if TabMemory.ContactsMode == "profile" then
            local image = cachedgalleryimages[TabMemory.GallerySelected]
            if not image then return end
            local index = ply.ID
            TabMemory.ProfilePictures[index] = image.filename
            TabMemory.ProfilePicturesMats[index] = nil
            TabMemory.ContactsMode = "contact"
            savepfps()
            TabPhone.EnterApp("gallery")
        elseif TabMemory.ContactsMode == "contact" then
            if not IsValid(ply.Entity) then
                TabMemory.CallingPlayer = nil
                TabMemory.CallingContact = ply
                TabPhone.EnterApp("active_call")
                LocalPlayer():EmitSound("fesiug/tabphone/ringtone.ogg", 100, 100, TabPhone.GetVolume(), CHAN_STATIC)
            else
                TabMemory.CallingPlayer = ply.Entity
                net.Start("Tabphone_Call_Send")
                net.WriteString(ply.Entity:SteamID64())
                net.SendToServer()
                TabPhone.EnterApp("active_call")
                LocalPlayer():EmitSound("fesiug/tabphone/ringtone.ogg", 100, 100, TabPhone.GetVolume(), CHAN_STATIC)
            end
        elseif TabMemory.ContactsMode == "message" then
            local id = ply.ID

            TabMemory.UnreadMessages[id] = false

            TabPhone.EnterApp("messages_viewer")
        end
    end,
    Func_Secondary = function()
        if TabMemory.ContactsMode == "profile" then
            TabMemory.ContactsMode = "contact"
            TabPhone.EnterApp("gallery_options")
        else
            TabPhone.EnterApp("mainmenu")
        end
    end,
    Func_Scroll = function(level)
        TabPhone.Scroll(level, "SelectedPlayer", #cachedplayers)
    end,
    Func_Reload = function()
        if TabMemory.ContactsMode == "message" then
            for i, _ in pairs(TabMemory.UnreadMessages) do
                TabMemory.UnreadMessages[i] = false
            end
        end
    end,
    Func_Draw = function(w, h)
        TabMemory.LeftText = ""
        cachedplayers = {}

        for i, v in player.Iterator() do
            local pd = {
                Entity = v,
                Name = v:Nick(),
                ID = "SteamID:" .. tostring(v:SteamID64()),
                Number = v:SteamID64()
            }
            pd.Icon = GetProfilePic(pd.ID)

            table.insert(cachedplayers, pd)
        end

        for i, v in pairs(TabPhone.NPCContacts) do
            local pd = {
                Name = v.name,
                ID = i,
                Number = v.number or "UNKNOWN"
            }
            pd.Icon = GetProfilePic(pd.ID)

            table.insert(cachedplayers, pd)
        end

        -- Scroll math
        local longestscroll = 0

        for i, prev in ipairs(cachedplayers) do
            local sel = i == TabMemory.SelectedPlayer
            local Sy = ((i - 1) * (96 + 8)) + 8
            local Sh = 96
            local Ty = Sy + Sh

            if Ty > (512 - 48 - 40) then
                longestscroll = math.max(-((512 - 48 - 40 - 8) - Ty), longestscroll)
            end

            if sel then
                if (Ty + TabMemory.TotalScrollContacts) > (512 - 48 - 40) then
                    TabMemory.TotalScrollContacts = (512 - 48 - 40 - 8) - Ty
                elseif (Sy + TabMemory.TotalScrollContacts) <= (48 + 8) then
                    TabMemory.TotalScrollContacts = math.min(0, (48 + 8) - Sy)
                end
            end
        end

        local TotalScroll = TabMemory.TotalScrollContacts

        -- App logic
        for i, v in ipairs(cachedplayers) do
            local sel = i == TabMemory.SelectedPlayer or (TabMemory.ContactsMode == "message" and TabMemory.UnreadMessages[v.ID] and (CurTime() % 1 > 0.5))
            surface.SetDrawColor(COL_BG)

            if sel then
                surface.DrawRect(8, TotalScroll + ((i - 1) * (96 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8 - 8, 96)

                if v.Entity == LocalPlayer() then
                    TabMemory.LeftText = ""
                else
                    if TabMemory.ContactsMode == "profile" then
                        TabMemory.LeftText = "SET"
                    elseif TabMemory.ContactsMode == "contact" then
                        TabMemory.LeftText = "CALL"
                    elseif TabMemory.ContactsMode == "message" then
                        TabMemory.LeftText = "MESSAGE"
                    end
                end
            else
                surface.DrawOutlinedRect(8, TotalScroll + ((i - 1) * (96 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8 - 8, 96, 4)
            end

            draw.SimpleText(v.Name, "TabPhone24", 8 + 96 + 8, TotalScroll + ((i - 1) * (96 + 8)) + 48 + 8 + 8, sel and COL_FG or COL_BG)
            local textr = v.Number

            if TabMemory.ContactsMode == "message" then
                local history = GetMessageHistory(v.ID)
                textr = "Start a conversation!"

                local id = v.ID

                if history[#history] then
                    textr = history[#history].msg
                end

                if TabMemory.UnreadMessages[id] and (CurTime()) % 1 > 0.5 then
                    textr = "NEW MESSAGE!"
                end

                local maxlen = 21

                if string.len(textr) > maxlen then
                    textr = string.sub(textr, 1, maxlen - 2) .. ".."
                end
            end

            draw.SimpleText(textr, "TabPhone16", BARRIER_FLIPPHONE - 16 - 8, TotalScroll + ((i - 1) * (96 + 8)) + 48 + 8 + 8 + (96 - 8 - 8 - 16), sel and COL_FG or COL_BG, TEXT_ALIGN_RIGHT)

            if v.Icon then
                surface.SetDrawColor(255, 255, 255)
                surface.SetMaterial(v.Icon)
                surface.DrawTexturedRect(8, TotalScroll + ((i - 1) * (96 + 8)) + 48 + 8, 96, 96)
                surface.SetDrawColor(COL_BG)
                surface.DrawOutlinedRect(8, TotalScroll + ((i - 1) * (96 + 8)) + 48 + 8, 96, 96, 4)
            end
        end

        -- Scroll logic
        local fulllength = 512 - 48 - 40 - 8 - 8
        local annoyingmath = (512 - 48 - 40 - 8) / ((512 - 48 - 40 - 8) - longestscroll)
        local length = fulllength / annoyingmath
        local s_per

        if longestscroll <= 0 then
            s_per = 0
        else
            s_per = (-TotalScroll) / longestscroll
        end

        local endpos = ((48 + 8) + (512 - 48 - 40 - 8 - 4) * s_per) - length * s_per
        surface.SetDrawColor(COL_BG)
        surface.DrawRect(BARRIER_FLIPPHONE - 12, endpos, 6, length)
    end,
}

local unread_icon = Material("fesiug/tabphone/alert.png")
local message_icon = Material("fesiug/tabphone/message.png")

TabPhone.Apps["messages"] = {
    Name = "Messages",
    Func_GetIcon = function()
        if TabMemory.Has_Unread and (CurTime()) % 1 > 0.5 then
            return unread_icon
        else
            return message_icon
        end
    end,
    Icon = message_icon,
    SortOrder = -1008,
    Func_Enter = function()
        TabMemory.ContactsMode = "message"
        TabPhone.EnterApp("contacts")
    end,
}

temp_message = temp_message or ""
TabPhone_MessageDebounceTime = 0

TabPhone.Apps["messages_sender"] = {
    Hidden = true,
    Func_Enter = function()
        temp_message = ""

        if SuperTextFrame then
            SuperTextFrame:Remove()
        end

        SuperTextFrame = vgui.Create("DFrame")
        SuperTextFrame:SetSize(0, 0)
        SuperTextFrame:Center()
        SuperTextFrame:MakePopup()
		SuperTextFrame:SetMouseInputEnabled(false)

        function SuperTextFrame:Paint()
            return
        end

        SuperTextEntry = vgui.Create("DTextEntry", SuperTextFrame)
        SuperTextEntry:Dock(TOP)
        SuperTextEntry:RequestFocus()
        SuperTextEntry:SetUpdateOnType(true)
		SuperTextEntry:SetEnterAllowed(false)

        function SuperTextEntry:OnLoseFocus()
            if SuperTextFrame then
                SuperTextFrame:Remove()
            end
        end

        function SuperTextEntry:OnValueChange(value)
			value = value:gsub("%s+", " ")
			if string.len(value) > 200 then
                value = value:Left(200)
                self:SetValue(value)
            end

            temp_message = value
        end

        function SuperTextEntry:Paint()
            return
        end
    end,
    Func_Primary = function()
        if TabPhone_MessageDebounceTime > CurTime() then return end
        local ply = cachedplayers[TabMemory.SelectedPlayer]

        if IsValid(ply.Entity) then
            TabPhone.SendMessage(ply.Entity, temp_message)
        else
            TabPhone.SendMessage(ply.ID, temp_message)
        end
        TabPhone.EnterApp("messages_viewer")
    end,
	Func_Leave = function()
		SuperTextFrame:Remove()
	end,
	Func_Holster = function()
        TabPhone.EnterApp("messages_viewer")
	end,
    Func_Secondary = function()
        TabPhone.EnterApp("messages_viewer")
    end,
    Func_Draw = function(w, h)
        TabMemory.LeftText = "SEND"
        TabMemory.RightText = "DISCARD"
        surface.SetDrawColor(COL_BG)
        surface.DrawRect(0, 48, 512, 48 + 4 + 4)
        local ply = cachedplayers[TabMemory.SelectedPlayer]

        if !ply then
            TabPhone.EnterApp("messages")
			return
        end

        local pfp = GetProfilePic(ply.ID)

        if pfp then
            surface.SetMaterial(pfp)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawTexturedRect(4, 48 + 4, 48, 48)
        end

        draw.SimpleText("To: " .. ply.Name, "TabPhone24", 8 + 48 + 8 + 4, 8 + 48 + 4, COL_FG)
        local message_lines = TabPhone.SIL(temp_message, 404-16-16, "TabPhone24")
        surface.SetFont("TabPhone24")
        surface.SetDrawColor(COL_BG)
        local v_y = 120
        local v_x = 16

        for _, ts in ipairs(message_lines) do
			--if (_ == 1 and ts == "") then v_y = v_y + 32 break end
            if v_y > 0 and v_y < h then
                local tsn = surface.GetTextSize(ts)
                draw.SimpleText(ts, "TabPhone24", 16, v_y, COL_BG)
                v_x = 16+tsn
            end

            v_y = v_y + 32
        end

        if (CurTime() * 2) % 1 > 0.5 and string.len(temp_message) < 200 then
            surface.SetDrawColor(COL_BG)
            surface.DrawRect(v_x, v_y - 32, 24, 32)
            -- draw.SimpleText("|", "TabPhone24", v_x, v_y - 32, COL_BG, TEXT_ALIGN_LEFT)
        end
    end
}

local ChatSizes = {16, 24, 32}

TabPhone.Apps["messages_viewer"] = {
    Hidden = true,
    Func_Enter = function()
        TabMemory.MessageScroll = 0
    end,
    Func_Scroll = function(level)
		local TEXTTALL = ChatSizes[GetConVar("tabphone_chatsize"):GetInt()]

        local min = 0
        local max = -320 - 40
        local ply = cachedplayers[TabMemory.SelectedPlayer]

        for _, MsgData in ipairs(GetMessageHistory(ply.ID)) do
			local msgsplit = TabPhone.SIL( MsgData.msg, 404-16-16, "TabPhone"..TEXTTALL )
            max = max + #msgsplit * (TEXTTALL+8)
            max = max + 8
        end

        max = math.max(max, 0)
        TabMemory.MessageScroll = TabMemory.MessageScroll - (level * (TEXTTALL+8))
        TabMemory.MessageScroll = math.Clamp(TabMemory.MessageScroll, min, max)
    end,
    Func_Primary = function()
        TabPhone.EnterApp("messages_sender")
    end,
    Func_Secondary = function()
        TabPhone.EnterApp("messages")
    end,
    Func_Reload = function()
    end,
    Func_Draw = function(w, h)
		local TEXTTALL = ChatSizes[GetConVar("tabphone_chatsize"):GetInt()]

        TabMemory.LeftText = "REPLY"
        surface.SetDrawColor(COL_BG)
        surface.DrawRect(0, 48, 512, 48 + 4 + 4)
        local ply = cachedplayers[TabMemory.SelectedPlayer]

        if !ply then
            TabPhone.EnterApp("messages")
			return
        end

        local pfp = GetProfilePic(ply.ID)

        if pfp then
            surface.SetMaterial(pfp)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawTexturedRect(4, 48 + 4, 48, 48)
        end

        draw.SimpleText(ply.Name, "TabPhone24", 8 + 48 + 8 + 4, 8 + 48 + 4, COL_FG)
        render.SetScissorRect(0, 104, w, h, true)
        local v_y = 512 - 40 - 8 - (TEXTTALL + 4) - 4 + TabMemory.MessageScroll
		v_y = v_y + (TEXTTALL+8)
        local history = GetMessageHistory(ply.ID)

        for i = 1, #history do
            local MsgData = history[#history - i + 1]
			local msgsplit = TabPhone.SIL( MsgData.msg, 404-16-16, "TabPhone"..TEXTTALL )
            surface.SetFont("TabPhone"..TEXTTALL)
            surface.SetDrawColor(COL_BG)
            v_y = v_y - ((TEXTTALL+8) * #msgsplit)

			local backup = v_y
            for _, ts in ipairs(msgsplit) do
                if backup > 0 and backup < h then
                    if !MsgData.yours then continue end
					surface.SetFont("TabPhone"..TEXTTALL)
					local tsn = surface.GetTextSize(ts)

					surface.SetDrawColor(COL_BG)
					surface.DrawRect( w - tsn - 8 - 8 - 8 - (2), backup - (2), tsn + 8 + 8 + (4), TEXTTALL + 4 + 4 + (4) )
				end
                backup = backup + (TEXTTALL+8)
			end

            for _, ts in ipairs(msgsplit) do
                if v_y > 0 and v_y < h then
					surface.SetFont("TabPhone"..TEXTTALL)
					local tsn = surface.GetTextSize(ts)

                    if MsgData.yours then
						surface.SetDrawColor(COL_FG)
						surface.DrawRect( w - tsn - 8 - 8 - 8, v_y, tsn + 8 + 8, TEXTTALL + 4 + 4 )
                        draw.SimpleText(ts, "TabPhone"..TEXTTALL, w - 8 - 8, v_y+2, COL_BG, TEXT_ALIGN_RIGHT)
                    else
                        surface.DrawRect( 8, v_y, tsn + 16, TEXTTALL + 4 + 4 )
                        draw.SimpleText(ts, "TabPhone"..TEXTTALL, 8 + 8, v_y+2, COL_FG, TEXT_ALIGN_LEFT)
                    end
                end

				v_y = v_y + (TEXTTALL+8)
            end

            v_y = v_y - ((TEXTTALL+8) * #msgsplit)
            v_y = v_y - 8
        end

        render.SetScissorRect(0, 56, w, h, false)
    end,
}

TabPhone.Apps["jobs"] = {
    Name = "Jobs",
    Icon = Material("fesiug/tabphone/job.png"),
    SortOrder = -1007,
    Func_Enter = function() end,
    Func_Primary = function()
        TabPhone.PlayNotiftone()
    end,
    Func_Secondary = function()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h)
        for i = 0, 10 do
            draw.SimpleText("WORK IN PROGRESS", "TabPhone32", BARRIER_FLIPPHONE / 2, 64 + (i * (32 + 4)), COL_BG, TEXT_ALIGN_CENTER)
        end
    end,
}

TabPhone.Apps["calendar"] = {
    Name = "Calendar",
    Icon = Material("fesiug/tabphone/calendar.png"),
    SortOrder = -1006,
    Hidden = true,
    Func_Enter = function() end,
    Func_Primary = function() end,
    Func_Secondary = function()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h) end,
}

TabPhone.Apps["dialer"] = {
    Name = "Dialer",
    Icon = Material("fesiug/tabphone/phone.png"),
    SortOrder = -1006,
    Func_Enter = function()
        TabMemory.YouDial = ""
    end,
    Func_Primary = function()
        net.Start("Tabphone_Call_Send")
        net.WriteString(TabMemory.YouDial)
        net.SendToServer()
        TabPhone.EnterApp("active_call")
        LocalPlayer():EmitSound("fesiug/tabphone/ringtone.ogg", 100, 100, TabPhone.GetVolume(), CHAN_STATIC)
    end,
    Func_Secondary = function()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h)
        TabMemory.LeftText = "CALL"
        local YOUDIAL = TabMemory.YouDial or ""
        draw.SimpleText(YOUDIAL, "TabPhone48", BARRIER_FLIPPHONE - 4, 48 + 48, COL_BG, TEXT_ALIGN_RIGHT)
        draw.SimpleText("USE NUMROW OR NUMPAD", "TabPhone24", BARRIER_FLIPPHONE / 2, 48 + 12, COL_BG, TEXT_ALIGN_CENTER)

        if (CurTime() * 2) % 1 > 0.5 then
            surface.SetFont("TabPhone48")
            local tsn = surface.GetTextSize("8")
            surface.SetDrawColor(COL_BG)
            surface.DrawRect(BARRIER_FLIPPHONE - 4 - (tsn + 6), 48 + 48, tsn + 6, 48 + 6)
            draw.SimpleText(YOUDIAL:Right(1), "TabPhone48", BARRIER_FLIPPHONE - 4, 48 + 48, COL_FG, TEXT_ALIGN_RIGHT)
        end
    end,
}

local itemstobuy = {
	{
		["Name"] = "Washing Machine",
	},
	{
		["Name"] = "Blood Cleaner",
	},
	{
		["Name"] = "Automatic Weapons",
	},
	{
		["Name"] = "Body Bags",
	},
}

TabPhone.Apps["shopping"] = {
    Name = "Shopping",
    Icon = Material("fesiug/tabphone/shopper.png"),
    SortOrder = -1006,
    Func_Enter = function() end,
    Func_Primary = function() end,
    Func_Secondary = function()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function() end,
    Func_Scroll = function(level)
        TabPhone.Scroll(level, "Shopping_Selected", #itemstobuy)
	end,
    Func_Draw = function(w, h)
		local sw, sh = 16, 48 + 16
		for i, v in ipairs( itemstobuy ) do
			local sel = (TabMemory.Shopping_Selected or 1) == i
			draw.SimpleText(v.Name, "TabPhone24", sw, sh, COL_BG)
			if sel then
				draw.SimpleText(v.Name, "TabPhone24", sw+2, sh, COL_BG)

				surface.SetDrawColor( COL_BG )
				surface.DrawRect( sw-4, sh+24+1, surface.GetTextSize( v.Name ) + 8+2, 3 )
			end
			sh = sh + 4 + 24
		end
	end,
}

TabPhone.Apps["call"] = {
    Name = "Receiving Call",
    Icon = Material("fesiug/tabphone/phone.png"),
    SortOrder = 0,
    Hidden = true,
    Func_Enter = function() end,
    Func_Holster = function()
        TabPhone.EndRingtone()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Primary = function()
        TabPhone.EndRingtone()
        TabPhone.EnterApp("active_call")
        net.Start("Tabphone_Call_Accept")
        net.SendToServer()
    end,
    Func_Secondary = function()
        TabPhone.EndRingtone()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h)
        TabMemory.LeftText = "ANSWER"
        TabMemory.RightText = "DECLINE"
        surface.SetDrawColor(COL_FG)
        surface.DrawRect(0, 0, 512, 512)

        if TabMemory.TempPFP then
            surface.SetMaterial(Material("data/arcrp_photos/" .. TabMemory.TempPFP))
            surface.SetDrawColor(255, 255, 255)
            local super = 512 - 48 - 40
            surface.DrawTexturedRect(w / 2 - super / 2, (((512 + 48) / 2) - (40 / 2)) - (super / 2), super, super)
        end

        local jiggy = (math.Round(math.sin(UnPredictedCurTime() * 2 * math.pi) * 2, 0) / 2) * 16
        local jiggy2 = math.Round(math.sin(UnPredictedCurTime() * 28 * math.pi), 0) * 4
        surface.SetFont("TabPhone32")
        local tsn = surface.GetTextSize(" INCOMING CALL ")
        surface.SetDrawColor(COL_FG)
        surface.DrawRect((BARRIER_FLIPPHONE / 2) + jiggy - tsn / 2, 64 + 16 + jiggy2, tsn, 32 + 4 + 4)
        local tsn = surface.GetTextSize(" Bank of Siple ")
        surface.DrawRect((BARRIER_FLIPPHONE / 2) - tsn / 2, 64 + 72, tsn, 32 + 4 + 4)
        draw.SimpleText("INCOMING CALL", "TabPhone32", (BARRIER_FLIPPHONE / 2) + jiggy, 64 + 16 + jiggy2, COL_BG, TEXT_ALIGN_CENTER)
        local nick = "[???????]"

        if TabMemory.CallingPlayer and TabMemory.CallingPlayer:IsValid() then
            nick = TabMemory.CallingPlayer:Nick()
        end

        draw.SimpleText(nick, "TabPhone32", BARRIER_FLIPPHONE / 2, 64 + 72, COL_BG, TEXT_ALIGN_CENTER)
    end,
}

TabPhone.Apps["active_call"] = {
    Name = "Active Call",
    Icon = Material("fesiug/tabphone/phone.png"),
    SortOrder = 0,
    Hidden = true,
    Func_Enter = function()
        TabMemory.CallStartTime = UnPredictedCurTime()
        TabMemory.CallEndTime = math.huge
    end,
    Func_Primary = function() end,
    Func_Secondary = function()
        LocalPlayer():StopSound(TabPhone.GetRingtonePath())
        net.Start("Tabphone_Call_HangUp")
        net.SendToServer()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h)
        if (TabMemory.CallEndTime or math.huge) + 1 <= CurTime() then
            TabPhone.EnterApp("mainmenu")

            return
        end

        TabMemory.LeftText = ""
        TabMemory.RightText = "HANG UP"
        surface.SetDrawColor(COL_FG)
        surface.DrawRect(0, 0, 512, 512)

        local pfp

        if TabMemory.CallingPlayer then
            pfp = GetProfilePic("SteamID:" .. TabMemory.CallingPlayer:SteamID64())
        elseif TabMemory.CallingContact then
            pfp = TabMemory.CallingContact.Icon
        end

        if pfp then
            surface.SetMaterial(pfp)
            surface.SetDrawColor(255, 255, 255)
            local super = 512 - 48 - 40
            surface.DrawTexturedRect(w / 2 - super / 2, (((512 + 48) / 2) - (40 / 2)) - (super / 2), super, super)
        end

        local calllength = "" --

        if TabMemory.CallStatus == "incall" then
            local mrew = string.FormattedTime(UnPredictedCurTime() - TabMemory.CallStartTime)
            calllength = string.format("%02i:%02i:%02i", mrew.h, mrew.m, mrew.s)
        elseif TabMemory.CallStatus == "calling" then
            calllength = "Calling..."
        elseif TabMemory.CallStatus == "busy" then
            calllength = "BUSY"
        elseif TabMemory.CallStatus == "callended" then
            calllength = "CALL ENDED"
        else
            calllength = "...??"
        end

        surface.SetFont("TabPhone32")
        local tsn = surface.GetTextSize(" " .. calllength .. " ")
        surface.SetDrawColor(COL_FG)
        surface.DrawRect((BARRIER_FLIPPHONE / 2) - tsn / 2, 64 + 72, tsn, 32 + 4 + 4)
        draw.SimpleText(calllength, "TabPhone32", BARRIER_FLIPPHONE / 2, 64 + 72, COL_BG, TEXT_ALIGN_CENTER)
        surface.SetFont("TabPhone32")
        surface.SetDrawColor(COL_FG)
        local nick = "[???????]"

        if TabMemory.CallingPlayer and TabMemory.CallingPlayer:IsValid() then
            nick = TabMemory.CallingPlayer:Nick()
        elseif TabMemory.CallingContact then
            pfp = TabMemory.CallingContact.Name
        end

        local tsn = surface.GetTextSize(" " .. nick .. " ")
        surface.DrawRect((BARRIER_FLIPPHONE / 2) - tsn / 2, 64 + 16, tsn, 32 + 4 + 4)
        draw.SimpleText(nick, "TabPhone32", BARRIER_FLIPPHONE / 2, 64 + 16, COL_BG, TEXT_ALIGN_CENTER)
    end,
}

--local voicesize = Entity(2):VoiceVolume()*100*10
--surface.SetDrawColor(COL_BG)
--surface.DrawRect((BARRIER_FLIPPHONE / 2) - voicesize/2, 256 - voicesize/2, voicesize, voicesize)
local settings_options = {
    {
        label = "Volume",
        min = 0,
        max = 10,
        convar = GetConVar("tabphone_volume"),
        icon = Material("fesiug/tabphone/volume.png"),
        type = "int"
    },
    {
        label = "Ringtone",
        icon = Material("fesiug/tabphone/phone.png"),
        min = 1,
        max = function() return #TabPhone.Ringtones end,
        convar = GetConVar("tabphone_ringtone"),
        func_change = function(val)
            if TabMemory.RingToneExample then
                TabMemory.RingToneExample:Stop()
            end

            local sound = TabPhone.RingtonePath .. TabPhone.Ringtones[val]
            TabMemory.RingToneExample = CreateSound(LocalPlayer(), sound)
            TabMemory.RingToneExample:PlayEx(TabPhone.GetVolume(), 100)
        end,
        type = "int",
    },
    {
        label = "Notiftone",
        icon = Material("fesiug/tabphone/bell.png"),
        min = 1,
        max = function() return #TabPhone.Notiftones end,
        convar = GetConVar("tabphone_notiftone"),
        func_change = function(val)
            if TabMemory.RingToneExample then
                TabMemory.RingToneExample:Stop()
            end

            local sound = TabPhone.RingtonePath .. TabPhone.Notiftones[val]
            TabMemory.RingToneExample = CreateSound(LocalPlayer(), sound)
            TabMemory.RingToneExample:PlayEx(TabPhone.GetVolume(), 100)
        end,
        type = "int",
    },
    {
        label = "Phone Dist.",
        icon = Material("fesiug/tabphone/settings.png"),
        min = 1,
        max = 4,
        convar = GetConVar("tabphone_vmpos"),
        type = "int",
    },
    {
        label = "Chat Size",
        icon = Material("fesiug/tabphone/message.png"),
        min = 1,
        max = 3,
        convar = GetConVar("tabphone_chatsize"),
        type = "int",
    },
    {
        label = "24h Time",
        icon = Material("fesiug/tabphone/clock.png"),
        type = "bool",
        convar = GetConVar("tabphone_24h")
    },
    {
        label = "DontDisturb",
        type = "bool",
        convar = GetConVar("tabphone_dnd"),
        icon = Material("fesiug/tabphone/sleep.png"),
    },
    {
        label = "Back",
        type = "func",
        func_change = function()
            TabPhone.EnterApp("mainmenu")

            if TabMemory.RingToneExample then
                TabMemory.RingToneExample:Stop()
            end
        end,
        icon = Material("fesiug/tabphone/back.png"),
    }
}

local function changeOption(level)
    local opt = settings_options[TabMemory.SelectedSetting]
    if not opt then return end

    if opt.type == "int" then
        local val = opt.convar:GetInt()
        local min = opt.min
        local max = opt.max

        if isfunction(min) then
            min = min()
        end

        if isfunction(max) then
            max = max()
        end

        val = val + level

        if val > max then
            val = min
        elseif val < min then
            val = max
        end

        opt.convar:SetInt(val)

        if isfunction(opt.func_change) then
            opt.func_change(val)
        end
    elseif opt.type == "bool" then
        local var = opt.convar:GetBool()

        if opt.convar then
            opt.convar:SetBool(not var)
        end
    else
        if isfunction(opt.func_change) then
            opt.func_change()
        end
    end
end

local radio_empty = Material("fesiug/tabphone/radio_empty.png")
local radio_filled = Material("fesiug/tabphone/radio_filled.png")

TabPhone.Apps["settings"] = {
    Name = "Settings",
    Icon = Material("fesiug/tabphone/settings.png"),
    SortOrder = -1005,
    Func_Enter = function() end,
    Func_Primary = function()
        changeOption(1)
    end,
    Func_Scroll = function(level)
        TabPhone.Scroll(level, "SelectedSetting", #settings_options)
    end,
    Func_Secondary = function()
        -- TabPhone.EnterApp("mainmenu")
        changeOption(-1)
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h)
        for i, opt in ipairs(settings_options) do
            local sel = i == TabMemory.SelectedSetting
            surface.SetDrawColor(COL_BG)

            if sel then
                surface.DrawRect(8, ((i - 1) * (48 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8, 52)

                if opt.type == "int" then
                    TabMemory.LeftText = "NEXT"
                    TabMemory.RightText = "PREVIOUS"
                end
            else
                surface.DrawOutlinedRect(8, ((i - 1) * (48 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8, 52, 4)
            end

            draw.SimpleText(opt.label, "TabPhone32", 8 + 8 + 8 + 8 + 8 + 32, ((i - 1) * (48 + 8)) + 48 + 8 + 8, sel and COL_FG or COL_BG)

            if opt.icon then
                surface.SetDrawColor(sel and COL_FG or COL_BG)
                surface.SetMaterial(opt.icon)
                surface.DrawTexturedRect(8 + 8 + 4 + 4, ((i - 1) * (48 + 8)) + 48 + 8 + 8 + 2, 32, 32)
            end

            if opt.type == "int" then
                local val = opt.convar:GetInt()
                draw.SimpleText(tostring(val), "TabPhone32", w - 8 - 8 - 4 - 4, ((i - 1) * (48 + 8)) + 48 + 8 + 8, sel and COL_FG or COL_BG, TEXT_ALIGN_RIGHT)
            elseif opt.type == "bool" then
                local val = opt.convar:GetBool()

                if val then
                    surface.SetMaterial(radio_filled)
                else
                    surface.SetMaterial(radio_empty)
                end

                surface.SetDrawColor(sel and COL_FG or COL_BG)
                surface.DrawTexturedRect(w - 32 - 24, ((i - 1) * (48 + 8)) + 64 + 2, 32, 32)
            end
        end
    end,
}

local camera_nextdraw = 0
local camera_framerate = 15
local pattern = Material("pp/texturize/plain.png")
local flashmat = Material("fesiug/tabphone/flash.png")
local noflashmat = Material("fesiug/tabphone/noflash.png")

TabPhone.Apps["camera"] = {
    Name = "Camera",
    Icon = Material("fesiug/tabphone/camera.png"),
    SortOrder = -1020,
    Func_Enter = function()
        TabMemory.CameraZoom = 1
    end,
    Func_Primary = function()
        if TabMemory.NextPhotoTime > UnPredictedCurTime() then return end
        local vangle = LocalPlayer():EyeAngles()

        if TabMemory.Flash then
            local dlight = DynamicLight(LocalPlayer():EntIndex())

            if dlight then
                dlight.pos = LocalPlayer():EyePos()
                dlight.r = 255
                dlight.g = 255
                dlight.b = 255
                dlight.brightness = 1
                dlight.decay = 0
                dlight.size = 2048
                dlight.dietime = UnPredictedCurTime() + 0.1
            end
        end

        timer.Simple(0, function()
            render.PushRenderTarget(cameratex, 0, 0, 512, 512)
            surface.PlaySound("npc/scanner/scanner_photo1.wav", 100, 100, TabPhone.GetVolume())

            local rt = {
                x = 0,
                y = 0,
                w = 512,
                h = 512,
                aspect = 1,
                angles = vangle,
                origin = EyePos(),
                drawviewmodel = false,
                fov = 50 / TabMemory.CameraZoom,
                znear = 8
            }

            render.RenderView(rt)
            DrawTexturize(1, pattern)

            DrawColorModify({
                ["$pp_colour_addr"] = (COL_FG.r - 255) / 255,
                ["$pp_colour_addg"] = (COL_FG.g - 255) / 255,
                ["$pp_colour_addb"] = (COL_FG.b - 255) / 255,
                ["$pp_colour_brightness"] = 0.6,
                ["$pp_colour_contrast"] = 1.25,
                ["$pp_colour_colour"] = 1,
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })

            local content = render.Capture({
                format = "png",
                x = 0,
                y = 0,
                w = 512,
                h = 512,
                alpha = false,
            })

            file.CreateDir("arcrp_photos")
            file.CreateDir("arcrp_photos/thumbs")
            file.Write("arcrp_photos/" .. os.time() .. ".png", content)
            render.PopRenderTarget()

            local rt_thumb = {
                x = 0,
                y = 0,
                w = 64,
                h = 64,
                aspect = 1,
                angles = vangle,
                origin = EyePos(),
                drawviewmodel = false,
                fov = 50 / TabMemory.CameraZoom,
                znear = 8
            }

            render.PushRenderTarget(thumbtex, 0, 0, 64, 64)
            render.RenderView(rt_thumb)
            DrawTexturize(1, pattern)

            DrawColorModify({
                ["$pp_colour_addr"] = (COL_FG.r - 255) / 255,
                ["$pp_colour_addg"] = (COL_FG.g - 255) / 255,
                ["$pp_colour_addb"] = (COL_FG.b - 255) / 255,
                ["$pp_colour_brightness"] = 0.6,
                ["$pp_colour_contrast"] = 1.25,
                ["$pp_colour_colour"] = 1,
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })

            local content_thumb = render.Capture({
                format = "png",
                x = 0,
                y = 0,
                w = 64,
                h = 64,
                alpha = false,
            })

            file.Write("arcrp_photos/thumbs/" .. os.time() .. ".png", content_thumb)
            render.PopRenderTarget()
        end)

        TabMemory.NextPhotoTime = UnPredictedCurTime() + 1.1
        camera_nextdraw = UnPredictedCurTime() + 1
    end,
    Func_Secondary = function()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function()
        TabMemory.Flash = not TabMemory.Flash
    end,
    Func_Scroll = function(level)
        local last = TabMemory.CameraZoom
        TabMemory.CameraZoom = math.Clamp(TabMemory.CameraZoom - level, 1, 10)

        if last ~= TabMemory.CameraZoom then
            LocalPlayer():EmitSound(level > 0 and "fesiug/tabphone/zoom_out.ogg" or "fesiug/tabphone/zoom_in.ogg", 100, 100, TabPhone.GetVolume())
        end
    end,
    Func_DrawScene = function()
        if camera_nextdraw < UnPredictedCurTime() then
            local rt = {
                x = 0,
                y = 0,
                w = 512,
                h = 512,
                aspect = 1,
                angles = vangle,
                origin = EyePos(),
                drawviewmodel = false,
                fov = 50 / TabMemory.CameraZoom,
                znear = 8
            }

            render.PushRenderTarget(cameratex, 0, 0, 512, 512)
            render.RenderView(rt)
            DrawTexturize(1, pattern)

            DrawColorModify({
                ["$pp_colour_addr"] = (COL_FG.r - 255) / 255,
                ["$pp_colour_addg"] = (COL_FG.g - 255) / 255,
                ["$pp_colour_addb"] = (COL_FG.b - 255) / 255,
                ["$pp_colour_brightness"] = 0.6,
                ["$pp_colour_contrast"] = 1.25,
                ["$pp_colour_colour"] = 1,
                ["$pp_colour_mulr"] = 0,
                ["$pp_colour_mulg"] = 0,
                ["$pp_colour_mulb"] = 0
            })

            render.PopRenderTarget()
            camera_nextdraw = UnPredictedCurTime() + 1 / camera_framerate
        end
    end,
    Func_Draw = function(w, h)
        TabMemory.LeftText = "TAKE PHOTO"
        surface.SetDrawColor(COL_BG)
        surface.DrawRect(0, 0, 512, 512)
        surface.SetMaterial(camMat)
        surface.SetDrawColor(255, 255, 255)
        local realbound = 512 - 48 - 40
        surface.DrawTexturedRect(w / 2 - realbound / 2, ((512 + 48) / 2 - (40 / 2)) - realbound / 2, realbound, realbound)

        if TabMemory.NextPhotoTime - 0.9 > UnPredictedCurTime() then
            surface.SetDrawColor(0, 0, 0)
            surface.DrawRect(0, 0, w, h)
        end

        if TabMemory.NextPhotoTime > UnPredictedCurTime() then return end

        -- rule of thirds !!!
        if TabMemory.Flash then
            surface.SetDrawColor(COL_FG)
        else
            surface.SetDrawColor(COL_BG)
        end

        surface.DrawLine(0, h / 3, w, h / 3)
        surface.DrawLine(0, h * 2 / 3, w, h * 2 / 3)
        surface.DrawLine(w / 3, 0, w / 3, h)
        surface.DrawLine(w * 2 / 3, 0, w * 2 / 3, h)

        if TabMemory.Flash then
            surface.SetMaterial(flashmat)
        else
            surface.SetMaterial(noflashmat)
        end

        surface.DrawTexturedRect(10, 64, 48, 48)
    end,
}

cachedgalleryimages = cachedgalleryimages or {}

local function GetGalleryImages()
    table.Empty(cachedgalleryimages)
    local images = file.Find("arcrp_photos/thumbs/*.png", "DATA", "datedesc")

    for i, filename in ipairs(images) do
        table.insert(cachedgalleryimages, {
            index = i,
            filename = filename,
        })
    end
end

TabPhone.Apps["gallery"] = {
    Name = "Gallery",
    Icon = Material("fesiug/tabphone/gallery.png"),
    SortOrder = -1019,
    Func_Enter = function()
        if not TabMemory.GallerySelected then
            TabMemory.GallerySelected = 1
        end

        GetGalleryImages()
    end,
    Func_Primary = function()
        TabPhone.EnterApp("gallery_viewer")
    end,
    Func_Secondary = function()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Scroll = function(level)
        TabPhone.Scroll(level, "GallerySelected", #cachedgalleryimages)
    end,
    Func_Reload = function()
        TabPhone.EnterApp("gallery_options")
    end,
    Func_Draw = function(w, h)
        TabMemory.LeftText = ""

        if #cachedgalleryimages <= 0 then
            draw.SimpleText("NO PHOTOS", "TabPhone32", w / 2, (512 - 48) / 2 - (40 / 2), COL_BG, TEXT_ALIGN_CENTER)
        end

        local page = math.floor((TabMemory.GallerySelected - 1) / 9)
        local maxpages = 16
        local pagecount = math.ceil(#cachedgalleryimages / 9)

        for i, k in ipairs(cachedgalleryimages) do
            local sel = TabMemory.GallerySelected == i
            local mypage = math.floor(i / 9)

            if i % 9 == 0 then
                mypage = mypage - 1
            end

            if mypage ~= page then continue end
            local ti = i - 1
            local xslot = (ti % 3) - 1
            local yslot = (math.floor(ti / 3) % 3) - 1
            local sw = 128
            local sh = 128
            local x = (404 / 2) - (sw / 2) + ((sw + 4) * xslot)
            local y = ((512 - 48) / 2) + (40 / 2) - (sh / 2) - 4 + ((sh + 4) * yslot)

            if sel then
                surface.SetDrawColor(0, 0, 0)
                surface.DrawRect(x - 5, y - 5, sw + 10, sh + 10)
                TabMemory.LeftText = "VIEW"
            end

            if not k.thumbmat then
                k.thumbmat = Material("data/arcrp_photos/thumbs/" .. k.filename)
            end

            surface.SetMaterial(k.thumbmat)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawTexturedRect(x, y, sw, sh)
        end

        if pagecount > maxpages then
            draw.SimpleText(tostring(page + 1) .. "/" .. tostring(pagecount + 1), "TabPhone24", w / 2, h - 16 - 40 - 14, COL_BG, TEXT_ALIGN_CENTER)
        else
            for i = 1, pagecount do
                local sel = (page + 1) == i

                if sel then
                    surface.SetMaterial(radio_filled)
                else
                    surface.SetMaterial(radio_empty)
                end

                surface.SetDrawColor(COL_BG)
                local x = (w / 2) - (pagecount * 20 / 2) + (i * 20) - 20
                surface.DrawTexturedRect(x, h - 40 - 24, 20, 20)
            end
        end
    end,
}

TabPhone.Apps["gallery_viewer"] = {
    Name = "Image Viewer",
    Hidden = true,
    Func_Enter = function() end,
    Func_Primary = function()
        -- local image = cachedgalleryimages[TabMemory.GallerySelected]
        -- if not image then return end
        -- TabMemory.TempPFP = image.filename
        TabPhone.EnterApp("gallery_options")
    end,
    Func_Secondary = function()
        TabPhone.EnterApp("gallery")
    end,
    Func_Reload = function()
        TabPhone.EnterApp("gallery_options")
    end,
    Func_Scroll = function(level)
        TabPhone.Scroll(level, "GallerySelected", #cachedgalleryimages)
    end,
    Func_Draw = function(w, h)
        TabMemory.LeftText = "OPTIONS"
        local image = cachedgalleryimages[TabMemory.GallerySelected]
        if not image then return end

        if not image.material then
            image.material = Material("data/arcrp_photos/" .. image.filename)
        end

        local available = 512 - 48 - 40
        surface.SetMaterial(image.material)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(BARRIER_FLIPPHONE / 2 - available / 2, ((512 + 48) / 2 - (40 / 2)) - available / 2, available, available)
    end,
}

local image_options = {
    {
        label = "Set Profile",
        func = function()
            TabMemory.ContactsMode = "profile"
            TabPhone.EnterApp("contacts")
        end,
        icon = mat_profile
    },
    {
        label = "Delete",
        func = function()
            TabPhone.EnterApp("gallery_deleter")
        end,
        icon = Material("fesiug/tabphone/bin.png")
    }
}

TabPhone.Apps["gallery_options"] = {
    Name = "Image Options",
    Hidden = true,
    Func_Enter = function() end,
    Func_Scroll = function(level)
        TabPhone.Scroll(level, "SelectedImageOption", #image_options)
    end,
    Func_Primary = function()
        image_options[TabMemory.SelectedImageOption].func()
    end,
    Func_Secondary = function()
        TabPhone.EnterApp("gallery_viewer")
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h)
        local superoff = -4 + 256 + 8 + 40
        local image = cachedgalleryimages[TabMemory.GallerySelected]
        if not image then return end

        if not image.material then
            image.material = Material("data/arcrp_photos/" .. image.filename)
        end

        surface.SetMaterial(image.material)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(w / 2 - 256 / 2, 48 + 4, 256, 256)
        local hourstyle = GetConVar("tabphone_24h"):GetBool() and "%H:%M" or "%I:%M %p"
        local mrew = os.date("%Y-%m-%d, " .. hourstyle, tonumber(image.filename:Left(-5)))
        draw.SimpleText(mrew, "TabPhone24", w / 2, 48 + 8 + 256 + 8, COL_BG, TEXT_ALIGN_CENTER)

        for i, opt in ipairs(image_options) do
            local sel = i == TabMemory.SelectedImageOption
            surface.SetDrawColor(COL_BG)

            if sel then
                surface.DrawRect(8, superoff + ((i - 1) * (48 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8, 52)
            else
                surface.DrawOutlinedRect(8, superoff + ((i - 1) * (48 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8, 52, 4)
            end

            draw.SimpleText(opt.label, "TabPhone32", 8 + 8 + 8 + 8 + 8 + 32, superoff + ((i - 1) * (48 + 8)) + 48 + 8 + 8, sel and COL_FG or COL_BG)

            if opt.icon then
                surface.SetDrawColor(sel and COL_FG or COL_BG)
                surface.SetMaterial(opt.icon)
                surface.DrawTexturedRect(8 + 8 + 4 + 4, superoff + ((i - 1) * (48 + 8)) + 48 + 8 + 8 + 2, 32, 32)
            end
        end
    end,
}

TabPhone.Apps["gallery_deleter"] = {
    Name = "Image Deleter",
    Hidden = true,
    Func_Enter = function()
        LocalPlayer():EmitSound("fesiug/tabphone/delete.ogg", 70, 100, 0.5 * TabPhone.GetVolume(), CHAN_STATIC)
    end,
    Func_Reload = function() end,
    Func_Primary = function()
        local image = cachedgalleryimages[TabMemory.GallerySelected]
        file.Delete("arcrp_photos/" .. image.filename)
        file.Delete("arcrp_photos/thumbs/" .. image.filename)
        cachedgalleryimages[TabMemory.GallerySelected] = nil
        GetGalleryImages()
        TabPhone.EnterApp("gallery")
    end,
    Func_Secondary = function()
        TabPhone.EnterApp("gallery_options")
    end,
    Func_Draw = function(w, h)
        TabMemory.LeftText = "CONFIRM"
        TabMemory.RightText = "CANCEL"
        surface.SetDrawColor(COL_BG)
        surface.DrawRect(0, 0, 512, 512)
        draw.SimpleText("DELETE??", "TabPhone32", w / 2, 64, COL_FG, TEXT_ALIGN_CENTER)
        draw.SimpleText("This cannot", "TabPhone24", w / 2, 80 + 24, COL_FG, TEXT_ALIGN_CENTER)
        draw.SimpleText("be undone!!", "TabPhone24", w / 2, 80 + 24 + 24, COL_FG, TEXT_ALIGN_CENTER)
        local image = cachedgalleryimages[TabMemory.GallerySelected]
        if not image then return end

        if not image.material then
            image.material = Material("data/arcrp_photos/" .. image.filename)
        end

        surface.SetMaterial(image.material)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(w / 2 - 300 / 2, 172, 300, 300)
    end,
}