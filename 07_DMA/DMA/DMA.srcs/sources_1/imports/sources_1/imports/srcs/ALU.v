///////////////////////////ALU module//////////////////////////////
module ALU(
    input [15:0] A,
    input [15:0] B,
    input Cin,
    input [3:0] OP,
    output [15:0] C,
    output Cout
    );
    
    reg [15:0] C;
    reg Cout;
    
    reg temp;
    reg temp2;
    reg i;
    
    always @ * begin
        
        
        case (OP)
        
        //ADD operation
        4'b0000: begin
            {Cout, C} = A+B+Cin;
        end       
        
        //SUB operation
        4'b0001: begin
            {Cout, C} = A-B-Cin;
        end
                
    
    
        //LHI operation
        4'b0010 : begin
            C[15:8] <= B[7:0];
            C[7:0] <= 8'b00000000;
            Cout<=0;
        end
        
        //AND operation
        4'b0111: begin
            C<=A&B;
            Cout<=0; 
        end
        
        //OR operation
        4'b1000: begin
            C<=A|B;
            Cout<=0;
        end
        
        //NOT operation
        4'b0110: begin
            C<=~A;
            Cout<=0;
        end
        
        //TCP operation
        4'b1001: begin
            C<=~A+1;
            Cout<=0;
        end
        
        //EQUAL operation
        4'b0101 : begin
            if(A==B) C<=1;
            else C<=0;
            Cout<=0;
        end
        
        //NOTEQUAL operation
        4'b0011: begin
            if(A!=B) C<=1;
            else C<=0;
            Cout<=0;
            
        end
        
        //NOR operation NOT
        4'b0100 : begin
            C<=~(A|B);
            Cout<=0;
        end
        
        //LRS operation
        4'b1010 : begin
            C<=(A>>1);
            Cout<=0;            
        end
        
        //LLS operation
        4'b1101 : begin
            C<=(A<<1);
            Cout<=0;
        end
        
        //ARS operation
        4'b1011 : begin
            temp<=A[15];
            C<=(A>>1);
            if(A[15]==1)
                C[15]<=temp;
        end
        
        //ALS operation
        4'b1110 : begin
            C<=(A<<1);
            Cout<=0;
            
        end
        
        
        //BGZ operation
        4'b1100 : begin
            if(A[15]==0 && A!=0) C<=1;
            else begin C<=0; end
            Cout<=0;
        end

        //BLZ operation
        //1111
        default : begin
            if(A[15]==1 && A!=0) C<=1;
            else C<=0;
            Cout<=0;
        end
                        
        endcase
        
       //$display("ALU : %d, %d, %d, C: %d", A, B, OP, C);
    end
    
endmodule
//////////////////////////////////////////////////////////////////////////