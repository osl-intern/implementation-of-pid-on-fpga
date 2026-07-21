# Implementation of a Digital PID Controller on FPGA

## Overview

This repository contains the MATLAB models, algorithm development, fixed-point conversion, and verification scripts for implementing a high-speed digital PID controller on an FPGA.

The project targets a real-time digital control system where analog signals are sampled using a high-speed ADC, digitally processed using CIC and FIR filters, controlled using a fixed-point PID controller, and transmitted to a DAC.

The repository serves as the algorithm development and verification stage before HDL implementation and deployment on FPGA hardware.

---

# System Architecture

```
         Analog Input
               │
               ▼
        LTC2314 ADC
               │
               ▼
       ADC Quantization
               │
               ▼
        CIC Decimator
               │
               ▼
   CIC Compensation FIR
               │
               ▼
      Fixed-Point PID
               │
               ▼
        DAC Interface
               │
               ▼
        Analog Output
```

---

# Project Objectives

- Develop a complete digital control chain in MATLAB.
- Design a high-speed CIC decimation filter.
- Design a FIR compensation filter.
- Implement a fixed-point PID controller.
- Verify numerical accuracy before HDL conversion.
- Prepare the complete design for FPGA implementation.

---

# Repository Structure

```
MATLAB/
│
├── ADC_DAC/
│   ├── ADC_Model.m
│   ├── DAC_Model.m
│   ├── DAC_Model_fixed.m
│
├── CIC/
│   ├── cic_design.m
│   ├── cic_analysis.m
│   ├── cic_export.m
│   ├── cic_quantisation.m
│   ├── CIC_Integrator.m
│   ├── CIC_Normalize.m
│   ├── CIC_Comb.m
│   └── CIC_Fixed.m
│
├── FIR/
│   ├── FIR_Filter.m
│   ├── FIR_Filter_Fixed.m
│   ├── FIR_DSP_Validation.m
│   ├── FIR_Design_Explorer.m
│   ├── FIR_Order_Optimization.m
│   ├── FIR_Coefficients.csv
│   └── FIR_Coefficients_Q2_16.csv
│
├── PID/
│   ├── PID_RunSimulation.m
│   ├── PID_GridSearch.m
│   ├── PID_Objective.m
│   ├── PID_CostFunction.m
│   └── PID_CostFunction_Settling.m
│
├── Plant/
│   ├── Build_Plant_TF.m
│   ├── Build_PID_TF.m
│   ├── Build_CIC_TF.m
│   ├── Build_FIR_TF.m
│   ├── Build_Heq_TF.m
│   └── Extract_Heq.m
│
├── Verification/
│   ├── verify.m
│   ├── Digital_FrontEnd_Test.m
│   ├── Test_CIC.m
│   ├── Test_FIR_Filter.m
│   ├── Test_DAC_Model.m
│   └── Test_CIC_Normalize.m
│
└── Utilities/
    ├── OpenLoop_Analysis.m
    ├── Plot_Poles_From_Characteristic.m
    └── FRF_RunFrequency.m
```

---

# Features

## ADC Modeling

- High-speed ADC quantization model
- Digital code generation
- Saturation modelling

---

## CIC Decimation

- Multi-stage CIC filter
- Integrator implementation
- Comb implementation
- Gain normalization
- Frequency response analysis
- Coefficient export

---

## FIR Compensation

- CIC passband compensation
- Frequency response validation
- Fixed-point implementation
- Coefficient generation
- Order optimization

---

## PID Controller

- Floating-point implementation
- Fixed-point implementation
- Grid-search based tuning
- Closed-loop simulation
- Cost function optimization

---

## Plant Modeling

- Continuous transfer function
- Discrete transfer function
- Frequency response generation
- Open-loop analysis

---

## Verification

- Module-level verification
- End-to-end simulation
- Fixed-point validation
- DSP response validation

---

# Hardware Target

The algorithms developed in this repository are intended for FPGA implementation with:

- High-speed ADC (LTC2314)
- High-speed DAC
- Fixed-point DSP architecture
- Verilog HDL implementation
- Vivado Design Suite

---

# Software Requirements

- MATLAB
- Signal Processing Toolbox
- DSP System Toolbox
- Control System Toolbox
- Fixed-Point Designer

---

# Design Flow

```
Plant Modelling
        │
        ▼
ADC Model
        │
        ▼
CIC Filter
        │
        ▼
FIR Compensation
        │
        ▼
PID Design
        │
        ▼
Fixed Point Conversion
        │
        ▼
Verification
        │
        ▼
HDL Implementation
        │
        ▼
FPGA Deployment
```

---

# Current Status

✔ Plant Modeling

✔ ADC Modeling

✔ CIC Design

✔ FIR Compensation

✔ PID Design

✔ Fixed-Point Conversion

✔ MATLAB Verification

✔ HDL Preparation

⬜ FPGA Hardware Validation

⬜ Real-Time Closed-Loop Testing

---

# Future Work

- HDL optimization
- FPGA implementation
- Timing closure
- Hardware debugging
- Real-time controller validation
- Closed-loop performance characterization

---

# Author

**Hrushikesh Jaladani**

B.Tech Electrical Engineering

Indian Institute of Technology (BHU), Varanasi

Internship Project – FPGA-Based Digital Control System

---

# License

This repository is intended for educational and research purposes.
