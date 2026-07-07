# Real-Time ECG Arrhythmia Detection and Monitoring System

Hi, I'm Hüma. As a biomedical engineering student, I am highly interested in clinical signal processing. I created this project to detect arrhythmias from raw ECG data in real time. 

The goal here is simple take a noisy clinical signal, clean it up, accurately identify the R-peaks, and calculate the heart rate, just like a bedside patient monitor.

## How It Works

The project relies on a combination of MATLAB and Simulink to process the data
1. Noise Reduction The raw signal is passed through a 5-15 Hz bandpass filter to eliminate baseline wander and high-frequency interference.
2. Feature Enhancement The algorithm takes the derivative of the signal and squares it to boost the energy of the QRS complex.
3. Peak Detection A moving window integration is applied alongside an adaptive threshold to catch the exact heartbeats without false positives.
4. Live Simulation The processed data is fed into a Simulink model to simulate real-time monitoring.

## Project Files

 main_analysis.m The core script. It handles data loading, signal processing, peak detection, and generates the validation plots.
 realtime_monitor.slx The Simulink model that simulates the live clinical monitor.
 100m.mat The raw ECG dataset, sourced from Kaggle.
 images Contains screenshots of the processing stages and validation results.

## Usage

To test the system on your machine
1. Clone this repository.
2. Open MATLAB and run main_analysis.m. This will process the dataset, calculate the necessary filter coefficients, and display the signal processing stages.
3. Once the script finishes, open realtime_monitor.slx and run the simulation to see the real-time scope output.

Feel free to reach out or open an issue if you have any questions regarding the signal processing pipeline.