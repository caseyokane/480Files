//EE480 Assignment 1 - Casey O'kane
//satadd8 implmentation and testbench

module half_adder(a,b,s,carry);
	input a,b;
	output s,carry;

//Simple half_adder logic
	xor(s,a,b);
	and(carry,a,b);
 
endmodule


module full_adder(a, b, carryIn, s, carryOut);
	
	input a,b,carryIn;
	output s,carryOut;
	wire tempSum, carry1, carry2;

//Instantiate two half adders and an or block  to calculate the sum and carry
//of a full adder	
	half_adder add1(a,b,tempSum, carry1);
	half_adder add2(carryIn,tempSum,s,carry2);
	or(carryOut, carry1, carry2);



endmodule 

module ripple_carry(a, b, carryIn, s, carryOut);

	input[7:0]a, b;
	output[7:0]s;
	input carryIn;
	output carryOut;


	wire[6:0]carry;
//generate - bitslice approach can be used here to increase readability
	full_adder add1(a[0],b[0],carryIn,s[0],carry[0]);	 
	full_adder add2(a[1],b[1],carry[0],s[1],carry[1]);	 
	full_adder add3(a[2],b[2],carry[1],s[2],carry[2]);	 
	full_adder add4(a[3],b[3],carry[2],s[3],carry[3]);	 
	full_adder add5(a[4],b[4],carry[3],s[4],carry[4]);	 
	full_adder add6(a[5],b[5],carry[4],s[5],carry[5]);	 
	full_adder add7(a[6],b[6],carry[5],s[6],carry[6]);	 
	full_adder add8(a[7],b[7],carry[6],s[7],carryOut);	 


endmodule


module satadd8(s,a,b);

	input[7:0] a,b;
	output[7:0]s;
	wire carry;

	//result and sRip are used as temporary variables to store sum values
	//prior to the use of the saturation
	reg[7:0]result;
	wire[7:0] sRip;


	ripple_carry rip1(a,b,1'b0,sRip,carry); 


	always@(a or b or s)
	begin 

		//If the sum sign is different than that of the operands, then 
		//an overflow has occurred and saturation must be accounted for
		if(a[7]==b[7])
		begin
			if( (a[7]==1'b0) && sRip[7]==1'b1)
			begin
				assign result = 'H7f;
			end

			
			else if( (a[7]==1'b1) && sRip[7]==1'b0)
			begin
				assign result = 'H80;
			end

			else 
			begin
				assign result = sRip;
			end
		end

		else
		begin
				assign result = sRip;
		end	
	end
	
	assign s = result;

endmodule


module testbench;

//registers initialized for device inputs
	reg[7:0]a,b,aCtr,bCtr; 
	reg[31:0]errorCtr, rightCtr;
	reg clk;

//Initialize signed registers for testing purposes
	reg signed[7:0]aSign, bSign, cmpRes;
	reg signed[8:0]cmpTmp;


//wire initialized for device outputs
	wire[7:0]s;

	satadd8 test1(.s(s), .a(a), .b(b));

	initial begin
		a = 0;
		b = 0;
		aCtr = 0;
		bCtr = 0;
		aSign = 0;
		bSign = 0;
		errorCtr = 0;
		rightCtr = 0;
	end

//Use checker preform calculations and test if input is correct
	initial begin
	repeat(256) begin
		repeat(256) begin
			a=aCtr; b=bCtr; 
			aSign=a; bSign=b;
			//delay needed here to ensure assignment has occurred
			#5 cmpTmp = aSign + bSign;

			if(cmpTmp < -128)begin cmpTmp = -128;
				if(s == 'H80) rightCtr = rightCtr +1;
				else begin errorCtr = errorCtr + 1;
					$display("a=%d\tb=%d\tsRC=%d\tsTEST=%d", aSign,bSign,s,cmpTmp);
					end
			end

			else if (cmpTmp > 127)begin cmpTmp =127;
				if(s == 'H7f) rightCtr = rightCtr +1;
				else begin errorCtr = errorCtr + 1;
					$display("a=%d\tb=%d\tsRC=%d\tsTEST=%d", aSign,bSign,s,cmpTmp);
				end			
			end

			 else begin cmpRes= cmpTmp;
				if(s == cmpRes) rightCtr = rightCtr +1;
				else begin errorCtr = errorCtr + 1;
					$display("a=%d\tb=%d\tsRC=%d\tsTEST=%d", aSign,bSign,s,cmpTmp);
				end
			end

		bCtr = bCtr +1;
		end

	aCtr = aCtr +1;
	end

//Output results based on checker's findings
	$display("All cases tested;%d correct, %d failed", rightCtr, errorCtr);
	end

endmodule

