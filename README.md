# Triple DES Hardware Architectures

A Verilog implementation of **Two-Key Triple DES (3DES)** using three different digital hardware architectures: **Single-Cycle**, **Multi-Cycle**, and **Pipelined**.

The project supports **ECB, CBC, and OFB** encryption modes and demonstrates the trade-offs between latency, throughput, hardware reuse, combinational complexity, and parallelism across different hardware architectures.

The designs were developed and simulated using **ModelSim** as part of a Digital Systems Design course project.

---

## Features

- Two-Key Triple DES (3DES) encryption
- Three different hardware architectures:
  - Single-Cycle
  - Multi-Cycle
  - Pipelined
- Support for three encryption modes:
  - ECB (Electronic Codebook)
  - CBC (Cipher Block Chaining)
  - OFB (Output Feedback)
- Parameterized input data width
- 64-bit block processing
- Zero-padding support for incomplete final blocks
- 128-bit input containing two DES keys
- Initialization Vector (IV) support for CBC and OFB
- Dedicated DES building blocks and S-Boxes
- Separate testbenches for each architecture
- ModelSim simulation and verification
- Support for multi-block input data

---

## Triple DES Overview

Triple DES extends the DES encryption algorithm by applying DES operations multiple times to each 64-bit data block.

This project implements **Two-Key Triple DES** using the EDE sequence:

```text
DES Encryption with K1
          ↓
DES Decryption with K2
          ↓
DES Encryption with K1
```

In other words:

```text
Ciphertext = E(K1, D(K2, E(K1, Plaintext)))
```

where:

- `K1` is the first DES key
- `K2` is the second DES key
- `Plaintext` is a 64-bit input block
- `Ciphertext` is the resulting encrypted block

The complete key input is represented as:

```text
K1 || K2 = 128 bits
```

Each DES operation consists of **16 DES rounds**.

---

## Supported Encryption Modes

The encryption mode is selected using the 2-bit `mode` input.

| Mode | Value | Description |
|---|---|---|
| ECB | `00` | Electronic Codebook |
| CBC | `01` | Cipher Block Chaining |
| OFB | `10` | Output Feedback |

### ECB — Electronic Codebook

In ECB mode, every 64-bit plaintext block is encrypted independently.

```text
P0 ─────► 3DES ─────► C0

P1 ─────► 3DES ─────► C1

P2 ─────► 3DES ─────► C2
```

Because blocks are independent, no Initialization Vector is required.

---

### CBC — Cipher Block Chaining

In CBC mode, each plaintext block is combined with the previous ciphertext block before encryption.

The first block uses the provided Initialization Vector (`IV`).

```text
             IV
              │
              ▼
P0 ────────► XOR ─────► 3DES ─────► C0
                                      │
                                      ▼
P1 ────────► XOR ─────► 3DES ─────► C1
                                      │
                                      ▼
P2 ────────► XOR ─────► 3DES ─────► C2
```

---

### OFB — Output Feedback

OFB uses the encryption algorithm to generate a keystream from the Initialization Vector.

The generated output is XORed with the plaintext to produce the ciphertext.

This allows the block cipher to behave similarly to a stream cipher.

---

# Hardware Architectures

The main objective of this project is to implement the same Two-Key Triple DES algorithm using three different digital hardware architectures.

---

## 1. Single-Cycle Architecture

In the Single-Cycle implementation, each complete DES operation for a 64-bit block is performed combinationally.

A Two-Key Triple DES operation requires:

```text
DES Encryption
      ↓
DES Decryption
      ↓
DES Encryption
```

Therefore, three DES operations are required for each block.

For `N` input blocks, the expected processing latency is:

```text
3 × N cycles
```

### Characteristics

- Large combinational datapath
- Low number of clock cycles
- Less hardware reuse
- Longer critical path

The implementation is located under:

```text
SingleCycle/
```

---

## 2. Multi-Cycle Architecture

The Multi-Cycle implementation reuses the DES hardware across multiple clock cycles.

A DES operation contains 16 rounds:

```text
1 DES operation = 16 cycles
```

Since Two-Key Triple DES requires three DES operations:

```text
3 × 16 = 48 cycles
```

are required for each 64-bit block.

For `N` input blocks:

```text
Latency = 48 × N cycles
```

### Characteristics

- Reuses DES hardware
- Lower combinational complexity
- Higher latency
- Smaller hardware footprint compared with a fully expanded implementation

The implementation is located under:

```text
Multi-Cycle/
```

---

## 3. Pipelined Architecture

The Pipelined implementation divides the complete Triple DES computation into pipeline stages.

The pipeline consists of:

