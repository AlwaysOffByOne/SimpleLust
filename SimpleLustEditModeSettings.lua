local _, addon = ...

local constants = addon.constants
local frame = addon.frame
local editMode = addon.editMode
local sharedMedia = addon.sharedMedia
local appearanceStates = addon.appearanceStates
local wordingPresets = addon.wordingPresets
local wordingByValue = addon.wordingByValue
local GetPreviewText = addon.GetPreviewText
local SetFontInstanceFont = addon.SetFontInstanceFont
local ResolveFontPath = addon.ResolveFontPath

local settingsPanel
local controls = {}
local refreshing = false
local fontOptionObjects = {}
local fontOptionCount = 0
local configHooked = false

local function RefreshHostConfig(height)
    local configFrame = editMode.configFrame
    if not configFrame then
        return
    end

    if height then
        configFrame.frameSpecificSocket:SetHeight(height)
    end
    configFrame.flexContainer:MarkDirty()
    configFrame.flexContainer:Layout()

    local totalHeight = configFrame.flexContainer:GetHeight()
        + configFrame.title:GetHeight()
        + 4 * editMode.CONFIG_FRAME_PADDING
        + editMode.CONFIG_EDIT_BOX_HEIGHT
    configFrame:SetHeight(totalHeight)
end

local function SetSimpleLustConfigMode(enabled)
    local configFrame = editMode:GetOrCreateConfigFrame()
    if not configFrame.SimpleLustStandardRows then
        configFrame.SimpleLustStandardRows = {}
        for _, child in ipairs({ configFrame.flexContainer:GetChildren() }) do
            if child ~= configFrame.frameSpecificSocket then
                table.insert(configFrame.SimpleLustStandardRows, child)
            end
        end

        configFrame.SimpleLustOriginalBackdrop = configFrame:GetBackdrop()
        configFrame.SimpleLustOriginalBackdropColor = {
            configFrame:GetBackdropColor(),
        }
        configFrame.SimpleLustOriginalBorderColor = {
            configFrame:GetBackdropBorderColor(),
        }
        configFrame.SimpleLustBorder = CreateFrame(
            "Frame",
            nil,
            configFrame,
            "DialogBorderTranslucentTemplate"
        )
        configFrame.SimpleLustBorder:Hide()
    end

    for _, row in ipairs(configFrame.SimpleLustStandardRows) do
        row:SetShown(not enabled)
    end

    if enabled then
        configFrame:SetBackdrop(nil)
        configFrame.SimpleLustBorder:Show()
        configFrame.title:SetFontObject("GameFontHighlightLarge")
    else
        configFrame:SetBackdrop(configFrame.SimpleLustOriginalBackdrop)
        configFrame:SetBackdropColor(unpack(configFrame.SimpleLustOriginalBackdropColor))
        configFrame:SetBackdropBorderColor(unpack(configFrame.SimpleLustOriginalBorderColor))
        configFrame.SimpleLustBorder:Hide()
        configFrame.title:SetFontObject("GameFontNormalLarge")
    end

    RefreshHostConfig()

    if not configHooked then
        configHooked = true
        hooksecurefunc(editMode, "ShowConfigForFrame", function(_, targetFrame)
            if targetFrame ~= frame then
                SetSimpleLustConfigMode(false)
            end
        end)
    end
end

local function GetFontOptionObject(fontName, fontPath)
    if not fontOptionObjects[fontName] then
        fontOptionCount = fontOptionCount + 1
        local fontObject = CreateFont("SimpleLustFontOption" .. fontOptionCount)
        if not SetFontInstanceFont(fontObject, fontPath, 12, "") then
            SetFontInstanceFont(fontObject, constants.font.defaultPath, 12, "")
        end
        fontOptionObjects[fontName] = fontObject
    end

    return fontOptionObjects[fontName]
end

