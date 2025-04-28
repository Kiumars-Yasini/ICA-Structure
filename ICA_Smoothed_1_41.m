figure; hold on; grid on;
cmap = jet(41);  % Color gradient from blue to red

for i = 1:41
    Q = cell_struct.AhStep_CHA{1,i};
    V = cell_struct.qOCV_CHA{1,i};

    if length(Q) > 10 && length(V) > 10  % Skip too-short cycles
        min_len = min(length(Q), length(V));
        Q = Q(1:min_len);
        V = V(1:min_len);

        dQ = diff(Q);
        dV = diff(V);
        V_mid = (V(1:end-1) + V(2:end)) / 2;

        % 💡 Stronger filtering
        eps = 1e-4;  % Minimum dV to avoid divide-by-zero
        valid = abs(dV) > eps & abs(dQ) < 0.05 & abs(dV) < 0.05;

        dQ = dQ(valid);
        dV = dV(valid);
        V_mid = V_mid(valid);

        if length(dQ) > 10  % Still enough points after filtering
            dQdV = dQ ./ dV;

            % 🧽 Smooth with Savitzky-Golay
            window = min(1000, length(dQdV));  % Smaller, tighter smoothing
            dQdV_smooth = smooth(dQdV, window, 'lowess');

            % Plot
            plot(V_mid, dQdV_smooth, 'Color', cmap(i,:), 'LineWidth', 1.2);
        end
    end
end

xlabel('Voltage (V)');
ylabel('dQ/dV');
title('ICA – All 41 Cycles (Filtered + Smoothed)');
colormap(jet(41));
colorbar('Ticks', linspace(0,1,5), 'TickLabels', {'1','11','21','31','41'});
