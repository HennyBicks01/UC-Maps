from pdf2image import convert_from_path
import os

def convert_pdf_to_png(pdf_path, dpi = 500):
    # Convert PDF to a list of images
    images = convert_from_path(pdf_path)

    # Base name for PNG files
    base_name = os.path.splitext(pdf_path)[0]

    # Save each page as an image
    for i, image in enumerate(images):
        image_path = f'{base_name}.png'
        image.save(image_path, 'PNG')

    # Delete the original PDF file
    os.remove(pdf_path)

def convert_directory_pdfs_to_pngs(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.pdf'):
                pdf_path = os.path.join(root, file)
                convert_pdf_to_png(pdf_path)
                print(f"Converted {file} to PNGs.")

if __name__ == "__main__":
    blueprints_directory = 'Blueprints'  # Replace with the path to your 'Blueprints' directory
    convert_directory_pdfs_to_pngs(blueprints_directory)
