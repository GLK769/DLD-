# Results Folder

Save submission evidence here after running the simulation.

Suggested files:

- `console_output.png`: Screenshot of both passing test cases.
- `waveform_no_error.png`: EPWave screenshot for the error-free case.
- `waveform_one_error.png`: EPWave screenshot showing the controlled error and correct recovery.
- `results_table.md`: Final table of channel errors and decoded errors.

Suggested final table:

| Case | Input | Channel error | Decoder output | Raw channel errors | Decoded errors |
|---|---|---|---|---:|---:|
| 1 | `1011` | None | `1011` | 0 | 0 |
| 2 | `1011` | One forced bit flip | `1011` | 1 | 0 |
