`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/07/29 17:42:24
// Design Name: 
// Module Name: tm_top_alpha
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


module tm_top_alpha_s

#(
    parameter	 C_S_AXIS_TDATA_WIDTH = 512,
    parameter	 C_S_AXIS_TUSER_WIDTH = 256,
    parameter    C_S_AXIS_TKEEP_WIDTH = 32,

    parameter   DDR4_AXIS_DATA_WIDTH = 512,
    parameter   DDR4_AXIS_STRB_WIDTH = DDR4_AXIS_DATA_WIDTH/8, //512/8=64

    parameter   RAM_AXIS_DATA_WIDTH = 512,
    parameter   RAM_AXIS_STRB_WIDTH = RAM_AXIS_DATA_WIDTH/8, 

    parameter   PKT_LEN_WIDTH = 16,  // the width for pkt length  1518 needs 11bits
    parameter   TIME_SCALE_WIDTH = 32// the width for virtual time


)



(


    input                                   clk               ,
    input                                   aresetn                ,
    input                                   i_pkt_data_valid5     ,
    input  [C_S_AXIS_TDATA_WIDTH/2-1    :0]    i_pkt5_data0          ,
    input  [C_S_AXIS_TDATA_WIDTH/2-1    :0]    i_pkt5_data1          ,
    input  [C_S_AXIS_TDATA_WIDTH/2-1    :0]    i_pkt5_data2          ,
    input  [C_S_AXIS_TDATA_WIDTH/2-1    :0]    i_pkt5_data3          ,
    input  [C_S_AXIS_TDATA_WIDTH/2-1    :0]    i_pkt5_data4          ,
    input  [C_S_AXIS_TDATA_WIDTH/2-1    :0]    i_pkt5_data5          ,
    input  [C_S_AXIS_TDATA_WIDTH/2-1    :0]    i_pkt5_data6          ,
    input  [C_S_AXIS_TDATA_WIDTH/2-1    :0]    i_pkt5_data7          ,
    input  [255                      :0]       i_metadata            , 
    input                                      i_metadata_vld        ,

    output                                  o_tuser_fifo_rd_en     ,
	input  [C_S_AXIS_TUSER_WIDTH-1 :0]      i_snd_half_fifo_tuser  ,
	input  [C_S_AXIS_TKEEP_WIDTH-1 :0]      i_snd_half_fifo_tkeep  ,
	input                                   i_snd_half_fifo_tlast  ,

	input [C_S_AXIS_TDATA_WIDTH-1:0]	    i_seg_fifo_tdata_out   ,
	input [C_S_AXIS_TUSER_WIDTH-1:0]	    i_seg_fifo_tuser_out   ,
	input [C_S_AXIS_TKEEP_WIDTH-1:0]	  	i_seg_fifo_tkeep_out   ,
	input							                	  i_seg_fifo_tlast_out   ,
	output                               	o_seg_fifo_rd_en       ,
	input                              	    i_seg_fifo_empty       ,
   
    output wire    [C_S_AXIS_TDATA_WIDTH-1:0]   depar_out_tdata     ,
    output wire    [C_S_AXIS_TKEEP_WIDTH-1:0]   depar_out_tkeep     ,
    output wire    [C_S_AXIS_TUSER_WIDTH-1:0]   depar_out_tuser     ,
    output wire                                 depar_out_tvalid    ,
    output wire                                 depar_out_tlast     ,
	input                                      depar_out_tready    ,

    input     [TIME_SCALE_WIDTH-1:0]           virtual_time,
    input     ui_clk,
    input     ui_rst,

    //DDR4 interface

    output wire                                c0_init_calib_complete, // output wire c0_init_calib_complete
    output wire                                dbg_clk, // output wire dbg_clk
    input wire                                 c0_sys_clk_p, // input wire c0_sys_clk_p
    input wire                                 c0_sys_clk_n, // input wire c0_sys_clk_n
    output wire [511 : 0]                      dbg_bus, // output wire [511 : 0] dbg_bus
    output wire [16 : 0]                       c0_ddr4_adr, // output wire [16 : 0] c0_ddr4_adr
    output wire [1 : 0]                        c0_ddr4_ba, // output wire [1 : 0] c0_ddr4_ba
    output wire [0 : 0]                        c0_ddr4_cke, // output wire [0 : 0] c0_ddr4_cke
    output wire [0 : 0]                        c0_ddr4_cs_n, // output wire [0 : 0] c0_ddr4_cs_n
    inout wire [7 : 0]                         c0_ddr4_dm_dbi_n, // inout wire [7 : 0] c0_ddr4_dm_dbi_n
    inout wire [63 : 0]                        c0_ddr4_dq, // inout wire [63 : 0] c0_ddr4_dq
    inout wire [7 : 0]                         c0_ddr4_dqs_c, // inout wire [7 : 0] c0_ddr4_dqs_c
    inout wire [7 : 0]                         c0_ddr4_dqs_t, // inout wire [7 : 0] c0_ddr4_dqs_t
    output wire [0 : 0]                        c0_ddr4_odt, // output wire [0 : 0] c0_ddr4_odt
    output wire [1 : 0]                        c0_ddr4_bg, // output wire [1 : 0] c0_ddr4_bg
    output wire                                c0_ddr4_reset_n, // output wire c0_ddr4_reset_n
    output wire                                c0_ddr4_act_n, // output wire c0_ddr4_act_n
    output wire [0 : 0]                        c0_ddr4_ck_c, // output wire [0 : 0] c0_ddr4_ck_c
    output wire [0 : 0]                        c0_ddr4_ck_t, // output wire [0 : 0] c0_ddr4_ck_t
    output wire                                c0_ddr4_ui_clk, // output wire c0_ddr4_ui_clk
    output wire                                c0_ddr4_ui_clk_sync_rst,   // output wire c0_ddr4_ui_clk_sync_rst
    input wire                                 rst
    
    );

   wire                                                 c_chooser_coarse_cq_ddr4_data_en;
   wire  [PKT_LEN_WIDTH+TIME_SCALE_WIDTH-1:0]           c_chooser_coarse_cq_ddr4_descripter;
   wire  [C_S_AXIS_TDATA_WIDTH-1:0]                     c_chooser_coarse_cq_ddr4_axis_tdata;
   wire  [C_S_AXIS_TDATA_WIDTH/8-1:0]                   c_chooser_coarse_cq_ddr4_axis_tstrb;
   wire                                                 c_chooser_coarse_cq_ddr4_axis_tlast;
   wire                                                 c_chooser_coarse_cq_ddr4_axis_tvalid;
   wire                                                 c_chooser_coarse_cq_ddr4_axis_tready;

   wire                                                 c_chooser_switch_data_en;
   wire [PKT_LEN_WIDTH+TIME_SCALE_WIDTH-1:0]            c_chooser_switch_descripter;
   wire [C_S_AXIS_TDATA_WIDTH-1:0]                      c_chooser_switch_axis_wdata;
   wire [C_S_AXIS_TDATA_WIDTH/8-1:0]                    c_chooser_switch_axis_wstrb;
   wire                                                 c_chooser_switch_axis_wlast   ; 
   wire                                                 c_chooser_switch_axis_wvalid  ;
   wire                                                 c_chooser_switch_axis_wready  ;

   wire                                                 c_coarse_cq_switch_data_en;
   wire [PKT_LEN_WIDTH+TIME_SCALE_WIDTH-1:0]            c_coarse_cq_switch_descripter;
   wire [C_S_AXIS_TDATA_WIDTH-1:0]                     c_coarse_cq_switch_axis_wdata;
   wire [C_S_AXIS_TDATA_WIDTH/8-1:0]                    c_coarse_cq_switch_axis_wstrb;
   wire                                                 c_coarse_cq_switch_axis_wlast;
   wire                                                 c_coarse_cq_switch_axis_wvalid;
   wire                                                 c_coarse_cq_switch_axis_wready;

   wire                                                 c_switch_fine_cq_data_en;
   wire [PKT_LEN_WIDTH+TIME_SCALE_WIDTH-1:0]            c_switch_fine_cq_descripter;
   wire [C_S_AXIS_TDATA_WIDTH-1:0]                      c_switch_fine_cq_axis_wdata;
   wire [C_S_AXIS_TDATA_WIDTH/8-1:0]                    c_switch_fine_cq_axis_wstrb;
   wire                                                 c_switch_fine_cq_axis_wlast;    
   wire                                                 c_switch_fine_cq_axis_wvalid; 
   wire                                                 c_switch_fine_cq_axis_wready;



    wire [31:0]                      c0_ddr4_s_axi_awaddr;
    wire [7:0]                       c0_ddr4_s_axi_awlen;
    wire [2:0]                       c0_ddr4_s_axi_awsize;
    wire [1:0]                       c0_ddr4_s_axi_awburst;
    wire [3:0]                       c0_ddr4_s_axi_awcache;
    wire [2:0]                       c0_ddr4_s_axi_awprot;
    wire                             c0_ddr4_s_axi_awvalid;
    wire                             c0_ddr4_s_axi_awready;

        // Slave Interface Write Data Ports
    wire [511:0]    c0_ddr4_s_axi_wdata;
    wire [63:0]  c0_ddr4_s_axi_wstrb;
    wire [63:0]  c0_ddr4_s_axi_wstrb_s;
    
    wire                             c0_ddr4_s_axi_wlast;
    wire                             c0_ddr4_s_axi_wvalid;
    wire                             c0_ddr4_s_axi_wready;
        // Slave Interface Write Response Ports
    wire                             c0_ddr4_s_axi_bready;
    wire [0:0]      c0_ddr4_s_axi_bid;
    wire [1:0]                       c0_ddr4_s_axi_bresp;
    wire                             c0_ddr4_s_axi_bvalid;
        // Slave Interface Read Address Ports

    wire [31:0]    c0_ddr4_s_axi_araddr;
    wire [7:0]                       c0_ddr4_s_axi_arlen;
    wire [2:0]                       c0_ddr4_s_axi_arsize;
    wire [1:0]                       c0_ddr4_s_axi_arburst;
    wire [3:0]                       c0_ddr4_s_axi_arcache;
    wire [2:0]                       c0_ddr4_s_axi_arprot;
    wire                             c0_ddr4_s_axi_arvalid;
    wire                             c0_ddr4_s_axi_arready;
        // Slave Interface Read Data Ports
    wire                             c0_ddr4_s_axi_rready;
    wire [0:0]      c0_ddr4_s_axi_rid;
    wire [511:0]    c0_ddr4_s_axi_rdata;
    wire [1:0]                       c0_ddr4_s_axi_rresp;
    wire                             c0_ddr4_s_axi_rlast;
    wire                             c0_ddr4_s_axi_rvalid;

    wire [31 : 0] s_axi_awaddr;
    wire [7 : 0] s_axi_awlen;
    wire [2 : 0] s_axi_awsize;
    wire [1 : 0] s_axi_awburst;
    wire [3 : 0] s_axi_awcache;
    wire [2 : 0] s_axi_awprot;

    wire s_axi_awvalid;
    wire s_axi_awready;
    wire [511 : 0] s_axi_wdata;
    wire [63 : 0] s_axi_wstrb;
    wire s_axi_wlast;
    wire s_axi_wvalid;
    wire s_axi_wready;
    wire [1 : 0] s_axi_bresp;
    wire s_axi_bvalid;
    wire s_axi_bready;
    wire [21 : 0] s_axi_araddr;
    wire [7 : 0] s_axi_arlen;
    wire [2 : 0] s_axi_arsize;
    wire [1 : 0] s_axi_arburst;

    wire [3 : 0] s_axi_arcache;
    wire [2 : 0] s_axi_arprot;
    wire s_axi_arvalid;
    wire s_axi_arready;
    wire [511 : 0] s_axi_rdata;
    wire [1 : 0] s_axi_rresp;
    wire s_axi_rlast;
    wire s_axi_rvalid;
    wire s_axi_rready;
    reg [8:0] w_cnt;

    assign      c0_ddr4_s_axi_wstrb_s = (  c0_ddr4_s_axi_wvalid == 1)? c0_ddr4_s_axi_wstrb:64'd0;
    reg c0_ddr4_aresetn;

   always @(posedge c0_ddr4_ui_clk) begin
     c0_ddr4_aresetn <= ~c0_ddr4_ui_clk_sync_rst;
   end


    localparam IDLE   = 5'b0_0001;
    localparam W_ADDR = 5'b0_0010;
    localparam W_DATA = 5'b0_0100;
    localparam W_XFER_CPL= 5'b0_1000;
    localparam R_ADDR = 5'b1_0000;

    reg [4:0] curr_state;
    reg [4:0] next_state;
    reg [3:0] start_cnt;
    wire [22:0] btt  = 64*3; 
    wire        cmd_type = 1'b1;
    wire [5:0]  dsa  = 6'd0;
    wire        eof  = 1'b1;
    wire        drr  = 1'b0;
    wire [31:0] saddr = 32'h0; //������д������ȥ
    wire [ 3:0] tag  = 4'b0;
    wire [ 3:0] rsvd = 4'b0;
    
    wire [71:0]   S_AXIS_S2MM_CMD_tdata = {rsvd, tag, saddr, drr, eof, dsa, cmd_type, btt};
    wire          S_AXIS_S2MM_CMD_tready;
    reg           S_AXIS_S2MM_CMD_tvalid;
    wire [511:0]  S_AXIS_S2MM_tdata     ;
    wire [63:0]   S_AXIS_S2MM_tkeep     = 64'hffffffffffffffff;//128�����ݶ���Ч��64*8=128��
    wire          S_AXIS_S2MM_tlast     ;
    wire          S_AXIS_S2MM_tready    ;
    wire          S_AXIS_S2MM_tvalid    ;

    reg           M_AXIS_MM2S_CMD_tvalid;
    wire          M_AXIS_MM2S_CMD_tready;
    wire  [71:0]  M_AXIS_MM2S_CMD_tdata = {rsvd, tag, saddr, drr, eof, dsa, cmd_type, btt};

    wire [511:0]  M_AXIS_MM2S_tdata     ;
    wire [63:0]   M_AXIS_MM2S_tkeep     ;
    wire          M_AXIS_MM2S_tlast     ;
    wire          M_AXIS_MM2S_tvalid    ;

    always @(posedge c0_ddr4_ui_clk ) begin
        if(c0_ddr4_ui_clk_sync_rst)begin
            curr_state <= IDLE;//��ʼ״̬
        end
        else begin
            curr_state <= next_state;//������һ״̬
        end
    end
    always @(*) begin
        case (curr_state)
            IDLE: begin
                if(start_cnt == 4'b1111)begin
                    next_state = W_ADDR;
                end
                else begin
                    next_state = IDLE;
                end
            end
            W_ADDR: begin
                if((S_AXIS_S2MM_CMD_tvalid == 1'b1) && (S_AXIS_S2MM_CMD_tready == 1'b1))begin//���ֳɹ�
                    next_state = W_DATA;//��ת��д����״̬
                end
                else begin
                    next_state = W_ADDR;
                end
            end
            W_DATA: begin
                if((S_AXIS_S2MM_tlast == 1'b1) && (S_AXIS_S2MM_tready == 1'b1) && (S_AXIS_S2MM_tvalid == 1'b1))begin//д�����һ�����ݾͽ�����
                    next_state = W_XFER_CPL;
                end
                else begin
                    next_state = W_DATA;
                end
            end
            W_XFER_CPL: begin
            if(m_axis_s2mm_sts_tvalid) begin  //sts means transfer complete
                next_state = R_ADDR;
            end
            else begin 
                next_state = W_XFER_CPL;
            end
            end
            R_ADDR: begin 
            if((M_AXIS_MM2S_CMD_tvalid == 1'b1) && (M_AXIS_MM2S_CMD_tready == 1'b1))begin 
                next_state = R_ADDR;//��ת��д����״̬
            end
            else begin
                next_state = R_ADDR;
            end
            end
            default: begin
                next_state = IDLE;
            end 
        endcase
    end
    //��ʼ�źŵĲ���
    always @(posedge c0_ddr4_ui_clk ) begin
        if((c0_ddr4_ui_clk_sync_rst)||(c0_init_calib_complete == 1'b0))begin
            start_cnt <= 4'b0;
        end
        else begin
            if(curr_state == IDLE)begin
                start_cnt <= start_cnt + 4'b1;
            end
            else begin
                start_cnt <= 4'b0;
            end
        end
    end
    //tvalid�źŵĲ���
    always @(posedge c0_ddr4_ui_clk ) begin
        if(c0_ddr4_ui_clk_sync_rst)begin
            S_AXIS_S2MM_CMD_tvalid <= 1'b0;
        end
        else begin
            if((curr_state == IDLE) && (next_state == W_ADDR))begin//��ǰ״̬��IDLE��һ״̬��W_ADDRʱ����
                S_AXIS_S2MM_CMD_tvalid <= 1'b1;
            end
            else begin
                if((S_AXIS_S2MM_CMD_tvalid == 1'b1) && (S_AXIS_S2MM_CMD_tready == 1'b1))begin//���ֳɹ��������
                    S_AXIS_S2MM_CMD_tvalid <= 1'b0;
                end
            end
        end
    end
    //�ɹ�д��һ���������һ
    always @(posedge c0_ddr4_ui_clk ) begin
        if(c0_ddr4_ui_clk_sync_rst)begin
            w_cnt <= 9'd0;
        end
        else begin
            if(curr_state == W_DATA)begin
                if((S_AXIS_S2MM_tready == 1'b1) && (S_AXIS_S2MM_tvalid == 1'b1))begin
                    w_cnt <= w_cnt + 9'd1;
                end
            end
            else begin
                w_cnt <= 9'd0;
            end
        end
    end
    always @(posedge c0_ddr4_ui_clk ) begin
        if(c0_ddr4_ui_clk_sync_rst)begin
            M_AXIS_MM2S_CMD_tvalid <= 1'b0;
        end
        else begin
            if((curr_state == W_XFER_CPL) && (next_state == R_ADDR))begin
                M_AXIS_MM2S_CMD_tvalid <= 1'b1;
            end
            else begin
                if((M_AXIS_MM2S_CMD_tvalid == 1'b1) && (M_AXIS_MM2S_CMD_tready == 1'b1))begin
                    M_AXIS_MM2S_CMD_tvalid <= 1'b0;
                end
            end
        end
    end

    assign S_AXIS_S2MM_tdata  = w_cnt;//��w_cnt������д�������
    assign S_AXIS_S2MM_tvalid = (curr_state == W_DATA);
    assign S_AXIS_S2MM_tlast  = w_cnt == 9'd3;//������127�����ݾ�������������1bit����tlast����
    


    axi_datamover_0 axi_datamover_0 (
        .m_axi_mm2s_aclk(c0_ddr4_ui_clk),                        // input wire m_axi_mm2s_aclk
        .m_axi_mm2s_aresetn(!c0_ddr4_ui_clk_sync_rst),                  // input wire m_axi_mm2s_aresetn
        .m_axi_s2mm_aclk             (c0_ddr4_ui_clk),                        // input wire m_axi_s2mm_aclk
        .m_axi_s2mm_aresetn          (!c0_ddr4_ui_clk_sync_rst),                     // input wire m_axi_s2mm_aresetn

        .mm2s_err(mm2s_err),                                      // output wire mm2s_err
        .m_axis_mm2s_cmdsts_aclk(c0_ddr4_ui_clk),        // input wire m_axis_mm2s_cmdsts_aclk
        .m_axis_mm2s_cmdsts_aresetn(!c0_ddr4_ui_clk_sync_rst),  // input wire m_axis_mm2s_cmdsts_aresetn
        .s_axis_mm2s_cmd_tvalid(M_AXIS_MM2S_CMD_tvalid),          // input wire s_axis_mm2s_cmd_tvalid
        .s_axis_mm2s_cmd_tready(M_AXIS_MM2S_CMD_tready),          // output wire s_axis_mm2s_cmd_tready
        .s_axis_mm2s_cmd_tdata(M_AXIS_MM2S_CMD_tdata),            // input wire [71 : 0] s_axis_mm2s_cmd_tdata

        .m_axis_mm2s_sts_tvalid(m_axis_mm2s_sts_tvalid),          // output wire m_axis_mm2s_sts_tvalid
        .m_axis_mm2s_sts_tready(1'b1),          // input wire m_axis_mm2s_sts_tready
        .m_axis_mm2s_sts_tdata(m_axis_mm2s_sts_tdata),            // output wire [7 : 0] m_axis_mm2s_sts_tdata
        .m_axis_mm2s_sts_tkeep(m_axis_mm2s_sts_tkeep),            // output wire [0 : 0] m_axis_mm2s_sts_tkeep
        .m_axis_mm2s_sts_tlast(m_axis_mm2s_sts_tlast),            // output wire m_axis_mm2s_sts_tlast

        .m_axi_mm2s_araddr(c0_ddr4_s_axi_araddr),                    // output wire [31 : 0] m_axi_mm2s_araddr
        .m_axi_mm2s_arlen(c0_ddr4_s_axi_arlen),                      // output wire [7 : 0] m_axi_mm2s_arlen
        .m_axi_mm2s_arsize(c0_ddr4_s_axi_arsize),                    // output wire [2 : 0] m_axi_mm2s_arsize
        .m_axi_mm2s_arburst(c0_ddr4_s_axi_arburst),                  // output wire [1 : 0] m_axi_mm2s_arburst
        .m_axi_mm2s_arprot(c0_ddr4_s_axi_arprot),                    // output wire [2 : 0] m_axi_mm2s_arprot
        .m_axi_mm2s_arcache(c0_ddr4_s_axi_arcache),                  // output wire [3 : 0] m_axi_mm2s_arcache
        .m_axi_mm2s_aruser(),                    // output wire [3 : 0] m_axi_mm2s_aruser
        .m_axi_mm2s_arvalid(c0_ddr4_s_axi_arvalid),                  // output wire m_axi_mm2s_arvalid
        .m_axi_mm2s_arready(c0_ddr4_s_axi_arready),                  // input wire m_axi_mm2s_arready
        .m_axi_mm2s_rdata(c0_ddr4_s_axi_rdata),                      // input wire [511 : 0] m_axi_mm2s_rdata
        .m_axi_mm2s_rresp(c0_ddr4_s_axi_rresp),                      // input wire [1 : 0] m_axi_mm2s_rresp
        .m_axi_mm2s_rlast(c0_ddr4_s_axi_rlast),                      // input wire m_axi_mm2s_rlast
        .m_axi_mm2s_rvalid(c0_ddr4_s_axi_rvalid),                    // input wire m_axi_mm2s_rvalid
        .m_axi_mm2s_rready(c0_ddr4_s_axi_rready),                    // output wire m_axi_mm2s_rready

        .m_axis_mm2s_tdata(M_AXIS_MM2S_tdata),                    // output wire [511 : 0] m_axis_mm2s_tdata
        .m_axis_mm2s_tkeep(M_AXIS_MM2S_tkeep),                    // output wire [63 : 0] m_axis_mm2s_tkeep
        .m_axis_mm2s_tlast(M_AXIS_MM2S_tlast),                    // output wire m_axis_mm2s_tlast
        .m_axis_mm2s_tvalid(M_AXIS_MM2S_tvalid),                  // output wire m_axis_mm2s_tvalid
        .m_axis_mm2s_tready(1'b1),                  // input wire m_axis_mm2s_tready

        .s2mm_err(s2mm_err),                                      // output wire s2mm_err
        .m_axis_s2mm_cmdsts_awclk    (c0_ddr4_ui_clk),                       // input wire m_axis_s2mm_cmdsts_awclk
        .m_axis_s2mm_cmdsts_aresetn  (!c0_ddr4_ui_clk_sync_rst),                     // input wire m_axis_s2mm_cmdsts_aresetn
        .s_axis_s2mm_cmd_tvalid      (S_AXIS_S2MM_CMD_tvalid),          // input wire s_axis_s2mm_cmd_tvalid
        .s_axis_s2mm_cmd_tready      (S_AXIS_S2MM_CMD_tready),          // output wire s_axis_s2mm_cmd_tready
        .s_axis_s2mm_cmd_tdata       (S_AXIS_S2MM_CMD_tdata),            // input wire [71 : 0] s_axis_s2mm_cmd_tdata
        .m_axis_s2mm_sts_tvalid      (m_axis_s2mm_sts_tvalid),          // output wire m_axis_s2mm_sts_tvalid
        .m_axis_s2mm_sts_tready      (1'b1),                      // input wire m_axis_s2mm_sts_tready
        .m_axis_s2mm_sts_tdata       (m_axis_s2mm_sts_tdata),            // output wire [7 : 0] m_axis_s2mm_sts_tdata
        .m_axis_s2mm_sts_tkeep       (m_axis_s2mm_sts_tkeep),            // output wire [0 : 0] m_axis_s2mm_sts_tkeep
        .m_axis_s2mm_sts_tlast       (m_axis_s2mm_sts_tlast),            // output wire m_axis_s2mm_sts_tlast

        // .m_axi_s2mm_awid(m_axi_s2mm_awid),                        // output wire [3 : 0] m_axi_s2mm_awid
        .m_axi_s2mm_awaddr(c0_ddr4_s_axi_awaddr),                    // output wire [31 : 0] m_axi_s2mm_awaddr
        .m_axi_s2mm_awlen(c0_ddr4_s_axi_awlen),                      // output wire [7 : 0] m_axi_s2mm_awlen
        .m_axi_s2mm_awsize(c0_ddr4_s_axi_awsize),                    // output wire [2 : 0] m_axi_s2mm_awsize
        .m_axi_s2mm_awburst(c0_ddr4_s_axi_awburst),                  // output wire [1 : 0] m_axi_s2mm_awburst
        .m_axi_s2mm_awprot(c0_ddr4_s_axi_awprot),                    // output wire [2 : 0] m_axi_s2mm_awprot
        .m_axi_s2mm_awcache(c0_ddr4_s_axi_awcache),                  // output wire [3 : 0] m_axi_s2mm_awcache
        .m_axi_s2mm_awuser(),                    // output wire [3 : 0] m_axi_s2mm_awuser
        .m_axi_s2mm_awvalid(c0_ddr4_s_axi_awvalid),                  // output wire m_axi_s2mm_awvalid
        .m_axi_s2mm_awready(c0_ddr4_s_axi_awready),                                // input wire m_axi_s2mm_awready
        .m_axi_s2mm_wdata(c0_ddr4_s_axi_wdata),                      // output wire [511 : 0] m_axi_s2mm_wdata
        .m_axi_s2mm_wstrb(c0_ddr4_s_axi_wstrb),                      // output wire [63 : 0] m_axi_s2mm_wstrb,����źŸ�����
        .m_axi_s2mm_wlast(c0_ddr4_s_axi_wlast),                      // output wire m_axi_s2mm_wlast
        .m_axi_s2mm_wvalid(c0_ddr4_s_axi_wvalid),                    // output wire m_axi_s2mm_wvalid
        .m_axi_s2mm_wready(c0_ddr4_s_axi_wready),                    // input wire m_axi_s2mm_wready
        
        .m_axi_s2mm_bresp(c0_ddr4_s_axi_bresp),                      // input wire [1 : 0] m_axi_s2mm_bresp
        .m_axi_s2mm_bvalid(c0_ddr4_s_axi_bvalid),                    // input wire m_axi_s2mm_bvalid
        .m_axi_s2mm_bready(c0_ddr4_s_axi_bready),                    // output wire m_axi_s2mm_bready
        .s_axis_s2mm_tdata            (S_AXIS_S2MM_tdata),                    // input wire [127 : 0] s_axis_s2mm_tdata
        .s_axis_s2mm_tkeep            (S_AXIS_S2MM_tkeep),                    // input wire [15 : 0] s_axis_s2mm_tkeep
        .s_axis_s2mm_tlast            (S_AXIS_S2MM_tlast),                    // input wire s_axis_s2mm_tlast
        .s_axis_s2mm_tvalid           (S_AXIS_S2MM_tvalid),                  // input wire s_axis_s2mm_tvalid
        .s_axis_s2mm_tready           (S_AXIS_S2MM_tready)                  // output wire s_axis_s2mm_tready
        );





    ddr4_0 ddr4_ins (
        .c0_init_calib_complete(c0_init_calib_complete),    // output wire c0_init_calib_complete
        .dbg_clk(dbg_clk),                                  // output wire dbg_clk
        .c0_sys_clk_p(c0_sys_clk_p),                        // input wire c0_sys_clk_p
        .c0_sys_clk_n(c0_sys_clk_n),                        // input wire c0_sys_clk_n
        .dbg_bus(),                                  // output wire [511 : 0] dbg_bus

        .c0_ddr4_adr(c0_ddr4_adr),                          // output wire [16 : 0] c0_ddr4_adr
        .c0_ddr4_ba(c0_ddr4_ba),                            // output wire [1 : 0] c0_ddr4_ba
        .c0_ddr4_cke(c0_ddr4_cke),                          // output wire [0 : 0] c0_ddr4_cke
        .c0_ddr4_cs_n(c0_ddr4_cs_n),                        // output wire [0 : 0] c0_ddr4_cs_n
        .c0_ddr4_dm_dbi_n(c0_ddr4_dm_dbi_n),                // inout wire [7 : 0] c0_ddr4_dm_dbi_n
        .c0_ddr4_dq(c0_ddr4_dq),                            // inout wire [63 : 0] c0_ddr4_dq
        .c0_ddr4_dqs_c(c0_ddr4_dqs_c),                      // inout wire [7 : 0] c0_ddr4_dqs_c
        .c0_ddr4_dqs_t(c0_ddr4_dqs_t),                      // inout wire [7 : 0] c0_ddr4_dqs_t
        .c0_ddr4_odt(c0_ddr4_odt),                          // output wire [0 : 0] c0_ddr4_odt
        .c0_ddr4_bg(c0_ddr4_bg),                            // output wire [1 : 0] c0_ddr4_bg
        .c0_ddr4_reset_n(c0_ddr4_reset_n),                  // output wire c0_ddr4_reset_n
        .c0_ddr4_act_n(c0_ddr4_act_n),                      // output wire c0_ddr4_act_n
        .c0_ddr4_ck_c(c0_ddr4_ck_c),                        // output wire [0 : 0] c0_ddr4_ck_c
        .c0_ddr4_ck_t(c0_ddr4_ck_t),                        // output wire [0 : 0] c0_ddr4_ck_t

        .c0_ddr4_ui_clk(c0_ddr4_ui_clk),                    // output wire c0_ddr4_ui_clk
        .c0_ddr4_ui_clk_sync_rst(c0_ddr4_ui_clk_sync_rst),  // output wire c0_ddr4_ui_clk_sync_rst

        .c0_ddr4_aresetn(c0_ddr4_aresetn),                  // input wire c0_ddr4_aresetn

        .c0_ddr4_s_axi_awid(),            // input wire [0 : 0] c0_ddr4_s_axi_awid
        .c0_ddr4_s_axi_awaddr(c0_ddr4_s_axi_awaddr),        // input wire [31 : 0] c0_ddr4_s_axi_awaddr
        .c0_ddr4_s_axi_awlen(c0_ddr4_s_axi_awlen),          // input wire [7 : 0] c0_ddr4_s_axi_awlen
        .c0_ddr4_s_axi_awsize(c0_ddr4_s_axi_awsize),        // input wire [2 : 0] c0_ddr4_s_axi_awsize
        .c0_ddr4_s_axi_awburst(c0_ddr4_s_axi_awburst),      // input wire [1 : 0] c0_ddr4_s_axi_awburst
        .c0_ddr4_s_axi_awlock(1'b0),        // input wire [0 : 0] c0_ddr4_s_axi_awlock
        .c0_ddr4_s_axi_awcache(4'd0),      // input wire [3 : 0] c0_ddr4_s_axi_awcache
        .c0_ddr4_s_axi_awprot(c0_ddr4_s_axi_awprot),        // input wire [2 : 0] c0_ddr4_s_axi_awprot
        .c0_ddr4_s_axi_awqos(4'b0),          // input wire [3 : 0] c0_ddr4_s_axi_awqos
        .c0_ddr4_s_axi_awvalid(c0_ddr4_s_axi_awvalid),      // input wire c0_ddr4_s_axi_awvalid
        .c0_ddr4_s_axi_awready(c0_ddr4_s_axi_awready),      // output wire c0_ddr4_s_axi_awready
        .c0_ddr4_s_axi_wdata(c0_ddr4_s_axi_wdata),          // input wire [511 : 0] c0_ddr4_s_axi_wdata
        .c0_ddr4_s_axi_wstrb(c0_ddr4_s_axi_wstrb_s),          // input wire [63 : 0] c0_ddr4_s_axi_wstrb
        .c0_ddr4_s_axi_wlast(c0_ddr4_s_axi_wlast),          // input wire c0_ddr4_s_axi_wlast
        .c0_ddr4_s_axi_wvalid(c0_ddr4_s_axi_wvalid),        // input wire c0_ddr4_s_axi_wvalid
        .c0_ddr4_s_axi_wready(c0_ddr4_s_axi_wready),        // output wire c0_ddr4_s_axi_wready

        .c0_ddr4_s_axi_bready(c0_ddr4_s_axi_bready),        // input wire c0_ddr4_s_axi_bready
        .c0_ddr4_s_axi_bid(c0_ddr4_s_axi_bid),              // output wire [0 : 0] c0_ddr4_s_axi_bid
        .c0_ddr4_s_axi_bresp(c0_ddr4_s_axi_bresp),          // output wire [1 : 0] c0_ddr4_s_axi_bresp
        .c0_ddr4_s_axi_bvalid(c0_ddr4_s_axi_bvalid),        // output wire c0_ddr4_s_axi_bvalid

        .c0_ddr4_s_axi_arid(),            // input wire [0 : 0] c0_ddr4_s_axi_arid
        .c0_ddr4_s_axi_araddr(c0_ddr4_s_axi_araddr),        // input wire [31 : 0] c0_ddr4_s_axi_araddr
        .c0_ddr4_s_axi_arlen(c0_ddr4_s_axi_arlen),          // input wire [7 : 0] c0_ddr4_s_axi_arlen
        .c0_ddr4_s_axi_arsize(c0_ddr4_s_axi_arsize),        // input wire [2 : 0] c0_ddr4_s_axi_arsize
        .c0_ddr4_s_axi_arburst(c0_ddr4_s_axi_arburst),      // input wire [1 : 0] c0_ddr4_s_axi_arburst
        .c0_ddr4_s_axi_arlock(1'b0),        // input wire [0 : 0] c0_ddr4_s_axi_arlock
        .c0_ddr4_s_axi_arcache(4'd0),      // input wire [3 : 0] c0_ddr4_s_axi_arcache
        .c0_ddr4_s_axi_arprot(c0_ddr4_s_axi_arprot),        // input wire [2 : 0] c0_ddr4_s_axi_arprot
        .c0_ddr4_s_axi_arqos(4'b0),          // input wire [3 : 0] c0_ddr4_s_axi_arqos
        .c0_ddr4_s_axi_arvalid(c0_ddr4_s_axi_arvalid),      // input wire c0_ddr4_s_axi_arvalid
        .c0_ddr4_s_axi_arready(c0_ddr4_s_axi_arready),      // output wire c0_ddr4_s_axi_arready
        .c0_ddr4_s_axi_rready(c0_ddr4_s_axi_rready),        // input wire c0_ddr4_s_axi_rready

        .c0_ddr4_s_axi_rlast(c0_ddr4_s_axi_rlast),          // output wire c0_ddr4_s_axi_rlast
        .c0_ddr4_s_axi_rvalid(c0_ddr4_s_axi_rvalid),        // output wire c0_ddr4_s_axi_rvalid
        .c0_ddr4_s_axi_rresp(c0_ddr4_s_axi_rresp),          // output wire [1 : 0] c0_ddr4_s_axi_rresp
        .c0_ddr4_s_axi_rid(),              // output wire [0 : 0] c0_ddr4_s_axi_rid
        .c0_ddr4_s_axi_rdata(c0_ddr4_s_axi_rdata),          // output wire [511 : 0] c0_ddr4_s_axi_rdata
        .sys_rst(rst)                                  // input wire sys_rst
        );



    










endmodule
