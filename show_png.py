import numpy as np
import cv2
import os

def main():
    cls = ['west_0', 'west_1', 'east_0', 'east_1']
    png_parts = []

    for direction in cls:
        fname = f"./lena_gated_mf_{direction}.txt"
        if not os.path.exists(fname):
            print(f"[ERROR] File not found: {fname}")
            return

        with open(fname, 'rb') as txt:
            pixels = txt.readlines()

        # ------------------------------------------------------------
        # FIX: replace any line containing 'x' with all-zero binary
        # ------------------------------------------------------------
        clean_pixels = []
        for p in pixels:
            line = p.strip().lower()   # bytes
            if b'x' in line:
                clean_pixels.append(b'0000000000000000')
            else:
                clean_pixels.append(line)

        # convert binary strings → integers
        try:
            pixels = [int(p, 2) for p in clean_pixels]
        except ValueError as e:
            print(f"[ERROR] Binary conversion failed in {direction}: {e}")
            return

        pixels = np.asarray(pixels)

        # reshape
        try:
            pixels = np.reshape(pixels, (85, 85, 3, 3))
        except Exception as e:
            print(f"[ERROR] reshape failed for {direction}: {e}")
            print("array length:", len(pixels))
            return

        # reconstruct cluster output
        lena_out_part = np.zeros((255, 255))
        for m in range(pixels.shape[0]):
            for n in range(pixels.shape[1]):
                for i in range(pixels.shape[2]):
                    for j in range(pixels.shape[3]):
                        lena_out_part[3*m + i][3*n + j] = int(pixels[m][n][i][j] / 9.0)

        png_parts.append(lena_out_part)
        print(
            f"[INFO] Loaded {direction}: "
            f"shape {lena_out_part.shape}, "
            f"min={lena_out_part.min()}, "
            f"max={lena_out_part.max()}"
        )

    # ------------------------------------------------------------
    # combine the four quadrants
    # ------------------------------------------------------------
    png_pixel = np.hstack((
        np.vstack((png_parts[0], png_parts[1][:-2, :])),
        np.vstack((png_parts[2][:, :-2], png_parts[3][:-2, :-2]))
    ))

    print("[INFO] Combined shape:", png_pixel.shape)
    print("[INFO] Range:", png_pixel.min(), "to", png_pixel.max())

    # ensure valid image range
    png_pixel = np.clip(png_pixel, 0, 255).astype(np.uint8)

    out_path = "./lena_out.png"
    success = cv2.imwrite(out_path, png_pixel)
    print("[INFO] Image written:", success, "→", os.path.abspath(out_path))

    # also save numeric version
    np.savetxt("./png_out.txt", png_pixel, fmt="%4d")

if __name__ == "__main__":
    main()

