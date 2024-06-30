local cameratex = GetRenderTarget("TabPhoneRTCam", 512, 512, false)
local thumbtex = GetRenderTarget("TabPhoneRTCamThumb", 64, 64, false)
local camMat = CreateMaterial("TabPhoneRTCam", "UnlitGeneric", {
    ["$basetexture"] = cameratex:GetName(),
})

local COL_FG = Color(76, 104, 79)
local COL_BG = color_black
local IMAGE_MESSAGE = Material("fesiug/TabPhone/message.png")

local BARRIER_FLIPPHONE = 404

TabPhone.RingtonePath = "fesiug/tabphone/ringtones/44khz/"
TabPhone.Ringtones = {
    "1.6.ogg",
    "109.ogg",
    "americafyeah.ogg",
    "amongla.ogg",
    "angrybirds.ogg",
    "arab.ogg",
    "Bassmatic.ogg",
    "butterfly.ogg",
    "callring.ogg",
    "callring2.ogg",
    "callring3_franklin.ogg",
    "callring4.ogg",
    "callring5.ogg",
    "callring6_michael.ogg",
    "callring7.ogg",
    "callring8_trevor.ogg",
    "clockring.ogg",
    "Cool Room.ogg",
    "Countryside.ogg",
    "Credit Check.ogg",
    "Dragon Brain.ogg",
    "Drive.ogg",
    "duvet.ogg",
    "edgy.ogg",
    "Fox.ogg",
    "Funk in Time.ogg",
    "Get Down.ogg",
    "gutsberserk.ogg",
    "High Seas.ogg",
    "Hooker.ogg",
    "Into Something.ogg",
    "Katja's Waltz.ogg",
    "Laidback.ogg",
    "Malfunction.ogg",
    "Mine Until Monday.ogg",
    "Pager.ogg",
    "Ringing 1.ogg",
    "Ringing 2.ogg",
    "russian.ogg",
    "Science of Crime.ogg",
    "sfx_sms.ogg",
    "Solo.ogg",
    "Spy.ogg",
    "Standard Ring.ogg",
    "Swing It.ogg",
    "tailsofvalor.ogg",
    "Take the Pain.ogg",
    "Teeker.ogg",
    "Text.ogg",
    "textring.ogg",
    "textring2.ogg",
    "textring3.ogg",
    "textring4.ogg",
    "textring5.ogg",
    "The One for Me.ogg",
    "themanwhosoldtheworld.ogg",
    "Tonight.ogg",
    "valve.ogg",
}

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

TabPhone.Apps = {}

