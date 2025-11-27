const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3002;

app.use(bodyParser.json());

let messageQueue = [];

// 1. Health Check
app.get('/health-check', (req, res) => {
    console.log('Health checking')
    res.status(200).send('OK');
});

// 2. Fetch list of messages to send (App pools this)
app.get('/messages', (req, res) => {
    const messagesToSend = [...messageQueue];
    // messageQueue = [];
    res.json(messagesToSend);
});

// 3. Receive message from App (Delivery reports or replies)
app.post('/message', (req, res) => {
    console.log('Received message/report:', req.body);
    messageQueue.push(req.body);
    res.status(200).send('Received');
});

// 4. Clean up
app.post('/cron/clean', (req, res) => {
    console.log('Cleaning up...');
    res.status(200).send('Cleaned');
});

// --- Demo Endpoints ---

// Broadcast Message
app.post('/broadcast', (req, res) => {
    const { numbers, message } = req.body;
    if (!numbers || !Array.isArray(numbers) || !message) {
        return res.status(400).send('Invalid request. Expecting { numbers: [], message: "" }');
    }

    numbers.forEach(number => {
        messageQueue.push({
            address: number,
            body: message,
            id: Date.now() + Math.random()
        });
    });

    console.log(`Queued ${numbers.length} messages for broadcast.`);
    res.json({ success: true, queued: numbers.length });
});

app.listen(port, () => {
    console.log(`Marketing Server running at http://localhost:${port}`);
});
