function [predict] = cca(signal, ref_signals, fs)

% Filter the signal
for i = 1:size(signal,1)
    signal(i,:) = my_filter(signal(i,:), fs, 1, 100, 50, 50);
end
% signal = signal(:,length(signal)-1024+1:length(signal));

% Find SSVEP frequency and maximum canonical correlation
[predict, ~] = find_ssvep_freq(signal, ref_signals, 4, fs);
end

function [signal_filt] = my_filter(signal, fs, fl, fh, f0, Q)
% Bandpass filter
n = 4;  % Filter order
[b_band, a_band] = butter(n, [fl, fh]/(fs/2));
signal_filt = filtfilt(b_band, a_band, signal);  % Double-direction filtering to reduce transient response influence

signal_filt = signal_filt - signal_filt(1);  % Remove mean

% 50Hz Butterworth notch filter
W0 = f0 / (fs/2);
bw = W0/Q;
[b_notch, a_notch] = butter(n, [W0-bw, W0+bw], 'stop');
signal_filt = filtfilt(b_notch, a_notch, signal_filt);
end

function [fs, rho_max] = find_ssvep_freq(eeg, ref_signals, N_harm, Fs)
% Input:
%   eeg: A preprocessed EEG signal column vector
%   ref_signals: Reference signal matrix, with each column representing a specific frequency reference signal
%   N_harm: Number of harmonic frequencies for each reference signal
%
% Output:
%   fs: Estimated SSVEP frequency (Hz)
%   rho_max: Maximum canonical correlation coefficient

% Build reference signals for each frequency
freqs = ref_signals;
N_ref = length(freqs);
N_samples = length(eeg);
ref_signals_all = zeros(N_samples, N_harm*N_ref*2);
for i = 1:N_ref
    freq = freqs(i);
    ref_signals_i = zeros(N_samples, N_harm*2);
    for j = 1:N_harm
        ref_signals_i(:,(j-1)*2+1) = sin(2*pi*j*freq*(0:N_samples-1)/Fs);
        ref_signals_i(:,j*2) = cos(2*pi*j*freq*(0:N_samples-1)/Fs);
    end
    ref_signals_all(:,(i-1)*N_harm*2+1:i*N_harm*2) = ref_signals_i;
end

% Apply CCA algorithm to compute the canonical correlation coefficients between EEG data and each reference signal
rho = zeros(N_ref, 1);
for i = 1:N_ref
    [~, ~, r] = canoncorr(eeg', ref_signals_all(:,(i-1)*N_harm*2+1:i*N_harm*2));
    rho(i) = max(r);
end

% Find the reference signal with the highest canonical correlation coefficient
[rho_max, ind] = max(rho);
fs = freqs(ind);
end