TabPhone.Apps["mainmenu"] = {
    Name = "Main Menu",
    Hidden = true,
    Icon = Material("fesiug/TabPhone/contact.png"),
    SortOrder = 0,
    Func_Enter = function() end,
    Func_Primary = function()
        local Sortedapps = GetApps()
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

        for i, prev in ipairs(Sortedapps) do
            local v = TabPhone.Apps[prev]
            local sel = i == TabMemory.Selected
            surface.SetDrawColor(COL_BG)

            if sel then
                surface.DrawRect(8, ((i - 1) * (48 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8, 52)
            else
                surface.DrawOutlinedRect(8, ((i - 1) * (48 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8, 52, 4)
            end

            draw.SimpleText(v.Name, "TabPhone32", 8 + 8 + 8 + 8 + 8 + 32, ((i - 1) * (48 + 8)) + 48 + 8 + 8, sel and COL_FG or COL_BG)
            surface.SetDrawColor(sel and COL_FG or COL_BG)
            surface.SetMaterial(v.Icon)
            surface.DrawTexturedRect(8 + 8 + 4 + 4, ((i - 1) * (48 + 8)) + 48 + 8 + 8 + 2, 32, 32)
        end
    end,
}

TabPhone.Apps["contacts"] = {
    Name = "Contacts",
    Icon = Material("fesiug/TabPhone/contact.png"),
    SortOrder = -1009,
    Func_Enter = function() end,
    Func_Primary = function() end,
    Func_Secondary = function()
        TabMemory.ActiveApp = "mainmenu"
        TabMemory.PageSwitchTime = CurTime()
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h)
        draw.SimpleText("Players online:", "TabPhone24", 8, 8 + 48, COL_BG)

        for i, v in player.Iterator() do
            draw.SimpleText(v:Nick(), "TabPhone32", 8, 8 + 48 + 24 + ((i - 1) * 32), COL_BG)
        end
    end,
}

TabPhone.Apps["messages"] = {
    Name = "Messages",
    Icon = Material("fesiug/TabPhone/message.png"),
    SortOrder = -1008,
    Func_Enter = function() end,
    Func_Scroll = function() end,
    Func_Primary = function() end,
    Func_Secondary = function()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h)
		surface.SetDrawColor( COL_BG )
		surface.DrawRect( 0, 48, 512, 48+4+4 )

		if TabMemory.TempPFP then
			surface.SetMaterial( Material("data/arcrp_photos/thumbs/" .. TabMemory.TempPFP) )
			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRect(4, 48+4, 48, 48)
		end

        draw.SimpleText("Alice", "TabPhone24", 8+48+8 + 4, 8 + 48 + 4, COL_FG )

		do
			surface.SetFont("TabPhone24")
			local ts = "'jeff the kill' you"
			local tsn = surface.GetTextSize(ts)
			surface.SetDrawColor( COL_BG )
			surface.DrawRect( w-8-tsn, 512-40-8-(24+4+4), tsn, 24+4+4 )
			draw.SimpleText( ts, "TabPhone24", w-8-tsn, 512-40-8-(24+4), COL_FG )
		end

		do
			surface.SetFont("TabPhone24")
			local ts = "'jeff the kill' you"
			local tsn = surface.GetTextSize(ts)
			surface.SetDrawColor( COL_BG )
			surface.DrawRect( 8, 512-40-8-(24+4+4)-8-(24+4+4), tsn, 24+4+4 )
			draw.SimpleText( ts, "TabPhone24", 8, 512-40-8-(24+4+4)-8-(24+4), COL_FG )
		end
    end,
}

TabPhone.Apps["jobs"] = {
    Name = "Jobs",
    Icon = Material("fesiug/TabPhone/job.png"),
    SortOrder = -1007,
    Func_Enter = function() end,
    Func_Primary = function() end,
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
    Icon = Material("fesiug/TabPhone/calendar.png"),
    SortOrder = -1006,
    Func_Enter = function() end,
    Func_Primary = function() end,
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

TabPhone.Apps["shopping"] = {
    Name = "Shopping",
    Icon = Material("fesiug/TabPhone/shopper.png"),
    SortOrder = -1006,
    Func_Enter = function() end,
    Func_Primary = function() end,
    Func_Secondary = function()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h) end,
}

TabPhone.Apps["call"] = {
    Name = "Fake Call",
    Icon = Material("fesiug/TabPhone/phone.png"),
    SortOrder = 0,
    Func_Enter = function()
        local sound = TabPhone.RingtonePath .. TabPhone.Ringtones[GetConVar("tabphone_ringtone"):GetInt()]
        LocalPlayer():EmitSound(sound, 100, 100, 1, CHAN_STATIC)
    end,
    Func_Primary = function() end,
    Func_Secondary = function()
        local sound = TabPhone.RingtonePath .. TabPhone.Ringtones[GetConVar("tabphone_ringtone"):GetInt()]
        LocalPlayer():StopSound(sound)
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function() end,
    Func_Draw = function(w, h)
		TabMemory.LeftText = "ANSWER"
		TabMemory.RightText = "DECLINE"
        surface.SetDrawColor(COL_FG)
        surface.DrawRect(0, 0, 512, 512)
		
		if TabMemory.TempPFP then
			surface.SetMaterial( Material("data/arcrp_photos/" .. TabMemory.TempPFP) )
			surface.SetDrawColor(255, 255, 255)
			local super = (512-48-40)
			surface.DrawTexturedRect(w/2 - super/2, (((512+48)/2) - (40/2)) - (super/2), super, super)
		end

        local jiggy = (math.Round(math.sin(CurTime() * 2 * math.pi) * 2, 0) / 2) * 16
        local jiggy2 = math.Round(math.sin(CurTime() * 28 * math.pi), 0) * 4

		surface.SetFont("TabPhone32")
		local tsn = surface.GetTextSize(" INCOMING CALL ")
        surface.SetDrawColor(COL_FG)
        surface.DrawRect((BARRIER_FLIPPHONE / 2) + jiggy - tsn/2, 64 + 16 + jiggy2, tsn, 32+4+4)
		local tsn = surface.GetTextSize(" Bank of Siple ")
        surface.DrawRect((BARRIER_FLIPPHONE / 2) - tsn/2, 64 + 72, tsn, 32+4+4)
		
        draw.SimpleText("INCOMING CALL", "TabPhone32", (BARRIER_FLIPPHONE / 2) + jiggy, 64 + 16 + jiggy2, COL_BG, TEXT_ALIGN_CENTER)
        draw.SimpleText("Bank of Siple", "TabPhone32", BARRIER_FLIPPHONE / 2, 64 + 72, COL_BG, TEXT_ALIGN_CENTER)
    end,
}

local settings_options = {
    {
        label = "Ringtone",
        icon = Material("fesiug/TabPhone/phone.png"),
        min = 1,
        max = function()
            return #TabPhone.Ringtones
        end,
        convar = GetConVar("tabphone_ringtone"),
        func_change = function(val)
            if TabMemory.RingToneExample then
                TabMemory.RingToneExample:Stop()
            end
            local sound = TabPhone.RingtonePath .. TabPhone.Ringtones[val]
            TabMemory.RingToneExample = CreateSound(LocalPlayer(), sound)
            TabMemory.RingToneExample:Play()
        end,
        type = "int",
    },
    {
        label = "Back",
        type = "func",
        func_change = function()
            TabPhone.EnterApp("mainmenu")
            if TabMemory.RingToneExample then
                TabMemory.RingToneExample:Stop()
            end
        end
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
        else
            if isfunction(opt.func_change) then
                opt.func_change()
            end
        end
end

TabPhone.Apps["settings"] = {
    Name = "Settings",
    Icon = Material("fesiug/TabPhone/settings.png"),
    SortOrder = -1005,
    Func_Enter = function() end,
    Func_Primary = function()
        changeOption(1)
    end,
    Func_Scroll = function(level)
        TabPhone.Scroll(level, "SelectedSetting", #settings_options)
    end,
    Func_Secondary = function()
        // TabPhone.EnterApp("mainmenu")
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
            end
        end
    end,
}

local camera_nextdraw = 0
local camera_framerate = 15

local pattern = Material("pp/texturize/plain.png")
local flashmat = Material("fesiug/TabPhone/flash.png")
local noflashmat = Material("fesiug/TabPhone/noflash.png")

TabPhone.Apps["camera"] = {
    Name = "Camera",
    Icon = Material("fesiug/TabPhone/camera.png"),
    SortOrder = -1020,
    Func_Enter = function()
		TabMemory.CameraZoom = 1
	end,
    Func_Primary = function()
        if TabMemory.NextPhotoTime > CurTime() then return end
		local vangle = LocalPlayer():EyeAngles()

        if TabMemory.Flash then
            local dlight = DynamicLight( LocalPlayer():EntIndex() )
            if ( dlight ) then
                dlight.pos = LocalPlayer():EyePos()
                dlight.r = 255
                dlight.g = 255
                dlight.b = 255
                dlight.brightness = 1
                dlight.decay = 0
                dlight.size = 2048
                dlight.dietime = CurTime() + 0.1
            end
        end

        timer.Simple(0, function()
            render.PushRenderTarget(cameratex, 0, 0, 512, 512)

            surface.PlaySound("npc/scanner/scanner_photo1.wav")

            local rt = {
                x = 0,
                y = 0,
                w = 512,
                h = 512,
                aspect = 1,
                angles = vangle,
                origin = EyePos(),
                drawviewmodel = false,
                fov = 50/TabMemory.CameraZoom,
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
            file.Write("arcrp_photos/" .. os.time() ..  ".png", content)
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
                fov = 50/TabMemory.CameraZoom,
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
            file.Write("arcrp_photos/thumbs/" .. os.time() ..  ".png", content_thumb)
            render.PopRenderTarget()
        end)

        TabMemory.NextPhotoTime = CurTime() + 1.1
        camera_nextdraw = CurTime() + 1
    end,
    Func_Secondary = function()
        TabPhone.EnterApp("mainmenu")
    end,
    Func_Reload = function()
		TabMemory.Flash = !TabMemory.Flash
	end,
    Func_Scroll = function(level)
		local last = TabMemory.CameraZoom
		TabMemory.CameraZoom = math.Clamp( TabMemory.CameraZoom-(level), 1, 10 )
		if last != TabMemory.CameraZoom then
			surface.PlaySound(level > 0 and "fesiug/tabphone/zoom_out.ogg" or "fesiug/tabphone/zoom_in.ogg")
		end
    end,
    Func_DrawScene = function()
        if camera_nextdraw < CurTime() then
            local rt = {
                x = 0,
                y = 0,
                w = 512,
                h = 512,
                aspect = 1,
                angles = vangle,
                origin = EyePos(),
                drawviewmodel = false,
                fov = 50/TabMemory.CameraZoom,
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

            camera_nextdraw = CurTime() + 1 / camera_framerate
        end
    end,
    Func_Draw = function(w, h)
		TabMemory.LeftText = "TAKE PHOTO"
		surface.SetDrawColor(COL_FG)
        surface.DrawRect(0, 0, 512, 512)

        surface.SetMaterial(camMat)
        surface.SetDrawColor(255, 255, 255)
		local realbound = (512-48-40)
        surface.DrawTexturedRect(w/2 - realbound/2, ((512+48)/2 - (40/2)) - realbound/2, realbound, realbound)

        if TabMemory.NextPhotoTime - 0.9 > CurTime() then
            surface.SetDrawColor(0, 0, 0)
            surface.DrawRect(0, 0, w, h)
        end

        if TabMemory.NextPhotoTime > CurTime() then return end
        // rule of thirds !!!
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

    local c = 0

    for i, filename in ipairs(images) do
        if c >= 9 then break end
        c = c + 1
        table.insert(cachedgalleryimages, {
            index = i,
            filename = filename,
            thumbmat = Material("data/arcrp_photos/thumbs/" .. filename)
        })
    end
end

TabPhone.Apps["gallery"] = {
    Name = "Gallery",
    Icon = Material("fesiug/TabPhone/gallery.png"),
    SortOrder = -1019,
    Func_Enter = function()
		if !TabMemory.GallerySelected then
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
        TabPhone.EnterApp("gallery_deleter")
	end,
    Func_Draw = function(w, h)
		TabMemory.LeftText = ""
		if #cachedgalleryimages >= 0 then
			draw.SimpleText( "NO PHOTOS", "TabPhone32", w/2, (512-48)/2 - (40/2), COL_BG, TEXT_ALIGN_CENTER )
		end
		for i, k in ipairs(cachedgalleryimages) do
            local xslot = (i - 1) % 3
            local yslot = math.ceil(i / 3)

            local sel = TabMemory.GallerySelected == i

            local sw = 120
            local sh = 120
            local x = 10 + xslot * (sw + 10)
            local y = -60 + yslot * (sh + 10)

            if sel then
                surface.SetDrawColor(0, 0, 0)
                surface.DrawRect(x - 5, y - 5, sw + 10, sh + 10)
				TabMemory.LeftText = "VIEW"
			end

            surface.SetMaterial(k.thumbmat)
            surface.SetDrawColor(255, 255, 255)
            surface.DrawTexturedRect(x, y, sw, sh)
        end
    end,
}

TabPhone.Apps["gallery_viewer"] = {
    Name = "Image Viewer",
    Hidden = true,
    Func_Enter = function() end,
    Func_Primary = function()
        local image = cachedgalleryimages[TabMemory.GallerySelected]
        if not image then return end
		TabMemory.TempPFP = image.filename
	end,
    Func_Secondary = function()
        TabPhone.EnterApp("gallery")
    end,
    Func_Reload = function()
        TabPhone.EnterApp("gallery_deleter")
	end,
    Func_Scroll = function(level)
        TabPhone.Scroll(level, "GallerySelected", #cachedgalleryimages)
    end,
    Func_Draw = function(w, h)
		TabMemory.LeftText = "(TEMP)MAKE PFP"
		local image = cachedgalleryimages[TabMemory.GallerySelected]

        if not image then return end
        if not image.material then image.material = Material("data/arcrp_photos/" .. image.filename) end

		local available = 512 - 48 - 40
        surface.SetMaterial(image.material)
        surface.SetDrawColor(255, 255, 255)
        surface.DrawTexturedRect(BARRIER_FLIPPHONE/2 - available/2, ((512+48)/2 - (40/2)) - available/2, available, available)
    end,
}

TabPhone.Apps["gallery_deleter"] = {
    Name = "Image Deleter",
    Hidden = true,
    Func_Enter = function()
        LocalPlayer():EmitSound("fesiug/tabphone/delete.ogg", 70, 100, 0.5, CHAN_STATIC)
	end,
    Func_Reload = function() end,
    Func_Primary = function()
		local image = cachedgalleryimages[TabMemory.GallerySelected]
		file.Delete("arcrp_photos/" .. image.filename )
		file.Delete("arcrp_photos/thumbs/" .. image.filename )
		cachedgalleryimages[TabMemory.GallerySelected] = nil
		GetGalleryImages()
        TabPhone.EnterApp("gallery")
	end,
    Func_Secondary = function()
        TabPhone.EnterApp("gallery")
    end,
    Func_Draw = function(w, h)
		TabMemory.LeftText = "CONFIRM"
		TabMemory.RightText = "CANCEL"
		surface.SetDrawColor(COL_BG)
        surface.DrawRect(0, 0, 512, 512 )
		
		draw.SimpleText("DELETE??", "TabPhone32", w/2, 64, COL_FG, TEXT_ALIGN_CENTER)
		draw.SimpleText("This cannot", "TabPhone24", w/2, 80+24, COL_FG, TEXT_ALIGN_CENTER)
		draw.SimpleText("be undone!!", "TabPhone24", w/2, 80+24+24, COL_FG, TEXT_ALIGN_CENTER)

        local image = cachedgalleryimages[TabMemory.GallerySelected]
        if not image then return end
        if not image.material then image.material = Material("data/arcrp_photos/" .. image.filename) end
		surface.SetMaterial(image.material)
		surface.SetDrawColor(255, 255, 255)
		surface.DrawTexturedRect(w/2 - 300/2, 172, 300, 300)
    end,
}