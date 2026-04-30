import time

SYSFS_BASE = "/sys/bus/i2c/drivers/ina3221x/6-0040/iio:device0"

RAILS = {
	"VDD_IN": "in_power0_input",
	"VDD_GPU": "in_power1_input",
	"VDD_CPU": "in_power2_input",
	}

def read_rail(filename):
	try:
		with open(f"{SYSFS_BASE}/{filename}","r") as f:
			return float(f.read().strip()) / 1000.0
	except:
		return 0.0

def read_all():
	return {name: read_rail(fname) for name, fname in RAILS.items()}

if __name__== "__main__":
	print("Rail 		Power (W)")
	print("-" * 25)
	while True:
		readings = read_all()
		for name, watts in readings.items():
			print(f"{name:<12} {watts:.3f} W")
		print()
		time.sleep(1)
