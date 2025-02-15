SWEP.Base = "weapon_base"
SWEP.Spawnable = true
SWEP.ViewModel = "models/fesiug/TabPhone_2.mdl"
SWEP.ViewModelFOV = 44
SWEP.WorldModel = "models/weapons/w_camphone.mdl"
SWEP.PrintName = "TabPhone"
SWEP.BobScale = 0.1
SWEP.SwayScale = 0.1
SWEP.Slot = -99999
SWEP.Primary.ClipSize = -1
SWEP.Primary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.Ammo = ""
SWEP.IsTabPhone = true
AddCSLuaFile()
TabPhone = TabPhone or {}

local searchdir = "weapons/testphone"

local function autoinclude(dir)
	local files, dirs = file.Find(searchdir .. "/*.lua", "LUA")

	for _, filename in pairs(files) do
		if filename == "shared.lua" then continue end
		local luatype = string.sub(filename, 1, 2)

		if luatype == "sv" then
			if SERVER then
				include(dir .. "/" .. filename)
			end
		elseif luatype == "cl" then
			AddCSLuaFile(dir .. "/" .. filename)

			if CLIENT then
				include(dir .. "/" .. filename)
			end
		else
			AddCSLuaFile(dir .. "/" .. filename)
			include(dir .. "/" .. filename)
		end
	end

	for _, path in pairs(dirs) do
		autoinclude(dir .. "/" .. path)
	end
end

autoinclude(searchdir)

function SWEP:GetTabPhoneVolume()
	local vol = self:GetOwner():GetInfoNum("tabphone_volume", 5)

	return vol / 10
end

function SWEP:QuickAnim(name)
	local vm = self:GetOwner():GetViewModel()
	vm:SetPlaybackRate(1)
	vm:SendViewModelMatchingSequence(vm:LookupSequence(name))
end

function SWEP:Keypress()
	self:EmitSound("fesiug/tabphone/key_press" .. math.random(1, 7) .. ".wav", 40, 100, 0.4)
end

function SWEP:PrimaryAttack()
	self:QuickAnim("left")
	self:Keypress()
	self:EmitSound("fesiug/tabphone/yea.ogg", 40, 100, self:GetTabPhoneVolume(), CHAN_STATIC)

	if CLIENT and IsFirstTimePredicted() then
		local active = TabMemory.ActiveApp
		local activeapp = TabPhone.Apps[active]

		if activeapp and activeapp.Func_Primary then
			TabPhone.Apps[active].Func_Primary()
		end
	end
end

function SWEP:SecondaryAttack()
	self:QuickAnim("right")
	self:Keypress()
	self:EmitSound("fesiug/tabphone/nae.ogg", 40, 100, self:GetTabPhoneVolume(), CHAN_STATIC)

	if CLIENT and IsFirstTimePredicted() then
		local active = TabMemory.ActiveApp
		local activeapp = TabPhone.Apps[active]

		if activeapp and activeapp.Func_Secondary then
			TabPhone.Apps[active].Func_Secondary()
		end
	end
end

function SWEP:Reload()
	if not self:GetOwner():KeyPressed(IN_RELOAD) then return end
	self:QuickAnim("reload")
	self:Keypress()

	if CLIENT and IsFirstTimePredicted() then
		local active = TabMemory.ActiveApp
		local activeapp = TabPhone.Apps[active]

		if activeapp and activeapp.Func_Reload then
			TabPhone.Apps[active].Func_Reload()
		end
	end
end

function SWEP:Deploy()
	self:QuickAnim("open")
	self:EmitSound("fesiug/tabphone/draw.ogg", 60, 100, 1)
	self:SetHoldType("slam")

	if CLIENT and IsFirstTimePredicted() then
		if not TabMemory.ActiveApp then
			TabMemory.ActiveApp = "mainmenu"
		end
	end

	return true
end

function SWEP:Holster()
	if CLIENT and IsFirstTimePredicted() then
		local active = TabMemory.ActiveApp
		local activeapp = TabPhone.Apps[active]

		if activeapp and activeapp.Func_Holster then
			activeapp.Func_Holster()
		end
	end

	return true
end

