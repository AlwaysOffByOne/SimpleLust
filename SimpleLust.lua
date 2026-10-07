local ADDON_NAME, addon = ...

local constants = addon.constants
local APPEARANCE_STATES = addon.appearanceStates
local STATE_BY_ID = addon.appearanceByID
local WORDING_BY_VALUE = addon.wordingByValue
local CUSTOM_SETTING_KEYS = addon.customSettingKeys

local frame = CreateFrame("Frame", "SimpleLustFrame", UIParent)
frame:SetSize(constants.frame.width, constants.frame.height)
frame:SetPoint(
    constants.frame.point,
    UIParent,
    constants.frame.point,
    constants.frame.x,
    constants.frame.y
)
frame:SetClampedToScreen(true)
frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
frame.text:SetPoint("CENTER")

local editMode = LibStub("FerrozEditModeLib-1.0")
local sharedMedia = LibStub("LibSharedMedia-3.0")
local currentDisplayState

local appliedSettings = addon.CreateDefaultCustomSettings()

local function Clamp(value, minimum, maximum)
    return math.min(maximum, math.max(minimum, value))
end

local function SetFontInstanceFont(fontInstance, fontPath, size, flags)
    if not fontInstance or not fontInstance.SetFont or not fontPath then
        return false
    end

    local ok, applied = pcall(fontInstance.SetFont, fontInstance, fontPath, size, flags)
    return ok and applied ~= false
end

local function ResolveFontPath(fontName)
    return sharedMedia:Fetch(sharedMedia.MediaType.FONT, fontName, true)
        or sharedMedia:Fetch(sharedMedia.MediaType.FONT, constants.font.defaultName)
end

local function CopyCustomSettings(source, destination)
    for _, key in ipairs(CUSTOM_SETTING_KEYS) do
        destination[key] = source[key]
    end
    return destination
end

local function SetAppliedValue(key, value)
    if appliedSettings[key] == value then
        return false
    end

    appliedSettings[key] = value
    return true
end

local function ApplyAppearance(stateID)
    local state = STATE_BY_ID[stateID]
    if not state then
        return
    end

    local fontName = appliedSettings[state.fontKey]
    local fontPath = ResolveFontPath(fontName)
    local fontSize = appliedSettings[state.sizeKey]

    if not SetFontInstanceFont(frame.text, fontPath, fontSize, constants.font.flags) then
        SetFontInstanceFont(
            frame.text,
            constants.font.defaultPath,
            fontSize,
            constants.font.flags
        )
    end

    frame.text:SetTextColor(
        appliedSettings[state.redKey],
        appliedSettings[state.greenKey],
        appliedSettings[state.blueKey]
    )
end

local function PreviewStateColor(stateID, red, green, blue)
    if currentDisplayState == stateID then
        frame.text:SetTextColor(red, green, blue)
    end
end

local function UpdateVisibility()
    if frame.isEditing or not appliedSettings.hideOutOfCombat or InCombatLockdown() then
        frame:Show()
    else
        frame:Hide()
    end
end

local function ApplyCustomSettings(settings)
    local changed = false
    local wording = WORDING_BY_VALUE[settings.wording] and settings.wording or "lust"

    changed = SetAppliedValue("hideOutOfCombat", settings.hideOutOfCombat == true) or changed
    changed = SetAppliedValue("wording", wording) or changed

    for _, state in ipairs(APPEARANCE_STATES) do
        local fontName = settings[state.fontKey]
        if type(fontName) ~= "string"
            or not sharedMedia:Fetch(sharedMedia.MediaType.FONT, fontName, true) then
            fontName = constants.font.defaultName
        end

        local size = tonumber(settings[state.sizeKey]) or constants.font.defaultSize
        size = Clamp(
            math.floor(size + 0.5),
            constants.font.minimumSize,
            constants.font.maximumSize
        )
        local red = Clamp(tonumber(settings[state.redKey]) or state.defaultColor.r, 0, 1)
        local green = Clamp(tonumber(settings[state.greenKey]) or state.defaultColor.g, 0, 1)
        local blue = Clamp(tonumber(settings[state.blueKey]) or state.defaultColor.b, 0, 1)

        changed = SetAppliedValue(state.fontKey, fontName) or changed
        changed = SetAppliedValue(state.sizeKey, size) or changed
        changed = SetAppliedValue(state.redKey, red) or changed
        changed = SetAppliedValue(state.greenKey, green) or changed
        changed = SetAppliedValue(state.blueKey, blue) or changed
    end

    ApplyAppearance(currentDisplayState)
    UpdateVisibility()
    if addon.RefreshSettingsUI then
        addon.RefreshSettingsUI()
    end
    return changed
