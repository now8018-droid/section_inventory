ServerInventory = ServerInventory or {}
local accessoriesStateKey = ('%sAccessories'):format(ResourceName)
local vehicleKeysStateKey = ('%sVehicleKeys'):format(ResourceName)

local function getPlayer(source)
    if not ESX or type(ESX.GetPlayerFromId) ~= 'function' then
        return nil
    end

    return ESX.GetPlayerFromId(source)
end

local function safeNumber(value)
    local amount = tonumber(value)
    if not amount then
        return nil
    end

    amount = math.floor(amount)
    if amount <= 0 then
        return nil
    end

    return amount
end

local function getJobPermission(xPlayer)
    if not xPlayer or not xPlayer.job or not General or not General.Config then
        return nil
    end

    local permissions = General.Config.JobPermissions
    if not permissions then
        return nil
    end

    return permissions[xPlayer.job.name]
end

local function hasAccessToType(xPlayer, itemType)
    local permission = getJobPermission(xPlayer)
    if not permission or not permission.CanOpen then
        return false
    end

    if permission.AllowedTypes then
        for i = 1, #permission.AllowedTypes do
            if permission.AllowedTypes[i] == itemType then
                return true
            end
        end

        return false
    end

    if permission.Grades then
        local allowedTypes = permission.Grades[xPlayer.job.grade]
        if not allowedTypes then
            return false
        end

        for i = 1, #allowedTypes do
            if allowedTypes[i] == itemType then
                return true
            end
        end

        return false
    end

    return true
end

local function buildAccountMap(xPlayer)
    local accounts = {}

    if xPlayer.accounts then
        for i = 1, #xPlayer.accounts do
            local account = xPlayer.accounts[i]
            accounts[account.name] = account.money
        end
    end

    return accounts
end

local function buildItemMap(xPlayer)
    local items = {}
    local inventory = xPlayer.inventory or {}

    for i = 1, #inventory do
        local item = inventory[i]
        if item.count and item.count > 0 then
            items[item.name] = item.count
        end
    end

    return items
end

local function buildWeaponMap(xPlayer)
    local weapons = {}
    local loadout = xPlayer.loadout or {}

    for i = 1, #loadout do
        local weapon = loadout[i]
        weapons[weapon.name] = weapon.ammo or 0
    end

    return weapons
end

function ServerInventory.GetPlayer(source)
    return getPlayer(source)
end

function ServerInventory.SanitizeAmount(value)
    return safeNumber(value)
end

function ServerInventory.CanOpenOtherInventory(source, targetId)
    local xPlayer = getPlayer(source)
    local xTarget = getPlayer(targetId)
    if not xPlayer or not xTarget then
        return false
    end

    if source == targetId then
        return true
    end

    local permission = getJobPermission(xPlayer)
    if not permission or not permission.CanOpen then
        return false
    end

    if permission.Grades then
        return permission.Grades[xPlayer.job.grade] ~= nil
    end

    return true
end

function ServerInventory.CanMoveType(source, itemType)
    local xPlayer = getPlayer(source)
    if not xPlayer then
        return false
    end

    return hasAccessToType(xPlayer, itemType)
end

function ServerInventory.GetOtherPlayerInventory(targetId)
    local xTarget = getPlayer(targetId)
    if not xTarget then
        return nil
    end

    return {
        accounts = buildAccountMap(xTarget),
        items = buildItemMap(xTarget),
        weapons = buildWeaponMap(xTarget)
    }
end

function ServerInventory.GetPlayerAddonItems(source)
    local player = Player(source)
    if not player then
        return {}, {}
    end

    local state = player.state

    local accessories = state[accessoriesStateKey] or {}
    local vehicleKeys = state[vehicleKeysStateKey] or {}

    return accessories, vehicleKeys
end

function ServerInventory.AddAccessory(targetSource, accessory)
    local player = Player(targetSource)
    if not player then
        return {}
    end

    local state = player.state
    local accessories = state[accessoriesStateKey] or {}

    accessories[#accessories + 1] = accessory
    state:set(accessoriesStateKey, accessories, true)

    return accessories
end

function ServerInventory.RemoveAccessory(targetSource, nameOrLabel)
    local player = Player(targetSource)
    if not player then
        return {}
    end

    local state = player.state
    local accessories = state[accessoriesStateKey] or {}

    for i = #accessories, 1, -1 do
        local data = accessories[i]
        if data and (data.name == nameOrLabel or data.label == nameOrLabel) then
            table.remove(accessories, i)
            break
        end
    end

    state:set(accessoriesStateKey, accessories, true)

    return accessories
end
