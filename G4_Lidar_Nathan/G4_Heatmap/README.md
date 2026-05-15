# Live LiDAR Spatial Heatmap (MATLAB)

This repository contains a MATLAB script that interfaces with a serial 2D LiDAR sensor to generate a real-time, accumulating spatial heatmap. Instead of just showing the current laser points, this script remembers where points have been detected, creating a density map that highlights the most frequently occupied spaces or solid walls in your environment over time.

## 🌟 Features

* **Spatial Density Tracking:** Accumulates LiDAR hits into a 2D grid, effectively mapping out solid objects and heavily trafficked areas in real-time.
* **Gaussian Smoothing:** Utilizes `imgaussfilt` to blur the raw grid data, transforming pixelated hit-counts into a smooth, professional-looking thermal heatmap. (Includes an automatic fallback if the Image Processing Toolbox is not installed).
* **Custom 'Turbo' Colormap:** Renders the map using MATLAB's high-contrast `turbo` colormap, customized with a stark white background to make low-density points easy to see.
* **Direct Hardware Parsing:** Reads raw byte streams directly from the serial port (`230400` baud rate) without needing ROS or external middleware.
* **Graceful Shutdown:** Safely sends the motor-stop command to the sensor when the figure window is closed.

## 📋 Prerequisites

* **Software:** * MATLAB (R2019b or newer is recommended for native `serialport` support).
* *Optional but Recommended:* **Image Processing Toolbox** (for the Gaussian smoothing effect).


* **Hardware:** * A compatible 2D LiDAR sensor (using the `0xAA 0x55` packet header protocol).
* A USB-to-Serial adapter.



## 🚀 Setup and Usage

1. **Connect your LiDAR:** Plug the sensor into your computer via USB.
2. **Identify your Serial Port:** * On macOS/Linux: `/dev/cu.usbserial-XXXX`
* On Windows: `COM3`, `COM4`, etc.


3. **Update the Script:** Open the script and modify the `lidarPort` variable:
```matlab
lidarPort = '/dev/cu.usbserial-0001'; % Change this to match your system

```


4. **Run:** Execute the script. The motor will initialize, and the heatmap will begin accumulating data. Close the figure window to safely stop the sensor.

## ⚙️ Configuration Parameters

You can adjust the resolution and scale of the heatmap by modifying these variables at the top of the script:

| Variable | Default | Description |
| --- | --- | --- |
| `mapSize` | `8` | The total physical size of the tracking area in meters (e.g., an 8x8 meter square). |
| `resolution` | `50` | Pixels per meter. Higher values create a sharper grid but require more processing power. `50` means each pixel represents 2cm. |
| `baudRate` | `230400` | Serial communication speed for the sensor. |

## 🎯 Expected Result

Upon successfully running the script, a white-themed MATLAB figure will open, displaying your live spatial heatmap.

* **Background (White):** Areas where the LiDAR has detected nothing (empty space).
* **Cool Colors (Blue/Cyan):** Areas with a low density of laser hits (transient objects or partial reflections).
* **Warm Colors (Yellow/Red/Dark Red):** Areas with a high density of laser hits. This will quickly highlight permanent walls, solid furniture, or the location of the LiDAR sensor itself.
* **Colorbar:** A scale on the right side of the window will show the relative density mapping colors in real-time.

As you run the sensor, the map will continuously build upon itself, growing richer and more defined the longer it scans the room.
