
module sdr_wr(/*autoarg*/
    //Inouts
    sdr_DQ,

    //Outputs
    sdr_CKE, sdr_nCS, sdr_BA, sdr_A, sdr_nRAS, sdr_nCAS, sdr_nWE,
    sdr_DQM, wr_exit,

    //Inputs
    clk, rst_n, sdr_wr_req, sdr_bank_addr, sdr_row_addr, sdr_col_addr
);

`include "sdr_parameters.vh"

input                 clk              ;  //clock, 167MHz
input                 rst_n            ;

output                sdr_CKE          ;
output                sdr_nCS          ;
output      [1:0]     sdr_BA           ;
output      [12:0]    sdr_A            ;
output                sdr_nRAS         ;
output                sdr_nCAS         ;
output                sdr_nWE          ;
inout       [15:0]    sdr_DQ           ;
output      [1:0]     sdr_DQM          ;

input                 sdr_wr_req       ;
input       [1:0]     sdr_bank_addr    ;
input       [12:0]    sdr_row_addr     ;
input       [8:0]     sdr_col_addr     ;
output                wr_exit          ;

localparam S_IDLE = 4'h0;
localparam S_ACTIVE = 4'h1;
localparam S_WRITE = 4'h2;
localparam S_PRECHARGE = 4'h3;

localparam CMD_NOP = 3'b111;
localparam CMD_ACTIVE = 3'b011;
localparam CMD_WRITE = 3'b100;
localparam CMD_PRECHARGE = 3'b010;

localparam NRCD = (tRCD/tCK);
localparam NRP = (tRP/tCK);
/*autodefine*/
//auto wires{{{
wire          active_done;
wire          precharge_done;
wire          sdr_CKE;
wire[15:0]    sdr_DQ;
wire[1:0]     sdr_DQM;
wire          sdr_nCS;
wire          wr_done;
wire        wr_exit;
//}}}
//auto regs{{{
reg          sdr_nCAS;
reg          sdr_nRAS;
reg          sdr_nWE;
reg[15:0]     base_cnt;
reg           base_cnt_en;
reg[12:0]     sdr_A;
reg[1:0]      sdr_BA;
reg[3:0]      sdr_wr_state;
reg[3:0]      sdr_wr_state_nxt;
reg[12:0]   bank0_act_row;
reg[12:0]   bank1_act_row;
reg[12:0]   bank2_act_row;
reg[12:0]   bank3_act_row;
//}}}
// End of automatic define

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        base_cnt[15:0] <= #`RD 16'h0;
    else if(active_done | wr_done | precharge_done)
        base_cnt <= #`RD 16'h0;
    else if(base_cnt_en)
        base_cnt <= #`RD base_cnt + 16'h1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        base_cnt_en <= #`RD 1'b0;
    else if(sdr_wr_req)
        base_cnt_en <= #`RD 1'b1;
    else if(precharge_done)
        base_cnt_en <= #`RD 1'b0;

assign active_done = (base_cnt >= NRCD) & (sdr_wr_state == S_ACTIVE);
assign wr_done = (base_cnt == 4) & (sdr_wr_state == S_WRITE);
assign precharge_done = (base_cnt >= NRP) & (sdr_wr_state == S_PRECHARGE);
assign wr_exit = precharge_done;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_wr_state[3:0] <= #`RD S_IDLE;
    else
        sdr_wr_state[3:0] <= #`RD sdr_wr_state_nxt;

always @(*) begin
    sdr_wr_state_nxt[3:0] = sdr_wr_state;
    case(sdr_wr_state)
        S_IDLE: if(sdr_wr_req) sdr_wr_state_nxt = S_ACTIVE;
        S_ACTIVE: if(active_done) sdr_wr_state_nxt = S_WRITE;
        S_WRITE: if(wr_done) sdr_wr_state_nxt = S_PRECHARGE;
        S_PRECHARGE: if(precharge_done) sdr_wr_state_nxt = S_IDLE;
        default: sdr_wr_state_nxt = S_IDLE;
    endcase
end

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_NOP;
    else 
        case({sdr_wr_state, sdr_wr_state_nxt})
            {S_IDLE, S_ACTIVE}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_ACTIVE;
            {S_ACTIVE, S_WRITE}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_WRITE;
            {S_WRITE, S_PRECHARGE}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_PRECHARGE;
            default: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_NOP;
        endcase

//always @(posedge clk or negedge rst_n)
//    if(!rst_n)

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_BA[1:0] <= #`RD 2'h0;
    else if(sdr_wr_req)
        sdr_BA[1:0] <= #`RD sdr_bank_addr;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_A[12:0] <= #`RD 13'h0;
    else if(sdr_wr_req)
        sdr_A[12:0] <= #`RD sdr_row_addr;
    else if({sdr_wr_state, sdr_wr_state_nxt} == {S_ACTIVE, S_WRITE})
        sdr_A[12:0] <= #`RD {2'h0, 1'b0, 1'b0, sdr_col_addr};

assign sdr_DQ[15:0] = 16'h5555;
assign sdr_DQM[1:0] = 2'h0;
assign sdr_CKE = 1'b1;
assign sdr_nCS = 1'b0;


endmodule
