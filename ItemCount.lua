local addonName, addon = ...
addon.Modules.ItemCount = {}
local module = addon.Modules.ItemCount

local characterKey = UnitName("player") .. "-" .. GetRealmName()
ForeverUtillsDB.ItemCountBankCache = ForeverUtillsDB.ItemCountBankCache or {}
ForeverUtillsDB.ItemCountBankCache[characterKey] =
    ForeverUtillsDB.ItemCountBankCache[characterKey] or {}

module.Enabled = ForeverUtillsDB.ItemCountEnabled

function module.Enable()
    module.Enabled = true
end

function module.Disable()
    module.Enabled = false
end

local function CountBags()
    local total = 0

    for bag = 0, 5 do
        local slots = C_Container.GetContainerNumSlots(bag)

        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)

            if itemID then
                local info = C_Container.GetContainerItemInfo(bag, slot)

                if info and info.stackCount then
                    total = total + info.stackCount
                end
            end
        end
    end

    return total
end
addon.Modules.ItemCount.CountBags = CountBags

local function CountItemInBags(itemID)
    local total = 0

    for bag = 0, 5 do
        local slots = C_Container.GetContainerNumSlots(bag)

        for slot = 1, slots do
            local slotItemID = C_Container.GetContainerItemID(bag, slot)

            if slotItemID == itemID then
                local info = C_Container.GetContainerItemInfo(bag, slot)

                if info and info.stackCount then
                    total = total + info.stackCount
                end
            end
        end
    end

    return total
end
addon.Modules.ItemCount.CountItemInBags = CountItemInBags

local function CountItemInBank(itemID)
    local cache = ForeverUtillsDB.ItemCountBankCache[characterKey]

    if not BankFrame:IsShown() then
        return cache[itemID] or 0
    end
    
    local total = 0

    for bag = 6, 14 do
        local slots = C_Container.GetContainerNumSlots(bag)

        for slot = 1, slots do
            local slotItemID = C_Container.GetContainerItemID(bag, slot)

            if slotItemID == itemID then
                local info = C_Container.GetContainerItemInfo(bag, slot)

                if info and info.stackCount then
                    total = total + info.stackCount
                end
            end
        end
    end

    return total
end

local function UpdateBankChache()
    ForeverUtillsDB.ItemCountBankCache = ForeverUtillsDB.ItemCountBankCache or {}
    ForeverUtillsDB.ItemCountBankCache[characterKey] =
        ForeverUtillsDB.ItemCountBankCache[characterKey] or {}

    local cache = ForeverUtillsDB.ItemCountBankCache[characterKey]

    -- clean old cache
    wipe(cache)

    for bag = 6, 14 do
        local slots = C_Container.GetContainerNumSlots(bag)    
        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)
            if itemID then
                local info = C_Container.GetContainerItemInfo(bag, slot)
                if info and info.stackCount then
                    cache[itemID] = (cache[itemID] or 0) + info.stackCount
                end
            end
        end
    end
end

local bankEventFrame = CreateFrame("Frame")
bankEventFrame:RegisterEvent("BANKFRAME_OPENED")
bankEventFrame:SetScript("OnEvent", function(self, event)
    if event == "BANKFRAME_OPENED" then
        C_Timer.After(0, function()
            UpdateBankChache()
        end)
    end
end)

addon.Modules.ItemCount.CountItemInBank = CountItemInBank

local function CountItemOwned(itemID)
    local bags = CountItemInBags(itemID)
    local bank = CountItemInBank(itemID)

    return bags + bank
end
addon.Modules.ItemCount.CountItemOwned = CountItemOwned

local function CountBank()
    local total = 0

    for bag = 6, 14 do
        local slots = C_Container.GetContainerNumSlots(bag)

        for slot = 1, slots do
            local itemID = C_Container.GetContainerItemID(bag, slot)

            if itemID then
                local info = C_Container.GetContainerItemInfo(bag, slot)

                if info and info.stackCount then
                    total = total + info.stackCount
                end
            end
        end
    end

    return total
end
addon.Modules.ItemCount.CountBank = CountBank

GameTooltip:HookScript("OnUpdate", function(tooltip)
    if not module.Enabled then
        return
    end

    local _, itemLink = tooltip:GetItem()

    local owner = tooltip:GetOwner()
    if owner then
        local ownerName = owner:GetName()
        if ownerName then
            if ownerName:match("^CharacterBag%d+Slot$") then
                return
            end
            if ownerName:match("^CharacterReagentBag%d+Slot$") then
                return
            end
        end
    
        local parent = owner:GetParent()
        if parent then
            local grandParent = parent:GetParent()
            if parent == BankFrame and grandParent == UIParent then
                return
            end
        end
    end

    if not itemLink then
        tooltip.ItemCountItemID = nil
        return
    end

    local itemID = tonumber(itemLink:match("item:(%d+)"))
    if not itemID then
        return
    end
    if tooltip.ItemCountItemID == itemID then
        local found = false

        for i = 1, tooltip:NumLines() do
            local line = _G[tooltip:GetName() .. "TextLeft" .. i]

            if line and line:GetText() == "Total: " .. addon.Modules.ItemCount.CountItemOwned(itemID) then
                found = true
                break
            end
        end

        if found then
            return
        end
    end

    tooltip.ItemCountItemID = itemID

    local bags = addon.Modules.ItemCount.CountItemInBags(itemID)
    local bank = addon.Modules.ItemCount.CountItemInBank(itemID)
    local owned = addon.Modules.ItemCount.CountItemOwned(itemID)

    tooltip:AddLine("Total: " .. owned)
    tooltip:AddLine("In Bags: " .. bags)
    tooltip:AddLine("In Bank: " .. bank)
    tooltip:Show()
end)


GameTooltip:HookScript("OnHide", function(tooltip)
    tooltip.ItemCountItemID = nil
end)