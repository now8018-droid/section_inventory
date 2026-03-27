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
local waitTime = 1500

--| Modules functions. |--
Inventory = Functions.Inventory()
local hasVaultExport, vaultModule = pcall(function()
    return exports['section_vaults']:getVault()
end)

Vault = hasVaultExport and vaultModule or {
    GetInventory = {
        JobType = nil,
        CompileVaultItems = function()
            return {}
        end
    },
    GetValidItems = {
        BlackLists = function()
            return false
        end
    }
}

if not hasVaultExport then
    Debug('warn', '[Vault] Missing export getVault from resource section_vaults; vault interactions disabled')
end

RegisterNetEvent('msc.vault:opened', 
    function(itemData, vaultType)
        Vault.GetInventory.JobType = vaultType
        
        Utils.SendNui('set-inventory-type', {
            modal = 'vault'
        })
        
        local Items = Vault.GetInventory.CompileVaultItems(itemData)
        Utils.SendNui('setup-other-initial-items', {
            inventory = Items
        })

        Citizen.Wait(200)
        Inventory.InitInventory()
        Inventory.OpenOtherInventory()
    end
)

RegisterNUICallback('putVault', 
    function(itemData)
        local ped = PlayerPedId()
        if IsPedSittingInAnyVehicle(ped) then return end

        local validItems = Vault.GetValidItems.BlackLists(itemData.item)
        if not validItems then
            Debug('error', "^1[Vaults] Item is blacklisted")
            pcall(function()
                Notification.Push.Executor('error', nil, 'VaultBlacklistItem', itemData.item.name)
            end)

            return
        end
        
        local inputCount = tonumber(itemData.modalAmount)
        if not inputCount or math.floor(inputCount) ~= inputCount then
            Debug('error', "^1[Vaults] Invalid item count")
            return
        end
        
        local finalCount = inputCount
        if inputCount == 0 or inputCount > itemData.item.count then
            finalCount = 1
        end

        -- Put Item into Vault
        TriggerServerEvent('msc.vault:putItem', Vault.GetInventory.JobType, itemData.item.name, finalCount)
    end
)

RegisterNetEvent('msc.vault:putSync', 
    function(data)
        if not data or not data.n or not data.a then
            Debug('error', "^1[Vaults] Invalid item data received")
            return
        end

        Debug('info', string.format("^2[Vaults] Item updated: %s x%s", data.n, data.a))
        Utils.SendNui('update-vault-item', {
            name = data.n,
            count = data.a
        })
    end
)

RegisterNUICallback('takeVault', 
    function(itemData)
        local ped = PlayerPedId()
        if IsPedSittingInAnyVehicle(ped) then return end
    
        local inputCount = tonumber(itemData.modalAmount)
        if not inputCount or math.floor(inputCount) ~= inputCount then
            return
        end
        
        local finalCount = Utils.CalculateAvailableSpace(itemData.item.name, inputCount)
        
        if finalCount <= 0 then
            Debug('error', 'Not enough space in inventory')
            pcall(function()
                Notification.Push.Executor('error', nil, 'VaultNotEnoughSpace', itemData.item.name)
            end)

            return
        end
        
        if inputCount == 0 or inputCount > itemData.item.count then
            finalCount = math.min(1, Utils.CalculateAvailableSpace(itemData.item.name, 1))
        end
        
        -- Take Item from Vault
        TriggerServerEvent('msc.vault:getItem', Vault.GetInventory.JobType, itemData.item.name, finalCount)
    end
)

RegisterNetEvent('msc.vault:getSync', 
    function(data)
        if not data or not data.n then
            Debug('error', "^1[Vault] Invalid item data received")
            return
        end

        if not data.a then
            Debug('info', string.format("^3[Vault] Removing item: %s from UI", data.n))
            Utils.SendNui('remove-vault-item', {
                name = data.n
            })
        else
            Debug('info', string.format("^2[Vault] Item updated: %s x%s", data.n, data.a))
            Utils.SendNui('update-vault-item', {
                name = data.n,
                count = data.a
            })
        end
    end
)

