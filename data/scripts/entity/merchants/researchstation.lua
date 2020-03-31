local upcall_refreshButton = ResearchStation.refreshButton
local upcall_initUI = ResearchStation.initUI
local upcall_update = ResearchStation.update
local upcall_onDialogClosed = ResearchStation.onDialogClosed

function ResearchStation.resetPosition()
    if inventory ~= nil then
	    odds_window.position = inventory.position - vec2(size.x,0) + offset
    end
end

function ResearchStation.onDialogClosed()
    if upcall_onDialogClosed ~= nil then
        upcall_onDialogClosed()
    end

    odds_window.hide()
end

function ResearchStation.initUI()
    upcall_initUI()

    local res = getResolution()
    local menu = ScriptUI()

    size = vec2(400, 600)
    odds_window = menu:createWindow(Rect(res * 0.5 - size * 0.5, res * 0.5 + size * 0.5))
    size = odds_window.size

    offset = vec2(-31,-247)
    ResearchStation.resetPosition()

    odds_window.caption = "The Odds"%_t
    odds_window.showCloseButton = 0
    odds_window.moveable =  0
    odds_window:hide()

    frame = odds_window:createScrollFrame(Rect(size))

    size.x = size.x - 20
    local lister = UIVerticalLister(Rect(size), 10, 10)

    text = frame:createLabel(Rect(), "Rarity", 13)
    lister:placeElementCenter(text)
    rarities_box = frame:createListBoxEx(lister:nextRect(100))
    rarities_box.columns = 2
    rarities_box:setColumnWidth(0, 200)
    rarities_box:setColumnWidth(1, 100)
    rarities_box:clear()

    text = frame:createLabel(Rect(), "Type", 13)
    lister:placeElementLeft(text)
    type_box = frame:createListBoxEx(lister:nextRect(100))
    type_box.columns = 2
    type_box:setColumnWidth(0, 200)
    type_box:setColumnWidth(1, 100)
    type_box:clear()

    text = frame:createLabel(Rect(), "Material", 13)
    lister:placeElementCenter(text)
    material_box = frame:createListBoxEx(lister:nextRect(100))
    material_box.columns = 2
    material_box:setColumnWidth(0, 200)
    material_box:setColumnWidth(1, 100)
    material_box:clear()

    Player():registerCallback("onPreRenderHud", "resetPosition")
end

function ResearchStation.getActualTypeProbabilities(items)
    local probabilities = {}
    local typesByIcons = getWeaponTypesByIcon()

    for _, item in pairs(items) do
        if item.itemType == InventoryItemType.Turret
            or item.itemType == InventoryItemType.TurretTemplate then

            local weaponType = WeaponTypes.getTypeOfItem(item)

            local p = probabilities[weaponType] or 0
            p = p + 1
            probabilities[weaponType] = p
        else
            local p = probabilities[item.name] or 0
            p = p + 1
            probabilities[item.name] = p
        end
    end

    return probabilities
end

function ResearchStation.refreshButton()
    upcall_refreshButton()

    odds_window:hide()

    rarities_box:clear()
    type_box:clear()
    material_box:clear()

    local buyer = Player()
    local items = {}
    local itemIndices = {}

    for _, item in pairs(required:getItems()) do
        if item.item then
            local amount = itemIndices[item.index] or 0
            amount = amount + 1
            itemIndices[item.index] = amount
        end
    end
    for _, item in pairs(optional:getItems()) do
        if item.item then
            local amount = itemIndices[item.index] or 0
            amount = amount + 1
            itemIndices[item.index] = amount
        end
    end

    for index, amount in pairs(itemIndices) do
        local item = buyer:getInventory():find(index)
        local has = buyer:getInventory():amount(index)

        if not item or has < amount then
            return
        end

        for i = 1, amount do
            table.insert(items, item)
        end
    end

    if #items < 3 then
        return
    end

    if not ResearchStation.checkRarities(items) then
        return
    end

    odds_window:show()

    local rarities = ResearchStation.getRarityProbabilities(items)
    local types = ResearchStation.getActualTypeProbabilities(items)
    local materials = ResearchStation.getWeaponMaterials(items)

    local white = ColorRGB(1, 1, 1)

    local sum = 0
    for _, p in pairs(rarities) do
        sum = sum + p
    end

    local i = 0
    for rarity_enum, probability in pairs(rarities) do
        rarity = Rarity(rarity_enum)
        rarities_box:addRow()
        rarities_box:setEntry(0, i, rarity.name, false, false, rarity.color)
        rarities_box:setEntry(1, i, tostring(round(probability/sum * 100, 2)) .. "%", false, false, white)
        i = i + 1
    end

    local sum = 0
    for _, p in pairs(types) do
        sum = sum + p
    end

    local i = 0
    for item_type, probability in pairs(types) do
        type_box:addRow()
        if type(item_type) == "string" then
            type_box:setEntry(0, i, item_type, false, false, white)
        else
            type_box:setEntry(0, i, WeaponTypes.nameByType[item_type], false, false, white)
        end

        type_box:setEntry(1, i, tostring(round(probability/sum * 100, 2)) .. "%", false, false, white)
        i = i + 1
    end

    local sum = 0
    for _, p in pairs(materials) do
        sum = sum + p
    end

    local i = 0
    for material_enum, probability in pairs(materials) do
        material = Material(material_enum)
        material_box:addRow()
        material_box:setEntry(0, i, material.name, false, false, material.color)
        material_box:setEntry(1, i, tostring(round(probability/sum * 100, 2)) .. "%", false, false, white)
        i = i + 1
    end
end