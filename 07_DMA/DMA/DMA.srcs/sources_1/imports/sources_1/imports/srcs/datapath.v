`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

//////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////DATAPATH MODULE///////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////


module datapath(
    input clk,
    input reset_n ,
    
    // Instruction memory interface
    output i_readM, 
    output i_writeM, 
    output [`WORD_SIZE-1:0] i_address, 
    inout [`WORD_SIZE-1:0] i_data, 

	// Data memory interface
    output d_readM, 
    output d_writeM, 
    output [`WORD_SIZE-1:0] d_address, 
    inout [`WORD_SIZE-1:0] d_data, 
    
    input i_ready,
    input d_ready,

    //output [`WORD_SIZE-1:0] num_inst, 
    output [`WORD_SIZE-1:0] to_output_port,
    output is_halted,
    
    //for control unit
    output[15:0] inst,
    input ALUsrc,
    input[1:0] RegDist,
    input MemWrite,
    input MemRead,
    input MemtoReg,
    input RegWrite,
    input[3:0] Alucode,
    input Jump,
    input JumpR,
    input Branch,
    input Halt,
    
    
    output isStalled,
    
    output IDEX_Flush,
    output IFID_Flush,
    output IDEX_enable,
    
    //for DMA
    input stall_all,
    
    //debugging
    output[1:0] ALUsrc1,
    output PC_enable,
    output[15:0] IFID_inst_in,
    output[15:0] IFID_inst_out,
    output[15:0] EX_inst,
    output[15:0] ALU_out,
    
    output[15:0] ALU_in1,
    
    output[15:0] RF_val1,
    output[15:0] RF_val2,
    
    output[15:0] out0,
    output[15:0] out1,
    output[15:0] out2,
    output[15:0] out3
    
    
);


    wire[15:0] inst;
    wire[15:0] to_output_port;
    wire is_halted;
    
    //stalling & flushing
    wire isStalled;
    wire IFID_Flush;
    wire IDEX_Flush;
    
    wire[15:0] EX_inst;
    
    
    wire PC_enable;
    wire IFID_enable;
    wire IDEX_enable;
    wire EXMEM_enable;
    
    
    assign PC_enable = (!isStalled && i_ready && d_ready) || !reset_n || IFID_Flush;
    
    //always @(posedge clk) $display("SDDSADSADSADASD : %b, i_ready : %b, reset_n : %b", PC_enable, i_ready, reset_n); 
    assign IFID_enable = !isStalled && d_ready;
    
    assign IDEX_enable = d_ready;
    
    assign EXMEM_enable = d_ready;
    
//    always @(posedge clk) $display("d_ready %b", d_ready);
    
    
    
    //Jump & Branch Addr
    
    
    wire[15:0] jumpAddr;
    wire[15:0] branchAddr;
    wire[15:0] jumpRAddr;
    
    
    
    //RF debugging
            
    wire[15:0] out1;
    wire[15:0] out2;
    wire[15:0] out3;
    wire[15:0] out0;
    
////////////////////////////////data wires////////////////////////////////////
    
    
    //IF stage
    wire[15:0] pc_in;
    wire[15:0] pc_out;
    
    wire[15:0] imem_in;
    wire[15:0] imem_out;
    
    wire[15:0] IFID_inst_in;
    
    
    //ID stage
    wire[15:0] ID_pc;
    
    wire[15:0] IFID_inst_out;
    
    wire[1:0] RF_addr1;
    wire[1:0] RF_addr2;
    wire[1:0] RF_addrw;
    wire[15:0] RF_wData;
    wire[15:0] RF_val1;
    wire[15:0] RF_val2;
    
    wire[7:0] SE_in;
    wire[15:0] SE_out;
    
    wire[15:0] IDEX_val1_in;
    wire[15:0] IDEX_val2_in;
    wire[15:0] IDEX_SE_in;
    wire[1:0] IDEX_rt_in;
    wire[1:0] IDEX_rd_in;
    wire[1:0] IDEX_rs_in;
    
    
    //EX stage
    wire[15:0] EX_pc;
    
    wire[15:0] IDEX_val1_out;
    wire[15:0] IDEX_val2_out;
    wire[15:0] IDEX_SE_out;
    wire[1:0] IDEX_rt_out;
    wire[1:0] IDEX_rd_out;
    wire[1:0] IDEX_rs_out;
    
    wire[15:0] ALU_in1;
    wire[15:0] ALU_in2;
    wire[15:0] ALU_out;
    wire[1:0] RF_dist;
    
    //target address should be added//
    
    wire[15:0] EXMEM_ALU_in;
    wire[15:0] EXMEM_dmem_in;
    wire[1:0] EXMEM_RF_dist_in;
    
    
    //MEM stage
    wire[15:0] EXMEM_ALU_out;
    wire[15:0] EXMEM_dmem_out;
    wire[1:0] EXMEM_RF_dist_out;
    
    wire[15:0] dmem_addr;
    wire[15:0] dmem_wdata;
    wire[15:0] dmem_rdata;
    
    wire[15:0] MEMWB_rdata_in;
    wire[15:0] MEMWB_ALU_in;
    wire[1:0] MEMWB_RF_dist_in;
    
    //WB stage
    wire[15:0] MEMWB_rdata_out;
    wire[15:0] MEMWB_ALU_out;
    wire[1:0] MEMWB_RF_dist_out;
    
    
    
//////////////////////////////control signals/////////////////////////////
    
    wire[1:0] PCsrc;
    
    wire ID_ALUsrc;
    wire[1:0] ID_RegDist;
    wire ID_MemWrite;
    wire ID_MemRead;
    wire ID_MemtoReg;
    wire ID_RegWrite;
    wire[3:0] ID_Alucode;
    wire ID_Jump;
    wire ID_JumpR;
    wire ID_Branch;
    wire ID_Halt;
    
    wire EX_ALUsrc;
    wire[1:0] EX_RegDist;
    wire EX_MemWrite;
    wire EX_MemRead;
    wire EX_MemtoReg;
    wire EX_RegWrite;
    wire[3:0] EX_Alucode;
    wire EX_Jump;
    wire EX_JumpR;
    wire EX_Branch;
    wire EX_Halt;
    
    wire[1:0] ALUsrc1;
    wire[1:0] ALUsrc2;
        
    wire MEM_MemWrite;
    wire MEM_MemRead;
    wire MEM_MemtoReg;
    wire MEM_RegWrite;
        
    wire WB_MemtoReg;
    wire WB_RegWrite;
    
    
    
////////////////////////////wire connection///////////////////////////////

//IF stage

assign imem_in = pc_out;
assign IFID_inst_in = imem_out;

//ID stage

//control signals
assign ID_ALUsrc = ALUsrc;
assign ID_RegDist = RegDist;
assign ID_MemWrite = MemWrite;
assign ID_MemRead = MemRead;
assign ID_MemtoReg = MemtoReg;
assign ID_RegWrite = RegWrite;
assign ID_Alucode = Alucode;
assign ID_Jump = Jump;
assign ID_JumpR = JumpR;
assign ID_Branch = Branch;
assign ID_Halt = Halt;

assign RF_addr1 = IFID_inst_out[11:10];
assign RF_addr2 = IFID_inst_out[9:8];
assign SE_in = IFID_inst_out[7:0];
assign inst = IFID_inst_out;

assign IDEX_val1_in = RF_val1;
assign IDEX_val2_in = RF_val2;
assign IDEX_rd_in = IFID_inst_out[7:6];
assign IDEX_rt_in = IFID_inst_out[9:8];
assign IDEX_rs_in = IFID_inst_out[11:10];
assign IDEX_SE_in = SE_out;

//EX stage

assign ALU_in1 = (ALUsrc1 == 2'b00) ? IDEX_val1_out :
                 (ALUsrc1 == 2'b10) ? EXMEM_ALU_out :
                 RF_wData;
wire[15:0] temp;
assign temp = (ALUsrc2 == 2'b00) ? IDEX_val2_out :
                 (ALUsrc2 == 2'b10) ? EXMEM_ALU_out :
                 RF_wData;
assign ALU_in2 = EX_ALUsrc ? IDEX_SE_out : temp;
//assign RF_dist = EX_RegDist==2'b01 ? IDEX_rd_out : 
//                IDEX_rt_out;

assign RF_dist = EX_RegDist==2'b01 ? IDEX_rd_out : 
                 EX_RegDist==2'b00 ? IDEX_rt_out :  
                 2;
assign to_output_port = ALU_in1;

assign EXMEM_ALU_in = (EX_Jump || EX_JumpR) ? (EX_pc+1) : ALU_out;
assign EXMEM_dmem_in = IDEX_val2_out;
assign EXMEM_RF_dist_in = RF_dist;


//MEM stage

assign dmem_addr = EXMEM_ALU_out;
assign dmem_wdata = EXMEM_dmem_out;

assign MEMWB_rdata_in = dmem_rdata;
assign MEMWB_ALU_in = EXMEM_ALU_out;
assign MEMWB_RF_dist_in = EXMEM_RF_dist_out;

//WB stage

assign RF_wData = WB_MemtoReg ? MEMWB_rdata_out : MEMWB_ALU_out;
assign RF_addrw = MEMWB_RF_dist_out;



/////////////////////////////////module init////////////////////////////////////


//ALU
ALU alu( .A(ALU_in1), .B(ALU_in2), .Cin(0), .OP(EX_Alucode), .C(ALU_out));


//IMEM

reg i_readM;
reg i_writeM;
wire[`WORD_SIZE-1:0] i_address;
wire[`WORD_SIZE-1:0] i_data;

assign imem_out = i_readM ? i_data : `WORD_SIZE'bz;
assign i_data = `WORD_SIZE'bz;
assign i_address = pc_out;

initial begin 
    i_readM<=1; 
end

//DMEM

wire d_readM;
wire d_writeM;
wire [`WORD_SIZE-1:0] d_address; 
wire [`WORD_SIZE-1:0] d_data;

assign dmem_rdata = d_readM ? d_data : `WORD_SIZE'bz;
assign d_data = d_writeM ? dmem_wdata : `WORD_SIZE'bz;
assign d_address = dmem_addr;
assign d_readM = MEM_MemRead;
assign d_writeM = MEM_MemWrite;

//always @(posedge clk) $display("DATAC in DM : %b", d_data);
//always @(posedge clk) $display("DATAC_write in DM : %b", dmem_wdata);
//always @(posedge clk) $display("d_writeM : %b", d_writeM);

//Reg
 RegisterFile rf(.addr1(RF_addr1), 
                 .addr2(RF_addr2), 
                 .addr3(RF_addrw), 
                 .data(RF_wData), 
                 .write(WB_RegWrite), 
                 .clock(clk),
                 .reset_n(reset_n), 
                 .data1(RF_val1), 
                 .data2(RF_val2),
                 
                 .out0(out0),
                 .out1(out1),
                 .out2(out2),
                 .out3(out3)
);

//Sign Extension

signExtension SE(SE_in, SE_out);

//Forwarding Unit

forward FWD(
    .MEM_RegWrite(MEM_RegWrite),
    .WB_RegWrite(WB_RegWrite),
    .MEM_dest(EXMEM_RF_dist_out),
    .WB_dest(MEMWB_RF_dist_out),
    .EX_rs(IDEX_rs_out),
    .EX_rt(IDEX_rt_out),
    
    .ALUsrc1(ALUsrc1),
    .ALUsrc2(ALUsrc2)
);


//Stalling Unit
stalling STU(

    .EX_MemRead(EX_MemRead),
    .EX_MemWrite(EX_MemWrite),
    .EX_dest(EXMEM_RF_dist_in),
    .inst(IFID_inst_out),
    .isStalled(isStalled)
);


//Flushing Unit
flushing FLU(
    .Jump(ID_Jump),
    .Branch(EX_Branch && ALU_out[0]),
    .JumpR(EX_JumpR),
    
    .IFID_Flush(IFID_Flush),
    .IDEX_Flush(IDEX_Flush),
    .PCsrc(PCsrc)
);


//TargetAddr Unit
targetAddress TAU(

    .inst(IFID_inst_out),
    .ID_pc(ID_pc),
    .EX_pc(EX_pc),
    .offset(IDEX_SE_out),
    .ALU_in1(ALU_in1),
    .ID_Jump(ID_Jump),
    .EX_JumpR(EX_JumpR),
    .EX_Branch(EX_Branch && ALU_out[0]),
    
    .jumpAddr(jumpAddr),
    .jumpRAddr(jumpRAddr),
    .branchAddr(branchAddr)
);


//Halt Module
halt HTU(
    .EX_Halt(EX_Halt),
    .clk(clk),
    
    .is_halted(is_halted)
);

//////////////////////////////DEBUGGING////////////////////////////////////////

//always @(posedge clk) begin
//    $display("");
//    $display("-----------------------------------");
//    $display("");
//end

//always @(pc_out) $display("pc_out : %h", pc_out);



///////////////////////////////////////////////////////


/////////////////////////////LATCH INIT/////////////////////////////////////////

latch PC(PC_enable && !stall_all, 0, clk, pc_in, pc_out);

reg[15:0] pc_next;

initial begin
    pc_next<=-1;
end

always @(pc_out) pc_next = pc_in + 1;

assign pc_in = PCsrc==2'b00 ? pc_next :
               PCsrc==2'b01 ? jumpAddr :
               PCsrc==2'b10 ? jumpRAddr :
               branchAddr;

IFID ifid(
    //pc
    .pc_in(pc_out),
    .pc_out(ID_pc),

    .clk(clk),
    .flush(IFID_Flush || (!i_ready&&d_ready)),
    //data signals
    .inst_in(IFID_inst_in),
    .inst_out(IFID_inst_out),
    .enable(IFID_enable && !stall_all)
);


IDEX idex(
    .clk(clk),
    .flush(IDEX_Flush),
    .enable(IDEX_enable && !stall_all),
    
    //pc
    .pc_in(ID_pc),
    .pc_out(EX_pc),
    
    //instruction debugging
    .inst_in(IFID_inst_out),
    .inst_out(EX_inst),
    
    //data signals
    
    .val1_in(IDEX_val1_in),
    .val2_in(IDEX_val2_in),
    .SE_in(IDEX_SE_in),
    .rt_in(IDEX_rt_in),
    .rd_in(IDEX_rd_in),
    .rs_in(IDEX_rs_in),
    
    .val1_out(IDEX_val1_out),
    .val2_out(IDEX_val2_out),
    .SE_out(IDEX_SE_out),
    .rt_out(IDEX_rt_out),
    .rd_out(IDEX_rd_out),
    .rs_out(IDEX_rs_out),
    
    
    //control signals
    
     .ALUsrc_in(ID_ALUsrc),
     .RegDist_in(ID_RegDist),
     .MemWrite_in(ID_MemWrite),
     .MemRead_in(ID_MemRead),
     .MemtoReg_in(ID_MemtoReg),
     .RegWrite_in(ID_RegWrite),
     .Alucode_in(ID_Alucode),
     .Jump_in(ID_Jump),
     .JumpR_in(ID_JumpR),
     .Branch_in(ID_Branch),
     .Halt_in(ID_Halt),
     
     .ALUsrc_out(EX_ALUsrc),
     .RegDist_out(EX_RegDist),
     .MemWrite_out(EX_MemWrite),
     .MemRead_out(EX_MemRead),
     .MemtoReg_out(EX_MemtoReg),
     .RegWrite_out(EX_RegWrite),
     .Alucode_out(EX_Alucode),
     .Jump_out(EX_Jump),
     .JumpR_out(EX_JumpR),
     .Branch_out(EX_Branch),
     .Halt_out(EX_Halt)
     
);
    

EXMEM exmem(
    .clk(clk),
    .enable(EXMEM_enable && !stall_all),
    
    //data signals
    
    .ALU_in(EXMEM_ALU_in),
    .dmem_in(EXMEM_dmem_in),
    .dist_in(EXMEM_RF_dist_in),
    
    .ALU_out(EXMEM_ALU_out),
    .dmem_out(EXMEM_dmem_out),
    .dist_out(EXMEM_RF_dist_out),
    
    
    //control signals
    
    .MemWrite_in(EX_MemWrite),
    .MemRead_in(EX_MemRead),
    .MemtoReg_in(EX_MemtoReg),
    .RegWrite_in(EX_RegWrite),
    
    .MemWrite_out(MEM_MemWrite),
    .MemRead_out(MEM_MemRead),
    .MemtoReg_out(MEM_MemtoReg),
    .RegWrite_out(MEM_RegWrite)
    
     
);    
    
MEMWB memwb(
    
    .clk(clk),
    .enable(d_ready && !stall_all),
//    .flush(!d_ready),
    
    //data signals
    
    .rdata_in(MEMWB_rdata_in),
    .ALU_in(MEMWB_ALU_in),
    .dist_in(MEMWB_RF_dist_in),
    
    
    .rdata_out(MEMWB_rdata_out),
    .ALU_out(MEMWB_ALU_out),
    .dist_out(MEMWB_RF_dist_out),
    
    //control signals
    
    .MemtoReg_in(MEM_MemtoReg),
    .RegWrite_in(MEM_RegWrite),
    
    .MemtoReg_out(WB_MemtoReg),
    .RegWrite_out(WB_RegWrite)
    
    
     
);


endmodule