local function SetWorkingColor(state, red, green, blue)
    if not frame.workingState then
        return
    end

    frame._isInternalSynchronize = true
    frame.workingState[state.redKey] = red
    frame.workingState[state.greenKey] = green
    frame.workingState[state.blueKey] = blue
    frame._isInternalSynchronize = false

    if frame:UpdateFromState(frame.workingState) then
        editMode:SetDirty(frame)
    end
    editMode:RefreshConfigUI(frame)
end

local function UpdateStatePreview(state, stateControls, workingState)
    local fontName = workingState[state.fontKey] or constants.font.defaultName
    local fontPath = ResolveFontPath(fontName)
    local size = workingState[state.sizeKey] or constants.font.defaultSize
    local red = workingState[state.redKey] or state.defaultColor.r
    local green = workingState[state.greenKey] or state.defaultColor.g
    local blue = workingState[state.blueKey] or state.defaultColor.b

    stateControls.preview:SetText(GetPreviewText(state.id, workingState.wording))
    if not SetFontInstanceFont(stateControls.previewFont, fontPath, math.min(size, 18), "OUTLINE") then
        local fallbackPath, _, fallbackFlags = GameFontHighlight:GetFont()
        SetFontInstanceFont(stateControls.previewFont, fallbackPath, math.min(size, 18), fallbackFlags or "")
    end
    stateControls.preview:SetFontObject(stateControls.previewFont)
    stateControls.preview:SetTextColor(red, green, blue)
    stateControls.fontDropdown:OverrideText(fontName)
    if stateControls.fontDropdown.Text then
        stateControls.fontDropdown.Text:SetFontObject(GetFontOptionObject(fontName, fontPath))
    end
    stateControls.sizeSlider:SetValue(size)
    stateControls.sizeLabel:SetText("Size: " .. size)
    stateControls.colorTexture:SetColorTexture(red, green, blue, 1)
end

local function RefreshControls(workingState)
    if not settingsPanel or not workingState then
        return
    end

    refreshing = true
    controls.hideOutOfCombat:SetChecked(workingState.hideOutOfCombat == true)

    local wording = wordingByValue[workingState.wording] or wordingByValue.lust
    controls.wordingDropdown:OverrideText(wording.name)

    for _, state in ipairs(appearanceStates) do
        UpdateStatePreview(state, controls[state.id], workingState)
    end
    refreshing = false
end

local function CreateColorButton(parent, state, stateControls)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(24, 24)

    local border = button:CreateTexture(nil, "BACKGROUND")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0, 0, 0, 1)

    local texture = button:CreateTexture(nil, "ARTWORK")
    texture:SetAllPoints()
    stateControls.colorTexture = texture

    button:SetScript("OnClick", function()
        local workingState = frame.workingState
        if not workingState then
            return
        end

        local previous = {
            r = workingState[state.redKey],
            g = workingState[state.greenKey],
            b = workingState[state.blueKey],
            wasDirty = frame.isDirty,
        }

        local function ApplyPickerColor()
            local red, green, blue = ColorPickerFrame:GetColorRGB()
            SetWorkingColor(state, red, green, blue)
        end

        ColorPickerFrame:SetupColorPickerAndShow({
            r = previous.r,
            g = previous.g,
            b = previous.b,
            hasOpacity = false,
            swatchFunc = ApplyPickerColor,
            cancelFunc = function()
                SetWorkingColor(state, previous.r, previous.g, previous.b)
                if not previous.wasDirty then
                    frame.isDirty = false
                    editMode:RefreshConfigUI(frame)
                end
            end,
        })
    end)

    return button
end

local function CreateGeneralControls(parent)
    local description = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", 0, -8)
    description:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    description:SetJustifyH("LEFT")
    description:SetText("Visibility settings are saved separately for each Edit Mode layout.")

    local checkbox = CreateFrame("CheckButton", nil, parent, "InterfaceOptionsCheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", description, "BOTTOMLEFT", -4, -14)
    checkbox:SetScript("OnClick", function(self)
        if not refreshing and frame.workingState then
            frame.workingState.hideOutOfCombat = self:GetChecked() == true
        end
    end)
    controls.hideOutOfCombat = checkbox

    local label = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    label:SetText("Hide SimpleLust while out of combat")
