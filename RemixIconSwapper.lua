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


local slotsToCheck = {
    13,
    14,
    11,
    12,
    2,
}

local slotIdToSlotButton = {
    [2] = "CharacterNeckSlot",
    [11] = "CharacterFinger0Slot",
    [12] = "CharacterFinger1Slot",
    [13] = "CharacterTrinket0Slot",
    [14] = "CharacterTrinket1Slot",
}


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

local function GetItemDataFromLink(itemLink)
    if not itemLink then return nil end
    local tooltip = CreateFrame("GameTooltip", "TempTooltip", nil, "GameTooltipTemplate")
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tooltip:SetHyperlink(itemLink)
    tooltip:Show()

    local data = {}
    for i = 2, tooltip:NumLines() do
        local lineFont = _G["TempTooltipTextLeft"..i]
        if lineFont then
            local line = lineFont:GetText()
            if line then
                local foundLevel = line:match("^Item Level (%d+)")
                if foundLevel then
                    data.iLevel = tonumber(foundLevel)
                end

                local marker = " additional ranks of "
                local startPos = line:find(marker)
                if startPos then
                    local spellStart = startPos + #marker
                    local endPos = line:find("%.", spellStart)
                    if endPos then
                        data.spellName = line:sub(spellStart, endPos - 1)
                    end
                end
            end
        end
    end

    tooltip:Hide()
    return data
end


local function ScanEquipment()
    for _, slotId in ipairs(slotsToCheck) do
        local slotButtonName = slotIdToSlotButton[slotId]
        local slotButton = _G[slotButtonName]
        local icon = slotButton and slotButton.icon
        if icon then
            local itemLink = GetInventoryItemLink("player", slotId)
            local itemData = GetItemDataFromLink(itemLink)
            local replaced = false
            if itemData and itemData.spellName then
                local normName = NormalizeSpellName(itemData.spellName)
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

local MyFrame = CreateFrame("Frame", "RemixIconSwapperFrame", UIParent, "BasicFrameTemplate")
MyFrame:SetSize(274, 200)
MyFrame:SetPoint("CENTER")
MyFrame:SetMovable(true)
MyFrame:EnableMouse(true)
MyFrame:RegisterForDrag("LeftButton")
MyFrame:SetScript("OnDragStart", MyFrame.StartMoving)
MyFrame:SetScript("OnDragStop", MyFrame.StopMovingOrSizing)
MyFrame.TitleText:SetText("Remix Spell Items")
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
                        local itemData = GetItemDataFromLink(itemLink)
                        if itemData and itemData.spellName then
                            local normName = NormalizeSpellName(itemData.spellName)
                            local spellID = spellDB[normName]
                            if spellID then
                                table.insert(itemsToShow, {link = itemLink, spellID = spellID, iLevel = itemData.iLevel})
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
            local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("CENTER", 0, 0)
            button.itemLevelText = text
        end
        button:Show()

        local x = padding + (col * (buttonSize + padding))
        local y = -padding - (row * (buttonSize + padding))
        button:SetPoint("TOPLEFT", contentFrame, "TOPLEFT", x, y)

        local textureId = C_Spell.GetSpellTexture(itemData.spellID)
        if textureId and textureId > 0 then
            button.icon:SetTexture(textureId)
        end
        
        if itemData.iLevel then
            button.itemLevelText:SetText(itemData.iLevel)
            button.itemLevelText:Show()
        else
            button.itemLevelText:Hide()
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
    UpdateFrameVisibility()
    local itemUpdateFrame = CreateFrame("Frame")
    itemUpdateFrame:RegisterEvent("BAG_UPDATE")
    itemUpdateFrame:SetScript("OnEvent", UpdateFrameItems)
    MyFrame:HookScript("OnShow", UpdateFrameItems)

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