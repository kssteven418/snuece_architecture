`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size

`include "opcodes.v"

module cpu(
        input Clk, 
        input Reset_N, 
        
    //debugging cache interface
        output i_readC,
        output[`WORD_SIZE-1:0] i_addrC,
        output i_readyC,
        output[`WORD_SIZE-1:0] i_dataC,
        
        output d_readC,
        output d_writeC,
        output[`WORD_SIZE-1:0] d_addrC,
        output d_readyC,
        output[`WORD_SIZE-1:0] d_dataC,
        
	// Instruction memory interface
        output i_readM, 
        output i_writeM, 
        output [`WORD_SIZE-1:0] i_addrM, 
        inout [`WORD_SIZE*4-1:0] i_dataM, 
        
        input i_readyM,
        input d_readyM,

	// Data memory interface
        output d_readM, 
        output d_writeM, 
        output [`WORD_SIZE-1:0] d_addrM, 
        inout [`WORD_SIZE*4-1:0] d_dataM, 
        
        
        output[15:0] i_hit,
        output[15:0] i_miss,
        
        output[15:0] d_hit,
        output[15:0] d_miss,
        
        output [`WORD_SIZE-1:0] to_num_inst, //debugging
        output [`WORD_SIZE-1:0] num_inst, 
        output [`WORD_SIZE-1:0] output_port, 
        output is_halted,
        
        output IFID_Flush,
        output IDEX_Flush,
        output EX_isFetched,
        
        //debugging
//        output i_readM,
//        output i_writeM,
//        output[`WORD_SIZE-1:0] i_addressM,
//        output[`WORD_SIZE*4-1:0] i_dataM,
        
        
        output[1:0] ALUsrc1,
        output PC_enable,
        output IDEX_enable,
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
    
    //for counting hits and misses
    
    wire[15:0] i_hit;
    wire[15:0] i_miss;
    
    wire[15:0] d_hit;
    wire[15:0] d_miss;
    
    
    //i_cache
    
    wire i_readM;
    wire i_writeM;
    wire[`WORD_SIZE-1:0] i_addrM;
    wire[`WORD_SIZE*4-1:0] i_dataM;
    
    wire i_readC;
    wire[`WORD_SIZE-1:0] i_addrC;
    wire i_readyC;
    wire[`WORD_SIZE-1:0] i_dataC;
    
    
    Icache icache(
        
        //inverse clk
        .clk(!Clk),
    
        .readC(i_readC),
        .addrC(i_addrC),
        .dataC(i_dataC),
        .readyC(i_readyC),
        
        .readM(i_readM),
        .addrM(i_addrM),
        .dataM(i_dataM),
        .readyM(i_readyM),
        
        .hit(i_hit),
        .miss(i_miss)
        
    
    );
    
    //d_cache
    
        
    wire d_readM;
    wire d_writeM;
    wire[`WORD_SIZE-1:0] d_addrM;
    wire[`WORD_SIZE*4-1:0] d_dataM;
    
    wire d_readC;
    wire d_writeC;
    wire[`WORD_SIZE-1:0] d_addrC;
    wire d_readyC;
    wire[`WORD_SIZE-1:0] d_dataC;
//    always @(posedge Clk) $display("DATAC in CPU : %b", d_dataC);
    
    
    Dcache dcache(
            
        //inverse clk
        .clk(!Clk),
    
        .readC(d_readC),
        .writeC(d_writeC),
        .addrC(d_addrC),
        .dataC(d_dataC),
        .readyC(d_readyC),
        
        .readM(d_readM),
        .writeM(d_writeM),
        .addrM(d_addrM),
        .dataM(d_dataM),
        .readyM(d_readyM),
        
        
        .hit(d_hit),
        .miss(d_miss)
        
    
    );
    
    
    /////////////////////

    reg[`WORD_SIZE-1:0] to_num_inst;
    wire[`WORD_SIZE-1:0] num_inst;
    wire[`WORD_SIZE-1:0] num_inst_bf_delay;
    
    wire[`WORD_SIZE-1:0] output_port;
    wire[`WORD_SIZE-1:0] output_port_temp;
    wire[`WORD_SIZE-1:0] output_port_bf_delay;
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
    
    
    
    ////////////WWD, num_inst logic//////////////

    
    latch1 isFetched(1, 0, Clk, ID_isFetched && !IDEX_Flush, EX_isFetched); 
    latch1 WWD(1, 0, Clk, ID_WWD, EX_WWD); 
    
    wire WWD_delayed;
    
    latch wwd(1, 0, !Clk, EX_WWD, WWD_delayed);
    latch out(1, 0, !Clk, output_port_temp, output_port_bf_delay);
    latch num_in(1, 0, !Clk, num_inst_bf_delay, num_inst);
    latch out_delay(1, 0, !Clk, output_port_bf_delay, output_port);

    assign output_port_temp = EX_WWD ? to_output_port : 15'bz;
    assign num_inst_bf_delay = WWD_delayed ? to_num_inst: 15'bz;
    
    
    reg executed;
    initial executed <= 0;
    always @(EX_inst) begin
        if(executed) to_num_inst <= to_num_inst+1;
        if(EX_inst != 0) executed <= 1;
        if(EX_inst == 0) executed <= 0;
    end
    
    
        
    always @(posedge Clk) $display("NUMINSTRUCTION : %h", to_num_inst);
        
    
    ////////////////////////////////////  


    //stalling and flushing
    wire isStalled;
    
    
    //debugging 
    wire[1:0] ALUsrc1;
    wire PC_enable;
    wire[15:0] IF_inst;
    wire[15:0] ID_inst;
    wire[15:0] EX_inst;
    wire[15:0] ALU_out;
    
    datapath DM(
        .clk(Clk),
        .reset_n(Reset_N),
        
        .i_readM(i_readC),
        .i_writeM(i_writeC),
        .i_address(i_addrC),
        .i_data(i_dataC),
        
        .d_readM(d_readC),
        .d_writeM(d_writeC),
        .d_address(d_addrC),
        .d_data(d_dataC),
        
        .i_ready(i_readyC),
        .d_ready(d_readyC),
        
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
        .ALUsrc1(ALUsrc1),
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

