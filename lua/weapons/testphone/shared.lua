SWEP.Base = "weapon_base"
SWEP.Spawnable = true
SWEP.ViewModel = "models/fesiug/TabPhone_2.mdl"
SWEP.ViewModelFOV = 44
SWEP.PrintName = "TabPhone"
SWEP.BobScale = 0.1
SWEP.SwayScale = 0.1

SWEP.Slot = -1

SWEP.Primary.ClipSize = -1
SWEP.Primary.Ammo = ""
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.Ammo = ""

SWEP.IsTabPhone = true

AddCSLuaFile()

TabPhone = {}

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

function SWEP:QuickAnim(name)
	local vm = self:GetOwner():GetViewModel()
	vm:SetPlaybackRate(1)
	vm:SendViewModelMatchingSequence(vm:LookupSequence(name))
end

function SWEP:Keypress()
	self:EmitSound("fesiug/TabPhone/key_press" .. math.random(1, 7) .. ".wav", 70, 100, 0.4)
end

function SWEP:PrimaryAttack()
	self:QuickAnim("left")
	self:Keypress()
	self:EmitSound("fesiug/TabPhone/yea.ogg", 70, 100, 1, CHAN_STATIC)

	if CLIENT and IsFirstTimePredicted() then
		local active = TabMemory.ActiveApp
		TabPhone.Apps[active].Func_Primary()
	end
end

function SWEP:SecondaryAttack()
	self:QuickAnim("right")
	self:Keypress()
	self:EmitSound("fesiug/TabPhone/nae.ogg", 70, 100, 1, CHAN_STATIC)

	if CLIENT and IsFirstTimePredicted() then
		local active = TabMemory.ActiveApp
		TabPhone.Apps[active].Func_Secondary()
	end
end

function SWEP:Reload()
	if !self:GetOwner():KeyPressed(IN_RELOAD) then return end
	self:QuickAnim("reload")
	self:Keypress()

	if CLIENT and IsFirstTimePredicted() then
		local active = TabMemory.ActiveApp
		TabPhone.Apps[active].Func_Reload()
	end
end

function SWEP:Deploy()
	self:QuickAnim("open")
	self:EmitSound("fesiug/TabPhone/draw.ogg", 70, 100, 1)

	if CLIENT and IsFirstTimePredicted() then
		TabMemory.ActiveApp = "mainmenu"
	end

	return true
end

if CLIENT then
	hook.Add("PlayerBindPress", "TabPhone_Scroll", function(ply, bind, pressed)
		local w = ply:GetActiveWeapon()
		if w:IsValid() and w:GetClass() == "testphone" then
			local block = nil

			if pressed then
				if bind == "invnext" then
					block = 1
					-- w:QuickAnim("scdown")
				elseif bind == "invprev" then
					block = -1
					-- w:QuickAnim("scup")
				elseif bind == "slot1" then
					TabMemory.YouDial = TabMemory.YouDial .. "1"
					block = true
				elseif bind == "slot2" then
					TabMemory.YouDial = TabMemory.YouDial .. "2"
					block = true
				elseif bind == "slot3" then
					TabMemory.YouDial = TabMemory.YouDial .. "3"
					block = true
				elseif bind == "slot4" then
					TabMemory.YouDial = TabMemory.YouDial .. "4"
					block = true
				elseif bind == "slot5" then
					TabMemory.YouDial = TabMemory.YouDial .. "5"
					block = true
				elseif bind == "slot6" then
					TabMemory.YouDial = TabMemory.YouDial .. "6"
					block = true
				elseif bind == "slot7" then
					TabMemory.YouDial = TabMemory.YouDial .. "7"
					block = true
				elseif bind == "slot8" then
					TabMemory.YouDial = TabMemory.YouDial .. "8"
					block = true
				elseif bind == "slot9" then
					TabMemory.YouDial = TabMemory.YouDial .. "9"
					block = true
				elseif bind == "slot0" then
					TabMemory.YouDial = TabMemory.YouDial .. "0"
					block = true
				end
			end

			local active = TabMemory.ActiveApp
			local activeapp = TabPhone.Apps[active]
			if block then
				-- It'd be nice to also animate the VM, but this is a clientside hook.
				if block == true and active == "dialer" then
					w:Keypress()
					return true
				end

				if block != true and activeapp.Func_Scroll then
					activeapp.Func_Scroll(block)
					w:Keypress()
					return true
				end
			end
		end
	end)

	hook.Add("PreRender", "TabPhone", function()
		local wpn = LocalPlayer():GetActiveWeapon()

		if wpn.IsTabPhone then
			local activeapp = TabPhone.Apps[TabMemory.ActiveApp]
			if activeapp.Func_DrawScene then
				activeapp.Func_DrawScene()
			end
		end
	end)
end