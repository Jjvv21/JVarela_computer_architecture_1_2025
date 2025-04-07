import tkinter as tk
from PIL import Image, ImageTk
from tkinter import filedialog

# Configuración de la ventana principal
root = tk.Tk()
root.title("Interpolación Bilineal - Interfaz")
root.configure(bg="#2C3E50")

# Tamaño predefinido de la imagen
IMG_SIZE = 390
PATCH_SIZE = IMG_SIZE // 4  # 97 píxeles por recuadro

# Variables globales
original_img = None
grid_img = None
original_photo = None
grid_photo = None
unprocessed_photo = None

# Función para cargar la imagen
def load_image():
    global original_img, grid_img, original_photo, grid_photo
    file_path = filedialog.askopenfilename(filetypes=[("Image files", "*.jpg *.png *.jpeg")])
    if file_path:
        original_img = Image.open(file_path).convert("L").resize((IMG_SIZE, IMG_SIZE))
        original_photo = ImageTk.PhotoImage(original_img)
        original_label.config(image=original_photo)
        
        grid_img = original_img
        grid_photo = ImageTk.PhotoImage(grid_img)
        bw_canvas.create_image(0, 0, anchor=tk.NW, image=grid_photo)
        draw_grid(bw_canvas)
        unprocessed_canvas.delete("all")
        processed_canvas.delete("all")
        update_scroll_region()  # Actualizar región de scroll después de cargar la imagen

# Función para dibujar la cuadrícula y numerar los recuadros
def draw_grid(canvas):
    canvas.delete("grid")
    canvas.delete("numbers")
    for i in range(1, 4):
        canvas.create_line(i * PATCH_SIZE, 0, i * PATCH_SIZE, IMG_SIZE, fill="red", tags="grid")
        canvas.create_line(0, i * PATCH_SIZE, IMG_SIZE, i * PATCH_SIZE, fill="red", tags="grid")
    for row in range(4):
        for col in range(4):
            num = row * 4 + col + 1
            x = col * PATCH_SIZE + PATCH_SIZE // 2
            y = row * PATCH_SIZE + PATCH_SIZE // 2
            canvas.create_text(x, y, text=str(num), fill="#F1C40F", font=("Helvetica", 20, "bold"), tags="numbers")

# Función para procesar el recuadro seleccionado desde el input y generar el .img
def process_patch():
    global unprocessed_photo
    try:
        patch_num = int(entry.get())
        if 1 <= patch_num <= 16:
            if original_img is None:
                unprocessed_canvas.delete("all")
                unprocessed_canvas.create_text(IMG_SIZE // 2, IMG_SIZE // 2, text="Carga una imagen primero", 
                                               fill="white", font=("Helvetica", 12))
                processed_canvas.delete("all")
                return
            
            row = (patch_num - 1) // 4
            col = (patch_num - 1) % 4
            left = col * PATCH_SIZE
            top = row * PATCH_SIZE
            right = left + PATCH_SIZE
            bottom = top + PATCH_SIZE
            patch = original_img.crop((left, top, right, bottom))  # Patch original de 97x97
            patch_resized = patch.resize((IMG_SIZE, IMG_SIZE))  # Patch redimensionado para mostrar
            unprocessed_photo = ImageTk.PhotoImage(patch_resized)
            unprocessed_canvas.delete("all")
            unprocessed_canvas.create_image(1, 0, anchor=tk.NW, image=unprocessed_photo)

            #genera un archivo .txt con los valores de cada pixel en un solo canal ya que la imagen es generada en escala de grises
            
            with open(f"patch_{patch_num}_input.txt", "w") as f:
                for y in range(patch.height):  # 97 filas
                    row_values = [str(patch.getpixel((x, y))) for x in range(patch.width)]  # 97 columnas
                    f.write(" ".join(row_values) + "\n")

            processed_canvas.delete("all")
            processed_canvas.create_text(IMG_SIZE // 2, IMG_SIZE // 2, text=f"Procesado: Recuadro {patch_num}", 
                                         fill="white", font=("Helvetica", 12))
            update_scroll_region()  # Actualizar región de scroll después de procesar
        else:
            unprocessed_canvas.delete("all")
            unprocessed_canvas.create_text(IMG_SIZE // 2, IMG_SIZE // 2, text="Número inválido (1-16)", 
                                           fill="white", font=("Helvetica", 12))
            processed_canvas.delete("all")
    except ValueError:
        unprocessed_canvas.delete("all")
        unprocessed_canvas.create_text(IMG_SIZE // 2, IMG_SIZE // 2, text="Ingresa un número válido", 
                                       fill="white", font=("Helvetica", 12))
        processed_canvas.delete("all")

