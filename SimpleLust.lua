local frame = CreateFrame("Frame", "SimpleLustFrame", UIParent)
frame:SetSize(200, 40)
frame:SetPoint("CENTER")
frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.text:SetPoint("CENTER")
frame:SetPoint("TOP", UIParent, "TOP", 0, -60)
frame.text:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")

-- Colors
local COLOR_LUSTING = "|cffffff00"   -- yellow
local COLOR_SATED   = "|cffff0000"   -- red
local COLOR_READY   = "|cff00ff00"   -- green (unchanged)
local COLOR_END     = "|r"

local LUST_BUFFS = {
    [2825] = true,
    [32182] = true,
    [80353] = true,
    [264667] = true,
    [390386] = true,
}

local LUST_DEBUFFS = {
    [57723] = true,
    [57724] = true,
    [80354] = true,
    [264689] = true,
    [390435] = true,
    [160455] = true,
    [357745] = true,
}

local function GetAuraTimeValue(list)
    local found = false
    for spellID in pairs(list) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if aura and aura.expirationTime and aura.expirationTime > 0 then
            found = true
            return aura.expirationTime - GetTime()
        end
    end

    if not found then
        return nil
    end
end

local function DeriveBuffTime()
    local buffTime = GetAuraTimeValue(LUST_BUFFS)
    if buffTime and buffTime > 0 then
        return buffTime
    end

    local debuffTime = GetAuraTimeValue(LUST_DEBUFFS)
    if debuffTime and debuffTime > 0 then
        local t = debuffTime - 560
        if t > 0 then
            return t
        end
    end

    return nil
end

local function FormatTime(sec)
    local minutes = math.floor(sec / 60)
    local seconds = math.floor(sec % 60)
    return string.format("%d:%02d", minutes, seconds)
end


local function UpdateLustStatus()
    local buffTime = DeriveBuffTime()
    local debuffTime = GetAuraTimeValue(LUST_DEBUFFS)

    if buffTime and buffTime > 0 then
        frame.text:SetText(COLOR_LUSTING .. "Lusting for " .. math.floor(buffTime) .. "s" .. COLOR_END)
    elseif debuffTime and debuffTime > 0 then
        frame.text:SetText(COLOR_SATED .. "Lust in " .. FormatTime(math.floor(debuffTime)) .. COLOR_END)
    else
        frame.text:SetText(COLOR_READY .. "Lust Ready" .. COLOR_END)
    end
end

frame:SetScript("OnEvent", UpdateLustStatus)
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

C_Timer.NewTicker(0.2, UpdateLustStatus)
C_Timer.After(0.1, UpdateLustStatus)