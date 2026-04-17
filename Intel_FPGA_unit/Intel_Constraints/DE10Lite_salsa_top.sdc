##########
# Clocks #
##########

# The clock set on the board - 50MHz
create_clock -name {salsa_top_50mhz_clk} -period "20.000" [get_ports salsa_top_50mhz_clk]

# uncertainty
derive_clock_uncertainty

###############
# Input Delay #
###############
set_input_delay -clock {salsa_top_50mhz_clk} -max 0.000 [get_ports {salsa_top_rst_n rs232_rx_top}]
set_input_delay -clock {salsa_top_50mhz_clk} -min 0.000 [get_ports {salsa_top_rst_n rs232_rx_top}]

################
# Output Delay #
################
set_output_delay -clock {salsa_top_50mhz_clk} -max 0.000 [get_ports {rs_232_tx_top hash_done_sticky_top xor_valid_sticky_top}]
set_output_delay -clock {salsa_top_50mhz_clk} -min 0.000 [get_ports {rs_232_tx_top hash_done_sticky_top xor_valid_sticky_top}]

set_output_delay -clock {salsa_top_50mhz_clk} -max 0.000 [get_ports {dp_set_top seven_seg_top*}]
set_output_delay -clock {salsa_top_50mhz_clk} -min 0.000 [get_ports {dp_set_top seven_seg_top*}]