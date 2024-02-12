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
local LrApplication = import 'LrApplication'
local LrDevelopController = import 'LrDevelopController'
local LrFunctionContext = import 'LrFunctionContext'


local function writeLog(message)
    local logFilePath = LrPathUtils.child(_PLUGIN.path, "plugin.log")
    local file = io.open(logFilePath, "a")
    if file then
        file:write(os.date("%Y-%m-%d %H:%M:%S") .. ": " .. message .. "\n")
        file:close()
    else
        -- Handle the error of not being able to open the log file
    end
end




-- Define the output directory path
local outputDir = LrPathUtils.child(_PLUGIN.path, "temp_export")
writeLog("Script started. Output directory: " .. outputDir)
if LrFileUtils.exists(outputDir) ~= "directory" then
    LrFileUtils.createDirectory(outputDir)
end

local pythonCommand = "/opt/homebrew/bin/python"  -- Or the full path to your Python executable
local pythonScriptPath = LrPathUtils.child(_PLUGIN.path, "determine_data.py")
local modelPath = LrPathUtils.child(_PLUGIN.path, "model.pth")


-- Function to run the Python script on an exported photo
function runPythonScriptOnPhoto(photoPath)
    local cmd = '"' .. pythonCommand .. '" "' .. pythonScriptPath .. '" "' .. photoPath .. '" "' .. modelPath .. '"'
    --writeLog("Executing Python script: " .. cmd)
    local result = LrTasks.execute(cmd) 
    if result ~= 0 then
        writeLog("Python script failed for photo: " .. photoPath)
    else
        writeLog("Python script executed successfully for photo: " .. photoPath)
    end
end


function waitForFile(filePath, callback)
    local attempts = 10
    LrTasks.startAsyncTask(function()
        while attempts > 0 do
            if LrFileUtils.exists(filePath) then
                callback()
                return
            end
            LrTasks.sleep(0.5)  -- Check every half second
            attempts = attempts - 1
        end
        log:error("Output file not found after waiting: " .. filePath)
    end)
end

-- Function to read crop data from a file
function readCropDataFromFile(photo)
    local baseFileName = LrPathUtils.removeExtension(photo:getFormattedMetadata("fileName"))
    local filePath = LrPathUtils.child(outputDir, baseFileName .. ".txt")
  
    if not LrFileUtils.exists(filePath) then
        log:error("Crop data file not found: " .. filePath)
        return nil
    end
  
    local file = io.open(filePath, "r")
    local cropData = {}
    if file then
        cropData.left = tonumber(file:read("*line"))
        cropData.right = tonumber(file:read("*line"))
        cropData.top = tonumber(file:read("*line"))
        cropData.bottom = tonumber(file:read("*line"))
        cropData.angle = tonumber(file:read("*line"))
        file:close()
    else
        log:error("Unable to open file for reading: " .. filePath)
        return nil
    end
  
    return cropData
end






  function exportPhoto(photo, exportSettings, callback)

    -- Modify exportSettings if necessary
    exportSettings.LR_export_useSubfolder = false  -- Ensure no subfolder is used
    -- exportSettings.LR_export_destinationPathSuffix = nil  -- Uncomment if needed
    
    local exportSession = LrExportSession({
        photosToExport = { photo },
        exportSettings = exportSettings,
        LR_export_destinationType = "specificFolder",
        LR_export_destinationPathPrefix = outputDir,
        LR_format = "JPEG",
        LR_jpeg_quality = 0.4,  -- Lower JPEG quality (scale 0-1)
        LR_outputSharpeningOn = false,
        LR_size_doConstrain = true,  -- Enable size constraint
        LR_size_maxWidth = 800,  -- Max width in pixels
        LR_size_maxHeight = 800,  -- Max height in pixels
    })

    -- Start the export session
    exportSession:doExportOnNewTask()

    -- Wait for the export to complete and then process the photo
    LrTasks.startAsyncTask(function()
        for _, rendition in exportSession:renditions() do
            local success, pathOrMessage = rendition:waitForRender()
            if success then
                callback(pathOrMessage)  -- Call the callback function with the exported file path
            else
                writeLog("Export failed: " .. pathOrMessage)
            end
        end
    end)
end




function applyCrop(photo, cropData)
    LrFunctionContext.callWithContext("applyCrop", function(context)
        local catalog = LrApplication.activeCatalog()

        catalog:withWriteAccessDo("Apply Crop", function()
            -- Switch to the Develop module
            LrApplicationView.switchToModule('develop')

            -- Ensure the photo is the active photo in the Develop module
            catalog:setSelectedPhotos(photo, {[photo] = true})

            -- Apply the crop settings
            LrDevelopController.setValue('CropLeft', cropData.left)
            LrDevelopController.setValue('CropTop', cropData.top)
            LrDevelopController.setValue('CropRight', cropData.right)
            LrDevelopController.setValue('CropBottom', cropData.bottom)
            LrDevelopController.setValue('CropAngle', cropData.angle)
        end)

        writeLog("Applied crop to photo: " .. photo:getFormattedMetadata("fileName"))
    end)
end





-- Global queue for processed photos
local processedQueue = {}
local isProcessingQueue = false

function addToQueue(item)
    table.insert(processedQueue, item)
    if not isProcessingQueue then
        processQueue()
    end
end

function processQueue()
    if #processedQueue == 0 then
        isProcessingQueue = false
        return
    end

    isProcessingQueue = true
    local item = table.remove(processedQueue, 1)

    -- Process the item (apply crop and cleanup)
    applyCrop(item.photo, item.cropData)
    -- Delete the .txt file for crop data
    if LrFileUtils.exists(item.cropDataFilePath) then
        LrFileUtils.delete(item.cropDataFilePath)
        writeLog("Deleted crop data file: " .. item.cropDataFilePath)
    end
    LrFileUtils.delete(item.exportedFilePath)  -- Clean up the temporary jpg file

    -- Continue processing the queue
    LrTasks.startAsyncTask(processQueue)
end

function processPhoto(photo)
    local fileName = photo:getFormattedMetadata("fileName")
    local exportSettings = {
        LR_export_destinationType = "specificFolder",
        LR_export_destinationPathPrefix = outputDir,
        LR_format = "JPEG",
        -- Additional export settings as needed
    }

    exportPhoto(photo, exportSettings, function(exportedFilePath)
        if exportedFilePath then
            runPythonScriptOnPhoto(exportedFilePath)
            local cropDataFilePath = LrPathUtils.replaceExtension(exportedFilePath, "txt")
            waitForFile(cropDataFilePath, function()
                local cropData = readCropDataFromFile(photo)
                if cropData then
                    addToQueue({photo = photo, cropData = cropData, cropDataFilePath = cropDataFilePath, exportedFilePath = exportedFilePath})
                end
            end)
        else
            writeLog("Failed to export photo: " .. fileName)
        end
    end)
end

-- Main function to process selected photos concurrently
function processSelectedPhotos()
    LrFunctionContext.callWithContext("export", function(context)
        local catalog = LrApplication.activeCatalog()
        local targetPhotos = catalog.targetPhotos

        for _, photo in ipairs(targetPhotos) do
            processPhoto(photo)
        end
    end)
end

-- Execute the main function
LrTasks.startAsyncTask(processSelectedPhotos)
writeLog("Script execution finished.")

return {}
