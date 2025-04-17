import axios from 'axios';
import { validateToken } from '../../../lib/middleware/authMiddleware';

async function dbHandler(req, res) {
  if (req.method === 'GET') {
    try {
      const response = await axios.get('https://hciox4.ait.co.th/api/v1/iotonix/tenants', {
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${req.token}`, // Use the token from the middleware
        },
      });

      // Return the branches data
      res.status(200).json(response.data);
    } catch (error) {
      console.error('API Error:', error.response?.data || error.message);

      res.status(error.response?.status || 500).json({
        error: error.response?.data?.message || 'Internal Server Error',
      });
    }
  } else {
    // Handle unsupported HTTP methods
    res.setHeader('Allow', ['GET']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}

export default validateToken(dbHandler);

