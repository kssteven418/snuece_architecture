`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "opcodes.v"

module cpu(
        input Clk, 
        input Reset_N, 

	// Instruction memory interface
        output i_readM, 
        output i_writeM, 
        output [`WORD_SIZE-1:0] i_address, 
        inout [`WORD_SIZE-1:0] i_data, 
        
        input i_ready,
        input d_ready,

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_address, 
        inout [`WORD_SIZE-1:0] d_data, 
        output [`WORD_SIZE-1:0] to_num_inst, //debugging
        output [`WORD_SIZE-1:0] num_inst, 
        output [`WORD_SIZE-1:0] output_port, 
        output is_halted,
        
        output IFID_Flush,
        output IDEX_Flush,
        
        //debugging
        output PC_enable,
        
        output[15:0] IF_inst,
        output[15:0] ID_inst,
        output[15:0] EX_inst,
        output[15:0] ALU_out,
        output ID_WWD,
        output EX_WWD,
        
        
        output[15:0] ALU_in1,

        output[15:0] RF_val1,
        output[15:0] RF_val2,
        
        output[15:0] out0,
        output[15:0] out1,
        output[15:0] out2,
        output[15:0] out3
          
       
);

    reg[`WORD_SIZE-1:0] to_num_inst;
    wire[`WORD_SIZE-1:0] num_inst;
    
    wire[`WORD_SIZE-1:0] output_port;
    //initial output_port<=0;
    wire[`WORD_SIZE-1:0] to_output_port;
    initial begin to_num_inst<=0; end
    
	// TODO : Implement your multi-cycle CPU!

    wire [15:0] inst;
    wire ALUsrc;
    wire[1:0] RegDist;
    wire MemWrite;
    wire MemRead;
    wire MemtoReg;
    wire RegWrite;
    wire[3:0] Alucode;
    wire Jump;
    wire JumpR;
    wire Branch;
    
    
    wire[15:0] ALU_in1;
    wire[15:0] RF_val1;
    wire[15:0] RF_val2;
    
    wire[15:0] out1;
    wire[15:0] out2;
    wire[15:0] out3;
    wire[15:0] out0;   
   
    //num_inst
    wire ID_isFetched;
    wire EX_isFetched;
    wire ID_WWD;
    wire EX_WWD;
    
    wire IFID_Flush;
    wire IDEX_Flush;
    
    wire IDEX_enable;
    
    //WWD, num_inst logic
    
    
    latch1 isFetched(1, 0, Clk, ID_isFetched && !IDEX_Flush, EX_isFetched); 
    latch1 WWD(1, 0, Clk, ID_WWD, EX_WWD); 
    
//    always @(EX_WWD) begin
//        if(EX_WWD==1) output_port <= to_output_port;
//    end
    assign output_port = EX_WWD ? to_output_port : 15'bz;
    assign num_inst = EX_WWD ? to_num_inst: 15'bz;
    
    
    always @(negedge Clk) begin
        if(EX_isFetched && IDEX_enable) begin 
            to_num_inst<=to_num_inst+1; 
        end
    end

    //stalling and flushing
    wire isStalled;
    
    
    //debugging 
    wire PC_enable;
    wire[15:0] IF_inst;
    wire[15:0] ID_inst;
    wire[15:0] EX_inst;
    wire[15:0] ALU_out;
    
    datapath DM(
        .clk(Clk),
        .reset_n(Reset_N),
        
        .i_readM(i_readM),
        .i_writeM(i_writeM),
        .i_address(i_address),
        .i_data(i_data),
        
        .d_readM(d_readM),
        .d_writeM(d_writeM),
        .d_address(d_address),
        .d_data(d_data),
        
        .i_ready(i_ready),
        .d_ready(d_ready),
        
        .to_output_port(to_output_port),
        .is_halted(is_halted),
        
        .inst(inst),
        .ALUsrc(ALUsrc),
        .RegDist(RegDist),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .Alucode(Alucode),
        .Jump(Jump),
        .JumpR(JumpR),
        .Branch(Branch),
        .Halt(Halt),
        
        .isStalled(isStalled),
               
        .IDEX_Flush(IDEX_Flush),
        .IFID_Flush(IFID_Flush),
        .IDEX_enable(IDEX_enable),
        
        
        //debugging
        .PC_enable(PC_enable),
        .IFID_inst_out(ID_inst),
        .IFID_inst_in(IF_inst),
        .EX_inst(EX_inst),
        .ALU_out(ALU_out),
        
        .ALU_in1(ALU_in1),
        
        .RF_val1(RF_val1),
        .RF_val2(RF_val2),
        
        .out0(out0),
        .out1(out1),
        .out2(out2),
        .out3(out3)
        
    );
    
    control CTRL(
        .clk(Clk),
        .inst(inst),
        .ALUsrc(ALUsrc),
        .RegDist(RegDist),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .MemtoReg(MemtoReg),
        .RegWrite(RegWrite),
        .Alucode(Alucode),
        .Jump(Jump),
        .JumpR(JumpR),
        .Branch(Branch),
        .Halt(Halt),
        
        .isFetched(ID_isFetched),
        .WWD(ID_WWD),
        
        .isStalled(isStalled)
    );
    
endmodule

