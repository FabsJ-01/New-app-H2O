# 💧 H2O HUB: A Mobile Application Hydration Notification for PSU Lubao Campus
**Smart Campus Hydration Monitoring System**

## 📖 Introduction
**H2O HUB** is an integrated IoT-driven solution designed for precision hydration monitoring of students at the **PSU Lubao Campus**. It seamlessly combines customized embedded hardware, a feature-rich cross-platform mobile application, and a Web Admin Dashboard to establish a centralized ecosystem for real-time hydration telemetry and system node management.

---

## 📱 Mobile App Core Functionalities
Students interact with the Flutter-based mobile application to monitor their biological hydration benchmarks and securely access campus hydration nodes:

* **User Authentication**: A secure, persistent authentication system mapped directly to the student's unique institutional credentials.
* **Real-time Hydration Dashboard**: 
    * **Dynamic Title UI**: Displays a clean "Hydration Monitoring" structural header for proper visual telemetry tracking.
    * **Visual Metric Tracking**: Leverages the `percent_indicator` architecture to render real-time progression vectors against strict biological fluid demands.
    * **Automated Reset Engine**: Detects calendar day crossovers via internal timestamping vectors to programmatically flush data blocks and reset student intake attributes to `0ml` daily.
* **QR Code Integration**: 
    * Utilizes a built-in `mobile_scanner` framework to generate a high-density, unique user authentication QR code bound to the student's background record, enabling rapid handshake validation at physical campus hub sub-stations.
* **Firebase Synchronization**: Continuous, asynchronous state synchronization via non-blocking data streams ensures immediate alignment between local app interfaces and cloud record layers.

---

## ⚙️ Background Processing & Dual-Engine Architecture
The application runs a specialized, fault-tolerant background architecture optimized for Android's OS limits to process alerts and monitor peripheral system status without continuous foreground persistence:

### 1. Dynamic Hydration Engine (Workmanager Task Layer)
Driven by the `Workmanager` API, this mechanism operates as an automated state-loop executing structural logic cycles across changing time gaps:
* **Dynamic DOH Algorithm Validation**: Rather than enforcing fixed generic quotas, the system dynamically shifts target volume thresholds by processing the target user's profile metadata against official **Department of Health (DOH) Guidelines**:
    * *Ages 19–59*: Males = `3000ml` | Females = `2300ml`
    * *Ages 16–18*: Males = `2600ml` | Females = `2200ml`
    * *Ages 13–15*: Males = `2400ml` | Females = `2100ml`
* **Recursive Scheduling Framework**: The background controller evaluates current intake metrics against the calculated DOH profile benchmark:
    * **Stagnant Intake State**: If water intake fails to advance past the previously recorded volume data block, the runtime environment fires an instant localized reminder and schedules an aggressive **30-minute high-frequency alert cycle** to prompt hydration.
    * **Active Progress State**: Upon successful data increment detection, the background engine adjusts the process timing back to a standard **60-minute interval loop** to reduce operating overhead.
* **Global Standby Toggle (Campus Alerts Guard)**: Features a centralized state listener tied directly to `SharedPreferences`. When the user toggles the UI switch component to active suspension (e.g., *Alerts Paused / At Home*), the engine aborts network fetches instantly, suspending notification processes completely to safeguard device runtime resources.

### 2. Hardware Event Monitor (Foreground Service Layer)
Driven by the `flutter_background_service` package, this framework runs a persistent low-overhead background thread designed to manage hardware handshakes:
* **Real-time Coin Hardware Hook**: Listens directly to live changes inside the specific Firebase node path (`users/$uid`).
* **Verification Event Handling**: When the hardware architecture flags physical currency validation (`is_scanning: true`, `coin_trigger: false`, `last_credits > 0`), the background handler overrides system sleep states to push an immediate alert notification:
    ```text
    Title: Credits Received! ✅
    Body: PHP [X].00 detected. Click DISPENSE in the app.
    ```

---

## 🖥️ Web Admin Dashboard (The Control Center)
A multi-tenant administrative workstation designed for device diagnostics, auditing, and maintenance operations:

* **Liquid Mass Auditing**: Captures continuous level telemetry from field-deployed tanks to streamline station maintenance scheduling.
* **Node Integrity Monitoring**: Aggregates heartbeats and connection metrics from distributed edge controllers located throughout the campus.
* **Database Sanitization**: Provides administrative vectors to flush inactive nodes, manage credential structures, and enforce compliance resets across the system network.

---

## 🛠️ Hardware Architecture
The peripheral hardware platform deployed across campus hubs to capture water consumption metrics:
* **Edge Compute Module**: High-performance microcontroller and single-board compute architectures (ESP32-S3 / Mini PC infrastructure) executing unified device logic.
* **Sensor Array Sub-system**: 
    * **YF-S401 Water Flow Sensor**: A high-precision hall-effect turbine system that translates rotational mechanical motion into distinct pulse counts for exact metric volume computation.
    * **Proximity Tracking Suite**: Incorporates ultrasonic (`HC-SR04`) and capacitive proximity matrices to validate vessel alignment prior to fluid deployment.
* **System Middleware Integration**: Python system routines execute native low-level sensor analysis and act as a reliable transmission interface to pipe data to the cloud architecture.

---

## 📂 System File Map Overview
* `/lib/main.dart`: Contains system bootstrap logic, dynamic background service task loops, and global notification dispatcher hooks.
* `/lib/dashboard.dart`: Provides the interactive telemetry dashboard interface, dynamic title indicators, percent visualizations, and the global alert toggle controller.
* `/lib/notification_scheduler.dart`: Low-level wrapper logic interface handling native Android notification channel registers and payload construction.
* `/lib/profile_page.dart`: Interface managing student physical criteria values used by the DOH computation routine.

---
## 👥 Project Team
* **PROGRAMMER & HARDWARE/SYSTEM ANALYST**: James Eagan Pulusan Fabian -
* **DOCU/RESEARCHER**: Dannylyn Roque, Adrianne Limongco, John Hazelle Apelado
* **Hardware Analyst/System Analyst**: Edmund Manalansan
* **Frontend Designer**: John Paul Ruiz
* **Institution**: Pampanga State University - Lubao Campus

---
*Documented for the H2O HUB System Architecture Defense - 2026.*