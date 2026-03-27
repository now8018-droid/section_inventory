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
    local moveAmount = ServerInventory.SanitizeAmount(amount)
    if not moveAmount or not itemName then
        return false
    end

    local xPlayer = ServerInventory.GetPlayer(source)
    if not xPlayer then
        return false
    end

    local inventoryItem = xPlayer.getInventoryItem(itemName)
    if inventoryItem and (inventoryItem.count or 0) >= moveAmount then
        xPlayer.removeInventoryItem(itemName, moveAmount)
        return true
    end

    local account = xPlayer.getAccount(itemName)
    if account and (account.money or 0) >= moveAmount then
        xPlayer.removeAccountMoney(itemName, moveAmount)
        return true
    end

    if itemName == 'money' and type(xPlayer.getMoney) == 'function' and xPlayer.getMoney() >= moveAmount then
        xPlayer.removeMoney(moveAmount)
        return true
    end

    if type(xPlayer.hasWeapon) == 'function' and xPlayer.hasWeapon(itemName) then
        xPlayer.removeWeapon(itemName)
        return true
    end

    return false
end

RegisterNetEvent(InvEvent('deleteItem'), function(itemName, amount)
    local source = source
    if not deleteItemFromPlayer(source, itemName, amount) then
        return
    end

    TriggerClientEvent(InvEvent('refreshInventory'), source)
end)

-- Backward compatibility: old NUI/client code may still call dropItem.
RegisterNetEvent(InvEvent('dropItem'), function(itemName, amount)
    local source = source
    if not deleteItemFromPlayer(source, itemName, amount) then
        return
    end

    TriggerClientEvent(InvEvent('refreshInventory'), source)
end)

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
