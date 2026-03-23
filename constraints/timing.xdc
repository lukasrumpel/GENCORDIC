
create_clock -period 4.000 -name sys_clk [get_ports CLK]
set_clock_uncertainty 0.050 [get_clocks clk]

set_input_delay -clock [get_clocks sys_clk] 0.800 [get_ports {X_IN* Y_IN* Z_IN* START RESET MODE MU*}]
set_output_delay -clock [get_clocks sys_clk] 0.800 [get_ports {X_OUT* Y_OUT* Z_OUT* BUSY}]

set_max_delay -from [get_cells xREG_reg*] -to [get_cells XN_reg*] 4.000
set_max_delay -from [get_cells yREG_reg*] -to [get_cells YN_reg*] 4.000
set_max_delay -from [get_cells zREG_reg*] -to [get_cells ZN_reg*] 4.000
