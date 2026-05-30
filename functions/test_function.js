const https = require('https');
const data = JSON.stringify({ data: {
  locationId: "test",
  locationName: "test",
  vehicleMake: "test",
  vehiclePlate: "test",
  startDateTime: new Date().toISOString(),
  endDateTime: new Date(Date.now() + 3600000).toISOString()
} });

const options = {
  hostname: 'us-central1-mymove-cb624.cloudfunctions.net',
  port: 443,
  path: '/createBooking',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': data.length
  }
};

const req = https.request(options, res => {
  console.log(`statusCode: ${res.statusCode}`);
  res.on('data', d => {
    process.stdout.write(d);
  });
});

req.on('error', error => {
  console.error(error);
});

req.write(data);
req.end();
