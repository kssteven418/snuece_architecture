
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/24/2017 03:59:40 PM
// Design Name: 
// Module Name: Register
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


module Register(
    input write,
    input CLK,
    input [15:0] data,
    output [15:0] out
    );
    
    reg[15:0] out;
    
    
    
    initial out<=2'bxxxxxxxxxxxxxxxx;
    
    always @(posedge CLK) begin
        if(write==1) out<=data;
        else out<=out;    
    end
    
endmodule