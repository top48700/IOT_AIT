import { queryData } from '../../connectDB/connectdb';
import { validateToken } from '../../lib/middleware/authMiddleware';

async function handler(req, res) {
    if (req.method === 'GET') {
        try {
            const latestTimestampQuery = `
                SELECT LAST(measuredAt) AS latestTime FROM PowerSensorValue`;
            const latestTimeResult = await queryData(latestTimestampQuery);

            if (!latestTimeResult || latestTimeResult.length === 0 || !latestTimeResult[0].latestTime) {
                return res.status(404).json({ error: 'No data found in the database' });
            }

            const latestTime = new Date(latestTimeResult[0].latestTime);
            const year = latestTime.getUTCFullYear();
            const month = latestTime.getUTCMonth();
            const firstDayOfMonth = new Date(Date.UTC(year, month, 1));
            const lastDayOfMonth = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59));
            const { startDate, endDate } = req.query;
            const start = startDate ? new Date(startDate) : firstDayOfMonth;
            const end = endDate ? new Date(endDate) : lastDayOfMonth;


            const firstDayQuery = `
                SELECT FIRST(accumulatedEnergyValue) AS firstValue, sensorId
                FROM PowerSensorValue
                WHERE time >= '${start.toISOString()}' AND time < '${new Date(start.getTime() + 24 * 60 * 60 * 1000).toISOString()}'
                GROUP BY sensorId
            `;
            const firstDayResult = await queryData(firstDayQuery);


            const lastDayQuery = `
                SELECT LAST(accumulatedEnergyValue) AS lastValue, sensorId
                FROM PowerSensorValue
                WHERE time >= '${start.toISOString()}' AND time <= '${end.toISOString()}'
                GROUP BY sensorId
            `;
            const lastDayResult = await queryData(lastDayQuery);


            const totalFirstDayValue = firstDayResult.reduce((sum, entry) => sum + entry.firstValue, 0);
            const totalLastDayValue = lastDayResult.reduce((sum, entry) => sum + entry.lastValue, 0);


            const energyDifference = totalLastDayValue - totalFirstDayValue;


            res.status(200).json({
                latestMonth: `${year}-${month + 1}`,
                firstDayTimestamp: start.toISOString(),
                lastDayTimestamp: end.toISOString(),
                firstDayTotalValue: totalFirstDayValue,
                lastDayTotalValue: totalLastDayValue,
                energyDifference,
                sensorFirstDayValues: firstDayResult.map(entry => ({
                    sensorId: entry.sensorId,
                    value: entry.firstValue
                })),
                sensorLastDayValues: lastDayResult.map(entry => ({
                    sensorId: entry.sensorId,
                    value: entry.lastValue
                }))
            });
        } catch (error) {
            console.error('Error fetching data for latest month:', error.message);
            res.status(500).json({ error: 'Failed to fetch data for the latest month' });
        }
    } else {
        res.status(405).json({ message: 'Method Not Allowed' });
    }
}

export default validateToken(handler);