import { queryData } from '../../../connectDB/connectdb';
import { validateToken } from '../../../lib/middleware/authMiddleware';

async function handler(req, res) {
    if (req.method === 'GET') {
        try {
            const { sensorId } = req.query;

            const latestTimeQuery = `
                SELECT * FROM PowerSensorValue ORDER BY time DESC LIMIT 1
            `;
            const latestTimeResult = await queryData(latestTimeQuery);
            
            if (!latestTimeResult.length) {
                return res.status(404).json({ error: 'No data found' });
            }

            const latestTime = new Date(latestTimeResult[0].time);
            const latestDate = latestTime.toISOString().split('T')[0];

            let hourlyDataQuery = `
                SELECT 
                    mean("powerConsumptionValue") AS powerConsumption,
                    mean("powerFactorValue") AS powerFactor,
                    mean("reactivePowerValue") AS reactivePower
                FROM PowerSensorValue 
                WHERE time >= '${latestDate}T00:00:00Z' AND time < '${latestDate}T23:59:59Z'
                GROUP BY time(1h), sensorId
                ORDER BY time ASC
            `;

            if (sensorId && sensorId !== 'All') {
                hourlyDataQuery = `
                    SELECT 
                        mean("powerConsumptionValue") AS powerConsumption,
                        mean("powerFactorValue") AS powerFactor,
                        mean("reactivePowerValue") AS reactivePower
                    FROM PowerSensorValue 
                    WHERE sensorId = '${sensorId}' 
                    AND time >= '${latestDate}T00:00:00Z' AND time < '${latestDate}T23:59:59Z'
                    GROUP BY time(1h)
                    ORDER BY time ASC
                `;
            }

            const result = await queryData(hourlyDataQuery);

            if (!result.length) {
                return res.status(404).json({ error: 'No data found for latest date' });
            }

            const data = result.map(row => ({
                hour: row.time,
                sensorId: row.sensorId || sensorId,
                powerConsumption: row.powerConsumption || 0,
                powerFactor: row.powerFactor || 0,
                reactivePower: row.reactivePower || 0
            }));

            res.status(200).json({ data });
        } catch (error) {
            console.error('Error fetching hourly power usage data:', error.message);
            res.status(500).json({ error: 'Internal server error' });
        }
    } else {
        res.status(405).json({ message: 'Method Not Allowed' });
    }
}

export default validateToken(handler);