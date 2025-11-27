# OTP Server Example

This is a simple Node.js Express server that demonstrates an OTP (One-Time Password) use case for the TxtFlow SMS Gateway.

## Features
- **Generate OTP**: Creates a random 6-digit OTP and queues it for sending.
- **Message Queue**: Holds messages until the TxtFlow app polls for them.
- **Health Check**: Endpoint to verify server status.

## API Endpoints

### `POST /generate-otp`
Triggers an OTP SMS.
- **Body**: `{"phoneNumber": "+1234567890"}`
- **Response**: `{"success": true, "otp": 123456}`

### `GET /messages`
Used by TxtFlow app to fetch pending messages.

### `POST /message`
Receives incoming messages or delivery reports from TxtFlow app.

### `POST /cron/clean`
Used by TxtFlow app to trigger cleanup tasks.

## Usage
1. Install dependencies: `npm install`
2. Start server: `npm start`
3. Server runs on: `http://localhost:3000`
