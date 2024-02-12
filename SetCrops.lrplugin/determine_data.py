import sys
import os
import torch
from torchvision import transforms
from PIL import Image
from crop_cnn import CropCNN
import traceback  # Import traceback for detailed error information

def load_model(model_path):
    model = CropCNN()
    model.load_state_dict(torch.load(model_path))
    model.eval()
    return model

def process_image(image_path, transform):
    image = Image.open(image_path).convert('RGB')
    image = transform(image)
    image = image.unsqueeze(0)  # Add batch dimension
    return image

def predict(model, image_tensor):
    with torch.no_grad():
        output = model(image_tensor)
    return output.squeeze().tolist()  # Convert to a 1D list

def write_output_to_file(output, file_path):
    with open(file_path, 'w') as file:
        for value in output:
            file.write(f"{value}\n")


def main(image_path, model_path):
    transform = transforms.Compose([
        transforms.Resize((256, 256)),
        transforms.ToTensor()
    ])

    model = load_model(model_path)
    image_tensor = process_image(image_path, transform)
    output = predict(model, image_tensor)
    write_output_to_file(output, output_file_path)
    print(f"Prediction written to {output_file_path}")

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python script.py <path_to_image> <path_to_model>")
        sys.exit(1)

    image_path = sys.argv[1]
    model_path = sys.argv[2]
    base_name, _ = os.path.splitext(image_path)
    output_file_path = base_name + '.txt'

    try:
        main(image_path, model_path)
    except Exception as e:
        print("An error occurred:", str(e))
        traceback.print_exc()  # Print detailed traceback
        sys.exit(1)  # Exit with error code 1