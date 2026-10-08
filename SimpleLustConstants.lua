local _, addon = ...

addon.constants = {
    updateInterval = 0.5,
    frame = {
        width = 200,
        height = 40,
        point = "TOP",
        x = 0,
        y = -60,
    },
    font = {
        defaultName = "Friz Quadrata TT",
        defaultPath = "Fonts\\FRIZQT__.TTF",
        defaultSize = 20,
        minimumSize = 8,
        maximumSize = 48,
        flags = "OUTLINE",
    },
    aura = {
        lustDuration = 40,
        exhaustionDuration = 600,
        buffs = {
            [2825] = true,
            [32182] = true,
            [80353] = true,
            [264667] = true,
            [390386] = true,
        },
        debuffs = {
            [57723] = true,
            [57724] = true,
            [80354] = true,
            [264689] = true,
            [390435] = true,
            [160455] = true,
            [357745] = true,
        },
    },
}

addon.appearanceStates = {
    {
        id = "lusting",
        name = "Active",
        fontKey = "lustingFont",
        sizeKey = "lustingSize",
        redKey = "lustingColorR",
        greenKey = "lustingColorG",
        blueKey = "lustingColorB",
        defaultColor = { r = 1, g = 1, b = 0 },
    },
    {
        id = "sated",
        name = "Cooldown",
        fontKey = "satedFont",
        sizeKey = "satedSize",
        redKey = "satedColorR",
        greenKey = "satedColorG",
        blueKey = "satedColorB",
        defaultColor = { r = 1, g = 0, b = 0 },
    },
    {
        id = "ready",
        name = "Ready",
        fontKey = "readyFont",
        sizeKey = "readySize",
        redKey = "readyColorR",
        greenKey = "readyColorG",
        blueKey = "readyColorB",
        defaultColor = { r = 0, g = 1, b = 0 },
    },
}

addon.wordingPresets = {
    {
        value = "lust",
        name = "Lust",
        active = "Lusting for %ds",
        cooldown = "Lust in %s",
        ready = "Lust Ready",
    },
    {
        value = "heroism",
        name = "Heroism",
        active = "Active for %ds",
        cooldown = "Heroism in %s",
        ready = "Heroism Ready",
    },
    {
        value = "basic",
        name = "Basic",
        active = "Active for %ds",
        cooldown = "Cooldown for %s",
        ready = "Ready",
    },
}

addon.appearanceByID = {}
addon.wordingByValue = {}
addon.customSettingKeys = { "hideOutOfCombat", "wording" }

for _, state in ipairs(addon.appearanceStates) do
    addon.appearanceByID[state.id] = state
    table.insert(addon.customSettingKeys, state.fontKey)
    table.insert(addon.customSettingKeys, state.sizeKey)
    table.insert(addon.customSettingKeys, state.redKey)
    table.insert(addon.customSettingKeys, state.greenKey)
    table.insert(addon.customSettingKeys, state.blueKey)
end

for _, wording in ipairs(addon.wordingPresets) do
    addon.wordingByValue[wording.value] = wording
end

function addon.CreateDefaultCustomSettings()
    local settings = {
        hideOutOfCombat = false,
        wording = "lust",
    }

    for _, state in ipairs(addon.appearanceStates) do
        settings[state.fontKey] = addon.constants.font.defaultName
        settings[state.sizeKey] = addon.constants.font.defaultSize
        settings[state.redKey] = state.defaultColor.r
        settings[state.greenKey] = state.defaultColor.g
        settings[state.blueKey] = state.defaultColor.b
    end

    return settings
end
