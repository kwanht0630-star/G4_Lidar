# G4_Lidar

This is my internship project based on discovering the functionality of the G4 Lidar.

# YDLIDAR G4 & JetAuto Pro Development Log

A complete MATLAB development suite for the **YDLIDAR G4** laser scanner and the **JetAuto Pro** robotics platform, detailing dependencies, hardware sprints, and specific mapping/tracking scripts.

---

## 🛠️ Environment & Toolbox Dependencies

To run the scripts in this repository, ensure your MATLAB environment includes the following versions (installed during the **Day 2 & Day 4** environment configuration sprints):

* **Automated Driving Toolbox** (v24.2)
* **Computer Vision Toolbox** (v24.2)
* **ROS Toolbox** (v24.2)
* **Navigation Toolbox** (v24.2)
* **RPLidar A1 Reader Support Package** (v1.58)

---

## ⏱️ 4-Day Development Timeline

### Day 1 & 2: Environment Setup & Core Foundations

* **Toolbox Configuration:** Deployed fundamental packages for computer vision, automated driving, and ROS communications.
* **Basic LiDAR Scripts:** Programmed live Cartesian coordinate streamers, basic Point Cloud visualizers, and evaluated built-in MATLAB mapping examples (*"Build A Map From Lidar Data"*).

### Day 3: Hardware Benchmarking & First-Gen Mapper

* **JetAuto Pro Integration:** Conducted live testing of integrated LiDAR SLAM routines.
* **Disassembly & Benchmarking:** Tore down the JetAuto Pro chassis to analyze physical component configurations.
* **First-Gen Meter-Scale Mapper:** Authored custom hardware safety blocks and compiled sequential multi-scan assembly loops to generate the initial room maps.

### Day 4: High-Resolution SLAM & Tracking Suite

* **Production Deployment:** Modularized individual tracking, SLAM, and spooling scripts. Added support infrastructure for advanced mapping resolutions and dynamic target monitoring.
* **Personal Exploration:** Developed a custom spatial accumulation heatmap tool to experiment with long-term environmental data density visualization.

---

## 📁 Repository Script Guide

The workspace scripts developed during Day 3 and Day 4 are split by application intent below:

### 📡 Data Streaming & Infrastructure

* **`G4_Point_Cloud_Spooler_Nathan.m`** – Asynchronously caches hardware parsed data blocks into an organized workspace `timetable` for processing.
* **`G4_Direct_Map_Nathan.m`** – Real-time Cartesian coordinate scatter mapper.

### 🗺️ Occupancy Mapping & SLAM

* **`G4_HighRes_Occupancy_Grid_Map_Nathan.m`** – Builds high-density probabilistic occupancy grids using standard ray-casting.
* **`G4_HighRes_Occupancy_Grid_Map_ver2_Nathan.m`** – Advanced grid builder optimized with sub-centimeter merging metrics to preserve wall features.
* **`G4_Sequential_SLAM_Builder_Nathan.m`** – Executes custom Simultaneous Localization and Mapping utilizing pre-spooled point cloud inputs.

### 📊 Spatial Analysis & Tracking

* **`G4_Heatmap_Nathan.m`** – Developed as a personal interest feature; features a live, long-term environmental data accumulation engine wrapped in a high-contrast, light-themed renderer to visualize spatial density and frequency.
* **`G4_Active_MultiTarget_Tracking_Nathan.m`** – Segments spatial point clusters to identify, isolate, and trace multi-target movements dynamically.

---

## 🚀 Execution Workflow

To successfully map a localized workspace:

1. **Clean Connections:** Always check your port settings inside the chosen script:
```matlab
lidarPort = '/dev/cu.usbserial-0001'; 
baudRate = 230400;

```
I am in MacOS and using USB Serial 0001 so it will be /dev/cu.usbserial-0001. You may refer to your own port.
