audio_names = {'dog-bark', 'flute', 'speech'};
Js = [11, 12, 13, 14, 15, 16, 17];
scattering_strs = {'none', 'time', 'time-frequency'};
wavelets = {'morlet'};

% Define parameters.
N = 131072;

% Construct wavelet filter bank for visualization.
vis_archs = tsp19_setup_visualization(24, N);

for audio_name_str = audio_names

audio_name_str = audio_name_str{1};
audio_path = ['media/', audio_name_str, '.wav'];
disp(audio_path);

[target_waveform, sample_rate] = tsp19_load(audio_path, N / 2);
target_U0 = initialize_U(target_waveform, vis_archs{1}.banks{1});
target_Y1 = U_to_Y(target_U0, vis_archs{1}.banks);
target_U1 = Y_to_U(target_Y1{end}, vis_archs{1}.nonlinearity);
target_scalogram = display_scalogram(target_U1);
[~, target_argmax] = max(sum(abs(diff(log1p(target_scalogram), 1, 2)), 1));


for J = Js
for scattering_str = scattering_strs
scattering_str = scattering_str{1};

for wavelet_str = wavelets

wavelet_str = wavelet_str{1};

% Load waveform.
audio_path = [ ...
    'media/', ...
    audio_name_str, ...
    '_Q=08', ...
    '_J=', num2str(J), ...
    '_sc=', scattering_str, ...
    '_wvlt=', wavelet_str, '/', ...
    audio_name_str, ...
    '_Q=08', ...
    '_J=', num2str(J), ...
    '_sc=', scattering_str, ...
    '_wvlt=', wavelet_str, ...
    '_it=100.wav'];
disp(audio_path);

waveform = tsp19_load(audio_path,  N / 2);

% Compute scalogram.
U0 = initialize_U(waveform, vis_archs{1}.banks{1});
Y1 = U_to_Y(U0, vis_archs{1}.banks);
U1 = Y_to_U(Y1{end}, vis_archs{1}.nonlinearity);

% Display original scalogram.
scalogram = display_scalogram(U1);
[~, argmax] = max(sum(abs(diff(log1p(scalogram), 1, 2)), 1));
registered_scalogram = circshift(log1p(scalogram), ...
    (target_argmax - argmax), 2);

imagesc(log1p(registered_scalogram));
colormap rev_magma;
axis off;
drawnow();
export_fig([ ...
    'media/', ...
    audio_name_str, ...
    '_Q=08', ...
    '_J=', num2str(J), ...
    '_sc=', scattering_str, ...
    '_wvlt=', wavelet_str, '/', ...
    audio_name_str, ...
    '_Q=08', ...
    '_J=', num2str(J), ...
    '_sc=', scattering_str, ...
    '_wvlt=', wavelet_str, ...
    '_it=100_registered.png']);

end
end
end

end
