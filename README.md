# Jetson Nano SoC Power-Performance Characterization

**Shubaan Meyyappan** · Wentworth Institute of Technology

A systematic characterization of the NVIDIA Tegra X1 SoC across configurable power modes, using hardware instrumentation and custom CUDA benchmarks. Power draw is measured in real-time from the onboard INA3221 triple-channel power monitor via I2C, while custom CUDA kernels stress different subsystems of the GPU.

**Platform:** NVIDIA Jetson Nano P3450 (Tegra X1, 128 Maxwell CUDA cores, 4GB LPDDR4)  
**Software:** JetPack 4.6.1 — Ubuntu 18.04, CUDA 10.2, Compute Capability 5.3

---

## Motivation

Every semiconductor and GPU architecture role I've looked at lists SoC characterization, CUDA, and power analysis as core skills. This project demonstrates all three on NVIDIA's own silicon — the same kind of work done by hardware validation and power analysis teams internally. It also serves as the foundation for a comparative study once the Jetson Orin Nano Super (Ampere) arrives, enabling a cross-generation architectural comparison.

---

## Hardware Setup

| Component | Details |
|-----------|---------|
| SoC | NVIDIA Tegra X1 |
| GPU | 128 CUDA Cores, Maxwell Architecture |
| Compute Capability | 5.3 |
| Memory | 4GB LPDDR4 (shared CPU/GPU) |
| Memory Bus | 64-bit |
| Theoretical Memory BW | 25.6 GB/s |
| Theoretical FP32 Peak | ~236 GFLOPS |
| GPU Max Clock (MAXN) | 921.6 MHz |
| GPU Max Clock (5W) | 640 MHz |
| Power Monitor | Texas Instruments INA3221 (I2C bus 6, addr 0x40) |

### Power Rails Monitored

| Channel | Rail | Description |
|---------|------|-------------|
| 0 | VDD_IN | Total board input power |
| 1 | VDD_GPU | GPU power domain |
| 2 | VDD_CPU | CPU power domain |

---

## Power Modes

The Tegra X1 exposes two operating modes via `nvpmodel`:

| Mode | Name | CPU Cores | CPU Clock | GPU Clock | Power Budget |
|------|------|-----------|-----------|-----------|-------------|
| 0 | MAXN | 4 | 1479 MHz | 921.6 MHz | 10W |
| 1 | 5W | 2 | 918 MHz | 640 MHz | 5W |

Clocks were locked to maximum for each mode using `jetson_clocks` before every benchmark run to ensure reproducibility.

---

## Methodology

1. Located INA3221 on I2C bus 6 at address 0x40 using `i2cdetect`
2. Wrote a Python power logging harness reading from the Linux sysfs interface at `/sys/bus/i2c/drivers/ina3221x/6-0040/iio:device0/`
3. Sampled all three power rails + six thermal zones at 2 Hz into timestamped CSV files
4. Ran each CUDA benchmark simultaneously with the power logger running in a separate terminal
5. Repeated all benchmarks in both MAXN (10W) and 5W modes
6. Collected idle baseline for both modes as control measurements

---

## Benchmarks

### 1. Matrix Multiplication (`benchmarks/matrix_multiply.cu`)
- Naive CUDA matrix multiply, 1024×1024 FP32
- 10 iterations, averaged
- Compute-bound workload — stresses GPU ALUs
- Compiled: `nvcc -arch=sm_53 benchmarks/matrix_multiply.cu -o benchmarks/matrix_multiply`

### 2. Memory Bandwidth (`benchmarks/memory_bandwidth.cu`)
- Simple array copy kernel, 256MB working set (64M floats)
- 20 iterations, averaged
- Memory-bound workload — stresses the unified memory bus
- Reports effective bandwidth vs theoretical max (25.6 GB/s)

### 3. Compute Throughput (`benchmarks/compute_intensive.cu`)
- FMA (fused multiply-add) loop kernel, 1M threads × 1000 FMA iterations
- Minimal memory access — pure arithmetic throughput

---

## Results

### Performance

| Benchmark | Mode 0 (MAXN) | Mode 1 (5W) | Delta |
|-----------|--------------|-------------|-------|
| Matrix Multiply | ~12.3 GFLOPS, 174ms | ~9.2 GFLOPS, 233ms | -25% perf |
| Memory Bandwidth | 15.19 GB/s | — | 59% of theoretical max |

### Power Characterization

| Benchmark | Avg VDD_IN (W) | Avg VDD_GPU (W) | Avg VDD_CPU (W) | Peak VDD_IN (W) | Avg Temp (°C) |
|-----------|---------------|----------------|----------------|----------------|--------------|
| Mode 0 — Idle | 2.930 | 0.174 | 0.762 | 5.177 | 41.1 |
| Mode 0 — Matrix Multiply | 2.878 | 0.244 | 0.620 | 8.332 | 41.9 |
| Mode 0 — Memory BW | 3.191 | 0.280 | 0.884 | 6.835 | 43.6 |
| Mode 0 — Compute | 3.029 | 0.234 | 0.818 | 7.742 | 43.2 |
| Mode 1 — Idle | 2.492 | 0.087 | 0.395 | 3.269 | 40.9 |
| Mode 1 — Matrix Multiply | 2.644 | 0.177 | 0.463 | 4.642 | 41.0 |
| Mode 1 — Memory BW | 2.675 | 0.125 | 0.509 | 4.881 | 42.4 |
| Mode 1 — Compute | 2.569 | 0.103 | 0.436 | 4.147 | 42.0 |

