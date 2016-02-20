/*
module half_adder(a, b, s, c);

	input a,b;
	output s,c;

	xor(s,a,b);
	and(c,a,b);

endmodule
*/

module full_adder(a, b, carryIn, s, carryOut);
	
	input a,b,carryIn;
	output s,carryOut;
	//wire s,cout;

	assign s = a^b^carryIn;
	assign carryOut = ((a&b) | (b&carryIn) | (a&carryIn));
	
/*
	wire s1, c1, c2;
	half_adder hadd1(s1,c1,a,b);
	half_adder hadd2(S,c2,s1,Cin);
	or OG1(Cout,c1,c2);
*/

endmodule 

module ripple_carry(a, b, carryIn, s, carryOut);

	input[7:0]a, b;
	output[7:0]s;
	input carryIn;
	output carryOut;


	wire[6:0]carry;

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
	output[7:0] s;
	wire carry;
	reg[7:0] result;

	ripple_carry rip1(a,b,1'b0,s,carry); 

//If the sum sign is different than that of the operands, then an overflow
//has occurred and saturation must be accounted for.

//If s[7]==0 then the result should be -128
//if s[7]==1 then the result should be 127

	always@(a or b or s)
	begin 
		if((a[7]&b[7])!=s[7])
		begin
			if(s[7]==1)
			begin
				assign result = 'H7f;
			end
		
			else
			begin
				assign result = 'H80;
			end

			//s = result;
		end
	

	end

	

endmodule


module testbench;

	reg[7:0]a;
	reg[7:0]b;
	reg carryIn;
	wire[7:0]s;
	wire carryOut;

	//ripple_carry uut(.a(a), .b(b), .carryIn(carryIn), .s(s), 
	//			.carryOut(carryOut));
	
	satadd8 test1(.s(s), .a(a), .b(b));

	initial begin
/*
	#10 a=8'b00000011; b=8'b00000011; carryIn=1'b0;
	#10 a=8'b00000000; b=8'b00000001; carryIn=1'b0;
	#10 a=8'b00000001; b=8'b00000001; carryIn=1'b0;
	#10 a=8'b00000010; b=8'b00000011; carryIn=1'b0;
	#10 a=8'b00000011; b=8'b00000010; carryIn=1'b0;
*/
	#10 a=8'b00000011; b=8'b00000011;
	#10 a=8'b00000000; b=8'b00000001;
	#10 a=8'b00000001; b=8'b00000001;
	#10 a=8'b00000010; b=8'b00000011; 
	#10 a=8'b11111101; b=8'b10000001;
	#10 a=8'b00010110; b=8'b01110010;
	#10 $stop;
	
	end

	initial 
		$monitor("input1=%b[%d,%x], input2=%b[%d,%x], sum=%b[%d,%x], time=%3d", a,a,a,b,b,b,s,s,s,$time);

endmodule

