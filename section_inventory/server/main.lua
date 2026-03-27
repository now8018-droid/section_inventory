local function notify(source, message)
    TriggerClientEvent('esx:showNotification', source, message)
end

local function refreshBoth(source, targetId)
    TriggerClientEvent(InvEvent('refreshInventory'), source)

    local targetInventory = ServerInventory.GetOtherPlayerInventory(targetId)
    if targetInventory then
        TriggerClientEvent(InvEvent('refreshOtherPlayer'), source, targetId, targetInventory)
    end
end

local function moveStandardItem(xFrom, xTo, itemName, amount)
    local item = xFrom.getInventoryItem(itemName)
    if not item or item.count < amount then
        return false, 'not_enough_item'
    end

    if not xTo.canCarryItem(itemName, amount) then
        return false, 'target_no_space'
    end

    xFrom.removeInventoryItem(itemName, amount)
    xTo.addInventoryItem(itemName, amount)

    return true
end

local function moveMoney(accountName, xFrom, xTo, amount)
    local account = xFrom.getAccount(accountName)
    if not account or account.money < amount then
        return false, 'not_enough_money'
    end

    xFrom.removeAccountMoney(accountName, amount)
    xTo.addAccountMoney(accountName, amount)

    return true
end

local function moveWeapon(xFrom, xTo, weaponName, amount)
    if not xFrom.hasWeapon(weaponName) then
        return false, 'no_weapon'
    end

    xFrom.removeWeapon(weaponName)
    xTo.addWeapon(weaponName, amount or 0)

    return true
end

RegisterNetEvent(InvEvent('requestAddonItems'), function()
    local source = source
    local accessories, keys = ServerInventory.GetPlayerAddonItems(source)

    TriggerClientEvent(InvEvent('setAddonItems'), source, accessories, keys)
end)

RegisterNetEvent(InvEvent('saveAccessories'), function(targetSource, label, accessoryType, skin)
    local source = source
    local receiver = tonumber(targetSource) or source
    local accessory = {
        label = label,
        name = accessoryType,
        skin = skin,
        type = 'item_accessories',
        count = 1,
        limit = -1,
        usable = true,
        canRemove = true
    }

    ServerInventory.AddAccessory(receiver, accessory)
    TriggerClientEvent(InvEvent('addNewAccessory'), receiver, accessory)
end)

RegisterNetEvent(InvEvent('removeAccessory'), function(targetSource, nameOrLabel)
    local source = source
    local receiver = tonumber(targetSource) or source
    if type(nameOrLabel) ~= 'string' or nameOrLabel == '' then
        return
    end

    ServerInventory.RemoveAccessory(receiver, nameOrLabel)
    TriggerClientEvent(InvEvent('removeAccessory'), receiver, nameOrLabel)
end)

RegisterNetEvent(InvEvent('req:player:open'), function(targetId)
    local source = source
    local playerId = tonumber(targetId)

    if not playerId then
        return
    end

    if not ServerInventory.CanOpenOtherInventory(source, playerId) then
        notify(source, 'You do not have permission to open this inventory')
        return
    end

    local payload = ServerInventory.GetOtherPlayerInventory(playerId)
    if not payload then
        notify(source, 'Target player not found')
        return
    end

    TriggerClientEvent(InvEvent('res:player:open'), source, payload, playerId)
end)

RegisterNetEvent(InvEvent('req:player:tradeItem'), function(mode, targetId, itemType, itemName, amount)
    local source = source
    local receiverId = tonumber(targetId)
    local moveAmount = ServerInventory.SanitizeAmount(amount)

    if not receiverId or not moveAmount or not itemType or not itemName then
        return
    end

    if not ServerInventory.CanOpenOtherInventory(source, receiverId) then
        notify(source, 'You do not have permission to transfer this item')
        return
    end

    local xSource = ServerInventory.GetPlayer(source)
    local xTarget = ServerInventory.GetPlayer(receiverId)
    if not xSource or not xTarget then
        return
    end

    local fromPlayer, toPlayer
    if mode == 'put' then
        fromPlayer = xSource
        toPlayer = xTarget
    elseif mode == 'take' then
        if not ServerInventory.CanMoveType(source, itemType) then
            notify(source, 'You are not allowed to take this item type')
            return
        end

        fromPlayer = xTarget
        toPlayer = xSource
    else
        return
    end

    local ok = false

    if itemType == 'item_standard' then
        ok = moveStandardItem(fromPlayer, toPlayer, itemName, moveAmount)
    elseif itemType == 'item_account' then
        ok = moveMoney(itemName, fromPlayer, toPlayer, moveAmount)
    elseif itemType == 'item_money' then
        ok = moveMoney('money', fromPlayer, toPlayer, moveAmount)
    elseif itemType == 'item_weapon' then
        ok = moveWeapon(fromPlayer, toPlayer, itemName, moveAmount)
    end

    if not ok then
        return
    end

    refreshBoth(source, receiverId)
    TriggerClientEvent(InvEvent('refreshInventory'), receiverId)
end)

