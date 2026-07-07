%% PROJECT NAME: Real-Time ECG Arrhythmia Detection and Monitoring System
%  Author: Hüma Nur Özçelik

%% 1. Initialization and Data Acquisition
clc; clear; close all;

% Load Data
filename = '100m.mat';
if exist(filename, 'file')
    load(filename);
else
    error('Error: Data file not found.');
end

% Auto-detect variable
vars = whos;
raw_signal = [];
for i = 1:length(vars)
    if strcmp(vars(i).name, 'val')
        raw_signal = val(1, :); 
        break;
    elseif vars(i).bytes > 10000 
        temp = eval(vars(i).name);
        raw_signal = temp(1, :);
    end
end

% Convert to mV
fs = 360;               
ecg_mV = (raw_signal - 0) / 200;
N = length(ecg_mV);
time_axis = (0:N-1) / fs; 

%% 2. STAGE 1: Band-Pass Filtering (Noise Removal)
% 5-15 Hz Bandpass to isolate QRS energy
f_low = 5; f_high = 15; order = 3;
[b, a] = butter(order, [f_low f_high]/(fs/2), 'bandpass');
ecg_filtered = filtfilt(b, a, ecg_mV);

%% 3. STAGE 2: Derivative & Squaring (Feature Enhancement)
% Derivative to find slope, Squaring to boost high energy
ecg_deriv = [0, diff(ecg_filtered)]; 
ecg_squared = ecg_deriv .^ 2;

%% 4. STAGE 3: Moving Window Integration (Smoothing)
% Objective: To merge the multiple peaks of a single QRS complex into a single smooth wave.

% Window Width Calculation (150 ms)
window_width = round(0.150 * fs); % ~54 samples

% Define the Integration Kernel (Coefficient Vector)
% IMPORTANT: This variable 'b_integ' is also used by the Simulink Model.
b_integ = ones(1, window_width) / window_width; 

% Perform Convolution for MATLAB Analysis
ecg_integrated = conv(ecg_squared, b_integ, 'same');
%% 5. STAGE 4: Adaptive Thresholding & Peak Detection
% Using local maxima for threshold calibration (Visual Guarantee Logic)
analysis_window = ecg_integrated(1:3600); % Analyze first 10 seconds
local_max = max(analysis_window);
threshold_level = local_max * 0.35; % 35% of the max peak is the threshold

min_peak_dist = 0.20 * fs; 

[peaks, locs] = findpeaks(ecg_integrated, ...
                          'MinPeakHeight', threshold_level, ...
                          'MinPeakDistance', min_peak_dist);

%% 6. Heart Rate Calculation
rr_intervals_sec = diff(locs) / fs;
bpm = 60 / mean(rr_intervals_sec);

% Console Output
fprintf('===========================================\n');
fprintf('   AUTOMATED ARRHYTHMIA DIAGNOSIS SYSTEM   \n');
fprintf('===========================================\n');
fprintf('Step 1: Data Loaded & Normalized\n');
fprintf('Step 2: Noise Removed (5-15Hz Bandpass)\n');
fprintf('Step 3: Features Extracted (Pan-Tompkins)\n');
fprintf('Step 4: Heart Rate Calculated\n');
fprintf('-------------------------------------------\n');
fprintf('RESULT: %.1f BPM\n', bpm);
fprintf('===========================================\n');

%% --- VISUALIZATION 1: THE ENGINEERING STORY (PROCESS STEPS) ---
% This figure shows HOW we got the result. Crucial for technical explanation.
figure('Name', 'Signal Processing Stages', 'Color', 'w');

% Plot 1: Raw Input
subplot(4,1,1);
plot(time_axis, ecg_mV, 'g'); 
title('Stage 1: Raw ECG Signal (Noisy Input)');
ylabel('mV'); grid on; xlim([0 5]);

