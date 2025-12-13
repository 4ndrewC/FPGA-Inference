module processor_top #(
    parameter integer N = 32,
    parameter integer W = 6
)(
	input  logic		clk, 
	input  logic 		reset,
	input  logic signed [15:0] in,
    output logic signed [N-1:0] out
);


//logic signed [N-1:0] out;

    
//logic signed [N-1:0] in;


logic signed [N-1:0] l1val[W];
logic signed [N-1:0] l2val[W];
    
logic signed [N-1:0] l1weights [W] = '{
    -15,
   1375,
  -1686,
   -711,
   -789,
   2196
};

logic signed [N-1:0] l1bias [W] = '{
    -41,  2430,  -182,  1427,  -619, -2587
};

logic signed [N-1:0] l2weights [W][W] = '{
  '{  -799,  -554,  -345,    31,   331,   502 },
  '{  -567,  1648,   304,  1487,  -172, -1717 },
  '{  -135,  2217,   757, -1497,  -526, -3461 },
  '{  -326,   827,  -542,    96,  -584,  -905 },
  '{  -488,   732,   373,  1107,    44,  -704 },
  '{   141,  -781,  -604,  -431,   528,   490 }
};


logic signed [N-1:0] l2bias [W] = '{
   -371,  1183,  3231,   486,   -91,   113
};

logic signed [N-1:0] l3weights [W] = '{
    561, -3044,  2747,  -576,  -633,  -432
};
    logic signed [N-1:0] outbias = 761;
    
    
    logic signed [N-1:0] mat_weights[W][W];
    logic signed [N-1:0] mat_vals[W];
    logic signed [N-1:0] mat_bias[W];
    logic signed [N-1:0] mat_out[W];

    integer i, j;
    
    logic [1:0] layer;
    
    
    logic mm_done, flag;
    
    
    mat_mul mm(
        .clk(clk),
        .mat1 (mat_weights),
        .mat2 (mat_vals),
        .bias (mat_bias),
        .out  (mat_out),
        .done (mm_done),
        .layer(layer),
        .flag (flag)
    );
    
//    real real_out;
    
    always_ff @(posedge clk) begin
//    always_comb begin
        if(reset) begin
            layer <= 0;
            mm_done <= 0;
        end
        else begin
             mat_vals    <= '{default: 0};
             mat_bias    <= '{default: 0};
             mat_weights <= '{default: 0};
    
            case (layer)
                2'd0: begin
//                    $display("layer 0\n");
                    mat_vals[0] <= in;
                    mat_bias <= l1bias;
                    for (i = 0; i < W; i+=1) mat_weights[i][0] <= l1weights[i];
                    if(flag==1) mm_done <= 1;
                    if(mm_done) begin
                        if(flag==0) begin
                            mm_done <= 0;
                            layer <= 2'd1;
                            
                        end
                    end
                end
  
                2'd1: begin
//                    $display("layer 1\n");
                    mat_vals    <= l1val;      
                    mat_bias    <= l2bias;     
                    mat_weights <= l2weights;
                    if(flag==1) mm_done <= 1;
                    if(mm_done) begin
                        if(flag==0) begin
                            mm_done <= 0;
                            layer <= 2'd2;
                        end
                    end
                end
                2'd2: begin
//                    $display("layer 2\n");
                    mat_vals <= l2val; 
                    mat_bias[0] <= outbias;
                    for(i = 0; i<W; i+=1) mat_weights[0][i] <= l3weights[i];
                    if(flag==1) begin
                        mm_done <= 1;
                    end
                    if(mm_done) begin
                        if(flag==0) begin
//                            #10;
//                            layer <= 2'd3;
                            layer <= 2'd3;
                            mm_done <= 0;
                        end
                    end
                end
    
                2'd3: begin
//                    real_out <= out/2048.0;
//                    mm_done <= 1;
                  out <= mat_out[0];
                  layer <= 2'd0;
                end
                default: begin
                
                end
            endcase
        end
    end

    assign l1val = mat_out;
    assign l2val = mat_out;

//    always_comb begin
//        real_out = out / 2048.0; 
//    end
//    assign out = (mat_out[0]+outbias)<0?0:(mat_out[0]+outbias);

    // assign out = mat_out[0];   
    

endmodule
