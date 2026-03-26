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
local TargetPlayer = nil

--| Modules functions. |--
Inventory = Functions.Inventory()
OtherPlayerInventory = Functions.OtherPlayerInventory()

RegisterCommand('inv',
    function(_, args)
        local targetId = args and args[1] and tonumber(args[1])
        if not targetId or targetId <= 0 then return end

        TriggerServerEvent('section_inventory:req:player:open', targetId)
    end, false
)

RegisterNetEvent('section_inventory:res:player:open', 
    function(itemData, targetId)
        Utils.SendNui('set-inventory-type', {
            modal = 'player'
        })

        print(ESX.DumpTable(itemData))
        
        local Items = OtherPlayerInventory.CompileInventory(itemData)
        Utils.SendNui('setup-other-initial-items', {
            inventory = Items
        })

        TargetPlayer = targetId
        Citizen.Wait(200)
        Inventory.InitInventory()
        Inventory.OpenOtherInventory()
    end
)

RegisterNetEvent('section_inventory:refreshOtherPlayer', function(targetId, itemData)
    TargetPlayer = targetId
    if TargetPlayer then
        local Items = OtherPlayerInventory.CompileInventory(itemData)

        Utils.SendNui('setup-other-initial-items', {
            inventory = Items
        })
    end
end)

RegisterNetEvent('section_inventory:refreshInventory', function()
    Inventory.RefreshInventory()
end)

RegisterNUICallback('putPlayer', 
    function(itemData)
        local ped = PlayerPedId()
        if IsPedSittingInAnyVehicle(ped) then return end

        local inputCount = tonumber(itemData.modalAmount)
        if not inputCount or math.floor(inputCount) ~= inputCount then
            return
        end
        
        local finalCount = inputCount
        if inputCount == 0 or inputCount > itemData.item.count then
            finalCount = 1
        end

        local itemType = itemData.item.type
        local itemName = itemData.item.name
        -- if itemType == 'item_weapon' then
        --     finalCount = GetAmmoInPedWeapon(ped, GetHashKey(itemName)) or 0
        -- end

        -- ตัวเอง (source) ให้ของ TargetPlayer (receiver)
        TriggerServerEvent('section_inventory:req:player:tradeItem', 'put', TargetPlayer, itemType, itemName, finalCount)
    end
)

RegisterNUICallback('takePlayer', 
    function(itemData)
        local ped = PlayerPedId()
        if IsPedSittingInAnyVehicle(ped) then return end
    
        local inputCount = tonumber(itemData.modalAmount)
        if not inputCount or math.floor(inputCount) ~= inputCount then
            return
        end
        
        local itemType = itemData.item.type
        local itemName = itemData.item.name
        local finalCount = inputCount

        local playerData = ESX.GetPlayerData()
        local jobName = playerData.job and playerData.job.name
        local isBypass = jobName and General.Config.JobPermissions[jobName] and General.Config.JobPermissions[jobName].CanOpen

        if not isBypass then
            finalCount = Utils.CalculateAvailableSpace(itemName, inputCount)
        end

        if finalCount <= 0 then
            Debug('error', 'Not enough space in inventory')
            pcall(function()
                Notification.Push.Executor('error', nil, 'VaultNotEnoughSpace', itemName)
            end)

            return
        end
        
        if inputCount == 0 or inputCount > itemData.item.count then
            finalCount = math.min(1, Utils.CalculateAvailableSpace(itemName, 1))
        end
        
        -- TargetPlayer (source) ให้ของ ตัวเอง (receiver)
        TriggerServerEvent('section_inventory:req:player:tradeItem', 'take', TargetPlayer, itemType, itemName, finalCount)
    end
)