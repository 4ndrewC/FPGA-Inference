`timescale 1ns/1ps

module tb_nn;
    localparam int N = 200;
//    int W = 16;
    logic clk;
//    logic [2:0] layer;
    logic [N-1:0] in;
    logic [N-1:0] out;
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
        in = 3;
        clk = 0;
        rst = 1;
        
        #10;
        rst = 0;
//        for (int i = 0; i < 16; i++) begin
//            dut.l1weights[i] = i;    // <-- replace this with your desired values
//        end
//        for (int i = 0; i < 16; i++) begin
//            dut.l1bias[i] = 16'h0001 * i;  // simple example bias
//        end
        
        #50;

//        clk = 0;
        
        #100;
//        layer = 1;

//        layer = 2;

//        #20;
         if(done) $display("%d\n", out);
        $finish;
    end

endmodule
