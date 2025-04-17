import { queryData } from '../../connectDB/connectdb';
import { validateToken } from '../../lib/middleware/authMiddleware';

async function handler(req, res) {
  if (req.method === 'GET') {
    try {
      const query = 'SHOW TAG VALUES FROM "PowerSensorValue" WITH KEY = "sensorId"';
      console.log('Executing query:', query);

      const data = await queryData(query);

      const sensorIds = data
        .map(record => parseInt(record.sensorId || record.value, 10)) 
        .filter(sensorId => !isNaN(sensorId)) 
        .sort((a, b) => a - b); 

      console.log('Sorted Sensor IDs:', sensorIds);

      res.status(200).json({ sensors: sensorIds });
    } catch (error) {
      console.error('Error retrieving sensor IDs:', error.message);
      res.status(500).json({ message: 'Error retrieving sensor IDs', error: error.message });
    }
  } else {
    res.status(405).json({ message: 'Method Not Allowed' });
  }
}

export default validateToken(handler);
