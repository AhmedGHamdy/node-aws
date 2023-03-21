const express = require('express');
/* const mysql = require('mysql');

// Create a connection to the database
const connection = mysql.createConnection({
host: 'localhost',
  user: 'your_username',
  password: 'your_password',
database: 'your_database'
});

// Connect to the database
connection.connect();
 */
// Create an Express app
const app = express();

// Define a route that displays "Hello, world!"
app.get('/', (req, res) => {
  res.send('Hello, world!');
});

// Start the server
app.listen(80, () => {
  console.log('Server listening on port 80');
});
