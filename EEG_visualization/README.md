# EEG Visualization  

This directory contains a script for visualizing EEG data from our dataset.  

In our paper, we provide a basic method for EEG visualization (*The Averaged Power Spectral Density Topomap of Expert Drivers and Novice Drivers*). This script allows you to replicate and explore the visualization process.  

## Installation  

Before running the script, ensure you have created a virtual environment using Conda. Then, install the required dependencies by running the following command in your terminal:  

```
pip install -r requirements.txt
```


## Running the Visualization Script  

Once the dependencies are installed, you can run the visualization script provided in `eeg_visualization.ipynb`.  

To open the script, use Jupyter Notebook or, if you're using VS Code, install the Jupyter extension.  

### Configuration  

Before running the script, update the following path variables to match your dataset structure:  

- `dataset_dir`: Set this to the EEG data directory (e.g., `3-Driver/1-EEG`).  
- `psd_fig_save_dir`: Specify the directory where the power spectral density (PSD) figures will be saved.  
- `psd_stats_save_dir`: Specify the directory where the PSD statistics will be saved.  

## Need Help?  

If you have any questions or encounter issues, feel free to open an issue. ☺  
