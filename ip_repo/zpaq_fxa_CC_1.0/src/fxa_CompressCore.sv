`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/21/2019 10:09:48 PM
// Design Name: 
// Module Name: fxa_CompressCore
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fxa_CompressCore #
	(
		// Users to add parameters here
        /* ZPAQ PARAMETER*/
        parameter integer CM_TW = 20,
        parameter integer CM_COUNT_LIMIT = 1020,
        parameter integer CMTable_BaseAddr = 32'h8000_0000,
        /* Other PARAMETER*/
        parameter integer NumberPerBlock = 4096,
		// User parameters ends
		// Do not modify the parameters beyond this line


		// Parameters of Axi Master Bus Interface M00_AXI
//		parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h40000000,
//		parameter integer C_M00_AXI_BURST_LEN	= 16,
		parameter integer C_M00_AXI_ID_WIDTH	= 1,
		parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
		parameter integer C_M00_AXI_DATA_WIDTH	= 64,
		parameter integer C_M00_AXI_AWUSER_WIDTH	= 0,
		parameter integer C_M00_AXI_ARUSER_WIDTH	= 0,
		parameter integer C_M00_AXI_WUSER_WIDTH	= 0,
		parameter integer C_M00_AXI_RUSER_WIDTH	= 0,
		parameter integer C_M00_AXI_BUSER_WIDTH	= 0,

		// Parameters of Axi Slave Bus Interface S00_AXIS
		parameter integer C_AXIS_TDATA_WIDTH	= 8

		// Parameters of Axi Master Bus Interface M00_AXIS
//		parameter integer C_M00_AXIS_TDATA_WIDTH	= 32
//		parameter integer C_M00_AXIS_START_COUNT	= 32
	)
	(
		// Users to add ports here
        input wire Start,
        output wire ByteFinish,
        input wire FBFlag,
        input wire [31:0]FBCount,
        output wire tableInitFinish,
        output wire [31 : 0]EncLow,EncHigh,EncMid,
        output wire FileFinish,
        
		input wire  aclk,
		input wire  aresetn,
		output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_awid,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
		output wire [7 : 0] m00_axi_awlen,
		output wire [2 : 0] m00_axi_awsize,
		output wire [1 : 0] m00_axi_awburst,
		output wire  m00_axi_awlock,
		output wire [3 : 0] m00_axi_awcache,
		output wire [2 : 0] m00_axi_awprot,
		output wire [3 : 0] m00_axi_awqos,
		output wire [C_M00_AXI_AWUSER_WIDTH-1 : 0] m00_axi_awuser,
		output wire  m00_axi_awvalid,
		input wire  m00_axi_awready,
		output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
		output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
		output wire  m00_axi_wlast,
		output wire [C_M00_AXI_WUSER_WIDTH-1 : 0] m00_axi_wuser,
		output wire  m00_axi_wvalid,
		input wire  m00_axi_wready,
		input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_bid,
		input wire [1 : 0] m00_axi_bresp,
		input wire [C_M00_AXI_BUSER_WIDTH-1 : 0] m00_axi_buser,
		input wire  m00_axi_bvalid,
		output wire  m00_axi_bready,
		output wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_arid,
		output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
		output wire [7 : 0] m00_axi_arlen,
		output wire [2 : 0] m00_axi_arsize,
		output wire [1 : 0] m00_axi_arburst,
		output wire  m00_axi_arlock,
		output wire [3 : 0] m00_axi_arcache,
		output wire [2 : 0] m00_axi_arprot,
		output wire [3 : 0] m00_axi_arqos,
		output wire [C_M00_AXI_ARUSER_WIDTH-1 : 0] m00_axi_aruser,
		output wire  m00_axi_arvalid,
		input wire  m00_axi_arready,
		input wire [C_M00_AXI_ID_WIDTH-1 : 0] m00_axi_rid,
		input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
		input wire [1 : 0] m00_axi_rresp,
		input wire  m00_axi_rlast,
		input wire [C_M00_AXI_RUSER_WIDTH-1 : 0] m00_axi_ruser,
		input wire  m00_axi_rvalid,
		output wire  m00_axi_rready,

		(*mark_debug = "true"*)output wire  s00_axis_tready,
		(*mark_debug = "true"*)input wire [C_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
		(*mark_debug = "true"*)input wire  s00_axis_tlast,
		(*mark_debug = "true"*)input wire  s00_axis_tvalid,

		output wire  m00_axis_tvalid,
		output wire [C_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready
	);


	// Add user logic here
    Axi4StreamIf #(C_AXIS_TDATA_WIDTH/8) testAxis_master(.clk(aclk), .reset_n(aresetn));
    Axi4StreamIf #(C_AXIS_TDATA_WIDTH/8) testAxis_slave(.clk(aclk), .reset_n(aresetn));
    Axi4FullIf #(C_M00_AXI_ADDR_WIDTH,C_M00_AXI_DATA_WIDTH/8,C_M00_AXI_ID_WIDTH,
    C_M00_AXI_ARUSER_WIDTH,C_M00_AXI_AWUSER_WIDTH,C_M00_AXI_RUSER_WIDTH,C_M00_AXI_WUSER_WIDTH,C_M00_AXI_BUSER_WIDTH)
    testAxi(.clk(aclk), .reset_n(aresetn));	
	
	
    CompressCore#(
      .AXIS_DW(C_AXIS_TDATA_WIDTH),
      /* ZPAQ PARAMETER*/
      .CM_TW(CM_TW),
      .CM_COUNT_LIMIT(CM_COUNT_LIMIT),
      .CMTable_BaseAddr(CMTable_BaseAddr),
      /* Other PARAMETER*/
      .NumberPerBlock(NumberPerBlock),
      /* AXI_FULL PARAMETER*/
      .AXI_DWByte(C_M00_AXI_DATA_WIDTH/8),
      .AXI_IDW(C_M00_AXI_ID_WIDTH),
      .AXI_AW(C_M00_AXI_ADDR_WIDTH),
      .AXI_AWUSER(C_M00_AXI_AWUSER_WIDTH),
      .AXI_ARUSER(C_M00_AXI_ARUSER_WIDTH),
      .AXI_WUSER(C_M00_AXI_WUSER_WIDTH),
      .AXI_RUSER(C_M00_AXI_RUSER_WIDTH),
      .AXI_BUSER(C_M00_AXI_BUSER_WIDTH)
    )CompressCore(
      .start(Start),
      .FBFlag(FBFlag),
      .FBCount(FBCount),
      .CompressIn(testAxis_slave.slave),
      .CompressOut(testAxis_master.master),
      .DDRWrite(testAxi.master_wr),
      .DDRRead(testAxi.master_rd),
      .ByteFinish(ByteFinish),
      .tableInitFinish(tableInitFinish),
      .EncLow(EncLow),
      .EncHigh(EncHigh),
      .EncMid(EncMid),
      .FileFinish(FileFinish)
    );

    /*AXI_Stream*/
    assign testAxis_slave.tdata = s00_axis_tdata;
    assign testAxis_slave.tvalid = s00_axis_tvalid & (~FileFinish);
    assign testAxis_master.tready = m00_axis_tready;
    assign s00_axis_tready = testAxis_slave.tready & (~FileFinish);
    assign m00_axis_tvalid = testAxis_master.tvalid;
    assign m00_axis_tdata = testAxis_master.tdata;
    assign testAxis_slave.tlast = s00_axis_tlast; 
    assign m00_axis_tlast = testAxis_master.tlast;

    /*AXI_Full*/
	assign m00_axi_awid = testAxi.awid,
    m00_axi_awaddr = testAxi.awaddr,
    m00_axi_awlen = testAxi.awlen,   
    m00_axi_awsize = testAxi.awsize,
    m00_axi_awburst = testAxi.awburst,
    m00_axi_awlock = testAxi.awlock,
    m00_axi_awcache = testAxi.awcache,
    m00_axi_awprot = testAxi.awprot,
    m00_axi_awqos = testAxi.awqos,
    m00_axi_awuser = testAxi.awuser,
    m00_axi_awvalid = testAxi.awvalid;
    assign testAxi.awready = m00_axi_awready;
    assign m00_axi_wdata = testAxi.wdata,
    m00_axi_wstrb = testAxi.wstrb,
    m00_axi_wlast = testAxi.wlast,
    m00_axi_wuser = testAxi.wuser,
    m00_axi_wvalid = testAxi.wvalid;
    assign testAxi.wready = m00_axi_wready,
    testAxi.bid = m00_axi_bid,
    testAxi.bresp = m00_axi_bresp,
    testAxi.buser = m00_axi_buser,
    testAxi.bvalid = m00_axi_bvalid;
    assign m00_axi_bready = testAxi.bready,
    m00_axi_arid  = testAxi.arid, 
    m00_axi_araddr = testAxi.araddr,
    m00_axi_arlen = testAxi.arlen,
    m00_axi_arsize = testAxi.arsize,
    m00_axi_arburst = testAxi.arburst,
    m00_axi_arlock = testAxi.arlock,
    m00_axi_arcache = testAxi.arcache,
    m00_axi_arprot = testAxi.arprot,
    m00_axi_arqos = testAxi.arqos,
    m00_axi_aruser = testAxi.aruser,
    m00_axi_arvalid = testAxi.arvalid;
    assign testAxi.arready = m00_axi_arready,
    testAxi.rid = m00_axi_rid,
    testAxi.rdata = m00_axi_rdata,
    testAxi.rresp = m00_axi_rresp,
    testAxi.rlast = m00_axi_rlast,
    testAxi.ruser = m00_axi_ruser,
    testAxi.rvalid = m00_axi_rvalid;
    assign m00_axi_rready = testAxi.rready;
	// User logic ends


endmodule
