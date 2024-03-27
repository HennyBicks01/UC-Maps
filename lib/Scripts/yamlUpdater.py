import os

def find_folders_with_assets(root_directory):
    """
    Find folders directly containing .json or .png files within the specified root directory.
    """
    asset_folders = set()

    for root, dirs, files in os.walk(root_directory):
        if any(file.endswith('.json') or file.endswith('.png') for file in files):
            # Constructing a path relative to the root_directory for inclusion in pubspec.yaml
            relative_path = os.path.relpath(root, start=root_directory)
            asset_folders.add(relative_path.replace('\\', '/'))  # Ensuring posix-style paths

    return asset_folders

def update_pubspec_yaml(pubspec_path, asset_folders):
    """
    Update the pubspec.yaml file with the specified asset folders.
    """
    asset_paths = ["  - assets/{}/\n".format(folder) for folder in sorted(asset_folders)]

    with open(pubspec_path, 'r+') as file:
        content = file.readlines()

        # Finding the index where assets start
        try:
            asset_start_index = next(i for i, line in enumerate(content) if 'assets:' in line) + 1
        except StopIteration:
            print("No 'assets:' section found in pubspec.yaml. Please ensure it exists and try again.")
            return

        # Removing existing asset entries to avoid duplicates
        content = [line for line in content if not line.strip().startswith('- assets/')]

        # Inserting new asset paths
        for path in reversed(asset_paths):
            content.insert(asset_start_index, path)

        # Writing back to the file
        file.seek(0)
        file.writelines(content)
        file.truncate()

# Path to the pubspec.yaml file and assets directory
pubspec_path = 'pubspec.yaml'
assets_directory = 'assets'

# Finding folders within assets that contain .json or .png files
asset_folders = find_folders_with_assets(assets_directory)

# Updating the pubspec.yaml file with these asset folders
update_pubspec_yaml(pubspec_path, asset_folders)
