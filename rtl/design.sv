module conv_encoder (
    input wire clk,
    input wire rst,
    input wire data_bit,
    input wire data_valid,
    output reg [1:0] encoded_pair,
    output reg encoded_valid
);

    reg s1;
    reg s2;

    always @(posedge clk) begin
        if (rst) begin
            s1 <= 1'b0;
            s2 <= 1'b0;
            encoded_pair <= 2'b00;
            encoded_valid <= 1'b0;
        end else begin
            encoded_valid <= data_valid;
            if (data_valid) begin
                encoded_pair[1] <= data_bit ^ s1 ^ s2;
                encoded_pair[0] <= data_bit ^ s2;
                s2 <= s1;
                s1 <= data_bit;
            end
        end
    end

endmodule


module noisy_channel #(
    parameter COUNT_W = 6
) (
    input wire clk,
    input wire rst,
    input wire [1:0] encoded_pair,
    input wire encoded_valid,
    input wire inject_enable,
    input wire [COUNT_W-1:0] inject_index,
    input wire [1:0] error_mask,
    output reg [1:0] received_pair,
    output reg received_valid,
    output reg error_injected
);

    reg [COUNT_W-1:0] pair_count;

    always @(posedge clk) begin
        if (rst) begin
            pair_count <= 0;
            received_pair <= 2'b00;
            received_valid <= 1'b0;
            error_injected <= 1'b0;
        end else begin
            received_valid <= 1'b0;
            error_injected <= 1'b0;
            if (encoded_valid) begin
                received_valid <= 1'b1;
                if (inject_enable && pair_count == inject_index) begin
                    received_pair <= encoded_pair ^ error_mask;
                    error_injected <= 1'b1;
                end else begin
                    received_pair <= encoded_pair;
                end
                pair_count <= pair_count + 1'b1;
            end
        end
    end

endmodule


