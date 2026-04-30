import csv
import os

data_dir = "data/raw"
files = {
    "mode0_idle": "mode0_idle.csv",
    "mode0_matmul": "mode0_matmul.csv",
    "mode0_membw": "mode0_membw.csv",
    "mode0_compute": "mode0_compute.csv",
    "mode1_idle": "mode1_idle.csv",
    "mode1_matmul": "mode1_matmul.csv",
    "mode1_membw": "mode1_membw.csv",
    "mode1_compute": "mode1_compute.csv",
}

print(f"{'Benchmark':<20} {'Avg VDD_IN':>10} {'Avg GPU':>10} {'Avg CPU':>10} {'Peak IN':>10} {'Avg Temp1':>10}")
print("-" * 75)

for name, fname in files.items():
    path = os.path.join(data_dir, fname)
    vdd_in, vdd_gpu, vdd_cpu, temp1 = [], [], [], []
    with open(path) as f:
        reader = csv.DictReader(f)
        for row in reader:
            try:
                vdd_in.append(float(row["VDD_IN"]))
                vdd_gpu.append(float(row["VDD_GPU"]))
                vdd_cpu.append(float(row["VDD_CPU"]))
                temp1.append(float(row["temp1"]))
            except:
                pass
    if vdd_in:
        avg_in = sum(vdd_in) / len(vdd_in)
        avg_gpu = sum(vdd_gpu) / len(vdd_gpu)
        avg_cpu = sum(vdd_cpu) / len(vdd_cpu)
        peak_in = max(vdd_in)
        avg_t = sum(temp1) / len(temp1)
        print(f"{name:<20} {avg_in:>10.3f} {avg_gpu:>10.3f} {avg_cpu:>10.3f} {peak_in:>10.3f} {avg_t:>10.1f}")
