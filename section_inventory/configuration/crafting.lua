Crafting = Crafting or {}

Crafting.General = {
    [1] = {
        Categories = 'Normal',
        Lists = {
            ['exp'] = {
                Label = 'Experience',
                Amount = {
                    Min = 1,   
                    Max = 10,
                },

                Rate = 50,
                Duration = {
                    Timer = 10, -- In seconds
                    Multiply = 1
                },

                -- Materials items for crafting.
                Materials = {
                    -- Money accounts
                    Money = {
                        ['black_money'] = {
                            Label = 'Black Money',
                            Need = 100
                        },
                        ['money'] = {
                            Label = 'Money',
                            Need = 100
                        }
                    }, 

                    -- Items for crafting
                    Items = {
                        ['exp'] = {
                            Label = 'Experience',
                            Need = 5
                        }
                    }
                },

                AfterSuccess = function()

                end,

                AfterFailed = function()

                end
            }
        }
    },
}