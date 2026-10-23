local addon = CreateFrame("Frame")
ForeverUtills.Modules = ForeverUtills.Modules or {}
ForeverUtills.Modules.Aggro = {}
local module = ForeverUtills.Modules.Aggro

--=================================
-- AggroColor
-- for wow Forever
-- /run print(select(4, GetBuildInfo())) to find interface number
-- green  = full Aggro
-- yellow = aggro but others close in
-- orange = close to loose aggro
-- red    = no aggro
--==================================

local COLORS = {
    GREEN = {0.10, 1.00, 0.10},     --full aggro
    YELLOW = {1.00, 0.90, 0.00},    --someone getting close
    ORANGE = {1.00, 0.55, 0.00},    --nearly lost
    RED = {1.00, 0.10, 0.10},       --no aggro
    GREY = {0.50, 0.50, 0.50},      --not pulled
}

local function SetBarColor(healthBar, color)
    if not healthBar then
        return
    end

    healthBar:SetStatusBarColor(
        color[1],
        color[2],
        color[3],
        1
    )

end

local function UpdateNameplate(namePlate)
    if not ForeverUtillsDB.AggroEnabled then
        return
    end

    if not namePlate then
        return
    end

    local unitFrame = namePlate.UnitFrame
    if not unitFrame then
        return
    end
    
    local unit = unitFrame.unit
    if not unit or not UnitExists(unit) then
        return
    end

    -- Only enemy plates
    if UnitIsPlayer(unit) then
        return
    end

    if not UnitCanAttack("player", unit) then
        return
    end

    local healthBar = unitFrame.healthBar
    if not healthBar then 
        return
    end

    -- get threat leveln info
    local status = UnitThreatSituation("player", unit)
    
    -- get mob targeting info
    local target = unit .. "target"
    local hasTarget = UnitExists(target)
    local isTargetingPlayer = UnitIsUnit(target, "player")
    local isTargetingGroupMember = hasTarget and UnitIsPlayer(target) and (UnitInParty(target) or UnitInRaid(target))

    -- get player role info
    local role = UnitGroupRolesAssigned("player")
    local isTank = (role == "TANK")

    --====================================================
    -- Threat Levels
    -- nil = no entry
    -- 0 = low
    -- 1 = hight
    -- 2 = primary but not highest threat
    -- 3 = primary and higest threat
    --====================================================

    if isTank then
        --==================
        -- Tank: Keep Aggro
        --==================
        
        -- full aggro
        if isTargetingPlayer and status == 3 then
            SetBarColor(healthBar, COLORS.GREEN)
        -- Primary but not higest
        elseif isTargetingPlayer and  status == 2 then
            SetBarColor(healthBar, COLORS.YELLOW)
        -- not Primary but high
        elseif isTargetingPlayer and status == 1 then
            SetBarColor(healthBar, COLORS.ORANGE)
        -- no aggro
        elseif isTargetingGroupMember then
            SetBarColor(healthBar, COLORS.RED)
        -- not pulled
        else
            SetBarColor(healthBar, COLORS.GREY)
        end
    
    else
        --=====================
        -- DD/Heal: Evade Aggro
        --=====================
        
        -- no aggro
        if isTargetingGroupMember and status == 0 then
            SetBarColor(healthBar, COLORS.GREEN)
        -- low aggro
        elseif isTargetingGroupMember and  status == 1 then
            SetBarColor(healthBar, COLORS.YELLOW)
        -- close to pull aggro
        elseif isTargetingGroupMember and status == 2 then
            SetBarColor(healthBar, COLORS.ORANGE)
        -- you have aggro
        elseif isTargetingPlayer then
            SetBarColor(healthBar, COLORS.RED)
        -- not pulled
        else
            SetBarColor(healthBar, COLORS.GREY)
        end
    end
end

local function UpdateAllNameplate()
    if not C_NamePlate or not C_NamePlate.GetNamePlates then
        return
    end

    local plates = C_NamePlate.GetNamePlates()

    for _, namePlate in ipairs(plates) do
        UpdateNameplate(namePlate)
    end
end

--=================
--Nameplate Events
--=================

local function EnableAggro()
    addon:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    addon:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    addon:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
    addon:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
    addon:RegisterEvent("PLAYER_TARGET_CHANGED")

    addon:SetScript("OnUpdate", AggroOnUpdate)
end

local function DisableAggro()
    addon:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
    addon:UnregisterEvent("NAME_PLATE_UNIT_REMOVED")
    addon:UnregisterEvent("UNIT_THREAT_LIST_UPDATE")
    addon:UnregisterEvent("UNIT_THREAT_SITUATION_UPDATE")
    addon:UnregisterEvent("PLAYER_TARGET_CHANGED")

    addon:SetScript("OnUpdate", nil)
end

module.Enable = EnableAggro
module.Disable = DisableAggro

if ForeverUtillsDB.AggroEnabled then
    module.Enable()
end

addon:SetScript("OnEvent", function(self, event, ...)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...

        -- wait for blizz init
        C_Timer.After(0, function()
            if unit and UnitExists(unit) then
                for _, namePlate in ipairs(C_NamePlate.GetNamePlates()) do
                    if namePlate.UnitFrame
                        and namePlate.UnitFrame.unit == unit then
                
                        UpdateNameplate(namePlate)
                        break
                    end
                end
            end
        end)
    else
        UpdateAllNameplate()
    end 
end)

--=========================================
-- cyclic updates
-- bc forever client sometimes laggs behind
--=========================================

local elapsed = 0

local function AggroOnUpdate(self, delta)
    elapsed = elapsed + delta

    -- 10 updates per second
    if elapsed >= 0.10 then
        elapsed = 0
        UpdateAllNameplate()
    end
end