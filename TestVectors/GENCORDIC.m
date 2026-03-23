function [xO, yO, zO] = GENCORDIC(x, y, z, u, mode, iterations)
%GENCORDIC generic CORDIC module
%   u  -> rotation mode:
%           1 -> circular
%           0 -> linear
%           -1 -> hyperbolic
%   mode -> 0 -> rotation mode
%           1 -> vectoring mode
    start = 1;
    if (u == -1)
        start = 2;
    end
    itVect = 0:iterations-1;
    potVect = itVect;
    itVect = 2.^(-itVect);
    d = 1;
    
    K = prod(sqrt(1+2.^(-2*potVect)));
    Kp = prod(sqrt(1-2.^(-2*potVect(2:end))));
    
    xReg = x;
    yReg = y;
    zReg = z;

    if (u == 1)
        lookUp = atan(itVect);
    elseif (u == 0)
        lookUp = itVect;
    else
        lookUp = atanh(itVect);
    end

    i = start;
    repeat = 0;

    while (i < iterations)
        %get sign aka d
        if (mode == 0)
            if (zReg >= 0)
                d = 1;
            else
                d = -1;
            end
        else
            if (((xReg >= 0) && (yReg >= 0)) || ((xReg < 0) && (yReg < 0)))
                d = -1;
            else
                d = 1;
            end
        end

        xRegN = xReg - u*d*2^(-(i-1))*yReg;
        yRegN = yReg + d*2^(-(i-1))*xReg;
        zRegN = zReg - d*lookUp(i);

        xReg = xRegN;
        yReg = yRegN;
        zReg = zRegN;

        if ((u == -1) && ((i == 4) || (i == 13) || (i == 40)) && (repeat == 0))
            repeat = 1;
        else
            i = i + 1;
            repeat = 0;
        end
    end

    if ((u == 1) && (mode == 0))
        xO = xReg/K;
        yO = yReg/K;
        zO = zReg;
    elseif ((u == 1)&&(mode == 1))
        xO = xReg/K;
        yO = yReg;
        zO = zReg;
    elseif ((u == -1) && (mode == 0))
        xO = xReg/Kp;
        yO = yReg/Kp;
        zO = zReg;
    elseif ((u == -1) && (mode == 1))
        xO = xReg/Kp;
        yO = yReg;
        zO = zReg;
    else
        xO = xReg;
        yO = yReg;
        zO = zReg;
    end
end