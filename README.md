# TxtFlow SMS Gateway

**TxtFlow** is a powerful, open-source Android SMS Gateway built with Flutter. It turns your Android device into a dedicated SMS server, allowing you to send and receive SMS messages programmatically via a REST API.

![Logo](assets/images/logo.png)

## 🚀 Features

*   **Turn Android into SMS Gateway**: Use your existing SIM card and mobile plan to send/receive messages.
*   **Background Polling**: robust background service using `Workmanager` to fetch and send pending messages even when the app is closed.
*   **Real-time Incoming SMS**: Automatically forwards received SMS messages to your server via Webhook.
*   **Dashboard & Stats**: Real-time monitoring of service status, sent/received counts, and detailed activity logs.
*   **Configurable**:
    *   **API URL**: Point to any backend server.
    *   **Polling Interval**: Adjustable frequency (min 15 mins) for battery optimization.
    *   **Whitelist**: Restrict operations to specific phone numbers for safety.
*   **Manual Testing**: Built-in UI to send test messages directly from the dashboard.
*   **Resilient**: Auto-retries on network failure and handles "Doze mode" restrictions.

## 💡 Use Cases

### 1. Transactional Notifications
Send OTPs (One Time Passwords), order confirmations, or appointment reminders to your customers without paying per-SMS fees to providers like Twilio.

### 2. Server Monitoring & Alerts
Hook up your monitoring stack (Prometheus, Grafana, Uptime Kuma) to TxtFlow to receive critical infrastructure alerts via SMS when your internet is down.

### 3. Marketing Campaigns
Run small-scale SMS marketing campaigns for local businesses using unlimited SMS plans.
*Note: Respect carrier limits and anti-spam regulations.*

### 4. IoT & Home Automation
Receive SMS commands to trigger home automation actions or get status updates from IoT devices in areas with poor data coverage but working GSM.

### 5. Development & Testing
Test SMS integrations in your applications during development without incurring costs.

## 🛠️ Setup & Configuration

### Prerequisites
*   Android Device (Android 5.0+) with an active SIM card.
*   A backend server to handle API requests (Node.js, Python, PHP, etc.).

### App Configuration
1.  **Install & Open**: Launch TxtFlow on your Android device.
2.  **Permissions**: Grant SMS and Phone permissions when prompted.
3.  **Settings**:
    *   Tap the **Settings** (gear) icon.
    *   **API URL**: Enter your backend server URL (e.g., `https://api.yourdomain.com`).
    *   **Polling Interval**: Set how often the app checks for new messages (default: 15 min).
    *   **Whitelist**: (Optional) Comma-separated list of allowed phone numbers.
4.  **Start Service**: Tap **Start Service** on the dashboard.

## 🔌 API Contract

Your backend server must implement the following endpoints:

### 1. Health Check
*   **Endpoint**: `GET /health-check`
*   **Expected Response**: `200 OK`
*   **Description**: Used by the app to verify server connectivity.

### 2. Fetch Pending Messages
*   **Endpoint**: `GET /messages`
*   **Description**: The app polls this endpoint to get messages waiting to be sent.
*   **Expected Response**: `200 OK`
    ```json
    [
      {
        "id": "unique_msg_id",
        "address": "+1234567890",
        "body": "Hello from TxtFlow!"
      }
    ]
    ```

### 3. Post Received Message (Webhook)
*   **Endpoint**: `POST /message`
*   **Description**: The app calls this endpoint when a new SMS is received.
*   **Payload**:
    ```json
    {
      "from": "+1987654321",
      "body": "Reply message content",
      "timestamp": 1634567890000
    }
    ```
*   **Expected Response**: `200 OK`

## 📱 Development

### Tech Stack
*   **Framework**: Flutter (Dart)
*   **State Management**: Provider
*   **Background Tasks**: `workmanager`
*   **SMS Handling**: `telephony`, Native Android `MethodChannel`
*   **Storage**: `shared_preferences`

### Build Instructions
1.  Clone the repository.
2.  Install dependencies:
    ```bash
    flutter pub get
    ```
3.  Run on device:
    ```bash
    flutter run
    ```
4.  Build APK:
    ```bash
    flutter build apk --release
    ```

## ⚠️ Limitations & Best Practices

*   **Android Background Restrictions**: Modern Android versions are aggressive about killing background processes. TxtFlow uses `Workmanager` (JobScheduler) which is reliable but has a minimum interval of 15 minutes.
*   **SMS Limits**: Android limits the number of SMS an app can send per hour to prevent spam. For high volume, you may need to root the device or use ADB to increase limits.
*   **Carrier Restrictions**: Personal SIM cards are not meant for A2P (Application-to-Person) traffic. Excessive usage may lead to SIM blocking.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.
