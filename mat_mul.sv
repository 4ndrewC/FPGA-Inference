module mat_mul #(
    parameter int N = 32,       
    parameter int W = 16        
)(
    input logic clk,
    input  logic signed [N-1:0] mat1 [W][W],  
    input  logic signed [N-1:0] mat2 [W],     
    input  logic signed [N-1:0] bias [W],     
    output logic signed [N-1:0] out  [W],
    input logic done,
    output logic flag
);

integer i, j;
logic signed [N-1:0] mult;
logic signed [N-1:0] sum;


//always_comb begin 
//    // Flag indicates combinational logic is valid (immediate)
//    flag = 1; 

//    for(i = 0; i < W; i ++) begin 
//        sum = 0;
//            mult = mat1[i][j] * mat2[j];
//            sum += mult;
//        end
//        sum = (sum >>> 11) + bias[i];
//        out[i] = (sum > 0) ? sum : 0;
//    end
//end
//assign out[0] = 0;

always_comb begin 
//always_ff @(posedge clk) begin
    if(done==0) begin
         for(i = 0; i < W; i ++) begin 
             sum = 0;
             for(j = 0; j < W; j++) begin 
                 mult = (mat1[i][j] * mat2[j])>>>11;
//                 sum = (sum+mult)>>11;
                sum+=mult;
             end
//        sum = (sum >>> 11) + bias[i];
//            sum = (sum+bias[i])>>11;
            sum+=bias[i];
            out[i] = (sum >= 0) ? sum : 0;
//             out[i] = (sum + bias[i]) > 0 ? (sum + bias[i]) : 0;
    //        out[i] = sum+bias[i];
    //         out[i] = 16'h1111;
             $display("%d\n", out[i]);
         end
//         done = 1;
        flag = 1;
     end
     else begin
//     `  $display("flag reset\n");
        flag = 0;
     end
     
    // out[0] = 0;
    // $display("%d\n", out[0]);
end
endmodule 
