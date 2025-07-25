# Speed-to-Acceleration Processing for CAN-Bus Data
This Python script processes **CAN-Bus CSV files** by calculating vehicle **acceleration** based on timestamped speed data. It adds a new `acceleration` column to each file and overwrites the original file with the updated data.
## Project Structure
* `2-CANBus/`: Directory containing CSV files with timestamp and speed data.
* The script will walk through all subdirectories and files in this folder, processing any `.csv` file it finds.
## Features
* Reads vehicle telemetry data from CSV files.
* Computes **acceleration** (in m/s²) from the difference in speed over time.
* Appends the computed acceleration as a new column.
* Automatically updates each CSV file in place.
## Calculation Method
Acceleration is calculated using the formula:

```text
acceleration = Δspeed / Δtime
```
Where:
* `speed` is in meters per second (`mps`)
* `timestamp` is in **nanoseconds** and converted to seconds
## How to Use
### 1. Install Dependencies
```bash
pip install pandas
```
### 2. Run the Script
Make sure your data is located inside the `2-CANBus/` folder (or modify the `data_dir` path in the script). Then run:
```bash
python script_name.py
```
The script will process all `.csv` files in that directory and update them in place.
## Notes
* The first row of `acceleration` will be `NaN` because there is no previous value to calculate from.
* The script **overwrites the original files** — be sure to back up your data if needed.
