

///////////////////////////////////////////////////////////////////////////
///////////////////////////SIGN EXTENSTION MODULE//////////////////////////
///////////////////////////////////////////////////////////////////////////

module signExtension(
    input [7:0] in,
    output [15:0] out
);

    genvar j;
    wire [15:0] out;

    assign out[7:0] = in;
    for(j=8; j<16; j=j+1) begin
        assign out[j] = in[7]==0 ? 0 : 1;
    end

endmodule



///////////////////////////////////////////////////////////////////////////
/////////////////////////////FORWARDING UNIT///////////////////////////////
///////////////////////////////////////////////////////////////////////////


module forward(

    input MEM_RegWrite,
    input WB_RegWrite,
    input[1:0] MEM_dest,
    input[1:0] WB_dest,
    input[1:0] EX_rs,
    input[1:0] EX_rt,
    
    output[1:0] ALUsrc1,
    output[1:0] ALUsrc2

);

    reg[1:0] ALUsrc1;
    reg[1:0] ALUsrc2;

    initial begin
      
       ALUsrc1<=2'b00;
       
       ALUsrc2<=2'b00;
    end

    always @(*) begin
        if(MEM_RegWrite && EX_rs==MEM_dest) begin 
            ALUsrc1<=2'b10;
        end
        
        else if(WB_RegWrite && EX_rs==WB_dest) begin
            ALUsrc1<=2'b11;
        end
        
        else ALUsrc1<=2'b00;
    
        if(MEM_RegWrite && EX_rt==MEM_dest) begin
            ALUsrc2<=2'b10;
        end
        
        else if(WB_RegWrite && EX_rt==WB_dest) begin
            ALUsrc2<=2'b11;
        end
        
        else ALUsrc2<=2'b00;
    
    end 


endmodule


///////////////////////////////////////////////////////////////////////////
/////////////////////////////STALLING UNIT/////////////////////////////////
///////////////////////////////////////////////////////////////////////////


module stalling(

    input EX_MemRead,
    input EX_MemWrite,
    input[1:0] EX_dest,
    input[15:0] inst,
    
    
    output isStalled
);

reg isStalled;
initial isStalled <= 0;

wire[1:0] ID_rt;
wire[1:0] ID_rs;
wire[5:0] ftncode;
wire[3:0] opcode;

assign ID_rt = inst[9:8];
assign ID_rs = inst[11:10];
assign ftncode = inst[5:0];
assign opcode = inst[15:12];

wire use_rs;
wire use_rt;

assign use_rs = !(opcode==9 || opcode==10);
assign use_rt = (opcode==15 && (ftncode==0 || ftncode==1 || ftncode==2 || ftncode==3));


//EX stage MEM_Read, ID stage using same register
always @(*) begin
    
    if(EX_MemRead && ID_rs==EX_dest && use_rs) begin
        isStalled <= 1;
    end
    else if(EX_MemRead && ID_rt==EX_dest && use_rt) begin
        isStalled <= 1;
    end
    
//    //stalling only for debugging purpose
//    else if((EX_MemRead || EX_MemRead) || (opcode==7 || opcode==8)) begin
//        isStalled <= 1;
//    end
    
    
    else begin
        isStalled <= 0;
    end


end

endmodule



///////////////////////////////////////////////////////////////////////////
/////////////////////////////FLUSHING UNIT/////////////////////////////////
///////////////////////////////////////////////////////////////////////////

module flushing(
    input Jump,
    input JumpR,
    input Branch,
    
    output IFID_Flush,
    output IDEX_Flush,
    output[1:0] PCsrc

);

reg IFID_Flush;
reg IDEX_Flush;
reg[1:0] PCsrc;

initial begin
    IFID_Flush <= 0;
    IDEX_Flush <= 0;
    PCsrc <= 2'b00;
end    

always @(*) begin
    
    
    if(Branch) begin
        IFID_Flush <= 1;
        IDEX_Flush <= 1;
        PCsrc <= 2'b11;
    end
       
    else if (JumpR) begin
        IFID_Flush <= 1;
        IDEX_Flush <= 1;
        PCsrc <= 2'b10;
    end
    
    else if (Jump) begin
        IFID_Flush <= 1;
        IDEX_Flush <= 0;
        PCsrc <= 2'b01;
    end
    
    else begin
        IFID_Flush <= 0;
        IDEX_Flush <= 0;
        PCsrc <= 2'b00;
    end    
        
    
end

endmodule



///////////////////////////////////////////////////////////////////////////
///////////////////////////Target Address Unit/////////////////////////////
///////////////////////////////////////////////////////////////////////////


module targetAddress(

    input[15:0] inst,
    input[15:0] ID_pc,
    input[15:0] EX_pc,
    input[15:0] offset,
    input[15:0] ALU_in1,
    
    input ID_Jump,
    input EX_JumpR,
    input EX_Branch,
    output[15:0] jumpAddr,
    output[15:0] jumpRAddr,
    output[15:0] branchAddr
);

reg[15:0] jumpAddr;
reg[15:0] jumpRAddr;
reg[15:0] branchAddr;


always @(*) begin

    if(EX_Branch) begin
        branchAddr = EX_pc + offset + 1;
    end
    
    //JAR, JLR
    else if(EX_JumpR) begin
        jumpRAddr =  ALU_in1;  
    end
    
    //JMP , JAL
    else if(ID_Jump) begin
        jumpAddr[15:12] <= ID_pc[15:12];
        jumpAddr[11:0] <= inst[11:0];
    end
    
    
    
end

endmodule


///////////////////////////////////////////////////////////////////////////
////////////////////////////////HALT Unit//////////////////////////////////
///////////////////////////////////////////////////////////////////////////


module halt(
    input EX_Halt,
    input clk,
    
    output is_halted
);

reg[1:0] timing;
reg halted;

reg is_halted;

initial begin
    halted <= 0;
    timing <= 0;
    is_halted <= 0;

end

always@(EX_Halt) begin

    if(EX_Halt) begin
        timing <= 3;
        halted <= 1;
    end

end

always @(clk) begin

    if(halted==1) begin
        if(timing==0) is_halted <= 1;
        else timing <= timing-1;
    end
    
end

endmodule