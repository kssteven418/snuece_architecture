

module brenchPred(
    //read input
    input clk,
    input[15:0] pc,
    input[15:0] pc_next, //pc+1
    
    //write input for btb
    input update,
    input[15:0] pc_update,
    input[15:0] target_addr,
    
    //write input for bht
    input bht_update,
    input taken,

    output pred,
    
    output[15:0] pc_pred
    
    
);
    
    integer i;
    
    reg[15:0] pc_pred;
    initial pc_pred<=0;
    
    wire valid;
    wire[7:0] tag;
    wire[15:0] addr;
    
    wire pred;
    
//    //bhsr
//    reg[7:0] BHSR;
    
//    initial begin
//        for(i=0; i<8; i=i+1) begin
//            BHSR[i] <= 0;
//        end
//    end
    
//    always @(negedge clk) begin
    
////        if(bhsr_update) begin
////            for(i=0; i>=1; i=i-1) BHSR[i] = BHSR[i-1];
////            BHSR[0] = bhsr_input;
            
////        end
    
//    end
    
    
    btb BTB(
    
        //read input
        .clk(clk),
        .pc(pc),
//        .BHSR(BHSR),
        
        //write input
        .update(update),
        .pc_update(pc_update),
        .target_addr(target_addr),
        
        //read output
        .valid(valid),
        .tag(tag),
        .addr(addr)
    );
    
    bht BHT(
        .clk(clk),
        .pc( pc),
        
        //write input
        .update(bht_update),
        .taken(taken),
        .pc_update(pc_update),
        
        //read output
        .pred(pred)
    
    );

    
    wire[15:0] pc_tag;
    assign pc_tag = pc[15:8];
    
    //hit : pc<=addr from BTB, miss : pc<=pc+1(pc_next)
    always@(pc or pc_next or valid or tag or addr) begin
        if(valid && pc_tag==tag && pred) pc_pred <= addr;
        else pc_pred <= pc_next;
    end

endmodule
    

module bht(
    input clk,
    input[15:0] pc,
    
    //write input
    input update,
    input taken,
    input[15:0] pc_update,
    
    //read output
    output pred

);

    integer i;
    
    reg pred;
    initial pred <= 0;
    
    reg updates[255:0];
    initial begin
        for(i=0; i<256; i=i+1) updates[i] <= 0;
    end
    
    wire preds[255:0];
    
    generate
        genvar k;
        for(k=0; k<255; k=k+1) begin : dff
            bhtLine BHTL(clk, updates[k]&&update, taken, preds[k], pc_update_idx);
        end
    endgenerate
    
    wire[7:0] pc_idx;
    wire[7:0] pc_update_idx;
   
    assign pc_idx = pc[7:0]; // XOR
    assign pc_update_idx = pc_update[7:0];
    
    always @(pc) begin
        pred = preds[pc_idx];
        
    end
        
    always @(pc_update_idx) begin
        
        for(i=0; i<256; i=i+1) begin
            updates[i] <= 0;
        end
        
        updates[pc_update_idx] <= 1;
        
    end
    
    

endmodule    
    

module btb(

    //read input
    input clk,
    input[15:0] pc,
    //input[7:0] BHSR,
    
    //write input
    input update,
    input[15:0] pc_update,
    input[15:0] target_addr,
    
    //read output
    output valid,
    output[15:0] tag,
    output[15:0] addr
);

    
    integer i;

    
    //outputs
    
    reg valid;
    reg[7:0] tag;
    reg[15:0] addr;
    
    initial begin
        valid <= 0;
        tag <= 0;
        addr <= 0;
    end
    
    
    //line initiation
    
    reg updates[255:0];
    initial begin
        for(i=0; i<256; i=i+1) updates[i] <= 0;
    end
    
    wire valids[255:0];
    wire[7:0] tags[255:0];
    wire[15:0] addrs[255:0];
    
    generate
        genvar k;
        for(k=0; k<255; k=k+1) begin : dff
            btbLine lines(clk, update && updates[k], pc_update, target_addr, valids[k], tags[k], addrs[k]);
            
        end
    endgenerate
    
    
    wire[7:0] pc_idx;
    wire[7:0] pc_update_idx;
    
    assign pc_idx = pc[7:0]; // XOR
    assign pc_update_idx = pc_update[7:0];
    
    always @(pc) begin
        valid = valids[pc_idx];
        tag = tags[pc_idx];
        addr = addrs[pc_idx];
        
    end
    
    always @(pc_update_idx) begin
        
        for(i=0; i<256; i=i+1) begin
            updates[i] <= 0;
        end
        
        updates[pc_update_idx] <= 1;
        
    end
    

endmodule

module bhtLine(
    input clk,
    input update,
    input taken,
    
    output pred,
    
    input[7:0] pc_update_idx
);

    reg[1:0] state;
    initial state <= 2'b10;
    
    wire pred;
    assign pred = state[1];
    
    
    always @(posedge clk) begin
    
        if(update) begin
            $display("State : %b to!", state);

            //2-bit
            
            //11 - 10 -/- 01 - 00
            if(taken) begin
                if(state!=2'b11) state = state+1;
            end
            
            else begin
                if(state!=2'b00) state = state-1;
            end

//            //1-bit
//            if(taken) begin
//                if(state==2'b01) state = state+1;
//            end
            
//            else begin
//                if(state==2'b10) state = state-1;
//            end
            
            $display("State : %b", state);
            //always taken
//            state<=2'b10;
            
//            //always non-taken
//            state<=2'b01;
            
            
            
        end
    end

endmodule

module btbLine(
    input clk,      
    input update,
    input[15:0] pc_update,
    input[15:0] target_addr,

    output valid,
    output[7:0] tag,
    output[15:0] addr
    
);

    reg valid;
    reg[7:0] tag;
    reg[15:0] addr;

    initial begin
    
        valid<=0;
        tag<=0;
        addr<=0;
    
    end
    
    
    //update at every clk
    
    always @(posedge clk) begin
        
        if(update) begin
            valid <= 1;
            tag <= pc_update[15:8];
            addr <= target_addr;
        end
        
    end

endmodule
    

