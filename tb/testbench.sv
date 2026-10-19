`timescale 1ns/1ps

module tb_full_link;

    reg clk;
    reg rst;
    reg tx_bit;
    reg tx_valid;
    reg inject_enable;
    reg [5:0] inject_index;
    reg [1:0] error_mask;
    reg start_decode;
    reg [5:0] payload_length;

    wire [1:0] encoded_pair;
    wire encoded_valid;
    wire [1:0] received_pair;
    wire received_valid;
    wire error_injected;
    wire decoded_bit;
    wire decoded_valid;
    wire decoder_busy;
    wire decode_done;

    reg [3:0] expected_message;
    integer decoded_count;
    integer failures;
    integer raw_channel_errors;

    comm_system dut (
        .clk(clk),
        .rst(rst),
        .tx_bit(tx_bit),
        .tx_valid(tx_valid),
        .inject_enable(inject_enable),
        .inject_index(inject_index),
        .error_mask(error_mask),
        .start_decode(start_decode),
        .payload_length(payload_length),
        .encoded_pair(encoded_pair),
        .encoded_valid(encoded_valid),
        .received_pair(received_pair),
        .received_valid(received_valid),
        .error_injected(error_injected),
        .decoded_bit(decoded_bit),
        .decoded_valid(decoded_valid),
        .decoder_busy(decoder_busy),
        .decode_done(decode_done)
    );

    always #5 clk = ~clk;

    task reset_design;
        begin
            rst = 1'b1;
            tx_bit = 1'b0;
            tx_valid = 1'b0;
            inject_enable = 1'b0;
            inject_index = 6'd0;
            error_mask = 2'b00;
            start_decode = 1'b0;
            payload_length = 6'd4;
            repeat (2) @(negedge clk);
            rst = 1'b0;
        end
    endtask

    task send_bit;
        input bit_value;
        begin
            @(negedge clk);
            tx_bit = bit_value;
            tx_valid = 1'b1;
            @(negedge clk);
            tx_valid = 1'b0;
        end
    endtask

    task send_message_1011_with_tails;
        begin
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b1);
            send_bit(1'b1);
            send_bit(1'b0);
            send_bit(1'b0);
        end
    endtask

    task begin_traceback;
        begin
            repeat (4) @(negedge clk);
            start_decode = 1'b1;
            @(negedge clk);
            start_decode = 1'b0;
        end
    endtask

    task check_result;
        begin
            wait (decode_done == 1'b1);
            @(negedge clk);
            #1;
            if (decoded_count == 4 && failures == 0) begin
                $display("RESULT: PASS");
                $display("Recovered message is 1011");
                $display("Raw channel-corrupted pairs: %0d", raw_channel_errors);
            end else begin
                $display("RESULT: FAIL");
                $display("Decoded bits received: %0d", decoded_count);
                $display("Incorrect decoded bits: %0d", failures);
            end
        end
    endtask

    always @(negedge clk) begin
        if (!rst && received_valid && error_injected) begin
            raw_channel_errors = raw_channel_errors + 1;
            $display("Channel error injected at time %0t", $time);
        end

        if (!rst && decoded_valid) begin
            $display("Decoded bit %0d = %b", decoded_count, decoded_bit);
            if (decoded_count < 4 && decoded_bit !== expected_message[3 - decoded_count]) begin
                failures = failures + 1;
            end
            decoded_count = decoded_count + 1;
        end
    end

    initial begin
        $dumpfile("full_link.vcd");
        $dumpvars(0, tb_full_link);

        clk = 1'b0;
        expected_message = 4'b1011;

        $display("========================================");
        $display("CASE 1: Error-free transmission");
        $display("========================================");

        decoded_count = 0;
        failures = 0;
        raw_channel_errors = 0;
        reset_design;
        send_message_1011_with_tails;
        begin_traceback;
        check_result;

        $display("========================================");
        $display("CASE 2: One controlled channel error");
        $display("========================================");

        decoded_count = 0;
        failures = 0;
        raw_channel_errors = 0;
        reset_design;
        inject_enable = 1'b1;
        inject_index = 6'd2;
        error_mask = 2'b01;
        send_message_1011_with_tails;
        begin_traceback;
        check_result;

        $display("========================================");
        $display("Simulation completed");
        $display("========================================");

        #20;
        $finish;
    end

endmodule
