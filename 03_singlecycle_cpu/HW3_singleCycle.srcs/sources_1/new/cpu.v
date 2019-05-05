`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////
// MODULE: CPU for TSC microcomputer: cpu.v
// Author: 
// Description: 

// DEFINITIONS
`define WORD_SIZE 16    // data and address word size

// INCLUDE files
//`include "opcodes.v"    // "opcode.v" consists of "define" statements for
                        // the opcodes and function codes for all

`define FUNC_ADD 6'd0
`define FUNC_SUB 6'd1
`define FUNC_AND 6'd2
`define FUNC_ORR 6'd3
`define FUNC_NOT 6'd4
`define FUNC_TCP 6'd5
`define FUNC_SHL 6'd6
`define FUNC_SHR 6'd7
`define FUNC_WWD 6'd28

`define OPCODE_ADI 4'd4
`define OPCODE_ORI 4'd5
`define OPCODE_LHI 4'd6
`define OPCODE_LWD 4'd7
`define OPCODE_SWD 4'd8
`define OPCODE_BNE 4'd0
`define OPCODE_BEQ 4'd1
`define OPCODE_BGZ 4'd2
`define OPCODE_BLZ 4'd3
`define OPCODE_JMP 4'd9
`define OPCODE_JAL 4'd10
`define OPCODE_FTN 4'd15


// MODULE DECLARATION
module cpu (
  output readM,                       // read from memory
  output [`WORD_SIZE-1:0] address,    // current address for data
  inout [`WORD_SIZE-1:0] data,        // data being input or output
  input inputReady,                   // indicates that data is ready from the input port
  input reset_n,                      // active-low RESET signal
  input clk,                          // clock signal

  // for debuging/testing purpose
  output [`WORD_SIZE-1:0] num_inst,   // number of instruction during execution
  output [`WORD_SIZE-1:0] output_port // this will be used for a "WWD" instruction
);
  

  // ... fill in the rest of the code
  
  reg [`WORD_SIZE-1:0] num_inst;
  wire [`WORD_SIZE-1:0] output_port;
  
  wire[`WORD_SIZE-1:0] data;
  reg[`WORD_SIZE-1:0] data_reg;
  
  //memory address for the instruction
  wire[`WORD_SIZE-1:0] address;
  assign address = PC;
  
  //PC
  reg[15:0] PC;
  wire[15:0] PC_jump;
  wire[15:0] PC_next;
  
  assign PC_next = jump==0 ? PC+1 : PC_jump;
  
//  always@ (PC_next)
//  $display("%d, %d, %b", num_inst, PC, jump);
  
  //ctrl signals
  wire regWrite;
  wire ALUsrc;
  wire regDst;
  wire jump;
  wire LHI;
  wire WWD;
  wire[3:0] OP;
  //signals from datapath
  wire[3:0] opcode;
  wire[5:0] ftncode;
  wire[11:0] jumpAddr;
  wire[15:0] outData;
  
  assign output_port = WWD==1 ? outData : 2'bzzzzzzzzzzzzzzzz;
    
  reg readM;
  
  
  DataPath datapath(data_reg, clk, regWrite, ALUsrc, regDst, OP, LHI, opcode, ftncode, jumpAddr, outData);
  Controller ctrl(clk, opcode, ftncode, regDst, ALUsrc, regWrite, OP, jump, LHI, WWD);
  JumpConcaternate jumpConcat(PC, jumpAddr, PC_jump);
  
  initial begin
    num_inst <= 0;
    PC <= -1;
    readM <= 0;
  end
  
  //reset data from memory
  always @(posedge inputReady) begin
    data_reg <= data;
    readM <= 0;
  end
    
  always @(data_reg) begin
    $display("instruction : %b", data_reg);
  end
  
//  always @(regWrite) begin
//  $display("regW %b", regWrite);
//  end
  
  always @(posedge clk) begin
    //update PC
    PC<=PC_next;
    //debug
//        $display("%d!!!!!!!!!!!", regWrite);
        
//                $display("PC : %d", PC);
//                $display("PCn : %d", PC_next);
//                $display("inst : %d, %d", opcode, ftncode);
                                
    num_inst <= num_inst+1;
    readM <= 1;
  end
    
  
endmodule


////////////CONTROL MODULE///////////////////

module Controller(
    input clk,
    input [3:0] opcode,
    input [5:0] ftncode,
    output regDst,
    output ALUsrc,
    output regWrite,
    output [3:0] OP,
    output jump,
    output LHI,
    output WWD
);

    reg regDst;
    reg ALUsrc;
    reg regWrite;
    reg[3:0] OP;
    reg jump;
    reg LHI;
    reg WWD;
    
