clear;
DATAWIDTH = 16
vectorMode = 1;

if (vectorMode == 1)
    
    N = 101;
    
    xVec = zeros(6, N);
    yVec = zeros(6, N);
    zVec = zeros(6, N);
    
    
    % 1. Circular Vectoring (1, 0)
    xVec(2, :) = ones(1, N);
    yVec(2, :) = linspace(-1, 1, N);
    zVec(2, :) = zeros(1, N);
    
    % 2. Circular Rotation (1, 1)
    xVec(1, :) = ones(1, N);
    yVec(1, :) = zeros(1, N);
    zVec(1, :) = linspace(-pi/2, pi/2, N);
    
    % 3. Linear Vectoring (0, 0)
    xVec(4, :) = ones(1, N);
    yVec(4, :) = linspace(-1, 1, N);
    zVec(4, :) = zeros(1, N);
    
    % 4. Linear Rotation (0, 1)
    xVec(3, :) = ones(1, N) * 0.5;
    yVec(3, :) = zeros(1, N);
    zVec(3, :) = linspace(-1, 1, N);
    
    % 5. Hyperbolic Vectoring (-1, 0)
    w_sweep    = linspace(0.1, 1, N);
    xVec(6, :) = w_sweep + 0.25;
    yVec(6, :) = w_sweep - 0.25;
    zVec(6, :) = zeros(1, N);
    
    % 6. Hyperbolic Rotation (-1, 1)
    xVec(5, :) = 0.5*ones(1, N);
    yVec(5, :) = zeros(1, N);
    zVec(5, :) = linspace(-1, 1, N);

else
    N = 1;
    xVec = zeros(6, 1);
    yVec = zeros(6, 1);
    zVec = zeros(6, 1);

    % 1. Circular Vectoring (1, 0)
    xVec(2, :) = 1;
    yVec(2, :) = -0.5;
    zVec(2, :) = 0;
    
    % 2. Circular Rotation (1, 1)
    xVec(1, :) = 1;
    yVec(1, :) = 0;
    zVec(1, :) = pi/2;
    
    % 3. Linear Vectoring (0, 0)
    xVec(4, :) = 1;
    yVec(4, :) = -0.2;
    zVec(4, :) = 0;
    
    % 4. Linear Rotation (0, 1)
    xVec(3, :) = -0.5;
    yVec(3, :) = 0;
    zVec(3, :) = 0.3;
    
    % 5. Hyperbolic Vectoring (-1, 0)
    xVec(6, :) = 0.25;
    yVec(6, :) = -0.25;
    zVec(6, :) = 0;
    
    % 6. Hyperbolic Rotation (-1, 1)
    xVec(5, :) = 0.5;
    yVec(5, :) = 0;
    zVec(5, :) = -0.8;
