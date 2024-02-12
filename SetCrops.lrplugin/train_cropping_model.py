import os
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader
from torchvision import transforms
from PIL import Image
from crop_cnn import CropCNN

class FilmDataset(Dataset):
    def __init__(self, original_dir, transform=None):
        self.original_dir = original_dir
        self.transform = transform
        self.original_files = sorted([f for f in os.listdir(original_dir) if os.path.isfile(os.path.join(original_dir, f))])

    def __len__(self):
        return len(self.original_files)

    def __getitem__(self, idx):
        img_name = self.original_files[idx]
        original_img_path = os.path.join(self.original_dir, img_name)

        original_image = Image.open(original_img_path).convert('RGB')

        if self.transform:
            original_image = self.transform(original_image)

        # Placeholder for getting the coordinates
        coordinates = self.get_coordinates_for_image(img_name)

        # Convert coordinates to a tensor
        coordinates_tensor = torch.tensor(coordinates, dtype=torch.float32)

        return original_image, coordinates_tensor

    def get_coordinates_for_image(self, img_name):
        # Determine the base name (without extension) and construct the crop data file path
        base_name = os.path.splitext(img_name)[0]
        crop_data_path = os.path.join("crop_data_full", base_name + ".txt")

        # Check if the crop data file exists
        if not os.path.exists(crop_data_path):
            raise FileNotFoundError(f"Crop data file not found for image: {img_name}")

        # Read the crop data file
        with open(crop_data_path, 'r') as file:
            lines = file.readlines()
            # Parse the lines to get the crop values
            crop_left = float(lines[0].strip())
            crop_right = float(lines[1].strip())
            crop_top = float(lines[2].strip())
            crop_bottom = float(lines[3].strip())
            crop_angle = float(lines[4].strip())

        # Return the crop values
        return [crop_left, crop_right, crop_top, crop_bottom, crop_angle]

# Example usage
transform = transforms.Compose([
    transforms.Resize((256, 256)),
    transforms.ToTensor()
])

dataset = FilmDataset(original_dir='original_files_full', transform=transform)
dataloader = DataLoader(dataset, batch_size=4, shuffle=True)

# Model, Loss Function, and Optimizer
model = CropCNN()
criterion = nn.MSELoss()
optimizer = optim.Adam(model.parameters(), lr=0.001)

# Training loop
num_epochs = 10 

for epoch in range(num_epochs):
    for i, (images, coordinates) in enumerate(dataloader):
        # 'coordinates' should contain the crop coordinates for each image
        outputs = model(images)
        loss = criterion(outputs, coordinates)

        optimizer.zero_grad()
        loss.backward()
        optimizer.step()

        if (i+1) % 100 == 0:
            print(f'Epoch [{epoch+1}/{num_epochs}], Step [{i+1}/{len(dataloader)}], Loss: {loss.item()}')

print("Training complete!")

torch.save(model.state_dict(), 'film_cropping_model.pth')
