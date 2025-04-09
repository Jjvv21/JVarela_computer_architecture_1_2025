# JVarela_computer_architecture_1_2025

## Descripción del Proyecto

En este proyecto se desarrolló un programa capaz de tomar una imagen con una cantidad de píxeles predefinida (según las especificaciones del proyecto) y aplicar un algoritmo de interpolación bilineal a un cuadrante específico de dicha imagen. El programa muestra el cuadrante procesado en contraste con el cuadrante sin procesar, utilizando una interfaz visual diseñada en Python.

El algoritmo de procesamiento de la imagen se implementó en lenguaje ensamblador x86 NASM. El desarrollo se llevó a cabo en Ubuntu 18.04, y se requirió la instalación de paquetes específicos para Python y NASM, además de herramientas como GDB para depuración y comandos como `awk` para verificar la salida del procesamiento.

El objetivo principal fue combinar una interfaz gráfica sencilla con un procesamiento eficiente en ensamblador, verificando que las imágenes procesadas tuvieran una resolución de 400x400 píxeles en la salida.

---

## Herramientas Utilizadas

| Herramienta | Propósito | Uso |
|-------------|-----------|-----|
| **Python** | Desarrollo de la interfaz visual | Se diseñó una interfaz gráfica que carga la imagen original, muestra los resultados del procesamiento y permite visualizar los cuadrantes contrastados. Se asumió el uso de bibliotecas como Pillow para manipulación de imágenes. |
| **NASM (Netwide Assembler)** | Implementación del algoritmo de interpolación bilineal | El código en NASM procesa la imagen píxel por píxel, aplicando el algoritmo al cuadrante especificado y generando una salida con los píxeles procesados. |
| **GDB (GNU Debugger)** | Depuración del código ensamblador | Se utilizó para inspeccionar los registros y asegurar que el algoritmo en NASM funcionara correctamente. |
| **awk** | Verificación de la salida del ensamblador | Se emplearon comandos `awk` para analizar archivos de texto generados por el ensamblador y verificar que las dimensiones fueran 400x400 píxeles. |
| **Ubuntu 18.04** | Sistema operativo base | Entorno donde se instalaron y ejecutaron todas las herramientas. |

---

## Instalación de Herramientas en Ubuntu 18.04

Ejecuta los siguientes comandos para configurar el entorno:

### Actualizar el sistema:
```bash
sudo apt update && sudo apt upgrade -y
```
### Instalar Python y bibliotecas necesarias:
```bash
sudo apt install python3 python3-pip -y
pip3 install pillow
```
### Instalar NASM:
```bash
sudo apt install nasm -y
```
### Instalar GDB:
```bash
sudo apt install gdb -y
```
### Instalar awk (en caso de que no esté preinstalado):
```bash
sudo apt install gawk -y
```
## Compilación y Ejecución
### Compilar el código ensamblador:
```bash
nasm -f elf archivo.asm -o archivo.o
ld -m elf_i386 archivo.o -o archivo
```
### Ejecutar la interfaz gráfica:
```bash
python3 interfaz.py
```
###  Verificar el archivo de salida con awk:
```bash
awk 'END {print NR}' pixeles.txt
```

![Imagen del programa cuando se carga un archivo](https://github.com/Jjvv21/JVarela_computer_architecture_1_2025/blob/Development/ImagenesTest/CargarImagen.PNG)
![Imagen del programa cuando se procesa un cuadrante](https://github.com/Jjvv21/JVarela_computer_architecture_1_2025/blob/Development/ImagenesTest/ImagenProcesada.PNG)

