const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

app.use(bodyParser.json());

// In-memory store
let messageQueue = [];
let receivedMessages = [];

// 1. Health Check
app.get('/health-check', (req, res) => {
    res.status(200).send('OK');
});

// 2. Fetch list of messages to send (App pools this)
app.get('/messages', (req, res) => {
    const messagesToSend = [...messageQueue];
    messageQueue = []; // Clear queue after fetching (or use a status flag)
    res.json(messagesToSend);
});

// 3. Receive message from App (Reply or Incoming)
app.post('/message', (req, res) => {
    const message = req.body;
    console.log('Received message:', message);
    receivedMessages.push(message);
    res.status(200).send('Message received');
});

// 4. Clean up messages (App pools this)
app.post('/cron/clean', (req, res) => {
    console.log('Cleaning up messages...');
    receivedMessages = []; // Clear logs
    res.status(200).send('Cleaned');
});

// --- Demo Endpoints ---

// Generate OTP (Demo trigger)
app.post('/generate-otp', (req, res) => {
    const { phoneNumber } = req.body;
    if (!phoneNumber) {
        return res.status(400).send('phoneNumber is required');
    }

    const otp = Math.floor(100000 + Math.random() * 900000);
    const message = {
        address: phoneNumber,
        body: `Your OTP is: ${otp}`,
        id: Date.now()
    };

    messageQueue.push(message);
    console.log(`Generated OTP for ${phoneNumber}: ${otp}`);
    res.json({ success: true, otp });
});

app.listen(port, () => {
    console.log(`OTP Server running at http://localhost:${port}`);
});
