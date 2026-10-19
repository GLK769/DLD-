# Convolutional Encoder and Viterbi Decoder Simulation

This project simulates a rate 1/2, constraint-length 3 convolutional coding link. It uses generator polynomials (7,5) in octal, a controlled digital noisy channel, and a hard-decision Viterbi decoder.

## Folder layout

- `rtl/design.sv`: All HDL design modules.
- `tb/testbench.sv`: Full-system testbench with two automated test cases.
- `results/`: Put EDA Playground console screenshots, EPWave screenshots, and result tables here.
- `docs/system_flowchart.svg`: Flowchart image for the report or presentation.

## Modules in `rtl/design.sv`

1. `conv_encoder`: Converts one input bit into a two-bit encoded pair.
2. `noisy_channel`: Copies encoded pairs, or flips selected bits at one chosen pair index.
3. `branch_metric_unit`: Calculates the Hamming distance between a received pair and an expected pair.
4. `viterbi_decoder`: Contains the branch metrics, add-compare-select operation, path metrics, survivor memory, and traceback process.
5. `comm_system`: Connects encoder, noisy channel, and decoder into one simulated communication link.

## Run in EDA Playground

1. Select `SystemVerilog` and `Icarus Verilog`.
2. Paste `rtl/design.sv` into the design pane.
3. Paste `tb/testbench.sv` into the testbench pane.
4. Enable `Open EPWave after run` and run the simulation.
5. Save console and waveform screenshots in `results/`.

## Test cases

The testbench sends payload `1011`, then two zero tail bits to return the encoder to state `00`.

| Case | Channel condition | Expected recovered payload |
|---|---|---|
| 1 | No error | `1011` |
| 2 | One forced bit flip in encoded pair 2 | `1011` |

The second test demonstrates coding gain conceptually: the channel introduces an error, but the decoder can still recover the original short message.

## Evidence to include in the report

- Console screenshot showing both cases and `RESULT: PASS`.
- EPWave screenshot with input, encoded, received, and decoded signals.
- EPWave screenshot showing `error_injected = 1` during Case 2.
- A small result table comparing raw channel errors with decoded errors.
