`timescale 1ns/1ps

module tb_mat_mul;

    // You can change N back to 16 once you're happy
    localparam int N = 16;
    localparam int W = 16;
    localparam int ACC_W = 2*W + $clog2(N);

    // DUT ports
    logic signed [W-1:0] mat1 [N][N];
    logic signed [W-1:0] mat2 [N];
    logic signed [W-1:0] bias [N];
    logic signed [W-1:0] out  [N];

    // Expected output
    logic signed [W-1:0] expected [N];

    int i, j;
    
    logic clk;
    initial clk = 0;
    
    always #5 clk = ~clk;

    // For random generation (keep as simple ints)
    int r1, r2, r3;

    // Instantiate DUT
    mat_mul #(
        .N(N),
        .W(W)
    ) dut (
        .clk(clk),
        .mat1(mat1),
        .mat2(mat2),
        .bias(bias),
        .out (out)
    );

    // Task to compute expected result in the same way as DUT
    task automatic compute_expected;
    logic signed [ACC_W-1:0] acc;
    logic signed [ACC_W-1:0] relu_val;

    for (i = 0; i < N; i++) begin
        acc = '0;

        // matrix × vector
        for (j = 0; j < N; j++) begin
            acc += mat1[i][j] * mat2[j];
        end

        // add bias
        acc += bias[i];

        // -----------------------
        // Apply ReLU activation
        // -----------------------
        relu_val = (acc > 0) ? acc : '0;

        // Truncate the positive ReLU result to W bits
        expected[i] = relu_val[W-1:0];
    end
endtask

    // Task to compare DUT output with expected
    task automatic check_results(input string testname);
        compute_expected();
        #1; // allow combinational logic to settle

        for (i = 0; i < N; i++) begin
            if (out[i] !== expected[i]) begin
                $display("ERROR in %s: index %0d expected %0d got %0d",
                         testname, i, expected[i], out[i]);
                $fatal;
            end
        end

        $display("PASS: %s", testname);
    endtask

    initial begin
        // -----------------------------
        // Test 1: Identity matrix
        // mat1 = I, mat2 = [1,2,...], bias = 0 → out = mat2
        // -----------------------------
        $display("Identity matrix\n");
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                mat1[i][j] = (i == j) ? 16'sd1 : 16'sd0;
            end
            mat2[i] = i + 1;
            bias[i] = 0;
        end
        
        #10000;
        check_results("Identity matrix");

        // -----------------------------
        // Test 2: All zeros except bias
        // mat1 = 0, mat2 arbitrary, bias = [i-2] → out = bias
        // -----------------------------
        $display("Zero matrix with bias only\n");
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                mat1[i][j] = 0;
            end
            mat2[i] = (i + 1) * 5;
            bias[i] = i - 2;
        end
        check_results("Zero matrix with bias only");

        // -----------------------------
        // Test 3: Random small values (including negatives)
        // mat1, mat2, bias in range -10..+10
        // -----------------------------
        $display("Random small values\n");
        for (i = 0; i < N; i++) begin
            for (j = 0; j < N; j++) begin
                r1 = $random;
                // constrict to -10..+10
                mat1[i][j] = (r1 % 21) - 10;
            end

            r2 = $random;
            mat2[i] = (r2 % 21) - 10;

            r3 = $random;
            bias[i] = (r3 % 21) - 10;
        end
        check_results("Random small values");

        $display("All tests passed.");
        $finish;
    end

endmodule