end

local function CreateAppearanceControls(parent, state)
    local stateControls = {}
    controls[state.id] = stateControls

    stateControls.previewFont = CreateFont("SimpleLust" .. state.id .. "PreviewFont")
    local defaultPath, _, defaultFlags = GameFontHighlight:GetFont()
    SetFontInstanceFont(stateControls.previewFont, defaultPath, 18, defaultFlags or "")

    local title = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    title:SetPoint("TOPLEFT", 8, -5)
    title:SetText(state.name)

    local preview = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    preview:SetPoint("TOPLEFT", 90, -5)
    preview:SetPoint("TOPRIGHT", -8, -5)
    preview:SetJustifyH("RIGHT")
    preview:SetText(GetPreviewText(state.id, "lust"))
    preview:SetFontObject(stateControls.previewFont)
    stateControls.preview = preview

    local fontDropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    fontDropdown:SetPoint("BOTTOMLEFT", 8, 8)
    fontDropdown:SetSize(158, 26)
    fontDropdown:SetupMenu(function(_, rootDescription)
        rootDescription:SetScrollMode(260)
        for _, fontName in ipairs(sharedMedia:List(sharedMedia.MediaType.FONT)) do
            local fontPath = ResolveFontPath(fontName)
            local fontObject = GetFontOptionObject(fontName, fontPath)
            local radio = rootDescription:CreateRadio(
                fontName,
                function(name)
                    return frame.workingState and frame.workingState[state.fontKey] == name
                end,
                function(name)
                    if frame.workingState then
                        frame.workingState[state.fontKey] = name
                    end
                end,
                fontName
            )
            radio:AddInitializer(function(button)
                button.fontString:SetFontObject(fontObject)
            end)
        end
    end)
    stateControls.fontDropdown = fontDropdown

    local sliderName = "SimpleLust" .. state.name .. "SizeSlider"
    local sizeSlider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    sizeSlider:SetPoint("BOTTOMLEFT", fontDropdown, "BOTTOMRIGHT", 16, 5)
    sizeSlider:SetSize(115, 16)
    sizeSlider:SetMinMaxValues(constants.font.minimumSize, constants.font.maximumSize)
    sizeSlider:SetValueStep(1)
    sizeSlider:SetObeyStepOnDrag(true)
    sizeSlider.Low:SetText("")
    sizeSlider.High:SetText("")
    sizeSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        stateControls.sizeLabel:SetText("Size: " .. value)
        if not refreshing and frame.workingState then
            frame.workingState[state.sizeKey] = value
        end
    end)
    stateControls.sizeSlider = sizeSlider

    stateControls.sizeLabel = _G[sliderName .. "Text"]
    stateControls.sizeLabel:SetText("Size: " .. constants.font.defaultSize)

    local colorButton = CreateColorButton(parent, state, stateControls)
    colorButton:SetPoint("BOTTOMRIGHT", -10, 9)
end

local function CreateWordingControls(parent)
    local description = parent:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    description:SetPoint("TOPLEFT", 0, -6)
    description:SetPoint("RIGHT", parent, "RIGHT", 0, 0)
    description:SetJustifyH("LEFT")
    description:SetText("Choose the built-in wording used by the tracker.")

    local dropdown = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", description, "BOTTOMLEFT", 0, -8)
    dropdown:SetSize(220, 26)
    dropdown:SetupMenu(function(_, rootDescription)
        for _, wording in ipairs(wordingPresets) do
            rootDescription:CreateRadio(
                wording.name,
                function(value)
                    return frame.workingState and frame.workingState.wording == value
                end,
                function(value)
                    if frame.workingState then
                        frame.workingState.wording = value
                    end
                end,
                wording.value
            )
        end
    end)
    controls.wordingDropdown = dropdown
