import axios from 'axios';

export default async function handler(req, res) {
  if (req.method === 'POST') {
    const { refresh_token } = req.body;

    try {
      const response = await axios.post('https://hciox4.ait.co.th/api/User/RefreshToken', {
        refresh_token,
      });

      res.status(200).json({
        access_token: response.data.access_token,
      });
    } catch (error) {
      res.status(error.response?.status || 500).json({
        error: error.response?.data || 'Failed to refresh token',
      });
    }
  } else {
    res.setHeader('Allow', ['POST']);
    res.status(405).end(`Method ${req.method} Not Allowed`);
  }
}
