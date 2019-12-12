
`timescale 1 ns / 1 ps

	module zpaq_fxa_CC_v1_0 #
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
        output wire CMInitFinish,
        output wire [31 : 0]EncLow,EncHigh,EncMid,
        output wire FileFinish,
		// User ports ends
		// Do not modify the ports beyond this line


		// Ports of Axi Master Bus Interface M00_AXI
//		input wire  m00_axi_init_axi_txn,
//		output wire  m00_axi_txn_done,
//		output wire  m00_axi_error,
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

		// Ports of Axi Slave Bus Interface S00_AXIS
//		input wire  s00_axis_aclk,
//		input wire  s00_axis_aresetn,
		output wire  s00_axis_tready,
		input wire [C_AXIS_TDATA_WIDTH-1 : 0] s00_axis_tdata,
//		input wire [(C_S00_AXIS_TDATA_WIDTH/8)-1 : 0] s00_axis_tstrb,
		input wire  s00_axis_tlast,
		input wire  s00_axis_tvalid,

		// Ports of Axi Master Bus Interface M00_AXIS
//		input wire  m00_axis_aclk,
//		input wire  m00_axis_aresetn,
		output wire  m00_axis_tvalid,
		output wire [C_AXIS_TDATA_WIDTH-1 : 0] m00_axis_tdata,
//		output wire [(C_M00_AXIS_TDATA_WIDTH/8)-1 : 0] m00_axis_tstrb,
		output wire  m00_axis_tlast,
		input wire  m00_axis_tready
	);
//// Instantiation of Axi Bus Interface M00_AXI
//	zpaq_fxa_CC_v1_0_M00_AXI # ( 
//		.C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
//		.C_M_AXI_BURST_LEN(C_M00_AXI_BURST_LEN),
//		.C_M_AXI_ID_WIDTH(C_M00_AXI_ID_WIDTH),
//		.C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
//		.C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
//		.C_M_AXI_AWUSER_WIDTH(C_M00_AXI_AWUSER_WIDTH),
//		.C_M_AXI_ARUSER_WIDTH(C_M00_AXI_ARUSER_WIDTH),
//		.C_M_AXI_WUSER_WIDTH(C_M00_AXI_WUSER_WIDTH),
//		.C_M_AXI_RUSER_WIDTH(C_M00_AXI_RUSER_WIDTH),
//		.C_M_AXI_BUSER_WIDTH(C_M00_AXI_BUSER_WIDTH)
//	) zpaq_fxa_CC_v1_0_M00_AXI_inst (
//		.INIT_AXI_TXN(m00_axi_init_axi_txn),
//		.TXN_DONE(m00_axi_txn_done),
//		.ERROR(m00_axi_error),
//		.M_AXI_ACLK(m00_axi_aclk),
//		.M_AXI_ARESETN(m00_axi_aresetn),
//		.M_AXI_AWID(m00_axi_awid),
//		.M_AXI_AWADDR(m00_axi_awaddr),
//		.M_AXI_AWLEN(m00_axi_awlen),
//		.M_AXI_AWSIZE(m00_axi_awsize),
//		.M_AXI_AWBURST(m00_axi_awburst),
//		.M_AXI_AWLOCK(m00_axi_awlock),
//		.M_AXI_AWCACHE(m00_axi_awcache),
//		.M_AXI_AWPROT(m00_axi_awprot),
//		.M_AXI_AWQOS(m00_axi_awqos),
//		.M_AXI_AWUSER(m00_axi_awuser),
//		.M_AXI_AWVALID(m00_axi_awvalid),
//		.M_AXI_AWREADY(m00_axi_awready),
//		.M_AXI_WDATA(m00_axi_wdata),
//		.M_AXI_WSTRB(m00_axi_wstrb),
//		.M_AXI_WLAST(m00_axi_wlast),
//		.M_AXI_WUSER(m00_axi_wuser),
//		.M_AXI_WVALID(m00_axi_wvalid),
//		.M_AXI_WREADY(m00_axi_wready),
//		.M_AXI_BID(m00_axi_bid),
//		.M_AXI_BRESP(m00_axi_bresp),
//		.M_AXI_BUSER(m00_axi_buser),
//		.M_AXI_BVALID(m00_axi_bvalid),
//		.M_AXI_BREADY(m00_axi_bready),
//		.M_AXI_ARID(m00_axi_arid),
//		.M_AXI_ARADDR(m00_axi_araddr),
//		.M_AXI_ARLEN(m00_axi_arlen),
//		.M_AXI_ARSIZE(m00_axi_arsize),
//		.M_AXI_ARBURST(m00_axi_arburst),
//		.M_AXI_ARLOCK(m00_axi_arlock),
//		.M_AXI_ARCACHE(m00_axi_arcache),
//		.M_AXI_ARPROT(m00_axi_arprot),
//		.M_AXI_ARQOS(m00_axi_arqos),
//		.M_AXI_ARUSER(m00_axi_aruser),
//		.M_AXI_ARVALID(m00_axi_arvalid),
//		.M_AXI_ARREADY(m00_axi_arready),
//		.M_AXI_RID(m00_axi_rid),
//		.M_AXI_RDATA(m00_axi_rdata),
//		.M_AXI_RRESP(m00_axi_rresp),
//		.M_AXI_RLAST(m00_axi_rlast),
//		.M_AXI_RUSER(m00_axi_ruser),
//		.M_AXI_RVALID(m00_axi_rvalid),
//		.M_AXI_RREADY(m00_axi_rready)
//	);

//// Instantiation of Axi Bus Interface S00_AXIS
//	zpaq_fxa_CC_v1_0_S00_AXIS # ( 
//		.C_S_AXIS_TDATA_WIDTH(C_S00_AXIS_TDATA_WIDTH)
//	) zpaq_fxa_CC_v1_0_S00_AXIS_inst (
//		.S_AXIS_ACLK(s00_axis_aclk),
//		.S_AXIS_ARESETN(s00_axis_aresetn),
//		.S_AXIS_TREADY(s00_axis_tready),
//		.S_AXIS_TDATA(s00_axis_tdata),
//		.S_AXIS_TSTRB(s00_axis_tstrb),
//		.S_AXIS_TLAST(s00_axis_tlast),
//		.S_AXIS_TVALID(s00_axis_tvalid)
//	);

//// Instantiation of Axi Bus Interface M00_AXIS
//	zpaq_fxa_CC_v1_0_M00_AXIS # ( 
//		.C_M_AXIS_TDATA_WIDTH(C_M00_AXIS_TDATA_WIDTH),
//		.C_M_START_COUNT(C_M00_AXIS_START_COUNT)
//	) zpaq_fxa_CC_v1_0_M00_AXIS_inst (
//		.M_AXIS_ACLK(m00_axis_aclk),
//		.M_AXIS_ARESETN(m00_axis_aresetn),
//		.M_AXIS_TVALID(m00_axis_tvalid),
//		.M_AXIS_TDATA(m00_axis_tdata),
//		.M_AXIS_TSTRB(m00_axis_tstrb),
//		.M_AXIS_TLAST(m00_axis_tlast),
//		.M_AXIS_TREADY(m00_axis_tready)
//	);

	// Add user logic here
fxa_CompressCore #
    (
        // Users to add parameters here
        /* ZPAQ PARAMETER*/
        .CM_TW(CM_TW),
        .CM_COUNT_LIMIT(CM_COUNT_LIMIT),
        .CMTable_BaseAddr(CMTable_BaseAddr),
        /* Other PARAMETER*/
        .NumberPerBlock(NumberPerBlock),
        // User parameters ends
        // Do not modify the parameters beyond this line


        // Parameters of Axi Master Bus Interface M00_AXI
//        parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR    = 32'h40000000,
//        parameter integer C_M00_AXI_BURST_LEN    = 16,
        .C_M00_AXI_ID_WIDTH(C_M00_AXI_ID_WIDTH),
        .C_M00_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
        .C_M00_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
        .C_M00_AXI_AWUSER_WIDTH(C_M00_AXI_AWUSER_WIDTH),
        .C_M00_AXI_ARUSER_WIDTH(C_M00_AXI_ARUSER_WIDTH),
        .C_M00_AXI_WUSER_WIDTH(C_M00_AXI_WUSER_WIDTH),
        .C_M00_AXI_RUSER_WIDTH(C_M00_AXI_RUSER_WIDTH),
        .C_M00_AXI_BUSER_WIDTH(C_M00_AXI_BUSER_WIDTH),

        // Parameters of Axi Slave Bus Interface S00_AXIS
        .C_AXIS_TDATA_WIDTH(C_AXIS_TDATA_WIDTH)

        // Parameters of Axi Master Bus Interface M00_AXIS
//        parameter integer C_M00_AXIS_TDATA_WIDTH    = 32
//        parameter integer C_M00_AXIS_START_COUNT    = 32
    )theCC
    (
        // Users to add ports here
        .Start(Start),
        .ByteFinish(ByteFinish),
        .FBFlag(FBFlag),
        .FBCount(FBCount),
        .tableInitFinish(CMInitFinish),
        .EncLow(EncLow),
        .EncHigh(EncHigh),
        .EncMid(EncMid),
        .FileFinish(FileFinish),
        
        .aclk(aclk),
        .aresetn(aresetn),
        .m00_axi_awid(m00_axi_awid),
        .m00_axi_awaddr(m00_axi_awaddr),
        .m00_axi_awlen(m00_axi_awlen),
        .m00_axi_awsize(m00_axi_awsize),
        .m00_axi_awburst(m00_axi_awburst),
        .m00_axi_awlock(m00_axi_awlock),
        .m00_axi_awcache(m00_axi_awcache),
        .m00_axi_awprot(m00_axi_awprot),
        .m00_axi_awqos(m00_axi_awqos),
        .m00_axi_awuser(m00_axi_awuser),
        .m00_axi_awvalid(m00_axi_awvalid),
        .m00_axi_awready(m00_axi_awready),
        .m00_axi_wdata(m00_axi_wdata),
        .m00_axi_wstrb(m00_axi_wstrb),
        .m00_axi_wlast(m00_axi_wlast),
        .m00_axi_wuser(m00_axi_wuser),
        .m00_axi_wvalid(m00_axi_wvalid),
        .m00_axi_wready(m00_axi_wready),
        .m00_axi_bid(m00_axi_bid),
        .m00_axi_bresp(m00_axi_bresp),
        .m00_axi_buser(m00_axi_buser),
        .m00_axi_bvalid(m00_axi_bvalid),
        .m00_axi_bready(m00_axi_bready),
        .m00_axi_arid(m00_axi_arid),
        .m00_axi_araddr(m00_axi_araddr),
        .m00_axi_arlen(m00_axi_arlen),
        .m00_axi_arsize(m00_axi_arsize),
        .m00_axi_arburst(m00_axi_arburst),
        .m00_axi_arlock(m00_axi_arlock),
        .m00_axi_arcache(m00_axi_arcache),
        .m00_axi_arprot(m00_axi_arprot),
        .m00_axi_arqos(m00_axi_arqos),
        .m00_axi_aruser(m00_axi_aruser),
        .m00_axi_arvalid(m00_axi_arvalid),
        .m00_axi_arready(m00_axi_arready),
        .m00_axi_rid(m00_axi_rid),
        .m00_axi_rdata(m00_axi_rdata),
        .m00_axi_rresp(m00_axi_rresp),
        .m00_axi_rlast(m00_axi_rlast),
        .m00_axi_ruser(m00_axi_ruser),
        .m00_axi_rvalid(m00_axi_rvalid),
        .m00_axi_rready(m00_axi_rready),

        .s00_axis_tready(s00_axis_tready),
        .s00_axis_tdata(s00_axis_tdata),
        .s00_axis_tlast(s00_axis_tlast),
        .s00_axis_tvalid(s00_axis_tvalid),

        .m00_axis_tvalid(m00_axis_tvalid),
        .m00_axis_tdata(m00_axis_tdata),
        .m00_axis_tlast(m00_axis_tlast),
        .m00_axis_tready(m00_axis_tready)
    );
// User logic ends

	endmodule
