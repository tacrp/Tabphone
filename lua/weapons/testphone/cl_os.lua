local tex = GetRenderTargetEx("TabPhoneRT8", 512, 512, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE, bit.bor(2, 256), 0, IMAGE_FORMAT_BGR888)

local myMat = CreateMaterial("TabPhoneRTMat8", "UnlitGeneric", {
    ["$basetexture"] = tex:GetName(),
})

local COL_FG = Color(76, 104, 79)
local COL_BG = color_black

local sizes = {48, 32, 28, 24, 22, 16}

for i, v in pairs(sizes) do
    surface.CreateFont("TabPhone" .. v, {
        font = "HD44780A00 5x8 Regular",
        size = v,
        antialias = false,
    })
end

local BARRIER_FLIPPHONE = 404
local IMAGE_BATTERY = Material("fesiug/TabPhone/battery.png")
local IMAGE_CELL = Material("fesiug/TabPhone/cell2.png")

TabMemory = TabMemory or {
    ActiveApp = false,
    --GallerySelected = 1,
    SelectedSetting = 1,
    Flash = false,
    NextPhotoTime = 0,
    TotalScroll = 0,
    SelectedPlayer = 1,
    TotalScrollContacts = 0,
	CallEndTime = math.huge,
	YouDial = "",
}

function TabPhone.EnterApp(name)
    local from = TabMemory.ActiveApp
    TabMemory.ActiveApp = name
    TabMemory.PageSwitchTime = UnPredictedCurTime()
    local active = TabMemory.ActiveApp
    TabPhone.Apps[active].Func_Enter(from)
end


function TabPhone.Scroll(level, var, total)
    if not TabMemory[var] then
        TabMemory[var] = 1
    end

    TabMemory[var] = TabMemory[var] + level
    local Appcount = total

    if TabMemory[var] <= 0 then
        TabMemory[var] = Appcount
    elseif TabMemory[var] > Appcount then
        TabMemory[var] = 1
    end
end

function SWEP:PreDrawViewModel(vm, wep, ply)
	TabMemory.LeftText = "SELECT"
	TabMemory.RightText = "BACK"

    render.PushRenderTarget(tex)
    cam.Start2D()
    surface.SetDrawColor(COL_FG)
    surface.DrawRect(0, 0, 512, 512)
    local active = TabMemory.ActiveApp
    local activeapp = TabPhone.Apps[active]
    activeapp.Func_Draw(405, 512)
    local blah = ColorAlpha(COL_FG, math.Clamp(math.Remap(UnPredictedCurTime(), TabMemory.PageSwitchTime or 0, (TabMemory.PageSwitchTime or 0) + 0.2, 1, 0), 0, 1) * 255)
    surface.SetDrawColor(blah)
    surface.DrawRect(0, 48, 512, 512 - 32 - 8)
    surface.SetDrawColor(COL_BG)
    surface.DrawRect(0, 0, 512, 48)
    surface.SetDrawColor(COL_FG)
    surface.SetMaterial(IMAGE_BATTERY)
    surface.DrawTexturedRect(BARRIER_FLIPPHONE - 8 - 64, 8, 64, 32)
    --draw.SimpleText( "24%", "TabPhone16", BARRIER_FLIPPHONE-8-64+10, 14, COL_FG, TEXT_ALIGN_RIGHT )
    surface.SetDrawColor(COL_FG)
    surface.SetMaterial(IMAGE_CELL)
    surface.DrawTexturedRect(8, 8, 32, 32)
    --draw.SimpleText( "OTER", "TabPhone16", 8+32+4, 14, COL_FG )
    local TimeString

    -- 24 hr
    local colon = ":"

    if math.floor(UnPredictedCurTime()) % 2 == 0 then
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

    draw.SimpleText(TimeString, "TabPhone24", BARRIER_FLIPPHONE / 2, 10, COL_FG, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(COL_BG)
    surface.DrawRect(0, 512 - 32 - 8, 512, 32 + 8)
    --surface.DrawRect( 0, 512-4, 512, 4 )
    draw.SimpleText(TabMemory.LeftText or "SELECT", "TabPhone28", 4, 512 - 32 - 4, COL_FG)
    draw.SimpleText(TabMemory.RightText or "BACK", "TabPhone28", BARRIER_FLIPPHONE - 4, 512 - 32 - 4, COL_FG, TEXT_ALIGN_RIGHT)
    cam.End2D()
    render.PopRenderTarget()
    render.MaterialOverrideByIndex(1, myMat)
end

function SWEP:PostDrawViewModel(vm, ply, wep)
    render.MaterialOverrideByIndex(1, nil)
end

function SWEP:Think()

	--print( TabMemory.CallStatus, TabMemory.CallStatus, TabMemory.CallStatus, TabMemory.CallStatus )

    if TabMemory.NextPhotoTime > UnPredictedCurTime() then return end

    --local dlight = DynamicLight( self:GetOwner():EntIndex() )
    --if ( dlight ) then
    --    dlight.pos = self:GetOwner():EyePos()
    --    dlight.r = COL_FG.r
    --    dlight.g = COL_FG.g
    --    dlight.b = COL_FG.b
    --    dlight.brightness = 0.1
    --    dlight.decay = 1024
    --    dlight.size = 128
    --    dlight.dietime = UnPredictedCurTime() + 1
    --end
end