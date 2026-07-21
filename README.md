# Implementation of a Digital PID Controller on FPGA

## Overview

This repository contains the MATLAB models and Verilog HDL developed for implementing a high-speed digital PID controller on an FPGA. The project follows a complete MATLAB-to-HDL workflow, beginning with floating-point algorithm development and verification, followed by fixed-point conversion for FPGA implementation, and finally the development of hardware interfaces for external data converters.

The digital control system consists of a Cascaded Integrator-Comb (CIC) decimation filter, a compensation FIR filter, and a fixed-point PID controller. MATLAB was used for algorithm development, controller tuning, system-level verification, and fixed-point analysis, while Verilog HDL was used to implement SPI interfaces for the external ADCs and DACs.

The repository represents the algorithm development and FPGA preparation stage of the project, providing validated floating-point reference models, FPGA-oriented fixed-point implementations, and HDL interface modules for integration into the final hardware design.

---

# Actual System Architecture

The intended hardware architecture of the project is illustrated below.

```text
                              Setpoint (SP)
                                   │
                            LTC2314-14 ADC
                                   │
                             SPI Interface
                                   │
                                   ▼

      RF Transceiver (61.44 MSPS Process Variable)
                       │
                       ▼
                CIC Decimation Filter
                       │
                       ▼
            CIC Compensation FIR Filter
                       │
                       ▼
              PID + Feedforward Controller
                       │
                       ▼
                    DAC2932 DAC
                       │
                       ▼
                      Plant

           Monitoring Signals (SP, PV,
            Error & Controller Output)
                       │
                       ▼
                    AD5754 DAC
```

The FPGA receives the **Setpoint (SP)** through the **LTC2314-14 SAR ADC**, while the **Process Variable (PV)** is acquired from the RF transceiver operating at **61.44 MSPS**. The PV is first decimated using a CIC filter, compensated using a FIR filter, and then processed by the digital PID controller. The controller output is transmitted to the plant through the DAC2932 DAC, while important internal signals are monitored using the AD5754 DAC.

---

# MATLAB Development Assumptions

During the development of the MATLAB models, the RF transceiver hardware was not available. Consequently, the behavioural model of the **LTC2314-14 ADC** was temporarily used to digitize both the **Setpoint (SP)** and the **Process Variable (PV)**.

This assumption was introduced solely for algorithm development and verification. Since the downstream DSP chain (CIC, FIR, PID, and fixed-point arithmetic) operates only on quantized digital samples, the behaviour of the controller is independent of the acquisition hardware once the signals have been digitized.

Therefore,

**Actual Hardware**

```text
Setpoint (SP)
        │
LTC2314 ADC
        │
        ▼
Controller

Process Variable (PV)
        │
RF Transceiver
        │
        ▼
CIC → FIR → PID
```

**MATLAB Behavioural Model**

```text
Setpoint (SP)
        │
LTC2314 ADC Model
        │
        ▼
Controller

Process Variable (PV)
        │
LTC2314 ADC Model
        │
        ▼
CIC → FIR → PID
```

Only the source of the Process Variable changes between the MATLAB model and the intended hardware implementation. The complete digital signal-processing chain remains identical.

---

# MATLAB Development Workflow

The MATLAB implementation follows a standard FPGA-oriented development methodology where each subsystem is first designed and verified using floating-point arithmetic before being converted into fixed-point arithmetic suitable for HDL implementation.

```text
Floating-Point Design
          │
          ▼
Filter Design & Verification
          │
          ▼
PID Controller Design
          │
          ▼
Closed-Loop Simulation
          │
          ▼
Fixed-Point Conversion
          │
          ▼
HDL Implementation
```

The repository is therefore divided into three major sections:

- **Floating-Point Reference Models** – MATLAB models used for algorithm development and system verification.
- **Fixed-Point Hardware Models** – FPGA-compatible implementations used for numerical verification prior to HDL generation.
- **Verilog HDL Implementation** – RTL implementations of SPI interfaces and corresponding simulation testbenches developed directly from the converter datasheets.

