library ieee ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all ;
use work.CORDICPackage.all;
use std.textio.all;

entity GENCORDIC_TB is
    generic(
        numOfTestVals : natural range 0 to 32 := 2
           );

end GENCORDIC_TB ; 

architecture arch of GENCORDIC_TB is
    constant TB_DATAWIDTH : NATURAL range 4 to 32 := 16;
    constant DATAWIDTH : natural range 4 to 32 := TB_DATAWIDTH;
    signal CLK_TB : std_logic := '0';
    signal X_IN_TB : signed(DATAWIDTH-1 downto 0) := (others => '0');
    signal Y_IN_TB : signed(DATAWIDTH-1 downto 0) := (others => '0');
    signal Z_IN_TB : signed(DATAWIDTH-1 downto 0) := (others => '0');
    signal X_OUT_TB : signed(DATAWIDTH-1 downto 0) := (others => '0');
    signal Y_OUT_TB : signed(DATAWIDTH-1 downto 0) := (others => '0');
    signal Z_OUT_TB : signed(DATAWIDTH-1 downto 0) := (others => '0');
    signal MU_TB : std_logic_vector(1 downto 0) := "00";
    signal MODE_TB : std_logic := '0';
    signal ITERATIONS_TB : natural range 0 to DATAWIDTH := TB_DATAWIDTH;
    signal RESET_TB : std_logic := '0';
    signal START_TB : std_logic := '0';
    signal BUSY_TB : std_logic := '0';
    signal CORDICLatency : natural := 0;
----------------------------------------------------------------------------------
-- test values
----------------------------------------------------------------------------------
    TYPE DATAARR is ARRAY (0 to numOfTestVals-1) of signed(DATAWIDTH-1 downto 0);
    signal X_RES : signed(DATAWIDTH-1 downto 0);
    signal Y_RES : signed(DATAWIDTH-1 downto 0);
    signal Z_RES : signed(DATAWIDTH-1 downto 0);
    TYPE MODEARR_T is ARRAY (0 to numOfTestVals-1) of bit;
    TYPE MUARR_T is ARRAY (0 to numOfTestVals-1) of bit_vector(1 downto 0);
    signal MUARR : MUARR_T := ("00", "01");
    signal MODEARR : MODEARR_T := ('0', '1');
    signal testCNT : integer range 0 to numOfTestVals := 0;
    signal TB_OK : bit := '1';
    constant residuum : signed(DATAWIDTH-1 downto 0) := X"00_08";
    constant residuumHyperbolic : signed(DATAWIDTH-1 downto 0) := X"00_C6";
    constant residuumATAN : signed(DATAWIDTH-1 downto 0) := X"00_09";
    --constant residuum : signed(DATAWIDTH-1 downto 0) := X"00_00_00_84";
    --constant residuumHyperbolic : signed(DATAWIDTH-1 downto 0) := X"00_82_00_00";
    --constant residuumATAN : signed(DATAWIDTH-1 downto 0) := X"00_00_00_C0";
    signal resSigX : signed(DATAWIDTH-1 downto 0);
    signal resSigY : signed(DATAWIDTH-1 downto 0);
    signal resSigZ : signed(DATAWIDTH-1 downto 0);
    signal testCaseCNT : integer range 0 to 6 := 0;
    file file_VECTORS : text open read_mode is "TestVectors/testVectors.txt";
