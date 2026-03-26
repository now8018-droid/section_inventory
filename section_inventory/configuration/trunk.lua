Vehicle = Vehicle or {}

Vehicle.Config = {
    -- Vehicle Class Names * ห้ามเเก้ไข
    ClassNames = {
        [0] = 'compacts',
        [1] = 'sedans',
        [2] = 'suvs',
        [3] = 'coupes',
        [4] = 'muscle',
        [5] = 'sports classics',
        [6] = 'sports',
        [7] = 'super',
        [8] = 'motorcycles',
        [9] = 'off-road',
        [10] = 'industrial',
        [11] = 'utility',
        [12] = 'vans',
        [13] = 'cycles',
        [14] = 'boats',
        [15] = 'helicopters',
        [16] = 'planes',
        [17] = 'service',
        [18] = 'emergency',
        [19] = 'military',
        [20] = 'commercial',
        [21] = 'trains'
    },

    -- Vehicle default slots.
    VehicleSlots = {
        ['compacts']           =   { Slots  = -1 },
        ['sedans']             =   { Slots  = -1 },
        ['suvs']               =   { Slots  = -1 },
        ['coupes']             =   { Slots  = -1 },
        ['muscle']             =   { Slots  = -1 },
        ['sports classics']    =   { Slots  = -1 },
        ['sports']             =   { Slots  = 10 },
        ['super']              =   { Slots  = -1 },
        ['motorcycles']        =   { Slots  = -1 },
        ['off-road']           =   { Slots  = -1 },
        ['vans']               =   { Slots  = -1 },
        ['emergency']          =   { Slots  = -1 },
        ['industrial']         =   { Slots  = -1 },
        ['utility']            =   { Slots  = -1 },
        ['cycles']             =   { Slots  = -1 },
        ['boats']              =   { Slots  = -1 },
        ['helicopters']        =   { Slots  = -1 },
        ['planes']             =   { Slots  = -1 },
        ['service']            =   { Slots  = -1 },
        ['military']           =   { Slots  = -1 },
        ['commercial']         =   { Slots  = -1 },
        ['trains']             =   { Slots  = -1 }
    },

    -- Items Max limit.
    ItemsLimit = {
        ['exp'] = 100,
        ['goldore'] = 100,
        ['copperore'] = 50
    },

    -- Trunk Blacklists
    TrunkBlacklists = {
        ['exp'] = true,
    },

    VehicleLists = {
        ['sports'] = {
            Unlimited = true, -- Items unlimited.
            Slots = -1, -- -1 = Unlimited
            -- Job allows to open.
            JobAllows = { 
                -- { Job = 'police', JobGrade = -1 },
                -- { Job = 'council', JobGrade = 3 },
            },

            -- Required Open
            RequiresLicenses = {
                ['exp'] = true,
            },
        },
    },

    VehicleListsPlate = {
        ['AAA 1234'] = {
            Unlimited = true, -- Items unlimited.
            Slots = -1, -- -1 = Unlimited
            -- Job allows to open.
            JobAllows = { 
                -- { Job = 'police', JobGrade = -1 },
                -- { Job = 'council', JobGrade = 3 },
            },

            -- Required Open
            RequiresLicenses = {
                ['exp'] = true,
            },
        }
    }
}
