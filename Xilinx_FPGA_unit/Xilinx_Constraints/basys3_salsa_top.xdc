##########
# Clocks #
##########

# The clock set on the board - 100MHz

create_clock -period 10.000 -name salsa_top_100mhz_clk -waveform {0.000 5.000} [get_ports salsa_top_100mhz_clk]

# The clock after PLL - 80MHz

create_generated_clock -name salsa_top_80mhz_pll_clk -source [get_ports salsa_top_100mhz_clk] -divide_by 5 -multiply_by 4 [get_pins salsa_top_xilinix_ip_pll/clk_out1]


###############
# Input Delay #
###############
set_input_delay -clock salsa_top_80mhz_pll_clk -add_delay 0.000 [get_ports {salsa_top_rst_n rs232_rx_top}]


################
# Output Delay #
################
set_output_delay -clock salsa_top_80mhz_pll_clk -add_delay 0.000 [get_ports {rs_232_tx_top hash_done_sticky_top xor_valid_sticky_top salsa_top_pll_locked}]

set_output_delay -clock salsa_top_80mhz_pll_clk -add_delay 0.000 [get_ports {anode_set_top* dp_set_top seven_seg_top*}]

##############################
# Pin Locations and Voltages #
##############################

# clk
set_property -dict {PACKAGE_PIN W5 IOSTANDARD LVCMOS33} [get_ports salsa_top_100mhz_clk]

# rst_n active low rst - switch --> SW15 (R2)
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports salsa_top_rst_n]

# rx
set_property -dict {PACKAGE_PIN B18 IOSTANDARD LVCMOS33} [get_ports rs232_rx_top]

# tx
set_property -dict {PACKAGE_PIN A18 IOSTANDARD LVCMOS33} [get_ports rs_232_tx_top]

# sticky signals - LED (LD0 & LD1)
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports hash_done_sticky_top]
set_property -dict {PACKAGE_PIN E19 IOSTANDARD LVCMOS33} [get_ports xor_valid_sticky_top]

# pll locked signal - LED (LD2)
set_property -dict {PACKAGE_PIN U19 IOSTANDARD LVCMOS33} [get_ports salsa_top_pll_locked]

############ SSD ########
# Anode
set_property -dict {PACKAGE_PIN U2 IOSTANDARD LVCMOS33} [get_ports {anode_set_top[0]}]
set_property -dict {PACKAGE_PIN U4 IOSTANDARD LVCMOS33} [get_ports {anode_set_top[1]}]
set_property -dict {PACKAGE_PIN V2 IOSTANDARD LVCMOS33} [get_ports {anode_set_top[2]}]
set_property -dict {PACKAGE_PIN W4 IOSTANDARD LVCMOS33} [get_ports {anode_set_top[3]}]

# DP
set_property -dict {PACKAGE_PIN V7 IOSTANDARD LVCMOS33} [get_ports dp_set_top]

# 7 Segment
set_property -dict {PACKAGE_PIN W7 IOSTANDARD LVCMOS33} [get_ports {seven_seg_top[0]}]
set_property -dict {PACKAGE_PIN W6 IOSTANDARD LVCMOS33} [get_ports {seven_seg_top[1]}]
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS33} [get_ports {seven_seg_top[2]}]
set_property -dict {PACKAGE_PIN V8 IOSTANDARD LVCMOS33} [get_ports {seven_seg_top[3]}]
set_property -dict {PACKAGE_PIN U5 IOSTANDARD LVCMOS33} [get_ports {seven_seg_top[4]}]
set_property -dict {PACKAGE_PIN V5 IOSTANDARD LVCMOS33} [get_ports {seven_seg_top[5]}]
set_property -dict {PACKAGE_PIN U7 IOSTANDARD LVCMOS33} [get_ports {seven_seg_top[6]}]

##########################
# Configuration Settings #
##########################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

