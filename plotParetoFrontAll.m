function fig = plotParetoFrontAll(details, varargin)
% plotParetoFrontAll
% Plot Pareto front in (Latency, Throughput) space using smoothed curves.
% Shows all CW points, Pareto points, and highlights the selected Wtrade.
%
% Input:
%   details : output 'details' from analyzeCWSelection (struct array)
%
% Name-Value:
%   'ProtocolName' : title prefix
%   'ShowAllPoints': true/false (default true)

    p = inputParser;
    p.addParameter('ProtocolName',"Protocol", @(s)ischar(s) || isstring(s));
    p.addParameter('ShowAllPoints', true, @(x)islogical(x) && isscalar(x));
    p.parse(varargin{:});
    opt = p.Results;

    fig = figure('Name', string(opt.ProtocolName) + " Pareto (smoothed)");
    hold on; grid on;

    xlabel('Latency (smoothed)');
    ylabel('Throughput (smoothed)');
    title(string(opt.ProtocolName) + " Pareto front (maximize throughput, minimize latency)");

    for k = 1:numel(details)
        W  = details(k).W(:);
        Ts = details(k).T_smooth(:);
        Ls = details(k).L_smooth(:);
        pIdx = details(k).paretoIdx(:);

        label = sprintf('Packet generation time = %g', details(k).parTime);

        % All points (optional)
        if opt.ShowAllPoints
            plot(Ls, Ts, 'o', 'HandleVisibility','off');  % same color as next plot may not hold, but OK
        end

        % Pareto points (connected for readability)
        [Lp, ord] = sort(Ls(pIdx));
        Tp = Ts(pIdx);
        Tp = Tp(ord);

        plot(Lp, Tp, '-o', 'DisplayName', label);

        % Mark chosen Wtrade
        Wtrade = details(k).Wtrade;
        iTrade = find(W == Wtrade, 1, 'first');
        if ~isempty(iTrade)
            plot(Ls(iTrade), Ts(iTrade), 'p', 'MarkerSize', 12, ...
                 'LineWidth', 1.5, 'HandleVisibility','off');
            text(Ls(iTrade), Ts(iTrade), sprintf('  W=%g', Wtrade), ...
                 'VerticalAlignment','bottom', 'FontSize', 9);
        end
    end

    legend('Location','best');
end
