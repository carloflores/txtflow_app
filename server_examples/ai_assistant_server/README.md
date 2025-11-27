# AI Assistant Server Example

This is a Node.js Express server that demonstrates an auto-reply "AI Assistant" use case for the TxtFlow SMS Gateway.

## Features
- **Auto-Reply**: Analyzes incoming SMS content and queues an intelligent reply.
- **Keyword Detection**: Responds to "hello" and "help" with specific messages.
- **Message Queue**: Holds replies until the TxtFlow app polls for them.

## API Endpoints

### `POST /message`
Receives incoming SMS from TxtFlow app and triggers the auto-reply logic.
- **Body**: `{"address": "+1234567890", "body": "Hello"}`

### `GET /messages`
Used by TxtFlow app to fetch queued replies.

### `GET /health-check`
Endpoint to verify server status.

### `POST /cron/clean`
Used by TxtFlow app to trigger cleanup tasks.

## Usage
1. Install dependencies: `npm install`
2. Start server: `npm start`
3. Server runs on: `http://localhost:3001`