---

# Floating-Point Reference Models

The floating-point models serve as the **golden reference** for the complete digital control system. Every DSP block, controller, and mathematical model was first developed and verified using floating-point arithmetic before being converted into fixed-point implementations suitable for FPGA deployment.

---

# ADC Behavioural Models

These models emulate the behaviour of the external ADC used during MATLAB simulations. They convert analog voltages into quantized digital samples that are subsequently processed by the digital signal-processing chain.

### `ADC_Model.m`

Models the behaviour of the LTC2314 ADC including quantization, reference voltage scaling, and digital code generation. It converts analog inputs into digital samples identical to the hardware ADC and serves as the primary ADC model during controller verification.

### `SP_ADC_Model.m`

Dedicated ADC behavioural model used for digitizing the **Setpoint (SP)** input. During MATLAB development, this model was also temporarily used for the **Process Variable (PV)** because the RF transceiver hardware was unavailable.

### `Test_ADC_Model.m`

Verifies the ADC behavioural model by applying different analog input voltages and validating quantization, saturation limits, and output code generation.

---

# DAC Behavioural Models

These models emulate the digital-to-analog conversion process and reconstruct the controller output for closed-loop plant simulations.

### `DAC_Model.m`

Models the DAC output conversion from digital controller codes back into analog voltages. It provides the analog input required by the plant model during closed-loop simulations.

### `Test_DAC_Model.m`

Validates the DAC behavioural model by applying different digital input values and verifying the reconstructed analog output, output scaling, and saturation behaviour.

---

# CIC Decimation Filter

The CIC (Cascaded Integrator-Comb) filter forms the first stage of the digital front-end. It reduces the high sampling rate of the incoming signal before compensation using the FIR filter.

### `01_CIC_Design.m`

Designs the CIC decimation filter using the selected decimation factor, number of stages, and differential delay. It establishes the first stage of the multirate DSP chain.

### `02_CIC_Analysis.m`

Analyzes the CIC filter by plotting its magnitude response, passband droop, stopband attenuation, and gain characteristics to verify compliance with the required specifications.

### `cic_design.m`

Alternative implementation of the CIC design used during parameter exploration and design refinement before finalizing the filter.

### `cic_analysis.m`

Performs additional frequency-domain analysis and validation of the designed CIC filter.

### `cic_export.m`

Exports the finalized CIC parameters for use in subsequent MATLAB scripts and HDL implementation.

### `CIC_Integrator.m`

Implements and verifies the integrator stages of the CIC filter independently.

### `CIC_Comb.m`

Implements and verifies the comb stages of the CIC filter following the decimation stage.

### `CIC_Normalize.m`

Normalizes the CIC output by compensating for the gain introduced during decimation.

### `Test_CIC.m`

Validates the complete CIC filter implementation against the expected theoretical response.

### `Test_CIC_Integrator.m`

Unit test used to verify the functionality of the CIC integrator stages.

### `Test_CIC_Normalize.m`

Verifies the normalization stage of the CIC filter after decimation.

---

# FIR Compensation Filter (45-Tap)

The FIR filter compensates for the passband droop introduced by the CIC decimator and provides a flat frequency response before the controller.

### `03_CIC_Compensation_FIR.m`

Designs the FIR compensation filter using MATLAB DSP Toolbox and exports the filter coefficients for simulation and HDL implementation.

### `10_FIR_DSP_Validation.m`

Validates the combined CIC + FIR response against the original design specifications and verifies passband flatness and stopband attenuation.

### `FIR_Filter.m`

Floating-point implementation of the compensation FIR filter using the designed coefficients. It serves as the MATLAB golden reference.

### `FIR_Design_Explorer.m`

Interactive design tool used to explore ripple, transition bandwidth, attenuation, and other FIR design parameters before selecting the final implementation.

