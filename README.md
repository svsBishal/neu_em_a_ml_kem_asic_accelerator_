# ML-KEM ASIC Accelerator

A synthesizable, ASIC-ready hardware accelerator for ML-KEM polynomial arithmetic. This repository contains the SystemVerilog design and simulation files for a high-throughput, pipelined Number Theoretic Transform (NTT) computation engine.

## Overview

This project aims to develop a specialized hardware accelerator for ML-KEM, utilizing a two-tier hybrid design that yields a 57.1% reduction in global memory bandwidth. The architecture exploits parallel NTT/INTT butterfly processing and incorporates custom Address Generation Units (AGUs) and division-free K2RED modular reduction to optimize hardware cost and latency while ensuring constant-time execution to minimize timing-dependent security leakages.

## Repository Structure

* **`NTT Design/`**: Contains the SystemVerilog RTL source code for the ML-KEM NTT engine, Kaleidoscope Clusters, Butterfly Units, and modular arithmetic components.

* **`NTT Sim/`**: Contains the simulation and testbench files used to verify the functional correctness of the RTL modules.

## Proposed Architecture

### 1. Top Level Architecture (NTT Engine)

The top-level execution engine consists of a Main Control Unit, a Global AGU, Global SRAM, ROM for twiddle factors, and **four independent Kaleidoscope Clusters**.

![Top Level Block Diagram of the FNTT/INTT Computation Engine](top.png)

### 2. The Kaleidoscope Cluster

The heart of the architecture, each cluster operates autonomously to handle localized polynomial arithmetic. 

![Kaleidoscope Cluster](kaleidoscope_arch.png)

It features:
* **KC FSM**: Drives a continuous 20-cycle depth-first execution loop (LOAD $\rightarrow$ COMPUTE $\rightarrow$ STORE).
* **L_AGU (Local AGU)**: Utilizes bit-weaving for zero-adder dynamic stride generation.
* **8 Parallel Butterfly Units (BUs)**: Ensures 100% hardware utilization with zero pipeline stalls.
* **Shared L1 Cache**: Traps 64-word blocks natively for localized operations.

**Internal Block Diagram:**
![Internal Block Diagram of the Kaleidoscope Unit](kaleidoscope_internal.png)

### 3. Pipelined Butterfly Unit

A 4-stage reconfigurable pipelined data path consisting of:
1. Modular Adder & Subtractor
2. Dynamic Input Router & Twiddle Factor Synchronization
3. Division-Free K2RED Reduction Unit
4. Output Selection Router

![Internal Block Diagram of the pipelined reconfigurable butterfly unit](butterfly_unit.png)

**NTT Butterfly Operation:**
For each pair $(A,B)$ with twiddle factor $W$:
$A^{\prime} = (A + BW) \mod q$
$B^{\prime} = (A - BW) \mod q$

**INTT Butterfly Operation:**
$A^{\prime} = (A + B) \mod q$
$B^{\prime} = (A - B)W^{-1} \mod q$
*(where* $q = 3329$ *is the ML-KEM modulus)*

## Execution Scenarios

The hybrid architecture utilizes three execution phases:

* **Global Horizontal**: The Global-AGU sweeps the 256-coefficient polynomial horizontally for Layers 0 & 1 (Strides 128, 64).
* **Local Horizontal**: The polynomial fractures into 64-word blocks stored in L1 Cache. The L_AGU sweeps Strides 32 & 16.
* **Interleaved Horizontal**: The L_AGU weaves four 16-word sub-blocks continuously to mask the 4-cycle Butterfly Unit latency (Layers 4, 5, 6).

## Current Progress (Verified Work)

The following blocks have been successfully implemented in SystemVerilog and verified via RTL simulation:

* **Modular Arithmetic Blocks**: Modular addition, subtraction, multiplication, and division-free K2RED modular reduction.
* **Butterfly Units**: Both Forward NTT and INTT butterfly operations with correct data paths.
* **Local Address Generation Unit (L-AGU)**: Verified local coefficient addressing and stride/access patterns.
* **Kaleidoscope Cluster FSM**: Proper synchronization of LOAD, COMPUTE, and STORE states.

## Future Work

* **Point-wise Multiplication Unit**: To multiply the NTT transformed polynomial vectors.
* **Global AGU & Global Control Logic**: Develop FSM and address generation units to coordinate pipeline execution and reduce routing bottlenecks.
* **Constant Time Execution Validation**: Strict guarantees against side-channel leaks.
* **Complete ASIC Evaluation**: Full RTL synthesis and extraction of Area, Power, Timing, Throughput, and Latency metrics.
