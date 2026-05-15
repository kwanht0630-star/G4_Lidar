# High-Resolution LiDAR Point Cloud Mapper (MATLAB)

This repository contains a MATLAB script that performs a high-fidelity room scan using a serial 2D LiDAR sensor. Instead of simply updating a live view, this script accumulates dozens of consecutive 360-degree sweeps, merges them to filter out noise, and generates a highly detailed, static probabilistic occupancy grid map.

## 🌟 Features

* **Time-Series Accumulation:** Collects a predefined number of sequential LiDAR sweeps (default: 80) and safely stores them in a MATLAB `timetable`.
* **Dense Point Cloud Merging:** Utilizes `pcmerge` with a 1cm tolerance grid to stitch all 80 sweeps into a single, ultra-dense `pointCloud` object, effectively eliminating transient sensor noise.
* **Batch Ray Tracing:** Feeds the entire dense point cloud array into MATLAB's `insertRay` algorithm all at once to precisely calculate verified free space versus solid obstacles.
* **Custom Protocol Parsing:** Directly parses the raw `[170 85]` serial packet headers and calculates relative angles and distances at a `230400` baud rate without requiring external middleware.

## 📋 Prerequisites

* **Software:** MATLAB (R2019b or newer recommended)
  * **Navigation Toolbox** (Required for `occupancyMap` and `insertRay`)
  * **Computer Vision Toolbox** (Required for `pointCloud` and `pcmerge`)
* **Hardware:** A 2D LiDAR sensor utilizing the `0xAA 0x55` serial header protocol.
  * A USB-to-Serial adapter.



## 🚀 Setup and Usage

1. **Connect your LiDAR:** Plug the LiDAR sensor into your computer via USB.
2. **Identify your Serial Port:**
* On macOS/Linux, it usually looks like `/dev/cu.usbserial-XXXX`.
* On Windows, it will be a COM port (e.g., `COM3`).
3. **Update the Script:** Open the MATLAB script and modify the `lidarPort` variable to match your system's configuration:
```matlab
lidarPort = '/dev/cu.usbserial-0001'; % Change this to your specific port
```
  OR
```matlab
lidarPort = 'COM3'; % Change this to your specific port
```
4. **Run:** Execute the script in MATLAB. The radar window will open, the motor will initialise, and data will begin plotting after a brief startup pause. To stop the program, simply close the figure window.


## ⚙️ Configuration Parameters

| Variable | Default | Description |
| --- | --- | --- |
| `numScans` | `80` | The total number of 360-degree sweeps the script will collect before generating the map. Higher numbers yield denser maps but take longer to process. |
| `baudRate` | `230400` | Serial communication speed for the sensor. |
| `occupancyMap` | `10, 10, 40` | Creates a 10x10 meter map with a resolution of 40 grid cells per meter (2.5cm per pixel). |

## 🎯 Expected Result

<img width="444" height="411" alt="image" src="https://github.com/user-attachments/assets/6f02a291-4f43-4755-a6a0-0fa5481e7cc8" />

Upon running the script, the Command Window will output the status of the data collection as it decodes points.

Once all scans are completed and merged, a dark-themed MATLAB figure will open containing your **High-Resolution Probabilistic Occupancy Map**.

* **🟩 Green Square:** The physical location of the LiDAR sensor at the origin `(0,0)`.
* **⬜ White Areas:** High-confidence free space (areas where the laser successfully traveled without hitting anything).
* **🔲 Dark/Grey Boundaries:** High-confidence occupied space (solid walls, furniture, and boundaries).
* **⬛ Black Areas:** Unscanned or obscured territory (shadows behind solid objects).

Because the map is generated from a merged point cloud rather than a single live frame, the resulting walls and object boundaries will appear significantly sharper, thicker, and more defined than in standard real-time tracking scripts.

