Core = {}
Core.Input = {}
Core.Events = {}

ESX.PlayerData = {}

-- NPC systems removed: disable ambient population/cops once on startup.
CreateThread(function()
    SetPedPopulationBudget(0)
    SetVehiclePopulationBudget(0)
    SetCreateRandomCops(false)
    SetCreateRandomCopsNotOnScenarios(false)
    SetCreateRandomCopsOnScenarios(false)
end)
ESX.PlayerLoaded = false
ESX.playerId = PlayerId()
ESX.serverId = GetPlayerServerId(ESX.playerId)

ESX.UI = {}
ESX.UI.Menu = {}
ESX.UI.Menu.RegisteredTypes = {}
ESX.UI.Menu.Opened = {}

ESX.Game = {}
ESX.Game.Utils = {}

local joinFreezeThreadActive = false
local joinFreezeActive = false
local joinFreezePendingStart = false

local defaultJoinFreezeControls = { 30, 31, 32, 33, 34, 35 }

local function getJoinFreezeConfig()
    local config = Config and Config.JoinFreeze
    if type(config) ~= "table" then
        return {}
    end

    return config
end

local function getJoinFreezeNumber(config, key, fallback)
    local value = tonumber(config[key])
    if value == nil then
        return fallback
    end

    return value
end

local function getJoinFreezeControls(config)
    if type(config.movementControls) == "table" and #config.movementControls > 0 then
        return config.movementControls
    end

    return defaultJoinFreezeControls
end

local function setJoinFreezeState(active, forceZeroVelocity)
    local ped = PlayerPedId()

    if ped <= 0 or not DoesEntityExist(ped) then
        return
    end

    if forceZeroVelocity then
        SetEntityVelocity(ped, 0.0, 0.0, 0.0)
    end

    FreezeEntityPosition(ped, active)
end

function Core.StopJoinFreeze()
    if not joinFreezePendingStart and not joinFreezeActive then
        return
    end

    joinFreezePendingStart = false
    joinFreezeActive = false
    setJoinFreezeState(false, false)
end

local function applyRemovedHudComponents()
    local config = Config and Config.RemoveHudComponents
    if type(config) ~= "table" then
        return
    end

    for i = 1, #config do
        if config[i] then
            SetHudComponentSize(i, 0.0, 0.0)
            SetHudComponentPosition(i, 900.0, 900.0)
        end
    end
end

function Core.StartJoinFreeze(skipDelay)
    local config = getJoinFreezeConfig()

    if config.enabled == false then
        Core.StopJoinFreeze()
        return
    end

    if not skipDelay then
        local startDelay = math.max(0, getJoinFreezeNumber(config, "startDelayMs", 0))
        if startDelay > 0 then
            if joinFreezePendingStart or joinFreezeActive then
                return
            end

            joinFreezePendingStart = true
            SetTimeout(startDelay, function()
                if not joinFreezePendingStart or joinFreezeActive then
                    return
                end

                joinFreezePendingStart = false
                Core.StartJoinFreeze(true)
            end)
            return
        end
    end

    joinFreezePendingStart = false
    joinFreezeActive = true

    local forceZeroVelocity = config.forceZeroVelocity ~= false
    setJoinFreezeState(true, forceZeroVelocity)

    if joinFreezeThreadActive then
        return
    end

    joinFreezeThreadActive = true

    CreateThread(function()
        local startedAt = GetGameTimer()
        local autoTimeout = math.max(0, getJoinFreezeNumber(config, "autoUnfreezeTimeoutMs", 15000))
        local pollInterval = math.max(0, getJoinFreezeNumber(config, "pollIntervalMs", 0))
        local controls = getJoinFreezeControls(config)
        local unfreezeOnMovement = config.unfreezeOnMovement ~= false

        while joinFreezeActive do
            local shouldUnfreeze = false

            if autoTimeout > 0 and (GetGameTimer() - startedAt) >= autoTimeout then
                shouldUnfreeze = true
            end

            if not shouldUnfreeze and unfreezeOnMovement then
                for i = 1, #controls do
                    if IsControlPressed(0, controls[i]) then
                        shouldUnfreeze = true
                        break
                    end
                end
            end

            if shouldUnfreeze then
                Core.StopJoinFreeze()
                break
            end

            setJoinFreezeState(true, forceZeroVelocity)
            Wait(pollInterval)
        end

        joinFreezeThreadActive = false
    end)
end

local function waitForPlayerActivation()
    if not NetworkIsPlayerActive(ESX.playerId) then
        return SetTimeout(100, waitForPlayerActivation)
    end

    applyRemovedHudComponents()

    ESX.DisableSpawnManager()
    DoScreenFadeOut(0)
    Wait(250)
    TriggerServerEvent("esx:onPlayerJoined")
end

CreateThread(waitForPlayerActivation)
