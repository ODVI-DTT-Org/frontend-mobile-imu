from PIL import Image, ImageOps
import os

# Open the original IMU logo
input_path = r"C:\odvi-apps\IMU\IMU logo.png"
output_path = r"C:\odvi-apps\IMU\mobile\imu_flutter\app-icon-512.png"

# Open image
img = Image.open(input_path)

# Create new 512x512 image with white background
new_img = Image.new("RGBA", (512, 512), (255, 255, 255, 255))

# Calculate scaling to fit within 512x512 while maintaining aspect ratio
img.thumbnail((512, 512), Image.Resampling.LANCZOS)

# Calculate position to center the image
x = (512 - img.width) // 2
y = (512 - img.height) // 2

# Paste the resized logo onto the center
new_img.paste(img, (x, y), img)

# Convert to RGB (remove transparency for Play Store)
new_img_rgb = Image.new("RGB", new_img.size, (255, 255, 255))
new_img_rgb.paste(new_img, (0, 0), new_img)

# Save the result
new_img_rgb.save(output_path, "PNG", quality=95)

print(f"App icon created: {output_path}")
print(f"Size: 512 x 512 pixels")
print(f"Format: PNG (RGB)")
print(f"Ready for Google Play Store!")
