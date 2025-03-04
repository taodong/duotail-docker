const http = require('http');
const { exec } = require('child_process');

const port = 8080;

const requestHandler = (req, res) => {
  if (req.url === '/health') {

    exec('service postfix status', (error, stdout, stderr)  => {
        if (error) {
            res.writeHead(500, { 'Content-Type': 'text/plain' });
            res.end('Error reading health status');
            return;
        }

        if (stdout.includes('running')) {
            res.writeHead(200, { 'Content-Type': 'text/plain' });
            res.end('OK');
        } else {
            res.writeHead(503, { 'Content-Type': 'text/plain' });
            res.end('Service Unavailable');
        }
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