# Crear un canvas principal con scrollbar horizontal
main_canvas = tk.Canvas(root, bg="#2C3E50", width=800)  # Ancho inicial fijo para evitar que sea demasiado pequeño
main_canvas.pack(side=tk.TOP, fill=tk.BOTH, expand=True)

# Agregar scrollbar horizontal
scrollbar = tk.Scrollbar(root, orient=tk.HORIZONTAL, command=main_canvas.xview)
scrollbar.pack(side=tk.BOTTOM, fill=tk.X)
main_canvas.configure(xscrollcommand=scrollbar.set)

# Crear un frame dentro del canvas para contener todo el contenido
content_frame = tk.Frame(main_canvas, bg="#2C3E50")
main_canvas.create_window((0, 0), window=content_frame, anchor="nw")

# Configuración del grid en la ventana con formato centrado
# Frame superior para controles
top_frame = tk.Frame(content_frame, bg="#2C3E50", pady=10)
top_frame.grid(row=1, column=1, columnspan=4, sticky="ew")

load_button = tk.Button(top_frame, text="Cargar Imagen", command=load_image, bg="#3498DB", fg="white", 
                        font=("Helvetica", 12, "bold"), relief="flat", padx=10, pady=5)
load_button.pack(side=tk.LEFT, padx=10)

tk.Label(top_frame, text="Número del recuadro (1-16):", bg="#2C3E50", fg="white", 
         font=("Helvetica", 12)).pack(side=tk.LEFT, padx=5)
entry = tk.Entry(top_frame, width=5, font=("Helvetica", 12), justify="center")
entry.pack(side=tk.LEFT, padx=5)
process_button = tk.Button(top_frame, text="Aplicar Interpolación", command=process_patch, bg="#E74C3C", fg="white", 
                           font=("Helvetica", 12, "bold"), relief="flat", padx=10, pady=5)
process_button.pack(side=tk.LEFT, padx=10)

# Configurar pesos para centrar dentro del content_frame
content_frame.grid_rowconfigure(0, weight=1)  # Espacio arriba
content_frame.grid_rowconfigure(3, weight=1)  # Espacio abajo
content_frame.grid_columnconfigure(0, weight=1)  # Espacio izquierda
content_frame.grid_columnconfigure(5, weight=1)  # Espacio derecha

tk.Label(content_frame, text="Imagen Original", bg="#2C3E50", fg="#ECF0F1", font=("Helvetica", 14, "bold")).grid(row=2, column=1, pady=5)
original_label = tk.Label(content_frame, bg="#34495E", borderwidth=2, relief="solid")
original_label.grid(row=3, column=1, padx=10, pady=5)

tk.Label(content_frame, text="Imagen con Cuadrícula", bg="#2C3E50", fg="#ECF0F1", font=("Helvetica", 14, "bold")).grid(row=2, column=2, pady=5)
bw_canvas = tk.Canvas(content_frame, width=IMG_SIZE, height=IMG_SIZE, bg="#34495E", borderwidth=2, relief="solid")
bw_canvas.grid(row=3, column=2, padx=10, pady=5)

tk.Label(content_frame, text="Cuadrícula sin procesar", bg="#2C3E50", fg="#ECF0F1", font=("Helvetica", 14, "bold")).grid(row=2, column=3, pady=5)
unprocessed_canvas = tk.Canvas(content_frame, width=IMG_SIZE, height=IMG_SIZE, bg="#34495E", borderwidth=2, relief="solid")
unprocessed_canvas.grid(row=3, column=3, padx=10, pady=5)

tk.Label(content_frame, text="Cuadrícula procesada", bg="#2C3E50", fg="#ECF0F1", font=("Helvetica", 14, "bold")).grid(row=2, column=4, pady=5)
processed_canvas = tk.Canvas(content_frame, width=IMG_SIZE, height=IMG_SIZE, bg="#34495E", borderwidth=2, relief="solid")
processed_canvas.grid(row=3, column=4, padx=10, pady=5)

# Función para actualizar el área de scroll
def update_scroll_region():
    main_canvas.update_idletasks()  # Asegurarse de que todos los widgets estén actualizados
    main_canvas.configure(scrollregion=main_canvas.bbox("all"))

# Vincular la función de configuración al frame de contenido
content_frame.bind("<Configure>", lambda event: update_scroll_region())

# Actualizar la región de scroll inicialmente
root.after(100, update_scroll_region)  # Llamar después de que la ventana esté inicializada

# Iniciar la ventana
root.mainloop()
