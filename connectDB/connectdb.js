const Influx = require('influx');

const influx = new Influx.InfluxDB({
    host: 'hciox4.ait.co.th',
    port: 59004,
    username: 'admin',
    password: 'dtSDD@a1t2025',
    database: 'iox2024',
});

const checkConnection = async () => {
    try {
        const databases = await influx.getDatabaseNames();
        if (!databases.includes('iox2024')) {
            console.error('Database iox2024 not found on the server');
        } else {
            console.log('Successfully connected to InfluxDB');
        }
    } catch (error) {
        console.error('Error connecting to InfluxDB:', error);
    }
};

const writeData = async (measurement, fields, tags = {}) => {
    try {
        await influx.writePoints([
            {
                measurement,
                fields,
                tags,
            },
        ]);
        console.log('Data written to InfluxDB successfully');
    } catch (error) {
        console.error('Error writing data:', error);
    }
};

const queryData = async (query) => {
    try {
        console.log('Executing query:', query);
        const result = await influx.query(query);
        console.log('Query result:', result);

        return result.map((entry) => {
            return { ...entry }; 
        });
    } catch (error) {
        console.error('Error executing query:', error.message);
        return [];
    }
};

// Export functions for use in other files
module.exports = {
    checkConnection,
    writeData,
    queryData,
};
