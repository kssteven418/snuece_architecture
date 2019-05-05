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

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_address, 
        inout [`WORD_SIZE-1:0] d_data, 

        output [`WORD_SIZE-1:0] num_inst, 
        output [`WORD_SIZE-1:0] output_port, 
        output is_halted,
        
        //debugging

        output[15:0] pc_out,
        output[15:0] pc_next,
        output[15:0] pc_in,
        
       output[15:0] ID_pc,
       output[15:0] ID_pc_pred,
       output[15:0] EX_pc,
       output[15:0] EX_pc_pred,
       
       output[15:0] jumpAddr,
       output[15:0] branchAddr,
       
       
       output jumpPred,
       output branchPred,
       output branchMissPred,
       
       output EX_Branch,
       output b_cond,
       output[1:0] PCsrc,
       
       output[7:0] BHSR,
       output valid,
       output[7:0] tag,
       output[7:0] pc_tag,
       output pred,
       output taken,
       output bht_update,
       output[15:0] pc_update
        
//        //for BTB test
//        output valid,
//        output[7:0] tag,
//        output[15:0] addr
          
       
);

    reg[`WORD_SIZE-1:0] num_inst;
    wire[`WORD_SIZE-1:0] output_port;
    wire[`WORD_SIZE-1:0] to_output_port;
    initial begin num_inst<=0; end
    
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
    
    
    wire[15:0] out1;
    wire[15:0] out2;
    wire[15:0] out3;
    wire[15:0] out4;   
   
    //num_inst
    wire ID_isFetched;
    wire EX_isFetched;
    wire ID_WWD;
    wire EX_WWD;
    
    //debugging

    wire[15:0] pc_out;
    wire[15:0] pc_next;
    wire[15:0] pc_in;
    
            
    wire[15:0] ID_pc;
    wire[15:0] ID_pc_pred;
    wire[15:0] EX_pc;
    wire[15:0] EX_pc_pred;
   
    wire[15:0] jumpAddr;
    wire[15:0] branchAddr;
    

    wire jumpPred;
    wire branchPred;
    wire branchMissPred;
    
    wire EX_Branch;
    wire b_cond;
    wire[1:0] PCsrc;
    
    wire[7:0] BHSR;
    wire valid;
    wire[7:0] tag;
    wire[7:0] pc_tag;
    wire pred;
    wire taken;
    
    wire bht_update;
    wire[15:0] pc_update;
    
    //WWD, num_inst logic
    
    
    latch1 isFetched(1, 0, Clk, ID_isFetched && !IDEX_Flush, EX_isFetched); 
    latch1 WWD(1, 0, Clk, ID_WWD, EX_WWD); 
    
    assign output_port = EX_WWD ? to_output_port : 15'bz;
    
    always @(negedge Clk) begin
        if(EX_isFetched) begin 
            num_inst<=num_inst+1; 
        end
    end

    //stalling and flushing
    wire isStalled;
    
    
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
        
        //debugging
        
        .pc_out(pc_out),
        .pc_next(pc_next),
        .pc_in(pc_in),
        
        .ID_pc(ID_pc),
        .ID_pc_pred(ID_pc_pred),
        .EX_pc(EX_pc),
        .EX_pc_pred(EX_pc_pred),
        
        .jumpAddr(jumpAddr),
        .branchAddr(branchAddr),
        
        
        .jumpPred(jumpPred),
        .branchPred(branchPred),
        .branchMissPred(branchMissPred),
        .b_cond(b_cond),
        .EX_Branch(EX_Branch),
        .PCsrc(PCsrc),
        .BHSR(BHSR),
        .pred(pred),
        .taken(taken),
        
        .bht_update(bht_update),
        .pc_update(pc_update)

        
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
