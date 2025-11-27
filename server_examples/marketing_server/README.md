# Marketing Server Example

This is a Node.js Express server that demonstrates a Bulk SMS Marketing use case for the TxtFlow SMS Gateway.

## Features
- **Bulk Broadcast**: Queues the same message for multiple recipients.
- **Message Queue**: Holds messages until the TxtFlow app polls for them.

## API Endpoints

### `POST /broadcast`
Queues a message for multiple phone numbers.
- **Body**: 
  ```json
  {
    "numbers": ["+1234567890", "+0987654321"],
    "message": "Special Sale! 50% off today."
  }
  ```

### `GET /messages`
Used by TxtFlow app to fetch pending broadcast messages.

### `POST /message`
Receives delivery reports or replies from TxtFlow app.

### `GET /health-check`
Endpoint to verify server status.

### `POST /cron/clean`
Used by TxtFlow app to trigger cleanup tasks.

## Usage
1. Install dependencies: `npm install`
2. Start server: `npm start`
3. Server runs on: `http://localhost:3002`