> Note: Average power values include brief idle periods before/after each benchmark run. Peak VDD_IN values better reflect true load power. During matrix multiply, instantaneous GPU rail draw reached ~2.9W (Mode 0) and ~1.5W (Mode 1).

### Key Findings

**1. Power scales predictably with mode.** Peak board power drops from 8.3W (MAXN) to 4.6W (5W mode) during matrix multiply — a 45% reduction. The 5W mode reliably stays within its power envelope.

**2. Performance degrades less than power.** Matrix multiply performance drops 25% when power budget is cut roughly in half. The 5W mode delivers 75% of MAXN performance at ~55% of the power — making it more efficient (GFLOPS/Watt).

**3. Memory bandwidth is the bottleneck.** Effective bandwidth of 15.19 GB/s is 59% of the 25.6 GB/s theoretical maximum. On the Tegra X1, the CPU and GPU share the same memory bus, so any CPU activity during GPU workloads competes directly for bandwidth — a fundamental architectural constraint of integrated SoCs.

**4. Thermal behavior is stable.** Temperatures remain below 52°C even under sustained load, well within safe operating range. The Tegra X1 manages power via clock scaling rather than thermal throttling in these workloads.

**5. Idle power is significant.** Mode 0 idle draws 2.93W — nearly a third of its peak load power. This matters for always-on edge deployments where workloads are bursty.

---

## Efficiency Summary

| Mode | Benchmark | GFLOPS | Avg Load Power (W) | GFLOPS/Watt |
|------|-----------|--------|-------------------|-------------|
| MAXN | Matrix Multiply | 12.3 | ~6.5 (peak period) | ~1.89 |
| 5W | Matrix Multiply | 9.2 | ~4.3 (peak period) | ~2.14 |

The 5W mode is **~13% more efficient** in GFLOPS/Watt for this workload.

---

## Repository Structure

```
jetson-nano-soc-characterization/
├── benchmarks/
│   ├── matrix_multiply.cu       # Compute-bound: naive 1024x1024 CUDA matmul
│   ├── memory_bandwidth.cu      # Memory-bound: array copy bandwidth test
│   └── compute_intensive.cu     # ALU-bound: FMA throughput kernel
├── power_monitor/
│   ├── ina3221_reader.py        # Live power monitor (terminal display)
│   └── power_logger.py          # Timestamped CSV power logger
├── scripts/
│   └── analyze_data.py          # Summary statistics across all datasets
├── data/
│   └── raw/                     # 8 CSV files (2 modes × 4 workloads)
└── README.md
```

---

## How to Reproduce

```bash
# Clone
git clone https://github.com/Shubaan7/jetson-nano-soc.git
cd jetson-nano-soc

# Lock clocks for consistent results
sudo jetson_clocks

# Compile benchmarks
nvcc -arch=sm_53 benchmarks/matrix_multiply.cu -o benchmarks/matrix_multiply
nvcc -arch=sm_53 benchmarks/memory_bandwidth.cu -o benchmarks/memory_bandwidth
nvcc -arch=sm_53 benchmarks/compute_intensive.cu -o benchmarks/compute_intensive

# Run power logger (Terminal 1)
sudo python3 power_monitor/power_logger.py data/raw/mode0_matmul.csv 120

# Run benchmark (Terminal 2)
for i in 1 2 3 4 5; do benchmarks/matrix_multiply; done

# Analyze results
python3 scripts/analyze_data.py
```

---

## References

- [NVIDIA Tegra X1 Technical Reference Manual](https://developer.nvidia.com/embedded/downloads)
- [NVIDIA Jetson Nano Developer Kit User Guide](https://developer.nvidia.com/embedded/learn/get-started-jetson-nano-devkit)
- [Texas Instruments INA3221 Datasheet](https://www.ti.com/product/INA3221)
- [CUDA C Programming Guide v10.2](https://docs.nvidia.com/cuda/archive/10.2/cuda-c-programming-guide/)
- [nvpmodel documentation](https://docs.nvidia.com/jetson/archives/l4t-archived/l4t-3261/index.html#page/Tegra%20Linux%20Driver%20Package%20Development%20Guide/power_management_jetson_nano.html)

---

---

**Shubaan Meyyappan** · [shubaan76@gmail.com](mailto:shubaan76@gmail.com) · [github.com/Shubaan7](https://github.com/Shubaan7) · [linkedin.com/in/shubaan7](https://www.linkedin.com/in/shubaan7) · [Portfolio](https://shubaanmeyyappan.floot.app/)
