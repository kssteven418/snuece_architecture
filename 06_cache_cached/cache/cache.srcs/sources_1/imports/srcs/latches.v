
///////////////////////////////////////////////////////////////////////////
///////////////////////////LATCH MODULEs///////////////////////////////////
///////////////////////////////////////////////////////////////////////////


// when enabled, change 'out value' to 'in value' in every clock

module latch(
    input enable,
    input flush,
    input clk,
    input[15:0] in,
    output[15:0] out
);

    reg[15:0] out;
    
    initial begin
        out <= 16'bx;
    end
    
    always @(posedge clk) begin
        if(flush && enable) out<=0;
        else if(enable) out<=in;
        else out<=out;
        
    end

endmodule


//for 2-bit
module latch2(
    input enable,
    input flush,
    input clk,
    input[1:0] in,
    output[1:0] out
);

    reg[1:0] out;
    
    initial begin
        out <= 2'bx;
    end
    
        
    always @(posedge clk) begin
        if(flush && enable) out<=0;
        else if(enable) out<=in;
        else out<=out;
        
    end

endmodule


//for 1-bit
module latch1(
    input enable,
    input flush,
    input clk,
    input in,
    output out
);

    reg out;
    
    initial begin
        out <= 1'bx;
    end
    
    always @(posedge clk) begin
        if(flush && enable) out<=0;
        else if(enable) out<=in;
        else out<=out;
        
    end

endmodule

//for 4-bit
module latch4(
    input enable,
    input flush,
    input clk,
    input[3:0] in,
    output[3:0] out
);

    reg[3:0] out;
    
    initial begin
        out <= 4'bx;
    end
    
    
    always @(posedge clk) begin
        if(flush && enable) out<=0;
        else if(enable) out<=in;
        else out<=out;
        
    end

endmodule


module IFID(
    input clk,
    
    //pc
    input[15:0] pc_in,
    output[15:0] pc_out,
    
    //data signals
    input[15:0] inst_in,
    output[15:0] inst_out,
    
    input enable,
    input flush
);

    latch inst(enable, flush, clk, inst_in, inst_out);
    latch pc(enable, flush, clk, pc_in, pc_out);
    
endmodule

module IDEX(
    input clk,
    
    input flush,
    
    //pc
    
    input[15:0] pc_in,
    output[15:0] pc_out,
    
    //instruction debugging
    input[15:0] inst_in,
    output[15:0] inst_out,
    
    
    //data signals
    
    input[15:0] val1_in,
    input[15:0] val2_in,
    input[15:0] SE_in,
    input[1:0] rt_in,
    input[1:0] rd_in,
    input[1:0] rs_in,
    
    output[15:0] val1_out,
    output[15:0] val2_out,
    output[15:0] SE_out,
    output[1:0] rt_out,
    output[1:0] rd_out,
    output [1:0] rs_out,
    
    //control signals
    
     input ALUsrc_in,
     input[1:0] RegDist_in,
     input MemWrite_in,
     input MemRead_in,
     input MemtoReg_in,
     input RegWrite_in,
     input[3:0] Alucode_in,
     input Jump_in,
     input JumpR_in,
     input Branch_in,
     input Halt_in,
     
     output ALUsrc_out,
     output[1:0] RegDist_out,
     output MemWrite_out,
     output MemRead_out,
     output MemtoReg_out,
     output RegWrite_out,
     output[3:0] Alucode_out,
     output Jump_out,
     output JumpR_out,
     output Branch_out,
     output Halt_out,
     
     input enable
     
);
    latch pc(enable, flush, clk, pc_in, pc_out);
    latch inst(enable, flush, clk, inst_in, inst_out);
    
    //data signals
    
    latch val1(enable, flush, clk, val1_in, val1_out); 
    latch val2(enable, flush, clk, val2_in, val2_out); 
    latch SE(enable, flush, clk, SE_in, SE_out); 
    latch2 rt(enable, flush, clk, rt_in, rt_out); 
    latch2 rd(enable, flush, clk, rd_in, rd_out); 
    latch2 rs(enable, flush, clk, rs_in, rs_out); 
    
    //control signals
    
    latch1 ALUsrc(enable, flush, clk, ALUsrc_in, ALUsrc_out);
    latch2 RegDist(enable, flush, clk, RegDist_in, RegDist_out);
    latch1 MemWrite(enable, flush, clk, MemWrite_in, MemWrite_out);
    latch1 MemRead(enable, flush, clk, MemRead_in, MemRead_out);
    latch1 MemtoReg(enable, flush, clk, MemtoReg_in, MemtoReg_out);
    latch1 RegWrite(enable, flush, clk, RegWrite_in, RegWrite_out);
    latch4 Alucode(enable, flush, clk, Alucode_in, Alucode_out);
    latch1 JumpR(enable, flush, clk, JumpR_in, JumpR_out);
    latch1 Jump(enable, flush, clk, Jump_in, Jump_out);
    latch1 Branch(enable, flush, clk, Branch_in, Branch_out);
    latch1 Halt(enable, flush, clk, Halt_in, Halt_out);
    
    
    
endmodule



module EXMEM(
    input clk,
    
    //data signals
    
    input[15:0] ALU_in,
    input[15:0] dmem_in,
    input[1:0] dist_in,
    
    output[15:0] ALU_out,
    output[15:0] dmem_out,
    output[1:0] dist_out,
    
    //control signals
    
     input MemWrite_in,
     input MemRead_in,
     input MemtoReg_in,
     input RegWrite_in,
     
     output MemWrite_out,
     output MemRead_out,
     output MemtoReg_out,
     output RegWrite_out,
     
     input enable
     
);

    
    latch ALU(enable, 0, clk, ALU_in, ALU_out); 
    latch dmem(enable, 0, clk, dmem_in, dmem_out); 
    latch2 dist(enable, 0, clk, dist_in, dist_out); 

    latch1 MemWrite(enable, 0, clk, MemWrite_in, MemWrite_out);
    latch1 MemRead(enable, 0, clk, MemRead_in, MemRead_out);
    latch1 MemtoReg(enable, 0, clk, MemtoReg_in, MemtoReg_out);
    latch1 RegWrite(enable, 0, clk, RegWrite_in, RegWrite_out);
    
    
endmodule

module MEMWB(
    input clk,
    
    //data signals
    
    input[15:0] rdata_in,
    input[15:0] ALU_in,
    input[1:0] dist_in,
    
    output[15:0] rdata_out,
    output[15:0] ALU_out,
    output[1:0] dist_out,
    
    //control signals
    
     input MemtoReg_in,
     input RegWrite_in,
     
     output MemtoReg_out,
     output RegWrite_out,
     
     input enable,     
     input flush
     
);

    
    latch rdata(enable, flush, clk, rdata_in, rdata_out); 
    latch ALU(enable, flush, clk, ALU_in, ALU_out); 
    latch2 dist(enable, flush, clk, dist_in, dist_out); 

    latch1 MemtoReg(enable, flush, clk, MemtoReg_in, MemtoReg_out);
    latch1 RegWrite(enable, flush, clk, RegWrite_in, RegWrite_out);
    
    
endmodule