
module sdr_top(/*autoarg*/
    //Inouts
    sdr_DQ,

    //Outputs
    sdr_wdata_ready, sdr_rdata_out, sdr_rdata_rd, sdr_rdata_ready, 
    sdr_CKE, sdr_nCS, sdr_BA, sdr_A, sdr_nRAS, sdr_nCAS, sdr_nWE, 
    sdr_DQM,

    //Inputs
    clk, rst_n, sdr_wr_req, sdr_wdata_in, sdr_wdata_wr, sdr_waddr,
    sdr_wr_byte_cnt, sdr_rd_req, sdr_raddr, sdr_rd_byte_cnt, aref_req,
    aref_done
);

//port decleration
input                 clk                ;  //clock, 167MHz
input                 rst_n              ;  //reset

input                 sdr_wr_req         ;
input       [15:0]    sdr_wdata_in       ;
input                 sdr_wdata_wr       ;
output                sdr_wdata_ready       ;
input       [31:0]    sdr_waddr          ;
input       [11:0]    sdr_wr_byte_cnt    ;

input                 sdr_rd_req         ;
output      [15:0]    sdr_rdata_out      ;
input               sdr_rdata_rd;
output              sdr_rdata_ready;
input       [31:0]    sdr_raddr          ;
input       [11:0]  sdr_rd_byte_cnt;


//sdr
output                sdr_CKE            ;
output                sdr_nCS            ;
output      [1:0]     sdr_BA             ;
output      [12:0]    sdr_A              ;
output                sdr_nRAS           ;
output                sdr_nCAS           ;
output                sdr_nWE            ;
inout       [15:0]    sdr_DQ             ;
output      [1:0]     sdr_DQM            ;

localparam S_INIT = 4'h0;
localparam S_IDLE = 4'h1;
localparam S_WRITE = 4'h2;
localparam S_READ = 4'h3;
localparam S_AREF = 4'h4;

/*autodefine*/
//auto wires{{{
wire        init_done ;
wire [3:0]  r_fifo_addr_r;
wire [3:0] r_fifio_addr_w;
wire        r_fifo_empty;
wire        r_fifo_full;
wire        r_fifo_rd_r;
wire        r_fifo_wr_w;
wire        rd_exit ;
wire [15:0] sdr_DQ ;
wire [12:0] sdr_init_A ;
wire [1:0]  sdr_init_BA ;
wire        sdr_init_CKE ;
wire [1:0]  sdr_init_DQM ;
wire        sdr_init_nCAS ;
wire        sdr_init_nCS ;
wire        sdr_init_nRAS ;
wire        sdr_init_nWE ;
wire [12:0] sdr_rd_A ;
wire [1:0]  sdr_rd_BA ;
wire        sdr_rd_CKE ;
wire [15:0] sdr_rd_DQ ;
wire [1:0]  sdr_rd_DQM ;
wire [1:0]  sdr_rd_bank_addr ;
wire [8:0]  sdr_rd_col_addr ;
wire        sdr_rd_nCAS ;
wire        sdr_rd_nCS ;
wire        sdr_rd_nRAS ;
wire        sdr_rd_nWE ;
wire [12:0] sdr_rd_row_addr ;
wire [15:0] sdr_rdata;
wire [4:0] sdr_rdata_filled_depth;
wire [15:0] sdr_rdata_out ;
wire sdr_rdata_ready;
wire [4:0] sdr_rdata_unfilled_depth;
wire sdr_rdata_wr;
wire [15:0] sdr_wdata ;
wire [4:0]  sdr_wdata_filled_depth ;
wire        sdr_wdata_rd ;
wire sdr_wdata_ready;
wire [12:0] sdr_wr_A ;
wire [1:0]  sdr_wr_BA ;
wire        sdr_wr_CKE ;
wire [15:0] sdr_wr_DQ ;
wire [1:0]  sdr_wr_DQM ;
wire [1:0]  sdr_wr_bank_addr ;
wire [8:0]  sdr_wr_col_addr ;
wire        sdr_wr_nCAS ;
wire        sdr_wr_nCS ;
wire        sdr_wr_nRAS ;
wire        sdr_wr_nWE ;
wire        sdr_wr_pausing;
wire [12:0] sdr_wr_row_addr ;
wire [3:0]  w_fifo_addr_r ;
wire [3:0]  w_fifo_addr_w ;
wire        w_fifo_empty ;
wire        w_fifo_full ;
wire        w_fifo_rd_r ;
wire        w_fifo_wr_w ;
wire        wr_exit ;
//}}}
//auto regs{{{
reg [12:0] sdr_A ;
reg [1:0]  sdr_BA ;
reg        sdr_CKE ;
reg [1:0]  sdr_DQM ;
reg        sdr_nCAS ;
reg        sdr_nCS ;
reg        sdr_nRAS ;
reg        sdr_nWE ;
reg [3:0]  sdr_state ;
reg [3:0]  sdr_state_nxt ;
//}}}
// End of automatic define

