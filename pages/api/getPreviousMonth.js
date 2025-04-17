import { queryData } from '../../connectDB/connectdb';
import { validateToken } from '../../lib/middleware/authMiddleware';

async function handler(req, res) {
    if (req.method === 'GET') {
        try {
            // Function to calculate the first and last days of a given month offset
            const getMonthDateRange = (offset) => {
                const now = new Date();
                const targetDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - offset, 1));
                const year = targetDate.getUTCFullYear();
                const month = targetDate.getUTCMonth(); // 0-indexed
                const firstDay = new Date(Date.UTC(year, month, 1)).toISOString();
                const lastDay = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59)).toISOString();
                return { year, month: month + 1, firstDay, lastDay }; // Return human-readable month (1-indexed)
            };

            // Parse the month offset from the query string (default: -1)
            const offset = parseInt(req.query.offset || '-1', 10);

            // Get date range for the specified month offset
            const { year, month, firstDay, lastDay } = getMonthDateRange(offset);

            // Step 1: Query the max accumulatedEnergyValue for each sensorId on the first day
            const firstDayMaxQuery = `
                SELECT MAX(accumulatedEnergyValue) AS maxFirstDayValue, sensorId
                FROM PowerSensorValue
                WHERE time >= '${firstDay}' AND time < '${new Date(Date.UTC(year, month - 1, 2)).toISOString()}'
                GROUP BY sensorId
            `;
            const firstDayMaxResult = await queryData(firstDayMaxQuery);

            // Step 2: Query the max accumulatedEnergyValue for each sensorId on the last day
            const lastDayMaxQuery = `
                SELECT MAX(accumulatedEnergyValue) AS maxLastDayValue, sensorId
                FROM PowerSensorValue
                WHERE time >= '${new Date(Date.UTC(year, month - 1, new Date(firstDay).getUTCDate() - 1)).toISOString()}' 
                AND time <= '${lastDay}'
                GROUP BY sensorId
            `;
            const lastDayMaxResult = await queryData(lastDayMaxQuery);

            // Calculate total max values
            const totalMaxFirstDay = firstDayMaxResult.reduce((sum, entry) => sum + entry.maxFirstDayValue, 0);
            const totalMaxLastDay = lastDayMaxResult.reduce((sum, entry) => sum + entry.maxLastDayValue, 0);

            // Calculate the energy difference
            const energyDifference = totalMaxLastDay - totalMaxFirstDay;

            // Step 3: Return the results
            res.status(200).json({
                monthOffset: offset,
                targetMonth: `${year}-${month}`, // Human-readable month
                firstDayTotalMaxValue: totalMaxFirstDay,
                lastDayTotalMaxValue: totalMaxLastDay,
                energyDifference,
                sensorFirstDayMaxValues: firstDayMaxResult.map(entry => ({
                    sensorId: entry.sensorId,
                    maxValue: entry.maxFirstDayValue
                })),
                sensorLastDayMaxValues: lastDayMaxResult.map(entry => ({
                    sensorId: entry.sensorId,
                    maxValue: entry.maxLastDayValue
                }))
            });
        } catch (error) {
            console.error('Error fetching monthly data:', error.message);
            res.status(500).json({ error: 'Failed to fetch monthly data' });
        }
    } else {
        res.status(405).json({ message: 'Method Not Allowed' });
    }
}

export default validateToken(handler);