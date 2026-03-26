Notification = Notification or {}

Notification.Push = {
    Executor = function(type, xPlayer, key, ...)
        local event = 'mythic_notify:client:SendAlert'
        local text = Notification.Push.Locales[key] or key

        -- %s
        if select('#', ...) > 0 then
            text = string.format(text, ...)
        end

        local data = { 
            type = type,
            text = text,
            timeout = 4000
        }

        if IsDuplicityVersion() then
            TriggerClientEvent(event, xPlayer.source, data)
        else
            TriggerEvent(event, data)
        end
    end,

    Locales = {
        -- Inventory
        CannotDropItem = 'ไอเท็ม %s ไม่สามารถทิ้งได้!',

        -- Vault   
        VaultBlacklistItem = 'ไอเท็ม %s ไม่สามารถย้ายเข้าตู้เซฟเเละออกตู้เซฟได้เนื่องจากถูกบล็อคบนระบบ!',
        VaultNotEnoughSpace = 'ไอเท็ม %s ในกระเป๋าหลักของคุณมีพื้นที่ลิมิตไม่พอ!',
        VaultJobAccess = 'คุณไม่มีสิทธิ์เข้าถึงตู้เซฟ %s นี้!',

        -- Trunk
        TrunkBlacklistItem = 'ไอเท็ม %s ไม่สามารถย้ายเข้าตู้ได้เนื่องจากถูกบล็อคบนระบบ!',
        TrunkSlotsFull = 'ท้ายรถของคุณมีรายการไอเท็มเต็มแล้ว!',
        TrunkItemLimit = 'ลิมิตของไอเท็ม %s ไม่พอต่อการใส่ไอเท็มนี้!',
        
        -- Give 
        PlayerNotFound = 'ไม่พบผู้เล่นทีอยู่ใกล้คุณ!',
        PlayerDead = 'ผู้เล่นที่เลือกมีสถานะเสียชีวิต!',
        InvalidItemAmount = 'จํานวนไอเท็มไม่ถูกต้อง!',
        PlayerNotAcceptingItems = 'ผู้เล่นฝ่ายตรงข้ามปิดรับมอบของ!',
        ItemCannotBeGiven = 'ไอเท็ม %s นี้ไม่สามารถให้ได้เนื่องจากถูกบล็อคบนระบบ!',

        -- Other Player
        NoPermissionOpen = 'คุณไม่มีสิทธิ์เปิดกระเป๋าผู้เล่นอื่น!',
        NoPermissionTrade = 'คุณไม่มีสิทธิ์ดึงไอเท็มประเภท %s!',
        TargetHasWeapon = 'ผู้เล่นเป้าหมายมีอาวุธนี้อยู่แล้ว!',
    }
}