```text
16 stages → DES Encryption with K1

16 stages → DES Decryption with K2

16 stages → DES Encryption with K1
```

Therefore, the complete pipeline contains:

```text
48 stages
```

After the pipeline is filled, multiple data blocks can progress through the architecture concurrently.

For `N` blocks, the expected latency is:

```text
48 + (N - 1) cycles
```

### Characteristics

- High throughput
- Multiple blocks processed concurrently
- 48-stage Triple DES pipeline
- Increased hardware usage
- Well suited for continuous streams of input blocks

The implementation is located under:

```text
Pipeline/
```

---

## Architecture Comparison

| Architecture | Main Strategy | Latency for N Blocks | Main Advantage |
|---|---|---:|---|
| Single-Cycle | Combinational DES operations | `3 × N` | Low cycle count |
| Multi-Cycle | Reuse DES hardware | `48 × N` | Hardware reuse |
| Pipeline | Concurrent block processing | `48 + (N - 1)` | High throughput |

These architectures demonstrate the fundamental trade-offs between:

- Latency
- Throughput
- Hardware reuse
- Hardware complexity
- Critical path length
- Parallelism

---

## DES Building Blocks

The DES implementation is constructed from several dedicated hardware modules.

These include:

```text
IP.v
IP_inv.v

PC1.v
PC2.v

E.v
P.v

S1.v
S2.v
S3.v
S4.v
S5.v
S6.v
S7.v
S8.v

f.v
DES.v
triple_des.v
```

### Initial Permutation

`IP.v` implements the DES Initial Permutation.

### Final Permutation

`IP_inv.v` implements the inverse permutation applied at the end of DES.

### Key Scheduling

The DES key scheduling logic uses modules such as:

```text
PC1.v
PC2.v
ks.v
KS_step.v
```

to generate the round keys required by the 16 DES rounds.

### Expansion Permutation

`E.v` expands the 32-bit right half of the DES state to 48 bits before S-Box substitution.

### S-Boxes

The eight DES substitution boxes are implemented separately:

```text
S1.v
S2.v
S3.v
S4.v
S5.v
S6.v
S7.v
S8.v
```

Each S-Box converts a **6-bit input** into a **4-bit output**.

### P Permutation

`P.v` performs the permutation applied after the S-Box substitution stage.

---

## Parameterized Input Width

The design is not limited to a single 64-bit plaintext block.

The input data width can be parameterized, and the input is divided into 64-bit blocks.

The number of required blocks is calculated as:

```text
Number of Blocks = ceil(DATA_W / 64)
```

This makes it possible to process inputs containing multiple DES blocks.

---

## Zero Padding

If the input width is not an exact multiple of 64 bits, the final incomplete block is padded with zeros.

For example:

```text
300-bit input
        ↓
5 × 64-bit blocks
        ↓
320-bit internal representation
```

The additional bits are zero padding.

Padding is applied only to the final incomplete block.

The padded portion of the final ciphertext is not considered part of the valid original data.

---

## Top-Level Interface

The main design exposes an interface equivalent to:

```verilog
input  wire                 clk,
input  wire                 nrst,
input  wire                 start,
input  wire [1:0]           mode,
input  wire [DATA_W-1:0]    data_in,
input  wire [127:0]         key,
input  wire [63:0]          iv,

output wire [OUT_W-1:0]     data_out,
output wire                 done,
output wire                 busy
```

### Signals

| Signal | Description |
|---|---|
| `clk` | System clock |
| `nrst` | Active-low reset |
| `start` | Starts the encryption operation |
| `mode` | Selects ECB, CBC, or OFB |
| `data_in` | Input plaintext data |
| `key` | 128-bit input containing K1 and K2 |
| `iv` | Initialization Vector used by CBC/OFB |
| `data_out` | Encrypted output |
| `done` | Indicates that processing has completed |
| `busy` | Indicates that the module is currently processing data |

---

## Project Structure

