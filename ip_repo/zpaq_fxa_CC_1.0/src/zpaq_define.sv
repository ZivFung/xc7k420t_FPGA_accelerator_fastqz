`ifndef __DEFINES_SV__
`define __DEFINES_SV__


package ZPAQDefines;

parameter integer ZPAQ_INPUT_DW = 8;
parameter integer ZPAQ_Prob_DW = 32; 
parameter integer ZPAQ_Enc_In_DW = 1;
parameter integer ZPAQ_CM_TW = 20;
parameter integer ZPAQ_CM_COUNT_LIMIT = 1020;
parameter integer ZPAQ_CM_DW = 32;
parameter integer ZPAQ_COUNT_DT_LEN = 1024;
parameter integer ZPAQ_COUNT_DT_DW = 32;
parameter integer ZPAQ_CM_LOOKUP_CHANNEL_NUM = 8;
parameter integer ZPAQ_H0_DW = 32;
parameter integer ZPAQ_Compress_Channel_NUM = 1;


parameter integer AxiMasterAruser_W = 2;
parameter integer AxiMasterAwuser_W = 2;

parameter integer ZPAQ_FIFO_LENW = 6;
parameter integer ZPAQ_BURST_LEN = 64;

//parameter ZPAQ_INPUT_DW = 8;
//parameter ZPAQ_Prob_DW = 32;
//parameter ZPAQ_Enc_In_DW = 1;
//parameter ZPAQ_CM_TW = 20;
//parameter ZPAQ_CM_COUNT_LIMIT = 1020;
//parameter ZPAQ_CM_DW = 32;
//parameter ZPAQ_COUNT_DT_LEN = 1024;
//parameter ZPAQ_COUNT_DT_DW = 32;
//parameter ZPAQ_CM_LOOKUP_CHANNEL_NUM = 8;
//parameter ZPAQ_H0_DW = 32;
//parameter ZPAQ_Compress_Channel_NUM = 1;

endpackage 
interface Axi4LiteIf #( parameter AW = 32, DW = 32)(
    input wire clk, reset_n
);
    logic [AW-1:0] awaddr;
    logic [2:0] awprot;
    logic awvalid, awready;
    logic [DW-1:0] wdata;
    logic [DW/8-1:0] wstrb;
    logic wvalid, wready;
    logic [1:0] bresp;
    logic bvalid, bready;
    logic [AW-1:0] araddr;
    logic [2:0] arprot;
    logic arvalid, arready;
    logic [DW-1:0] rdata;
    logic [1:0] rresp;
    logic rvalid, rready;
    modport master(
        input clk, reset_n,
        output awaddr, awprot, awvalid, input awready,
        output wdata, wstrb, wvalid, input wready,
        input bresp, bvalid, output bready,
        output araddr, arprot, arvalid, input arready,
        input rdata, rresp, rvalid, output rready
    );
    modport slave(
        input clk, reset_n,
        input awaddr, awprot, awvalid, output awready,
        input wdata, wstrb, wvalid, output wready,
        output bresp, bvalid, input bready,
        input araddr, arprot, arvalid, output arready,
        output rdata, rresp, rvalid, input rready
    );
//    task Write(
//        input logic [AW-1:0] addr, logic [31:0] data,
//        logic [31:0] strb = '1, logic [2:0] prot = '0
//    );
//        @(posedge clk) begin
//            awaddr = addr; awprot = prot; awvalid = '1;
//            wdata = data; wstrb = strb; wvalid = '1;
//            bready = '1;
//        end
//        fork
//            wait(awready) @(posedge clk) awvalid = '0;
//            wait(wready) @(posedge clk) wvalid = '0;
//            wait(bvalid) @(posedge clk) bready = '0;
//        join
//    endtask
//    task Read(
//        input logic [AW-1:0] addr, output logic [31:0] data,
//        input logic [3:0] prot = '0
//    );
//        @(posedge clk) begin
//            araddr = addr; arprot = prot; arvalid = '1;
//            rready = '1;
//        end
//        wait(arready) @(posedge clk) arvalid = '0;
//        wait(rvalid) @(posedge clk) begin
//            rready = '0;
//            data = rdata;
//        end
//    endtask
endinterface

