`timescale 1ns/10ps

module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output         busy;
output         valid;
output [127:0] iot_out;

reg valid_w;
//reg valid_r;
reg [127:0]iot_out_w;
//reg [127:0]iot_out_r;


reg [7:0]REG [0:15];
reg [4:0]ind;
reg [4:0]enc_count;
integer i ; 
wire [31:0]s_out;//原本是reg
wire [31:0]f_out;

//assign busy=(in_en)?0:1;
//assign busy=(ind==5'b01111||(fn_sel==1||fn_sel==2)&|enc_count[3:0])?1:0;
assign busy=(&ind[3:0]||ind==5'b10000)?1:0;
assign iot_out=iot_out_w;
assign valid=valid_w;
wire [63:0]in_R;

wire [55:0]PC1_R;
//reg [55:0]PC1_res;
reg [55:0]subk;
reg [47:0]out_x;
reg [31:0]out_w;

wire [47:0]exp_r;

wire [47:0]k_1;

wire [27:0]CIR_R1;
wire [27:0]CIR_L1;
reg [27:0]CIR_IR_P;
reg [27:0]CIR_IL_P;

wire [63:0] per_in;
reg [63:0]in_FP;


wire [27:0]CIR_R_R1;
wire [27:0]CIR_R_L1;
//reg [27:0]CIR_R_IR_P;
//reg [27:0]CIR_R_IL_P;

wire [7:0]Btg_out;
reg in_bit0;

wire [63:0]FP_out;

wire [7:0]Gtb_out;
reg G_in_bit0;

wire [2:0]CRC_out;
reg [2:0]C_in_bit;
//vcs -f rtl_01.f -full64 -R +v2k -sverilog -v2005 -debug_access+all +define+p1+F | tee rtl_F1.log

reg [3:0]CRC_res_1;
reg [3:0]CRC_res_2;
reg [3:0]CRC_res_3;
always@(*)begin
    if(ind==5'b10000)begin
        case(fn_sel)
            3'b001:begin
                out_x=k_1^exp_r;
                CRC_res_3=0;
                if(enc_count==0)
                    out_w=f_out^per_in[63:32];
                else
                    out_w=f_out^{REG[8],REG[9],REG[10],REG[11]};
            end
            3'b010:begin
                out_x=k_1^exp_r;
                CRC_res_3=0;
                if(enc_count==0)
                    out_w=f_out^per_in[63:32];
                else
                    out_w=f_out^{REG[8],REG[9],REG[10],REG[11]};
            end
            3'b011:begin
                CRC_res_1=(REG[15][2]==1)?{REG[15][2:0],1'b0}^4'b1011:{REG[15][2:0],1'b0};
                CRC_res_2=(CRC_res_1[2]==1)?{CRC_res_1[2:0],1'b0}^4'b1011:{CRC_res_1[1:0],1'b0};//注意後面那項位數一定要指定
                CRC_res_3=(CRC_res_2[2]==1)?{CRC_res_2[2:0],1'b0}^4'b1011:{CRC_res_2[1:0],1'b0};
                out_x=0;
                out_w=0;
            end
            default:begin
                out_x=0;
                out_w=0;
                CRC_res_3=0;
            end
        endcase
    end
    else begin
                out_x=0;
                out_w=0;
                CRC_res_3=0;
    end
end

always@(posedge clk or posedge rst)begin
    if(rst)begin
        ind<=5'b0;
        enc_count<=0;
        CIR_IR_P<=0;
        CIR_IL_P<=0;
        in_bit0<=0;
        for(i=0;i<16;i=i+1)begin
            REG[i]<=0;
        end
    end
    else if(ind==5'b10000)begin
        case(fn_sel)
            3'b001:begin
                CIR_IR_P<=CIR_R1;
                CIR_IL_P<=CIR_L1;
                enc_count<=enc_count+1;
                if(enc_count==16)begin
                    ind<=0;
                    enc_count<=0;
                end
                if(&enc_count[3:0])begin
                    {REG[8],REG[9],REG[10],REG[11]}<=out_w;
                end
                else begin
                    {REG[12],REG[13],REG[14],REG[15]}<=out_w;
                    if(enc_count==0)
                        {REG[8],REG[9],REG[10],REG[11]}<=per_in[31:0];
                    else 
                        {REG[8],REG[9],REG[10],REG[11]}<={REG[12],REG[13],REG[14],REG[15]};
                end
            end
            3'b010:begin
                CIR_IR_P<=CIR_R_R1;
                CIR_IL_P<=CIR_R_L1;
                enc_count<=enc_count+1;
                if(enc_count==16)begin
                    //in_FP<={REG[8],REG[9],REG[10],REG[11],REG[12],REG[13],REG[14],REG[15]};
                    //valid_w<=1;
                    ind<=0;
                    enc_count<=0;
                end
                if(enc_count==5'b01111)begin
                    {REG[8],REG[9],REG[10],REG[11]}<=out_w;
                end
                else begin
                    {REG[12],REG[13],REG[14],REG[15]}<=out_w;
                    if(enc_count==0)
                        {REG[8],REG[9],REG[10],REG[11]}<=per_in[31:0];
                    else 
                        {REG[8],REG[9],REG[10],REG[11]}<={REG[12],REG[13],REG[14],REG[15]};
                end
            end
            3'b011:begin
                //valid_w<=1;
                ind<=0;
            end
            3'b100:begin
                //valid_w<=1;
                ind<=0;
            end
            3'b101:begin
                //valid_w<=1;
                ind<=0;
            end
            default:begin
                //valid_w<=1;
                ind<=0;
                enc_count<=0;
            end
        endcase
    end
    else if(in_en)begin
        if (fn_sel==3)begin
            REG[ind[3:0]]<=CRC_out;
            ind<=ind+1;
        end
        else if(fn_sel==4)begin//改case應該比較好
            in_bit0<=iot_in[0];
            REG[ind[3:0]]<=Btg_out;
            ind<=ind+1;
        end
        else if(fn_sel==5)begin
            //in_bit0<=(ind==0)?in_bit0:REG[ind-1][7]
            REG[ind[3:0]]<=Gtb_out;
            ind<=ind+1;
        end
        else begin
            REG[ind[3:0]]<=iot_in;
            ind<=ind+1;
        end
    end
    else begin
        //valid_w<=0;
    end
end
always@(*)begin
    G_in_bit0=(ind==0)?0:REG[ind[3:0]-1][0];
    C_in_bit=(ind==0)?0:REG[ind[3:0]-1][2:0];
    in_FP=0;
    if(ind==5'b10000)begin
        case(fn_sel)
            3'b001:begin
                iot_out_w={REG[0],REG[1],REG[2],REG[3],REG[4],REG[5],REG[6],REG[7],FP_out};
                if(enc_count==16)begin
                    in_FP={REG[8],REG[9],REG[10],REG[11],REG[12],REG[13],REG[14],REG[15]};
                    valid_w=1;
                end
                else begin
                valid_w=0;
                in_FP=0;
                end
            end
            3'b010:begin
            iot_out_w={REG[0],REG[1],REG[2],REG[3],REG[4],REG[5],REG[6],REG[7],FP_out};
                if(enc_count==16)begin
                    in_FP={REG[8],REG[9],REG[10],REG[11],REG[12],REG[13],REG[14],REG[15]};
                    valid_w=1;
                end
                else begin
                valid_w=0;
                in_FP=0;
                end
            end
            3'b011:begin
                iot_out_w=CRC_res_3;
                valid_w=1;
            end
            3'b100:begin
                iot_out_w={REG[0],REG[1],REG[2],REG[3],REG[4],REG[5],REG[6],REG[7],REG[8],REG[9],REG[10],REG[11],REG[12],REG[13],REG[14],REG[15]};
                valid_w=1;
            end
            3'b101:begin 
                iot_out_w={REG[0],REG[1],REG[2],REG[3],REG[4],REG[5],REG[6],REG[7],REG[8],REG[9],REG[10],REG[11],REG[12],REG[13],REG[14],REG[15]};
                valid_w=1;
            end
            default:begin
                iot_out_w=0;
                valid_w=0;
            end
        endcase
    end
    else begin
        valid_w=0;
        iot_out_w=0;
        in_FP=0;
    end
end
//always@(posedge clk or posedge rst)begin
//    if(rst)begin
//        valid_r<=0;
//        iot_out_r<=0;
//    end
//    else begin
//        valid_r<=valid_w;
//        //iot_out_r<={REG[0],REG[1],REG[2],REG[3],REG[4],REG[5],REG[6],REG[7],iot_out_w};
//        iot_out_r<=iot_out_w;
//    end
//end
////key//////////////////
PC1_2 PC1_a(
    .in({REG[0],REG[1],REG[2],REG[3],REG[4],REG[5],REG[6],REG[7]}),
    .out(PC1_R)
);
wire [27:0]CIR_IR;
wire [27:0]CIR_IL;
assign CIR_IR=(enc_count==0)?PC1_R[27:0]:CIR_IR_P;
assign CIR_IL=(enc_count==0)?PC1_R[55:28]:CIR_IL_P;
///cirular shift////
CIR CIR_1(
    .enc_count(enc_count),
    .in(CIR_IR),
    .out(CIR_R1)
);
CIR CIR_2(
    .enc_count(enc_count),
    .in(CIR_IL),
    .out(CIR_L1)
);

//wire [27:0]CIR_R_IR;
//wire [27:0]CIR_R_IL;
//assign CIR_R_IR=(enc_count==0)?PC1_R[27:0]:CIR_R_IR_P;
//assign CIR_R_IL=(enc_count==0)?PC1_R[55:28]:CIR_R_IL_P;//可能可以省
CIR_R CIR_RR1(
    .enc_count(enc_count),
    .in(CIR_IR),
    .out(CIR_R_R1)
);
CIR_R CIR_RR2(
    .enc_count(enc_count),
    .in(CIR_IL),
    .out(CIR_R_L1)
);
/////pc2////
wire [55:0]CIR_res_1;
assign CIR_res_1=(fn_sel==1)?{CIR_L1,CIR_R1}:{CIR_R_L1,CIR_R_R1};
PC2_2 PC2_1(
    .in(CIR_res_1),
    .out(k_1)
);



/// text////

IP_2 IP1(
    .in({REG[8],REG[9],REG[10],REG[11],REG[12],REG[13],REG[14],REG[15]}),
    .out(per_in)
);

wire [31:0]F_in;
assign F_in=(enc_count==0)?per_in[31:0]:{REG[12],REG[13],REG[14],REG[15]};

EXP exp(
    .in(F_in),//[31:0]
    .out(exp_r)  
);


sbox1 s1(
    .in(out_x[47:42]),
    .out(s_out[31:28])
);
sbox2 s2(
    .in(out_x[41:36]),
    .out(s_out[27:24])
);
sbox3 s3(
    .in(out_x[35:30]),
    .out(s_out[23:20])
);
sbox4 s4(
    .in(out_x[29:24]),
    .out(s_out[19:16])
);

sbox5 s5(
    .in(out_x[23:18]),
    .out(s_out[15:12])
);
sbox6 s6(
    .in(out_x[17:12]),
    .out(s_out[11:8])
);
sbox7 s7(
    .in(out_x[11:6]),
    .out(s_out[7:4])
);
sbox8 s8(
    .in(out_x[5:0]),
    .out(s_out[3:0])
);
//reg [63:0]iot_out_w1;
P_2 p(
    .in(s_out),
    .out(f_out)
);
FP FP1(
    .in(in_FP),
    .out(FP_out)
);
/// BtoG///
BtoG btg(
    .ind(ind),
    .REG_8(in_bit0),//可能有問題
    .in(iot_in),
    .out(Btg_out)
);
GtoB gtb(
    .ind(ind),
    .REG_8(G_in_bit0),
    .in(iot_in),
    .out(Gtb_out)//感覺可以共用？
);

CRC crc(
    .ind(ind),
    .REG_8(C_in_bit),
    .in(iot_in),
    .out(CRC_out)
);
endmodule




module PC1_2(input [63:0] in, output [55:0] out);
  assign out[0] = in[60];
  assign out[1] = in[52];
  assign out[2] = in[44];
  assign out[3] = in[36];
  assign out[4] = in[59];
  assign out[5] = in[51];
  assign out[6] = in[43];
  assign out[7] = in[35];
  assign out[8] = in[27];
  assign out[9] = in[19];
  assign out[10] = in[11];
  assign out[11] = in[3];
  assign out[12] = in[58];
  assign out[13] = in[50];
  assign out[14] = in[42];
  assign out[15] = in[34];
  assign out[16] = in[26];
  assign out[17] = in[18];
  assign out[18] = in[10];
  assign out[19] = in[2];
  assign out[20] = in[57];
  assign out[21] = in[49];
  assign out[22] = in[41];
  assign out[23] = in[33];
  assign out[24] = in[25];
  assign out[25] = in[17];
  assign out[26] = in[9];
  assign out[27] = in[1];
  assign out[28] = in[28];
  assign out[29] = in[20];
  assign out[30] = in[12];
  assign out[31] = in[4];
  assign out[32] = in[61];
  assign out[33] = in[53];
  assign out[34] = in[45];
  assign out[35] = in[37];
  assign out[36] = in[29];
  assign out[37] = in[21];
  assign out[38] = in[13];
  assign out[39] = in[5];
  assign out[40] = in[62];
  assign out[41] = in[54];
  assign out[42] = in[46];
  assign out[43] = in[38];
  assign out[44] = in[30];
  assign out[45] = in[22];
  assign out[46] = in[14];
  assign out[47] = in[6];
  assign out[48] = in[63];
  assign out[49] = in[55];
  assign out[50] = in[47];
  assign out[51] = in[39];
  assign out[52] = in[31];
  assign out[53] = in[23];
  assign out[54] = in[15];
  assign out[55] = in[7];
endmodule

module PC2_2(input [55:0] in, output [47:0] out);
  assign out[0] = in[24];
  assign out[1] = in[27];
  assign out[2] = in[20];
  assign out[3] = in[6];
  assign out[4] = in[14];
  assign out[5] = in[10];
  assign out[6] = in[3];
  assign out[7] = in[22];
  assign out[8] = in[0];
  assign out[9] = in[17];
  assign out[10] = in[7];
  assign out[11] = in[12];
  assign out[12] = in[8];
  assign out[13] = in[23];
  assign out[14] = in[11];
  assign out[15] = in[5];
  assign out[16] = in[16];
  assign out[17] = in[26];
  assign out[18] = in[1];
  assign out[19] = in[9];
  assign out[20] = in[19];
  assign out[21] = in[25];
  assign out[22] = in[4];
  assign out[23] = in[15];
  assign out[24] = in[54];
  assign out[25] = in[43];
  assign out[26] = in[36];
  assign out[27] = in[29];
  assign out[28] = in[49];
  assign out[29] = in[40];
  assign out[30] = in[48];
  assign out[31] = in[30];
  assign out[32] = in[52];
  assign out[33] = in[44];
  assign out[34] = in[37];
  assign out[35] = in[33];
  assign out[36] = in[46];
  assign out[37] = in[35];
  assign out[38] = in[50];
  assign out[39] = in[41];
  assign out[40] = in[28];
  assign out[41] = in[53];
  assign out[42] = in[51];
  assign out[43] = in[55];
  assign out[44] = in[32];
  assign out[45] = in[45];
  assign out[46] = in[39];
  assign out[47] = in[42];
endmodule

module EXP(input [31:0] in, output [47:0] out);
  assign out[0] = in[31];
  assign out[1] = in[0];
  assign out[2] = in[1];
  assign out[3] = in[2];
  assign out[4] = in[3];
  assign out[5] = in[4];
  assign out[6] = in[3];
  assign out[7] = in[4];
  assign out[8] = in[5];
  assign out[9] = in[6];
  assign out[10] = in[7];
  assign out[11] = in[8];
  assign out[12] = in[7];
  assign out[13] = in[8];
  assign out[14] = in[9];
  assign out[15] = in[10];
  assign out[16] = in[11];
  assign out[17] = in[12];
  assign out[18] = in[11];
  assign out[19] = in[12];
  assign out[20] = in[13];
  assign out[21] = in[14];
  assign out[22] = in[15];
  assign out[23] = in[16];
  assign out[24] = in[15];
  assign out[25] = in[16];
  assign out[26] = in[17];
  assign out[27] = in[18];
  assign out[28] = in[19];
  assign out[29] = in[20];
  assign out[30] = in[19];
  assign out[31] = in[20];
  assign out[32] = in[21];
  assign out[33] = in[22];
  assign out[34] = in[23];
  assign out[35] = in[24];
  assign out[36] = in[23];
  assign out[37] = in[24];
  assign out[38] = in[25];
  assign out[39] = in[26];
  assign out[40] = in[27];
  assign out[41] = in[28];
  assign out[42] = in[27];
  assign out[43] = in[28];
  assign out[44] = in[29];
  assign out[45] = in[30];
  assign out[46] = in[31];
  assign out[47] = in[0];
endmodule

module sbox1(input [5:0] in, output reg[3:0] out);
    always@(*) begin
        case (in)
        6'd0 : out = 14;
        6'd1 : out = 0;
        6'd2 : out = 4;
        6'd3 : out = 15;
        6'd4 : out = 13;
        6'd5 : out = 7;
        6'd6 : out = 1;
        6'd7 : out = 4;
        6'd8 : out = 2;
        6'd9 : out = 14;
        6'd10 : out = 15;
        6'd11 : out = 2;
        6'd12 : out = 11;
        6'd13 : out = 13;
        6'd14 : out = 8;
        6'd15 : out = 1;
        6'd16 : out = 3;
        6'd17 : out = 10;
        6'd18 : out = 10;
        6'd19 : out = 6;
        6'd20 : out = 6;
        6'd21 : out = 12;
        6'd22 : out = 12;
        6'd23 : out = 11;
        6'd24 : out = 5;
        6'd25 : out = 9;
        6'd26 : out = 9;
        6'd27 : out = 5;
        6'd28 : out = 0;
        6'd29 : out = 3;
        6'd30 : out = 7;
        6'd31 : out = 8;
        6'd32 : out = 4;
        6'd33 : out = 15;
        6'd34 : out = 1;
        6'd35 : out = 12;
        6'd36 : out = 14;
        6'd37 : out = 8;
        6'd38 : out = 8;
        6'd39 : out = 2;
        6'd40 : out = 13;
        6'd41 : out = 4;
        6'd42 : out = 6;
        6'd43 : out = 9;
        6'd44 : out = 2;
        6'd45 : out = 1;
        6'd46 : out = 11;
        6'd47 : out = 7;
        6'd48 : out = 15;
        6'd49 : out = 5;
        6'd50 : out = 12;
        6'd51 : out = 11;
        6'd52 : out = 9;
        6'd53 : out = 3;
        6'd54 : out = 7;
        6'd55 : out = 14;
        6'd56 : out = 3;
        6'd57 : out = 10;
        6'd58 : out = 10;
        6'd59 : out = 0;
        6'd60 : out = 5;
        6'd61 : out = 6;
        6'd62 : out = 0;
        6'd63 : out = 13;
        endcase
    end
endmodule

module sbox2(input [5:0] in, output reg[3:0] out);
    always @(*) begin
        case (in)
        6'd0 : out = 15;
        6'd1 : out = 3;
        6'd2 : out = 1;
        6'd3 : out = 13;
        6'd4 : out = 8;
        6'd5 : out = 4;
        6'd6 : out = 14;
        6'd7 : out = 7;
        6'd8 : out = 6;
        6'd9 : out = 15;
        6'd10 : out = 11;
        6'd11 : out = 2;
        6'd12 : out = 3;
        6'd13 : out = 8;
        6'd14 : out = 4;
        6'd15 : out = 14;
        6'd16 : out = 9;
        6'd17 : out = 12;
        6'd18 : out = 7;
        6'd19 : out = 0;
        6'd20 : out = 2;
        6'd21 : out = 1;
        6'd22 : out = 13;
        6'd23 : out = 10;
        6'd24 : out = 12;
        6'd25 : out = 6;
        6'd26 : out = 0;
        6'd27 : out = 9;
        6'd28 : out = 5;
        6'd29 : out = 11;
        6'd30 : out = 10;
        6'd31 : out = 5;
        6'd32 : out = 0;
        6'd33 : out = 13;
        6'd34 : out = 14;
        6'd35 : out = 8;
        6'd36 : out = 7;
        6'd37 : out = 10;
        6'd38 : out = 11;
        6'd39 : out = 1;
        6'd40 : out = 10;
        6'd41 : out = 3;
        6'd42 : out = 4;
        6'd43 : out = 15;
        6'd44 : out = 13;
        6'd45 : out = 4;
        6'd46 : out = 1;
        6'd47 : out = 2;
        6'd48 : out = 5;
        6'd49 : out = 11;
        6'd50 : out = 8;
        6'd51 : out = 6;
        6'd52 : out = 12;
        6'd53 : out = 7;
        6'd54 : out = 6;
        6'd55 : out = 12;
        6'd56 : out = 9;
        6'd57 : out = 0;
        6'd58 : out = 3;
        6'd59 : out = 5;
        6'd60 : out = 2;
        6'd61 : out = 14;
        6'd62 : out = 15;
        6'd63 : out = 9;
        endcase
    end
endmodule

module sbox3(input [5:0] in, output reg[3:0] out);
    always @(*) begin
        case (in)
        6'd0 : out = 10;
        6'd1 : out = 13;
        6'd2 : out = 0;
        6'd3 : out = 7;
        6'd4 : out = 9;
        6'd5 : out = 0;
        6'd6 : out = 14;
        6'd7 : out = 9;
        6'd8 : out = 6;
        6'd9 : out = 3;
        6'd10 : out = 3;
        6'd11 : out = 4;
        6'd12 : out = 15;
        6'd13 : out = 6;
        6'd14 : out = 5;
        6'd15 : out = 10;
        6'd16 : out = 1;
        6'd17 : out = 2;
        6'd18 : out = 13;
        6'd19 : out = 8;
        6'd20 : out = 12;
        6'd21 : out = 5;
        6'd22 : out = 7;
        6'd23 : out = 14;
        6'd24 : out = 11;
        6'd25 : out = 12;
        6'd26 : out = 4;
        6'd27 : out = 11;
        6'd28 : out = 2;
        6'd29 : out = 15;
        6'd30 : out = 8;
        6'd31 : out = 1;
        6'd32 : out = 13;
        6'd33 : out = 1;
        6'd34 : out = 6;
        6'd35 : out = 10;
        6'd36 : out = 4;
        6'd37 : out = 13;
        6'd38 : out = 9;
        6'd39 : out = 0;
        6'd40 : out = 8;
        6'd41 : out = 6;
        6'd42 : out = 15;
        6'd43 : out = 9;
        6'd44 : out = 3;
        6'd45 : out = 8;
        6'd46 : out = 0;
        6'd47 : out = 7;
        6'd48 : out = 11;
        6'd49 : out = 4;
        6'd50 : out = 1;
        6'd51 : out = 15;
        6'd52 : out = 2;
        6'd53 : out = 14;
        6'd54 : out = 12;
        6'd55 : out = 3;
        6'd56 : out = 5;
        6'd57 : out = 11;
        6'd58 : out = 10;
        6'd59 : out = 5;
        6'd60 : out = 14;
        6'd61 : out = 2;
        6'd62 : out = 7;
        6'd63 : out = 12;
        endcase
    end
endmodule

module sbox4(input [5:0] in, output reg[3:0] out);
    always @(*)begin
        case (in)
        6'd0 : out = 7;
        6'd1 : out = 13;
        6'd2 : out = 13;
        6'd3 : out = 8;
        6'd4 : out = 14;
        6'd5 : out = 11;
        6'd6 : out = 3;
        6'd7 : out = 5;
        6'd8 : out = 0;
        6'd9 : out = 6;
        6'd10 : out = 6;
        6'd11 : out = 15;
        6'd12 : out = 9;
        6'd13 : out = 0;
        6'd14 : out = 10;
        6'd15 : out = 3;
        6'd16 : out = 1;
        6'd17 : out = 4;
        6'd18 : out = 2;
        6'd19 : out = 7;
        6'd20 : out = 8;
        6'd21 : out = 2;
        6'd22 : out = 5;
        6'd23 : out = 12;
        6'd24 : out = 11;
        6'd25 : out = 1;
        6'd26 : out = 12;
        6'd27 : out = 10;
        6'd28 : out = 4;
        6'd29 : out = 14;
        6'd30 : out = 15;
        6'd31 : out = 9;
        6'd32 : out = 10;
        6'd33 : out = 3;
        6'd34 : out = 6;
        6'd35 : out = 15;
        6'd36 : out = 9;
        6'd37 : out = 0;
        6'd38 : out = 0;
        6'd39 : out = 6;
        6'd40 : out = 12;
        6'd41 : out = 10;
        6'd42 : out = 11;
        6'd43 : out = 1;
        6'd44 : out = 7;
        6'd45 : out = 13;
        6'd46 : out = 13;
        6'd47 : out = 8;
        6'd48 : out = 15;
        6'd49 : out = 9;
        6'd50 : out = 1;
        6'd51 : out = 4;
        6'd52 : out = 3;
        6'd53 : out = 5;
        6'd54 : out = 14;
        6'd55 : out = 11;
        6'd56 : out = 5;
        6'd57 : out = 12;
        6'd58 : out = 2;
        6'd59 : out = 7;
        6'd60 : out = 8;
        6'd61 : out = 2;
        6'd62 : out = 4;
        6'd63 : out = 14;
        endcase
    end
endmodule

module sbox5(input [5:0] in, output reg[3:0] out);
    always @(*)begin
        case (in)
        6'd0 : out = 2;
        6'd1 : out = 14;
        6'd2 : out = 12;
        6'd3 : out = 11;
        6'd4 : out = 4;
        6'd5 : out = 2;
        6'd6 : out = 1;
        6'd7 : out = 12;
        6'd8 : out = 7;
        6'd9 : out = 4;
        6'd10 : out = 10;
        6'd11 : out = 7;
        6'd12 : out = 11;
        6'd13 : out = 13;
        6'd14 : out = 6;
        6'd15 : out = 1;
        6'd16 : out = 8;
        6'd17 : out = 5;
        6'd18 : out = 5;
        6'd19 : out = 0;
        6'd20 : out = 3;
        6'd21 : out = 15;
        6'd22 : out = 15;
        6'd23 : out = 10;
        6'd24 : out = 13;
        6'd25 : out = 3;
        6'd26 : out = 0;
        6'd27 : out = 9;
        6'd28 : out = 14;
        6'd29 : out = 8;
        6'd30 : out = 9;
        6'd31 : out = 6;
        6'd32 : out = 4;
        6'd33 : out = 11;
        6'd34 : out = 2;
        6'd35 : out = 8;
        6'd36 : out = 1;
        6'd37 : out = 12;
        6'd38 : out = 11;
        6'd39 : out = 7;
        6'd40 : out = 10;
        6'd41 : out = 1;
        6'd42 : out = 13;
        6'd43 : out = 14;
        6'd44 : out = 7;
        6'd45 : out = 2;
        6'd46 : out = 8;
        6'd47 : out = 13;
        6'd48 : out = 15;
        6'd49 : out = 6;
        6'd50 : out = 9;
        6'd51 : out = 15;
        6'd52 : out = 12;
        6'd53 : out = 0;
        6'd54 : out = 5;
        6'd55 : out = 9;
        6'd56 : out = 6;
        6'd57 : out = 10;
        6'd58 : out = 3;
        6'd59 : out = 4;
        6'd60 : out = 0;
        6'd61 : out = 5;
        6'd62 : out = 14;
        6'd63 : out = 3;
        endcase
    end
endmodule

module sbox6(input [5:0] in, output reg[3:0] out);
    always @(*)begin
        case (in)
            6'd0 : out = 12;
            6'd1 : out = 10;
            6'd2 : out = 1;
            6'd3 : out = 15;
            6'd4 : out = 10;
            6'd5 : out = 4;
            6'd6 : out = 15;
            6'd7 : out = 2;
            6'd8 : out = 9;
            6'd9 : out = 7;
            6'd10 : out = 2;
            6'd11 : out = 12;
            6'd12 : out = 6;
            6'd13 : out = 9;
            6'd14 : out = 8;
            6'd15 : out = 5;
            6'd16 : out = 0;
            6'd17 : out = 6;
            6'd18 : out = 13;
            6'd19 : out = 1;
            6'd20 : out = 3;
            6'd21 : out = 13;
            6'd22 : out = 4;
            6'd23 : out = 14;
            6'd24 : out = 14;
            6'd25 : out = 0;
            6'd26 : out = 7;
            6'd27 : out = 11;
            6'd28 : out = 5;
            6'd29 : out = 3;
            6'd30 : out = 11;
            6'd31 : out = 8;
            6'd32 : out = 9;
            6'd33 : out = 4;
            6'd34 : out = 14;
            6'd35 : out = 3;
            6'd36 : out = 15;
            6'd37 : out = 2;
            6'd38 : out = 5;
            6'd39 : out = 12;
            6'd40 : out = 2;
            6'd41 : out = 9;
            6'd42 : out = 8;
            6'd43 : out = 5;
            6'd44 : out = 12;
            6'd45 : out = 15;
            6'd46 : out = 3;
            6'd47 : out = 10;
            6'd48 : out = 7;
            6'd49 : out = 11;
            6'd50 : out = 0;
            6'd51 : out = 14;
            6'd52 : out = 4;
            6'd53 : out = 1;
            6'd54 : out = 10;
            6'd55 : out = 7;
            6'd56 : out = 1;
            6'd57 : out = 6;
            6'd58 : out = 13;
            6'd59 : out = 0;
            6'd60 : out = 11;
            6'd61 : out = 8;
            6'd62 : out = 6;
            6'd63 : out = 13;
        endcase
    end
endmodule
module sbox7(input [5:0] in, output reg[3:0] out);
    always @(*)begin
        case (in)
        6'd0 : out = 4;
        6'd1 : out = 13;
        6'd2 : out = 11;
        6'd3 : out = 0;
        6'd4 : out = 2;
        6'd5 : out = 11;
        6'd6 : out = 14;
        6'd7 : out = 7;
        6'd8 : out = 15;
        6'd9 : out = 4;
        6'd10 : out = 0;
        6'd11 : out = 9;
        6'd12 : out = 8;
        6'd13 : out = 1;
        6'd14 : out = 13;
        6'd15 : out = 10;
        6'd16 : out = 3;
        6'd17 : out = 14;
        6'd18 : out = 12;
        6'd19 : out = 3;
        6'd20 : out = 9;
        6'd21 : out = 5;
        6'd22 : out = 7;
        6'd23 : out = 12;
        6'd24 : out = 5;
        6'd25 : out = 2;
        6'd26 : out = 10;
        6'd27 : out = 15;
        6'd28 : out = 6;
        6'd29 : out = 8;
        6'd30 : out = 1;
        6'd31 : out = 6;
        6'd32 : out = 1;
        6'd33 : out = 6;
        6'd34 : out = 4;
        6'd35 : out = 11;
        6'd36 : out = 11;
        6'd37 : out = 13;
        6'd38 : out = 13;
        6'd39 : out = 8;
        6'd40 : out = 12;
        6'd41 : out = 1;
        6'd42 : out = 3;
        6'd43 : out = 4;
        6'd44 : out = 7;
        6'd45 : out = 10;
        6'd46 : out = 14;
        6'd47 : out = 7;
        6'd48 : out = 10;
        6'd49 : out = 9;
        6'd50 : out = 15;
        6'd51 : out = 5;
        6'd52 : out = 6;
        6'd53 : out = 0;
        6'd54 : out = 8;
        6'd55 : out = 15;
        6'd56 : out = 0;
        6'd57 : out = 14;
        6'd58 : out = 5;
        6'd59 : out = 2;
        6'd60 : out = 9;
        6'd61 : out = 3;
        6'd62 : out = 2;
        6'd63 : out = 12;
        endcase
    end
endmodule

module sbox8(input [5:0] in, output reg[3:0] out);
    always @(*)begin
        case (in)
        6'd0 : out = 13;
        6'd1 : out = 1;
        6'd2 : out = 2;
        6'd3 : out = 15;
        6'd4 : out = 8;
        6'd5 : out = 13;
        6'd6 : out = 4;
        6'd7 : out = 8;
        6'd8 : out = 6;
        6'd9 : out = 10;
        6'd10 : out = 15;
        6'd11 : out = 3;
        6'd12 : out = 11;
        6'd13 : out = 7;
        6'd14 : out = 1;
        6'd15 : out = 4;
        6'd16 : out = 10;
        6'd17 : out = 12;
        6'd18 : out = 9;
        6'd19 : out = 5;
        6'd20 : out = 3;
        6'd21 : out = 6;
        6'd22 : out = 14;
        6'd23 : out = 11;
        6'd24 : out = 5;
        6'd25 : out = 0;
        6'd26 : out = 0;
        6'd27 : out = 14;
        6'd28 : out = 12;
        6'd29 : out = 9;
        6'd30 : out = 7;
        6'd31 : out = 2;
        6'd32 : out = 7;
        6'd33 : out = 2;
        6'd34 : out = 11;
        6'd35 : out = 1;
        6'd36 : out = 4;
        6'd37 : out = 14;
        6'd38 : out = 1;
        6'd39 : out = 7;
        6'd40 : out = 9;
        6'd41 : out = 4;
        6'd42 : out = 12;
        6'd43 : out = 10;
        6'd44 : out = 14;
        6'd45 : out = 8;
        6'd46 : out = 2;
        6'd47 : out = 13;
        6'd48 : out = 0;
        6'd49 : out = 15;
        6'd50 : out = 6;
        6'd51 : out = 12;
        6'd52 : out = 10;
        6'd53 : out = 9;
        6'd54 : out = 13;
        6'd55 : out = 0;
        6'd56 : out = 15;
        6'd57 : out = 3;
        6'd58 : out = 3;
        6'd59 : out = 5;
        6'd60 : out = 5;
        6'd61 : out = 6;
        6'd62 : out = 8;
        6'd63 : out = 11;
        endcase
    end
endmodule

module P_2(input  [31:0]in,output [31:0]out);//in本來有reg
  assign out[0] = in[7];
  assign out[1] = in[28];
  assign out[2] = in[21];
  assign out[3] = in[10];
  assign out[4] = in[26];
  assign out[5] = in[2];
  assign out[6] = in[19];
  assign out[7] = in[13];
  assign out[8] = in[23];
  assign out[9] = in[29];
  assign out[10] = in[5];
  assign out[11] = in[0];
  assign out[12] = in[18];
  assign out[13] = in[8];
  assign out[14] = in[24];
  assign out[15] = in[30];
  assign out[16] = in[22];
  assign out[17] = in[1];
  assign out[18] = in[14];
  assign out[19] = in[27];
  assign out[20] = in[6];
  assign out[21] = in[9];
  assign out[22] = in[17];
  assign out[23] = in[31];
  assign out[24] = in[15];
  assign out[25] = in[4];
  assign out[26] = in[20];
  assign out[27] = in[3];
  assign out[28] = in[11];
  assign out[29] = in[12];
  assign out[30] = in[25];
  assign out[31] = in[16];
endmodule

module IP_2(input [63:0]in,output [63:0] out);
    assign out[0] = in[57];
    assign out[1] = in[49];
    assign out[2] = in[41];
    assign out[3] = in[33];
    assign out[4] = in[25];
    assign out[5] = in[17];
    assign out[6] = in[9];
    assign out[7] = in[1];
    assign out[8] = in[59];
    assign out[9] = in[51];
    assign out[10] = in[43];
    assign out[11] = in[35];
    assign out[12] = in[27];
    assign out[13] = in[19];
    assign out[14] = in[11];
    assign out[15] = in[3];
    assign out[16] = in[61];
    assign out[17] = in[53];
    assign out[18] = in[45];
    assign out[19] = in[37];
    assign out[20] = in[29];
    assign out[21] = in[21];
    assign out[22] = in[13];
    assign out[23] = in[5];
    assign out[24] = in[63];
    assign out[25] = in[55];
    assign out[26] = in[47];
    assign out[27] = in[39];
    assign out[28] = in[31];
    assign out[29] = in[23];
    assign out[30] = in[15];
    assign out[31] = in[7];
    assign out[32] = in[56];
    assign out[33] = in[48];
    assign out[34] = in[40];
    assign out[35] = in[32];
    assign out[36] = in[24];
    assign out[37] = in[16];
    assign out[38] = in[8];
    assign out[39] = in[0];
    assign out[40] = in[58];
    assign out[41] = in[50];
    assign out[42] = in[42];
    assign out[43] = in[34];
    assign out[44] = in[26];
    assign out[45] = in[18];
    assign out[46] = in[10];
    assign out[47] = in[2];
    assign out[48] = in[60];
    assign out[49] = in[52];
    assign out[50] = in[44];
    assign out[51] = in[36];
    assign out[52] = in[28];
    assign out[53] = in[20];
    assign out[54] = in[12];
    assign out[55] = in[4];   
    assign out[56] = in[62];
    assign out[57] = in[54];
    assign out[58] = in[46];
    assign out[59] = in[38];
    assign out[60] = in[30];
    assign out[61] = in[22];
    assign out[62] = in[14];
    assign out[63] = in[6];   
endmodule

module FP(input  [63:0]in,output  [63:0] out);//in 本來有reg
    assign out[0] = in[39];
    assign out[1] = in[7];
    assign out[2] = in[47];
    assign out[3] = in[15];
    assign out[4] = in[55];
    assign out[5] = in[23];
    assign out[6] = in[63];
    assign out[7] = in[31];
    assign out[8] = in[38];
    assign out[9] = in[6];
    assign out[10] = in[46];
    assign out[11] = in[14];
    assign out[12] = in[54];
    assign out[13] = in[22];
    assign out[14] = in[62];
    assign out[15] = in[30];
    assign out[16] = in[37];
    assign out[17] = in[5];
    assign out[18] = in[45];
    assign out[19] = in[13];
    assign out[20] = in[53];
    assign out[21] = in[21];
    assign out[22] = in[61];
    assign out[23] = in[29];
    assign out[24] = in[36];
    assign out[25] = in[4];
    assign out[26] = in[44];
    assign out[27] = in[12];
    assign out[28] = in[52];
    assign out[29] = in[20];
    assign out[30] = in[60];
    assign out[31] = in[28];
    assign out[32] = in[35];
    assign out[33] = in[3];
    assign out[34] = in[43];
    assign out[35] = in[11];
    assign out[36] = in[51];
    assign out[37] = in[19];
    assign out[38] = in[59];
    assign out[39] = in[27];
    assign out[40] = in[34];
    assign out[41] = in[2];
    assign out[42] = in[42];
    assign out[43] = in[10];
    assign out[44] = in[50];
    assign out[45] = in[18];
    assign out[46] = in[58];
    assign out[47] = in[26];
    assign out[48] = in[33];
    assign out[49] = in[1];
    assign out[50] = in[41];
    assign out[51] = in[9];
    assign out[52] = in[49];
    assign out[53] = in[17];
    assign out[54] = in[57];
    assign out[55] = in[25];   
    assign out[56] = in[32];
    assign out[57] = in[0];
    assign out[58] = in[40];
    assign out[59] = in[8];
    assign out[60] = in[48];
    assign out[61] = in[16];
    assign out[62] = in[56];
    assign out[63] = in[24];   
endmodule

module CIR(input [4:0]enc_count,input [27:0] in, output [27:0] out);
    assign out = (enc_count == 0 || enc_count == 1 || enc_count == 8 || enc_count == 15) ?{in[26:0], in[27]} : {in[25:0], in[27:26]};
endmodule

module CIR_R(input [4:0]enc_count,input [27:0] in, output [27:0] out);
    assign out = (enc_count == 0)?in:(enc_count == 1 || enc_count == 8 || enc_count == 15|| enc_count == 16)?{in[0], in[27:1]} : {in[1:0], in[27:2]};
endmodule

module BtoG(input [4:0]ind,input REG_8,input [7:0]in,output[7:0]out);
    assign out[7]=(ind==0)?in[7]:REG_8^in[7];
    assign out[6]=in[7]^in[6];
    assign out[5]=in[6]^in[5];
    assign out[4]=in[5]^in[4];
    assign out[3]=in[4]^in[3];
    assign out[2]=in[3]^in[2];
    assign out[1]=in[2]^in[1];
    assign out[0]=in[1]^in[0];
endmodule

module GtoB(input [4:0]ind,input REG_8,input [7:0]in,output[7:0]out);
    assign out[7]=(ind==0)?in[7]:REG_8^in[7];
    assign out[6]=REG_8^in[7]^in[6];
    assign out[5]=REG_8^in[7]^in[6]^in[5];
    assign out[4]=REG_8^in[7]^in[6]^in[5]^in[4];
    assign out[3]=REG_8^in[7]^in[6]^in[5]^in[4]^in[3];
    assign out[2]=REG_8^in[7]^in[6]^in[5]^in[4]^in[3]^in[2];
    assign out[1]=REG_8^in[7]^in[6]^in[5]^in[4]^in[3]^in[2]^in[1];
    assign out[0]=REG_8^in[7]^in[6]^in[5]^in[4]^in[3]^in[2]^in[1]^in[0];
endmodule

module CRC(input [4:0]ind,input [2:0]REG_8,input [7:0]in,output[2:0]out);
    wire [3:0]res1;
    wire [3:0]res2;
    wire [3:0]res3;
    wire [3:0]res4;
    wire [3:0]res5;
    wire [3:0]res6;
    wire [3:0]res7;
    wire [3:0]res8;
    assign res1=(ind==0)?0:(REG_8[2]==1)?{REG_8,in[7]}^4'b1011:{REG_8[2:0],in[7]};
    assign res2=(ind==0)?0:(res1[2]==1)?{res1[2:0],in[6]}^4'b1011:{res1[2:0],in[6]};
    assign res3=(ind==0)?in[7:5]:(res2[2]==1)?{res2[2:0],in[5]}^4'b1011:{res2[2:0],in[5]};
    assign res4=(res3[2]==1)?{res3[2:0],in[4]}^4'b1011:{res3[2:0],in[4]};
    assign res5=(res4[2]==1)?{res4[2:0],in[3]}^4'b1011:{res4[2:0],in[3]};
    assign res6=(res5[2]==1)?{res5[2:0],in[2]}^4'b1011:{res5[2:0],in[2]};
    assign res7=(res6[2]==1)?{res6[2:0],in[1]}^4'b1011:{res6[2:0],in[1]};
    assign res8=(res7[2]==1)?{res7[2:0],in[0]}^4'b1011:{res7[2:0],in[0]};//可能可以直接接out
    assign out=res8[2:0];
endmodule

//vcs -f rtl_01.f -full64 -R +v2k -sverilog -v2005 -debug_access+all +define+p1+F5 | tee rtl_F1.log
