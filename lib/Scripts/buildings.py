import os
import random
import json

# Directory containing the text files
directory = 'Geofencing'
# Output directory for the JSON file
output_directory = 'lib'

# List to hold building names
building_names = []

# Extract building names from each file
for filename in os.listdir(directory):
    if filename.endswith(".txt"):  # Assuming the files are .txt
        filepath = os.path.join(directory, filename)
        with open(filepath, 'r') as file:
            first_line = file.readline().strip()
            if first_line.startswith("Building:"):
                building_name = first_line.split("Building:")[1].strip()
                building_names.append(building_name)

# Shuffle the list of building names before splitting
random.shuffle(building_names)

# Split the list into three parts
split_size = len(building_names) // 3
lists = [building_names[i:i + split_size] for i in range(0, len(building_names), split_size)]

# Ensure there are exactly three lists
while len(lists) < 3:
    lists.append([])  # Add empty lists if needed

# Random names for the lists
names = ["Ben", "DeGuy", "Spencer"]
random.shuffle(names)

# Assign names to the lists
named_lists = {names[i]: lists[i] for i in range(3)}

# Save the named lists to a JSON file
output_path = os.path.join(output_directory, 'named_lists3.json')
with open(output_path, 'w') as json_file:
    json.dump(named_lists, json_file, indent=4)

print(f"Named lists saved to {output_path}")
