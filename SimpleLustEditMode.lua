local _, addon = ...

local constants = addon.constants
local frame = addon.frame
local editMode = addon.editMode
local initialized = false
local settings

local selection = CreateFrame("Frame", nil, frame, "EditModeSystemSelectionTemplate")
selection:SetAllPoints()
selection:EnableMouse(true)
selection:SetPropagateMouseClicks(false)
selection:RegisterForDrag("LeftButton")
selection:Hide()

if selection.Label then
    selection.Label:SetText("SimpleLust")
end

selection.systemBaseName = "SimpleLust"
selection.system = {
    GetSystemName = function()
        return "SimpleLust"
    end,
}

local function CreateDefaultEditModeState()
    local state = {
        point = constants.frame.point,
        relativeFrame = "UIParent",
        relativePoint = constants.frame.point,
        xOfs = constants.frame.x,
        yOfs = constants.frame.y,
    }
    return addon.CopyCustomSettings(addon.CreateDefaultCustomSettings(), state)
end

local function ApplyCurrentLayout()
    if not settings then
        return
    end

    local layoutName = editMode:GetCurrentLayoutName()
    local state = settings.layouts[layoutName] or CreateDefaultEditModeState()

    editMode:ApplyState(frame, state)
    editMode:SnapshotBaseState(frame)
    editMode:SnapshotWorkingState(frame)
end

local function QueueCurrentLayout()
    C_Timer.After(0, ApplyCurrentLayout)
end

local function InitializeEditMode()
    if initialized then
        return
    end

    settings = type(SimpleLustDB.editMode) == "table" and SimpleLustDB.editMode or {}
    SimpleLustDB.editMode = settings
    settings.layouts = type(settings.layouts) == "table"
        and settings.layouts
        or {}

    frame.systemName = "SimpleLust"
    frame.showStandardEditModeControls = false
    frame.GetFrameSpecificSnapshot = addon.CaptureCustomSettings
    frame.UpdateFromState = function(_, state)
        return addon.ApplyCustomSettings(state)
    end
    frame.CommitFrameSpecificFields = function(self)
        local workingState = self.workingState
        local layoutName = workingState and workingState.layoutName or editMode:GetCurrentLayoutName()
        local layout = self.settingsTable.layouts[layoutName]
        if layout then
            addon.CopyCustomSettings(addon.CaptureCustomSettings(), layout)
        end
    end
    frame.EditModeStartMock = function()
        frame:Show()
        selection.isSelected = false
        selection:Show()
        selection:ShowHighlighted()
    end
    frame.EditModeStopMock = function()
        selection.isSelected = false
        selection:Hide()
        addon.HideEditModeSettings()
        addon.UpdateVisibility()
    end

    editMode:Register(frame, settings, CreateDefaultEditModeState())
    hooksecurefunc(EditModeManagerFrame, "SelectLayout", QueueCurrentLayout)
    QueueCurrentLayout()
    initialized = true
end

selection:SetScript("OnMouseDown", function(_, button)
    if button ~= "LeftButton" or not frame.isEditing then
        return
    end

    if EditModeManagerFrame and EditModeManagerFrame.ClearSelectedSystem then
        EditModeManagerFrame:ClearSelectedSystem()
    end

    selection:ShowSelected(true)
    selection.isSelected = true
    editMode:SnapshotWorkingState(frame)
    addon.ShowEditModeSettings()
end)

selection:SetScript("OnDragStart", function()
    local onDragStart = frame:GetScript("OnDragStart")
    if onDragStart and frame.isEditing then
        onDragStart(frame)
    end
end)

selection:SetScript("OnDragStop", function()
    local onDragStop = frame:GetScript("OnDragStop")
    if onDragStop and frame.isEditing then
        onDragStop(frame)
    end
end)

addon.InitializeEditMode = InitializeEditMode
