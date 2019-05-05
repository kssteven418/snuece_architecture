`timescale 1ns / 1ps


module cacheLine(
    
    input clk,
    
    //for read 
    input rWrite,
    input[11:0] targetTag,
    input[63:0] targetData,
    
    //for write
    input wWrite,
    input[1:0] targetBlock,
    input[15:0] targetDataWrite,
    
    //debugging
    input[1:0] num,
    
    output valid,
    output[11:0] tag,
    output[63:0] data
);

    wire wWrite;
    
    reg valid;
    reg[11:0] tag;
    reg[63:0] data;
    
    initial valid<= 0;
    
    initial tag <= 0;
    
    //read data update
    always @(rWrite) begin
        
        if(rWrite) begin
            
            valid <= 1;
            data <= targetData;
            tag <= targetTag;
//            $display("TARGET Data : %h", targetData);
                        
        end
    
    end
    
    //write dat update
    always @(wWrite) begin
        
//            $display("ACK...");
            
        if(wWrite) begin
        
            if(targetBlock==3) data[15:0]<=targetDataWrite;
            else if(targetBlock==2) data[31:16]<=targetDataWrite;
            else if(targetBlock==1) data[47:32]<=targetDataWrite;
            else if(targetBlock==0) data[63:48]<=targetDataWrite;
//            $display("Written in Cache: %h", data);
        
        end
    
    end
    
//    always @(posedge clk) $display("SIBAL : %h, wWrite %b", num, wWrite);
  

endmodule

module Dcache(

    //inverse clk
    input clk,
    
    //for dma control
    input dma_on,
    output stall_all,

    input readC,
    input writeC,
    input[15:0] addrC,
    inout[15:0] dataC,
    output readyC,
    
    output readM,
    output writeM,
    output[15:0] addrM,
    inout [63:0] dataM,
    input readyM,
    
    output[15:0] hit,
    output[15:0] miss
);
    
    reg stall_all;
    initial stall_all <= 0;
    
    //for counting hits & misses
    reg[15:0] hit;
    reg[15:0] miss;
    initial hit<=0;
    initial miss<=0;
    
    
    ////get targets from addr
    
    wire[11:0] targetTag;
    wire[1:0] targetIdx;
    wire[1:0] targetBlock;
    
//    always@ targetIdx $display("targetIdx %b", targetIdx );
    
    assign targetTag = addrC[15:4];
    assign targetIdx = addrC[3:2];
    assign targetBlock = addrC[1:0];
    
    //////initiate cache lines
    
    integer i;
    
    wire valids[3:0];
    wire[11:0] tags[3:0];
    wire[63:0] datas[3:0];
   
    reg rWrite[3:0];
    initial rWrite[0]<=0;
    initial rWrite[1]<=0;
    initial rWrite[2]<=0;
    initial rWrite[3]<=0;
    
    reg wWrite[3:0];
    initial wWrite[0]<=0;
    initial wWrite[1]<=0;
    initial wWrite[2]<=0;
    initial wWrite[3]<=0;
    
    reg[1:0] nums[3:0];
    initial nums[0] <= 0; 
    initial nums[1] <= 1; 
    initial nums[2] <= 2; 
    initial nums[3] <= 3;
     
    generate
        genvar k;
        for(k=0; k<4; k=k+1) begin : dff
            cacheLine cl( 
            .clk(clk),
           
           //for read 
           .rWrite(rWrite[k]),
           .targetTag(targetTag),
           .targetData(dataM),
           
           //for write
           .wWrite(wWrite[k]),
           .targetBlock(targetBlock),
           .targetDataWrite(dataC),
           
           .num(nums[k]),
           
           .valid(valids[k]),
           .tag(tags[k]),
           .data(datas[k])
           
           );
        end
    endgenerate
    
    //////outputs    
        
    reg readyC;
    initial readyC<=1;
    
    wire[15:0] dataC;
    assign dataC = !readC ? 16'bz :
                   targetBlock==0 ? datas[targetIdx][63:48] : 
                   targetBlock==1 ? datas[targetIdx][47:32] : 
                   targetBlock==2 ? datas[targetIdx][31:16] : 
                   datas[targetIdx][15:0];
                   
    
//    always @(posedge clk) $display("DATAC in Cache : %h, %h, readC : %b, targetBlock : %h", dataC, datas[targetIdx], readC, targetBlock);
    
    
    reg readM;
    initial readM<=0;
    
    reg writeM;
    initial writeM<=0;
    
    wire[15:0] addrM;
    assign addrM = addrC;
    
    wire[63:0] dataM;
    wire[63:0] dataC_toWrite; // extended dataC into 64 bit
//    always@(posedge clk) $display("DATAC : %h", dataC);
    
    assign dataC_toWrite[15:0] = dataC;
    assign dataC_toWrite[53:16] = 48'bz;
    
    assign dataM = writeM ? dataC_toWrite : 64'bz;
    
//    always @(posedge clk) begin
//        $display("%h", dataM);
//    end
        
        
    
        
    always @(posedge clk) begin
    
//        $display("TAGS : %h, %h, %h, %h", tags[0], tags[1], tags[2], tags[3]);
//        $display("VALIDS : %b, %b, %b, %b", valids[0], valids[1], valids[2], valids[3]);
//        $display("WWRITES : %b, %b, %b, %b", wWrite[0], wWrite[1], wWrite[2], wWrite[3]);
   
    end
    
    /////////////////////////////read logic///////////////////////////////
    
    reg dma_waitState;
    initial dma_waitState <= 0;
    
    reg waitState;
    initial waitState <= 0;
    
    reg readState;
    initial readState <= 0;
    
    always @(readC or addrC or targetIdx or targetTag) begin
        
        waitState <= 0;
        readState <= 0;
        
        if(readC) begin
            
            //hit
            if(targetTag==tags[targetIdx] && valids[targetIdx]) begin
//                $display("HIT, %b, %h, %h", readC, addrC, targetIdx);
                //$display("HIT, t.index %h, t.tag %h,  ");
                readM<=0;
                readyC<=1; 
                hit <= hit+1;
            end
            
            //miss
            else begin
                //dma not on activation
                if(!dma_on) begin
                    readyC <= 0;
        //                $display("MISS, %b, %h, %h", readC, addrC, targetIdx);
        //                $display("readyM %b, waitState %b, readM %b, clk %b", readyM, waitState, readM, clk);
                    readM <= 1;
                    waitState <= 1;
                end
                
                //dma on activation
                if(dma_on) begin
                    dma_waitState <= 1;
                    stall_all <= 1;
                end
            end    
        end
        
    end
    
    always @(dma_on) begin
        
        if(!dma_on && dma_waitState) begin
            
            dma_waitState <= 0;
            stall_all <= 0;
            
            readyC <= 0;
            readM <= 1;
            waitState <= 1;
        end
    end
    
    ///////////////////////////////write logic//////////////////////////////
    
    reg dma_writeState;
    initial dma_writeState <= 0;
    
    reg writeState;
    initial writeState <= 0;
    
    
    always @(writeC or addrC or targetIdx or targetTag) begin
        
        writeState <= 0;
        
        if(writeC) begin
            
            
            
            //write hit - write Through
            if(targetTag==tags[targetIdx] && valids[targetIdx]) begin
//                $display("WRITE HIT!.!");
                hit <= hit+1;
                //write in cache
                for(i=0; i<4; i=i+1) begin
                    if(i==targetIdx) wWrite[i] <= 1;
                    else wWrite[i] <= 0;
                end
                
                //dma not on activation
                if(!dma_on) begin
                    readyC <= 0;
                    //go to mem write stage
                    writeState <= 1;
                    writeM <= 1;
                end
                
                //dma on activation
                if(dma_on) begin
                    dma_writeState <= 1;
                    stall_all <= 1;
                end
                
            end
            
            //write miss - write non allocate
            else begin
//                $display("WRITE MISS");
                miss <= miss+1;
                
                //dma not on activation
                if(!dma_on) begin
                    readyC<=0;
                    writeState <= 1;
                    writeM <= 1;
                end
                
                //dma on activation
                if(dma_on) begin
                    dma_writeState <= 1;
                    stall_all <= 1;
                end
            end
        
        end
        
    end
    
     always @(dma_on) begin
           
        if(!dma_on && dma_writeState) begin
           
           dma_writeState <= 0;
           stall_all <= 0;
           
           
           readyC<=0;
           writeState <= 1;
           writeM <= 1;
        end
       
     end
    
//    always @(wWrite[targetIdx]) $display("WWRITE :%b, %h", wWrite[targetIdx], targetIdx);
        
    
    //////////////////////////common update logic//////////////////////////////
    
    always @(negedge clk) begin
        
        
        if(readyM && waitState) begin
//            $display("WAITSTATE");
//            $display("DCACHE WAITSTATE, TA : %b, rWrite : %b", targetIdx, rWrite[targetIdx]);
            waitState <= 0;
            readState <= 1;
            for(i=0; i<4; i=i+1) begin
                if(i==targetIdx) rWrite[i] <= 1;
                else rWrite[i] <= 0;
            end
        end
        
        if(readState) begin
//            $display("READSTATE");
//            $display("DCACHE READSTATE, %h", dataM);
             for(i=0; i<4; i=i+1) rWrite[i] <= 0;
            readState <= 0;
            readyC <= 1;
            readM<=0;
            miss <= miss+1;
        end
        
        //wait for mem write
        if(writeState && !readyM) begin
            readyC<= 0;
            for(i=0; i<4; i=i+1) wWrite[i] <= 0;
        end
        
        if(writeState && readyM) begin
            readyC<= 1;
            writeM <= 0;
            writeState <= 0;
            for(i=0; i<4; i=i+1) wWrite[i] <= 0;
                           
        end
    
    end     
        


endmodule


module Icache(
    
    //inverse clk
    input clk,

    input readC,
    input[15:0] addrC,
    inout[15:0] dataC,
    output readyC,
    
    output readM,
    output[15:0] addrM,
    inout [63:0] dataM,
    input readyM,
    

    output[15:0] hit,
    output[15:0] miss
);
    
    //for counting hits & misses
    reg[15:0] hit;
    reg[15:0] miss;
    initial hit<=0;
    initial miss<=0;
    
    ////get targets from addr
    
    wire[11:0] targetTag;
    wire[1:0] targetIdx;
    wire[1:0] targetBlock;
    
//    always@ targetIdx $display("targetIdx %b", targetIdx );
    
    assign targetTag = addrC[15:4];
    assign targetIdx = addrC[3:2];
    assign targetBlock = addrC[1:0];
    
    
    //////initiate cache lines
    
    wire valids[3:0];
    wire[11:0] tags[3:0];
    wire[63:0] datas[3:0];
    
    
    reg rWrite[3:0];
    initial rWrite[0]<=0;
    initial rWrite[1]<=0;
    initial rWrite[2]<=0;
    initial rWrite[3]<=0;
    
    generate
        genvar k;
        for(k=0; k<4; k=k+1) begin : dff
            cacheLine cl( 
            .clk(clk),
           
           //for read 
           .rWrite(rWrite[k]),
           .targetTag(targetTag),
           .targetData(dataM),
           
           .valid(valids[k]),
           .tag(tags[k]),
           .data(datas[k])
           
           );
        end
    endgenerate
    
    
    //////outputs    
    
    reg readyC;
    initial readyC<=0;
    
    wire[15:0] dataC;
    assign dataC = targetBlock==0 ? datas[targetIdx][63:48] : 
                   targetBlock==1 ? datas[targetIdx][47:32] : 
                   targetBlock==2 ? datas[targetIdx][31:16] : 
                   datas[targetIdx][15:0];
    
    reg readM;
    initial readM<=0;
    
    wire[15:0] addrM;
    assign addrM = addrC;
    
    
    //logic
    
    reg waitState;
    initial waitState<=0;
    
    reg readState;
    initial readState <= 0;
    
    
    always @(readC or addrC or targetIdx) begin
        
        waitState <= 0;
        readState <= 0;
        
        if(readC) begin
            
            //hit
            if(targetTag==tags[targetIdx] && valids[targetIdx]) begin
//                $display("HIT");
                //$display("HIT, t.index %h, t.tag %h,  ");
               readyC<=1; 
               hit <= hit+1;
            end
            
            //miss
            else begin
            
                readyC <= 0;
//                $display("MISS");
//                $display("readyM %b, waitState %b, readM %b, clk %b", readyM, waitState, readM, clk);
                readM <= 1;
                waitState <= 1;
            end    
        end
        
    end
    
    always @(negedge clk) begin
        
//        $display("readyM %b, waitState %b", readyM, waitState);
        
        if(readyM && waitState) begin
//            $display("WAITSTATE, TA : %b, rWrite : %b", targetIdx, rWrite[targetIdx]);
            waitState <= 0;
            readState <= 1;
            rWrite[targetIdx] <= 1;
        end
        
        if(readState) begin
//            $display("READSTATE");
            rWrite[targetIdx] <= 0;
            readState <= 0;
            readyC <= 1;
            miss <= miss+1;
        end
    
    end
    
    
endmodule
