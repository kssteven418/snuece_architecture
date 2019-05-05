`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2017 04:09:41 PM
// Design Name: 
// Module Name: registerFile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module RegisterFile(
    input [1:0] addr1,
    input [1:0] addr2,
    input [1:0] addr3,
    input [15:0] data,
    input write,
    input clock,
    input reset_n,
    output [15:0] data1,
    output [15:0] data2,
    
    output[15:0] out0,
    output[15:0] out1,
    output[15:0] out2,
    output[15:0] out3
    
    
    );
    
    parameter num = 4;
    
    reg[num-1:0] writeReg;
    
    wire[15:0] outs[num-1:0];
    
    
    integer i;
        
    integer n = 1;
    
    generate
      genvar k;
      for (k=0; k<15; k=k+1) begin : dff
        Register regs(writeReg[k], clock, data, reset_n, outs[k]);
      end
    endgenerate
    
    
    reg [15:0] data1;
    reg [15:0] data2;
    
    initial begin
        data1<=outs[addr1];
        data2<=outs[addr2];
        
    end
    
    wire[15:0] out0;
    wire[15:0] out1;
    wire[15:0] out2;
    wire[15:0] out3;
    
    assign out0 = outs[0];
    assign out1 = outs[1];
    assign out2 = outs[2];
    assign out3 = outs[3];
    
    
        
    //input -> target change
    always @(addr3 or write) begin
        for(i=0;i<num;i=i+1) begin
            if(i==addr3) writeReg[i]=write;
            else writeReg[i]=0;
        end
    end
    
    
    //data read
    always @(addr1 or addr2 or outs[addr1] or outs[addr2]) begin
        data1<=outs[addr1];
        data2<=outs[addr2];
    end
    
    //debugging
    always @(outs[0] or outs[1] or outs[2] or outs[3]) begin
        //$display("RF changed : %h, %h, %h, %h", outs[0], outs[1], outs[2], outs[3]);
                //$display("RF changed: %d, %d, %d", addr1, addr2, addr3);
        n = n+1;
    end
    
    
endmodule