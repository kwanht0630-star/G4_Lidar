# Live Multi-Target LiDAR Radar (MATLAB)

This repository contains a MATLAB script that interfaces with a serial 2D LiDAR sensor to provide a real-time, interactive radar visualization. It continuously reads raw point cloud data, maps it to a 2D Cartesian grid, and actively tracks the closest targets around the sensor.

## 🌟 Features

* **Real-Time Point Cloud Visualization:** Renders incoming LiDAR distance and angle data dynamically on a custom-styled dark-mode plot.
* **Active Multi-Target Tracking:** Automatically identifies and highlights up to 5 of the closest distinct obstacles in real-time.
* **Live Telemetry Readouts:** Displays precise distance (meters) and angle (degrees) annotations directly next to tracked targets.
* **Spatial Filtering (De-clustering):** Implements a "clear radius" algorithm to ensure multiple tracking points don't cluster on a single large physical object.
* **Graceful Shutdown:** Automatically sends the stop command to halt the LiDAR motor when the figure window is closed.

## 📋 Prerequisites

* **Software:** MATLAB (R2019b or newer is recommended for native `serialport` support).
* **Hardware:** * A compatible 2D LiDAR sensor. (The script is tuned for sensors operating at a `230400` baud rate that utilize the `0xAA 0x55` / `[170 85]` packet header protocol).
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
4. **Run:** Execute the script in MATLAB. The radar window will open, the motor will initialize, and data will begin plotting after a brief startup pause. To stop the program, simply close the figure window.

## ⚙️ Configuration Parameters

You can easily tweak the radar's behavior by modifying the variables at the top of the script:

| Variable | Default | Description |
| --- | --- | --- |
| `baudRate` | `230400` | Serial communication speed. |
| `scanRadius` | `4` | The maximum visible range of the radar plot (in meters). |
| `maxTargets` | `5` | The maximum number of independent targets the script will track. |
| `clearRadius` | `0.3` | The exclusion zone (in meters) around a tracked target. Any data points within this radius are ignored by the tracker to prevent clustering on a single object. |

## 🛠️ Troubleshooting

* **`Connection failed. Unplug and replug the USB.`**

Ensure the LiDAR is plugged in and the `lidarPort` string exactly matches your system's active port.
Make sure no other software (like another terminal or LiDAR viewer) is currently holding the serial port open.


* **No data is plotting but the motor is spinning:**

Verify that your specific LiDAR model uses the packet structure expected by the parser (packet headers `[170 85]`). If using a different brand of LiDAR, the byte-parsing logic inside the `while` loop will need to be adapted to match your manufacturer's datasheet.

## 📸 Expected Result

<img width="740" height="718" alt="image" src="https://github.com/user-attachments/assets/724fab12-23e1-4726-bb9c-21e917bffa11" />

Upon successfully running the script, a dark-themed interactive MATLAB figure will open, acting as your live radar display. 

You will see the following real-time data visualizers:
* **🟢 Green Center Dot:** Represents the physical location of the LiDAR sensor at coordinate `(0,0)`.
* **🩵 Cyan Point Cloud:** Represents the raw outline of the room and objects detected by the laser pulses.
* **🔴 Red Trackers:** Dynamic tethers pointing to the closest distinct obstacles within the scan radius (up to `maxTargets`).
* **🟡 Yellow Telemetry:** Live text readouts displaying the exact distance (in meters) and relative angle (in degrees) of each tracked target.

The map will continuously update in real-time as objects move around the sensor. Closing the figure window will safely stop the LiDAR motor and close the serial connection.
