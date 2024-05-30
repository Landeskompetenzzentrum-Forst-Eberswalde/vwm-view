// https://docs.github.com/en/actions/using-containerized-services/creating-postgresql-service-containers#testing-the-postgresql-service-container

const { Client } = require('pg');
const result = require('dotenv').config({ path: `_.env` })
const request = require('sync-request')

try {
    const res = request('GET', 'http://localhost:3000/');
    if(res.statusCode !== 200)
        throw 'http://localhost:3000/ not running!'
} catch (e) {
    throw e
}


// http://localhost:3000/my_schemata
try {
    const res = request('GET', 'http://localhost:3000/my_schemata');
    if(res.statusCode !== 200)
        throw 'function http://localhost:3000/my_schemata does not exist!'
} catch (e) {
    throw e
}

console.log('PW:', process.env.POSTGRES_HOST);
console.log('PW:', process.env.POSTGRES_PORT);
console.log('PW:', process.env.POSTGRES_USER);
console.log('PW:', process.env.POSTGRES_PASSWORD);

const pgclient = new Client({
    host: process.env.POSTGRES_HOST || 'localhost',
    port: process.env.POSTGRES_PORT || "5432",
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    database: 'postgres'
});

pgclient.connect();

const table = 'CREATE TABLE student(id SERIAL PRIMARY KEY, firstName VARCHAR(40) NOT NULL, lastName VARCHAR(40) NOT NULL, age INT, address VARCHAR(80), email VARCHAR(40))'
const text = 'INSERT INTO student(firstname, lastname, age, address, email) VALUES($1, $2, $3, $4, $5) RETURNING *'
const values = ['Mona the', 'Octocat', 9, '88 Colin P Kelly Jr St, San Francisco, CA 94107, United States', 'octocat@github.com']

pgclient.query(table, (err, res) => {
    if (err) throw err
});

pgclient.query(text, values, (err, res) => {
    if (err) throw err
});

pgclient.query('SELECT * FROM student', (err, res) => {
    if (err) throw err
    console.log(err, res.rows) // Print the data in student table
    pgclient.end()
});