interface Axi4StreamIf #(
    parameter DW_BYTES = 4
)(
    input wire clk, reset_n
);
    localparam DW = DW_BYTES * 8;
    logic [DW - 1 : 0] tdata;
    logic tvalid, tready, tlast;
    logic [DW_BYTES - 1 : 0] tstrb, tkeep;

    modport master(
        input   clk, reset_n, tready,
        output  tdata, tvalid, tlast, tstrb, tkeep
    );
    modport slave(
        input   clk, reset_n, tdata, tvalid, tlast,
                tstrb, tkeep,
        output  tready
    );
    // task static Put(logic [31:0] data, logic last);
    // begin
    //     tdata <= data; tlast <= last;
    //     tvalid <= '1;
    //     do @(posedge clk);
    //     while(~tready);
    //     tvalid <= '0;
    // end
    // endtask
    // task static Get();
    // begin
    //     tready <= '1;
    //     do @(posedge clk);
    //     while(~tvalid);
    //     tready <= '0;
    // end
    // endtask
endinterface

interface Axi4FullIf #(
  parameter AW = 32, DW_Byte = 4,
  parameter ID_W = 2,AruserW = 8,AwuserW = 8,RuserW = 8,WuserW = 8, BuserW = 8
)(
  input wire clk, reset_n
);
    localparam DW = DW_Byte*8;
    /************Write*************/
    logic [ID_W-1:0]awid;
    logic [7:0]awlen;
    logic [2:0]awsize;
    logic [1:0]awburst;
    logic [3:0]awcache;
    logic [1:0]awlock;
    logic [3:0]awqos;
    logic [3:0]awregion;
    logic [AwuserW-1:0]awuser;
    logic [AW-1:0] awaddr;
    logic [2:0] awprot;
    
    logic [ID_W-1:0]wid;
    logic awvalid, awready;
    logic [WuserW-1:0]wuser;
    logic [DW-1:0] wdata;
    logic [DW/8-1:0] wstrb;
    logic wvalid, wready;
    logic wlast;
    /************Response*************/
    logic [BuserW-1:0]buser;
    logic [ID_W-1:0]bid;
    logic [1:0] bresp;
    logic bvalid, bready;
    /************Read*************/
    logic [ID_W-1:0]arid;
    logic [AW-1:0] araddr;
    logic [7:0] arlen;
    logic [2:0] arsize;
    logic [1:0] arburst;
    logic [AruserW-1:0] aruser;
    logic [3:0] arcache;
    logic [1:0] arlock;
    logic [2:0] arprot;
    logic [3:0] arqos;
    logic [3:0] arregion;
    logic arvalid, arready;
    
    logic [ID_W-1:0]rid;
    logic [RuserW-1:0]ruser;
    logic [DW-1:0] rdata;
    logic [1:0] rresp;
    logic rvalid, rready;
    logic rlast;
    
    modport master_rd(
        input clk, reset_n,
        
        output arid, araddr, arprot, arvalid, arlen, arsize, arburst, arcache, arlock, arqos,
               arregion, aruser, input arready,
        
        input rid, rdata, rresp, rvalid, rlast, output rready
    );
    modport master_wr(
        input clk, reset_n,
        
        output awid, awaddr, awprot, awvalid, awlen, awsize, awburst, awcache, awlock, awqos,
               awregion, awuser,input awready,
               
        output wuser, wdata, wstrb, wvalid, wid, wlast, input wready,
        input buser, bid, bresp, bvalid, output bready
    );
    modport slave_wr(
        input clk, reset_n,
        input awid, awaddr, awprot, awvalid, awlen, awsize, awburst, awcache, awlock, awqos,
               awregion, awuser,output awready,
        
        input wuser, wdata, wstrb, wvalid, wid, wlast, output wready,
        output buser, bid, bresp, bvalid, input bready
    );
    modport slave_rd(   
        input clk, reset_n, 
        input arid, araddr, arprot, arvalid, arlen, arsize, arburst, arcache, arlock, arqos,
               arregion, aruser, output arready,
        
        output ruser, rid, rdata, rresp, rvalid, rlast, input rready
    );

endinterface


`endif
