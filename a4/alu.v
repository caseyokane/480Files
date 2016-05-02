// basic sizes of things
`define WORD	[15:0]
`define OP	[4:0]
`define Opcode	[15:12]
`define Dest	[11:6]
`define Src	[5:0]

// opcode values, also state numbers
`define OPadd	4'b0000
`define OPinvf	4'b0001
`define OPaddf	4'b0010
`define OPmulf	4'b0011
`define OPand	4'b0100
`define OPor	4'b0101
`define OPxor	4'b0110
`define OPany	4'b0111
`define OPdup	4'b1000
`define OPshr	4'b1001
`define OPf2i	4'b1010
`define OPi2f	4'b1011


//Provided helper module for determining the number of leading 0s
//Provide a 16 bit floating point number and receive the number of 0s
module lead0s(d, s);

input wire `WORD  s;
output reg[4:0] d; 
reg[7:0] s8; reg[3:0] s4; reg[1:0] s2;

always @(*) begin
  if(s[15:0] == 0) d = 16; 
  else begin
    d[4] = 0;
    {d[3],s8} = ((|s[15:8]) ? {1'b0,s[15:8]} : {1'b1,s[7:0]});  
    {d[2],s4} = ((|s8[7:4]) ? {1'b0,s8[7:4]} : {1'b1,s8[3:0]});  
    {d[1],s2} = ((|s4[3:2]) ? {1'b0,s4[3:2]} : {1'b1,s4[1:0]});  
    d[0] = !s2[1];
  end
end
endmodule

module alu(result, op, in1, in2);

