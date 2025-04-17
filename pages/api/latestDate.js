import { queryData } from '../../connectDB/connectdb';

export default async function handler(req, res) {
  if (req.method === 'GET') {
    try {

      const latestDateQuery = `SELECT LAST(measuredAt) AS latestTime FROM PowerSensorValue`;
      const result = await queryData(latestDateQuery);

      console.log('Query result:', result);

      if (result && result.length > 0) {
        const latestDate = result[0].latestTime;
        return res.status(200).json({ latestDate });
      } else {
        return res.status(404).json({ message: 'No data found' });
      }
    } catch (error) {
      console.error('Database Query Error:', error.message);
      res.status(500).json({ error: error.message });
    }
  } else {
    res.status(405).json({ message: 'Method Not Allowed' });
  }
}
