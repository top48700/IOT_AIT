import { queryData } from '../../../../connectDB/connectdb';
import { validateToken } from '../../../../lib/middleware/authMiddleware';
import axios from 'axios';

async function handler(req, res) {
    if (req.method !== 'GET') {
        return res.status(405).json({ error: "Method not allowed" });
    }

    const range = req.query.range || "day";
    const date = req.query.date;
    let query = "";

    if (date) {
        query = `SELECT sum(powerConsumptionValue) as total FROM PowerSensorValue WHERE time >= '${date}T00:00:00Z' AND time <= '${date}T23:59:59Z' GROUP BY sensorId`;
    } else if (range === "day") {
        query = `SELECT sum(powerConsumptionValue) as total FROM PowerSensorValue WHERE time >= '2024-12-16T00:00:00Z' AND time <= '2024-12-16T23:59:59Z' GROUP BY sensorId`;
    } else if (range === "month") {
        query = "SELECT sum(powerConsumptionValue) as total FROM PowerSensorValue WHERE time >= '2024-11-01T00:00:00Z' AND time <= '2024-11-30T23:59:59Z' GROUP BY sensorId";
    } else if (range === "year") {
        query = "SELECT sum(powerConsumptionValue) as total FROM PowerSensorValue WHERE time > now() - 365d GROUP BY sensorId";
    } else {
        return res.status(400).json({ error: "Invalid range type" });
    }

    try {
        const result = await queryData(query);

        // Sort by sensorId
        result.sort((a, b) => a.sensorId - b.sensorId);

        // Get sensor names from API
        try {
            const apiResponse = await axios.get('https://hciox4.ait.co.th/api/v1/branches', {
                headers: {
                    'Content-Type': 'application/json',
                    Authorization: `Bearer ${req.headers.authorization?.split(' ')[1]}`,
                },
            });

            const branches = apiResponse.data.branches;
            
            // Create a map of sensor IDs to sensor names
            const sensorNameMap = {};
            
            branches.forEach(branch => {
                branch.gateways.forEach(gateway => {
                    gateway.sensors.forEach(sensor => {
                        sensorNameMap[sensor.id] = sensor.name || `Sensor ${sensor.id}`;
                    });
                });
            });

            // Function to generate vibrant colors
            const generateVibrantColors = (num) => {
                // Predefined vibrant color palette
                const vibrantPalette = [
                    '#FF6B6B', // Coral Red
                    '#4ECDC4', // Turquoise 
                    '#FFD166', // Yellow
                    '#06D6A0', // Mint Green
                    '#118AB2', // Blue
                    '#73D2DE', // Sky Blue
                    '#FFA69E', // Salmon
                    '#9381FF', // Purple
                    '#FF8C42', // Orange
                    '#00B4D8', // Aqua
                    '#9EE493', // Light Green
                    '#F25F5C', // Tomato
                    '#50B2C0', // Teal
                    '#FF99C8', // Pink
                    '#A0C4FF', // Baby Blue
                    '#FCBF49', // Amber
                    '#EF476F', // Raspberry
                    '#6A0572', // Violet
                    '#96E072', // Lime
                    '#F7B801'  // Gold
                ];
                
                // If we need more colors than in our palette, we'll generate additional ones
                if (num <= vibrantPalette.length) {
                    return vibrantPalette.slice(0, num);
                } else {
                    // Generate additional colors using HSL with high saturation and lightness
                    const additionalColors = Array.from(
                        { length: num - vibrantPalette.length }, 
                        (_, i) => `hsl(${((i * 137) % 360)}, 85%, 65%)`
                    );
                    return [...vibrantPalette, ...additionalColors];
                }
            };

            const colors = generateVibrantColors(result.length);
            
            // Calculate total for percentages
            const total = result.reduce((sum, point) => sum + point.total, 0);

            const data = result.map((point, index) => ({
                sensor: point.sensorId,
                sensorName: sensorNameMap[point.sensorId] || `Sensor ${point.sensorId}`,
                // Keep raw value with 2 decimal places
                value: parseFloat(point.total.toFixed(2)),
                // Add percentage for pie chart
                percentage: total > 0 ? parseFloat(((point.total / total) * 100).toFixed(2)) : 0,
                color: colors[index],
            }));

            res.status(200).json(data);
        } catch (apiError) {
            // If API call fails, fall back to just using sensor IDs
            console.error("Failed to fetch sensor names:", apiError.message);
            
            // Use the same vibrant color function for the fallback
            const generateVibrantColors = (num) => {
                const vibrantPalette = [
                    '#FF6B6B', '#4ECDC4', '#FFD166', '#06D6A0', '#118AB2', 
                    '#73D2DE', '#FFA69E', '#9381FF', '#FF8C42', '#00B4D8', 
                    '#9EE493', '#F25F5C', '#50B2C0', '#FF99C8', '#A0C4FF', 
                    '#FCBF49', '#EF476F', '#6A0572', '#96E072', '#F7B801'
                ];
                
                if (num <= vibrantPalette.length) {
                    return vibrantPalette.slice(0, num);
                } else {
                    const additionalColors = Array.from(
                        { length: num - vibrantPalette.length }, 
                        (_, i) => `hsl(${((i * 137) % 360)}, 85%, 65%)`
                    );
                    return [...vibrantPalette, ...additionalColors];
                }
            };

            const colors = generateVibrantColors(result.length);
            const total = result.reduce((sum, point) => sum + point.total, 0);

            const data = result.map((point, index) => ({
                sensor: point.sensorId,
                sensorName: `Sensor ${point.sensorId}`,
                value: parseFloat(point.total.toFixed(2)),
                percentage: total > 0 ? parseFloat(((point.total / total) * 100).toFixed(2)) : 0,
                color: colors[index],
            }));

            res.status(200).json(data);
        }
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
}
export default validateToken(handler);


// if (date) {
//     query = `SELECT mean(powerConsumptionValue) FROM PowerSensorValue WHERE time >= '${date}T00:00:00Z' AND time <= '${date}T23:59:59Z' GROUP BY sensorId`;
// } else if (range === "day") {
//     query = `SELECT mean(powerConsumptionValue) FROM PowerSensorValue WHERE time >= now() -1d GROUP BY sensorId`;
// } else if (range === "month") {
//     query = "SELECT mean(powerConsumptionValue) FROM PowerSensorValue WHERE time > now() - 30d GROUP BY sensorId";
// } else if (range === "year") {
//     query = "SELECT mean(powerConsumptionValue) FROM PowerSensorValue WHERE time > now() - 365d GROUP BY sensorId";
// } else {
//     return res.status(400).json({ error: "Invalid range type" });
// }


// if (date) {
//     query = `SELECT sum(powerConsumptionValue) as total FROM PowerSensorValue WHERE time >= '${date}T00:00:00Z' AND time <= '${date}T23:59:59Z' GROUP BY sensorId`;
// } else if (range === "day") {
//     query = `SELECT sum(powerConsumptionValue) as total FROM PowerSensorValue WHERE time >= '2024-12-16T00:00:00Z' AND time <= '2024-12-16T23:59:59Z' GROUP BY sensorId`;
// } else if (range === "month") {
//     query = "SELECT sum(powerConsumptionValue) as total FROM PowerSensorValue WHERE time >= '2024-11-01T00:00:00Z' AND time <= '2024-11-30T23:59:59Z' GROUP BY sensorId";
// } else if (range === "year") {
//     query = "SELECT sum(powerConsumptionValue) as total FROM PowerSensorValue WHERE time > now() - 365d GROUP BY sensorId";
// } else {
//     return res.status(400).json({ error: "Invalid range type" });
// }