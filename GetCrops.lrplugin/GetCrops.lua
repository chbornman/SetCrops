-- LR imports
local LrApplication = import("LrApplication")
local LrApplicationView = import("LrApplicationView")
local LrBinding = import("LrBinding")
local LrDevelopController = import("LrDevelopController")
local LrDialogs = import("LrDialogs")
local LrExportSession = import("LrExportSession")
local LrFileUtils = import("LrFileUtils")
local LrFunctionContext = import("LrFunctionContext")
local LrLogger = import("LrLogger")
local LrPathUtils = import("LrPathUtils")
local LrProgressScope = import("LrProgressScope")
local LrTasks = import("LrTasks")

-- ... [previous imports]

local log = LrLogger("GetCrop")
log:enable("logfile")

-- Output directory for crop data files
local outputDir = LrPathUtils.child(_PLUGIN.path, "crop_data_output")

if LrFileUtils.exists(outputDir) ~= true then
  LrFileUtils.createDirectory(outputDir)
end

-- Function to retrieve crop values
function getCrop(photo)
  local settings = photo:getDevelopSettings()
  local cropData = {
    left = settings.CropLeft,
    right = settings.CropRight,
    top = settings.CropTop,
    bottom = settings.CropBottom,
    angle = settings.CropAngle
  }
  return cropData
end

-- Function to write crop data to a file
function writeCropDataToFile(photo, cropData)
  local fileName = photo:getFormattedMetadata("fileName")
  local filePath = LrPathUtils.child(outputDir, fileName .. "_crop.txt")

  local file = io.open(filePath, "w")
  if file then
    file:write(cropData.left .. "\n")
    file:write(cropData.right .. "\n")
    file:write(cropData.top .. "\n")
    file:write(cropData.bottom .. "\n")
    file:write(cropData.angle .. "\n")
    file:close()
  else
    log:error("Unable to open file for writing: " .. filePath)
  end
end

-- Main function to process selected photos
function processSelectedPhotos()
  LrFunctionContext.callWithContext("export", function(context)
    local catalog = LrApplication.activeCatalog()
    local targetPhotos = catalog.targetPhotos

    for _, photo in ipairs(targetPhotos) do
      local cropData = getCrop(photo)
      writeCropDataToFile(photo, cropData)
    end

    LrDialogs.message("Crop data export complete", "Crop data for selected photos have been written to " .. outputDir)
  end)
end

-- Execute the main function
LrTasks.startAsyncTask(processSelectedPhotos)

return {}
