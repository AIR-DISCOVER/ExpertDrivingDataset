import pandas as pd
import numpy as np
import os

def get_grid_number(x, y, screen_width, screen_height):
    # width and height of central area
    center_width = screen_width / 7
    center_height = screen_height / 7
    
    # width and height of other areas
    outer_width = (screen_width - center_width) / 2
    outer_height = (screen_height - center_height) / 2
    
    # locate the coordinate
    if (outer_width <= x < outer_width + center_width) and (outer_height <= y < outer_height + center_height):
        # central area marked 5
        return 5
    else:
        # division of other areas
        if x < outer_width:
            col = 0
        elif x < outer_width + center_width:
            col = 1
        else:
            col = 2
        
        if y < outer_height:
            row = 0
        elif y < outer_height + center_height:
            row = 1
        else:
            row = 2
        
        # return grid number
        grid_number = row * 3 + col + 1
        return grid_number

def process_file(file_path):
    try:
        df = pd.read_csv(file_path)
        
        # Set the screen resolution
        screen_width = 1920
        screen_height = 1080
        
        df['Grid Number'] = np.nan
        
        for index, row in df.iterrows():
            if pd.notna(row['Gaze point X']) and pd.notna(row['Gaze point Y']):
                df.at[index, 'Grid Number'] = get_grid_number(row['Gaze point X'], row['Gaze point Y'], screen_width, screen_height)
        
        # Generate new files
        dir_name = os.path.dirname(file_path)
        file_name = os.path.basename(file_path)
        new_file_name = os.path.splitext(file_name)[0] + "_grid.csv"
        new_file_path = os.path.join(dir_name, new_file_name)
        
        # Save the results
        df.to_csv(new_file_path, index=False)
        print(f"Processed: {new_file_path}")
    except Exception as e:
        print(f"Processing {file_path} caught error: {str(e)}")

def process_directory(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.csv'):
                file_path = os.path.join(root, file)
                process_file(file_path)

# Call the functions
directory = r".\3-Driver\2-EyeTracking"
process_directory(directory)

print("All files processed")