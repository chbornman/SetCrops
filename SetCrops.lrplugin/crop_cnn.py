import torch
import torch.nn as nn
import torch.nn.functional as F

class CropCNN(nn.Module):
    def __init__(self):
        super(CropCNN, self).__init__()
        self.conv1 = nn.Conv2d(3, 16, kernel_size=3, stride=2, padding=1)
        self.conv2 = nn.Conv2d(16, 32, kernel_size=3, stride=2, padding=1)
        self.conv3 = nn.Conv2d(32, 64, kernel_size=3, stride=2, padding=1)
        self.fc1 = nn.Linear(64 * 32 * 32, 128)  # Adjust size according to your input image size
        self.fc2 = nn.Linear(128, 5)  # 5 output values for [crop_left, crop_top, crop_right, crop_bottom, crop_angle]

    def forward(self, x):
        x = F.relu(self.conv1(x))
        x = F.relu(self.conv2(x))
        x = F.relu(self.conv3(x))
        x = x.view(x.size(0), -1)  # Flatten
        x = F.relu(self.fc1(x))
        x = self.fc2(x)  # No activation, as we want direct coordinate values
        return x