assign sdr_wr_bank_addr[1:0] = sdr_waddr[24:23];
assign sdr_wr_row_addr[12:0] = sdr_waddr[22:10];
assign sdr_wr_col_addr[8:0] = sdr_waddr[9:0];

assign sdr_rd_bank_addr[1:0] = sdr_raddr[24:23];
assign sdr_rd_row_addr[12:0] = sdr_raddr[22:10];
assign sdr_rd_col_addr[8:0] = sdr_raddr[9:0];

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_state[3:0] <= #`RD S_INIT;
    else 
        sdr_state[3:0] <= #`RD sdr_state_nxt;

always @(*) begin
    sdr_state_nxt[3:0] = sdr_state;
    case(sdr_state)
        S_INIT: if(init_done) sdr_state_nxt = S_IDLE;
        S_IDLE: if(sdr_wr_req | sdr_wr_pausing) sdr_state_nxt = S_WRITE;
                else if(sdr_rd_req) sdr_state_nxt = S_READ;
        S_WRITE: if(wr_exit) sdr_state_nxt = S_IDLE;
        S_READ: if(rd_exit) sdr_state_nxt = S_IDLE;
        S_AREF: if(aref_done) sdr_state_nxt = S_IDLE;
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
            sdr_CKE = sdr_rd_CKE;
            sdr_nCS = sdr_rd_nCS;
            sdr_BA[1:0] = sdr_rd_BA;
            sdr_A[12:0] = sdr_rd_A;
            sdr_nRAS = sdr_rd_nRAS;
            sdr_nCAS = sdr_rd_nCAS;
            sdr_nWE = sdr_rd_nWE;
            sdr_DQM[1:0] = sdr_rd_DQM;
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

assign sdr_wr_ready = ~w_fifo_full;

