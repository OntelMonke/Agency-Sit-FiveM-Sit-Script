Config = {}

-- =============================================
-- AGENCY-NOTIFY INTEGRATION
-- =============================================
-- Official Agency-Notify resource for beautiful notifications
-- Get it here: https://agency-script.tebex.io/package/6937769
-- Discord Support: https://discord.gg/zbG53tTUXR
Config.UseAgencyNotify = true

Config.UseOxTargetIfAvailable = true
Config.InteractKey = 38 -- E
Config.InteractDistance = 1.8
Config.DrawDistance = 8.0

Config.ScanRadius = 25.0
Config.ScanIntervalMs = 1500
Config.Debug = false

Config.BackrestProbeDistance = 0.75
Config.BackrestProbeHeight = 0.55
Config.BackrestGap = 0.42

Config.SeatAdjustOffset = vector3(0.0, 0.0, 0.0)
Config.SeatAdjustHeading = 0.0

Config.StandAnimDict = 'anim@amb@prop_human_seat_chair@male@generic@exit'
Config.StandAnimName = 'exit'
Config.StandAnimDurationMs = 1100

Config.DefaultHeadingOffset = 180.0

Config.SitScenario = 'PROP_HUMAN_SEAT_BENCH'

Config.SittableModels = {
    -- Add chair/bench prop model names here.
    'prop_bench_01a',
    'prop_bench_01b',
    'prop_bench_01c',
    'prop_bench_02',
    'prop_bench_03',
    'prop_bench_04',
    'prop_chair_01a',
    'prop_chair_01b',
    'prop_chair_02',
    'prop_chair_03',
    'prop_chair_04a',
    'prop_chair_04b',
}

Config.ModelOffsets = {
}
