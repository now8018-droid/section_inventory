Developer = Developer or {}
ResourceName = GetCurrentResourceName()

---@param eventName string
---@return string
InvEvent = function(eventName)
    return ('%s:%s'):format(ResourceName, eventName)
end

---@param commandName string
---@return string
InvCommand = function(commandName)
    return ('%s.%s'):format(ResourceName, commandName)
end

Developer.Mode = {
    -- Enable developer mode
    DebugerMode = true,
}

Debug = function(_type, message)
    if not Developer.Mode.DebugerMode then return end

    local types = {
        ok      = { color = 2, prefix = 'OK' },
        success = { color = 2, prefix = 'SUCCESS' },
        error   = { color = 1, prefix = 'ERROR' },
        warn    = { color = 3, prefix = 'WARNING' },
        info    = { color = 5, prefix = 'INFO' },
    }

    local t = types[_type]
    if not t then return end

    local prefix = ('[^%s%s^7]'):format(t.color, t.prefix)

    if type(message) == 'table' then
        print(prefix .. ' [DumpTable]')
        print(ESX.DumpTable(message))
    else
        print(('%s %s^7'):format(prefix, message))
    end
end