### `FIR_Order_Optimization.m`

Sweeps different FIR filter orders to determine the minimum number of taps satisfying the required specifications.

### `FIR_Passband_Error.m`

Measures passband ripple and gain error for different FIR configurations to quantify compensation accuracy.

### `FIR_Ripple_Optimization.m`

Optimizes the FIR design to minimize passband ripple while balancing FPGA resource utilization.

### `FIR_Transition_Optimization.m`

Investigates the effect of transition bandwidth on filter order, attenuation, and group delay.

### `FIR_Coefficients.csv`

Stores the floating-point FIR coefficients generated from the final filter design for simulation and hardware implementation.

### `FIR_Coefficients.mat`

MATLAB workspace containing the floating-point FIR coefficients.

### `Test_FIR_Filter.m`

Validates the FIR filter implementation by comparing its response against the expected design specifications.

---

# PID Controller Design & Gain Tuning

The PID controller was initially developed using floating-point arithmetic to establish a reference implementation before fixed-point conversion. Multiple optimization and analysis scripts were created to tune the controller gains and evaluate the transient performance of the closed-loop system.

### `PID_RunSimulation.m`

Runs the complete floating-point closed-loop simulation by connecting the controller with the plant and digital front-end. It evaluates rise time, overshoot, settling time, steady-state error, and overall controller performance.

### `PID_GridSearch.m`

Performs automatic tuning of the PID controller by searching different combinations of **Kp**, **Ki**, and **Kd**. The script ranks candidate controllers according to predefined performance metrics and selects the best performing parameters.

### `PID_Objective.m`

Defines the optimization objective used during PID tuning. It combines multiple transient performance metrics into a single objective function for automated optimization.

### `PID_CostFunction.m`

Computes the controller cost using rise time, overshoot, settling time, and steady-state error. This cost function is used by the tuning algorithms to compare different controller gains.

### `PID_CostFunction_Settling.m`

Alternative cost function that places greater emphasis on settling-time performance. It is primarily used when minimizing settling time is a key design requirement.

### `coarse_grid.m`

Performs an initial coarse search of the PID parameter space before fine optimization. This reduces the search space and improves the efficiency of the tuning process.

### `bandwidth_tune.m`

Adjusts the controller bandwidth by modifying the PID gains and evaluating the resulting frequency response and transient performance.

### `kpkikd_const_analysis.m`

Analyzes the influence of different **Kp**, **Ki**, and **Kd** combinations on system stability and transient response. This script provides insight into controller sensitivity before automated tuning.

### `pid_plant_step.m`

Generates the floating-point closed-loop step response of the controller and plant using the selected PID gains. It is used to evaluate transient performance during controller development.

### `pid_plant_step_tune.m`

Interactive tuning script that repeatedly performs step-response analysis while modifying PID gains to achieve the desired closed-loop behaviour.

---

# Transfer Function & System Analysis

These scripts are used to analyze the mathematical models of the plant, controller, and DSP blocks. They provide frequency-domain analysis, stability evaluation, and equivalent transfer-function generation for the complete control system.

### `Build_Plant_TF.m`

Generates the continuous and discrete transfer-function models of the plant used throughout controller design and verification.

### `Build_PID_TF.m`

Constructs the transfer-function representation of the PID controller for frequency-domain analysis.

### `Build_CIC_TF.m`

Builds the transfer-function representation of the CIC decimation filter for system-level analysis.

### `Build_FIR_TF.m`

Builds the transfer-function representation of the FIR compensation filter.

### `Build_Heq_TF.m`

Constructs the equivalent transfer function of the complete digital signal-processing chain by combining the individual transfer functions.

### `Extract_Heq.m`

Extracts the equivalent transfer function for further analysis and controller design.

### `FRF_RunFrequency.m`

Performs frequency-response analysis of the overall filtering chain and generates Bode plots for validation of the signal-processing path.

