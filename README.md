# AgriFlow Mobile App 📱

A high-performance Flutter mobile application tailored for farmers in Burkina Faso, providing an intuitive interface for agricultural resource procurement, digital assistance, and delivery monitoring.

## 🚀 Key Features

- **Farmer Onboarding**: Simplified registration and onboarding process specifically designed for agricultural users.
- **Product Catalogue**: Browse categorized agricultural inputs (seeds, fertilizers) with detailed descriptions and pricing.
- **Order Management**: easy-to-use checkout process and comprehensive order history.
- **Real-Time Delivery Tracking**: Visual tracking system for monitoring orders from distribution centers to the farm.
- **Smart Intelligence Center**: Multiple AI-powered assistants to support farmers:
    - **AgriFlow Neural**: General agricultural advisor.
    - **AgriFlow Logistics**: Expert in transportation and delivery.
    - **AgriFlow Inventory**: Specialist in input availability and usage.
- **Multi-Role Capability**: Support for Farmer personal view and Distributor global overview.

## 🛠️ Tech Stack

- **Framework**: Flutter (v3.13+)
- **Language**: Dart
- **Networking**: HTTP package for REST API communication.
- **Persistence**: SharedPreferences for session management.
- **Design**: Modern Material 3 UI with a focus on usability and accessibility.

## 📂 Project Structure

- `lib/`:
    - `screens/`: UI layers (Login, Onboarding, Catalogue, History, etc.).
    - `services/`: API communication and business logic.
    - `models/`: Data structures for Products, Orders, and Users.
    - `widgets/`: Reusable UI components and layouts.
- `assets/`: Static resources (images, fonts).

## 🚀 Getting Started

1.  **Prerequisites**: Ensure Flutter is installed and `flutter doctor` passes.
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Configure API**: Ensure the Backend server is running and update `ApiService` with your IP address if using a physical device.
4.  **Run Development**:
    ```bash
    flutter run
    ```

## 📱 Roles on Mobile

- **Farmer**: Default view. Can browse, order, and track their own deliveries.
- **Distributor**: Access to global history. Can view *all* active orders and deliveries within the system.

---

## 📄 License

© 2026 AgriFlow Ecosystem. All rights reserved.
