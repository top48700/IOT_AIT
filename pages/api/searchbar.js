import { queryData } from '../../connectDB/connectdb';
import { validateToken } from '../../lib/middleware/authMiddleware';

async function handler1(req, res) {
  if (req.method === 'GET') {
      const { limit, startDate, endDate, startTime, endTime, sensorId } = req.query;

      try {
          let query = `SELECT * FROM PowerSensorValue WHERE 1=1`;

          if (startDate && endDate) {
              query += ` AND time >= '${startDate}T00:00:00Z' AND time <= '${endDate}T23:59:59Z'`;
          } else if (startDate) {
              query += ` AND time >= '${startDate}T00:00:00Z'`;
          } else if (endDate) {
              query += ` AND time <= '${endDate}T23:59:59Z'`;
          }

          if (startTime && endTime) {
              query += ` AND time >= '${startTime}' AND time <= '${endTime}'`;
          } else if (startTime) {
              query += ` AND time >= '${startTime}'`;
          } else if (endTime) {
              query += ` AND time <= '${endTime}'`;
          }

          if (sensorId && sensorId !== 'All') {
              query += ` AND sensorId = '${sensorId}'`;
          }

          query += ` ORDER BY time DESC LIMIT ${limit || 15}`;
          console.log('Executing query:', query);
          const data = await queryData(query);

          res.status(200).json({ data });
      } catch (error) {
          console.error('Database Query Error:', error.message);
          res.status(500).json({ error: error.message });
      }
  } else {
      res.status(405).json({ message: 'Method Not Allowed' });
  }
}

export default validateToken(handler1);