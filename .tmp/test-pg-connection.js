// Test PostgreSQL connection directly
const { Client } = require('pg');

const client = new Client({
    host: 'localhost',
    port: 5432,
    database: 'laundry_db',
    user: 'ranith',
    password: 'ranith',
});

console.log('Attempting to connect...');
console.log('Connection config:', {
    host: client.host,
    port: client.port,
    database: client.database,
    user: client.user,
    password: '***'
});

client.connect()
    .then(() => {
        console.log('✅ Connected successfully!');
        return client.query('SELECT current_user, current_database(), version()');
    })
    .then((result) => {
        console.log('✅ Query result:', result.rows[0]);
        client.end();
    })
    .catch((err) => {
        console.error('❌ Connection failed:');
        console.error('Error code:', err.code);
        console.error('Error message:', err.message);
        console.error('Full error:', err);
        process.exit(1);
    });

