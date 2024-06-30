SWEP.Base = "weapon_base"
SWEP.Spawnable = true
SWEP.ViewModel = "models/fesiug/tabphone_2.mdl"
SWEP.ViewModelFOV = 44
SWEP.PrintName = "tabphone"
SWEP.BobScale = 0.1
SWEP.SwayScale = 0.1

SWEP.Slot = -1

SWEP.Primary.ClipSize = -1
SWEP.Primary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.Ammo = ""

SWEP.IsTabPhone = true

function SWEP:QuickAnim(name)
	local vm = self:GetOwner():GetViewModel()
	vm:SetPlaybackRate(1)
	vm:SendViewModelMatchingSequence(vm:LookupSequence(name))
end

function SWEP:Keypress()
	self:EmitSound("fesiug/tabphone/key_press" .. math.random(1, 7) .. ".wav", 70, 100, 0.4)
end

if CLIENT then
	local tex = GetRenderTargetEx("TabphoneRT8", 512, 512, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE, bit.bor(2, 256), 0, IMAGE_FORMAT_BGR888)
	local cameratex = GetRenderTarget("TabphoneRTCam", 512, 512, false)
	local thumbtex = GetRenderTarget("TabphoneRTCamThumb", 64, 64, false)

	local myMat = CreateMaterial("TabphoneRTMat8", "UnlitGeneric", {
		["$basetexture"] = tex:GetName(),
	})

	local camMat = CreateMaterial("TabphoneRTCam", "UnlitGeneric", {
		["$basetexture"] = cameratex:GetName(),
	})

	local COL_FG = Color(76, 104, 79)
	local COL_BG = color_black

	local sizes = {32, 28, 24, 22, 16,}

	for i, v in pairs(sizes) do
		surface.CreateFont("Tabphone" .. v, {
			font = "HD44780A00 5x8 Regular",
			size = v,
			antialias = false,
		})
	end

	local BARRIER_FLIPPHONE = 404
	local IMAGE_BATTERY = Material("fesiug/tabphone/battery.png")
	local IMAGE_CELL = Material("fesiug/tabphone/cell2.png")
	local IMAGE_MESSAGE = Material("fesiug/tabphone/message.png")
	local IMAGE_MESSAGE2 = Material("fesiug/tabphone/message2.png")
	Tabphone = {}

	TabMemory = TabMemory or {
		ActiveApp = "mainmenu",
		GallerySelected = 1,
	}

	local function EnterApp(name)
		local from = TabMemory.ActiveApp
		TabMemory.ActiveApp = name
		TabMemory.PageSwitchTime = CurTime()
		local active = TabMemory.ActiveApp
		Tabphone.Apps[active].Func_Enter(from)
	end

	local function GetApps()
		local Sortedapps = {}

		for i, v in pairs(Tabphone.Apps) do
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
			local tbl_a = Tabphone.Apps[a]
			local tbl_b = Tabphone.Apps[b]
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

		for i, v in pairs(Tabphone.Apps) do
			if v.Hidden then continue end
			table.insert(Sortedapps, i)
		end

		return table.Count(Sortedapps)
	end

	Tabphone.Apps = {}

	Tabphone.Apps["mainmenu"] = {
		Name = "Main Menu",
		Hidden = true,
		Icon = Material("fesiug/tabphone/contact.png"),
		SortOrder = 0,
		Func_Enter = function() end,
		Func_Primary = function()
			local Sortedapps = GetApps()
			EnterApp(Sortedapps[TabMemory.Selected])
		end,
		Func_Secondary = function()
			local p = LocalPlayer()
			local w = p:GetPreviousWeapon()

			if w:IsValid() and w:IsWeapon() then
				input.SelectWeapon(w)
			end
		end,
		Func_Scroll = function(level)
			if not TabMemory.Selected then
				TabMemory.Selected = 1
			end

			TabMemory.Selected = TabMemory.Selected + level
			local Appcount = AppCount()

			if TabMemory.Selected <= 0 then
				TabMemory.Selected = Appcount
			elseif TabMemory.Selected > Appcount then
				TabMemory.Selected = 1
			end
		end,
		Func_Reload = function() end,
		Func_Draw = function(w, h)
			local Sortedapps = GetApps()

			for i, prev in ipairs(Sortedapps) do
				local v = Tabphone.Apps[prev]
				local sel = i == TabMemory.Selected
				surface.SetDrawColor(COL_BG)

				if sel then
					surface.DrawRect(8, ((i - 1) * (48 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8, 52)
				else
					surface.DrawOutlinedRect(8, ((i - 1) * (48 + 8)) + 48 + 8, BARRIER_FLIPPHONE - 8 - 8, 52, 4)
				end

				draw.SimpleText(v.Name, "Tabphone32", 8 + 8 + 8 + 8 + 32, ((i - 1) * (48 + 8)) + 48 + 8 + 8, sel and COL_FG or COL_BG)
				surface.SetDrawColor(sel and COL_FG or COL_BG)
				surface.SetMaterial(v.Icon)
				surface.DrawTexturedRect(8 + 8 + 4, ((i - 1) * (48 + 8)) + 48 + 8 + 8 + 2, 32, 32)
			end
		end,
	}

	Tabphone.Apps["contacts"] = {
		Name = "Contacts",
		Icon = Material("fesiug/tabphone/contact.png"),
		SortOrder = -1009,
		Func_Enter = function() end,
		Func_Primary = function() end,
		Func_Secondary = function()
			TabMemory.ActiveApp = "mainmenu"
			TabMemory.PageSwitchTime = CurTime()
		end,
		Func_Reload = function() end,
		Func_Draw = function(w, h)
			draw.SimpleText("Players online:", "Tabphone24", 8, 8 + 48, COL_BG)

			for i, v in player.Iterator() do
				draw.SimpleText(v:Nick(), "Tabphone32", 8, 8 + 48 + 24 + ((i - 1) * 32), COL_BG)
			end
		end,
	}

	Tabphone.Apps["messages"] = {
		Name = "Messages",
		Icon = Material("fesiug/tabphone/message.png"),
		SortOrder = -1008,
		Func_Enter = function() end,
		Func_Primary = function() end,
		Func_Secondary = function()
			EnterApp("mainmenu")
		end,
		Func_Reload = function() end,
		Func_Draw = function(w, h)
			for i = 0, 10 do
				draw.SimpleText("WORK IN PROGRESS", "Tabphone32", BARRIER_FLIPPHONE / 2, 64 + (i * (32 + 4)), COL_BG, TEXT_ALIGN_CENTER)
			end
		end,
	}

	Tabphone.Apps["jobs"] = {
		Name = "Jobs",
		Icon = Material("fesiug/tabphone/job.png"),
		SortOrder = -1007,
		Func_Enter = function() end,
		Func_Primary = function() end,
		Func_Secondary = function()
			EnterApp("mainmenu")
		end,
		Func_Reload = function() end,
		Func_Draw = function(w, h)
			for i = 0, 10 do
				draw.SimpleText("WORK IN PROGRESS", "Tabphone32", BARRIER_FLIPPHONE / 2, 64 + (i * (32 + 4)), COL_BG, TEXT_ALIGN_CENTER)
			end
		end,
	}

	Tabphone.Apps["calendar"] = {
		Name = "Calendar",
		Icon = Material("fesiug/tabphone/calendar.png"),
		SortOrder = -1006,
		Func_Enter = function() end,
		Func_Primary = function() end,
		Func_Secondary = function()
			EnterApp("mainmenu")
		end,
		Func_Reload = function() end,
		Func_Draw = function(w, h) end,
	}

	Tabphone.Apps["call"] = {
		Name = "Fake Call",
		Icon = Material("fesiug/tabphone/phone.png"),
		SortOrder = 0,
		Func_Enter = function()
			LocalPlayer():EmitSound("fesiug/tabphone/ringtone_toy.ogg", 100, 100, 1, CHAN_STATIC)
		end,
		Func_Primary = function() end,
		Func_Secondary = function()
			LocalPlayer():StopSound("fesiug/tabphone/ringtone_toy.ogg")
			EnterApp("mainmenu")
		end,
		Func_Reload = function() end,
		Func_Draw = function(w, h)
			surface.SetDrawColor(COL_FG)
			surface.DrawRect(0, 0, 512, 512)
			local jiggy = (math.Round(math.sin(CurTime() * 2 * math.pi) * 2, 0) / 2) * 16
			local jiggy2 = (math.Round(math.sin(CurTime() * 28 * math.pi) * 2, 0) / 2) * 4
			draw.SimpleText("INCOMING CALL", "Tabphone32", (BARRIER_FLIPPHONE / 2) + jiggy, 64 + 16 + jiggy2, COL_BG, TEXT_ALIGN_CENTER)
			draw.SimpleText("Bank of Siple", "Tabphone32", BARRIER_FLIPPHONE / 2, 64 + 72, COL_BG, TEXT_ALIGN_CENTER)
		end,
	}

	Tabphone.Apps["settings"] = {
		Name = "Settings",
		Icon = Material("fesiug/tabphone/settings.png"),
		SortOrder = -1005,
		Func_Enter = function() end,
		Func_Primary = function() end,
		Func_Secondary = function()
			EnterApp("mainmenu")
		end,
		Func_Reload = function() end,
		Func_Draw = function(w, h) end,
	}

	local camera_nextdraw = 0
	local camera_framerate = 15
	local camera_nextphototime = 0

	local pattern = Material("pp/texturize/plain.png")

	Tabphone.Apps["camera"] = {
		Name = "Camera",
		Icon = Material("fesiug/tabphone/camera.png"),
		SortOrder = -1020,
		LeftText = "TAKE PHOTO",
		Func_Enter = function() end,
		Func_Primary = function()
			if camera_nextphototime > CurTime() then return end

			render.PushRenderTarget(cameratex, 0, 0, 512, 512)

			surface.PlaySound("npc/scanner/scanner_photo1.wav")
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

			local rt = {
				x = 0,
				y = 0,
				w = 64,
				h = 64,
				aspect = 1,
				angles = EyeAngles(),
				origin = EyePos(),
				drawviewmodel = false,
				fov = 50,
				znear = 8
			}
			render.PushRenderTarget(thumbtex, 0, 0, 64, 64)
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

			camera_nextphototime = CurTime() + 1.1
			camera_nextdraw = CurTime() + 1
		end,
		Func_Secondary = function()
			EnterApp("mainmenu")
		end,
		Func_Reload = function() end,
		Func_DrawScene = function()
			if camera_nextdraw < CurTime() then
				local rt = {
					x = 0,
					y = 0,
					w = 512,
					h = 512,
					aspect = 1,
					angles = EyeAngles(),
					origin = EyePos(),
					drawviewmodel = false,
					fov = 50,
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
			surface.SetDrawColor(COL_FG)
			surface.DrawRect(0, 0, 512, 512)

			surface.SetMaterial(camMat)
			surface.SetDrawColor(Color(255, 255, 255))
			surface.DrawTexturedRect(0, 0, w, h)

			if camera_nextphototime - 0.9 > CurTime() then
				surface.SetDrawColor(Color(0, 0, 0))
				surface.DrawRect(0, 0, w, h)
			end

			if camera_nextphototime > CurTime() then return end
			// rule of thirds !!!
			surface.SetDrawColor(0, 0, 0)
			surface.DrawLine(0, h / 3, w, h / 3)
			surface.DrawLine(0, h * 2 / 3, w, h * 2 / 3)
			surface.DrawLine(w / 3, 0, w / 3, h)
			surface.DrawLine(w * 2 / 3, 0, w * 2 / 3, h)
		end,
	}

	local cachedgalleryimages = cachedgalleryimages or {}

	local function GetGalleryImages()
		cachedgalleryimages = {}
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

	Tabphone.Apps["gallery"] = {
		Name = "Gallery",
		Icon = Material("fesiug/tabphone/gallery.png"),
		SortOrder = -1019,
		Func_Enter = function()
			GetGalleryImages()
		end,
		Func_Primary = function()
			EnterApp("gallery_viewer")
		end,
		Func_Secondary = function()
			EnterApp("mainmenu")
		end,
		Func_Scroll = function(level)
			if not TabMemory.GallerySelected then
				TabMemory.GallerySelected = 1
			end

			TabMemory.GallerySelected = TabMemory.GallerySelected + level
			local PhotoCount = #cachedgalleryimages

			if TabMemory.GallerySelected <= 0 then
				TabMemory.GallerySelected = PhotoCount
			elseif TabMemory.GallerySelected > PhotoCount then
				TabMemory.GallerySelected = 1
			end
		end,
		Func_Reload = function() end,
		Func_Draw = function(w, h)
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
				end

				surface.SetMaterial(k.thumbmat)
				surface.SetDrawColor(255, 255, 255)
				surface.DrawTexturedRect(x, y, sw, sh)
			end
		end,
	}

	Tabphone.Apps["gallery_viewer"] = {
		Name = "Image Viewer",
		Hidden = true,
		LeftText = "",
		Func_Enter = function() end,
		Func_Primary = function() end,
		Func_Secondary = function()
			EnterApp("gallery")
		end,
		Func_Reload = function() end,
		Func_Draw = function(w, h)
			local image = cachedgalleryimages[TabMemory.GallerySelected]

			if not image then return end
			if not image.material then image.material = Material("data/arcrp_photos/" .. image.filename) end

			surface.SetMaterial(image.material)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRect(0, 0, 512, 512)
		end,
	}

	function SWEP:PreDrawViewModel(vm, wep, ply)
		render.PushRenderTarget(tex)
		cam.Start2D()
		surface.SetDrawColor(COL_FG)
		surface.DrawRect(0, 0, 512, 512)
		local active = TabMemory.ActiveApp
		local activeapp = Tabphone.Apps[active]
		activeapp.Func_Draw(405, 512)
		local blah = ColorAlpha(COL_FG, math.Clamp(math.Remap(CurTime(), TabMemory.PageSwitchTime or 0, (TabMemory.PageSwitchTime or 0) + 0.2, 1, 0), 0, 1) * 255)
		surface.SetDrawColor(blah)
		surface.DrawRect(0, 48, 512, 512 - 32 - 8)
		surface.SetDrawColor(COL_BG)
		surface.DrawRect(0, 0, 512, 48)
		surface.SetDrawColor(COL_FG)
		surface.SetMaterial(IMAGE_BATTERY)
		surface.DrawTexturedRect(BARRIER_FLIPPHONE - 8 - 64, 8, 64, 32)
		--draw.SimpleText( "24%", "Tabphone16", BARRIER_FLIPPHONE-8-64+10, 14, COL_FG, TEXT_ALIGN_RIGHT )
		surface.SetDrawColor(COL_FG)
		surface.SetMaterial(IMAGE_CELL)
		surface.DrawTexturedRect(8, 8, 32, 32)
		--draw.SimpleText( "OTER", "Tabphone16", 8+32+4, 14, COL_FG )
		local TimeString

		-- 24 hr
		local colon = ":"

		if math.floor(CurTime()) % 2 == 0 then
			colon = " "
		end

		if false then
			TimeString = os.date("%H" .. colon .. "%M", Timestamp)
		else
			TimeString = os.date("%I" .. colon .. "%M %p", Timestamp)

			if TimeString:Left(1) == "0" then
				TimeString = TimeString:Right(-2)
			end
		end

		draw.SimpleText(TimeString, "Tabphone24", BARRIER_FLIPPHONE / 2, 10, COL_FG, TEXT_ALIGN_CENTER)
		surface.SetDrawColor(COL_BG)
		surface.DrawRect(0, 512 - 32 - 8, 512, 32 + 8)
		--surface.DrawRect( 0, 512-4, 512, 4 )
		draw.SimpleText(activeapp.LeftText or "SELECT", "Tabphone28", 4, 512 - 32 - 4, COL_FG)
		draw.SimpleText(activeapp.RightText or "BACK", "Tabphone28", BARRIER_FLIPPHONE - 4, 512 - 32 - 4, COL_FG, TEXT_ALIGN_RIGHT)
		cam.End2D()
		render.PopRenderTarget()
		render.MaterialOverrideByIndex(1, myMat)
	end

	function SWEP:PostDrawViewModel(vm, ply, wep)
		render.MaterialOverrideByIndex(1, nil)
	end
end

function SWEP:PrimaryAttack()
	self:QuickAnim("left")
	self:Keypress()
	self:EmitSound("fesiug/tabphone/yea.ogg", 70, 100, 1, CHAN_STATIC)

	if CLIENT and IsFirstTimePredicted() then
		local active = TabMemory.ActiveApp
		Tabphone.Apps[active].Func_Primary()
	end
end

function SWEP:SecondaryAttack()
	self:QuickAnim("right")
	self:Keypress()
	self:EmitSound("fesiug/tabphone/nae.ogg", 70, 100, 1, CHAN_STATIC)

	if CLIENT and IsFirstTimePredicted() then
		local active = TabMemory.ActiveApp
		Tabphone.Apps[active].Func_Secondary()
	end
end

function SWEP:Deploy()
	self:QuickAnim("open")
	self:EmitSound("fesiug/tabphone/draw.ogg", 70, 100, 1)

	if CLIENT and IsFirstTimePredicted() then
		TabMemory.ActiveApp = "mainmenu"
	end

	return true
end

if CLIENT then
	hook.Add("PlayerBindPress", "Tabphone_Scroll", function(ply, bind, pressed)
		if ply:GetActiveWeapon():IsValid() and ply:GetActiveWeapon():GetClass() == "testphone" then
			local block = nil

			if pressed and bind == "invnext" then
				block = 1
			elseif pressed and bind == "invprev" then
				block = -1
			end

			if block then
				local active = TabMemory.ActiveApp
				Tabphone.Apps[active].Func_Scroll(block)
				ply:GetActiveWeapon():Keypress()
				-- It'd be nice to also animate the VM, but this is a clientside hook.

				return true
			end
		end
	end)

	hook.Add("PreRender", "TabPhone", function()
		local wpn = LocalPlayer():GetActiveWeapon()

		if wpn.IsTabPhone then
			local activeapp = Tabphone.Apps[TabMemory.ActiveApp]
			if activeapp.Func_DrawScene then
				activeapp.Func_DrawScene()
			end
		end
	end)
end