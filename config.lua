lib.locale()

Config = {}
Config.DistressButton = 58 --https://docs.fivem.net/docs/game-references/controls/

Config.Dispatch = 'none'   --(cd_dispatch, quasar, default)
Config.OxTarget = true

Config.InjuriedBlip = { -- https://docs.fivem.net/docs/game-references/blips/
    scale = 0.8,
    colour = 59,
    sprite = 303
}

Config.DeathTime = 500                         --In seconds
Config.Job = 'ambulance'
Config.WhitelistedItems = { 'phone', 'radio' } --When the player respawn these things dontt get deleted


Config.Hopsitals = { -- You can add more hospital if you want
    { name = 'Pillbox Hill Hospital', coords = vector4(298.7979, -584.2709, 43.2608, 73.3128) },
    { name = 'Sandy Shores Hospital', coords = vector4(1839.2195, 3673.0483, 34.2767, 211.8064) },
    { name = 'Paleto Bay Hospital',   coords = vector4(-248.0382, 6332.0825, 32.4261, 245.1467) }

}
