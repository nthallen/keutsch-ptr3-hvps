# High Voltage Power Supply CMOD A7 Implementation
#
# clk, uart, reset are handled by board definition
#
# FAIL to led[0]
# scl_mon  to PMOD.3 N18 -- NOT
# sda_mon  to PMOD.4 L18 -- NOT
# hvps_scl to PMOD.9 J19
# hvps_sda to PMOD.10 K18

set_property -dict {PACKAGE_PIN A17 IOSTANDARD LVCMOS33} [get_ports Fail]
# set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports scl_mon]
# set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports sda_mon]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD LVCMOS33 PULLUP true} [get_ports hvps_scl]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33 PULLUP true} [get_ports hvps_sda]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
