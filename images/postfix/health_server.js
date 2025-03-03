const http = require('http');
const fs = require('fs');
const { exec } = require('child_process');

const port = 8080;

const requestHandler = (req, res) => {
  if (req.url === '/health') {

    exec('/bin/bash /healthcheck.sh', (error, stdout, stderr)  => {
        if (error) {
            console.error(`exec error: ${error}`);
            return res.status(500).send('Health check failed');
        }

        fs.readFile('/var/log/haraka/health_status', 'utf8', (err, data) => {
          if (err) {
            res.writeHead(500, { 'Content-Type': 'text/plain' });
            res.end('Error reading health status');
            return;
          }
          if (data.trim() === '0') {
            res.writeHead(200, { 'Content-Type': 'text/plain' });
            res.end('OK');
          } else {
            res.writeHead(503, { 'Content-Type': 'text/plain' });
            res.end('Service Unavailable');
          }
        });
    });

  } else {
    res.writeHead(404, { 'Content-Type': 'text/plain' });
    res.end('Not Found');
  }
};

const server = http.createServer(requestHandler);

server.listen(port, (err) => {
  if (err) {
    return console.log('Error starting server:', err);
  }
  console.log(`Server is listening on ${port}`);
});