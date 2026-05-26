# 💧 H2O HUB: A Mobile Application Hydration Notification for PSU Lubao Campus
**Smart Campus Hydration Monitoring System**

## 📖 Introduction
**H2O HUB** is an integrated solution designed for hydration monitoring of students at the **PSU Lubao Campus**. It combines IoT hardware, a feature-rich mobile application, and a Web Admin Dashboard for the centralized management of hydration data and system devices.

---

## 📱 Mobile App Full Functionality
Students interact with the mobile application to track their daily hydration progress:

*   **User Authentication**: A secure registration and login system for students.
*   **Real-time Hydration Dashboard**: 
    *   Visual tracking of water intake using the `percent_indicator` package.
    *   The database updates in real-time based on consumption from the dispenser.
*   **QR Code Integration**: 
    *   Features a built-in `mobile_scanner` for quick user identification at every H2O HUB station.
*   **Firebase Sync**: A seamless cloud connection ensures that student intake records are always updated.

---

## ⚙️ How Workmanager Works (Background Logic)
The **Workmanager** serves as the "intelligent engine" that handles notifications even when the app is not in use:

1.  **Periodic Task**: The app runs a background task every **15 minutes** (standard Android interval for battery optimization).
2.  **Remote Data Check**: The system triggers the Workmanager to connect to the **Firebase Realtime Database** to read the user's current `intake` level.
3.  **Smart Decision Logic**: 
    *   **Time Check**: Verifies if the current time is **2:00 PM (14:00)** onwards.
    *   **Volume Check**: Verifies if the intake volume is still below the **2000ml** threshold.
4.  **Notification Trigger**: 
    ```dart
    if (currentTime >= 14 && currentIntake < 2000) {
      // Sends a custom hydration reminder notification.
    }
    ```

---

## 🖥️ Web Admin Dashboard (The Control Center)
A centralized platform for system operation, monitoring, and maintenance:

*   **Water Level Monitoring**: Provides real-time status of the dispenser's water level for refill management.
*   **Device Management**: Monitors the connectivity and status of all IoT devices (Orange Pi) across the campus.
*   **User Management**: 
    *   Provides a total list of registered students.
    *   Allows administrators to delete inactive users to maintain database integrity.

---

## 🛠️ Hardware Architecture
The physical components integrated to track water consumption:
*   **Controller**: **Orange Pi Zero 3**.
*   **Sensors**: 
    *   **YF-S401 Water Flow Sensor**: Measures the precise volume of water dispensed.
    *   **HC-SR04 Ultrasonic Sensor**: Used for user or bottle detection.
*   **System Logic**: Python scripts (`main.py`) interface between the sensors and the Firebase Cloud.

---

## 🎨 Branding & Customization
*   **Official Icon**: The application features a custom **H2O HUB Logo**.
*   **Implementation**: Utilized `flutter_launcher_icons` to generate adaptive icons for professional mobile standards.
*   **Asset Path**: `assets/images/logo.png`.

---

## 📂 Project Structure
*   `/lib/main.dart`: Entry point and background service configuration.
*   `/lib/admin_register.dart`: UI for user registration and management.
*   `/assets/images/`: Storage for branding assets and the official logo.

## 👥 Project Team
*   **Developer**: James Eagan Pulusan Fabian
**Hardware/Analysis** James Fabian
*   **Campus**: Pampanga State University - Lubao Campus

---
*Generated for the H2O HUB Development Project - 2026.*