RegisterNetEvent(InvEvent('giveItem'), function(targetId, itemName, amount, itemType)
    local source = source
    local receiverId = tonumber(targetId)
    local moveAmount = ServerInventory.SanitizeAmount(amount)

    if not receiverId or not moveAmount then
        return
    end

    local xSource = ServerInventory.GetPlayer(source)
    local xTarget = ServerInventory.GetPlayer(receiverId)
    if not xSource or not xTarget then
        return
    end

    local ok = false

    if itemType == 'item_standard' then
        ok = moveStandardItem(xSource, xTarget, itemName, moveAmount)
    elseif itemType == 'item_account' then
        ok = moveMoney(itemName, xSource, xTarget, moveAmount)
    elseif itemType == 'item_money' then
        ok = moveMoney('money', xSource, xTarget, moveAmount)
    end

    if not ok then
        return
    end

    TriggerClientEvent(InvEvent('refreshInventory'), source)
    TriggerClientEvent(InvEvent('refreshInventory'), receiverId)
end)

local function deleteItemFromPlayer(source, itemName, amount)
    local rawItemName = tostring(itemName or '')
    local trimmedItemName = rawItemName:gsub('^%s+', ''):gsub('%s+$', '')
    if trimmedItemName == '' then
        return false
    end

    local lowerItemName = string.lower(trimmedItemName)
    local upperItemName = string.upper(trimmedItemName)

    local moveAmount = ServerInventory.SanitizeAmount(amount)
    if not moveAmount then
        return false
    end

    local xPlayer = ServerInventory.GetPlayer(source)
    if not xPlayer then
        return false
    end

    local inventoryItem = xPlayer.getInventoryItem(trimmedItemName)
    local inventoryName = trimmedItemName
    if (not inventoryItem or (inventoryItem.count or 0) <= 0) and lowerItemName ~= trimmedItemName then
        inventoryItem = xPlayer.getInventoryItem(lowerItemName)
        inventoryName = lowerItemName
    end

    local inventoryCount = inventoryItem and (inventoryItem.count or 0) or 0
    if inventoryCount > 0 then
        local removed = xPlayer.removeInventoryItem(inventoryName, math.min(moveAmount, inventoryCount))
        return removed ~= false
    end

    local account = xPlayer.getAccount(trimmedItemName)
    local accountName = trimmedItemName
    if (not account or (account.money or 0) <= 0) and lowerItemName ~= trimmedItemName then
        account = xPlayer.getAccount(lowerItemName)
        accountName = lowerItemName
    end

    local accountMoney = account and (account.money or 0) or 0
    if accountMoney > 0 then
        local removed = xPlayer.removeAccountMoney(accountName, math.min(moveAmount, accountMoney))
        return removed ~= false
    end

    local cash = type(xPlayer.getMoney) == 'function' and xPlayer.getMoney() or 0
    if lowerItemName == 'money' and cash > 0 then
        local removed = xPlayer.removeMoney(math.min(moveAmount, cash))
        return removed ~= false
    end

    if type(xPlayer.hasWeapon) == 'function' then
        if xPlayer.hasWeapon(trimmedItemName) then
            xPlayer.removeWeapon(trimmedItemName)
            return true
        end

        if upperItemName ~= trimmedItemName and xPlayer.hasWeapon(upperItemName) then
            xPlayer.removeWeapon(upperItemName)
            return true
        end

        if lowerItemName ~= trimmedItemName and xPlayer.hasWeapon(lowerItemName) then
            xPlayer.removeWeapon(lowerItemName)
            return true
        end
    end

    return false
end

local function handleDeleteItemEvent(itemName, amount)
    local source = source
    if not deleteItemFromPlayer(source, itemName, amount) then
        return
    end

    TriggerClientEvent(InvEvent('refreshInventory'), source)
end

local function registerDeleteEvent(eventName)
    RegisterNetEvent(eventName)
    AddEventHandler(eventName, handleDeleteItemEvent)
end

registerDeleteEvent(InvEvent('deleteItem'))
registerDeleteEvent(InvEvent('dropItem'))

-- Compatibility with older/non-prefixed event names from legacy clients.
registerDeleteEvent('section_inventory:deleteItem')
registerDeleteEvent('section_inventory:dropItem')
registerDeleteEvent('deleteItem')
registerDeleteEvent('dropItem')

AddEventHandler('playerDropped', function()
    local source = source
    local player = Player(source)
    if not player then
        return
    end

    local state = player.state

    state:set(('%sAccessories'):format(ResourceName), {}, false)
    state:set(('%sVehicleKeys'):format(ResourceName), {}, false)
end)