### `OpenLoop_Analysis.m`

Evaluates gain margin, phase margin, crossover frequencies, bandwidth, and overall open-loop stability of the control system.

### `Plot_Poles_From_Characteristic.m`

Plots the poles of the characteristic equation to evaluate closed-loop stability and verify controller performance.

### `investigate_immovble_poles.m`

Diagnostic script used to investigate poles that remain unchanged during controller tuning or stability analysis.

---

# Closed-Loop System Simulation

These scripts integrate all the developed models into a complete system-level simulation, allowing verification of the entire digital control chain before fixed-point conversion and HDL implementation.

### `Closed_Loop_System.m`

Integrates the ADC model, CIC decimation filter, FIR compensation filter, PID controller, DAC model, and plant into a complete floating-point closed-loop simulation. It serves as the primary reference model for validating the entire control system.

### `Digital_FrontEnd_Test.m`

Verifies the complete digital front-end by connecting the ADC model, CIC decimation filter, FIR compensation filter, and supporting DSP blocks before integration with the controller. This ensures the integrity of the signal-processing chain independently of the control algorithm.

---

# Fixed-Point Hardware Models

The floating-point reference models were converted into fixed-point implementations to prepare the complete signal-processing chain for FPGA deployment. These models use FPGA-compatible word lengths and arithmetic to verify numerical accuracy while minimizing hardware resource utilization.

### `Closed_Loop_System_fixed.m`

Implements the complete closed-loop control system using fixed-point arithmetic. It serves as the FPGA-oriented reference model for validating the numerical behaviour of the entire signal-processing chain before HDL implementation.

### `DAC_Model_fixed.m`

Fixed-point implementation of the DAC behavioural model used to verify the controller output after fixed-point conversion.

### `CIC_Fixed.m`

Implements the complete CIC decimation filter using fixed-point arithmetic. The model is used to evaluate quantization effects, bit growth, and numerical accuracy prior to FPGA implementation.

### `cic_quantisation.m`

Analyzes quantization effects within the CIC filter and determines appropriate word lengths for the integrator, comb, and normalization stages.

### `FIR_Filter_Fixed.m`

Fixed-point implementation of the 45-tap FIR compensation filter using quantized coefficients. It verifies that the FPGA-oriented implementation closely matches the floating-point reference.

### `pid_plant_step_fixed.m`

Generates the fixed-point closed-loop step response of the controller and plant. The results are compared against the floating-point implementation to verify equivalent controller performance.

### `verify.m`

General verification script used during fixed-point development to compare intermediate results and validate numerical consistency between different stages of the signal-processing chain.

---

# Verilog HDL Implementation

In addition to the MATLAB models, this repository contains Verilog HDL implementations of the SPI interfaces required for communication with the external converters. The controllers were developed directly from the respective device datasheets, and each module is accompanied by a dedicated simulation testbench for functional verification.

---

# LTC2314 ADC SPI Interface

### `LTC2314.txt`

Verilog implementation of the SPI master developed for the **LTC2314-14 SAR ADC**. The controller follows the timing requirements specified in the device datasheet and acquires 14-bit conversion results through the SPI interface.

### `TEST_LTC2314.txt`

Verilog testbench used to verify the functionality and timing of the LTC2314 SPI master. The simulation validates frame generation, clock timing, chip-select behaviour, and data acquisition.

---

# DAC2932 DAC SPI Interface

### `DAC2932.txt`

Verilog implementation of the SPI master for the **DAC2932 DAC**. The controller generates the required serial communication sequence to update DAC outputs from the FPGA.

### `TEST_DAC2932.txt`

Verilog testbench used to validate the DAC2932 SPI controller by verifying clock generation, data transmission, frame formatting, and timing requirements.

---

# AD5754 DAC SPI Interface

### `AD5754.txt`

