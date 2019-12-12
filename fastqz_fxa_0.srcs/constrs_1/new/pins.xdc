#Clock signal
create_clock -period 10.000 -name sys_clk_pin -add [get_ports clk_100M]

# Clock Pin, 100MHz input
set_property PACKAGE_PIN U24 [get_ports clk_100M]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100M]


#PCIe Pins
set_property PACKAGE_PIN AD6 [get_ports pciefer_clk_clk_p]

set_property PACKAGE_PIN W21 [get_ports pcie_rst_n]
set_property IOSTANDARD LVCMOS33 [get_ports pcie_rst_n]

set_property PACKAGE_PIN AH10 [get_ports {pcie_mgt_rxp[7]}]
set_property PACKAGE_PIN AG12 [get_ports {pcie_mgt_rxp[6]}]
set_property PACKAGE_PIN AF10 [get_ports {pcie_mgt_rxp[5]}]
set_property PACKAGE_PIN AE12 [get_ports {pcie_mgt_rxp[4]}]
set_property PACKAGE_PIN AH6 [get_ports {pcie_mgt_rxp[3]}]
set_property PACKAGE_PIN AG4 [get_ports {pcie_mgt_rxp[2]}]
set_property PACKAGE_PIN AE4 [get_ports {pcie_mgt_rxp[1]}]
set_property PACKAGE_PIN AC4 [get_ports {pcie_mgt_rxp[0]}]


set_property PACKAGE_PIN AJ12 [get_ports {pcie_mgt_txp[7]}]
set_property PACKAGE_PIN AK10 [get_ports {pcie_mgt_txp[6]}]
set_property PACKAGE_PIN AJ8 [get_ports {pcie_mgt_txp[5]}]
set_property PACKAGE_PIN AG8 [get_ports {pcie_mgt_txp[4]}]
set_property PACKAGE_PIN AK6 [get_ports {pcie_mgt_txp[3]}]
set_property PACKAGE_PIN AJ4 [get_ports {pcie_mgt_txp[2]}]
set_property PACKAGE_PIN AK2 [get_ports {pcie_mgt_txp[1]}]
set_property PACKAGE_PIN AH2 [get_ports {pcie_mgt_txp[0]}]

#LED's Pins
set_property PACKAGE_PIN AC19 [get_ports {led[4]}];          #d13
set_property PACKAGE_PIN AC20 [get_ports {led[3]}];          #d12
set_property PACKAGE_PIN E24 [get_ports {led[2]}];          #d4
set_property PACKAGE_PIN A27 [get_ports {led[1]}];           #d3
set_property PACKAGE_PIN AE20 [get_ports {led[0]}];          #d11

set_property IOSTANDARD LVCMOS15 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[0]}]