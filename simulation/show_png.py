import numpy as np
import cv2
import os

def main():
    cls = ['west_0','west_1','east_0','east_1']
    png_parts = []

    for direction in cls:
        fname = f"./lena_mf_{direction}.txt"
        if not os.path.exists(fname):
            print(f"[ERROR] File not found: {fname}")
            return

        with open(fname, 'rb') as txt:
            pixels = txt.readlines()

        # replace invalid 'x' values with zeros
        pixels = [b'0000000000000000\r\n' if p == b'xxxxxxxxxxxxxxxx\r\n' else p for p in pixels]

        # convert binary strings → integers
        pixels = [int(p.strip(), 2) for p in pixels]
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
                        lena_out_part[3*m+i][3*n+j] = int(pixels[m][n][i][j] / 9.0)

        png_parts.append(lena_out_part)
        print(f"[INFO] Loaded {direction}: shape {lena_out_part.shape}, min={lena_out_part.min()}, max={lena_out_part.max()}")

    # combine the four quadrants
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

