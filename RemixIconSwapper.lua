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

local slotsToCheck = {13,
14,
11,
12,
2
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


local function GetItemSpellName(slotId)
    local itemLink = GetInventoryItemLink("player", slotId)
    if not itemLink then return nil, itemLink end

    local tooltip = CreateFrame("GameTooltip", "TempTooltip", nil, "GameTooltipTemplate")
    tooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
    tooltip:SetHyperlink(itemLink)

    for i = 2, tooltip:NumLines() do
        local lineFont = _G["TempTooltipTextLeft"..i]
        if lineFont then
            local line = lineFont:GetText()
            if line then
                line = line:gsub("\n",""):gsub("^%s*",""):gsub("%s*$","")

                local spell = line:match("Grants %d+ additional ranks of (.-)%.$")
                if spell then
                    return spell, itemLink
                end

                spell = line:match("^Equip:%s*(.-)%.?$") or line:match("^Use:%s*(.-)%.?$")
                if spell then
                    return spell, itemLink
                end
            end
        end
    end

    return nil, itemLink
end


local function ScanEquipment()
    for _, slotId in ipairs(slotsToCheck) do
        local slotButtonName = slotIdToSlotButton[slotId]
        local slotButton = _G[slotButtonName]
        local icon = slotButton and slotButton.icon

        if icon then
            local spellName, _ = GetItemSpellName(slotId)
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

-- 6️⃣ Event frame for equipment changes
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
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

        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
