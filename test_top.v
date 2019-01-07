// Testbench for Micron SDR SDRAM Verilog models

`timescale 1ns / 1ps

module test;

`include "sdr_parameters.vh"

reg                     clk;                           // Clock
reg rst_n;

reg sdr_wr_req;
reg [15:0] sdr_wdata_in;
reg sdr_wr_vld;
wire sdr_wr_ready;
reg [31:0] sdr_waddr;
reg sdr_rd_req;
wire [15:0] sdr_rdata_out;
wire sdr_rd_vld;
reg  [31:0] sdr_raddr;
wire sdr_CKE;
wire sdr_nCS;
wire [1:0] sdr_BA;
wire [12:0] sdr_A;
wire sdr_nRAS;
wire sdr_nCAS;
wire sdr_nWE;
wire [15:0] sdr_DQ;
wire [1:0] sdr_DQM;


sdr sdram0 (sdr_DQ, sdr_A, sdr_BA, clk, sdr_CKE, sdr_nCS, sdr_nRAS, sdr_nCAS, sdr_nWE, sdr_DQM);
sdr_top u_sdr_top(/*autoinst*/
        .clk           ( clk                 ),    //I         u_sdr_top    
        .rst_n         ( rst_n               ),    //I         u_sdr_top    
        .sdr_wr_req    ( sdr_wr_req          ),    //I         u_sdr_top    
        .sdr_wdata_in  ( sdr_wdata_in[15:0]  ),    //I  [15:0] u_sdr_top    
        .sdr_wr_vld    ( sdr_wr_vld          ),    //I         u_sdr_top    
        .sdr_wr_ready  ( sdr_wr_ready        ),    //O         u_sdr_top    
        .sdr_waddr     ( sdr_waddr[31:0]     ),    //I  [31:0] u_sdr_top    
        .sdr_rd_req    ( sdr_rd_req          ),    //I         u_sdr_top    
        .sdr_rdata_out ( sdr_rdata_out[15:0] ),    //O  [15:0] u_sdr_top    
        .sdr_rd_vld    ( sdr_rd_vld          ),    //O         u_sdr_top    
        .sdr_raddr     ( sdr_raddr[31:0]     ),    //I  [31:0] u_sdr_top    
        .sdr_CKE       ( sdr_CKE             ),    //O         u_sdr_top    
        .sdr_nCS       ( sdr_nCS             ),    //O         u_sdr_top    
        .sdr_BA        ( sdr_BA[1:0]         ),    //O  [1:0]  u_sdr_top    
        .sdr_A         ( sdr_A[12:0]         ),    //O  [12:0] u_sdr_top    
        .sdr_nRAS      ( sdr_nRAS            ),    //O         u_sdr_top    
        .sdr_nCAS      ( sdr_nCAS            ),    //O         u_sdr_top    
        .sdr_nWE       ( sdr_nWE             ),    //O         u_sdr_top    
        .sdr_DQ        ( sdr_DQ[15:0]        ),    //IO [15:0] u_sdr_top    
        .sdr_DQM       ( sdr_DQM[1:0]        )     //O  [1:0]  u_sdr_top    
);

initial begin
    clk = 1'b0;
    rst_n = 1'b0;
    sdr_wr_req = 1'b0;
    sdr_rd_req = 1'b0;
    #10;
    rst_n = 1'b1;

    #100us;
    #tCK;
    #1us;
    sdr_wr_req = 1'b1;
    sdr_waddr = 32'h0;
    #tCK;
    sdr_wr_req = 1'b0;
    #100us;
    sdr_rd_req = 1'b1;
    sdr_raddr = 32'h0;
    #tCK;
    sdr_rd_req = 1'b0;
    #1us;
    sdr_wr_req = 1'b1;
    sdr_waddr = 32'h0;
    #tCK;
    sdr_wr_req = 1'b0;
    #100us;
    sdr_rd_req = 1'b1;
    sdr_raddr = 32'h0;
    #tCK;
    sdr_rd_req = 1'b0;
    #1us;
    $finish;
end

always #(tCK/2) clk = ~clk;

/*
always @ (posedge clk) begin
    $strobe("at time %t clk=%b cke=%b CS#=%b RAS#=%b CAS#=%b WE#=%b dqm=%b addr=%b ba=%b DQ=%d",
            $time, clk, cke, cs_n, ras_n, cas_n, we_n, dqm, addr, ba, DQ);
end
*/

initial begin
    $fsdbDumpfile("debug.fsdb");
    $fsdbDumpvars(0);
end

endmodule
//verilog-library-directories(".")
