return {

    LrSdkVersion = 6.0,
    LrSdkMinimumVersion = 6.0,
    LrToolkitIdentifier = 'chbornman.getcrops',

    LrPluginName = "GetCrops",

    LrExportMenuItems = {
        {
            title = "Get Crop Data",
            file = "GetCrops.lua",
            enabledWhen = "photosSelected"
        }
    },

    VERSION = {
        major=1,
        minor=0,
        revision=0,
    }
}