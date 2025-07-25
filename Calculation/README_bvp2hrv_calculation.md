# BVP to HRV Analysis Pipeline
This program processes Blood Volume Pulse (BVP) data to compute RMSSD (Root Mean Square of Successive Differences), a key heart rate variability (HRV) metric. The pipeline processes raw BVP data from Empatica E4 wristband and calculates RMSSD values using sliding windows with 90% overlap.
## Features
- Processes raw BVP data with timestamps
- Automated peak detection using NeuroKit2
- RMSSD calculation with sliding windows (5s window, 90% overlap)
- Handles multiple subjects and sessions
- Outputs aggregated RMSSD results in CSV format
## Requirements
- Python 3.7+
- Required packages:
  ```bash
  pip install numpy pandas neurokit2
## Project Structure
* `E4_rawdata/`: Folder containing raw BVP data files (CSV format) exported from Empatica E4.
* `RMSSD/`: Output directory where RMSSD results will be saved.
* `rmssd-320,90%.csv`: Final output file with RMSSD values for each subject-session combination.
## Features
* Parses and processes raw `.csv` BVP files.
* Applies signal processing using the [`neurokit2`](https://neurokit2.readthedocs.io/en/latest/) library.
* Computes RMSSD over **5-second sliding windows** with **90% overlap**.
* Outputs a CSV file where each column represents a unique subject-session combination.
## How It Works
The program input was the original files generated directly by E4 wristband adding timestamps, not the reorganized data published. The workflow is for the reference of calculation. Mapping or other file transportations can be ignored.
1. **Subject Mapping**:
   Maps raw data folders to subject IDs:
   ```python
   subject_mapping = {
       "A04A07": "01",
       "A042AE": "02",
       "A03E19": "03"
   }
   ```
2. **BVP Preprocessing**:
   * Reads BVP amplitude and timestamp values.
   * Uses `neurokit2.ppg_process()` to detect heartbeats (peaks).
   * Extracts timestamps of valid peaks for RMSSD computation.
3. **RMSSD Calculation**:
   * For each 5-second (320-sample) window with 90% overlap (288 samples), RMSSD is calculated from inter-beat intervals.
   * RMSSD is computed only when enough valid peaks are detected.
4. **Output Generation**:
   * All per-session RMSSD results are saved into `rmssd-320,90%.csv`.
## Notes
* The script skips files with missing or insufficient data.
* A warning is printed if an empty result is detected for a session.
* Ensure all BVP files follow the expected format.
