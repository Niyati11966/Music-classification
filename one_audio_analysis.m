clc;
clear;
close all;

%% =========================================================
%        MUSIC EMOTION CLASSIFICATION
%        HAPPY / SAD
%        Signal Processing + Feature Extraction
% =========================================================

%% 1. CHOOSE AUDIO FILE

[file, path] = uigetfile( ...
    {'*.mp3;*.wav', 'Audio Files (*.mp3, *.wav)'}, ...
    'Choose an Audio File');

% Check if user cancelled
if isequal(file,0)
    fprintf('No audio file selected.\n');
    return;
end

% Complete audio file path
audioFile = fullfile(path,file);

fprintf('\n========================================\n');
fprintf('       MUSIC EMOTION CLASSIFICATION\n');
fprintf('========================================\n');
fprintf('Selected File: %s\n',file);

%% =========================================================
% 2. READ AUDIO
% =========================================================

try

    [x, Fs] = audioread(audioFile);

catch ME

    fprintf('\nERROR: Could not read the audio file.\n');
    fprintf('%s\n',ME.message);
    return;

end

% Convert stereo audio to mono
if size(x,2) > 1
    x = mean(x,2);
end

% Normalize audio
maxValue = max(abs(x));

if maxValue > 0
    x = x ./ maxValue;
end

% Time vector
t = (0:length(x)-1)/Fs;

%% =========================================================
% 3. AUDIO INFORMATION
% =========================================================

duration = length(x)/Fs;

fprintf('\nAudio Information\n');
fprintf('----------------------------------------\n');
fprintf('File Name          : %s\n',file);
fprintf('Sampling Frequency : %d Hz\n',Fs);
fprintf('Duration           : %.2f seconds\n',duration);
fprintf('Number of Samples  : %d\n',length(x));

%% =========================================================
% 4. TIME DOMAIN WAVEFORM
% =========================================================

figure('Name','Time Domain Waveform');

plot(t,x);



xlabel('Time (seconds)');
ylabel('Amplitude');
title(['Audio Signal - Time Domain: ',file]);

grid on;

%% =========================================================
% 5. FFT - FREQUENCY DOMAIN
% =========================================================

N = length(x);

% FFT
X = fft(x);

% Two-sided spectrum
P2 = abs(X/N);

% Single-sided spectrum
P1 = P2(1:floor(N/2)+1);

if length(P1) > 2
    P1(2:end-1) = 2*P1(2:end-1);
end

% Frequency vector
f = Fs*(0:floor(N/2))/N;

%% =========================================================
% 6. DISPLAY FREQUENCY SPECTRUM
% =========================================================

figure('Name','Frequency Spectrum');

plot(f,P1);

xlabel('Frequency (Hz)');
ylabel('Magnitude');

title('Frequency Spectrum - FFT');

grid on;

% Display up to 5 kHz
xlim([0 min(5000,Fs/2)]);

%% =========================================================
% 7. SPECTROGRAM
% =========================================================

figure('Name','Spectrogram');

spectrogram(x,1024,512,1024,Fs,'yaxis');

title('Audio Spectrogram');

colorbar;

%% =========================================================
% 8. RMS ENERGY
% =========================================================

RMS = sqrt(mean(x.^2));

%% =========================================================
% 9. ZERO CROSSING RATE
% =========================================================

ZCR = sum(abs(diff(x > 0))) / length(x);

%% =========================================================
% 10. SPECTRAL CENTROID
% =========================================================

% Use FFT magnitude
magnitude = P1(:);
frequency = f(:);

spectralCentroid = ...
    sum(frequency .* magnitude) / ...
    (sum(magnitude) + eps);

%% =========================================================
% 11. MFCC
% =========================================================

mfccAvailable = true;

try

    mfccData = mfcc(x,Fs);

    % Mean MFCC values
    mfccMean = mean(mfccData,1,'omitnan');

catch

    mfccAvailable = false;

    mfccData = [];
    mfccMean = [];

end

%% =========================================================
% 12. DISPLAY MFCC
% =========================================================

if mfccAvailable

    figure('Name','MFCC Features');

    imagesc(mfccData');

    axis xy;

    xlabel('Time Frame');
    ylabel('MFCC Coefficient');

    title('MFCC Features');

    colorbar;

end

%% =========================================================
% 13. DISPLAY FEATURES
% =========================================================

fprintf('\n========================================\n');
fprintf('          AUDIO SIGNAL FEATURES\n');
fprintf('========================================\n');

fprintf('RMS Energy         : %.4f\n',RMS);

fprintf('Zero Crossing Rate : %.4f\n',ZCR);

fprintf('Spectral Centroid  : %.2f Hz\n', ...
    spectralCentroid);

if mfccAvailable

    fprintf('\nMean MFCC Values:\n');

    disp(mfccMean);

else

    fprintf('\nMFCC could not be calculated.\n');

end

%% =========================================================
% 14. HAPPY / SAD CLASSIFICATION
% =========================================================

% ---------------------------------------------------------
% Simple demonstration classifier
%
% Higher energy + higher spectral centroid
%     -> HAPPY
%
% Lower energy / lower centroid
%     -> SAD
% ---------------------------------------------------------

if RMS >= 0.08 && spectralCentroid >= 1500

    emotion = "HAPPY";
    emoji = "😊";

else

    emotion = "SAD";
    emoji = "😢";

end

%% =========================================================
% 15. DISPLAY CLASSIFICATION RESULT
% =========================================================

fprintf('\n========================================\n');
fprintf('        MUSIC EMOTION RESULT\n');
fprintf('========================================\n');

fprintf('Audio File         : %s\n',file);

fprintf('Predicted Emotion  : %s %s\n', ...
    emotion,emoji);

fprintf('========================================\n');

%% =========================================================
% 16. RESULT WINDOW
% =========================================================

resultFigure = figure( ...
    'Name','Music Emotion Result', ...
    'NumberTitle','off', ...
    'Position',[400 250 600 400]);

axis off;

% Main heading
text(0.5,0.82, ...
    'MUSIC EMOTION CLASSIFICATION', ...
    'HorizontalAlignment','center', ...
    'FontSize',20, ...
    'FontWeight','bold');

% Selected file
text(0.5,0.68, ...
    ['Audio File: ',file], ...
    'HorizontalAlignment','center', ...
    'FontSize',13);

% Result
text(0.5,0.50, ...
    ['Predicted Emotion: ',char(emotion)], ...
    'HorizontalAlignment','center', ...
    'FontSize',24, ...
    'FontWeight','bold');

% RMS
text(0.5,0.34, ...
    sprintf('RMS Energy: %.4f',RMS), ...
    'HorizontalAlignment','center', ...
    'FontSize',14);

% ZCR
text(0.5,0.26, ...
    sprintf('Zero Crossing Rate: %.4f',ZCR), ...
    'HorizontalAlignment','center', ...
    'FontSize',14);

% Spectral Centroid
text(0.5,0.18, ...
    sprintf('Spectral Centroid: %.2f Hz', ...
    spectralCentroid), ...
    'HorizontalAlignment','center', ...
    'FontSize',14);

% Final message
text(0.5,0.07, ...
    'Analysis Completed', ...
    'HorizontalAlignment','center', ...
    'FontSize',12);
