import numpy as np
import os
import glob
import pandas as pd
import neurokit2 as nk
import datetime

# Set data paths
base_path = " "
raw_data_path = os.path.join(base_path, "E4_rawdata")
output_path_rmssd = os.path.join(base_path, "RMSSD")

# Subject mapping
subject_mapping = {
    "A04A07": "01",
    "A042AE": "02",
    "A03E19": "03"
}

# Get all BVP raw data files
bvp_files = glob.glob(os.path.join(raw_data_path, "*", "*/*BVP_addtime.csv"))

def process_bvp_file(data2write, output_path):
    data2write.to_csv(output_path, index=False, float_format='%.2f')

def time_transform(t):
    return [datetime.datetime.fromtimestamp(x).strftime("%Y-%m-%d %H:%M:%S.%f") for x in t]

def time_interval(t1, t2):
    itv = []
    start_time = time_transform(t1)
    finish_time = time_transform(t2)
    for start, finish in zip(start_time, finish_time):
        time1 = datetime.datetime.strptime(start, "%Y-%m-%d %H:%M:%S.%f")
        time2 = datetime.datetime.strptime(finish, "%Y-%m-%d %H:%M:%S.%f")
        duration = (time2 - time1).total_seconds() * 1000
        itv.append(duration)
    return itv

# Create a list to store all subject RMSSD results
rmssd_results = []

# Loop through each BVP raw data file
for bvp_file in bvp_files:
    session = os.path.basename(os.path.dirname(os.path.dirname(bvp_file)))
    subject_folder = os.path.basename(os.path.dirname(bvp_file))
    subject_code = None
    subject_name = None

    for code, name in subject_mapping.items():
        if code in subject_folder:
            subject_code = code
            subject_name = name
            break

    if subject_name is None:
        print(f"Subject not found for file: {bvp_file}")
        continue

    
    bvp_data = pd.read_csv(bvp_file, skiprows=1, names=["Amplitude", "Timestamp"])
    full_bvp_data = bvp_data
    if full_bvp_data.empty:
        print(f"No BVP data found for the given timestamps in file: {bvp_file}")
        continue

    ppg_data = full_bvp_data["Amplitude"].values.astype(float)
    timestamp = full_bvp_data["Timestamp"].values

    signals, info = nk.ppg_process(ppg_data, sampling_rate=64)
    signals.insert(signals.shape[1], 'Timestamp', timestamp)
    signals_array = np.array(signals)
    peaks = signals_array[:, 4]
    full_timestamp = signals_array[:, 5]
    full_rmssd = []
    

    window_size = 320 # 5s
    overlap = 288 # 90% overlap

    for i in range(0, len(peaks) - window_size, window_size - overlap):
        part_timestamp = full_timestamp[i:i + window_size]
        part_peaks = peaks[i:i + window_size]
        index = np.where(part_peaks == 1)
        peak_timestamp = part_timestamp[index]

        if len(peak_timestamp) < 2:
            continue  # Skip if not enough peaks
        x0 = peak_timestamp[:-1]
        x1 = peak_timestamp[1:]
        hr_intervals = time_interval(x0, x1)
        if len(hr_intervals) > 1:
            diff_intervals = np.diff(hr_intervals)
            squared_diff = np.square(diff_intervals)
            mean_squared_diff = np.mean(squared_diff)
            rmssd = np.sqrt(mean_squared_diff)
            full_rmssd.append(rmssd)

    if not full_rmssd:
        print(f"No valid RMSSD values computed for file: {bvp_file}")
        continue

    array_rmssd = np.array(full_rmssd)

    # Store the results in a DataFrame
    rmssd_df = pd.DataFrame({
        f"{session}_{subject_name}": array_rmssd,
    })

    # Check for empty columns and print a message if found
    if rmssd_df.isnull().all().any():
        print(f"Warning: Empty column detected in {session}_{subject_name}.")

    rmssd_results.append(rmssd_df)

# Combine all subject RMSSD results and save to a CSV file
if rmssd_results:
    all_rmssd = pd.concat(rmssd_results, axis=1)
    all_rmssd.to_csv(os.path.join(output_path_rmssd, "rmssd-320,90%.csv"), index=False, float_format='%.2f')
    print("RMSSD results saved.")
else:
    print("No RMSSD results to save.")
