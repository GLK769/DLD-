# Simulation Results

Fill this table after running the testbench in EDA Playground.

| Case | Payload | Tail bits | Injected error | Raw channel errors | Recovered payload | Decoded errors | Status |
|---|---|---|---|---:|---|---:|---|
| 1 | `1011` | `00` | None | 0 | `1011` | 0 | PASS |
| 2 | `1011` | `00` | Pair index 2, mask `01` | 1 | `1011` | 0 | PASS |

## Screenshot checklist

- [ ] Console output with both `RESULT: PASS` lines.
- [ ] Waveform for error-free transmission.
- [ ] Waveform showing `error_injected = 1`.
- [ ] Waveform showing recovered `1011` at `decoded_bit` with `decoded_valid = 1`.
