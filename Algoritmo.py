import numpy as np
import matplotlib.pyplot as plt

# Leer imagen desde TXT
def leer_imagen_txt(ruta_txt):
    with open(ruta_txt, 'r') as archivo:
        datos = archivo.readlines()
    matriz = [list(map(int, fila.strip().split())) for fila in datos]
    return np.array(matriz, dtype=np.uint8)

# Guardar imagen en TXT
def guardar_imagen_txt(matriz, ruta_txt):
    with open(ruta_txt, 'w') as archivo:
        for fila in matriz:
            archivo.write(' '.join(map(str, fila)) + '\n')

# Interpolación bilineal hecha a mano
def interpolar_bilineal_manual(imagen, escala=4):
    h, w = imagen.shape
    new_h, new_w = h * escala, w * escala
    nueva_imagen = np.zeros((new_h, new_w), dtype=np.uint8)

    for i in range(new_h):
        for j in range(new_w):
            # Posición en imagen original
            x = i / escala
            y = j / escala

            x0 = int(np.floor(x))
            y0 = int(np.floor(y))
            x1 = min(x0 + 1, h - 1)
            y1 = min(y0 + 1, w - 1)

            # Diferencias
            dx = x - x0
            dy = y - y0

            # Píxeles vecinos
            p00 = imagen[x0, y0]
            p01 = imagen[x0, y1]
            p10 = imagen[x1, y0]
            p11 = imagen[x1, y1]

            # Interpolación bilineal
            valor = (
                p00 * (1 - dx) * (1 - dy) +
                p10 * dx * (1 - dy) +
                p01 * (1 - dx) * dy +
                p11 * dx * dy
            )

            nueva_imagen[i, j] = int(round(valor))

    return nueva_imagen

# Mostrar comparación
def mostrar_vs(original, interpolada):
    plt.figure(figsize=(10, 5))

    plt.subplot(1, 2, 1)
    plt.title("Original (97x97)")
    plt.imshow(original, cmap='gray', vmin=0, vmax=255)
    plt.axis('off')

    plt.subplot(1, 2, 2)
    plt.title("Interpolada (390x390)")
    plt.imshow(interpolada, cmap='gray', vmin=0, vmax=255)
    plt.axis('off')

    plt.tight_layout()
    plt.show()

# Uso
imagen_original = leer_imagen_txt("patch_7_input.txt")
imagen_interpolada = interpolar_bilineal_manual(imagen_original, escala=4)
guardar_imagen_txt(imagen_interpolada, "imagen_interpolada.txt")

# Leer el nuevo txt solo para demostrar que se guardó bien
imagen_interpolada_leida = leer_imagen_txt("imagen_interpolada.txt")
mostrar_vs(imagen_original, imagen_interpolada_leida)
