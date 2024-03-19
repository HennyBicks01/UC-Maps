import os
import re

def list_folders_in_directory(directory):
    """List all folders in the specified directory."""
    return [f.name for f in os.scandir(directory) if f.is_dir()]

def update_pubspec_yaml(pubspec_path, blueprint_directory):
    """Update the pubspec.yaml file with folders from the Blueprints directory."""
    folders = list_folders_in_directory(blueprint_directory)
    asset_paths = ["  - assets/Blueprints/{}/\n".format(folder) for folder in folders]

    with open(pubspec_path, 'r+') as file:
        content = file.readlines()

        # Finding the index where assets start
        asset_start_index = next(i for i, line in enumerate(content) if 'assets:' in line) + 1

        # Removing existing Blueprints entries
        content = [line for line in content if not line.strip().startswith('- Blueprints/')]

        # Inserting new asset paths
        for path in reversed(asset_paths):
            content.insert(asset_start_index, path)

        # Writing back to the file
        file.seek(0)
        file.writelines(content)
        file.truncate()

# Path to the pubspec.yaml file and Blueprints directory
pubspec_path = 'pubspec.yaml'
blueprint_directory = 'assets/Blueprints'

update_pubspec_yaml(pubspec_path, blueprint_directory)
