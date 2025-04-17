import { queryData } from '../../connectDB/connectdb';
import { validateToken } from '../../lib/middleware/authMiddleware';

async function handler1(req, res) {
  if(req.method === 'GET') {
    try {
      const query = 'SELECT * FROM PowerSensorValue ORDER BY time DESC LIMIT 10';
      console.log('Executing query:', query); // Log query
      const data = await queryData(query);

      console.log('Query Result:', data);
      res.status(200).json({ data });
    } catch (error) {
      console.error('Error retrieving data:', error.message);
      res.status(500).json({ message: 'Error retrieving data', error: error.message });
    }
  } else {
    res.status(405).json({ message: 'Method Not Allowed' });
  }
}

export default validateToken(handler1);
