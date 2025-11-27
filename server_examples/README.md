# TxtFlow Server Examples

This directory contains three example Node.js servers demonstrating different use cases for the TxtFlow SMS Gateway.

## Prerequisites
- Node.js installed
- TxtFlow App running on an Android device

## 1. OTP Server (`otp_server`)
**Use Case**: Sending One-Time Passwords.
- **Port**: 3000
- **Run**: `cd otp_server && npm start`
- **Demo**: Send a POST request to `http://localhost:3000/generate-otp` with JSON body `{"phoneNumber": "+1234567890"}`.

## 2. AI Assistant Server (`ai_assistant_server`)
**Use Case**: Auto-replying to incoming messages.
- **Port**: 3001
- **Run**: `cd ai_assistant_server && npm start`
- **Demo**: Send an SMS to the device. The server will reply based on keywords ("hello", "help").

## 3. Marketing Server (`marketing_server`)
**Use Case**: Bulk SMS broadcasting.
- **Port**: 3002
- **Run**: `cd marketing_server && npm start`
- **Demo**: Send a POST request to `http://localhost:3002/broadcast` with JSON body `{"numbers": ["+123...", "+456..."], "message": "Sale started!"}`.

## Connecting the App
1. Ensure your computer and Android device are on the same Wi-Fi network.
2. Find your computer's local IP address (e.g., `192.168.1.5`).
3. Open TxtFlow App -> Settings.
4. Set API URL to `http://<YOUR_IP>:<PORT>` (e.g., `http://192.168.1.5:3000`).
5. Save and Start Service.
