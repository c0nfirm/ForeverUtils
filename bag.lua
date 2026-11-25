local addonName, addon = ...
addon.Modules.Bag = {}
local module = addon.Modules.Bag
local RestoreCombPos
local RestoreRegPos
local RestoreKeyPos

module.Enabled = ForeverUtillsDB.BagEnabled

--- Speicher Taschen + schloss --
ForeverUtillsDB.BagWindowPos = ForeverUtillsDB.BagWindowPos or {}
ForeverUtillsDB.BagWindowLock = ForeverUtillsDB.BagWindowLock or {}

function module.Enable()
    module.Enabled = true
end
function module.Disable()
    module.Enabled = false
end

local function MakeBagMove (frame, storageKey)
    if not frame then
        return
    end

    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)

    local function IsLocked()
        ForeverUtillsDB.BagWindowLock = ForeverUtillsDB.BagWindowLock or {}
        return ForeverUtillsDB.BagWindowLock[storageKey] ~= false
    end

    local function RestorePos()
        ForeverUtillsDB.BagWindowPos = ForeverUtillsDB.BagWindowPos or {}
        local savePos = ForeverUtillsDB.BagWindowPos[storageKey]
        if savePos then
            frame:ClearAllPoints()
            frame:SetPoint(
                "CENTER",
                UIParent,
                "CENTER",
                savePos.x,
                savePos.y
            )
        end
    end

    if storageKey == "CombinedBag" then
        RestoreCombPos = RestorePos
    elseif storageKey == "ReagentBag" then
        RestoreRegPos = RestorePos
    elseif storageKey == "Keyring" then
        RestoreKeyPos = RestorePos
    end

    frame:HookScript("OnShow", function()
        RestorePos()
    end)

    local lockBtn = CreateFrame("Button", nil, frame)
    lockBtn:SetSize(28, 28)
    lockBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22.5, 2.5)
    lockBtn:SetFrameStrata("TOOLTIP")
    lockBtn:SetFrameLevel(1000)
    lockBtn:Show()

    local function UpdateLockBtn()
        if IsLocked() then
            lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Locked-Up")
        else
            lockBtn:SetNormalTexture("Interface\\Buttons\\LockButton-Unlocked-Up")
        end
    end

    lockBtn:SetScript("OnClick", function()
        ForeverUtillsDB.BagWindowLock = ForeverUtillsDB.BagWindowLock or {}
        ForeverUtillsDB.BagWindowLock[storageKey] = not IsLocked()
        UpdateLockBtn()
    end)

    UpdateLockBtn()

    frame:HookScript("OnDragStart", function(self)
        if IsLocked() then
            return
        end

        self:StartMoving()
    end)

    frame:HookScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        
        local x, y = self:GetCenter()
        local centerX, centerY = UIParent:GetCenter()

        if x and y and centerX and centerY then
            ForeverUtillsDB.BagWindowPos = ForeverUtillsDB.BagWindowPos or {}
            ForeverUtillsDB.BagWindowPos[storageKey] = {
                x = x - centerX,
                y = y - centerY,
            }
        end
    end)

    local savePos = ForeverUtillsDB.BagWindowPos[storageKey]
    if savePos then
        frame:ClearAllPoints()
        frame:SetPoint(
            "CENTER",
            UIParent,
            "CENTER",
            savePos.x,
            savePos.y
        )
    end
end

local combinedFrame = ContainerFrameCombinedBags
if combinedFrame then
    MakeBagMove(combinedFrame, "CombinedBag")
    combinedFrame:HookScript("OnShow", function()
        if module.Enabled then
            OpenBag(5)
        end
    end)

    combinedFrame:HookScript("OnHide", function()
        if module.Enabled then
            CloseBag(5)
            CloseBag(KEYRING_CONTAINER)
        end
    end)
end

local regFrame = ContainerFrame6
if regFrame then
    MakeBagMove(regFrame, "ReagentBag")
end

local keyFrame = ContainerFrame2
if keyFrame then
    MakeBagMove(keyFrame, "Keyring")
end

hooksecurefunc("UpdateContainerFrameAnchors", function()
    if RestoreCombPos then
        RestoreCombPos()
    end
    if RestoreRegPos then
        RestoreRegPos()
    end
    if RestoreKeyPos then
        RestoreKeyPos()
    end
end)