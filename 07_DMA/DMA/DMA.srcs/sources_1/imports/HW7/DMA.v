`define WORD_SIZE 16
/*************************************************
* DMA module (DMA.v)
* input: clock (CLK), bus grant (BG) signal, 
*        data from the device (edata), and DMA command (cmd)
* output: bus request (BR) signal
*         write enable (WRITE) signal
*         memory address (addr) to be written by the device, 
*         offset device offset (0 - 2)
*         data that will be written to the memory
*         interrupt to notify DMA is end
* You should NOT change the name of the I/O ports and the module name
* You can (or may have to) change the type and length of I/O ports 
* (e.g., wire -> reg) if you want 
* Do not add more ports! 
*************************************************/

module DMA (
    input CLK, BG,
    input [4 * `WORD_SIZE - 1 : 0] edata,
    input [33:0] cmd,
    output BR, WRITE,
    output [`WORD_SIZE - 1 : 0] addr, 
    output [4 * `WORD_SIZE - 1 : 0] data,
    output [1:0] offset,
    output interrupt);

    /* Implement your own logic */
    
    wire [4 * `WORD_SIZE - 1 : 0] data;
    assign data = BG ? edata : 64'bz;
    
    reg [`WORD_SIZE - 1 : 0] addr;
    initial addr <= 0;
    
    reg WRITE;
    initial WRITE <= 0;
    
    reg BR;
    initial BR <= 0;
    
    reg interrupt;
    initial interrupt <= 0;
    
    wire cmd_on;
    wire[15:0] cmd_addr;
    wire[15:0] cmd_len;
    
    wire d_ready; // if data memory is ready
    
    reg[15:0] startAddr;
    reg[15:0] addr;
    reg[15:0] len;
    reg[1:0] offset;
    
    initial addr <= 16'bz;
    initial offset <= -1;
    
    //decoding cmd
    assign d_ready = cmd[33];
    assign cmd_on = cmd[32];
    assign cmd_addr = cmd[31:16];
    assign cmd_len = cmd[15:0];
    
    //state machine for waiting for write
    
    reg waitingState;
    initial waitingState <= 0;
    
    //cmd is on, the outputs BR
    
    always @(cmd_on) begin
        if(cmd_on) begin
            startAddr <= cmd_addr;
            len <= cmd_len;
            BR <= 1;
            offset <= -1;
        end
    end
    
    always @(posedge CLK) begin
    
//        $display("%b", d_ready);
        
        //if cmd is in, then BR on
        
        
        //if BG is on, write on the memory
        if(!waitingState && BG && len > 0) begin
            $display("len : %d", len);
            waitingState <= 1;
            len <= len - 4;
            addr <= startAddr;
            startAddr <= startAddr + 4;
            offset <= offset + 1;
            WRITE <= 1;
        end
        
    end
    
    always @(d_ready) begin
        if(d_ready && BG && len>0) begin
            len <= len - 4;
            addr <= startAddr;
            startAddr <= startAddr + 4;
            offset <= offset + 1;
            WRITE <= 1;
        end
        
        if(d_ready && BG && len <= 0) begin
            interrupt <= 1;
        end
    end
    
    //if BG is off
    always @(BG) begin
        if(!BG) begin
            BR<=0;
            interrupt <= 0;
            WRITE <= 0;
            waitingState <= 0;
            addr <= 16'bz;
            offset <= -1;
        end
    end

endmodule


