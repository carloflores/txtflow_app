const express = require('express');
const bodyParser = require('body-parser');

const app = express();
const port = 3001;

app.use(bodyParser.json());

let messageQueue = [];

// 1. Health Check
app.get('/health-check', (req, res) => {
    res.status(200).send('OK');
});

// 2. Fetch list of messages to send (App pools this)
app.get('/messages', (req, res) => {
    const messagesToSend = [...messageQueue];
    messageQueue = [];
    res.json(messagesToSend);
});

// 3. Receive message from App and Auto-Reply
app.post('/message', (req, res) => {
    const { address, body } = req.body;
    console.log(`Received from ${address}: ${body}`);

    // Mock AI Logic
    let reply = `I am an AI. You said: "${body}"`;
    if (body.toLowerCase().includes('hello')) {
        reply = "Hello! How can I help you today?";
    } else if (body.toLowerCase().includes('help')) {
        reply = "I can assist you with general queries. Just ask!";
    }

    // Queue reply
    messageQueue.push({
        address: address,
        body: reply,
        id: Date.now()
    });

    res.status(200).send('Message processed');
});

// 4. Clean up
app.post('/cron/clean', (req, res) => {
    console.log('Cleaning up...');
    res.status(200).send('Cleaned');
});

app.listen(port, () => {
    console.log(`AI Assistant Server running at http://localhost:${port}`);
});
