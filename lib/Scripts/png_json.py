import os

def collect_asset_paths(root_dir, extension):
    asset_paths = {}
    for root, _, files in os.walk(root_dir):
        relevant_files = [f for f in files if f.endswith(extension)]
        if relevant_files:  # Check if there are relevant files in the directory
            # Get a normalized directory name as a key, replacing backslashes for consistency
            directory_key = os.path.relpath(root, start=root_dir).replace('\\', '/')
            asset_paths[directory_key] = [os.path.join(directory_key, f).replace('\\', '/') for f in relevant_files]
    return asset_paths

def write_dart_file(filename, variable_name, data, base_path):
    with open(filename, 'w') as f:
        f.write(f'Map<String, List<String>> {variable_name} = {{\n')
        for directory, paths in sorted(data.items()):
            # Extract the last part of the directory for a more descriptive key/name
            directory_key = directory.split('/')[-1]
            f.write(f"  '{directory_key}': [\n")
            for path in sorted(paths):
                f.write(f"    '{base_path}{path}',\n")
            f.write('  ],\n')
        f.write('};\n\n')
        function_name = 'get' + variable_name[:-1] + 'FilePaths'  # Remove 's' and prepend 'get'
        f.write(f'List<String> {function_name}(String directoryName) {{\n')
        f.write(f'  return {variable_name}[directoryName] ?? [];\n')
        f.write('}\n')

assets_directory = 'assets'  # Update this path
json_base_path = 'BlueprintMaps/'  # Update this base path for JSON files
png_base_path = 'Blueprints/'      # Update this base path for PNG files

# Collect paths
json_paths = collect_asset_paths(os.path.join(assets_directory, json_base_path), '.json')
png_paths = collect_asset_paths(os.path.join(assets_directory, png_base_path), '.png')

# Generate Dart files
write_dart_file('lib/json.dart', 'buildingJsonPaths', json_paths, json_base_path)
write_dart_file('lib/png.dart', 'buildingImagePaths', png_paths, png_base_path)
