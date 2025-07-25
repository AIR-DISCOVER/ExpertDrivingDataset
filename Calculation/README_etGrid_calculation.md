# Eye-Tracking Grid Mapping

This Python script processes CSV files containing eye-tracking data and maps gaze coordinates (`Gaze point X`, `Gaze point Y`) to one of nine predefined screen grid areas. It is designed for experiments or analyses involving gaze tracking on a 1920×1080 resolution screen.

## Features

* Reads eye-tracking data from CSV files.
* Divides the screen into 9 regions (3×3 grid), with the central region specially marked as **Grid 5**.
* Assigns each gaze point to its corresponding grid region.
* Outputs new CSV files with an added `Grid Number` column.

## Grid Mapping Logic

The screen is divided into:

* A **central square region** (1/7 of screen width and height) → **Grid 5**
* Surrounding regions are split evenly to form a 3×3 layout, numbered 1 through 9:

```
1 | 2 | 3
---------
4 | 5 | 6
---------
7 | 8 | 9
```

## Requirements

* Python 3.x
* pandas
* numpy

## How to Use

1. Locate eye-tracking data files inside the directory:
   `./3-Driver/2-EyeTracking/`

2. Run the script

3. The script will:

   * Recursively search for all `.csv` files in the directory.
   * Process each file and assign a `Grid Number` based on gaze coordinates.
   * Save a new CSV file with `_grid.csv` appended to the filename.

Example output file:
`original_file.csv` → `original_file_grid.csv`

## Input CSV Format

The script expects the CSV files to contain the following columns:

* `Gaze point X`
* `Gaze point Y`

## Output

Each output CSV will contain all original data plus an additional column:

* `Grid Number`: indicating the screen region (1–9) where the gaze point falls.

## Notes

* The screen resolution is hardcoded as **1920×1080**.
* Gaze points with missing `X` or `Y` values are ignored.
