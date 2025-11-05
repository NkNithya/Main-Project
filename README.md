# Power-Gated HMNoC CNN Accelerator

This repository implements a **Convolutional Neural Network (CNN) accelerator** based on a **Hierarchical Mesh Network-on-Chip (HMNoC)** architecture.  
Each router in the NoC supports **fine-grained power management** and **fly-over (FLoV) bypass links**, enabling high energy efficiency during sparse or low-traffic operation phases of CNN workloads.

---

## 🧠 Project Overview

The accelerator is designed to execute convolutional layers of CNNs using multiple **compute clusters**, each containing a **3×3 systolic array** of Processing Elements (PEs).  
A **router-based mesh interconnect** links these clusters to a **Global Buffer (GLB)** that stores activations, weights, and partial sums.

The routers employ a **deterministic XY routing algorithm** for packet traversal between clusters.  
Power-aware features allow each router to automatically enter a low-power state when idle, drastically reducing static power consumption.

---

## ⚙️ Router Architecture and Power States

Each router has **five ports** — four directional (North, South, East, West) and one **local port** connected to its compute cluster.

Routers operate under a **finite state machine (FSM)** with four power states:

| State | Description |
|--------|--------------|
| **Active** | Normal operation. Buffers, crossbar, and allocator fully enabled. |
| **Draining** | Router stops accepting new flits, clears all pending buffers. |
| **Sleep** | Main logic gated; allocator, buffers, and crossbar disabled. |
| **Wake-Up** | Router reactivates when new data or a wake request arrives. |

To maintain safe transitions, neighboring routers communicate using handshake signals:

| Signal | Function |
|---------|-----------|
| `drain_req` | Request to begin draining before entering sleep mode. |
| `drain_ack` | Neighbor acknowledges readiness for sender to drain. |
| `sleep_notify` | Indicates router has entered sleep; enables fly-over bypass. |
| `wake_req` | Triggered when traffic arrives; initiates router wake-up. |

Even when asleep, a **one-cycle fly-over (FLoV)** path connects opposite ports (N–S and E–W) using latch-based bypass links, allowing packets to pass through without waking the router.

---

## 🧩 Current Status

### ✅ Completed
- CNN dataflow tested on FPGA simulation with 4-cluster configuration.  
- Functional **Hierarchical Mesh NoC** (HMNoC) verified for multi-cluster CNN processing.  
- **UART interface** implemented for off-chip communication and memory access (read/write).  
- **Global Buffer (BRAM)** integrated for activation, weight, and PSUM storage.  
- **Verilog testbenches** created for CNN layer execution and UART communication.

### 🚧 In Progress
- Implementation of **router power management FSM** with:
  - Idle cycle counters,
  - Drain–Sleep–Wake transitions,
  - Fly-over (FLoV) bypass logic.

### 🧭 Next Steps
- Integrate the **power-gated router** into the existing HMNoC fabric.  
- Validate the FLoV-based data path through simulation (functional + power).  
- Perform FPGA synthesis to analyze power savings and timing impact.  
- Extend CNN mapping scripts to dynamically utilize router power states.  

---

## 🧰 Tools and Environment

- **HDL:** Verilog  
- **Simulation:** ModelSim 
- **Synthesis:** Intel Quartus Prime    
- **Host Interface:** UART @ 115200 baud  

---

## 📄 Repository Structure (planned)