regfile_2p_16x16 u_w_regfile_2p_16x16(/*autoinst*/
        .CLKB      ( clk                ),    //I         u_w_regfile_2p_16x16    
        .CENB      ( ~w_fifo_wr_w       ),    //I         u_w_regfile_2p_16x16    
        .WENB      ( ~w_fifo_wr_w       ),    //I         u_w_regfile_2p_16x16    
        .AB        ( w_fifo_addr_w[3:0] ),    //I  [3:0]  u_w_regfile_2p_16x16    
        .DB        ( sdr_wdata_in[15:0] ),    //I  [15:0] u_w_regfile_2p_16x16    
        .testmodep ( 1'b0               ),    //I         u_w_regfile_2p_16x16    
        .CLKA      ( clk                ),    //I         u_w_regfile_2p_16x16    
        .CENA      ( ~w_fifo_rd_r       ),    //I         u_w_regfile_2p_16x16    
        .AA        ( w_fifo_addr_r[3:0] ),    //I  [3:0]  u_w_regfile_2p_16x16    
        .QA        ( sdr_wdata[15:0]    )     //O  [15:0] u_w_regfile_2p_16x16    
);

sfifo_ctrl_typ2 #(.FIFO_DEPTH(4)) u_w_sfifo_ctrl_typ2(/*autoinst*/
        .clk_fifo          ( clk                             ),    //I             u_w_sfifo_ctrl_typ2    
        .rst_fifo_n        ( rst_n                           ),    //I             u_w_sfifo_ctrl_typ2    
        .fifo_af_lvl       ( 4'h8                            ),    //I  [FIFO_DEPTH-1:0] u_w_sfifo_ctrl_typ2    
        .fifo_ae_lvl       ( 4'h0                            ),    //I  [FIFO_DEPTH-1:0] u_w_sfifo_ctrl_typ2    
        .fifo_clr          ( 1'b0                            ),    //I             u_w_sfifo_ctrl_typ2    
        .fifo_req_w        ( sdr_wdata_wr                    ),    //I             u_w_sfifo_ctrl_typ2    
        .fifo_req_r        ( sdr_wdata_rd                    ),    //I             u_w_sfifo_ctrl_typ2    
        .fifo_wr_w         ( w_fifo_wr_w                     ),    //O             u_w_sfifo_ctrl_typ2    
        .fifo_rd_r         ( w_fifo_rd_r                     ),    //O             u_w_sfifo_ctrl_typ2    
        .fifo_addr_w       ( w_fifo_addr_w[3:0]              ),    //O  [FIFO_DEPTH-1:0] u_w_sfifo_ctrl_typ2    
        .fifo_addr_r       ( w_fifo_addr_r[3:0]              ),    //O  [FIFO_DEPTH-1:0] u_w_sfifo_ctrl_typ2    
        .fifo_af           (                                 ),    //O             u_w_sfifo_ctrl_typ2    
        .fifo_ae           (                                 ),    //O             u_w_sfifo_ctrl_typ2    
        .fifo_full         ( w_fifo_full                     ),    //O             u_w_sfifo_ctrl_typ2    
        .fifo_empty        ( w_fifo_empty                    ),    //O             u_w_sfifo_ctrl_typ2    
        .fifo_filled_depth ( sdr_wdata_filled_depth[3:0]     ),    //O  [FIFO_DEPTH:0] u_w_sfifo_ctrl_typ2    
        .fifo_waddr        (                                 ),    //O  [FIFO_DEPTH:0] u_w_sfifo_ctrl_typ2    
        .fifo_raddr        (                                 )     //O  [FIFO_DEPTH:0] u_w_sfifo_ctrl_typ2    
);

sdr_init u_sdr_init(/*autoinst*/
        .clk       ( clk               ),    //I         u_sdr_init    
        .rst_n     ( rst_n             ),    //I         u_sdr_init    
        .sdr_CKE   ( sdr_init_CKE      ),    //O         u_sdr_init    
        .sdr_nCS   ( sdr_init_nCS      ),    //O         u_sdr_init    
        .sdr_BA    ( sdr_init_BA[1:0]  ),    //O  [1:0]  u_sdr_init    
        .sdr_A     ( sdr_init_A[12:0]  ),    //O  [12:0] u_sdr_init    
        .sdr_nRAS  ( sdr_init_nRAS     ),    //O         u_sdr_init    
        .sdr_nCAS  ( sdr_init_nCAS     ),    //O         u_sdr_init    
        .sdr_nWE   ( sdr_init_nWE      ),    //O         u_sdr_init    
        .sdr_DQM   ( sdr_init_DQM[1:0] ),    //O  [1:0]  u_sdr_init    
        .init_done ( init_done         )     //O         u_sdr_init    
);

sdr_wr u_sdr_wr(/*autoinst*/
        .clk                    ( clk                         ),    //I         u_sdr_wr    
        .rst_n                  ( rst_n                       ),    //I         u_sdr_wr    
        .sdr_CKE                ( sdr_wr_CKE                  ),    //O         u_sdr_wr    
        .sdr_nCS                ( sdr_wr_nCS                  ),    //O         u_sdr_wr    
        .sdr_BA                 ( sdr_wr_BA[1:0]              ),    //O  [1:0]  u_sdr_wr    
        .sdr_A                  ( sdr_wr_A[12:0]              ),    //O  [12:0] u_sdr_wr    
        .sdr_nRAS               ( sdr_wr_nRAS                 ),    //O         u_sdr_wr    
        .sdr_nCAS               ( sdr_wr_nCAS                 ),    //O         u_sdr_wr    
        .sdr_nWE                ( sdr_wr_nWE                  ),    //O         u_sdr_wr    
        .sdr_DQ                 ( sdr_wr_DQ[15:0]             ),    //IO [15:0] u_sdr_wr    
        .sdr_DQM                ( sdr_wr_DQM[1:0]             ),    //O  [1:0]  u_sdr_wr    
        .sdr_wr_req             ( sdr_wr_req                  ),    //I         u_sdr_wr    
        .sdr_wr_byte_cnt        ( sdr_wr_byte_cnt[11:0]       ),    //I  [11:0] u_sdr_wr    
        .sdr_bank_addr          ( sdr_wr_bank_addr[1:0]       ),    //I  [1:0]  u_sdr_wr    
        .sdr_row_addr           ( sdr_wr_row_addr[12:0]       ),    //I  [12:0] u_sdr_wr    
        .sdr_col_addr           ( sdr_wr_col_addr[8:0]        ),    //I  [8:0]  u_sdr_wr    
        .wr_exit                ( wr_exit                     ),    //O         u_sdr_wr    
        .sdr_wdata_filled_depth ( sdr_wdata_filled_depth[3:0] ),    //I  [3:0]  u_sdr_wr    
        .sdr_wdata_rd           ( sdr_wdata_rd                ),    //O         u_sdr_wr    
        .sdr_wdata              ( sdr_wdata[15:0]             ),    //I  [15:0] u_sdr_wr    
        .need_ref               ( aref_req                    ),    //I         u_sdr_wr    
        .sdr_wr_pausing         ( sdr_wr_pausing              )     //O         u_sdr_wr    
);

sdr_rd u_sdr_rd(/*autoinst*/
        .clk           ( clk                   ),    //I         u_sdr_rd    
        .rst_n         ( rst_n                 ),    //I         u_sdr_rd    
        .sdr_CKE       ( sdr_rd_CKE            ),    //O         u_sdr_rd    
        .sdr_nCS       ( sdr_rd_nCS            ),    //O         u_sdr_rd    
        .sdr_BA        ( sdr_rd_BA[1:0]        ),    //O  [1:0]  u_sdr_rd    
        .sdr_A         ( sdr_rd_A[12:0]        ),    //O  [12:0] u_sdr_rd    
        .sdr_nRAS      ( sdr_rd_nRAS           ),    //O         u_sdr_rd    
        .sdr_nCAS      ( sdr_rd_nCAS           ),    //O         u_sdr_rd    
        .sdr_nWE       ( sdr_rd_nWE            ),    //O         u_sdr_rd    
        .sdr_DQ        ( sdr_rd_DQ[15:0]       ),    //IO [15:0] u_sdr_rd    
        .sdr_DQM       ( sdr_rd_DQM[1:0]       ),    //O  [1:0]  u_sdr_rd    
        .sdr_rd_req    ( sdr_rd_req            ),    //I         u_sdr_rd    
        .sdr_bank_addr ( sdr_rd_bank_addr[1:0] ),    //I  [1:0]  u_sdr_rd    
        .sdr_row_addr  ( sdr_rd_row_addr[12:0] ),    //I  [12:0] u_sdr_rd    
        .sdr_col_addr  ( sdr_rd_col_addr[8:0]  ),    //I  [8:0]  u_sdr_rd    
        .rd_exit       ( rd_exit               ),    //O         u_sdr_rd    
        .sdr_rdata_unfilled_depth (sdr_rdata_unfilled_depth[4:0]),
        .sdr_rd_byte_cnt (sdr_rd_byte_cnt[11:0]),
        .sdr_rdata_wr (sdr_rdata_wr),
        .sdr_rdata  (sdr_rdata[15:0])
);

assign sdr_rdata_unfilled_depth = (5'd16 - sdr_rdata_filled_depth);
assign sdr_DQ[15:0] = (sdr_state == S_WRITE) ? sdr_wr_DQ : 16'hz;

endmodule
//verilog-library-directories(".")
