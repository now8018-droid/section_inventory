--[[

    ███╗   ███╗███████╗ ██████╗    
    ████╗ ████║██╔════╝██╔════╝    
    ██╔████╔██║███████╗██║         
    ██║╚██╔╝██║╚════██║██║         
    ██║ ╚═╝ ██║███████║╚██████╗    
    ╚═╝     ╚═╝╚══════╝ ╚═════╝    

    🔧 Meta Script Collective (MSC) Core Utility
    🔐 License   : Private Property of Meta Script Collective.
    🕸️ Source    : discord.gg/msc-fivem | msc-security.online

]]

local TriggerServerEvent = TriggerServerEvent

--| Modules functions. |--
Inventory = Functions.Inventory()
local hasTrunkExport, trunkModule = pcall(function()
    return exports['msc.trunk']:getTrunk()
end)

Trunk = hasTrunkExport and trunkModule or {
    GetInventory = {
        Items = {},
        CurrentPlate = nil,
        VehicleClass = nil,
        ModelName = nil,
        OpenNearestTrunk = function()
            return nil, nil, nil, nil
        end,
        CompileTrunkItems = function()
            return {}, 0
        end,
        GetItemLimit = function()
            return -1
        end
    },
    GetValidItems = {
        BlackLists = function()
            return false
        end
    }
}

if not hasTrunkExport then
    Debug('warn', '[Trunk] Missing export getTrunk from resource msc.trunk; trunk interactions disabled')
end
local ModelName = nil

RegisterCommand('msc.trunk.open', function()
    if not Utils.IsDead() then
        local trunk, class, plate, model = Trunk.GetInventory.OpenNearestTrunk()
        if not trunk and not class and not plate and not model then
            return 
        end

        if not Inventory.HasVehicleKey(plate) then
            Debug('error', "^1[Trunk] No vehicle key found")
            return
        end
        
        Trunk.GetInventory.CurrentPlate = plate
        Trunk.GetInventory.VehicleClass = class
        ModelName = model
        TriggerServerEvent('msc_trunk:open', plate)
    end
end, false)
RegisterKeyMapping('msc.trunk.open', 'Key for opening an trunk', 'keyboard', 'l')

RegisterNetEvent('msc_trunk:opened', 
    function(itemData)
        Debug('info', ('Trunk Opened! Item Data: %s'):format(ESX.DumpTable(itemData)))
        
        Utils.SendNui('set-inventory-type', {
            modal = 'trunk'
        })

        local Items, slotLimit = Trunk.GetInventory.CompileTrunkItems(itemData)
        for _, item in ipairs(Items) do
            item.categories = General.Config.Categories[item.name] or 'all'
        end

        -- print(ESX.DumpTable(Items))
        Utils.SendNui('setup-other-initial-items', {
            inventory = Items,
            slotLimit = slotLimit,
            model = (Trunk.GetInventory.ModelName or ModelName or '???'):gsub("^%l", string.upper),
            plate = Trunk.GetInventory.CurrentPlate or '???',
        })

        Citizen.Wait(200)
        Inventory.InitInventory()
        Inventory.OpenOtherInventory()
    end
)

RegisterNUICallback('putTrunk', 
    function(itemData)
        local ped = PlayerPedId()
        if IsPedSittingInAnyVehicle(ped) then return end

        local plate = Trunk.GetInventory.CurrentPlate
        local vehicleClass = Trunk.GetInventory.VehicleClass
        if not vehicleClass and not plate then return end

        --| Check if item is blacklisted |--
        local inputCount = tonumber(itemData.modalAmount)
        if not inputCount or math.floor(inputCount) ~= inputCount then
            Debug('error', "^1[Trunk] Invalid item count")
            return
        end

        local finalCount = inputCount
        if inputCount == 0 or inputCount > itemData.item.count then
            finalCount = 1
        end

        local itemLimit = Trunk.GetInventory.GetItemLimit(itemData.item.name)
        local currentCount = 0
        for _, item in pairs(Trunk.GetInventory.Items) do
            if item.name == itemData.item.name then
                currentCount = item.count
                break
            end
        end

        if itemLimit ~= -1 and (currentCount + finalCount) > itemLimit then
            -- Debug('error', "^1[Trunk] Item limit reached")
            pcall(function()
                Notification.Push.Executor('error', nil, 'TrunkItemLimit', itemData.item.name)
            end)

            return false
        end

        local validItems = Trunk.GetValidItems.BlackLists(itemData.item)
        if not validItems then
            pcall(function()
                Notification.Push.Executor('error', nil, 'TrunkBlacklistItem', itemData.item.name)
            end)

            return
        end

        TriggerServerEvent('msc_trunk:putItem', vehicleClass, plate, itemData.item.name, finalCount)
    end
)

RegisterNetEvent('msc_trunk:putSync', 
    function(data)
        if not data or not data.n then return end
        Debug('info', string.format("^2[Trunk] Item added: %s x%s", data.n, data.a))

        local found = false
        for _, item in pairs(Trunk.GetInventory.Items) do
            if item.name == data.n then
                item.count = data.a
                found = true
                break
            end
        end
        
        if not found then
            table.insert(Trunk.GetInventory.Items, {
                name = data.n,
                count = data.a,
                label = data.n
            })
        end

        local limit = Trunk.GetInventory.GetItemLimit(data.n) or -1
        Utils.SendNui('update-trunk-item', {
            name = data.n,
            limit = limit,
            count = data.a
        })
    end
)

RegisterNUICallback('takeTrunk', 
    function(itemData)
        local ped = PlayerPedId()
        if IsPedSittingInAnyVehicle(ped) then
            Debug('error', "^1[Trunk] Cannot take items while in a vehicle")
            return
        end

        local plate = Trunk.GetInventory.CurrentPlate
        if not plate then
            Debug('error', "^1[Trunk] No trunk is currently open")
            return
        end

        local inputCount = tonumber(itemData.modalAmount)
        if not inputCount or math.floor(inputCount) ~= inputCount then
            Debug('error', "^1[Trunk] Invalid item count")
            return
        end

        local finalCount = inputCount
        if inputCount == 0 or inputCount > itemData.item.count then
            finalCount = 1
        end

        TriggerServerEvent('msc_trunk:getItem', plate, itemData.item.name, finalCount)
    end
)

RegisterNetEvent('msc_trunk:getSync', 
    function(data)
        if not data or not data.n then return end

        if not data.a then
            Debug('info', string.format("^3[Trunk] Removing item: %s from UI", data.n))
            
            for i, item in pairs(Trunk.GetInventory.Items) do
                if item.name == data.n then
                    table.remove(Trunk.GetInventory.Items, i)
                    break
                end
            end
            
            Utils.SendNui('remove-trunk-item', {
                name = data.n
            })
        else
            Debug('info', string.format("^2[Trunk] Item updated: %s x%s", data.n, data.a))
            
            local found = false
            for _, item in pairs(Trunk.GetInventory.Items) do
                if item.name == data.n then
                    item.count = data.a
                    found = true
                    break
                end
            end
            
            local limit = Trunk.GetInventory.GetItemLimit(data.n) or -1
            Utils.SendNui('update-trunk-item', {
                name = data.n,
                limit = limit,
                count = data.a
            })
        end
    end
)
