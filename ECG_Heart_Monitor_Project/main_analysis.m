%% PROJECT: ECG R-Peak Detection and Heart Rate Estimation
% Author: Hüma Nur Özçelik
%
% Educational biomedical signal-processing prototype using MATLAB.
% The script demonstrates ECG preprocessing, QRS-energy enhancement,
% heuristic R-peak detection, heart-rate estimation, and visualization.
%
% NOTE: This project is not a validated clinical diagnostic system and does
% not perform arrhythmia classification.

%% 1. Initialization and Data Loading
clc; clear; close all;

filename = '100m.mat';
if exist(filename, 'file')
    load(filename);
else
    error('Error: Data file not found.');
end

% Auto-detect a signal variable.
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

if isempty(raw_signal)
    error('Error: No suitable ECG signal variable was found.');
end

% Sampling frequency used by MIT-BIH record 100.
fs = 360;

% Approximate conversion used for this project dataset.
% If another ECG source is used, replace this with the appropriate gain and
% baseline values from that dataset's metadata.
ecg_mV = raw_signal / 200;

N = length(ecg_mV);
time_axis = (0:N-1) / fs;

%% 2. Stage 1: Band-Pass Filtering
% Emphasize QRS-band energy using a 5-15 Hz Butterworth band-pass filter.
f_low = 5;
f_high = 15;
order = 3;

[b, a] = butter(order, [f_low f_high] / (fs / 2), 'bandpass');
ecg_filtered = filtfilt(b, a, ecg_mV);

%% 3. Stage 2: Differentiation and Squaring
% Enhance rapid slope changes associated with the QRS complex.
ecg_deriv = [0, diff(ecg_filtered)];
ecg_squared = ecg_deriv .^ 2;

%% 4. Stage 3: Moving-Window Integration
% Smooth the QRS-energy envelope over a 150 ms window.
window_width = round(0.150 * fs);
b_integ = ones(1, window_width) / window_width;

ecg_integrated = conv(ecg_squared, b_integ, 'same');

%% 5. Stage 4: Heuristic Threshold-Based Peak Detection
% Use the first 10 seconds to define a simple amplitude threshold.
% This is intentionally a demonstration heuristic rather than a
% patient-independent adaptive detector.
analysis_window = ecg_integrated(1:min(3600, N));
local_max = max(analysis_window);
threshold_level = local_max * 0.35;

% Enforce a minimum separation of 200 ms between candidate peaks.
min_peak_dist = 0.20 * fs;

[peaks, locs] = findpeaks(ecg_integrated, ...
                          'MinPeakHeight', threshold_level, ...
                          'MinPeakDistance', min_peak_dist);

if numel(locs) < 2
    error('Insufficient detected peaks for heart-rate estimation.');
end

%% 6. Heart Rate Estimation
rr_intervals_sec = diff(locs) / fs;
bpm = 60 / mean(rr_intervals_sec);

fprintf('===========================================\n');
fprintf(' ECG R-PEAK DETECTION & HEART RATE ESTIMATE \n');
fprintf('===========================================\n');
fprintf('Step 1: ECG data loaded\n');
fprintf('Step 2: 5-15 Hz band-pass filter applied\n');
fprintf('Step 3: QRS-energy features enhanced\n');
fprintf('Step 4: Candidate R-peaks detected\n');
fprintf('-------------------------------------------\n');
fprintf('Estimated mean heart rate: %.1f BPM\n', bpm);
fprintf('===========================================\n');

%% 7. Visualization: Signal-Processing Stages
figure('Name', 'ECG Signal Processing Stages', 'Color', 'w');

subplot(4,1,1);
plot(time_axis, ecg_mV, 'g');
title('Stage 1: Input ECG Signal');
ylabel('mV');
grid on;
xlim([0 5]);

subplot(4,1,2);
plot(time_axis, ecg_filtered, 'b');
title('Stage 2: 5-15 Hz Band-Pass Filtered ECG');
ylabel('mV');
grid on;
xlim([0 5]);

subplot(4,1,3);
plot(time_axis, ecg_squared, 'm');
title('Stage 3: Differentiated and Squared Signal');
ylabel('Amplitude^2');
grid on;
xlim([0 5]);

subplot(4,1,4);
plot(time_axis, ecg_integrated, 'r', 'LineWidth', 1.5);
title('Stage 4: Moving-Window Integrated QRS Energy');
xlabel('Time (seconds)');
ylabel('Amplitude');
grid on;
xlim([0 5]);

%% 8. Visualization: Detection Review
% This plot is a visual inspection aid. It is not a substitute for
% annotation-based sensitivity, PPV, or timing-error validation.
figure('Name', 'R-Peak Detection Review', 'Color', 'w');

plot(time_axis, ecg_integrated, 'b', 'LineWidth', 1.5);
hold on;
yline(threshold_level, 'r--', 'Detection Threshold', 'LineWidth', 2);
plot(time_axis(locs), ecg_integrated(locs), ...
    'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

title(['Candidate Peak Detection Review (Estimated HR: ' ...
       num2str(round(bpm)) ' BPM)']);
xlabel('Time (s)');
ylabel('Integrated QRS Energy');
grid on;
xlim([0 5]);
ylim([0 local_max * 1.2]);

%% 9. Monitor-Style Visualization with Local Peak Refinement
figure('Name', 'ECG Monitor-Style Visualization', 'Color', 'k');

plot(time_axis, ecg_mV, 'g', 'LineWidth', 1.2);
hold on;

% Candidate peaks are detected from the integrated signal. To align the
% markers more closely with local maxima in the input ECG, search +/-20
% samples around each candidate location.
corrected_locs = locs;
search_window = 20;

for i = 1:length(locs)
    current_idx = locs(i);

    start_idx = max(1, current_idx - search_window);
    end_idx = min(N, current_idx + search_window);

    [~, max_rel_idx] = max(ecg_mV(start_idx:end_idx));
    corrected_locs(i) = start_idx + max_rel_idx - 1;
end

plot(time_axis(corrected_locs), ecg_mV(corrected_locs), ...
    'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

title(['ECG MONITORING DEMO - ESTIMATED MEAN HR: ' ...
       num2str(round(bpm)) ' BPM'], ...
      'Color', 'w', 'FontSize', 14, 'FontWeight', 'bold');

xlabel('Time (s)', 'Color', 'w');
ylabel('Amplitude (mV)', 'Color', 'w');
set(gca, 'XColor', 'w', 'YColor', 'w', 'Color', 'k');
set(gca, 'GridColor', 'w', 'GridAlpha', 0.3);
grid on;
xlim([0 5]);

%% 10. Prepare Workspace Variables for Simulink
% Package the ECG as a time-stamped signal for the Simulink model.
ekg_simin = timeseries(ecg_mV, time_axis);

% The Discrete Filter block uses the band-pass coefficients b and a.
if ~exist('b', 'var') || ~exist('a', 'var')
    error('Error: Filter coefficients (b, a) are missing. Run the MATLAB script first.');
else
    disp('ECG data and filter coefficients are ready for Simulink.');
end