% Plot 2: Filtered
subplot(4,1,2);
plot(time_axis, ecg_filtered, 'b'); 
title('Stage 2: Band-Pass Filtered (Noise Removed)');
ylabel('mV'); grid on; xlim([0 5]);

% Plot 3: Squared
subplot(4,1,3);
plot(time_axis, ecg_squared, 'm'); 
title('Stage 3: Derivative & Squared (Energy Boost)');
ylabel('mV^2'); grid on; xlim([0 5]);

% Plot 4: Integrated (Final)
subplot(4,1,4);
plot(time_axis, ecg_integrated, 'r', 'LineWidth', 1.5); 
title('Stage 4: Moving Window Integration (Ready for Detection)');
xlabel('Time (seconds)'); ylabel('Amplitude'); grid on; xlim([0 5]);


%% --- VISUALIZATION 2: VALIDATION (PROOF OF ACCURACY) ---
% This figure proves that the threshold is correct.
figure('Name', 'Algorithm Validation', 'Color', 'w');

plot(time_axis, ecg_integrated, 'b', 'LineWidth', 1.5); hold on;
yline(threshold_level, 'r--', 'Detection Threshold', 'LineWidth', 2);
plot(time_axis(locs), ecg_integrated(locs), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

title(['Validation Check: Are red dots on top of blue peaks? (BPM: ' num2str(round(bpm)) ')']);
xlabel('Time (s)'); ylabel('Integrated Energy');
grid on; xlim([0 5]); ylim([0 local_max*1.2]);


%% 8. Simulated Medical Monitor Display (With Peak Correction)
% Correction: Snaps the detected peak to the exact local maximum of the raw signal.

figure('Name', 'Patient Monitor Simulation', 'Color', 'k'); 

% 1. Plot Original ECG Signal (Green)
plot(time_axis, ecg_mV, 'g', 'LineWidth', 1.2); hold on;

% --- PEAK CORRECTION ALGORITHM START ---
% The peaks were found on the 'Integrated' signal, which has a slight delay.
% We now search +/- 20 samples around that point in the RAW signal to find the true peak.

corrected_locs = locs; % Initialize variable
search_window = 20;    % Look 20 samples left and right (approx 55ms)

for i = 1:length(locs)
    current_idx = locs(i);
    
    % Define safe boundaries to avoid index out of bounds error
    start_idx = max(1, current_idx - search_window);
    end_idx = min(N, current_idx + search_window);
    
    % Find the maximum value in the RAW signal within this small window
    [~, max_rel_idx] = max(ecg_mV(start_idx:end_idx));
    
    % Update the location to the true peak
    corrected_locs(i) = start_idx + max_rel_idx - 1;
end
% --- PEAK CORRECTION ALGORITHM END ---

% 2. Mark Corrected R-Peaks (Red Dots)
plot(time_axis(corrected_locs), ecg_mV(corrected_locs), 'ro', ...
    'MarkerSize', 8, 'MarkerFaceColor', 'r');

% 3. Display Vital Signs
title(['LIVE MONITORING - HEART RATE: ' num2str(round(bpm)) ' BPM'], ...
      'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');

% Formatting
xlabel('Time (s)', 'Color', 'w');
ylabel('Amplitude (mV)', 'Color', 'w');
set(gca, 'XColor', 'w', 'YColor', 'w', 'Color', 'k');
set(gca, 'GridColor', 'w', 'GridAlpha', 0.3);
grid on;

xlim([0 5]); % Initial view

% 1. Data Packaging for Simulink
% Convert the raw physical data (mV) into a Timeseries object.
% Simulink requires time-stamped data to stream it like a real signal.
ekg_simin = timeseries(ecg_mV, time_axis);

% 2. Verify Filter Coefficients
% The 'Discrete Filter' block in Simulink will require variables 'b' and 'a'.
if ~exist('b','var') || ~exist('a','var')
    error('Error: Filter coefficients (b, a) are missing. Please run the MATLAB script first.');
else
    disp('Data and Filter Coefficients are ready for Simulink!');
end