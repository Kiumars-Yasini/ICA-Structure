clc; clear all; close all;

% Load cell data
load("SAR_ANR26650M1B_A_1_3.mat");

% Set parameters
Cellnum       = 1;  % Cell index to analyze
Cycnum        = numel(cell_struct.equivalent_cycle_count);
equiv         = cell_struct.equivalent_cycle_count(:);

% Create figure
figure; hold on; box on; ax = gca;
ax.FontSize = 16;
xlabel('Voltage in V', 'FontSize', 18);
ylabel('dQ/dV in Ah/V', 'FontSize', 18);

% Define colormap based on equivalent cycle counts
colormap(jet);
cmin = 0;
cmax = 1000;
caxis([cmin cmax]);  % map color limits to [min,max]

% Create colorbar
cb = colorbar;
nticks = 11;
tickVals = linspace(cmin, cmax, nticks);
cb.Ticks = tickVals;
cb.TickLabels = round(tickVals);
cb.Label.String = 'Equivalent cycle count';
cb.Label.FontSize = 16;
cb.FontSize = 14;

% --- Filter and smoothing settings ---
smoothingMethod = 'butter';   % Options: 'butter', 'rloess', 'wavelet'
butterOrder     = 4;
butterFc        = 0.02;       % Butterworth cutoff fraction
rloessWin       = 0.05;       % Window for rloess
waveletName     = 'db8';
waveletLevel    = 3;

% === ICA Plot Loop ===
for l = 1:Cycnum
    % Get capacity and voltage data
    value = cell_struct.AhStep_CHA{1,l}(:);
    soc = value / value(end);  % Vectorized SoC
    U = cell_struct.qOCV_CHA{1,l}(:);
    
    Q = soc;
    
    % 1) Filter non-increasing voltages
    inc_idx = [true; diff(U) > 0];
    U_filt = U(inc_idx);
    Q_filt = Q(inc_idx);

    % 2) Ensure unique voltages
    [Vuniq, idxU] = unique(U_filt);
    Quniq = Q_filt(idxU);

    % 3) Smoothing
    switch lower(smoothingMethod)
        case 'butter'
            fs = 1 / mean(diff(Vuniq));  % Estimate sampling frequency
            [b, a] = butter(butterOrder, butterFc, 'low');
            Q_smooth = filtfilt(b, a, Quniq);
        case 'rloess'
            Q_smooth = smoothdata(Quniq, 'rloess', ...
                        floor(rloessWin * numel(Quniq)));
        case 'wavelet'
            Q_smooth = wdenoise(Quniq, waveletLevel, ...
                        'Wavelet', waveletName, ...
                        'DenoisingMethod', 'SURE');
        otherwise
            error('Unknown smoothing method.');
    end

    % 4) Differentiate
    dQdV_raw = diff(Q_smooth) ./ diff(Vuniq);

    % 5) Optional extra smoothing (zero-phase MA)
    dQdV = filtfilt(ones(1,5)/5, 1, dQdV_raw);

    % 6) Plot
    xPlot = Vuniq(1:end-1);
    yPlot = dQdV;

    cmap = jet(256);
    cv = (equiv(l) - cmin) / (cmax - cmin);
    idx = max(1, min(256, round(cv*255)+1));
    clr = cmap(idx, :);

    plot(xPlot, yPlot, 'LineWidth', 2, 'Color', clr);
end

% Title
title(['ICA – LFP50 Cell0' num2str(Cellnum)], 'FontSize', 20);

% Final formatting
xlim([3.2 3.45]);
set(gcf, 'Position', [100, 100, 800, 550]);
