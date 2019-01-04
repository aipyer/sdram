//============================================================
//       File Name:  sdr_top.v
//          Author:  Kody He
//          E-Mail:  kody.he@hotmail.com
//   First Created:  2019-01-04 22:22
//   Last Modified:  2019-01-04 22:22
//
//     Description:  
//
//============================================================

module sdr_top(/*autoarg*/);

//port decleration
input                 clk         ;  //clock, 167MHz
input                 rst_n       ;  //reset

output                sdr_CKE     ;
output                sdr_nCS      ;
output      [1:0]     sdr_BA      ;
output      [11:0]    sdr_A       ;
output                sdr_nRAS    ;
output                sdr_nCAS    ;
output                sdr_nWE     ;
inout       [15:0]    sdr_DQ      ;

    //parameter decleration
    localparam S_POWER_ON = 4'h0;
    localparam S_PRECHARGE = 4'h1;
    localparam S_IDLE = 4'h2;
    localparam S_AUTO_REFRESH = 4'h3;
    localparam S_LMR = 4'h4;
    localparam S_POWER_DONN = 4'h5;
    localparam S_ROW_ACTIVE = 4'h6;
    localparam S_ACTIVE_PD = 4'h7;
    localparam S_WRITE = 4'h8;
    localparam S_WRITE_SUSPEND = 4'h9;
    localparam S_READ = 4'ha;
    localparam S_READ_SUSPEND = 4'hb;

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
    //localparam tREF = 

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        base_cnt <= #`RD 16'h0;
    else if(init_done)
        base_cnt <= #`RD 16'h0;
    else if(precharge_done)
        base_cnt <= #`RD 16'h0;
    else if(base_cnt_en)
        base_cnt <= #`RD base_cnt + 16'h1;

assign init_done = (base_cnt == 16'd166_67) & (sdr_state == S_POWER_ON);
assign precharge_done = (base_cnt == tRP) & (sdr_state == S_PRECHARGE);
assign auto_refresh_done = (base_cnt == tRFC) & ((sdr_state == S_AUTO_REFRESH) | (sdr_state == S_AUTO_REFRESH_2));

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        sdr_state[3:0] <= #`RD S_POWER_ON;
    else
        sdr_state[3:0] <= #`RD sdr_state_nxt;

always @(*) begin
    sdr_state_nxt[3:0] = sdr_state;
    case(sdr_state_nxt)
        S_POWER_ON: if(init_done) sdr_state = S_PRECHARGE;
        S_PRECHARGE: if(precharge_done) sdr_state = S_AUTO_REFRESH;
        S_AUTO_REFRESH: if(auto_refresh_done) sdr_state = S_AUTO_REFRESH_2;
        S_AUTO_REFRESH_2: if(auto_refresh_done) sdr_state = S_LMR;
    endcase
end

always @(posedge clk or negedge rst_n)
    if(!rst_n)
        {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_NOP;
    else
        case({sdr_state, sdr_state_nxt})
            {S_POWER_ON, S_POWER_ON}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_NOP;
            {S_POWER_ON, S_PRECHARGE}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_PRECHARGE;
            {S_PRECHARGE, S_AUTO_REFRESH}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_AUTO_REFRESH;
            {S_AUTO_REFRESH, S_AUTO_REFRESH_2}: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_AUTO_REFRESH;

            default: {sdr_nRAS, sdr_nCAS, sdr_nWE} <= #`RD CMD_NOP;
        endcase


always @(posedge clk or negedge rst_n)
    if(!rst_n)



endmodule
