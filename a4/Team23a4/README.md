
EE 480 Assignment 4: Floating 

    | floatpipe.v  - source code for the assignment
    | ReqFiles/
        | assemblyinput - assembly source that includes test instructions for
		the processor.
        | pipe0.vmem - provided vmem used ot instantiate the register file
        | pipeinst.vmem - Assembled version of the assembly input that is loaded 
		into main mem and is ran by the processor.
	| recip.vmem - lookup table needed for the inverse instruction
    
    | ALUTEST/ - Directory used to test the ALU specifically prior to integration
	| alu.v - source that contains the 5 instructions necessary implement
    	| alu_tb.v - test bench used to drive alu.v
	| tests/ - Directory that contains four vector files of hex values that 
		are used to drive the test bench
	| reqFiles/ - Directory that includes all required files to make the ALUTest 
    | Documentation/
        | Directory containing documentation source files
        | notes.tex - implementer's notes source
        | notes.pdf - final draft of the implementor's notes

Compilation Instructions:
	Simply cast make in the current directory and it should compile the code and 
	produce the GTKWave output file "results.vcd"	
Testcase Instructions:
	For testing the ALU specifically, you just need to go to the ALUTest/ directory
	and cast make (it will display the results). The input files used are found in 
	the tests/ directory. 	