module branch_metric_unit (
    input wire [1:0] current_state,
    input wire candidate_bit,
    input wire [1:0] received_pair,
    output wire [1:0] expected_pair,
    output wire [1:0] next_state,
    output wire [1:0] branch_metric
);

    assign expected_pair[1] = candidate_bit ^ current_state[1] ^ current_state[0];
    assign expected_pair[0] = candidate_bit ^ current_state[0];
    assign next_state = {candidate_bit, current_state[1]};
    assign branch_metric =
        {1'b0, received_pair[1] ^ expected_pair[1]} +
        {1'b0, received_pair[0] ^ expected_pair[0]};

endmodule


module viterbi_decoder #(
    parameter MAX_STEPS = 32,
    parameter METRIC_W = 8,
    parameter COUNT_W = 6
) (
    input wire clk,
    input wire rst,
    input wire [1:0] received_pair,
    input wire received_valid,
    input wire start_decode,
    input wire [COUNT_W-1:0] payload_length,
    output reg decoded_bit,
    output reg decoded_valid,
    output reg busy,
    output reg decode_done
);

    localparam [METRIC_W-1:0] INF_METRIC = 8'd63;

    reg [METRIC_W-1:0] metric_00;
    reg [METRIC_W-1:0] metric_01;
    reg [METRIC_W-1:0] metric_10;
    reg [METRIC_W-1:0] metric_11;

    wire [1:0] bm_00_0;
    wire [1:0] bm_00_1;
    wire [1:0] bm_01_0;
    wire [1:0] bm_01_1;
    wire [1:0] bm_10_0;
    wire [1:0] bm_10_1;
    wire [1:0] bm_11_0;
    wire [1:0] bm_11_1;

    branch_metric_unit u00_0 (
        .current_state(2'b00), .candidate_bit(1'b0), .received_pair(received_pair),
        .expected_pair(), .next_state(), .branch_metric(bm_00_0)
    );
    branch_metric_unit u00_1 (
        .current_state(2'b00), .candidate_bit(1'b1), .received_pair(received_pair),
        .expected_pair(), .next_state(), .branch_metric(bm_00_1)
    );
    branch_metric_unit u01_0 (
        .current_state(2'b01), .candidate_bit(1'b0), .received_pair(received_pair),
        .expected_pair(), .next_state(), .branch_metric(bm_01_0)
    );
    branch_metric_unit u01_1 (
        .current_state(2'b01), .candidate_bit(1'b1), .received_pair(received_pair),
        .expected_pair(), .next_state(), .branch_metric(bm_01_1)
    );
    branch_metric_unit u10_0 (
        .current_state(2'b10), .candidate_bit(1'b0), .received_pair(received_pair),
        .expected_pair(), .next_state(), .branch_metric(bm_10_0)
    );
    branch_metric_unit u10_1 (
        .current_state(2'b10), .candidate_bit(1'b1), .received_pair(received_pair),
        .expected_pair(), .next_state(), .branch_metric(bm_10_1)
    );
    branch_metric_unit u11_0 (
        .current_state(2'b11), .candidate_bit(1'b0), .received_pair(received_pair),
        .expected_pair(), .next_state(), .branch_metric(bm_11_0)
    );
    branch_metric_unit u11_1 (
        .current_state(2'b11), .candidate_bit(1'b1), .received_pair(received_pair),
        .expected_pair(), .next_state(), .branch_metric(bm_11_1)
    );

    reg [METRIC_W-1:0] next_metric_00;
    reg [METRIC_W-1:0] next_metric_01;
    reg [METRIC_W-1:0] next_metric_10;
    reg [METRIC_W-1:0] next_metric_11;

    reg survivor_00;
    reg survivor_01;
    reg survivor_10;
    reg survivor_11;

    reg [METRIC_W-1:0] candidate_00_a;
    reg [METRIC_W-1:0] candidate_00_b;
    reg [METRIC_W-1:0] candidate_01_a;
    reg [METRIC_W-1:0] candidate_01_b;
    reg [METRIC_W-1:0] candidate_10_a;
    reg [METRIC_W-1:0] candidate_10_b;
    reg [METRIC_W-1:0] candidate_11_a;
    reg [METRIC_W-1:0] candidate_11_b;

    always @(*) begin
        candidate_00_a = metric_00 + bm_00_0;
        candidate_00_b = metric_01 + bm_01_0;
        candidate_01_a = metric_10 + bm_10_0;
        candidate_01_b = metric_11 + bm_11_0;
        candidate_10_a = metric_00 + bm_00_1;
        candidate_10_b = metric_01 + bm_01_1;
        candidate_11_a = metric_10 + bm_10_1;
        candidate_11_b = metric_11 + bm_11_1;

        if (candidate_00_a <= candidate_00_b) begin
            next_metric_00 = candidate_00_a;
            survivor_00 = 1'b0;
        end else begin
            next_metric_00 = candidate_00_b;
            survivor_00 = 1'b1;
        end

        if (candidate_01_a <= candidate_01_b) begin
            next_metric_01 = candidate_01_a;
            survivor_01 = 1'b0;
        end else begin
            next_metric_01 = candidate_01_b;
            survivor_01 = 1'b1;
        end

        if (candidate_10_a <= candidate_10_b) begin
            next_metric_10 = candidate_10_a;
            survivor_10 = 1'b0;
        end else begin
            next_metric_10 = candidate_10_b;
            survivor_10 = 1'b1;
        end

        if (candidate_11_a <= candidate_11_b) begin
            next_metric_11 = candidate_11_a;
            survivor_11 = 1'b0;
        end else begin
            next_metric_11 = candidate_11_b;
            survivor_11 = 1'b1;
        end
    end

    reg [3:0] survivor_memory [0:MAX_STEPS-1];
    reg decoded_buffer [0:MAX_STEPS-1];

    integer step_count;
    integer trace_index;
    integer output_index;
    integer stored_payload_length;

    reg [1:0] current_state;
    reg output_phase;

    always @(posedge clk) begin
        if (rst) begin
            metric_00 <= 0;
            metric_01 <= INF_METRIC;
            metric_10 <= INF_METRIC;
            metric_11 <= INF_METRIC;
            step_count <= 0;
            trace_index <= 0;
            output_index <= 0;
            stored_payload_length <= 0;
            current_state <= 2'b00;
            output_phase <= 1'b0;
            decoded_bit <= 1'b0;
            decoded_valid <= 1'b0;
            busy <= 1'b0;
            decode_done <= 1'b0;
        end else begin
            decoded_valid <= 1'b0;
            decode_done <= 1'b0;

            if (!busy) begin
                if (received_valid && step_count < MAX_STEPS) begin
                    metric_00 <= next_metric_00;
                    metric_01 <= next_metric_01;
                    metric_10 <= next_metric_10;
                    metric_11 <= next_metric_11;
                    survivor_memory[step_count] <= {survivor_11, survivor_10, survivor_01, survivor_00};
                    step_count <= step_count + 1;
                end

                if (start_decode && step_count > 0) begin
                    current_state <= 2'b00;
                    trace_index <= step_count;
                    stored_payload_length <= payload_length;
                    output_phase <= 1'b0;
                    busy <= 1'b1;
                end
            end else begin
                if (!output_phase) begin
                    if (trace_index > 0) begin
                        decoded_buffer[trace_index - 1] <= current_state[1];
                        case (current_state)
                            2'b00: current_state <= {current_state[0], survivor_memory[trace_index - 1][0]};
                            2'b01: current_state <= {current_state[0], survivor_memory[trace_index - 1][1]};
                            2'b10: current_state <= {current_state[0], survivor_memory[trace_index - 1][2]};
                            2'b11: current_state <= {current_state[0], survivor_memory[trace_index - 1][3]};
                        endcase
                        trace_index <= trace_index - 1;
                    end else begin
                        output_phase <= 1'b1;
                        output_index <= 0;
                    end
                end else if (output_index < stored_payload_length) begin
                    decoded_bit <= decoded_buffer[output_index];
                    decoded_valid <= 1'b1;
                    output_index <= output_index + 1;
                    if (output_index == stored_payload_length - 1) begin
                        busy <= 1'b0;
                        decode_done <= 1'b1;
                    end
                end
            end
        end
    end

endmodule


module comm_system #(
    parameter MAX_STEPS = 32,
    parameter COUNT_W = 6
) (
    input wire clk,
    input wire rst,
    input wire tx_bit,
    input wire tx_valid,
    input wire inject_enable,
    input wire [COUNT_W-1:0] inject_index,
    input wire [1:0] error_mask,
    input wire start_decode,
    input wire [COUNT_W-1:0] payload_length,
    output wire [1:0] encoded_pair,
    output wire encoded_valid,
    output wire [1:0] received_pair,
    output wire received_valid,
    output wire error_injected,
    output wire decoded_bit,
    output wire decoded_valid,
    output wire decoder_busy,
    output wire decode_done
);

    conv_encoder encoder (
        .clk(clk),
        .rst(rst),
        .data_bit(tx_bit),
        .data_valid(tx_valid),
        .encoded_pair(encoded_pair),
        .encoded_valid(encoded_valid)
    );

    noisy_channel #(.COUNT_W(COUNT_W)) channel (
        .clk(clk),
        .rst(rst),
        .encoded_pair(encoded_pair),
        .encoded_valid(encoded_valid),
        .inject_enable(inject_enable),
        .inject_index(inject_index),
        .error_mask(error_mask),
        .received_pair(received_pair),
        .received_valid(received_valid),
        .error_injected(error_injected)
    );

    viterbi_decoder #(.MAX_STEPS(MAX_STEPS), .COUNT_W(COUNT_W)) decoder (
        .clk(clk),
        .rst(rst),
        .received_pair(received_pair),
        .received_valid(received_valid),
        .start_decode(start_decode),
        .payload_length(payload_length),
        .decoded_bit(decoded_bit),
        .decoded_valid(decoded_valid),
        .busy(decoder_busy),
        .decode_done(decode_done)
    );

endmodule
