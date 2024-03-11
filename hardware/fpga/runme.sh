#!/bin/bash

echo "Building IPs..."
make ips
echo "Copying IPs..."
cp -r /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/tcl/ips/rom_ot/xilinx_rom_bank_8192x40.gen /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/xilinx_rom_bank_8192x40.gen
cp -r /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/tcl/ips/qspi/xilinx_qspi.gen /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/xilinx_qspi.gen
cp -r /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/tcl/ips/otp_ot/xilinx_rom_bank_1024x22.gen /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/xilinx_rom_bank_1024x22.gen
cp -r /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/tcl/ips/ddr/ddr4_0.gen /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/ddr4_0.gen
cp -r /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/tcl/ips/clk_mngr/xilinx_clk_mngr.gen /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/xilinx_clk_mngr.gen
cp -r /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/tcl/ips/boot_rom/xilinx_rom_bank_1024x64.gen /home/d3boker1/Build/he-soc/hardware/fpga/alsaqr/xilinx_rom_bank_1024x64.gen
echo "Gennerating Al Saqr..."
make clean run