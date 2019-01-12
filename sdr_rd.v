
module sdr_rd(/*autoarg*/
    //Inouts
    sdr_DQ,

    //Outputs
    sdr_CKE, sdr_nCS, sdr_BA, sdr_A, sdr_nRAS, sdr_nCAS, sdr_nWE,
    sdr_DQM, rd_exit, sdr_rdata_wr, sdr_rdata,

    //Inputs
    clk, rst_n, sdr_rd_req, sdr_bank_addr, sdr_row_addr, sdr_col_addr,
    sdr_rdata_unfilled_depth, sdr_rd_byte_cnt
);

`include "sdr_parameters.vh"

input                 clk              ;  //clock, 167MHz
input                 rst_n            ;  //reset

output                sdr_CKE          ;
output                sdr_nCS          ;
output      [1:0]     sdr_BA           ;
output      [12:0]    sdr_A            ;
output                sdr_nRAS         ;
output                sdr_nCAS         ;
output                sdr_nWE          ;
inout       [15:0]    sdr_DQ           ;
output      [1:0]     sdr_DQM          ;

input                 sdr_rd_req       ;
input       [1:0]     sdr_bank_addr    ;
input       [12:0]    sdr_row_addr     ;
input       [8:0]     sdr_col_addr     ;
output                rd_exit          ;
input [4:0] sdr_rdata_unfilled_depth;
input [11:0] sdr_rd_byte_cnt;
output sdr_rdata_wr;
output [15:0] sdr_rdata;

localparam S_IDLE = 4'h0;
localparam S_ACTIVE = 4'h1;
localparam S_READ = 4'h2;
localparam S_PRECHARGE = 4'h3;
localparam S_PAUSE = 4'h4;

localparam CMD_NOP = 3'b111;
localparam CMD_ACTIVE = 3'b011;
localparam CMD_READ = 3'b101;
localparam CMD_PRECHARGE = 3'b010;

localparam NRCD = (tRCD/tCK);
localparam NRP = (tRP/tCK);
/*autodefine*/
//auto wires{{{
wire        active_done ;
wire        rd_done ;
wire        sdr_CKE ;
wire [15:0] sdr_DQ ;
wire [1:0]  sdr_DQM ;
wire        sdr_nCS ;
//}}}
//auto regs{{{
reg [15:0] base_cnt ;
reg        base_cnt_en ;
reg [12:0] sdr_A ;
reg [1:0]  sdr_BA ;
reg [3:0]  sdr_rd_state ;
reg [3:0]  sdr_rd_state_nxt ;
//}}}
// End of automatic define
reg        sdr_nCAS ;
reg        sdr_nRAS ;
reg        sdr_nWE ;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        base_cnt[15:0] <= #`RD 16'h0;
    else if(active_done | rd_exit | precharge_done | exec_read_cmd | rd_data_over)
        base_cnt <= #`RD 16'h0;
    else if(base_cnt_en)
        base_cnt <= #`RD base_cnt + 16'h1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        base_cnt_en <= #`RD 1'b0;
    else if(sdr_rd_req)
        base_cnt_en <= #`RD 1'b1;
    else if(rd_exit)
        base_cnt_en <= #`RD 1'b0;

