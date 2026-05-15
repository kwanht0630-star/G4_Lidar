# Mobile LiDAR Data Capture (MATLAB)

This repository contains a specialized Data Acquisition (DAQ) MATLAB script designed to record continuous 2D LiDAR point clouds while the sensor is in motion. Rather than rendering a live map, this "headless" script focuses entirely on high-speed data collection, formatting the output into a time-stamped dataset perfectly structured for offline SLAM (Simultaneous Localization and Mapping) or secondary map-building scripts.

## 🌟 Features

* **Dynamic Data Acquisition:** Optimized for capturing frames while the sensor is moving, allowing you to walk the LiDAR through a hallway or room.
* **Chronological Timetable Storage:** Packages every frame as a `pointCloud` object inside a MATLAB `timetable`. This time-series formatting is critical for algorithms that need to calculate odometry or trajectory.
* **Workspace Persistence:** Uses `clearvars -except lidarPointClouds` to cleanly wipe the workspace of temporary variables while preserving your captured dataset for immediate use in downstream scripts.
* **Headless Operation:** Bypasses live plot rendering to dedicate 100% of CPU cycles to serial parsing, preventing buffer overflows and dropped frames during movement.
* **Safe Shutdown:** Automatically halts the LiDAR motor upon completion of the requested frames.

## 📋 Prerequisites

* **Software:** MATLAB (R2019b or newer is recommended for native `serialport` support).
* **Hardware:** * A compatible 2D LiDAR sensor. (The script is tuned for sensors operating at a `230400` baud rate that utilise the `0xAA 0x55` / `[170 85]` packet header protocol).
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
5. **Move the Sensor:** As soon as the motor spins up and the console reads `Capturing 60 frames. Move the Lidar SLOWLY...`, begin smoothly and slowly moving the sensor through your environment. Avoid sudden jerks or fast rotations.

## ⚙️ Key Configuration Parameters

| Variable | Default | Description |
| --- | --- | --- |
| `numScansToRecord` | `60` | The total number of consecutive frames to capture. Increase this number for longer walking paths (e.g., `200` for a long hallway). |
| `baudRate` | `230400` | Serial communication speed for the sensor. |

## 🎯 Expected Result

<img width="644" height="1079" alt="image" src="https://github.com/user-attachments/assets/2b4c1bbc-54f7-4586-8fb4-be10f31a85f6" />

Because this is a headless DAQ script, **no visual figure will open**. Instead, you will see real-time progress printed in the MATLAB Command Window:

```text
Lidar spinning. Initializing capture...
Capturing 60 frames. Move the Lidar SLOWLY...
Captured Frame 1/60 (385 points)
Captured Frame 2/60 (392 points)
...
✅ Capture complete! The "lidarPointClouds" variable is now in your Workspace.
👉 You can now run your Map Builder script.

```

Upon completion, you will find a highly structured `timetable` named **`lidarPointClouds`** sitting in your MATLAB Workspace. You can now leave this data in memory and immediately execute your secondary SLAM or trajectory-mapping script to process the room layout.


