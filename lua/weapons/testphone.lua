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

	local myMat = CreateMaterial("TabphoneRTMat8", "UnlitGeneric", {
		["$basetexture"] = tex:GetName(),
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
		ActiveApp = "mainmenu"
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
		Func_Draw = function()
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
		Func_Draw = function()
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
		Func_Draw = function()
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
		Func_Draw = function()
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
		Func_Draw = function() end,
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
		Func_Draw = function()
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
		Func_Draw = function() end,
	}

	function SWEP:PreDrawViewModel(vm, wep, ply)
		render.PushRenderTarget(tex)
		cam.Start2D()
		surface.SetDrawColor(COL_FG)
		surface.DrawRect(0, 0, 512, 512)
		local active = TabMemory.ActiveApp
		Tabphone.Apps[active].Func_Draw()
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
		draw.SimpleText("SELECT", "Tabphone28", 4, 512 - 32 - 4, COL_FG)
		draw.SimpleText("BACK", "Tabphone28", BARRIER_FLIPPHONE - 4, 512 - 32 - 4, COL_FG, TEXT_ALIGN_RIGHT)
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
				local active = "mainmenu"
				Tabphone.Apps[active].Func_Scroll(block)
				ply:GetActiveWeapon():Keypress()
				-- It'd be nice to also animate the VM, but this is a clientside hook.

				return true
			end
		end
	end)
end