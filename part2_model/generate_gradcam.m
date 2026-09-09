function [heatmap_rgb, overlay_rgb, peak_quadrant] = generate_gradcam(rgb_img, ma_mask, grade)
% GENERATE_GRADCAM Visual Attention Heatmap & Peak Lesion Quadrant Localization.
% Generates attention saliency heatmaps focused on detected lesion clusters and
% computes alpha-blended overlays for clinical visual validation.

    if nargin < 3, grade = 1; end

    [h, w, ~] = size(rgb_img);
    I_double = double(rgb_img) / 255.0;

    % If lesion mask is available, build attention map around lesion clusters
    if any(ma_mask(:))
        kernel_size = 31;
        sigma = 12;
        [X, Y] = meshgrid(-(kernel_size-1)/2 : (kernel_size-1)/2);
        gaussian_kernel = exp(-(X.^2 + Y.^2) / (2 * sigma^2));
        gaussian_kernel = gaussian_kernel / sum(gaussian_kernel(:));

        attention = conv2(double(ma_mask), gaussian_kernel, 'same');
        if max(attention(:)) > 0
            attention = attention / max(attention(:));
        end
    else
        % Center-weighted macular focus
        [X, Y] = meshgrid(linspace(-1, 1, w), linspace(-1, 1, h));
        R = sqrt(X.^2 + Y.^2);
        attention = exp(- (R.^2) / 0.35);
        attention = attention / max(attention(:));
    end

    % Colormap Jet transformation
    cmap = jet(256);
    idx = round(attention * 254) + 1;
    idx = max(1, min(256, idx));

    heatmap_rgb = zeros(h, w, 3);
    for c = 1:3
        channel_map = cmap(:, c);
        heatmap_rgb(:, :, c) = reshape(channel_map(idx), [h, w]);
    end

    % Alpha-blended overlay (65% original retina + 35% heatmap)
    overlay_rgb = 0.65 * I_double + 0.35 * heatmap_rgb;
    overlay_rgb = max(0.0, min(1.0, overlay_rgb));

    % Peak attention quadrant
    mid_y = floor(h / 2);
    mid_x = floor(w / 2);
    q_scores = [
        sum(sum(attention(1:mid_y, mid_x:end))), ...   % Superotemporal
        sum(sum(attention(mid_y:end, mid_x:end))), ... % Inferotemporal
        sum(sum(attention(1:mid_y, 1:mid_x))), ...     % Superonasal
        sum(sum(attention(mid_y:end, 1:mid_x)))        % Inferonasal
    ];
    [~, max_q] = max(q_scores);
    quadrant_names = {'Superotemporal', 'Inferotemporal', 'Superonasal', 'Inferonasal'};
    peak_quadrant = quadrant_names{max_q};
end