if CLIENT then
	hook.Add("PlayerBindPress", "TabPhone_Scroll", function(ply, bind, pressed)
		local w = ply:GetActiveWeapon()

		if w:IsValid() and w:GetClass() == "testphone" then
			local block = nil
			local numb

			if pressed then
				if bind == "invnext" then
					block = 1
					-- w:QuickAnim("scdown")
				elseif bind == "invprev" then
					block = -1
				elseif bind == "slot1" then
					-- w:QuickAnim("scup")
					numb = 1
				elseif bind == "slot2" then
					numb = 2
				elseif bind == "slot3" then
					numb = 3
				elseif bind == "slot4" then
					numb = 4
				elseif bind == "slot5" then
					numb = 5
				elseif bind == "slot6" then
					numb = 6
				elseif bind == "slot7" then
					numb = 7
				elseif bind == "slot8" then
					numb = 8
				elseif bind == "slot9" then
					numb = 9
				elseif bind == "slot0" then
					numb = 0
				end
			end

			local active = TabMemory.ActiveApp
			local activeapp = TabPhone.Apps[active]

			if block then
				-- It'd be nice to also animate the VM, but this is a clientside hook.
				if activeapp.Func_Scroll then
					activeapp.Func_Scroll(block)
					w:Keypress()

					return true
				end
			elseif numb then
				if active == "dialer" then
					w:Keypress()
					w:EmitSound("fesiug/tabphone/dialtone/" .. tostring(numb) .. ".ogg", 70, 100, 0.5 * TabPhone.GetVolume(), CHAN_STATIC)
					TabMemory.YouDial = TabMemory.YouDial .. tostring(numb)

					return true
				end
			end
		end
	end)

	hook.Add("PreRender", "TabPhone", function()
		local wpn = LocalPlayer():GetActiveWeapon()

		if wpn.IsTabPhone then
			local activeapp = TabPhone.Apps[TabMemory.ActiveApp]

			if activeapp and activeapp.Func_DrawScene then
				activeapp.Func_DrawScene()
			end
		end
	end)
end

TabPhone.RingtonePath = "fesiug/tabphone/ringtones/44khz/"

TabPhone.Notiftones = {"notifs/textring.ogg", "notifs/textring2.ogg", "notifs/textring3.ogg", "notifs/textring4.ogg", "notifs/textring5.ogg", "notifs/Text.ogg", "notifs/sfx_sms.ogg",}

TabPhone.Ringtones = {"Standard Ring.ogg", "arab.ogg", "butterfly.ogg", "americafyeah.ogg", "amongla.ogg", "angrybirds.ogg", "duvet.ogg", "edgy.ogg", "gutsberserk.ogg", "russian.ogg", "tailsofvalor.ogg", "themanwhosoldtheworld.ogg", "1.6.ogg", "valve.ogg", "clockring.ogg", "callring3_franklin.ogg", "callring6_michael.ogg", "callring8_trevor.ogg", "109.ogg", "Cool Room.ogg", "Countryside.ogg", "Credit Check.ogg", "Dragon Brain.ogg", "Drive.ogg", "Fox.ogg", "Funk in Time.ogg", "Hooker.ogg", "Katja's Waltz.ogg", "Malfunction.ogg", "Pager.ogg", "cowboy.ogg", "johncena.ogg", "persona.ogg"}

-- GTA 5
--"callring.ogg",
--"callring2.ogg",
--"callring4.ogg",
--"callring5.ogg",
--"callring7.ogg",
-- GTA 4
function TabPhone.GetRingtonePath()
	return TabPhone.RingtonePath .. TabPhone.Ringtones[GetConVar("tabphone_ringtone"):GetInt()]
end

function TabPhone.GetNotiftonePath()
	return TabPhone.RingtonePath .. TabPhone.Notiftones[GetConVar("tabphone_notiftone"):GetInt()]
end

function TabPhone.PlayNotiftone()
	LocalPlayer():EmitSound(TabPhone.GetNotiftonePath(), 100, 100, TabPhone.GetVolume(), CHAN_STATIC)
end

function TabPhone.StartRingtone()
	LocalPlayer():EmitSound(TabPhone.GetRingtonePath(), 100, 100, TabPhone.GetVolume(), CHAN_STATIC)
end

function TabPhone.EndRingtone()
	LocalPlayer():StopSound(TabPhone.GetRingtonePath())
end

local vmposes = { vector_origin, Vector( -0.9, -1.5, 0.4 ), Vector( -1.5, 0, 0 ), Vector( -2, -1.5, 0.4 ) }

function SWEP:GetViewModelPosition(pos, ang)
	local mover = vmposes[GetConVar("tabphone_vmpos"):GetInt()]
	pos:Add(mover.x * ang:Right())
	pos:Add(mover.y * ang:Forward())
	pos:Add(mover.z * ang:Up())
	-- ang:RotateAroundAxis( ang:Right(), 0 )
	-- ang:RotateAroundAxis( ang:Forward(), 0 )
	-- ang:RotateAroundAxis( ang:Up(), 0 )

	return pos, ang
end