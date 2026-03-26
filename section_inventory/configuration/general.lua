General = General or {}

---@description Accessory Configuration ตัวอย่างการเชื่อมร้านหน้ากาก
--[[

    Resource : esx_accessories (ร้านหน้ากาก)

    -- Server-Side (ฝั่ง Server) --
    TriggerEvent("section_inventory:saveAccessories", _source, label, type, skin)

]]--

---@description Close inventory nuis. (ปิดหน้าต่าง inventory)
--[[

    -- Client-Side (ฝั่ง Client) --
    TriggerEvent('section_inventory:closeNuis')

]]--

---@description General Configuration
General.Config = {
    Inventory = {
        Main = {
            Command = 'section_inventory.open',
            Key = 'T' -- อย่าลืมเปลี่ยนชื่อ Command นะครับหากเปลี่ยนปุ่ม เปลี่ยนเป็นชื่ออะไรก็ได้ครับ
        },
        QuickSlot = {
            Command = 'section_inventory.open.swap',
            Key = 'TAB' -- อย่าลืมเปลี่ยนชื่อ Command นะครับหากเปลี่ยนปุ่ม เปลี่ยนเป็นชื่ออะไรก็ได้ครับ
        }
    },

    -- Job Permissions (สําหรับการเปิดกระเป๋าของผู้เล่น)
    JobPermissions = {
        ['superadmin'] = {
            CanOpen = true,
            AllowedTypes = { 'item_standard', 'item_money', 'item_weapon', 'item_account' }
        },
        ['admin'] = {
            CanOpen = true,
            AllowedTypes = { 'item_standard', 'item_money', 'item_weapon', 'item_account' }
        },
        ['police'] = {
            CanOpen = true,
            Grades = {
                [0] = { 'item_standard' },
                [1] = { 'item_standard', 'item_weapon' },
                [2] = { 'item_standard', 'item_weapon', 'item_account' },
                [3] = { 'item_standard', 'item_money', 'item_weapon', 'item_account' },
                [4] = { 'item_standard', 'item_money', 'item_weapon', 'item_account' }
            }
        },
        ['ambulance'] = {
            CanOpen = true,
            AllowedTypes = { 'item_standard' }
        }
    },    
    
    -- ID Card (เชื่อม Id Card เมื่อกดใช้งาน)
    IdCard = function(myId, closestPlayer)
        -- event:emitNet('msc-card:openIdCard', myId, closestPlayer)
    end,

    -- Car Key (เชื่อมกุญเเจรถ Car Key เมื่อกดใช้งานผ่านกระเป๋า)
    CarKey = function(keyName)
        -- TriggerServerEvent("meeta_remote:useKey", keyName)
        Debug('info', string.format("^2Used car key: %s", keyName))
    end,

    -- Fashion Items (เมื่อกดใช้งานเเฟชั่นมันจะขึ้นไอคอนเเสดงสถานะ)
    FashionItems = {
        ['exp'] = true,
    },

    -- Accessories
    Accessories = {
        -- Animation
        Animation = {
            helmet = { 'veh@bicycle@roadfront@base', 'put_on_helmet' },
            mask = { 'veh@bicycle@roadfront@base', 'put_on_helmet' },
            glasses = { 'clothingspecs', 'try_glasses_positive_a' },
            ears = { 'mini@ears_defenders', 'takeoff_earsdefenders_idle' },

            takeOff = {
                helmet = { 'veh@bike@common@front@base', 'take_off_helmet_walk' },
                mask = { 'veh@bike@common@front@base', 'take_off_helmet_walk' },
                glasses = { 'clothingspecs', 'try_glasses_positive_a' },
                ears = { 'mini@ears_defenders', 'takeoff_earsdefenders_idle' }
            }
        },
    },

    -- Item Categories
    ---@type 'string' | 'cloths' | 'weapons' | 'keys' | 'foods' | 'fashions' | 'others'
    Categories = {
        ['exp'] = 'cloths',
        ['durian_2'] = 'foods',
        ['copperore'] = 'foods',
    },

    -- Give Blacklists (ปิดใช้งานการกิฟไอเทม)
    DisableGive = {
        ['exp'] = true,
    },

    -- Drop Blacklists (ปิดใช้งานการทิ้งไอเท็ม)
    DisableDrop = {
        ['exp'] = true,
    },

    -- Close Inventory (ใช้งานไอเท็มอะไรถึงจะให้กระเป๋าปิด?)
    CloseOnUse = {
        ['exp'] = true,
    },

    HoverDesc = {
        ['exp'] = 'พลังแห่งการเติบโต ยิ่งสะสมยิ่งแกร่ง!',
        ['goldore'] = 'ทองคำบริสุทธิ์! เปล่งประกายแห่งความมั่งคั่ง ค้นพบได้จากซากรถโบราณ!',
        ['copperore'] = 'แร่ทองแดงจากเหมืองใต้ดิน วัตถุดิบหลักในการสร้างเครื่องมือและอุปกรณ์!',
    }
}