```text
.
├── SingleCycle/
│   ├── main.v
│   ├── triple_des.v
│   ├── DES.v
│   ├── ks.v
│   ├── f.v
│   ├── IP.v
│   ├── IP_inv.v
│   ├── PC1.v
│   ├── PC2.v
│   ├── E.v
│   ├── P.v
│   ├── S1.v
│   ├── S2.v
│   ├── S3.v
│   ├── S4.v
│   ├── S5.v
│   ├── S6.v
│   ├── S7.v
│   ├── S8.v
│   └── singleCycle_tb.v
│
├── Multi-Cycle/
│   ├── main.v
│   ├── triple_des.v
│   ├── DES.v
│   ├── KS_step.v
│   ├── des_primitives.v
│   ├── f.v
│   ├── IP.v
│   ├── IP_inv.v
│   ├── PC1.v
│   ├── PC2.v
│   ├── E.v
│   ├── P.v
│   ├── S1.v
│   ├── S2.v
│   ├── S3.v
│   ├── S4.v
│   ├── S5.v
│   ├── S6.v
│   ├── S7.v
│   ├── S8.v
│   └── multiCycle_tb.v
│
└── Pipeline/
    ├── main.v
    ├── triple_des.v
    ├── DES.v
    ├── KS_step.v
    ├── ks.v
    ├── des_primitives.v
    ├── f.v
    ├── IP.v
    ├── IP_inv.v
    ├── PC1.v
    ├── PC2.v
    ├── E.v
    ├── P.v
    ├── S1.v
    ├── S2.v
    ├── S3.v
    ├── S4.v
    ├── S5.v
    ├── S6.v
    ├── S7.v
    ├── S8.v
    └── pipeline_tb.v
```

---

# Running the Project

The designs were developed and tested using **ModelSim**.

Each architecture has its own testbench:

```text
SingleCycle/singleCycle_tb.v

Multi-Cycle/multiCycle_tb.v

Pipeline/pipeline_tb.v
```

---

## 1. Install ModelSim

Install **ModelSim** or another compatible Verilog simulator.

The instructions below use ModelSim.

---

## 2. Choose an Architecture

Navigate to one of the architecture directories.

For example:

```text
SingleCycle/
```

or:

```text
Multi-Cycle/
```

or:

```text
Pipeline/
```

---

## 3. Start ModelSim

Open ModelSim and navigate to the selected architecture directory.

Create the working library:

```tcl
vlib work
```

---

## 4. Compile the Verilog Sources

Compile the Verilog files:

```tcl
vlog *.v
```

If compilation succeeds, the design and corresponding testbench will be available in the ModelSim `work` library.

---

## 5. Start the Testbench

### Single-Cycle

```tcl
vsim singleCycle_tb
```

### Multi-Cycle

```tcl
vsim multiCycle_tb
```

### Pipeline

```tcl
vsim pipeline_tb
```

---

## 6. Run the Simulation

Run the complete simulation:

```tcl
run -all
```

Signals can also be added to the waveform viewer to inspect:

- Input plaintext
- Output ciphertext
- Clock
- Reset
- Start
- Busy
- Done
- Encryption mode
- Internal DES states

---

# Verification

The implementations are verified using predefined encryption test vectors.

The tests cover:

- ECB mode
- CBC mode
- OFB mode
- Multi-block plaintext
- 256-bit input
- 300-bit input
- Zero-padding behavior

---

## Example ECB Test Vector

One of the provided ECB test vectors uses:

```text
K1 = A4E9432CE07AD076
K2 = 572F7C1513DA495E
```

with four 64-bit plaintext blocks:

```text
P0 = 12BB6F8DF45EF216
P1 = BA7BDE0C26FBA7DC
P2 = D1BF4B48A0F02854
P3 = 9947E3E0C209EE51
```

The expected ciphertext blocks are:

```text
C0 = 307D644D19BEB557
C1 = 59C0DC3E862B8238
C2 = 7EB35CC8ECE07C78
C3 = 0B8762E0708F1DF1
```

Resulting in:

```text
307D644D19BEB55759C0DC3E862B82387EB35CC8ECE07C780B8762E0708F1DF1
```

---

## 300-bit Input Test

The project also tests inputs whose width is not a multiple of the 64-bit DES block size.

For a 300-bit input:

```text
ceil(300 / 64) = 5 blocks
```

The final block contains the remaining input bits and zero padding.

This test verifies that the parameterized design correctly handles incomplete final blocks.

---

## Simulation Workflow

```text
Test Vector
     │
     ▼
Top-Level Module
     │
     ▼
Select Encryption Mode
     │
     ├──── ECB
     ├──── CBC
     └──── OFB
     │
     ▼
Two-Key Triple DES
     │
     ├──── E(K1)
     │
     ├──── D(K2)
     │
     └──── E(K1)
     │
     ▼
Ciphertext
     │
     ▼
Compare with Expected Output
```

---

## Technologies

- Verilog HDL
- ModelSim
- Digital System Design
- DES
- Triple DES (3DES)
- ECB
- CBC
- OFB
- Pipelining
- Multi-Cycle Datapaths
- Digital Hardware Architecture

---

## Authors

This project was developed collaboratively as part of a **Digital Systems Design** course assignment.

- **[@SMousavi7](https://github.com/SMousavi7)**
- **[@TEAMMATE_GITHUB_USERNAME](https://github.com/TEAMMATE_GITHUB_USERNAME)**