Verilog implementation of the SPI master for the **AD5754 DAC**. The controller follows the timing specifications provided in the datasheet and supports register configuration and DAC output updates through the serial interface.

### `TEST_AD5754.txt`

Verilog testbench developed to verify the functionality of the AD5754 SPI controller. The simulation checks SPI timing, register frame generation, and correct communication with the DAC.

---

# Development Workflow

The overall development process followed a standard **Model-Based Design** methodology, where the complete control system was first validated in MATLAB before progressing toward FPGA implementation.

```text
                   System Specifications
                            │
                            ▼
                  Plant Modelling & Analysis
                            │
                            ▼
               ADC Behavioural Modelling
                            │
                            ▼
                 CIC Decimation Filter Design
                            │
                            ▼
             FIR Compensation Filter Design
                            │
                            ▼
                PID Controller Design & Tuning
                            │
                            ▼
              Closed-Loop System Verification
                            │
                            ▼
               Fixed-Point Conversion & Analysis
                            │
                            ▼
                Verilog HDL Interface Development
                            │
                            ▼
             FPGA Integration & Hardware Validation
```

---

# Software & Development Tools

The following software tools and technologies were used throughout the project.

| Category | Software / Tool |
|-----------|-----------------|
| Programming Language | MATLAB |
| DSP Design | DSP System Toolbox |
| Control Design | Control System Toolbox |
| Fixed-Point Analysis | Fixed-Point Designer |
| HDL Preparation | HDL Coder |
| HDL Development | Verilog HDL |
| FPGA Design | Xilinx Vivado |
| Version Control | Git & GitHub |

---

# Repository Highlights

This repository includes the complete algorithm development flow for implementing a digital PID controller on FPGA, including:

- Floating-point behavioural models for the complete signal-processing chain.
- CIC decimation filter design, analysis, and optimization.
- 45-tap FIR compensation filter design and validation.
- Automatic PID gain tuning using MATLAB.
- Transfer-function generation and frequency-domain analysis.
- Closed-loop controller verification.
- FPGA-oriented fixed-point implementation.
- Verilog SPI master implementations for LTC2314, DAC2932, and AD5754.
- Dedicated Verilog testbenches for validating each SPI interface.

---

# Current Project Status

| Module | Status |
|---------|:------:|
| Floating-Point System Modelling | ✅ Completed |
| ADC Behavioural Model | ✅ Completed |
| DAC Behavioural Model | ✅ Completed |
| CIC Decimation Filter | ✅ Completed |
| FIR Compensation Filter | ✅ Completed |
| PID Controller Design & Tuning | ✅ Completed |
| Transfer Function & Stability Analysis | ✅ Completed |
| Closed-Loop System Simulation | ✅ Completed |
| Fixed-Point Implementation | ✅ Completed |
| Verilog SPI Master – LTC2314 | ✅ Completed |
| Verilog SPI Master – DAC2932 | ✅ Completed |
| Verilog SPI Master – AD5754 | ✅ Completed |
| Verilog Testbenches | ✅ Completed |
| FPGA Integration | ⏳ Planned |
| Hardware Validation | ⏳ Planned |

---

# Future Work

The MATLAB models and Verilog interface modules developed in this repository provide the foundation for the complete FPGA implementation. The remaining work primarily focuses on hardware integration and validation.

Future work includes:

- Integration of the DSP chain with the FPGA top-level design.
- Integration of the RF transceiver interface for acquiring the Process Variable (PV).
- Clock-domain crossing (CDC) implementation between multiple sampling domains.
- FPGA synthesis, implementation, and timing closure.
- Hardware validation using the target FPGA platform.
- Real-time closed-loop testing and controller performance evaluation.

---

# Author

**Hrushikesh Jaladani**

B.Tech. Electrical Engineering  
Indian Institute of Technology (BHU), Varanasi

Internship Project – FPGA-Based Digital PID Controller

---

# License

This repository is intended for educational, research, and learning purposes.

---
