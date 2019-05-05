/*************************************************
* external_device module (external_device.v)
* input: data (offset) to read from the device
* output: interrupt to request data write to the CPU
*         data that will be written to the memory
* You should NOT change the name of the I/O ports and the module name.
*************************************************/

`define WORD_SIZE 16
`define DATA_SIZE 3
`define DEVICE_BIT_LEN 2

`define FIRE_TIME 63500
`define INTTERRUPT_DURATION 500

module external_device(
    input wire [`DEVICE_BIT_LEN - 1 :0] offset,
    output reg interrupt, 
    output reg [4 * `WORD_SIZE - 1 : 0] data);

    reg [4 * `WORD_SIZE - 1 : 0] storage [`DATA_SIZE - 1 : 0];

    initial begin
        /* Randomized storage initialization.  
        * You may want to change these for the
        * debugging */
       storage[0] <= 64'h1234567890abcdef;
       storage[1] <= 64'h0000111122223333;
       storage[2] <= 64'haabbccddeeff0011;

       interrupt <= 0;

       /* Fire interrupt. You may want to change */
       #(`FIRE_TIME);
       interrupt <=  1;
       /* Interrupt duration. You may want to change */
       #(`INTTERRUPT_DURATION);
       interrupt <=  0;
        
       #(`INTTERRUPT_DURATION*1);
       /* Randomized storage initialization.  
       * You may want to change these for the
       * debugging */
      storage[0] <= 64'h4444555566667777;
      storage[1] <= 64'h888899990000aaaa;
      storage[2] <= 64'hbbbbccccddddeeee;

       /* Another interrupt. You may want to change */
      #(`FIRE_TIME);
      interrupt <=  1;
       /* Interrupt duration. You may want to change */
      #(`INTTERRUPT_DURATION);
      interrupt <=  0;
      
      //$finish;
  end

  /* Data to be send */
  always @(offset) begin
      if (offset < 3) data <= storage[offset];
      else data <= 16'hzzzz;
  end        
endmodule
