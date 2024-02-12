return {

    LrSdkVersion = 6.0,
    LrSdkMinimumVersion = 6.0,
    LrToolkitIdentifier = 'chbornman.setcrops',

    LrPluginName = "SetCrops",

    LrExportMenuItems = {
        {
            title = "Set Crop Data",
            file = "SetCrops.lua",
            enabledWhen = "photosSelected"
        }
    },

    VERSION = {
        major=1,
        minor=0,
        revision=0,
    }
}