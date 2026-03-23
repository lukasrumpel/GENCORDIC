clear;
DATAWIDTH = 16
vectorMode = 1;

if (vectorMode == 1)
    
    N = 101;
    
    xVec = zeros(6, N);
    yVec = zeros(6, N);
    zVec = zeros(6, N);
    
    
    % =========================================================================
    % 1. Zirkular Vectoring (1, 0) -> atan2(y,x) und Betrag
    % Test: Sweep über Y, konstantes X -> ergibt Phasenwinkel von -pi/4 bis pi/4
    xVec(2, :) = ones(1, N);
    yVec(2, :) = linspace(-1, 1, N);
    zVec(2, :) = zeros(1, N);
    
    % 2. Zirkular Rotation (1, 1) -> Sinus und Cosinus
    % Test: Winkel Z von -pi/2 bis pi/2 sweepen. X wird vorkompensiert!
    xVec(1, :) = ones(1, N);
    yVec(1, :) = zeros(1, N);
    zVec(1, :) = linspace(-pi/2, pi/2, N);
    
    % 3. Linear Vectoring (0, 0) -> Division (Z = Y/X)
    % Test: Sweep über Y. X ist fest auf 2. Ergebnis Z sollte Y/2 sein.
    xVec(4, :) = ones(1, N);
    yVec(4, :) = linspace(-1, 1, N);
    zVec(4, :) = zeros(1, N);
    
    % 4. Linear Rotation (0, 1) -> Multiplikation (Y = X*Z)
    % Test: Sweep über Z. X ist fest. Ergebnis Y sollte X*Z sein.
    xVec(3, :) = ones(1, N) * 0.5;
    yVec(3, :) = zeros(1, N);
    zVec(3, :) = linspace(-1, 1, N);
    
    % 5. Hyperbolisch Vectoring (-1, 0) -> Quadratwurzel (sqrt(w))
    % Test: Sweep des Wertes 'w' von 0.1 bis 2.
    % Setup: X = w + 0.25, Y = w - 0.25. (Ergebnis in X muss noch mit Ah skaliert werden!)
    w_sweep    = linspace(0.1, 1, N);
    xVec(6, :) = w_sweep + 0.25;
    yVec(6, :) = w_sweep - 0.25;
    zVec(6, :) = zeros(1, N);
    
    % 6. Hyperbolisch Rotation (-1, 1) -> sinh(Z) und cosh(Z)
    % Test: Sweep Z im gültigen Konvergenzbereich (ca. -1.118 bis 1.118).
    xVec(5, :) = 0.5*ones(1, N);
    yVec(5, :) = zeros(1, N);
    zVec(5, :) = linspace(-1, 1, N);
    % =========================================================================
else
    N = 1;
    xVec = zeros(6, 1);
    yVec = zeros(6, 1);
    zVec = zeros(6, 1);
    % =========================================================================
    % 1. Zirkular Vectoring (1, 0) -> atan2(y,x) und Betrag
    % Test: Sweep über Y, konstantes X -> ergibt Phasenwinkel von -pi/4 bis pi/4
    xVec(2, :) = 1;
    yVec(2, :) = -0.5;
    zVec(2, :) = 0;
    
    % 2. Zirkular Rotation (1, 1) -> Sinus und Cosinus
    % Test: Winkel Z von -pi/2 bis pi/2 sweepen. X wird vorkompensiert!
    xVec(1, :) = 1;
    yVec(1, :) = 0;
    zVec(1, :) = pi/2;
    
    % 3. Linear Vectoring (0, 0) -> Division (Z = Y/X)
    % Test: Sweep über Y. X ist fest auf 2. Ergebnis Z sollte Y/2 sein.
    xVec(4, :) = 1;
    yVec(4, :) = -0.2;
    zVec(4, :) = 0;
    
    % 4. Linear Rotation (0, 1) -> Multiplikation (Y = X*Z)
    % Test: Sweep über Z. X ist fest. Ergebnis Y sollte X*Z sein.
    xVec(3, :) = -0.5;
    yVec(3, :) = 0;
    zVec(3, :) = 0.3;
    
    % 5. Hyperbolisch Vectoring (-1, 0) -> Quadratwurzel (sqrt(w))
    % Test: Sweep des Wertes 'w' von 0.1 bis 2.
    % Setup: X = w + 0.25, Y = w - 0.25. (Ergebnis in X muss noch mit Ah skaliert werden!)
    xVec(6, :) = 0.25;
    yVec(6, :) = -0.25;
    zVec(6, :) = 0;
    
    % 6. Hyperbolisch Rotation (-1, 1) -> sinh(Z) und cosh(Z)
    % Test: Sweep Z im gültigen Konvergenzbereich (ca. -1.118 bis 1.118).
    xVec(5, :) = 0.5;
    yVec(5, :) = 0;
    zVec(5, :) = -0.8;
end
    
    % Speicher für Ergebnisse allokieren
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
    
    % Generate empty string arrays matching the sizes of the fixed-point matrices
    sz_xVec = size(xVec2q30);
    sz_yVec = size(yVec2q30);
    sz_zVec = size(zVec2q30);
    sz_xSol = size(xSol2q30);
    sz_ySol = size(ySol2q30);
    sz_zSol = size(zSol2q30);
    
    % Create empty string arrays of the same sizes
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
    
    % Open file for writing
    fid = fopen('testVectors.txt', 'w');
    if fid == -1
        error('Failed to open output file.');
    end
    
    % Determine dimensions
    [rows, cols] = size(xVecChar);
    
    % For each test case (row), write lines in the requested pattern:
    % xVec yVec zVec xSol ySol zSol
    for r = 1:rows
        mu_math = testcaseVec(r, 1);
        mode    = testcaseVec(r, 2);
    
        % Mappe den mathematischen MU-Wert auf deinen VHDL bit_vector String
        if mu_math == 1
            mu_str = '01';   % Zirkular
        elseif mu_math == 0
            mu_str = '00';   % Linear
        elseif mu_math == -1
            mu_str = '11';   % Hyperbolisch
        else
            mu_str = '00';   % Fallback
        end
    
        for c = 1:N
            % %s für den MU-String, %d für den Rest
            fprintf(fid, '%s %d %d %d %d %d %d %d\n', ...
                mu_str, mode, ...
                xVec2q30(r,c), yVec2q30(r,c), zVec2q30(r,c), ...
                xSol2q30(r,c), ySol2q30(r,c), zSol2q30(r,c));
        end
        % Optional blank line between test cases for readability
        fprintf(fid, '\n');
    end
    
    fclose(fid);