begin
    
    DUT1 : entity work.GENCORDIC 
    generic map(
        DATAWIDTH => TB_DATAWIDTH
    )
    port map(
        CLK => CLK_TB,
        X_IN => X_IN_TB,
        Y_IN => Y_IN_TB,
        Z_IN => Z_IN_TB,
        MU => MU_TB,
        MODE => MODE_TB,
        ITERATIONS => ITERATIONS_TB,
        RESET => RESET_TB,
        START => START_TB,
        BUSY => BUSY_TB,
        X_OUT => X_OUT_TB,
        Y_OUT => Y_OUT_TB,
        Z_OUT => Z_OUT_TB
    );

    CLOCKGEN : process 
    begin
        wait for 2 ns;
        CLK_TB <= '1';
        wait for 2 ns;
        CLK_TB <= '0';
    end process;

    STIMGEN : process
        variable diffX : signed(DATAWIDTH-1 downto 0);
        variable diffY : signed(DATAWIDTH-1 downto 0);
        variable diffZ : signed(DATAWIDTH-1 downto 0);
        variable v_line : line;
        variable v_xin, v_yin, v_zin : integer;
        variable v_xout, v_yout, v_zout : integer;
        variable v_mu   : std_logic_vector(1 downto 0);
        variable v_mode : std_logic;
    begin
        wait for 100 ns;
        while not endfile(file_VECTORS) loop
            readline(file_VECTORS, v_line);            
            if v_line.all'length = 0 then
                next;
            end if;
            
            read(v_line, v_mu);
            read(v_line, v_mode);
            read(v_line, v_xin);
            read(v_line, v_yin);
            read(v_line, v_zin);
            read(v_line, v_xout);
            read(v_line, v_yout);
            read(v_line, v_zout);

            X_IN_TB <= to_signed(v_xin, DATAWIDTH);
            Y_IN_TB <= to_signed(v_yin, DATAWIDTH);
            Z_IN_TB <= to_signed(v_zin, DATAWIDTH);
            
            X_RES <= to_signed(v_xout, DATAWIDTH);
            Y_RES <= to_signed(v_yout, DATAWIDTH);
            Z_RES <= to_signed(v_zout, DATAWIDTH);
            
            MU_TB <= v_mu;
            MODE_TB <= v_mode;
            
            wait for 20 ns;
            START_TB <= '1';     
            wait until BUSY_TB = '1';
            START_TB <= '0';
            wait until BUSY_TB = '0';
            wait for 1 ns;
            diffX := abs(X_OUT_TB - X_RES);
            diffY := abs(Y_OUT_TB - Y_RES);
            diffZ := abs(Z_OUT_TB - Z_RES);
            resSigX <= diffX;
            resSigY <= diffY;
            resSigZ <= diffZ;
            if (MU_TB /= "11") then
                if (MODE_TB = '1' and MU_TB = "01") then
                    diffZ := abs(Z_OUT_TB - (Z_RES));
                    if (diffX <= residuumATAN) and (diffY <= residuumATAN) and (diffZ <= residuumATAN) then
                        TB_OK <= '1';
                    else
                        TB_OK <= '0';
                    end if;
                    assert (diffX <= residuumATAN) report "Error in xREG!" severity ERROR;
                    assert (diffY <= residuumATAN) report "Error in yREG!" severity ERROR;
                    assert (diffZ <= residuumATAN) report "Error in zREG!" severity ERROR;
                else
                    if (diffX <= residuum) and (diffY <= residuum) and (diffZ <= residuum) then
                        TB_OK <= '1';
                    else
                        TB_OK <= '0';
                    end if;
                    assert (diffX <= residuum) report "Error in xREG!" severity ERROR;
                    assert (diffY <= residuum) report "Error in yREG!" severity ERROR;
                    assert (diffZ <= residuum) report "Error in zREG!" severity ERROR;
                end if;
            else 
                if (diffX <= residuumHyperbolic) and (diffY <= residuumHyperbolic) and (diffZ <= residuumHyperbolic) then
                    TB_OK <= '1';
                else
                    TB_OK <= '0';
                end if;
                assert (diffX <= residuumHyperbolic) report "Error in xREG!" severity ERROR;
                assert (diffY <= residuumHyperbolic) report "Error in yREG!" severity ERROR;
                assert (diffZ <= residuumHyperbolic) report "Error in zREG!" severity ERROR;
            end if;
            wait for 250 ns; 
        end loop;
    end process;

    CLOCKCNT : process(CLK_TB)
    begin 
        if (rising_edge(CLK_TB)) then
            if (BUSY_TB = '1') then
                CORDICLatency <= CORDICLatency+1;
            else
                CORDICLatency <= 0;
            end if;
        end if;
    end process;

end architecture ;
