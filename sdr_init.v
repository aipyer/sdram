//============================================================
//       File Name:  sdr_init.v
//          Author:  Kody He
//          E-Mail:  kody.he@hotmail.com
//   First Created:  2019-01-04 22:22
//   Last Modified:  2019-01-04 22:22
//
//     Description:  
//
//============================================================

module sdr_init(/*autoarg*/);

//port decleration
input                 clk         ;  //clock, 167MHz
input                 rst_n       ;  //reset

//sdr 
output                sdr_CKE     ;
output                sdr_nCS      ;
output      [1:0]     sdr_BA      ;
output      [12:0]    sdr_A       ;
output                sdr_nRAS    ;
output                sdr_nCAS    ;
output                sdr_nWE     ;
output      [1:0]   sdr_DQM;

//
output  init_done;

    //parameter decleration
localparam S_IDLE = 4'h0;
localparam S_POWER_ON = 4'h1;
localparam S_PRECHARGE = 4'h2;
localparam S_AUTO_REFRESH = 4'h3;
localparam S_AUTO_REFRESH_2 = 4'h4;
localparam S_LMR = 4'h5;

localparam CMD_NOP = 3'b111;
localparam CMD_ACTIVE = 3'b011;
localparam CMD_READ = 3'b101;
localparam CMD_WRITE = 3'b100;
localparam CMD_BURST_TERM = 3'b110;
localparam CMD_PRECHARGE = 3'b010;
localparam CMD_AUTO_REFRESH = 3'b001;
localparam CMD_LMR = 3'b000;

localparam tCK = 1;
localparam tRAS = 7;
localparam tRC = 10;
localparam tRFC = 10;
localparam tRP = 18;
localparam tRRD = 2;
localparam tWR = 2;
localparam tMRD = 2;
//localparam tREF = 
//

/*autodefine*/

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        base_cnt[15:0] <= #`RD 16'h0;
    else if(power_on_done | precharge_done | auto_refresh_done | load_mode_reg_done)
        base_cnt <= #`RD 16'h0;
    else if(base_cnt_en)
        base_cnt <= #`RD base_cnt + 16'h1;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        base_cnt_en <= #`RD 1'h0;
    else if(init_req)
        base_cnt_en <= #`RD 1'h1;
    else if(init_done)
        base_cnt_en <= #`RD 1'h0;

assign power_on_done = (base_cnt == 16'd166_67) & (sdr_init_state == S_POWER_ON);
assign precharge_done = (base_cnt == tRP) & (sdr_init_state == S_PRECHARGE);
assign auto_refresh_done = (base_cnt == tRFC) & ((sdr_init_state == S_AUTO_REFRESH) | (sdr_init_state == S_AUTO_REFRESH_2));
assign load_mode_reg_done = (base_cnt == tMRD) & (sdr_init_state == S_LMR);
assign sdr_init_done = (sdr_init_state == S_LMR) & (sdr_init_state_nxt == S_IDLE);

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        init_req <= #`RD 1'b1;
    else
        init_req <= #`RD 1'b0;

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_init_state[3:0] <= #`RD S_IDLE;
    else
        sdr_init_state[3:0] <= #`RD sdr_init_state_nxt;

always @(*) begin
    sdr_init_state_nxt[3:0] = sdr_init_state;
    case(sdr_init_state)
        S_IDLE: if(init_req) sdr_init_state_nxt = S_POWER_ON;
        S_POWER_ON: if(power_on_done) sdr_init_state_nxt = S_PRECHARGE;
        S_PRECHARGE: if(precharge_done) sdr_init_state_nxt = S_AUTO_REFRESH;
        S_AUTO_REFRESH: if(auto_refresh_done) sdr_init_state_nxt = S_AUTO_REFRESH_2;
        S_AUTO_REFRESH_2: if(auto_refresh_done) sdr_init_state_nxt = S_LMR;
        S_LMR: if(load_mode_reg_done) sdr_init_state_nxt = S_IDLE;
        default: sdr_init_state_nxt = S_IDLE;
    endcase
end

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_NOP;
    else
        case({sdr_init_state, sdr_init_state_nxt})
            {S_POWER_ON, S_PRECHARGE}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_PRECHARGE;
            {S_PRECHARGE, S_AUTO_REFRESH}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_AUTO_REFRESH;
            {S_AUTO_REFRESH, S_AUTO_REFRESH_2}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_AUTO_REFRESH;
            {S_AUTO_REFRESH_2, S_LMR}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_LMR;
            default: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_NOP;
        endcase


always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_A[12:0] <= #`RD 13'h0;
    else if({sdr_init_state, sdr_init_state_nxt} == {S_POWER_ON, S_PRECHARGE})
        sdr_A <= #`RD {2'h0, 1'h1, 10'h0};
    else if({sdr_init_state, sdr_init_state_nxt} == {S_AUTO_REFRESH_2, S_LMR})
        sdr_A <= #`RD {3'h0, 1'h0, 2'h0, 3'h3, 1'h0, 3'h2}; // WB=0, CL=3, BT=0, BL=4

assign sdr_BA = 2'h0;
assign sdr_DQM = 2'h0;
assign sdr_CKE = 1'b1;
assign sdr_nCS = 1'b0;

endmodule
