`timescale 1ns/1ps


module alu_tb;
    function disp;
    input x,y,z;
    begin
        $display("X:%d\nY:%d\nZ:%d",x,y,z);
    end
    endfunction

    //interface to uut
    reg `WORD X;
    reg `WORD Y;
    reg `WORD Z;
    wire `WORD z;
    reg [4:0] ALUop;
   
    reg `WORD Xvector[0:19];
    reg `WORD Yvector[0:19];
    reg `WORD Zvector[0:19];
    reg [4:0] OpVector[0:19];
    
    integer test_num, test_num_max;

    alu aluuut(z, ALUop, X, Y);

    integer correct, failed;
    reg `WORD calc;

    initial begin
        correct = 0;
        failed = 0;
        test_num_max = 20;

        X = 0;
        Y = 0;
        $dumpfile("results.vcd");
        $dumpvars(0, alu_tb);
       
        // 
        $readmemh("tests/aluXVector.vmem", Xvector);
        $readmemh("tests/aluYVector.vmem", Yvector);
        $readmemh("tests/aluZVector.vmem", Zvector);
        $readmemb("tests/aluOpVector.vmem", OpVector);
        //
        /*
        $readmemh("tests/Xcurr.vmem", Xvector);
        $readmemh("tests/Ycurr.vmem", Yvector);
        $readmemh("tests/Zcurr.vmem", Zvector);
        $readmemb("tests/OPcurr.vmem", OpVector);
        */

        $display("OP   :X    :Y    :Z    :Expected");
        for(test_num = 0; test_num < test_num_max; test_num = test_num + 1) begin
            X <= Xvector[test_num];
            Y <= Yvector[test_num];
            ALUop <= OpVector[test_num];
            #2;

            $display("%b: %x: %x: %x: %x", ALUop, X, Y, Z, Zvector[test_num]);
            if (Zvector[test_num] != Z) begin
                $display("Failure test %d", test_num);
                failed = failed + 1;
            end else begin
                correct = correct + 1;
            end
        end

        $display("Testing finished with %d correct %d failed", correct, failed);
        $finish;
    end
    always #1 Z <= z;

endmodule
