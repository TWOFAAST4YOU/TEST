local imageFolder = "backgrounds/"
local imageExtension = ".png"

local startIndex = 1
local endIndex = 1804
local currentIndex = startIndex
local changeInterval = 0.1 -- Change interval in seconds for smoother transitions
local nextChangeTime = CurTime() + changeInterval

local MenuGradient = Material("html/img/gradient.png", "nocull smooth")
local FreeMaterial = nil

local function CreateBackgroundMaterial(path)
    if (FreeMaterial) then
        FreeMaterial:SetDynamicImage(path)
        local ret = FreeMaterial
        FreeMaterial = nil
        return ret
    end
    return DynamicMaterial(path, "nocull smooth")
end

local function FreeBackgroundMaterial(mat)
    if (FreeMaterial) then
        MsgN("Warning! Menu shouldn't be releasing a material when one is already queued for use!")
    end
    FreeMaterial = mat
end

local Active = nil
local Outgoing = nil

local function Think(tbl)
    tbl.Angle = tbl.Angle + (tbl.AngleVel * FrameTime())
    tbl.Size = tbl.Size + ((tbl.SizeVel / tbl.Size) * FrameTime())

    if (tbl.AlphaVel) then
        tbl.Alpha = tbl.Alpha - tbl.AlphaVel * FrameTime()
    end

    if (tbl.DieTime > 0) then
        tbl.DieTime = tbl.DieTime - FrameTime()
        if (tbl.DieTime <= 0) then
            ChangeBackground()
        end
    end
end

local function Render(tbl)
    if (not tbl.mat) then return end

    surface.SetMaterial(tbl.mat)
    surface.SetDrawColor(255, 255, 255, tbl.Alpha)

    local w = ScrW() -- Adjusted width for better fit
    local h = ScrH() -- Adjusted height for better fit

    local x = ScrW() * 0.5
    local y = ScrH() * 0.5

    surface.DrawTexturedRectRotated(x, y, w, h, tbl.Angle)
end

local function ShouldBackgroundUpdate()
    return not IsInGame() and not IsInLoading()
end

function DrawBackground()
    if (ShouldBackgroundUpdate()) then
        if (Active) then
            Think(Active)
            Render(Active)
        end

        if (Outgoing) then
            Think(Outgoing)
            Render(Outgoing)
        end
    end

    surface.SetMaterial(MenuGradient)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
end

function ClearBackgroundImages()
    -- Dummy implementation to avoid errors
end

function AddBackgroundImage(img)
    -- Dummy implementation to avoid errors
    -- Assuming this function is not needed for the background update logic
end

local function GetImagePath(index)
    local formattedIndex = string.format("op_%010d", index) -- Format index to match the image naming convention
    local path = imageFolder .. formattedIndex .. imageExtension
    return path
end

function ChangeBackground()
    if (not ShouldBackgroundUpdate()) then return end -- Don't try to load new images while in-game or loading

    -- Handle outgoing background
    if (Outgoing) then
        FreeBackgroundMaterial(Outgoing.mat)
        Outgoing.mat = nil
    end

    Outgoing = Active
    if (Outgoing) then
        Outgoing.AlphaVel = 255
    end

    local imgPath = GetImagePath(currentIndex)
    local mat = CreateBackgroundMaterial(imgPath)
    if (not mat or mat:IsError()) then
        -- Suppress the error messages
        return
    end

    Active = {
        Ratio = 1, -- Use fixed ratio for simplicity
        Size = 1,
        Angle = 0,
        AngleVel = 0, -- No rotation for simplicity
        SizeVel = 0, -- No size change for simplicity
        Alpha = 255,
        DieTime = changeInterval, -- Use change interval to time the transition
        mat = mat,
        Name = imgPath
    }

    -- Increment the image index and loop back if necessary
    currentIndex = currentIndex + 1
    if (currentIndex > endIndex) then
        currentIndex = startIndex
    end
end

-- Create a timer to update the background image periodically
timer.Create("BackgroundImageUpdater", changeInterval, 0, ChangeBackground) -- Update every 'changeInterval' seconds

-- Hook the background drawing function to the HUDPaint event
hook.Add("HUDPaint", "DrawBackground", DrawBackground)
