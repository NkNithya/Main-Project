#!/usr/bin/env python3
import cv2
import numpy as np
import random
import os

# ===============================
# Convert image values to fixed point
# ===============================
def convert_to_fix_point(arr1, bit):
    arr2 = arr1.copy().astype(np.float32)
    arr2[arr2 < 0] = 0.0
    arr2 = np.round(np.abs(arr2) * (2 ** bit))

    arr3 = arr1.copy().astype(np.float32)
    arr3[arr3 > 0] = 0.0
    arr3 = -np.round(np.abs(-arr3) * (2 ** bit))

    arr4 = arr2 + arr3
    return arr4.astype(np.int64)

# ===============================
# Prepare grayscale image
# ===============================
def prepare_image_from_camera(im_path):
    Verilog_flag = 0
    img = cv2.imread(im_path)
    if img is None:
        raise FileNotFoundError(f"Image not found at {im_path}")
    print(f"Read image: {im_path}, Shape: {img.shape}")

    # Resize to 510x510
    img = cv2.resize(img, (510, 510), interpolation=cv2.INTER_CUBIC)
    print(f"Reduced shape: {img.shape}")

    # Convert to grayscale (human-based weighted)
    gray = np.zeros(img.shape[:2], dtype=np.uint16)
    gray[...] = 3*img[:, :, 0].astype(np.uint16) + 8*img[:, :, 1].astype(np.uint16) + 5*img[:, :, 2].astype(np.uint16)
    gray //= 16

    print("Sample grayscale values (top-left 3x3):")
    print(gray[:3, :3])

    # Clip and normalize if needed
    min_pixel, max_pixel = gray.min(), gray.max()
    print(f"Min pixel: {min_pixel}, Max pixel: {max_pixel}")

    output_image = gray.astype(np.uint8)
    return output_image

# ===============================
# Main mean-filter and file generator
# ===============================
def main():
    img_path = "./lena.png"                # Input
    verilog_path = "./simulation/lena_pixel.txt"      # Pixel output text
    out_image_path = "./lena_mf_python.jpg"

    image = prepare_image_from_camera(img_path)

    prob = 0.01
    thres = 1 - prob
    noise = 0
    pixel_mf = np.zeros((510, 510), dtype=np.float32)

    # Optional: add salt-and-pepper noise
    if noise:
        for i in range(image.shape[0]):
            for j in range(image.shape[1]):
                rdn = random.random()
                if rdn < prob:
                    image[i, j] = 0
                elif rdn > thres:
                    image[i, j] = 255

    # Scale and convert to fixed-point
    image_one = image / 256.0
    image_binary = convert_to_fix_point(image_one, 15)

    # Write pixel values for Verilog
    with open(verilog_path, 'w') as file:
        for i in range(image_binary.shape[0]):
            for j in range(image_binary.shape[1]):
                pixel = image[i, j]
                if i > 0 and j > 0 and i < image_binary.shape[0]-1 and j < image_binary.shape[1]-1:
                    pixel_mf[i, j] = np.mean(image[(i-1):(i+2), (j-1):(j+2)])
                file.write('{:016b}\n'.format(pixel))
    print(f"Pixel data written to {verilog_path}")

    # Normalize mean-filter output to 0–255
    pixel_mf_norm = pixel_mf - pixel_mf.min()
    if pixel_mf_norm.max() > 0:
        pixel_mf_norm = 255 * (pixel_mf_norm / pixel_mf_norm.max())
    pixel_mf_norm = pixel_mf_norm.astype(np.uint8)

    # Save as JPG
    cv2.imwrite(out_image_path, pixel_mf_norm)
    print(f" Mean-filtered image saved as {out_image_path}")

    # Display debug info
    print("pixel_mf range:", pixel_mf.min(), "→", pixel_mf.max())

if __name__ == "__main__":
    main()
