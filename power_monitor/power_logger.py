import time
import csv
import sys
from datetime import datetime

SYSFS_BASE = "/sys/bus/i2c/drivers/ina3221x/6-0040/iio:device0"
THERMAL = "/sys/devices/virtual/thermal/thermal_zone"


def read_power(rail):
	try:
		with open(SYSFS_BASE + "/in_power" + str(rail) + "_input","r") as f:
			return float(f.read().strip()) / 1000.0
	except:
		return 0.0

def read_temp(zone):
	try:
		with open(THERMAL + str(zone) + "/temp","r") as f:
			return float(f.read().strip()) / 1000.0
	except:
		return 0.0

outfile = sys.argv[1] if len(sys.argv) > 1 else "data/raw/log.csv"
duration = int(sys.argv[2]) if len(sys.argv) > 2 else 60


with open(outfile, "w", newline="") as f:
	writer = csv.writer(f)
	writer.writerow(["time", "VDD_IN", "VDD_GPU", "VDD_CPU", "temp0", "temp1", "temp2"])
	start = time.time()
	while time.time() - start < duration:
		row = [datetime.now().isoformat()]
		row.append(read_power(0))
		row.append(read_power(1))
		row.append(read_power(2))
		row.append(read_temp(0))
		row.append(read_temp(1))
		row.append(read_temp(2))
		writer.writerow(row)
		f.flush()
		time.sleep(0.5)

print("Done: " + outfile)
