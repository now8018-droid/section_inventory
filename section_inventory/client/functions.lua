--| Utils functions. |--
Utils = {
    ---@param str string
    ---@param start string
    ---@return boolean
    StartsWith = function(str, start)
        return string.sub(str, 1, str.len(start)) == start
    end,

    ---@param action string
    SendNui = function(action, data)
        data = data or {}
        data.action = action
        SendNUIMessage(data)
    end,

    ---@return table
    GetPlayerCoords = function()
        return GetEntityCoords(PlayerPedId())
    end,

    ---@param dict string
    LoadAnim = function(dict)
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(0)
        end
    end,

    ---@return boolean
    IsDead = function()
        local ped = PlayerPedId()
        return IsPedDeadOrDying(ped, true) or IsEntityDead(ped)
    end,

    IsPedOnFoot = function(ped)
        return not IsPedInAnyVehicle(ped, false) and not IsPedFalling(ped) and not IsPedRagdoll(ped)
    end,

    IsPedUsingAnyScenario = function(ped)
        return GetPedScriptTaskCommand(ped) ~= 0 or GetScriptTaskStatus(ped, 0x5BD8F010) ~= 7
    end,

    ---@return number
    GetItemLimit = function(itemName)
        local playerData = ESX.GetPlayerData()
        local itemLimit = -1 
        local currentCount = 0

        for _, item in ipairs(playerData.inventory) do
            if item.name == itemName then
                currentCount = item.count or 0
                itemLimit = item.limit or -1
                break
            end
        end
        
        if itemLimit == -1 then
            itemLimit = -1
        end
        
        return itemLimit, currentCount
    end,

    ---@param itemName string
    ---@param requestedAmount number
    ---@return number
    CalculateAvailableSpace = function(itemName, requestedAmount)
        local itemLimit, currentCount = Utils.GetItemLimit(itemName)
        
        if itemLimit == -1 then
            return requestedAmount
        end
        
        local availableSpace = itemLimit - currentCount
        if availableSpace <= 0 then
            return 0
        end
        
        return math.min(requestedAmount, availableSpace)
    end,

    ---@param itemName string
    ---@param amount number
    ---@return boolean
    CanReceiveItem = function(itemName, amount)
        amount = amount or 1
        local itemLimit, currentCount = Utils.GetItemLimit(itemName)
        
        if itemLimit == -1 then
            return true
        end
        
        return (currentCount + amount) <= itemLimit
    end,

    ---@param itemData table
    ---@return table
    GetItemWithLimit = function(itemData)
        local itemLimit, currentCount = Utils.GetItemLimit(itemData.name)
        
        return {
            name = itemData.name,
            count = itemData.count,
            label = itemData.label,
            limit = itemLimit,
            type = itemData.type,
            usable = itemData.usable,
            rare = itemData.rare,
            canRemove = itemData.canRemove,
        }
    end,

    ---@param inventory table
    ---@return table
    FormatInventoryWithLimits = function(inventory)
        local formatted = {}
        for _, item in ipairs(inventory) do
            formatted[#formatted + 1] = Utils.GetItemWithLimit(item)
        end

        return formatted
    end
}

--| Functions module |--
Functions = {
    --| Inventory |--
    Inventory = function()
        local self = {}
        
        --| Inventory Items |--
        self.Initial = false
        self.IsDrop = false
        self.IsBusy = false
        self.AddOnLoaded = false
        
        self.Accessories = {}
        self.VehicleKeys = {}
        self.ItemsExpire = {}
        self.Items = {}
        
        --| Fast Slot |--
        self.QuickSlot = {
            { nil, nil, nil, nil, nil, nil, nil }, 
            { nil, nil, nil, nil, nil, nil, nil }
        }

        self.CurrentHotbar = 1
        self.CurrentWeapon = nil

        --| Functions |--
        self.NuiFocus = function(setFocus)
            SetNuiFocus(setFocus, setFocus)
            if setFocus then 
                AnimpostfxPlay("MenuMGSelectionIn", 1000, setFocus)
            else 
                AnimpostfxStop("MenuMGSelectionIn")
            end
        end

        self.OpenInventory = function()
            self.Initial = true
            self.NuiFocus(true)

            Utils.SendNui('open-inventory')
        end

        self.OpenOtherInventory = function()
            Citizen.Wait(100)
            Utils.SendNui('open-others')
        end

        self.InitInventory = function()
            if not self.Initial then
                self.OpenInventory()
                self.Initial = true 
            end

            local Items = self.CompileInventory()

            Utils.SendNui('setup-initial-items', {
                inventory = Items or {},
                playerId = GetPlayerServerId(PlayerId()),
            })

            self.OpenInventory()
        end 

        self.RefreshInventory = function()
            local Items = self.CompileInventory()

            Utils.SendNui('setup-initial-items', {
                inventory = Items or {},
                playerId = GetPlayerServerId(PlayerId()),
            })
        end

        self.ExpireInsert = function(items)
            self.ItemsExpire = items
        end

        ---@param itemName string
        ---@return string|nil
        self.GetExpireDate = function(itemName)
            if not self.ItemsExpire or #self.ItemsExpire == 0 then
                return nil
            end

            for _, expireData in ipairs(self.ItemsExpire) do
                if expireData.item == itemName then
                    return expireData.date
                end
            end

            return nil
        end

        ---@return table
        self.NewItem = function(typeItem, itemName, itemLabel, itemCount, itemLimit, itemUsable, itemGiveable, itemDroppable, itemCategories)
            local itemCategories = nil
            local itemDesc = 'ไอเท็มทั่วไปที่สามารถใช้งานหรือเก็บไว้ในกระเป๋าได้'

            if General.Config.Categories[itemName] ~= nil then
                itemCategories = General.Config.Categories[itemName]
            end

            if General.Config.HoverDesc[itemName] ~= nil then
                itemDesc = General.Config.HoverDesc[itemName]
            end

            -- Check for expire date
            local expireDate = self.GetExpireDate(itemName)

            return {
                type = typeItem or 'item_standard',
                name = itemName or 'Item',
                label = itemLabel or 'Label',
                desc = itemDesc,
                count = itemCount or 0,
                limit = itemLimit or -1,
                usable = itemUsable or false,
                giveable = itemGiveable or false,
                droppable = itemDroppable or false,
                canRemove = itemDroppable or false,
                categories = itemCategories or 'all',
                expireDate = expireDate,
            }
        end

        ---@return table items
        self.CompileInventory = function()
            self.Items = {}
            table.insert(self.Items, self.NewItem('item_standard', 'id_card', 'ID Card', 1, -1, true, false, false, 'all')) -- Add ID Card

            self.AddMoneyAccounts() -- Add Money Accounts
            self.AddKeys() -- Add Keys
            self.AddAccessories() -- Add Accessories
            self.AddWeapons() -- Add Weapons
            self.AddRegularItems() -- Add Regular Items
            
            return self.Items
        end

        ---@return void
        self.AddMoneyAccounts = function()
            local accounts = ESX.GetPlayerData().accounts
            
            for _, account in ipairs(accounts) do
                if account.money > 0 and account.name ~= 'bank' then
                    table.insert(self.Items, self.NewItem('item_account', account.name, account.label, account.money, -1, false, true, true))
                end
            end
        end

        ---@return void
        self.AddKeys = function()
            for _, plate in ipairs(self.VehicleKeys) do
                local keyMeta = { 
                    type = 'item_key', 
                    label = plate, 
                    count = 1, 
                    limit = -1, 
                    name = 'key',
                    usable = true, 
                    rare = false, 
                    canRemove = false, 
                    categories = 'keys' 
                }

                table.insert(self.Items, keyMeta)
            end
        end

        ---@return void
        self.AddAccessories = function()
            local accessories = self.Accessories or {}
            if #accessories == 0 then
                print('^1ERROR: No accessories found^7')
            end

            for _, accessory in ipairs(accessories) do
                self.NewAccessorie(accessory)
            end
        end

        ---@param accessorie table
        ---@return table
        self.NewAccessorie = function(accessorie)
            if not accessorie or not accessorie.name then
                print('^1ERROR: Invalid accessory data - missing Name^7')
                return nil
            end

            local itemNum, itemSkin
            if accessorie.skin then
                itemNum = accessorie.skin[('%s_1'):format(accessorie.name)] or 0
                itemSkin = accessorie.skin[('%s_2'):format(accessorie.name)] or 0
            else
                itemNum = accessorie.itemNum
                itemSkin = accessorie.itemSkin
            end

            local meta = {
                type = 'item_accessories',
                name = accessorie.name,
                label = accessorie.label or 'Accessory',
                count = 1,
                limit = -1,
                usable = true,
                giveable = false,
                droppable = true,
                rare = false,
                canRemove = true,
                itemNum = itemNum,
                itemSkin = itemSkin,
                categories = 'cloth'
            }

            table.insert(self.Items, meta)
            return meta
        end

        ---@param itemName string
        ---@param itemData table
        self.UseAccessory = function(itemName, itemData)
            local ped = PlayerPedId()
            local n1 = ('%s_1'):format(itemName)
            local n2 = ('%s_2'):format(itemName)

            TriggerEvent('skinchanger:getSkin', function(skin)
                if skin[n1] ~= -1 then
                    local dict, anim
                    if General.Config.Accessories.Animation.takeOff and General.Config.Accessories.Animation.takeOff[itemName] then
                        dict = General.Config.Accessories.Animation.takeOff[itemName][1]
                        anim = General.Config.Accessories.Animation.takeOff[itemName][2]
                    else
                        dict = General.Config.Accessories.Animation[itemName][1]
                        anim = General.Config.Accessories.Animation[itemName][2]
                    end

                    Utils.LoadAnim(dict)
                    TaskPlayAnim(ped, dict, anim, 8.0, 2.0, -1, 48, 2, 0, 0, 0)
                    Citizen.Wait(1000)

                    local accessorySkin = {}
                    accessorySkin[n1] = -1
                    accessorySkin[n2] = 0

                    TriggerEvent('skinchanger:loadClothes', skin, accessorySkin)
                    Citizen.Wait(500)
                    return
                end

                local dict = General.Config.Accessories.Animation[itemName][1]
                local anim = General.Config.Accessories.Animation[itemName][2]
                Utils.LoadAnim(dict)
                TaskPlayAnim(ped, dict, anim, 8.0, 2.0, -1, 48, 2, 0, 0, 0)
                Citizen.Wait(1000)

                local itemNum = tonumber(itemData.itemNum) or -1
                local itemSkin = tonumber(itemData.itemSkin) or 0
                if itemNum == -1 then itemSkin = 0 end

                local accessorySkin = {}
                accessorySkin[n1] = itemNum
                accessorySkin[n2] = itemSkin

                TriggerEvent('skinchanger:loadClothes', skin, accessorySkin)
            end)
        end

        ---@return void
        self.AddWeapons = function() 
            local ped = PlayerPedId()
            
            for _, weaponConfig in ipairs(ESX.GetConfig().Weapons) do
                local weaponHash = GetHashKey(weaponConfig.name)
                if HasPedGotWeapon(ped, weaponHash, false) then
                    local weaponAmmo = GetAmmoInPedWeapon(ped, weaponHash)
                    if weaponAmmo == 0 then
                        weaponAmmo = 1
                    end
                    
                    table.insert(self.Items, self.NewItem('item_weapon', weaponConfig.name, weaponConfig.label, ammo, -1, true, false, false, 'weapon'))
                end
            end
        end
        
        ---@param itemName string
        self.IsItemDroppable = function(itemName)
            if General.Config.DisableDrop and General.Config.DisableDrop[itemName] then
                return false
            end

            return true
        end

        ---@return void
        self.AddRegularItems = function()
            local inventory = ESX.GetPlayerData().inventory
            
            for _, item in ipairs(inventory) do
                if item.count > 0 then
                    table.insert(self.Items, self.NewItem(
                        'item_standard',
                        item.name,
                        item.label, 
                        item.count,
                        item.limit,
                        item.usable,
                        self.IsItemDroppable(item.name),
                        item.canRemove
                    ))
                end
            end
        end

        ---@param data table
        ---@return void
        self.SetWeapon = function(data)
            if self.IsBusy then return end
            self.IsBusy = true

            local ped = PlayerPedId()

            RequestAnimDict("reaction@intimidation@1h")
            while not HasAnimDictLoaded("reaction@intimidation@1h") do
                Citizen.Wait(10)
            end
            
            if self.CurrentWeapon == data.name then
                TaskPlayAnim(ped, "reaction@intimidation@1h", "outro", 8.0, -8.0, 2000, 50, 0, false, false, false)
                Citizen.Wait(1300)
                SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
                self.CurrentWeapon = nil
            else
                if self.CurrentWeapon then
                    TaskPlayAnim(ped, "reaction@intimidation@1h", "outro", 8.0, -8.0, 2000, 50, 0, false, false, false)
                    Citizen.Wait(1300)
                    SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
                end
                
                TaskPlayAnim(ped, "reaction@intimidation@1h", "intro", 8.0, -8.0, 2000, 50, 0, false, false, false)
                Citizen.Wait(2000)
                SetCurrentPedWeapon(ped, GetHashKey(data.name), true)
                
                self.CurrentWeapon = data.name
                ClearPedTasks(ped)
            end

            self.IsBusy = false
        end

        ---@param item string
        ---@return boolean
        self.IsPlayerHasWeapon = function(item)
            local ped = PlayerPedId()
            for _, v in ipairs(ESX.GetConfig().Weapons) do
                local weaponHash = GetHashKey(v.name)
                if weaponHash == GetHashKey(item) then
                    return HasPedGotWeapon(ped, weaponHash, false)
                end
            end

            return false
        end

        ---@param index number
        self.UseSlot = function(index)
            if self.IsBusy then return end

            local currentHotbar = self.QuickSlot[self.CurrentHotbar]
            local slotItem = currentHotbar[index]
            
            if not slotItem then return end
            
            -- Open hotbar UI feedback
            Utils.SendNui('open-hot-bar')
            
            -- Weapon handling
            if Utils.StartsWith(slotItem.name, 'WEAPON_') then
                if not self.IsPlayerHasWeapon(slotItem.name) then return end
                -- Set weapon 
                self.SetWeapon(slotItem)
                self.CloseInventory()
                return
            end
            
            -- Accessory handling
            if slotItem.type == 'item_accessories' then
                self.UseAccessory(slotItem.name, slotItem)
                self.CloseInventory()
                return
            end

            -- Regular item handling
            local playerInventory = ESX.GetPlayerData().inventory
            local inventoryItem = nil

            for _, item in ipairs(playerInventory) do
                if item.name == slotItem.name then
                    inventoryItem = item
                    break
                end
            end

            if General.Config.FashionItems and General.Config.FashionItems[slotItem.name] then
                Utils.SendNui('toggle-item-active', { name = slotItem.name })
                return
            end
            
            if inventoryItem and inventoryItem.usable and inventoryItem.count > 0 then
                TriggerServerEvent('esx:useItem', slotItem.name)
            end
        end

        ---@param plate string
        ---@return boolean
        self.HasVehicleKey = function(plate)
            if self.VehicleKeys and #self.VehicleKeys > 0 then
                for i = 1, #self.VehicleKeys do
                    local keyPlate = self.VehicleKeys[i]
                    if keyPlate == plate then
                        return true
                    end
                end
            end
            
            return false
        end
        
        self.CloseInventory = function()
            self.NuiFocus(false)
            Utils.SendNui('close-inventory')
        end

        return self
    end,

    --| Other Player Inventory |--
    OtherPlayerInventory = function()
        local self = {}

        self.Items = {}

        self.CompileInventory = function(inventory)
            if not inventory or not next(inventory) then
                Debug('error', "^1[Other Player Inventory] Invalid inventory data")
                return
            end

            self.Items = {}

            if inventory.accounts then
                for accountName, accountAmount in pairs(inventory.accounts) do
                    if accountAmount > 0 then
                        local accountData = {
                            label = accountName:gsub("_", " "):gsub("^%l", string.upper), -- Format label
                            count = accountAmount,
                            type = 'item_account',
                            name = accountName,
                            usable = false,
                            rare = false,
                            limit = -1,
                            canRemove = false
                        }

                        table.insert(self.Items, accountData)
                    end
                end
            end
            
            -- Process Standard Items
            if inventory.items then
                for itemName, itemCount in pairs(inventory.items) do
                    if itemCount > 0 then
                        local processedItem = {
                            label = itemName:gsub("_", " "):gsub("^%l", string.upper), -- Format label
                            count = itemCount,
                            type = 'item_standard',
                            name = itemName,
                            usable = false,
                            rare = false,
                            limit = -1,
                            canRemove = false
                        }

                        table.insert(self.Items, processedItem)
                    end
                end
            end

            -- Process Weapons.
            if inventory.weapons then
                for weaponName, _ in pairs(inventory.weapons) do
                    local weaponHash = GetHashKey(weaponName)
                    local playerPed = PlayerPedId()
                    if weaponName ~= 'WEAPON_UNARMED' then
                        local ammo = GetAmmoInPedWeapon(playerPed, weaponHash)
                        local processedWeapon = {
                            label = weaponName:gsub("_", " "):gsub("^%l", string.upper),
                            count = ammo or 0,
                            limit = -1,
                            type = 'item_weapon',
                            name = weaponName,
                            usable = false,
                            rare = false,
                            canRemove = true
                        }

                        table.insert(self.Items, processedWeapon)
                    end
                end
            end
            

            -- Send Items to NUI
            -- Utils.SendNui('setup-other-initial-items', {
            --     inventory = self.Items
            -- })

            return self.Items
        end

        return self
    end
}