output reg `WORD result;
input wire `OP op;
input wire `WORD in1, in2;

//Added variables
reg `WORD absValue; reg `WORD tempResult; 
reg[23:0] valueNew;
reg signBit; reg[7:0] expVal; reg[6:0] mantissa;  
wire[4:0] numZero; 
reg [7:0] lookupArr [0:127];

//Liang's Variables 
//For F2I
reg `WORD temV;
reg `WORD temVs;
//For Mulf
reg[7:0] expVal1; reg[7:0] expVal2; reg[7:0] temexpVal;
reg[7:0] tem1; reg[7:0] tem2;



//Initialize the lookup array
initial begin
   $readmemh("reqFiles/recip.vmem", lookupArr);
end


//Always block that determines if the input is positive or negative and finds
//
always@(*) begin

  if(in1[15]) begin
    absValue <= ~in1 +1;
  end
  else begin
    absValue <= in1;
  end

end

//Find the number of leading zeros for the 2's complment value of input
lead0s findZeros(numZero, absValue);

always @(*) begin
  case (op)
    `OPadd: begin result = in1 + in2; end
    `OPand: begin result = in1 & in2; end
    `OPany: begin result = |in1; end
    `OPor: begin result = in1 | in2; end
    `OPshr: begin result = in1 >> 1; end
    `OPxor: begin result = in1 ^ in2; end
    
    //Floating point operations
    `OPf2i: begin
      //Get the exponent value
      //Subtract 127 from exponent
      //Shift fraction right by exponent value
      //normalize using leading 0s 
      //account for sign
     

      //New Code:
      
      //Check initial case that input is 0
      if(!in1) begin
        result = in1;
      end

      else begin
        //Create a buffer of 1's followed by the mantissa 
        valueNew= {8'b1, in1[6:0]};

        if(in1[14:7] < 127) begin
          valueNew = valueNew << (in1[14:7] -127)
          result = temp[22:7]
        end

        else begin
          result = 0;
        end

        if(in1[15]) begin
          result = (result ^ 'hffff) +1;
        end

      end

      /*Abdul's Pseudo 
      if(in1[15]) begin
        signBit = 1; 
      end 
      else begin
        signBit = 0;
      end

      expVal = in1[14:7];

      //if exponent < 7, then the result is equal to 0
      if(expVal < 7) begin
        result = 0; 
      end 
     
      //else if exponent >7, result is -126 (min) or 127 (max)
      else if(expVal > 7) begin
        result = ((signBit) ? -126 : 127);
        $display("Sign: %b, Result: %x", signBit, result); 

        //based on the minimum or maximum received, use a barrell shifter 
        //to find the result 
        if(expVal >0) begin
          $display("expVal > 0, expVal = %x", expVal);
          result = result << expVal;
        end

        else begin
          result = result >> expVal;
        end

      end       
     

      else if exponent >0, result is mantissa <<exponent;
      else if(expVal > 0) begin
        $display("expVal > 0, expVal = %x"
        result = result << expVal;
      end 

      //else result is mantissa >> -exponent
      else begin
        result = result >> expVal;
      end
      */

      /*Liang's Code:
      if (in1[15]) begin
        signBit = 1;
        tempResult = 16'h8000;
        end
      else 
      begin
        signBit = 0;
        tempResult = 16'h0; 
      end
        expVal[7:0] <= in1[14:7];
        if((expVal - 127)>0)
        begin
          temV[7] = 1'b1;
          temV[6:0] <= in1[7:0];
          int i;
          for(i=0, i<(expVal-126), i++)
          begin
            tempResult[i] <= temV[7-(expVal-127)+i];
          end
        end
        else if((expVal - 127)==0)
        begin
          tempResult[0] <= 1'b1;
        end
        else
        begin
          tempResult[0] <= 1'b0;
        end
      */
     end

    `OPi2f: begin 

      //Make positive, set sign :
      //If in1[15] then it's negative, so subtract num by 0x8000 to get pos val
      if(in1[15]) begin
        signBit =1; 
        //tempResult = ~in1 +1;
        tempResult = absValue;
      end 
      else begin
        signBit = 0;
        //tempResult = in1;
        tempResult = absValue;
      end

      //Assign value to a 24 bit buffer and pad with zeros
      valueNew = {tempResult, 8'b0};
      //Make a mantissa by indexing the buffer at 15-numzero +7 and 15-numzero
      mantissa = valueNew[((15-numZero)+7) -: 7];
      //mantissa = valueNew[((15-numZero)+8) -: 7];
      //Figure out exponent which is 142 - #zeros 
      expVal = (16'h7f + 15) - numZero;
      //cat all these parts together
      result = {signBit, expVal, mantissa};
     end

    `OPinvf: begin 
      //First set the sign bit like the other operations 
      if(in1[15]) begin
        signBit=1;
        tempResult = absValue;
      end
      else begin
        signBit=0;
        tempResult = absValue;
      end 

      //To find the mantissa, use a lookup table
      mantissa = lookupArr[absValue[6:0]][7:0];
      //$display("lookupValue: %x", lookupArr[2][7:0]);
      //Read the table into a 127 element array 

      //Need to determine the exponent based on the mantissa value
      if(!mantissa) begin 
        expVal = 254 - absValue[14:7];
      end
      else begin
        expVal = 253 - absValue[14:7];
      end

      //Finally, we set the result of the inverse based on whether the input
      //was 0 or not. For this assignment, we treat 1/0 as 0. 
      if(!absValue)begin
        result = 0;
      end 
      else begin
        result = {signBit, expVal, mantissa};
      end

     end
    
    `OPaddf: begin 
      //find the difference between the larger and smaller input
      //Shift the samller mantissa by this difference
      //Add mantissas
      //Normalize (shifting by 1 and adding 1 to the exponent)
      //Look at overflow/underflow and set to the max/min based on case
     end

    `OPmulf: begin 
      //Append 1 as top bit for both mantissas
      //Multiply these new mantissas
      //Mantissa = new mantissa[13:6]
      //Get the sign bit 
      //Get the exponent as = (Ea -Ebias) + (Eb -Ebias) + Ebias +Esign
      //Get the exponent as = Ea + Eb - Ebias + En
      //Concatenate all values together

      /*Liang's Code:
      
      signBit = in1[15]^in2[15];
      
      tem1 = {1'b1,in1[6:0]};
      tem2 = {1'b1,in1[6:0]};
      
      temV = tem1*tem2;
      
      expVal1[7:0] = in1[14:7];
      expVal2[7:0] = in2[14:7];
      
      if(temV[15])begin 
        emexpVal = 8'b00000001; 
        mantissa[6:0] = temv[14:8];
      end
      
      else begin 
        temexpVal = 8'b0; 
        mantissa[6:0] = temv[13:7]; 
      end
      
      expVal = expVal1 + expVal2 + temexpVal - 8'b01111111;

      result = {signBit,expVal,mantissa};
      */
     end

    default: begin result = in1; end
  endcase
end
endmodule