end

local function CaptureCustomSettings()
    return CopyCustomSettings(appliedSettings, {})
end

local function GetPreviewText(stateID, wordingValue)
    local wording = WORDING_BY_VALUE[wordingValue] or WORDING_BY_VALUE.lust
    if stateID == "lusting" then
        return string.format(wording.active, 40)
    elseif stateID == "sated" then
        return string.format(wording.cooldown, "9:20")
    end
    return wording.ready
end

local EXHAUSTION_ACTIVE_OFFSET = constants.aura.exhaustionDuration
    - constants.aura.lustDuration

local function GetAuraTimeValue(spellIDs)
    for spellID in pairs(spellIDs) do
        local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID)
        if aura and aura.expirationTime and aura.expirationTime > 0 then
            return aura.expirationTime - GetTime()
        end
    end

    return nil
end

local function GetLustTimes()
    local buffTime = GetAuraTimeValue(constants.aura.buffs)
    local debuffTime = GetAuraTimeValue(constants.aura.debuffs)
    local activeTime = buffTime

    -- Keep the direct buff lookup authoritative; derive from exhaustion only
    -- while the combat aura investigation remains unresolved.
    if (not activeTime or activeTime <= 0) and debuffTime and debuffTime > 0 then
        local derivedTime = debuffTime - EXHAUSTION_ACTIVE_OFFSET
        if derivedTime > 0 then
            activeTime = derivedTime
        end
    end

    return activeTime, debuffTime
end

local function FormatTime(seconds)
    return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

local function SetDisplayState(stateID, text)
    if currentDisplayState ~= stateID then
        currentDisplayState = stateID
        ApplyAppearance(stateID)
    end
    frame.text:SetText(text)
end

local function UpdateLustStatus()
    local activeTime, debuffTime = GetLustTimes()
    local wording = WORDING_BY_VALUE[appliedSettings.wording] or WORDING_BY_VALUE.lust

    if activeTime and activeTime > 0 then
        SetDisplayState("lusting", string.format(wording.active, math.floor(activeTime)))
    elseif debuffTime and debuffTime > 0 then
        SetDisplayState("sated", string.format(wording.cooldown, FormatTime(debuffTime)))
    else
        SetDisplayState("ready", wording.ready)
    end
end

addon.frame = frame
addon.editMode = editMode
addon.sharedMedia = sharedMedia
addon.CopyCustomSettings = CopyCustomSettings
addon.CaptureCustomSettings = CaptureCustomSettings
addon.ApplyCustomSettings = ApplyCustomSettings
addon.UpdateVisibility = UpdateVisibility
addon.RefreshAppearance = function()
    ApplyAppearance(currentDisplayState)
end
addon.PreviewStateColor = PreviewStateColor
addon.GetPreviewText = GetPreviewText
addon.SetFontInstanceFont = SetFontInstanceFont
addon.ResolveFontPath = ResolveFontPath

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == ADDON_NAME then
            SimpleLustDB = type(SimpleLustDB) == "table" and SimpleLustDB or {}
            frame:UnregisterEvent("ADDON_LOADED")
        end
    elseif event == "UNIT_AURA" then
        UpdateLustStatus()
    elseif event == "PLAYER_ENTERING_WORLD" then
        addon.InitializeEditMode()
        UpdateVisibility()
        UpdateLustStatus()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        UpdateVisibility()
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterUnitEvent("UNIT_AURA", "player")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_REGEN_DISABLED")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")

C_Timer.NewTicker(constants.updateInterval, UpdateLustStatus)
