-- 1️⃣ Spell Database
local spellDB = {
    ["brewingstorm"] = 1258587,
    ["highmountainfortitude"] = 1234683,
    ["temporalretaliation"] = 1232262,
    ["volatilemagics"] = 1234774,
    ["arcaneaegis"] = 1232720,
    ["arcaneward"] = 1242202,
    ["iammyscars"] = 1242022,
    ["lightsvengeance"] = 1251666,
    ["soulsofthecaw"] = 1235159,
    ["stormsurger"] = 1241854,
    ["terrorfrombelow"] = 1233595,
    ["touchofmalice"] = 1242992,
}

-- 2️⃣ Data Tables
local slotsToCheck = {
    13, -- Top trinket
    14, -- Bottom trinket
    11, -- Ring 1
    12, -- Ring 2
    2,  -- Neck
}

local slotIdToSlotButton = {
    [2] = "CharacterNeckSlot",
    [11] = "CharacterFinger0Slot",
    [12] = "CharacterFinger1Slot",
    [13] = "CharacterTrinket0Slot",
    [14] = "CharacterTrinket1Slot",
}

-- 3️⃣ Helper Functions
local function NormalizeSpellName(line)
    if not line then return nil end
    line = line:lower():gsub("%s+",""):gsub("!$","")
    for dbName,_ in pairs(spellDB) do
        if line:find(dbName) then
            return dbName
        end
    end
    return nil
end

local function GetSpellNameFromLink(itemLink)
    if not itemLink then return nil end
    local tooltip = CreateFrame("GameTooltip", "TempTooltip", nil, "GameTooltipTemplate")
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tooltip:SetHyperlink(itemLink)
    tooltip:Show()

    local spellName = nil
    for i = 2, tooltip:NumLines() do
        local lineFont = _G["TempTooltipTextLeft"..i]
        if lineFont then
            local line = lineFont:GetText()
            if line then
                local marker = " additional ranks of "
                local startPos = line:find(marker)
                if startPos then
                    local spellStart = startPos + #marker
                    local endPos = line:find("%.", spellStart)
                    if endPos then
                        spellName = line:sub(spellStart, endPos - 1)
                        break
                    end
                end
            end
        end
    end

    tooltip:Hide()
    return spellName
end

-- 4️⃣ Core Logic
-- Scanner for equipped items on the character sheet
local function ScanEquipment()
    for _, slotId in ipairs(slotsToCheck) do
        local slotButtonName = slotIdToSlotButton[slotId]
        local slotButton = _G[slotButtonName]
        local icon = slotButton and slotButton.icon
        if icon then
            local itemLink = GetInventoryItemLink("player", slotId)
            local spellName = GetSpellNameFromLink(itemLink)
            local replaced = false
            if spellName then
                local normName = NormalizeSpellName(spellName)
                if normName then
                    local spellID = spellDB[normName]
                    if spellID then
                        local textureId = C_Spell.GetSpellTexture(spellID)
                        if textureId and textureId > 0 then
                            icon:SetTexture(textureId)
                            replaced = true
                        end
                    end
                end
            end
            if not replaced then
                local itemTexture = GetInventoryItemTexture("player", slotId)
                icon:SetTexture(itemTexture)
            end
            if icon:GetTexture() then
                icon:Show()
                icon:SetVertexColor(1, 1, 1, 1)
            else
                icon:Hide()
            end
        end
    end
end

-- UI Frame for bag items
local MyFrame = CreateFrame("Frame", "RemixIconSwapperFrame", UIParent, "BasicFrameTemplate")
MyFrame:SetSize(184, 430)
MyFrame:SetPoint("CENTER")
MyFrame:SetMovable(true)
MyFrame:EnableMouse(true)
MyFrame:RegisterForDrag("LeftButton")
MyFrame:SetScript("OnDragStart", MyFrame.StartMoving)
MyFrame:SetScript("OnDragStop", MyFrame.StopMovingOrSizing)
MyFrame.TitleText:SetText("Remix Items")
MyFrame:Hide()

