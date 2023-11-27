import fitz  # PyMuPDF
import os
import xml.etree.ElementTree as ET
from io import StringIO  # Import StringIO

def convert_pdf_to_svg(pdf_path, enhance_lines=False):
    doc = fitz.open(pdf_path)

    for page_num in range(len(doc)):
        page = doc.load_page(page_num)
        svg = page.get_svg_image()

        if enhance_lines:
            svg = enhance_svg_lines(svg)

        output_svg_path = os.path.splitext(pdf_path)[0] + f".svg"
        with open(output_svg_path, "w") as svg_file:
            svg_file.write(svg)

    doc.close()
    # Removing the original PDF file
def enhance_svg_lines(svg_content):
    try:
        # Parse the SVG and remove namespaces
        it = ET.iterparse(StringIO(svg_content))
        for _, el in it:
            if '}' in el.tag:
                el.tag = el.tag.split('}', 1)[1]  # Remove the namespace
        root = it.root

        # Set a new stroke-width
        for path in root.findall('.//path'):
            style = path.get('style', '')
            new_style = update_style_attribute(style, 'stroke-width', '0.6')  # Adjust stroke width here
            path.set('style', new_style)

        return ET.tostring(root, encoding='unicode')
    except Exception as e:
        print(f"Error enhancing SVG lines: {e}")
        return svg_content

def update_style_attribute(style, attribute, new_value):
    style_parts = style.split(';')
    new_style_parts = []
    attribute_found = False

    for part in style_parts:
        if part.startswith(attribute):
            new_style_parts.append(f'{attribute}: {new_value}')
            attribute_found = True
        else:
            new_style_parts.append(part)

    if not attribute_found:
        new_style_parts.append(f'{attribute}: {new_value}')

    return ';'.join(new_style_parts)
def convert_directory_pdfs_to_svgs(directory, enhance_lines=False):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.pdf'):
                pdf_path = os.path.join(root, file)
                convert_pdf_to_svg(pdf_path, enhance_lines)
                print(f"Converted {file} to SVG and removed the original PDF.")

if __name__ == "__main__":
    pdf_directory = 'assets/Blueprints'  # Replace with your PDF directory
    convert_directory_pdfs_to_svgs(pdf_directory, enhance_lines=True)
