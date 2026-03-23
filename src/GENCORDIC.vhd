library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use work.CORDICPackage.all;



entity GENCORDIC is
    generic(
        DATAWIDTH : natural range 4 to 32 := 32
    );
    port (
        CLK :           in std_logic;
        X_IN :          in signed(DATAWIDTH-1 downto 0);
        Y_IN :          in signed(DATAWIDTH-1 downto 0);
        Z_IN :          in signed(DATAWIDTH-1 downto 0); 
        MU:             in std_logic_vector(1 downto 0);
        MODE :          in std_logic;
        ITERATIONS :    in natural range 0 to DATAWIDTH;
        RESET :         in std_logic;
        START :         in std_logic;
        BUSY :          out std_logic;
        X_OUT :         out signed(DATAWIDTH-1 downto 0);
        Y_OUT :         out signed(DATAWIDTH-1 downto 0);
        Z_OUT :         out signed(DATAWIDTH-1 downto 0)  
    ) ;
end GENCORDIC ; 

architecture RTL of GENCORDIC is
    signal xREG : signed(DATAWIDTH downto 0);
    signal yREG : signed(DATAWIDTH downto 0);
    signal zREG : signed(DATAWIDTH downto 0);
    signal MUReg : std_logic_vector(1 downto 0);
    signal MODEReg : std_logic;
    signal YSignReg, XSignReg, ZSignReg : std_logic;
    signal zREGPip : signed(DATAWIDTH-1 downto 0);
    signal zREGPipQ2, zREGPipQ3, zREGPipQ4 : signed(DATAWIDTH-1 downto 0);
    signal COMPUTEFLAG : bit;
    signal ItCNT : natural range 0 to 60 := 0;
    signal PipStageCNT : unsigned(PIPSTAGECNTWIDTH-1 downto 0) := (others => '0');
    signal shiftedY : signed(DATAWIDTH downto 0);
    signal shiftedX : signed(DATAWIDTH downto 0);
    signal XN : signed(DATAWIDTH+1 downto 0);
    signal YN : signed(DATAWIDTH+1 downto 0);
    signal lookUpVal : signed(DATAWIDTH-1 downto 0);
    signal multipliedLookUpVal : signed(DATAWIDTH-1 downto 0);
    signal ZN : signed(DATAWIDTH+1 downto 0);
    signal d : std_logic;
    signal ctrlVec : std_logic_vector(2 downto 0);
    signal current_shift : natural range 0 to 60;
    signal iterationArrLUTRow : natural range 0 to 60;
    signal maxIter : natural range 0 to 60;
    signal currColumn : natural range 0 to 60;
    signal yZERO, yZEROH, yZEROL : std_logic;
    signal active_shift_row : SHIFT_ROW_T;
    TYPE FSMCONTROLTYPE is (IDLE, READINPUT, STARTCOMPUTATION, COMPUTE, SCALERESULTMUX, REMAPQUADRANT, OUTPUTRES);
    signal FSMCONTROLSTATE : FSMCONTROLTYPE := IDLE;