//    assign regDst = opcode==`OPCODE_FTN ? 0:1;
//    assign ALUsrc = opcode==`OPCODE_FTN ? 1:0;
//    assign regWrite = (opcode==`OPCODE_FTN && ftncode==`FUNC_WWD) || opcode==`OPCODE_JMP ? 0:1;
//    assign jump = opcode==`OPCODE_JMP ? 1:0;
//    assign LHI = opcode==`OPCODE_LHI? 1:0;
    
    initial begin
        OP <= 2'b0000;
        jump <= 0;
        LHI <= 0;
        WWD <= 0;
    end
    always @(opcode or ftncode) begin
        
        //  $display("op, ftn in ctrl: %d, %d", opcode, ftncode);
        
        if((opcode==`OPCODE_FTN && ftncode==`FUNC_ADD) || opcode==`OPCODE_ADI) 
            OP<=2'b0000;
        
        if(opcode==`OPCODE_FTN) regDst<=0;
        else regDst<=1;
        
        if(opcode==`OPCODE_FTN) ALUsrc<=1;
        else ALUsrc<=0;
        
        if((opcode==`OPCODE_FTN && ftncode==`FUNC_WWD) || opcode==`OPCODE_JMP) begin
            regWrite<=0; //$display("regWrite 0 : %d, %d", opcode, ftncode);
        end
        else begin 
            regWrite<=1; //$display("regWrite 1 : %d, %d", opcode, ftncode); 
        end
        
        if(opcode==`OPCODE_JMP) jump<=1;
        else jump<=0;
        
        if(opcode==`OPCODE_LHI) LHI<=1;
        else LHI<=0;
       
        if(opcode==`OPCODE_FTN && ftncode==`FUNC_WWD) begin 
            WWD<=1;
        //$display("wwd 1 %b : %d, %d", WWD, opcode, ftncode);
        end
        else begin 
            WWD<=0;
        //$display("wwd 0 %b : %d, %d", WWD, opcode, ftncode);
        end 
        
    end
       

endmodule


////////////DATA PATH Module///////////////////
module DataPath(
    input[`WORD_SIZE-1:0] instruction,
    input clk,
    
    //ctrl signals
    input regWrite,
    input ALUsrc,
    input regDst,
    input[3:0] OP,
    input LTI,
    
    //instructions
    output[3:0] opcode,
    output[5:0] ftncode,
    output[11:0] jumpAddr,
    output[`WORD_SIZE-1:0] outData
);

    
    //decode instruction
    wire[1:0] addr1;
    wire[1:0] addr2;
    wire[1:0] addr3;
    wire[`WORD_SIZE/2-1:0] imm;
    wire[5:0] ftncode;
    wire[3:0] opcode;
    wire[11:0] jumpAddr;
    wire[15:0] outData;
    wire[`WORD_SIZE-1:0] imm_se;
    wire[`WORD_SIZE-1:0] imm_lhi;
    
    //dummy
    wire Cin;
    wire Cout;
    assign Cin=0;
    assign Cout=0;
    
    assign addr1 = instruction[11:10];
    assign addr2 = instruction[9:8];
    assign addr3 = regDst ? instruction[9:8] : instruction[7:6];
    assign imm = instruction[7:0];
    assign opcode = instruction[15:12];
    assign ftncode = instruction[5:0];
    assign jumpAddr = instruction[11:0];
    
    //register file outputs
    wire[`WORD_SIZE-1:0] readData1;
    wire[`WORD_SIZE-1:0] readData2_temp;
    wire[`WORD_SIZE-1:0] readData2;
    assign readData2 = ALUsrc ? readData2_temp : imm_se;
    assign outData = readData1;
    
//    always @(readData1) $display("RD1 : %d", readData1);
//        always @(readData2) $display("RD2 : %d", readData2);
//        always @(imm_se) $display("imm : %d", imm_se);
            
//        always @(readData2_temp) $display("RDtemp : %d", readData2_temp);
        
                                
    
    //ALU output register
    wire[`WORD_SIZE-1:0] ALU_out;
    wire[`WORD_SIZE-1:0] writeData;
    assign writeData = LTI==0 ? ALU_out : imm_lhi;
    
    
//        always @(posedge clk) $display("ALUout : %d", ALU_out);
//        always @(writeData) $display("WData : %d", writeData);
        
    //sign extension && concat module 
    SignExtension se(imm, imm_se);
    LHIConcaternate lhi(imm, imm_lhi);
    //register file(addr1_2, addr2_2, addr3_2, data16, write, clock, o data1_16, 0 data2_16) 
    RegisterFile rf(addr1, addr2, addr3, writeData, regWrite, clk, readData1, readData2_temp);
    //always @(posedge clk) $display("%b, %d" , regDst, addr3);
    //ALU(A16, B16, Cin, OP4, o C16, o Cout)
    ALU alu(readData1, readData2, Cin, OP, ALU_out, Cout);
    
endmodule


//////////SIGN EXTENSION MODULE/////////////

module SignExtension(
    input[`WORD_SIZE/2-1:0] in,
    output[`WORD_SIZE-1:0] out
);
    genvar j;
    wire [`WORD_SIZE-1:0] out;

    assign out[`WORD_SIZE/2-1:0] = in;
    for(j=`WORD_SIZE/2; j<`WORD_SIZE; j=j+1) begin
        assign out[j] = in[`WORD_SIZE/2-1]==0 ? 0 : 1;
    end

endmodule

module LHIConcaternate(
    input[`WORD_SIZE/2-1:0] in,
    output[`WORD_SIZE-1:0] out
);

    genvar j; 
    wire [`WORD_SIZE-1:0] out;
    assign out[`WORD_SIZE-1:`WORD_SIZE/2] = in;
    for(j=0; j<`WORD_SIZE/2; j=j+1) begin
        assign out[j] = 0;
    end

endmodule

module JumpConcaternate(
    input[`WORD_SIZE-1:0] PC,
    input[11:0] jumpAddr,
    output[`WORD_SIZE-1:0] PC_jump
);
    wire [`WORD_SIZE-1:0] PC_jump;
    assign PC_jump[15:12] = PC[15:12];
    assign PC_jump[11:0] = jumpAddr;
     
endmodule


//////////////////////////////////////////////////////////////////////////
