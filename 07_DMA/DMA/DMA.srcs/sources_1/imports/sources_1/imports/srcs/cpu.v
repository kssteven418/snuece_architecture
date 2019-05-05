`timescale 1ns/1ns
`define WORD_SIZE 16    // data and address word size
`define DMA_ADDRESS 500;

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
        
        //for DMA control
        
        input dma_start_int,
        input dma_end_int,
        input BR,
        
        output [32:0] dma_command,
        output BG,
        output dma_on,
        
        //debugging
        
        output IFID_Flush,
        output IDEX_Flush,
        output EX_isFetched,
        
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
        output[15:0] out3,
        
        output stall_all
          
       
);
//    wire clk;
//    assign clk = Clk && !stall_all;
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
    

    wire stall_all_mem; // stall all units by memory
    
    
//    always @(posedge Clk) $display("DATAC in CPU : %b", d_dataC);
    
    
    Dcache dcache(
            
        //inverse clk
        .clk(!Clk),
        .dma_on(dma_on),
        .stall_all(stall_all_mem),
    
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
    
    
    //DMA logics
    
    reg stall_all_int; // stall all units by interrupt
    initial stall_all_int = 0;
    
    
    wire stall_all;
    assign stall_all = stall_all_int || stall_all_mem;
    
    reg BG;
    initial BG <= 0;
    
    reg dma_on_ready;
    initial dma_on_ready <= 0;
    
    reg dma_on; // is dma on activation?
    initial dma_on <= 0;
    
    wire [32:0] dma_command;
    
    assign dma_command[32] = dma_command_on;
    assign dma_command[31:16] = dma_command_addr;
    assign dma_command[15:0] = dma_command_len;
    
    reg [15:0] dma_command_addr;
    reg [15:0] dma_command_len;
    reg dma_command_on;
    
    initial dma_command_addr <= 16'bz;
    initial dma_command_len <= 16'bz;
    initial dma_command_on <= 0;
    
    //if interrupt is in from the ext. device
    always@(dma_start_int) begin
        if(dma_start_int) begin
            stall_all_int<=1;
            dma_command_addr <= `DMA_ADDRESS;
            dma_command_len <= 12;
            dma_command_on <= 1;
            
        end
//        else begin
//            stall_all<=0;
//            dma_command_addr <= 16'bz;
//            dma_command_len <= 16'bz;
//        end
    end
    
    //if BR is in from the DMA controller
    always @(BR) begin
        if(BR) begin
        
            //off the command signal
            dma_command_addr <= 16'bz;
            dma_command_len <= 16'bz;
            dma_command_on <= 0;
            
            stall_all_int <= 0;
            
            dma_on_ready <= 1;
            
        end
        
//        else if(!BR) begin
//            BG <= 0;
//            dma_on <= 0;
//        end
    end
    
    always @(posedge Clk or negedge Clk) begin
        //dma_on and BG only if memory is not being used
        if(dma_on_ready && !BG && !d_readM && !d_writeM) begin
            BG <= 1;
            dma_on_ready <= 0;
            dma_on <= 1;
        end
    end
    
    always @(dma_end_int) begin
    
        if(dma_end_int) begin
            stall_all_int <= 1;
            BG <= 0;           
        end
        
        if(!dma_end_int) begin
            stall_all_int<=0;
            dma_on <= 0;
        end
    
    end
    
     
    
    
    
    ////////////WWD, num_inst logic//////////////

    
    latch1 isFetched(!stall_all, 0, Clk, ID_isFetched && !IDEX_Flush, EX_isFetched); 
    latch1 WWD(!stall_all, 0, Clk, ID_WWD, EX_WWD); 
    
    wire WWD_delayed;
    
    latch wwd(!stall_all, 0, !Clk, EX_WWD, WWD_delayed);
    latch out(!stall_all, 0, !Clk, output_port_temp, output_port_bf_delay);
    latch num_in(!stall_all, 0, !Clk, num_inst_bf_delay, num_inst);
    latch out_delay(!stall_all, 0, !Clk, output_port_bf_delay, output_port);

    assign output_port_temp = EX_WWD ? to_output_port : 15'bz;
    assign num_inst_bf_delay = WWD_delayed ? to_num_inst: 15'bz;
    
    
    reg executed;
    initial executed <= 0;
    always @(EX_inst) begin
        if(executed) to_num_inst <= to_num_inst+1;
        if(EX_inst != 0) executed <= 1;
        if(EX_inst == 0) executed <= 0;
    end
    
    
        
//    always @(posedge Clk) $display("NUMINSTRUCTION : %h", to_num_inst);
        
    
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
        .out3(out3),
        
        .stall_all(stall_all)
        
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

