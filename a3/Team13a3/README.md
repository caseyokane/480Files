
EE 480 Assignment 3: A Faster IDIOT

    | pipe.v  - source code for the assignment
    | ReqFiles/
        | datamem.txt - compiled AIK file that is used specify values for the data memory (mostly used for GTKWave testing)
        | reg.txt - same case as datamem.txt but for the register file
        | inst.txt - primary test file compiled using AIK and follows the test file present on the EE480 Assignment 3 page
        | inst1.txt - secondary test file compiled using AIK that can also be tested by renaming this file to 'inst.txt' 	
        | IDIOT Source/ 
           | Directory containing the source for the aforementioned inst/1.txt files  
    | Documentation/
        | Directory containing documentation source files
        | notes.tex - implementer's notes source


Compilation Instructions:
	Currently no Makefile for this assignment. Code compiled with "iverilog pipe.v -o pipeProg" then open GTKWave using "vvp pipeProg"
	
Testcase Instructions:
	As mentioned above, the two text files inst and inst1 that are used as input and can be used interchangeably by simply renaming them. 
	Sorry that a makefile wasn't included, time got very tight near the end. 
	