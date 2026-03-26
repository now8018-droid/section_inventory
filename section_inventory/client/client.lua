local TriggerServerEvent = TriggerServerEvent

ESX = nil
READY = promise.new()

--| Modules functions. |--
Inventory = Functions.Inventory()
Vault = exports['section_vaults']:getVault()

Citizen.CreateThread(function()
    while not NetworkIsPlayerActive(PlayerId()) do Citizen.Wait(100) end
    -- ESX Get Shared Object.
    while ESX == nil do
        TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
        Citizen.Wait(0)
    end

    Citizen.Await(READY)
    Debug('success', 'NUIs loaded successfully')
    
    -- Spawn object for vaults.
    pcall(function()
        Vault.GetInventory.SpawnVaultObjects()
    end)

    -- Request Addon Items
    Citizen.Wait(5000)
    Debug('info', 'Requesting addon items...')
    TriggerServerEvent('section_inventory:requestAddonItems')
    TriggerServerEvent("section_itemexpire:requestItems")
end)

RegisterCommand(General.Config.Inventory.Main.Command, function()
    if not Utils.IsDead() then
        Citizen.Wait(100)
        Inventory.InitInventory()
    end
end, false)
RegisterKeyMapping(General.Config.Inventory.Main.Command, 'Key for opening an inventory', 'keyboard', General.Config.Inventory.Main.Key)

RegisterNetEvent('section_inventory:setAddonItems', 
    function(accessories, keys)
        Inventory.Accessories = accessories
        Inventory.VehicleKeys = keys

        Debug('success', 'Addon items received successfully')
    end
)

RegisterNetEvent('section_inventory:addNewAccessory', 
    function(accessorie)
        if not accessorie or not accessorie.name then
            print('^1ERROR: Received invalid accessory data^7')
            return
        end

        local newAccessorie = Inventory.NewAccessorie(accessorie)
        if newAccessorie then
            table.insert(Inventory.Accessories, newAccessorie)

            Citizen.Wait(50)
            Inventory.RefreshInventory()
        end
    end
)

RegisterNetEvent('section_inventory:removeAccessory', 
    function(label)
        for i, acc in ipairs(Inventory.Accessories) do
            if acc.label == label or acc.name == label then
                table.remove(Inventory.Accessories, i)
                break
            end
        end

        Citizen.Wait(50)
        Inventory.RefreshInventory()
        Debug('success', ('Accessory removed and inventory refreshed: %s'):format(label))
    end
)

--| Get Nearby Players |--
RegisterNUICallback('getNearbyPlayers', 
    function(_, cb)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local nearbyPlayers = {}

        local players = ESX.Game.GetPlayersInArea(playerCoords, 3.0)
        for _, player in ipairs(players) do
            if player ~= PlayerId() then
                local serverId = GetPlayerServerId(player)
                nearbyPlayers[tostring(serverId)] = true 
            end
        end

        cb(nearbyPlayers)
    end
)

RegisterNUICallback('updateAcceptItem', 
    function(data, cb)
        local acceptItem = data.acceptItem
        if acceptItem ~= nil then
            LocalPlayer.state:set('acceptItem', acceptItem, true)
            Debug('info', ('Accept Item set to: %s'):format(tostring(acceptItem)))
        end

        cb('ok')
    end
)

--| Give Item System |--
RegisterNUICallback('give', 
    function(data)
        local modalId = tonumber(data.modalId)
        local itemData = data.item
        local itemAmount = tonumber(data.modalAmount)

        if not modalId or modalId <= 0 or not itemData or not itemData.name or not itemAmount then 
            return 
        end

        if itemData.type == 'item_weapon' or itemData.type == 'item_key' then
            Debug('error', 'This item cannot be given')
            pcall(function()
                Notification.Push.Executor('error', nil, 'ItemCannotBeGiven', itemData.name)
            end)
            return
        end

        if General.Config.DisableGive and General.Config.DisableGive[itemData.name] then
            Debug('error', 'This item cannot be given')
            pcall(function()
                Notification.Push.Executor('error', nil, 'ItemCannotBeGiven', itemData.name)
            end)
            return
        end

        local playerPed = PlayerPedId()
        if not IsPedOnFoot(playerPed) then
            Debug('error', 'You must be on foot to give items')
            return
        end

        if IsPedUsingAnyScenario(playerPed) then
            Debug('error', 'Cannot give items while in scenario')
            return
        end

        --| Find nearby players |--
        local players, nearbyPlayer = ESX.Game.GetPlayersInArea(GetEntityCoords(playerPed), 3.0)
        local foundPlayer = false
        local targetPlayerIndex

        for i = 1, #players, 1 do
            if players[i] ~= PlayerId() then
                if GetPlayerServerId(players[i]) == modalId then
                    foundPlayer = true
                    targetPlayerIndex = players[i]
                    break
                end
            end
        end

        if not foundPlayer then 
            Debug('error', 'Player not found')
            pcall(function()
                Notification.Push.Executor('error', nil, 'PlayerNotFound', itemName)
            end)
            return 
        end

        local targetPed = GetPlayerPed(targetPlayerIndex)

        -- Validate target player conditions
        if IsEntityDead(targetPed) then
            Debug('error', 'Cannot give items to dead player')
            pcall(function()
                Notification.Push.Executor('error', nil, 'PlayerDead', itemName)
            end)
            return
        end

        if not IsPedOnFoot(targetPed) then
            Debug('error', 'Target player must be on foot')
            return
        end

        if IsPedUsingAnyScenario(targetPed) then
            Debug('error', 'Cannot give items to player in scenario')
            return
        end

        if modalId and not Player(modalId).state.acceptItem then
            Debug('warn', 'Target player is not accepting items')
            pcall(function()
                Notification.Push.Executor('error', nil, 'PlayerNotAcceptingItems', itemName)
            end)
            return
        end

        -- Validate item amount
        if itemAmount <= 0 or itemAmount > itemData.count then
            Debug('error', 'Invalid item amount')
            pcall(function()
                Notification.Push.Executor('error', nil, 'InvalidItemAmount', itemName)
            end)
            return
        end

        ESX.Streaming.RequestAnimDict("gestures@m@car@low@casual@ps", function()
            TaskPlayAnim(PlayerPedId(), "gestures@m@car@low@casual@ps", "gesture_you_soft", 8.0, -8.0, -1, 48, 0, false, false, false)
        end)

        -- Execute give item
        TriggerServerEvent('section_inventory:giveItem', modalId, itemData.name, itemAmount, itemData.type)
        Debug('success', string.format('Gave %dx %s to player %d', itemAmount, itemData.label, modalId))
    end
)

