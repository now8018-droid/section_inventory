--| Modules functions. |--
Inventory = Functions.Inventory()

for index = 1, 7 do
    local commandName = ('%s_hotbar_%s'):format(ResourceName, index)
    RegisterCommand(commandName, 
        function()
            local isDead = Utils.IsDead()
            if not isDead then
                Inventory.UseSlot(index)
            end
        end, false
    )

    RegisterKeyMapping(commandName, ('Key for using quick slot %s'):format(index), 'keyboard', tostring(index))
end

RegisterCommand(General.Config.Inventory.QuickSlot.Command, 
    function()
        Utils.SendNui('open-hot-bar')
        Inventory.CurrentHotbar = 3 - Inventory.CurrentHotbar
        Utils.SendNui('set-active-quickslot', { row = Inventory.CurrentHotbar - 1 })
    end, false
)

RegisterKeyMapping(General.Config.Inventory.QuickSlot.Command, 'Key for swapping active slot', 'keyboard', General.Config.Inventory.QuickSlot.Key)

RegisterNUICallback('updateActiveQuickSlot', 
    function(data)
        Inventory.CurrentHotbar = tonumber(data.row)
    end
)

RegisterNUICallback('updateQuickSlot', 
    function(data)
        Inventory.QuickSlot = data
    end
)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        BlockWeaponWheelThisFrame()
        HudWeaponWheelIgnoreSelection()
        DisableControlAction(0, 37, true) -- INPUT_SELECT_WEAPON (TAB)
        DisableControlAction(0, 45, true) -- INPUT_RELOAD
    end
end)
