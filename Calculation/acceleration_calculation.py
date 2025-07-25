import os
import pandas as pd

def calculate_acceleration(df):
    # timestamp to seconds
    time_diff_sec = df['timestamp'].diff() / 1e9

    df['acceleration'] = df['speed_mps'].diff() / time_diff_sec
    return df

def process_csv_files(root_dir):
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.csv'):
                file_path = os.path.join(root, file)

                df = pd.read_csv(file_path)

                # Calculate and add to DataFrame
                df = calculate_acceleration(df)

                # Save to original file
                df.to_csv(file_path, index=False)
                print(f"Updated: {file_path}")


# call the functions
data_dir = './2-CANBus'
process_csv_files(data_dir)

print("All files updated.")