local contentFrame = CreateFrame("Frame", nil, MyFrame)
Mixin(contentFrame, BackdropTemplateMixin)
contentFrame:SetPoint("TOPLEFT", 15, -30)
contentFrame:SetPoint("BOTTOMRIGHT", -15, 15)

local function UpdateFrameItems()
    for _, child in ipairs({contentFrame:GetChildren()}) do
        child:Hide()
    end

    local itemsToShow = {}
    for bag = 0, NUM_BAG_SLOTS do
        local numSlots = C_Container.GetContainerNumSlots(bag)
        if numSlots and numSlots > 0 then
            for slot = 1, numSlots do
                local itemLink = C_Container.GetContainerItemLink(bag, slot)
                if itemLink then
                    local _, _, _, _, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
                    if itemEquipLoc == "INVTYPE_TRINKET" or itemEquipLoc == "INVTYPE_FINGER" or itemEquipLoc == "INVTYPE_NECK" then
                        local spellName = GetSpellNameFromLink(itemLink)
                        if spellName then
                            local normName = NormalizeSpellName(spellName)
                            local spellID = spellDB[normName]
                            if spellID then
                                table.insert(itemsToShow, {link = itemLink, spellID = spellID})
                            end
                        end
                    end
                end
            end
        end
    end

    local buttonSize = 36
    local padding = 4
    local buttonsPerRow = math.floor((MyFrame:GetWidth() - (padding*2)) / (buttonSize + padding))
    local row, col = 0, 0

    for i, itemData in ipairs(itemsToShow) do
        local buttonName = "RemixIconSwapperItem"..i
        local button = _G[buttonName] or CreateFrame("Button", buttonName, contentFrame)
        if not button.icon then
            button:SetSize(buttonSize, buttonSize)
            button:RegisterForClicks("AnyUp")
            local icon = button:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints(button)
            button.icon = icon
        end
        button:Show()

        local x = padding + (col * (buttonSize + padding))
        local y = -padding - (row * (buttonSize + padding))
        button:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", x, y)

        local textureId = C_Spell.GetSpellTexture(itemData.spellID)
        if textureId and textureId > 0 then
            button.icon:SetTexture(textureId)
        end
        
        button:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(itemData.link)
            GameTooltip:Show()
        end)
        button:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
        end)

        button:SetScript("OnClick", function(self, b, down)
            if b == "RightButton" then
                C_Item.EquipItemByName(itemData.link)
            end
        end)

        col = col + 1
        if col >= buttonsPerRow then
            col = 0
            row = row + 1
        end
    end
end

-- 5️⃣ Event Handling
local function UpdateFrameVisibility()
    local anyBagOpen = false
    for i = 1, NUM_CONTAINER_FRAMES do
        local frame = _G["ContainerFrame"..i]
        if frame and frame:IsVisible() then
            anyBagOpen = true
            break
        end
    end

    if anyBagOpen then
        MyFrame:Show()
    else
        MyFrame:Hide()
    end
end

for i = 1, NUM_CONTAINER_FRAMES do
    local frame = _G["ContainerFrame"..i]
    if frame then
        frame:HookScript("OnShow", UpdateFrameVisibility)
        frame:HookScript("OnHide", UpdateFrameVisibility)
    end
end

local loginEventFrame = CreateFrame("Frame")
loginEventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
loginEventFrame:SetScript("OnEvent", function(self)
    -- Set up bag item window
    UpdateFrameVisibility()
    local itemUpdateFrame = CreateFrame("Frame")
    itemUpdateFrame:RegisterEvent("BAG_UPDATE")
    itemUpdateFrame:SetScript("OnEvent", UpdateFrameItems)
    MyFrame:HookScript("OnShow", UpdateFrameItems)

    -- Set up character sheet scanner
    CharacterFrame:HookScript("OnUpdate", function()
        if CharacterFrame:IsVisible() then
            ScanEquipment()
        end
    end)
    local equipmentFrame = CreateFrame("Frame")
    equipmentFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    equipmentFrame:SetScript("OnEvent", function()
        if CharacterFrame:IsVisible() then
            ScanEquipment()
        end
    end)

    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)