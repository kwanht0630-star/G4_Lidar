# Ultra High-Resolution Stationary Room Mapping (MATLAB)

This repository contains a professional-grade MATLAB script that performs a high-fidelity environmental scan using a 2D LiDAR sensor. By accumulating 80 sequential sweeps and merging them into a single dense point cloud, this tool filters out transient noise and constructs an extremely precise, static probabilistic occupancy grid.

## 🌟 Features

* **Ultra-High Resolution:** Generates an `occupancyMap` with a resolution of 200 cells per meter, allowing for structural mapping with a precision of 5 millimeters.
* **Smart Hardware Management:** Automatically halts the LiDAR motor immediately after data collection finishes, preserving the motor's lifespan while the CPU handles the heavy map generation.
* **Dense Point Cloud Merging:** Utilizes `pcmerge` to stitch dozens of raw laser scans into a single, noise-filtered coordinate dataset.
* **Professional UI:** Renders the final map in a dark-themed visualizer complete with an automatically scaled zoom limit (framing the central 7x7 meter area) and a custom generated map legend.
* **Direct Hardware Parsing:** Directly parses the raw `[170 85]` serial packet headers and calculates relative angles and distances at a `230400` baud rate without requiring external middleware.

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

## ⚙️ Key Configuration Parameters

| Variable | Default | Description |
| --- | --- | --- |
| `numScans` | `80` | The total number of 360-degree sweeps collected. Higher numbers yield denser maps but increase collection time. |
| `baudRate` | `230400` | Serial communication speed for the sensor. |
| `occupancyMap` | `10, 10, 200` | Creates a 10x10 meter map with 200 grid cells per meter (5mm resolution). |
| `zoomLimit` | `3.5` | Automatically crops the visual output to a 7x7 meter square (from -3.5m to +3.5m on both axes) to focus on the most relevant data. |

## 🎯 Expected Result

<img width="774" height="739" alt="image" src="https://github.com/user-attachments/assets/f45a719b-8489-4465-87d1-cc399e529c51" />

Upon completion, a high-contrast MATLAB figure will open containing your environment's map. Because the map is generated from a merged array of 80 scans at a 5mm resolution, the resulting walls, corners, and object boundaries will appear incredibly sharp.

**Map Key (Legend Included in UI):**

* **🟩 Green Square:** The exact location of the LiDAR sensor at the origin `(0,0)`.
* **⬜ White Areas (Clear Space):** Verified free space where the laser safely traveled.
* **🔲 Black Squares (Wall / Obstacle):** High-confidence solid boundaries.
* **⬛ Grey Background:** Unscanned or obscured territory (e.g., shadows cast behind solid objects).

