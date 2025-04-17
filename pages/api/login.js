import axios from 'axios';

export default async function handler(req, res) {
    if (req.method === 'POST') {
        const { username, password } = req.body;

        try {
            const response = await axios.post(
                'https://hciox4.ait.co.th/api/User/Login',
                { username, password },
                { headers: { 'Content-Type': 'application/json' } }
            );

            const { access_token, refresh_token } = response.data;

            if (!access_token || !refresh_token) {
                return res.status(500).json({ error: 'Tokens not generated' });
            }

            console.log('API Response:', response.data);

            res.status(200).json({ access_token, refresh_token });
        } catch (error) {
            console.error('API Error:', error.response?.data || error.message);

            res.status(error.response?.status || 500).json({
                error: error.response?.data?.message || 'Internal Server Error',
            });
        }
    } else {
        res.setHeader('Allow', ['POST']);
        res.status(405).end(`Method ${req.method} Not Allowed`);
    }
}
