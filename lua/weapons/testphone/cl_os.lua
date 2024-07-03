local tex = GetRenderTargetEx("TabPhoneRT8", 512, 512, RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE, bit.bor(2, 256), 0, IMAGE_FORMAT_BGR888)

local myMat = CreateMaterial("TabPhoneRTMat8", "UnlitGeneric", {
    ["$basetexture"] = tex:GetName(),
})

local COL_FG = Color(76, 104, 79)
local COL_BG = color_black

local sizes = {48, 32, 28, 24, 16}

for i, v in pairs(sizes) do
    surface.CreateFont("TabPhone" .. v, {
        font = "HD44780A00 5x8 Regular",
        size = v,
        antialias = false,
    })
    surface.CreateFont("TabPhone" .. v .. "B", {
        font = "HD44780A00 5x8 Regular",
        size = v,
        antialias = false,
    })
end

local BARRIER_FLIPPHONE = 404
local IMAGE_BATTERY = Material("fesiug/TabPhone/battery.png")
local IMAGE_CELL0 = Material("fesiug/TabPhone/cell0.png")
local IMAGE_CELL1 = Material("fesiug/TabPhone/cell1.png")
local IMAGE_CELL2 = Material("fesiug/TabPhone/cell2.png")
local IMAGE_CELL3 = Material("fesiug/TabPhone/cell3.png")

local SIGNAL_IMAGES = {IMAGE_CELL1, IMAGE_CELL2, IMAGE_CELL3}

TabMemory = TabMemory or {
    ActiveApp = "mainmenu",
    LastApp = false,
    --GallerySelected = 1,
    SelectedSetting = 1,
    Flash = false,
    NextPhotoTime = 0,
    TotalScroll = 0,
    SelectedPlayer = 1,
    TotalScrollContacts = 0,
    CallEndTime = math.huge,
    YouDial = "",
    CellSignal = 3,
    NextChangeSignal = 0,
    SelectedImageOption = 1,
    SelectedGame = 1,
    ProfilePictures = {},
    ProfilePicturesMats = {},
    MessageHistory = {},
    UnreadMessages = {},
    ContactsMode = "contacts",
    MessageScroll = 0,
    Has_Unread = false,
    TotalGameScroll = 0,
}

function TabPhone.EnterApp(name)
    local from = TabMemory.ActiveApp
    TabMemory.LastApp = from

    do
        local active = TabMemory.LastApp
        local activeapp = TabPhone.Apps[active]

        if activeapp and activeapp.Func_Leave then
            TabPhone.Apps[active].Func_Leave(name)
        end
    end

    TabMemory.ActiveApp = name
    TabMemory.PageSwitchTime = UnPredictedCurTime()
    local active = TabMemory.ActiveApp
    local activeapp = TabPhone.Apps[active]

    if activeapp and activeapp.Func_Enter then
        TabPhone.Apps[active].Func_Enter(from)
    end
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

local volumevar = GetConVar("tabphone_volume")

function TabPhone.GetVolume()
    return volumevar:GetInt() / 10
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
	if activeapp then
    	activeapp.Func_Draw(BARRIER_FLIPPHONE, 512)
	end
    local blah = ColorAlpha(COL_FG, math.Clamp(math.Remap(UnPredictedCurTime(), TabMemory.PageSwitchTime or 0, (TabMemory.PageSwitchTime or 0) + 0.2, 1, 0), 0, 1) * 255)
    surface.SetDrawColor(blah)
    surface.DrawRect(0, 48, 512, 512 - 32 - 8)
    surface.SetDrawColor(COL_BG)
    surface.DrawRect(0, 0, 512, 48)
    surface.SetDrawColor(COL_FG)
    surface.SetMaterial(IMAGE_BATTERY)
    surface.DrawTexturedRect(BARRIER_FLIPPHONE - 8 - 64, 8, 64, 32)
    surface.SetDrawColor(COL_FG)
    surface.SetMaterial(SIGNAL_IMAGES[TabMemory.CellSignal or 1])
    surface.DrawTexturedRect(8, 8, 32, 32)

    if (TabMemory.NextChangeSignal or 0) < CurTime() then
        TabMemory.CellSignal = math.random(1, #SIGNAL_IMAGES)
        TabMemory.NextChangeSignal = CurTime() + math.Rand(10, 30)
    end

    local TimeString
    local colon = ":"
    if math.floor(UnPredictedCurTime()) % 2 == 0 then
        colon = " "
    end

    if GetConVar("tabphone_24h"):GetBool() then
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