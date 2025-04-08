import numpy as np
from PIL import Image

# Cargar el archivo txt
data = np.loadtxt("output.txt")  # Reemplazá con el nombre que corresponda
data = data.astype(np.uint8)  # Asegurar tipo entero de 8 bits

# Crear imagen en escala de grises desde array
img = Image.fromarray(data, mode="L")
img.show()  # O img.save("output.png")
