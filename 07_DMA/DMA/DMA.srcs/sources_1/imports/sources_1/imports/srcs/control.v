
////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////CONTROL MODULE/////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////


module control(
    input clk,

    input[15:0] inst,
    output ALUsrc,
    output[1:0] RegDist,
    output MemWrite,
    output MemRead,
    output MemtoReg,
    output RegWrite,
    output[3:0] Alucode,
    output Jump,
    output JumpR,
    output Branch,
    output Halt,
        
    //for num_inst
    output isFetched,
    output WWD,
    
    
    input isStalled
);

    reg ALUsrc;
    reg[1:0] RegDist;
    reg MemWrite;
    reg MemRead;
    reg MemtoReg;
    reg RegWrite;
    reg[3:0] Alucode;
    reg Jump;
    reg JumpR;
    reg Branch;
    reg Halt;   
    
    reg isFetched;
    reg WWD;
    

    wire[3:0] opcode;
    wire[5:0] ftncode;

    assign opcode = inst[15:12];
    assign ftncode = inst[5:0];

    initial begin
        ALUsrc <= 0;
        RegDist <= 0;
        MemWrite <= 0;
        MemRead <= 0;
        MemtoReg <= 0;
        RegWrite <= 0;
        Alucode <= 0;
        Jump<=0;
        JumpR<=0;
        Branch<=0;
        Halt<=0;
        
        WWD <= 0;
        isFetched <= 0;
    end

    always @(isStalled) begin
        if(isStalled) begin
            //$display("STALLED!!");
            ALUsrc <= 0;
            RegDist <= 0;
            MemWrite <= 0;
            MemRead <= 0;
            MemtoReg <= 0;
            RegWrite <= 0;
            Alucode <= 0;
            Jump<=0;
            JumpR<=0;
            Branch<=0;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 0;
        end
        
    end
    
    always @(inst or isStalled) begin
       //$display("inst at ctrl module : %h", inst);
        
        if(!isStalled) begin
        
        //bubble
        if(inst==0) begin
            //$display("BUBBLE INSTUCTION!!");
            ALUsrc <= 0;
            RegDist <= 0;
            MemWrite <= 0;
            MemRead <= 0;
            MemtoReg <= 0;
            RegWrite <= 0;
            Alucode <= 0;
            Jump<=0;
            JumpR<=0;
            Branch<=0;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 0;
        end
      
        
        else if(opcode==4 || opcode==5 || opcode==6) begin
            ALUsrc <= 1;
            RegDist <= 0;
            MemWrite <= 0;
            MemRead <= 0;
            MemtoReg <= 0;
            RegWrite <= 1;
            Jump<=0;
            JumpR<=0;
            Branch<=0;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 1;
            
            //ADI
            if(opcode==4) begin
                //$display("ctrl : ADI");
                Alucode <= 4'b0000;
            end
            
            //ORI
            if(opcode==5) begin
                //$display("ctrl : ORI");
                Alucode <= 4'b1000;
            end
            
            //LHI
            if(opcode==6) begin
                //$display("ctrl : LHI");
                Alucode <= 4'b0010;
            end
            
        end
        
        else if(opcode==15 && ftncode!=28 && ftncode!=25 && ftncode!=26 && ftncode!=29) begin
           // $display("ctrl : ALU R-type");
            ALUsrc <= 0;
            RegDist <= 1;
            MemWrite <= 0;
            MemRead <= 0;
            MemtoReg <= 0;
            RegWrite <= 1;
            Jump<=0;
            JumpR<=0;
            Branch<=0;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 1;
            
            //ADD
            if(ftncode==0) begin
                //$display("ctrl : ADD");
                Alucode <= 4'b0000;
            end
            
            //SUB
            if(ftncode==1) begin
                //$display("ctrl : SUB");
                Alucode <= 4'b0001;
            end
            
            //AND
            if(ftncode==2) begin
                //$display("ctrl : AND");
                Alucode <= 4'b0111;
            end
            
            //ORR
            if(ftncode==3) begin
                //$display("ctrl : ORR");
                Alucode <= 4'b1000;
            end
            
            //NOT
            if(ftncode==4) begin
                //$display("ctrl : NOT");
                Alucode <= 4'b0110;
            end
            
            //TCP
            if(ftncode==5) begin
                //$display("ctrl : TCP");
                Alucode <= 4'b1001;
            end
            
            //SHL
            if(ftncode==6) begin
                //$display("ctrl : SHL");
                Alucode <= 4'b1101;
            end
            
            //SHR
            if(ftncode==7) begin
                //$display("ctrl : SHR");
                Alucode <= 4'b1010;
            end
            
            
            
        end
        
        //WWD
        else if(opcode==15 && ftncode==28) begin
            //$display("ctrl : WWD");
            MemWrite <= 0;
            MemRead <= 0;
            RegWrite <= 0;
            Jump<=0;
            JumpR<=0;
            Branch<=0;
            Halt<=0;
            
            WWD <= 1;
            isFetched <= 1;
            
        end
        
        //LWD
        else if(opcode==7) begin
        
            //$display("ctrl : LWD");
            ALUsrc <= 1;
            RegDist <= 0;
            MemWrite <= 0;
            MemRead <= 1;
            MemtoReg <= 1;
            RegWrite <= 1;
            Alucode <= 4'b0000;
            Jump<=0;
            JumpR<=0;
            Branch<=0;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 1;
        end
        
        //SWD
        else if(opcode==8) begin
        
            //$display("ctrl : SWD");
            ALUsrc <= 1;
            MemWrite <= 1;
            MemRead <= 0;
            RegWrite <= 0;
            Alucode <= 4'b0000;
            Jump<=0;
            JumpR<=0;
            Branch<=0;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 1;
        end
        
        //JMP
        else if(opcode==9) begin
            
            //$display("ctrl : JMP");
            MemWrite <= 0;
            MemRead <= 0;
            RegWrite <= 0;
            Jump<=1;
            JumpR<=0;
            Branch<=0;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 1;
        end
        
        //JAL
        else if(opcode==10) begin
            
            //$display("ctrl : JAL");
            MemWrite <= 0;
            MemRead <= 0;
            RegWrite <= 1;
            Jump<=1;
            JumpR<=0;
            Branch<=0;
            RegDist = 2'b10;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 1;
        end    
        
        //JPR
        else if(opcode==15 && ftncode==25) begin
            
            //$display("ctrl : JPR");
            MemWrite <= 0;
            MemRead <= 0;
            RegWrite <= 0;
            Jump<=0;
            JumpR<=1;
            Branch<=0;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 1;
        end
        
        
        //JRL
        else if(opcode==15 && ftncode==26) begin
           
            //$display("ctrl : JRL");
            MemWrite <= 0;
            MemRead <= 0;
            RegWrite <= 1;
            Jump<=0;
            JumpR<=1;
            Branch<=0;
            RegDist = 2'b10;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 1;
        end
        
        //Brahches
        else if(opcode==0 || opcode==1 || opcode==2 || opcode==3) begin
        
            //$display("ctrl : Branches");
        
            ALUsrc <= 0;
            MemWrite <= 0;
            MemRead <= 0;
            RegWrite <= 0;
            Jump<=0;
            JumpR<=0;
            Branch<=1;
            Halt<=0;
                    
            WWD <= 0;
            isFetched <= 1;
            
            if(opcode==0) Alucode <= 4'b0011; 
            if(opcode==1) Alucode <= 4'b0101; 
            if(opcode==2) Alucode <= 4'b1100; 
            if(opcode==3) Alucode <= 4'b1111; 

        end
        
        //HLT
        else if(opcode==15 && ftncode == 29) begin
            Halt<=1;
            
        
        end
        
        else begin
            //$display("ctrl : nothing!");
           
            MemWrite <= 0;
            MemRead <= 0;
            RegWrite <= 0;
            Jump<=0;
            JumpR<=0;
            Branch<=0;
            Halt<=0;
            
            WWD <= 0;
            isFetched <= 0;
            
        end
        
    end
    
    end


    


endmodule
