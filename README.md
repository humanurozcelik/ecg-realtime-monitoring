# ECG Signal Processing with MATLAB & Simulink

This is a biomedical signal-processing project I made to practice ECG filtering, R-peak detection, heart-rate estimation, and Simulink.

The processing steps are based on the general idea of Pan-Tompkins-style QRS detection.

## Processing steps

1. 5–15 Hz band-pass filtering
2. differentiation
3. squaring
4. 150 ms moving-window integration
5. threshold-based peak detection
6. local R-peak refinement
7. heart-rate estimation from R–R intervals

The Simulink model is used to show the ECG processing in a more real-time style.

## Project files

```text
ECG_Heart_Monitor_Project/
├── main_analysis.m
├── realtime_monitor.slx
├── 100m.mat
└── images/
```

## Example outputs

### Signal-processing stages

![Signal-processing stages](ECG_Heart_Monitor_Project/images/signal_processing_stage.png)

### Peak detection

![Peak detection](ECG_Heart_Monitor_Project/images/algorithm_validation.png)

### Monitor-style display

![Monitor-style ECG visualization](ECG_Heart_Monitor_Project/images/live_monitoring.png)

## Requirements

- MATLAB
- Signal Processing Toolbox
- Simulink

## Run

Open MATLAB, go to the `ECG_Heart_Monitor_Project` folder, and run:

```matlab
main_analysis
```

Then open `realtime_monitor.slx` to run the Simulink model.

## Data

The example ECG is based on record 100 from the MIT-BIH Arrhythmia Database available through PhysioNet.

https://physionet.org/content/mitdb/1.0.0/

## Notes

The peak detector uses a simple threshold based on the first 10 seconds of the signal, so it may not work equally well on different recordings.

This project was made for learning and demonstration purposes and is not a clinical arrhythmia detector.
