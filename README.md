# FPGA_xc7k420t_acceleration_fastqz
  This is the Vivado project of acceleration of FASTQZ gene sequencing data compression algorithm using Xilinx FPGA xc7k420t. 
    
  This accelerator uses PCIe x4 for transmitting data between FPGA and PC. The hardware fastqz computation core operating under 203MHz clock. The wns and tns of this design is -0.1ns and -28.761ns.  
    
  The accelerator can reach an averge compression ratio lower than 20% on ".fastq" file with the computing speed being 1.42 times as fast as software FASTQZ tool.  
    
  I create two computation channel for accelerator in this project (more channel mean faster computing speed). Calculated by resources utilazation, up to 20 computation channel can be implemented on VU9P FPGA card, which means 10 times the speed compared to the current Project.  
    
  The hardware implementation of fastqz has been packaged into IP and put them into "ip_repo" directory.   
  
# Recreate Vivado Project
  The whole design is implemented into Vivado block design. After adding the ip in the "ip_repo" directory, you can source the "RecreateProject.tcl" file in Vivado to recreate the whole project.  
# Software
  The software of this accelerator another repository "xk7c420t_fastqz_fxa_dual_channel".  
    
  The software is used to control FPGA card through PCIe and transmission of data.  
# Algorithm
  The gene sequencing data algorithm FASTQZ website is:
  http://mattmahoney.net/dc/fastqz/
