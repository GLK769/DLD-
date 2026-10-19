# Convolutional Encoder and Viterbi Decoder over a Noisy Channel

## Overview

This project models a complete digital communication link that can detect and correct transmission errors. A stream of binary data is first encoded with extra redundancy, passed through a channel that may alter some transmitted bits, and then decoded using the Viterbi algorithm to recover the most likely original message.

The project is built as a hardware-oriented SystemVerilog simulation. It represents the digital logic behind error-correcting communication systems used in wireless links, satellite communication, deep-space probes, storage devices, and reliable data transfer systems.

## Vision

The aim is not only to show that data can be transmitted, but to demonstrate why channel coding is useful.

Normal transmission sends each bit directly. If noise flips a bit, the receiver has no way to know the intended value. In this design, the convolutional encoder adds structured redundancy to every input bit. The Viterbi decoder examines the received sequence, compares different possible transmission paths, and selects the path with the smallest total error.

The final result is a simulated communication system that can show the difference between:

- data affected by a noisy channel without correction
- data recovered through convolutional coding and Viterbi decoding

## System Flow

```text
Input Data Bits
      |
      v
Convolutional Encoder
      |
      | Encoded bit pairs
      v
Controlled Noisy Channel
      |
      | Possibly corrupted bit pairs
      v
Viterbi Decoder
      |
      v
Recovered Data Bits
