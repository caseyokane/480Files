
EE 480 Assignment 3: A Faster IDIOT

    | pipe.v  - source code for the assignment
    | ReqFiles/
        | datamem.txt - compiled AIK file that is used specify values for the 
	  	data memory (mostly used for GTKWave testing)
        | reg.txt - same case as datamem.txt but for the register file
        | inst.txt - primary test file compiled using AIK and follows the test 
	  	file present on the EE480 Assignment 3 page
        | inst1.txt - secondary test file compiled using AIK that can also be 
	  	tested by renaming this file to 'inst.txt' 	
        | inst2.txt - third and final test file used in a similar way as the previous
        		test files
        | IDIOT Source/ 
           | Directory containing additional files used that aren't necessary for 
           	compilation, but explain where our assembly comes from.
		| aikspc - AIK specification provided by Dr. Dietz
		| opcodetranslate.txt - Simple dictionary for  instructions used with
			GTKWave
		| test1/2/3Src.txt - original assembly files used as input for the 
			AIK Assembler cgi
    | Documentation/
        | Directory containing documentation source files
        | notes.tex - implementer's notes source
        | notes.pdf - final draft of the implementor's notes
        | DesignDraft.pdf - enlarged version of the high level design for the
        	  processor


Compilation Instructions:
	Currently no Makefile for this assignment. Code compiled with 
	"iverilog -o pipeProg pipe.v" then open GTKWave using "vvp pipeProg" and 
	"gtkwave ee480.2.0.txt"
	
Testcase Instructions:
	As mentioned above, the three text files inst, inst2, and inst1 that are used as 
	input and can be used interchangeably by simply renaming them. 
	
	Sorry that a makefile wasn't included, time got very tight near the end. 
	