begin
    
    
    CONTROLLER : process(CLK) is 
    begin
        if (rising_edge(CLK)) then
            if (RESET = '0') then
                case (FSMCONTROLSTATE) is
                    when IDLE =>
                        if (START = '1') then
                            BUSY <= '1';
                            FSMCONTROLSTATE <= READINPUT;
                            MUReg <= MU;
                            MODEReg <= MODE;
                            XSignReg <= X_IN(DATAWIDTH-1);
                            YSignReg <= Y_IN(DATAWIDTH-1);
                            ZSignReg <= Z_IN(DATAWIDTH-1);
                            iterationArrLUTRow <= ITERATIONS/4;
                        else
                            xREG <= (others => '0');
                            yREG <= (others => '0');
                            zREG <= (others => '0');
                            BUSY <= '0';
                            COMPUTEFLAG <= '0';
                            yZERO <= '0';
                        end if;
                    when READINPUT =>
                        FSMCONTROLSTATE <= STARTCOMPUTATION;
                        if ((MODEReg = '1') and (MUReg = "01")) then
                            case(XSignReg) is
                                when '1' => xREG <= resize(-X_IN, DATAWIDTH+1);
                                when others => xREG <= resize(X_IN, DATAWIDTH+1);
                            end case;
                            case(YSignReg) is 
                                when '1' => yREG <= resize(-Y_IN, DATAWIDTH+1);
                                when others => yREG <= resize(Y_IN, DATAWIDTH+1);
                            end case;
                            case(ZSignReg) is 
                                when '1' => zREG <= resize(-Z_IN,DATAWIDTH+1);
                                when others => zREG <= resize(Z_IN, DATAWIDTH+1) ;
                            end case;
                            if (Y_IN(DATAWIDTH/2-1 downto 0) = 0) then 
                                yZEROL <= '1';
                            else 
                                yZEROL <= '0';
                            end if;
                            if (Y_IN(DATAWIDTH-1 downto DATAWIDTH/2) = 0) then 
                                yZEROH <= '1';
                            else 
                                yZEROH <= '0';
                            end if;
                        else 
                            xREG <= RESIZE(X_IN, DATAWIDTH+1);
                            yREG <= RESIZE(Y_IN, DATAWIDTH+1);
                            zREG <= RESIZE(Z_IN, DATAWIDTH+1);
                        end if;

                        if (MUReg = "01") then
                            active_shift_row <= CIRC_SHIFT_TABLE(iterationArrLUTRow - 1);
                        elsif (MUReg = "11") then
                            active_shift_row <= HYP_SHIFT_TABLE(iterationArrLUTRow - 1);
                        end if; 

                    when STARTCOMPUTATION => 
                        COMPUTEFLAG <= '1';
                        yZERO <= yZEROL and yZEROH;
                        if (MUReg = "01") then
                            ItCNT <= CIRC_ITER_COUNTS(iterationArrLUTRow - 1);
                            maxIter <= CIRC_ITER_COUNTS(iterationArrLUTRow-1);
                        elsif (MUReg = "11") then
                            ItCNT <= HYP_ITER_COUNTS(iterationArrLUTRow -1);
                            maxIter <= HYP_ITER_COUNTS(iterationArrLUTRow-1);
                        else 
                            ItCNT <= ITERATIONS;
                        end if;
                        FSMCONTROLSTATE <= COMPUTE;

                        if (MUReg = "11") then
                            current_shift <= active_shift_row(0);
                            currColumn <= 1;
                        elsif (MUReg = "01") then
                            current_shift <= 0;
                            currColumn <= 0;
                        else
                            current_shift <= 0;
                            currColumn <= 0;
                        end if;

                    when COMPUTE =>
                        if ((PipStageCNT = NUMPIPSTAGES-1) and (ItCNT > 0)) then
                            ItCNT    <= ItCNT - 1;

                            xREG <= XN(DATAWIDTH downto 0);
                            yREG <= YN(DATAWIDTH downto 0);
                            zREG <= ZN(DATAWIDTH downto 0);

                        elsif ((PipStageCNT = 0) and (ItCNT > 0)) then
                            if (MUReg = "11" or MUReg = "01") then
                                current_shift <= active_shift_row(currColumn);
                            else
                                if(current_shift < ITERATIONS-1) then
                                    current_shift <= ITERATIONS-ItCNT+1;
                                end if;
                            end if;

                            if (currColumn < 59) then  
                                currColumn <= currColumn + 1;
                            end if;
                        end if; 

                        if ((ItCNT = 1) and (PipStageCNT = NUMPIPSTAGES-1)) then
                            COMPUTEFLAG <= '0';
                            FSMCONTROLSTATE <= SCALERESULTMUX;     
                        end if;
                    when SCALERESULTMUX =>
                        zREGPip <= zREG(DATAWIDTH downto 1);
                        if ((MODEReg = '1') and (MUReg = "01")) then 
                            FSMCONTROLSTATE <= REMAPQUADRANT;
                        else 
                            FSMCONTROLSTATE <= OUTPUTRES;
                        end if;
                    when REMAPQUADRANT =>
                        FSMCONTROLSTATE <= OUTPUTRES;
                        if  ((YSignReg = '1') and (XSignReg = '0')) then --quadrant IV
                            zREGPip(DATAWIDTH-1 downto 0) <= zREGPipQ4;
                        elsif ((YSignReg = '0') and (XSignReg = '1')) then --quadrant II
                            zREGPip(DATAWIDTH-1 downto 0) <= zREGPipQ2;
                        elsif ((YSignReg = '1') and (XSignReg = '1')) then -- quadrant III
                            zREGPip(DATAWIDTH-1 downto 0) <= zREGPipQ3;
                        else --quadrant I
                            zREGPip(DATAWIDTH-1 downto 0) <= resize(zREG srl 2, DATAWIDTH);
                        end if;
                    when OUTPUTRES =>
                        if (MUReg = "01") then
                            X_OUT <= xREG(DATAWIDTH downto 1);
                            Y_OUT <= yREG(DATAWIDTH downto 1);
                            if (yZERO = '1' and MODEReg = '1') then
                                Z_OUT <= (others => '0');
                            else
                                Z_OUT <= zREGPip;
                            end if;
                        elsif(MUReg = "11") then
                            X_OUT <= xREG(DATAWIDTH-2 downto 0) & '0';
                            Y_OUT <= yREG(DATAWIDTH-2 downto 0) & '0';
                            Z_OUT <= zREG(DATAWIDTH-1 downto 0);
                        else 
                            X_OUT <= xREG(DATAWIDTH-1 downto 0);
                            Y_OUT <= yREG(DATAWIDTH-1 downto 0);
                            Z_OUT <= zREG(DATAWIDTH-1 downto 0);                        
                        end if;
                        FSMCONTROLSTATE <= IDLE;
                        BUSY <= '0';
                end case;
            else
                xREG <= (others => '0');
                yREG <= (others => '0');
                zREG <= (others => '0');
                X_OUT <= (others => '0');
                Y_OUT <= (others => '0');
                Z_OUT <= (others => '0');
                ItCNT <= 0;
                BUSY <= '0';
                COMPUTEFLAG <= '0';
                FSMCONTROLSTATE <= IDLE;
                MUReg <= "00";
                MODEReg <= '0';
                XSignReg <= '0';
                YSignReg <= '0';
                ZSignReg <= '0'; 
            end if;
        end if;
    end process;

    CORDICALU : process(CLK) is
    begin
        if (rising_edge(CLK)) then
            if (COMPUTEFLAG = '1') then
                ----------------------------------- 
                -- actual pipeline 
                ----------------------------------- 
                if (PipStageCNT = 0) then
                    shiftedY <= SHIFT_RIGHT(yReg, current_shift);
                    shiftedX <= SHIFT_RIGHT(xREG, current_shift);
                    case (MUReg) is
                        when "01" =>
                            lookUpVal <= ATANLUTARR(current_shift)(MAXDATAWIDTH-1 downto (MAXDATAWIDTH-DATAWIDTH));
                        when "00" =>
                            lookUpVal <= ONELUTARR(current_shift)(MAXDATAWIDTH-1 downto (MAXDATAWIDTH-DATAWIDTH));
                        when others =>
                            lookUpVal <= ATANHLUTARR(current_shift)(MAXDATAWIDTH-1 downto (MAXDATAWIDTH-DATAWIDTH));
                    end case;
                    ctrlVec <= (MUReg & d);

                else

                    case MODEReg is
                        when '0' =>
                            if (ZN(DATAWIDTH+1) = '0') then
                                d <= '0';
                            else
                                d <= '1';
                            end if;
                        when others =>
                            if (((XN(DATAWIDTH+1) = '0') and (YN(DATAWIDTH+1) = '0')) or ((XN(DATAWIDTH+1) = '1') and (YN(DATAWIDTH+1) = '1'))) then
                                d <= '1';
                            else 
                                d <= '0';
                            end if;
                    end case;
                    
                end if;
            
                if (PipStageCNT < NUMPIPSTAGES-1) then
                    PipStageCNT <= PipStageCNT + 1; 
                else
                    PipStageCNT <= (others => '0');
                end if;

            else
                PipStageCNT <= (others => '0'); 
                case MODEReg is
                    when '0' =>
                        if (zREG(DATAWIDTH) = '0') then
                            d <= '0';
                        else
                            d <= '1';
                        end if;
                    when others =>
                        if (((xREG(DATAWIDTH) = '0') and (yREG(DATAWIDTH) = '0')) or ((xREG(DATAWIDTH) = '1') and (yREG(DATAWIDTH) = '1'))) then
                            d <= '1';
                        else 
                            d <= '0';
                        end if;
                end case;
            end if;
        end if;
    end process;

    --ctrlVec <= (MUReg & d);
    
    YN <= resize(yREG + shiftedX, DATAWIDTH+2) when (d = '0') else resize(yREG - shiftedX, DATAWIDTH+2);
    XN <= resize(xREG - shiftedY, DATAWIDTH+2) when ((ctrlVec = "111") or (ctrlVec = "010")) else resize(xReg, DATAWIDTH+2) when ((ctrlVec = "000") or (ctrlVec = "001")) else resize(xREG + shiftedY, DATAWIDTH+2);
    ZN <= resize(zREG - lookUpVal, DATAWIDTH+2) when (d = '0') else resize(zREG + lookUpVal, DATAWIDTH+2);
    
    zREGPipQ2 <= PI(MAXDATAWIDTH-1 downto MAXDATAWIDTH-DATAWIDTH) - resize(zREG srl 2, DATAWIDTH);
    zREGPipQ3 <= PI(MAXDATAWIDTH-1 downto MAXDATAWIDTH-DATAWIDTH) + resize(zREG srl 2, DATAWIDTH);
    zREGPipQ4 <= TWOPI(MAXDATAWIDTH-1 downto MAXDATAWIDTH-DATAWIDTH) - resize(zREG srl 2, DATAWIDTH);
           
end architecture ; 