end

local function LayoutSections(panel, resizeHost)
    local offset = -4
    for _, section in ipairs(panel.sections) do
        section:ClearAllPoints()
        section:SetPoint("TOPLEFT", 10, offset)
        section:SetPoint("RIGHT", panel, "RIGHT", -10, 0)
        offset = offset - section:GetHeight() - 4
    end

    panel:SetHeight(-offset)
    if resizeHost then
        RefreshHostConfig(panel:GetHeight())
    end
end

local function SetSectionExpanded(section, expanded)
    section.expanded = expanded
    section.content:SetShown(expanded)
    section:SetHeight(26 + (expanded and section.contentHeight or 0))
    section.collapseIcon:SetTexture(expanded
        and "Interface\\Buttons\\UI-MinusButton-Up"
        or "Interface\\Buttons\\UI-PlusButton-Up")
    LayoutSections(section.ownerPanel, true)
end

local function CreateSection(panel, title, contentHeight)
    local section = CreateFrame("Frame", nil, panel)
    section.ownerPanel = panel
    section.contentHeight = contentHeight

    local header = CreateFrame("Button", nil, section, "UIMenuButtonStretchTemplate")
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(24)
    local highlight = header:GetHighlightTexture()
    if highlight then
        highlight:SetAlpha(0)
    end

    local label = header:CreateFontString(nil, nil, "GameFontNormal")
    label:SetPoint("LEFT", 10, 0)
    label:SetPoint("RIGHT", -30, 0)
    label:SetJustifyH("LEFT")
    label:SetText(title)

    local collapseIcon = header:CreateTexture(nil, "ARTWORK")
    collapseIcon:SetSize(16, 16)
    collapseIcon:SetPoint("RIGHT", -6, 0)
    collapseIcon:SetTexture("Interface\\Buttons\\UI-MinusButton-Up")
    section.collapseIcon = collapseIcon

    local content = CreateFrame("Frame", nil, section)
    content:SetPoint("TOPLEFT", 4, -26)
    content:SetPoint("TOPRIGHT", -4, -26)
    content:SetHeight(contentHeight)
    section.content = content

    header:SetScript("OnClick", function()
        SetSectionExpanded(section, not section.expanded)
    end)

    section.expanded = true
    section:SetHeight(26 + contentHeight)
    table.insert(panel.sections, section)
    return section
end

local function CreateSettingsPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetWidth(400)
    panel.sections = {}

    local generalSection = CreateSection(panel, "General", 68)
    CreateGeneralControls(generalSection.content)

    local wordingSection = CreateSection(panel, "Wording", 70)
    CreateWordingControls(wordingSection.content)

    local appearanceSection = CreateSection(panel, "Appearance", 240)
    for index, state in ipairs(appearanceStates) do
        local row = CreateFrame("Frame", nil, appearanceSection.content)
        row:SetPoint("TOPLEFT", 0, -((index - 1) * 80))
        row:SetPoint("RIGHT", appearanceSection.content, "RIGHT", 0, 0)
        row:SetHeight(76)
        CreateAppearanceControls(row, state)

        if index < #appearanceStates then
            local divider = appearanceSection.content:CreateTexture(nil, "ARTWORK")
            divider:SetTexture("Interface\\FriendsFrame\\UI-FriendsFrame-OnlineDivider")
            divider:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, -1)
            divider:SetPoint("RIGHT", appearanceSection.content, "RIGHT", 0, 0)
            divider:SetHeight(2)
        end
    end

    LayoutSections(panel, false)
    return panel
end

function frame:GetOrCreateFrameSpecificControls(parent)
    SetSimpleLustConfigMode(true)
    if not settingsPanel then
        settingsPanel = CreateSettingsPanel(parent)
    end

    RefreshControls(self.workingState)
    return controls, settingsPanel
end

function frame:OnConfigRefresh(_, workingState)
    RefreshControls(workingState)
end
