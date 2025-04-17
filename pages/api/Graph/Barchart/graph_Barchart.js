import { queryData } from '../../../../connectDB/connectdb';
import { validateToken } from '../../../../lib/middleware/authMiddleware';

async function handler(req, res) {
    if (req.method === 'GET') {
        try {
            const getMonthDateRange = (offset) => {
                const now = new Date();
                const targetDate = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - offset, 1));
                const year = targetDate.getUTCFullYear();
                const month = targetDate.getUTCMonth(); // 0-indexed
                const firstDay = new Date(Date.UTC(year, month, 1)).toISOString();
                const lastDay = new Date(Date.UTC(year, month + 1, 0, 23, 59, 59)).toISOString();
                return { year, month: month + 1, firstDay, lastDay };
            };

            const months = 12;  
            let results = [];

            for (let offset = 0; offset < months; offset++) {
                const { year, month, firstDay, lastDay } = getMonthDateRange(offset);

                const firstDayMaxQuery = `
                    SELECT MAX(accumulatedEnergyValue) AS maxFirstDayValue, sensorId
                    FROM PowerSensorValue
                    WHERE time >= '${firstDay}' 
                    AND time < '${new Date(Date.UTC(year, month - 1, 2)).toISOString()}'
                    GROUP BY sensorId
                `;
                const firstDayMaxResult = await queryData(firstDayMaxQuery);

                const lastDayMaxQuery = `
                    SELECT MAX(accumulatedEnergyValue) AS maxLastDayValue, sensorId
                    FROM PowerSensorValue
                    WHERE time >= '${new Date(Date.UTC(year, month - 1, new Date(firstDay).getUTCDate() - 1)).toISOString()}' 
                    AND time <= '${lastDay}'
                    GROUP BY sensorId
                `;
                const lastDayMaxResult = await queryData(lastDayMaxQuery);

                const totalMaxFirstDay = firstDayMaxResult.reduce((sum, entry) => sum + entry.maxFirstDayValue, 0);
                const totalMaxLastDay = lastDayMaxResult.reduce((sum, entry) => sum + entry.maxLastDayValue, 0);

                // ถ้าค่าใดค่าหนึ่ง <= 0 ให้ energyDifference เป็น 0
                const energyDifference =
                    totalMaxFirstDay <= 0 || totalMaxLastDay <= 0 ? 0 : totalMaxLastDay - totalMaxFirstDay;

                results.push({
                    monthOffset: offset,
                    targetMonth: `${year}-${month}`,
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
            }

            res.status(200).json({ data: results });
        } catch (error) {
            console.error('Error fetching monthly data:', error.message);
            res.status(500).json({ error: 'Failed to fetch monthly data' });
        }
    } else {
        res.status(405).json({ message: 'Method Not Allowed' });
    }
}

export default validateToken(handler);
