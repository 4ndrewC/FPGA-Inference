`timescale 1ns/1ps

module tb_nn;
    localparam int N = 32;
//    int W = 16;
    logic clk;
//    logic [2:0] layer;
    logic signed [N-1:0] in;
    logic signed [N-1:0] out;
    logic rst;
    logic done;
    
    nn dut (
        .clk(clk),
        .rst(rst),
        .in(in),
        .out(out),
        .done(done)
    );
    
    always #5 clk = ~clk; 
    int i, j;
    initial begin
        rst = 1;
//        in = 16'sd614;
//        in = 16'sd2048;
        in = 16'sd2048;
        clk = 0;
        
        
       
//       #100;
         #10;
         rst = 0;
         
         #100;

            rst = 1;
         if(done) $display("%d\n", out);
        $finish;
    end

endmodule
