
module sdr_top(/*autoarg*/);

//port decleration
input clk;//clock, 167MHz
input rst_n;//reset

input   sdr_wr_req;
input [15:0]  sdr_wdata_in;
input   sdr_wr_vld;
output  sdr_wr_ready;
input [31:0] sdr_waddr;

input   sdr_rd_req;
output  [15:0] sdr_rdata_out;
output  sdr_rd_vld;
input [31:0] sdr_raddr;


//sdr
output sdr_CKE;
output sdr_nCS;
output [1:0] sdr_BA;
output [12:0] sdr_A;
output sdr_nRAS;
output sdr_nCAS;
output sdr_nWE;
inout [15:0] sdr_DQ;
output [1:0] sdr_DQM;

localparam S_INIT = 4'h0;
localparam S_IDLE = 4'h1;
localparam S_WRITE = 4'h2;
localparam S_READ = 4'h3;

assign sdr_wr_bank_addr[1:0] = sdr_waddr[24:23];
assign sdr_wr_row_addr[12:0] = sdr_waddr[22:10];
assign sdr_wr_col_addr[8:0] = sdr_waddr[9:0];


always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_state[3:0] <= #`RD S_INIT;
    else 
        sdr_state[3:0] <= #`RD sdr_state_nxt;

always @(*) begin
    sdr_state_nxt[3:0] = sdr_state;
    case(sdr_state)
        S_INIT: if(init_done) sdr_state_nxt = S_IDLE;
        S_IDLE: if(sdr_wr_req) sdr_state_nxt = S_WRITE;
                else if(sdr_rd_req) sdr_state_nxt = S_READ;
        S_WRITE: if(sdr_wr_done) sdr_state_nxt = S_IDLE;
        S_READ: if(sdr_rd_done) sdr_state_nxt = S_IDLE;
        default: sdr_state_nxt = S_INIT;
    endcase
end

always @(*) begin
    case(sdr_state)
        S_INIT: begin
            sdr_CKE = sdr_init_CKE;
            sdr_nCS = sdr_init_nCS;
            sdr_BA[1:0] = sdr_init_BA;
            sdr_A[12:0] = sdr_init_A;
            sdr_nRAS = sdr_init_nRAS;
            sdr_nCAS = sdr_init_nCAS;
            sdr_nWE = sdr_init_nWE;
            sdr_DQM[1:0] = sdr_init_DQM;
        end
        S_IDLE: begin

        end
        S_WRITE: begin
            sdr_CKE = sdr_wr_CKE;
            sdr_nCS = sdr_wr_nCS;
            sdr_BA[1:0] = sdr_wr_BA;
            sdr_A[12:0] = sdr_wr_A;
            sdr_nRAS = sdr_wr_nRAS;
            sdr_nCAS = sdr_wr_nCAS;
            sdr_nWE = sdr_wr_nWE;
            sdr_DQM[1:0] = sdr_wr_DQM;
        end
        S_READ: begin

        end
        default: begin
            sdr_CKE = 1'b0;
            sdr_nCS = 1'b0;
            sdr_BA[1:0] = 2'h0;
            sdr_A[12:0] = 13'h0;
            sdr_nRAS = 1'b0;
            sdr_nCAS = 1'b0;
            sdr_nWE = 1'b0;
            sdr_DQM[1:0] = 2'h0;
        end
    endcase
end

sdr_init u_sdr_init(/*autoinst*/);

sdr_wr u_sdr_wr(/*autoinst*/);

assign sdr_DQ[15:0] = (sdr_state == S_WRITE) ? sdr_wr_DQ : 16'hz;

endmodule
//verilog-library-directories(".")