end

    xSol = zeros(6, N);
    ySol = zeros(6, N);
    zSol = zeros(6, N);
    
    xSol = zeros(6, length(xVec));
    ySol = zeros(6, length(yVec));
    zSol = zeros(6, length(zVec));
    
    testcaseVec = [1 0; 1 1; 0 0; 0 1; -1 0; -1 1];
    
    for k = 1:length(testcaseVec)
        for i = 1:width(xVec)
            [xSol(k, i), ySol(k, i), zSol(k, i)] = GENCORDIC_SF(xVec(k, i), yVec(k, i), zVec(k, i), testcaseVec(k, 1), testcaseVec(k,2), DATAWIDTH);
        end
    end
    
    close all;
    
    figure(Name="Overvieplot");
    subplot(3,2,1);
    plot(xSol(1, :), DisplayName="X REG");
    hold on;
    plot(ySol(1, :), DisplayName="Y REG");
    plot(zSol(1, :), DisplayName="Z REG");
    title('Zirkular Rotation Result');
    legend();
    grid on;
    grid minor;
    
    subplot(3,2,2);
    plot(xSol(2, :), DisplayName="X REG");
    hold on;
    plot(ySol(2, :), DisplayName="Y REG");
    zSol(2,:) = mod(zSol(2,:), 2*pi);
    plot(zSol(2, :), DisplayName="Z REG");
    title('Zirkular Vectoring Result');
    legend();
    grid on;
    grid minor
    
    subplot(3,2,3);
    plot(xSol(3, :), DisplayName="X REG");
    hold on;
    plot(ySol(3, :), DisplayName="Y REG");
    plot(zSol(3, :), DisplayName="Z REG");
    title('Linear Rotation Result');
    legend();
    grid on;
    grid minor;
    
    subplot(3,2,4);
    plot(xSol(4, :), DisplayName="X REG");
    hold on;
    plot(ySol(4, :), DisplayName="Y REG");
    plot(zSol(4, :), DisplayName="Z REG");
    title('Linear Vectoring Result');
    legend();
    grid on;
    grid minor;
    
    subplot(3,2,5);
    plot(xSol(5, :), DisplayName="X REG");
    hold on;
    plot(ySol(5, :), DisplayName="Y REG");
    plot(zSol(5, :), DisplayName="Z REG");
    title('Hyperbolic Rotating Result');
    legend();
    grid on;
    grid minor;
    
    subplot(3,2,6);
    plot(xSol(6, :), DisplayName="X REG");
    hold on;
    plot(ySol(6, :), DisplayName="Y REG");
    plot(zSol(6, :), DisplayName="Z REG");
    title('Hyperbolic Vectoring Result');
    legend();
    grid on;
    grid minor;
    
    q = DATAWIDTH-2;
    
    xVec2q30 = round(xVec * 2^q);
    yVec2q30 = round(yVec * 2^q);
    zVec2q30 = round(zVec * 2^q);
    zVec2q30(2,:) = round(zVec(2,:) * 2^(q-2));
    xSol2q30 = round(xSol * 2^q);
    ySol2q30 = round(ySol * 2^q);
    zSol2q30 = round(zSol * 2^q);
    zSol2q30(2,:) = round(zSol(2,:) * 2^(q-2));
    
    sz_xVec = size(xVec2q30);
    sz_yVec = size(yVec2q30);
    sz_zVec = size(zVec2q30);
    sz_xSol = size(xSol2q30);
    sz_ySol = size(ySol2q30);
    sz_zSol = size(zSol2q30);
    
    xVecChar = strings(sz_xVec);
    yVecChar = strings(sz_yVec);
    zVecChar = strings(sz_zVec);
    xSolChar = strings(sz_xSol);
    ySolChar = strings(sz_ySol);
    zSolChar = strings(sz_zSol);
    
    for k = 1:length(testcaseVec)
        for i = 1:width(xVec)
            xVecChar(k, i) = sprintf('%d', xVec2q30(k,i));
            yVecChar(k, i) = sprintf('%d', yVec2q30(k,i));
            zVecChar(k, i) = sprintf('%d', zVec2q30(k,i));
            xSolChar(k, i) = sprintf('%d', xSol2q30(k,i));
            ySolChar(k, i) = sprintf('%d', ySol2q30(k,i));
            zSolChar(k, i) = sprintf('%d', zSol2q30(k,i));
        end
    end
    
    fid = fopen('testVectors.txt', 'w');
    if fid == -1
        error('Failed to open output file.');
    end

    [rows, cols] = size(xVecChar);
    
    for r = 1:rows
        mu_math = testcaseVec(r, 1);
        mode    = testcaseVec(r, 2);
    
        if mu_math == 1
            mu_str = '01';
        elseif mu_math == 0
            mu_str = '00';
        elseif mu_math == -1
            mu_str = '11';
        else
            mu_str = '00';
        end
    
        for c = 1:N
            fprintf(fid, '%s %d %d %d %d %d %d %d\n', ...
                mu_str, mode, ...
                xVec2q30(r,c), yVec2q30(r,c), zVec2q30(r,c), ...
                xSol2q30(r,c), ySol2q30(r,c), zSol2q30(r,c));
        end

        fprintf(fid, '\n');
    end
    
    fclose(fid);