--| Use Item. |--
RegisterNUICallback('use', 
    function(data)
        local itemData = data.item
        local itemName = data.item.name

        if General.Config.FashionItems and General.Config.FashionItems[itemName] then
            Utils.SendNui('toggle-item-active', { name = itemName })
            return
        end

        if itemName == 'id_card' then
            local myId = GetPlayerServerId(PlayerId())
            local closestPlayer, dist = ESX.Game.GetClosestPlayer()
            if closestPlayer ~= -1 and dist <= 3.0 then
                pcall(function()
                    if type(General.Config.IdCard) == 'function' then
                        General.Config.IdCard(myId, GetPlayerServerId(closestPlayer))
                    end
                end)
            end

            Inventory.CloseInventory()
        elseif data.item.type == 'item_accessories' then
            Inventory.UseAccessory(itemName, itemData)
            Inventory.CloseInventory() 
        elseif data.item.type == 'item_key' then
            pcall(function()
                if type(General.Config.CarKey) == 'function' then
                    General.Config.CarKey(itemData.label)
                end
            end)

            Inventory.CloseInventory() 
        elseif data.item.type == 'item_weapon' then
            Inventory.CloseInventory()
            Inventory.SetWeapon(itemData)
        else 
            TriggerServerEvent('esx:useItem', itemName)
            if General.Config.CloseOnUse and General.Config.CloseOnUse[itemName] then
                Inventory.CloseInventory() 
            end
        end
    end
)

--| Drop Item. |--
RegisterNUICallback('drop', 
    function(data)
        if not data then 
            print('Drop Error: No data received!')
            return 
        end

        local itemAmount = tonumber(data.modalAmount)
        local itemName = data.item.name
        local itemLabel = data.item.label
        local itemType = data.item.type

        if not Inventory.IsItemDroppable(itemName) then 
            pcall(function()
                Notification.Push.Executor('error', nil, 'CannotDropItem', itemName)
            end)

            return
        end

        local dictionary, animation = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
        ESX.Streaming.RequestAnimDict(dictionary)
        
        TaskPlayAnim(PlayerPedId(), dictionary, animation, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
        RemoveAnimDict(dictionary)  
        Citizen.Wait(1000) -- Wait for animation to finish

        TriggerServerEvent('section_inventory:dropItem', itemName, itemAmount, itemType, itemLabel)
        PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)

        -- Refresh before after drop.
        if not Inventory.IsDrop then 
            Citizen.Wait(250)
            Inventory.RefreshInventory()
            Inventory.IsDrop = true
        end
    end
)

-- | Item Expiration. |--
RegisterNetEvent("section_itemexpire:responseItems", 
    function(itemData)
        Inventory.ExpireInsert(itemData)
    end
)

RegisterNetEvent('esx:addInventoryItem', function(_) Citizen.Wait(100) Inventory.RefreshInventory() end)
RegisterNetEvent('esx:removeInventoryItem', function(_) Citizen.Wait(100) Inventory.RefreshInventory() end)
RegisterNetEvent('esx:setAccountMoney', function(_) Citizen.Wait(100) Inventory.RefreshInventory() end)
RegisterNetEvent('esx:addWeapon', function(_) Citizen.Wait(100) Inventory.RefreshInventory() end)
RegisterNetEvent('esx:removeWeapon', function(_) Citizen.Wait(100) Inventory.RefreshInventory() end)

RegisterNUICallback('closeNuis',
    function(_)
        Inventory.CloseInventory()
        Inventory.IsDrop = false
    end
)

RegisterNetEvent('section_inventory:closeNuis', 
    function()
        Inventory.CloseInventory()
        Inventory.IsDrop = false
    end
)

RegisterNUICallback('NuisReady',
    function(_, cb)
        READY:resolve(true)
        cb('ready')
    end
)