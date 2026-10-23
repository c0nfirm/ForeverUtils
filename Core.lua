local addonName, addon = ...
ForeverUtills = addon
addon.Modules = {}
ForeverUtillsDB = ForeverUtillsDB or {}

if ForeverUtillsDB.AggroEnabled == nil then
    ForeverUtillsDB.AggroEnabled = true
end
if ForeverUtillsDB.ItemCountEnabled == nil then
    ForeverUtillsDB.ItemCountEnabled = true
end

-- Settings --
local category = Settings.RegisterVerticalLayoutCategory("ForeverUtills")

aggroSetting = Settings.RegisterAddOnSetting(
    category,
    "ForeverUtillsDB_AggroEnabled",
    "AggroEnabled",
    ForeverUtillsDB,
    Settings.VarType.Boolean,
    "Aggro Nameplates",
    false
)

Settings.CreateCheckbox(
    category,
    aggroSetting,
    "Nameplate color according to threat."
)

aggroSetting:SetValue(ForeverUtillsDB.AggroEnabled)

aggroSetting:SetValueChangedCallback(function(_, value)
    ForeverUtillsDB.AggroEnabled = value

    if value then
        addon.Modules.Aggro.Enable()
    else
        addon.Modules.Aggro.Disable()
    end
end)

C_Timer.After(0, function()
    aggroSetting:SetValue(ForeverUtillsDB.AggroEnabled)
end)

local itemCountSetting = Settings.RegisterAddOnSetting(
    category,
    "ForeverUtills_ItemCountEnabled",
    "ItemCountEnabled",
    ForeverUtillsDB,
    Settings.VarType.Boolean,
    "Item Count",
    true
)

Settings.CreateCheckbox(
    category,
    itemCountSetting,
    "Show item counts in tooltips."
)

itemCountSetting:SetValue(ForeverUtillsDB.ItemCountEnabled)
itemCountSetting:SetValueChangedCallback(function(_, value)
    ForeverUtillsDB.ItemCountEnabled = value

    if value then
        addon.Modules.ItemCount.Enable()
    else
        addon.Modules.ItemCount.Disable()
    end
end)

C_Timer.After(0, function()
    itemCountSetting:SetValue(ForeverUtillsDB.ItemCountEnabled)
end)

Settings.RegisterAddOnCategory(category)