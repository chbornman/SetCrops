# SetCrops Lightroom Plugin

An Adobe Lightroom plugin that crops the dark edges of digitized slides. **Currently the model is not quite good enough for general use, but I hope to improve that soon.**

This is my first "real" coding personal project, and I welcome feedback and suggestions! I used ChatGPT to do a lot of the implementation, and I know close to nothing about setting up neural networks.

I was inspired by [AutoCrop.lua](https://gist.github.com/stecman/91cb5d28d330550a1dc56fa29215cb85) but wanted something for slides instead of negatives. I could have pursued a similar vein of using OpenCV, but I had already done a bunch of manual cropping of slides and wanted to learn a bit about PyTorch.

## How to Use

1. Add "SetCrops.lrplugin" to your Lightroom Plugins
2. Select image(s) to crop in the Library module
3. File->Plug-in Extras->Set Crop Data
4. Wait as it runs the images through the trained model

## Notes

- Like [AutoCrop.lua](https://gist.github.com/stecman/91cb5d28d330550a1dc56fa29215cb85), the SetCrops.lua exports a .jpg image into a python script, which then determines the left, right, top, and bottom edge along with a rotation value and writes it to a .txt file. Then SetCrops.lua reads those values into the Lightroom API and performs the crop and rotation on the image.
- This plugin can work on any file type, because the only transformation done is via decimal fractions in the .txt file. Nothing else changes about the photo.
- You can run "determine_data.py" separately from the lua script and pass the .jpg image and model paths as arguments. This will generate a .txt file with the crop data to be applied.
- You can get crop data from images you have cropped yourself in Lightroom by adding and running the GetCrops.lrplugin.
- You can train a new model with "train_cropping_model.py" using your own images and crop data in folders /original_files_full and /crop_data_full.
