local addonName, addon = ...
addon.Modules.Bag = {}
local module = addon.Modules.Bag

module.Enabled = ForeverUtillsDB.BagEnabled

function module.Enable()
    module.Enabled = true
end

function module.Disable()
    module.Enabled = false
end

local function BagOpen()
    for bag = 0, 4 do 
        if IsBagOpen(bag) then
            return true
        end
    end
    return false
end

local function OpenRegBag()
    if not module.Enabled then
        return 
    end
    if BagOpen() then
        OpenBag(5)
    end
end

local function RegBagOpen()
    return IsBagOpen(5)
end

local function SynRegBag()
    if not module.Enabled then
        return
    end
    if BagOpen() then
        OpenBag(5)
    else
        CloseBag(5)    
    end
end

local isSyn = false
local function SynBags()
    if not module.Enabled then
        return
    end

    if isSyn then
        return
    end

    isSyn = true
    
    isSyn = false
end

local combinedFrame = ContainerFrameCombinedBags
if combinedFrame then
    combinedFrame:HookScript("OnShow", function ()
        if module.Enabled then
            OpenBag(5)
        end
    end)

    combinedFrame:HookScript("OnHide", function()
        if module.Enabled then
            CloseBag(5)
        end
    end)
end