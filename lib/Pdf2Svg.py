import fitz  # PyMuPDF
import os
import xml.etree.ElementTree as ET

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
    os.remove(pdf_path)
def enhance_svg_lines(svg_content):
    # Increase stroke width in the SVG content
    try:
        root = ET.fromstring(svg_content)
        # Assuming paths are defined with the 'path' tag
        for path in root.findall('.//{http://www.w3.org/2000/svg}path'):
            style = path.get('style', '')
            if 'stroke-width' in style:
                # Increase existing stroke width
                styles = style.split(';')
                new_styles = []
                for s in styles:
                    if 'stroke-width' in s:
                        key, value = s.split(':')
                        new_width = float(value) * 1.25  # Double the stroke width
                        new_styles.append(f'{key}:{new_width}')
                    else:
                        new_styles.append(s)
                path.set('style', ';'.join(new_styles))
            else:
                # Add a stroke width if none exists
                path.set('style', style + ';stroke-width:1.25')
        return ET.tostring(root, encoding='unicode')
    except Exception as e:
        print(f"Error enhancing SVG lines: {e}")
        return svg_content

def convert_directory_pdfs_to_svgs(directory, enhance_lines=False):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.pdf'):
                pdf_path = os.path.join(root, file)
                convert_pdf_to_svg(pdf_path, enhance_lines)
                print(f"Converted {file} to SVG and removed the original PDF.")

if __name__ == "__main__":
    pdf_directory = 'Blueprints'  # Replace with your PDF directory
    convert_directory_pdfs_to_svgs(pdf_directory, enhance_lines=True)
