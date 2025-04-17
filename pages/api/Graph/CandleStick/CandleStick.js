import { queryData } from '../../../../connectDB/connectdb';
import { validateToken } from '../../../../lib/middleware/authMiddleware';

async function handler(req, res) {
    try {
        const query = `
            SELECT sum(powerConsumptionValue) AS value, time
            FROM PowerSensorValue
            WHERE time >= now() - 95d
            GROUP BY time(1d) FILL(none)
            ORDER BY time ASC
        `;

        const rawData = await queryData(query);
        console.log("Total raw data points:", rawData.length);

        const costPerUnit = 4.2;
        const dailyUsageData = rawData.map(item => ({
            date: new Date(item.time).toISOString().split('T')[0], // YYYY-MM-DD
            value: Math.round(item.value / 1000), // Convert to MegaWatt and round to integer
        }));
        
        const ohlcData = [];
        for (let i = 1; i < dailyUsageData.length; i++) {
            const prevUsage = dailyUsageData[i - 1];
            const currUsage = dailyUsageData[i];
        
            const usagePrev1 = Math.round(prevUsage.value); // Round to integer
            const usageCurr = Math.round(currUsage.value); // Round to integer
            const usageDiff = usageCurr - usagePrev1;
        
            const open = usagePrev1;
            const close = usageCurr;
            const high = Math.max(open, close);
            const low = Math.min(open, close);
            let xValue = Math.round(usageCurr - usageDiff); // Round to integer
        
            let changeType = usageDiff < 0 ? "decrease" : usageDiff > 0 ? "increase" : "nochange";
        
            ohlcData.push({
                date: new Date(currUsage.date).toISOString(),
                open: Math.round(open), // Ensure integer values
                high: Math.round(high),
                low: Math.round(low),
                close: Math.round(close),
                usagePrev1: Math.round(usagePrev1),
                usageCurr: Math.round(usageCurr),
                usageDiff: Math.round(usageDiff),
                xValue: Math.round(xValue),
                changeType
            });
        }
        
        res.status(200).json({ data: ohlcData });
    } catch (error) {
        console.error(error);
        res.status(500).json({ error: 'Error fetching data' });
    }
}
export default validateToken(handler);