assign active_done = (base_cnt >= NRCD) & active_state;
assign precharge_done = (base_cnt >= NRP) & precharge_state;
assign new_rdata_coming = (base_cnt == {13'h0, (CL-1)}) & read_state;
assign new_rdata_coming_pre = (base_cnt == {13'h0, (CL-2)}) & read_state;

assign rdata_rdy = rd_data_over ? 1'b0 : (|rd_left_cnt[23:2]) ? (sdr_rdata_unfilled_depth >= 5'h4) : (rd_left_cnt[23:0] <= {19'h0, sdr_rdata_unfilled_depth});
assign rd_left_cnt[23:0] = (sdr_rd_byte_cnt - rd_total_cnt);
assign rd_data_over = (sdr_rd_byte_cnt == rd_total_cnt) & read_state;
assign rd_exit = (sdr_rd_state == S_READ) && (sdr_rd_state_nxt == S_IDLE);

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        rdata_burst_left_cnt[2:0] <= #`RD 3'h0;
    else if(exec_read_cmd)
        rdata_burst_left_cnt[2:0] <= #`RD rdata_burst_left_cnt + 3'h4;
    else if(rdata_vld_pre)
        rdata_burst_left_cnt[2:0] <= #`RD rdata_burst_left_cnt - 3'h1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_bank_addr_r[1:0] <= #`RD 2'h0;
    else if(sdr_rd_req)
        sdr_bank_addr_r[1:0] <= #`RD sdr_bank_addr;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_row_addr_r[12:0] <= #`RD 13'h0;
    else if(sdr_rd_req)
        sdr_row_addr_r[12:0] <= #`RD sdr_row_addr;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_col_addr_r[8:0] <= #`RD 9'h0;
    else if(sdr_rd_req)
        sdr_col_addr_r[8:0] <= #`RD sdr_col_addr;

assign cur_col_addr[24:0] = (rd_total_cnt[23:0] + {sdr_bank_addr_r, sdr_row_addr_r, sdr_col_addr_r});
assign cur_row_addr[13:0] = cur_col_addr[21:9];
assign cur_bank_addr[1:0] = cur_col_addr[23:22];
assign rd_one_row_end = rdata_vld & (rd_total_cnt < sdr_rd_byte_cnt) ? (cur_col_addr[8:0] == 9'h0) : 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        rdata_vld <= #`RD 1'b0;
    else if(new_rdata_coming)
        rdata_vld <= #`RD 1'b1;
    else if(base_cnt > 16'h5)
        rdata_vld == #`RD 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        rd_total_cnt[23:0] <= #`RD 24'h0;
    else if(sdr_rd_req)
        rd_total_cnt[23:0] <= #`RD 24'h0;
    else if(rdata_vld_pre)
        rd_total_cnt[23:0] <= #`RD rd_total_cnt + 24'h1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        rdata_vld_pre <= #`RD 1'b0;
    else if(new_rdata_coming_pre)
        rdata_vld_pre <= #`RD 1'b1;
    else if(base_cnt > 16'h4)
        rdata_vld_pre <= #`RD 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_rd_state[3:0] <= #`RD S_IDLE;
    else
        sdr_rd_state[3:0] <= #`RD sdr_rd_state_nxt;

always @(*) begin
    sdr_rd_state_nxt[3:0] = sdr_rd_state;
    case(sdr_rd_state)
        S_IDLE: if(sdr_rd_req) sdr_rd_state_nxt = S_ACTIVE;
        S_ACTIVE: if(active_done) sdr_rd_state_nxt = S_READ;
        S_READ: if(rd_data_over) sdr_rd_state_nxt = S_PRECHARGE;
        S_PRECHARGE: if(precharge_done) sdr_rd_state_nxt = S_IDLE;
        default: sdr_rd_state_nxt = S_IDLE;
    endcase
end

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        `SEND_CMD <= #`RD CMD_NOP;
    else if(exec_active_cmd)
        `SEND_CMD <= #`RD CMD_ACTIVE;
    else if(exec_read_cmd)
        `SEND_CMD <= #`RD CMD_READ;
    else if(exec_precharge_cmd)
        `SEND_CMD <= #`RD CMD_NOP;

assign active_state = (sdr_rd_state == S_ACTIVE);
assign exec_active_cmd = (~active_state_dly) & active_state;
always @(posedge clk or negedge rst_n)
    if(!rst_n)
        active_state_dly <= #`RD 1'b0;
    else 
        active_state_dly <= #`RD active_state;

assign precharge_state = (sdr_rd_state == S_PRECHARGE);
assign exec_precharge_cmd = (~precharge_state_dly) & precharge_state;
always @(posedge clk or negedge rst_n)
    if(!rst_n)
        precharge_state_dly <= #`RD 1'b0;
    else 
        precharge_state_dly <= #`RD precharge_state;

assign read_state = (sdr_rd_state == S_READ);
assign exec_read_cmd = read_state & (~rd_data_over) & rdata_rdy & (rd_total_cnt[1:0] == 2'h0) & (rdata_burst_left_cnt < 3'h4);


always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_BA[1:0] <= #`RD 2'h0;
    else if(exec_active_cmd)
        sdr_BA[1:0] <= #`RD cur_bank_addr;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_A[12:0] <= #`RD 13'h0;
    else if(exec_active_cmd)
        sdr_A[12:0] <= #`RD sdr_row_addr;
    else if(exec_read_cmd)
        sdr_A[12:0] <= #`RD {2'h0, 1'b1, 1'b0, sdr_col_addr};

assign sdr_DQM[1:0] = 2'h0;
assign sdr_CKE = 1'b1;
assign sdr_nCS = 1'b0;
assign sdr_rdata = sdr_DQ;
assign sdr_rdata_wr = rdata_vld;



endmodule
