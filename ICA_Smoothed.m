clc; clear; close all;
load("___________.mat");

cycle_values = cell_struct.equivalent_cycle_count;  % Actual cycle values


cycle_min = min(cycle_values);
cycle_max = max(cycle_values);

figure; hold on; grid on;
colormap(jet(length(cycle_values)));
cmap = colormap;

for i = 1:length(cycle_values)
    Q = cell_struct.AhStep_CHA{1,i};
    V = cell_struct.qOCV_CHA{1,i};
    
    % Ensure column vectors and same length
    Q = Q(:);
    V = V(:);
    min_len = min(length(Q), length(V));
    Q = Q(1:min_len);
    V = V(1:min_len);

    % Compute differences
    dQ = diff(Q);
    dV = diff(V);
    V_mid = (V(1:end-1) + V(2:end)) / 2;

    % Filter: remove too small or huge dV (avoid division noise)
    eps = 1e-4;
    valid = abs(dV) > eps & abs(dQ) < 0.05 & abs(dV) < 0.05;  % can tweak 0.05
    dQ = dQ(valid);
    dV = dV(valid);
    V_mid = V_mid(valid);

    % Compute dQ/dV and smooth
    dQdV = dQ ./ dV;
    span = max(5, round(0.01 * length(dQdV)));  % Smooth over 5% of points
    dQdV_smooth = smooth(dQdV, span, 'moving');

    % Plot
    color_idx = round((cycle_values(i) - cycle_min) / (cycle_max - cycle_min) * (length(cmap)-1)) + 1;
    plot(V_mid, dQdV_smooth, 'Color', cmap(color_idx,:), 'LineWidth', 1.2);
end

xlabel('Voltage (V)');
ylabel('dQ/dV');
xlim([3.25 3.45]);
ylim([0 0.4]);
title('ICA – All Cycles (Filtered + Smoothed)');

% Colorbar
cb = colorbar;
clim([cycle_min cycle_max]);
cb.Ticks = linspace(cycle_min, cycle_max, 5);
cb.TickLabels = arrayfun(@(v) sprintf('%.0f', v), cb.Ticks, 'UniformOutput', false);
cb.Label.String = 'Cycle Value';
