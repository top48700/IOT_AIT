import axios from 'axios';
import { queryData } from "../../connectDB/connectdb";
import { validateToken } from '../../lib/middleware/authMiddleware';

async function handler(req, res) {
    if (req.method !== "GET") {
        return res.status(405).json({ message: "Method Not Allowed" });
    }

    try {
        const valueQuery = `
            SELECT LAST(powerFactorValue) AS lastValue, sensorId
            FROM PowerSensorValue
            GROUP BY sensorId
        `;
        const valueResult = await queryData(valueQuery);

        const timeQuery = `
            SELECT LAST(measuredAt) AS lastTime, sensorId
            FROM PowerSensorValue
            GROUP BY sensorId
        `;
        const timeResult = await queryData(timeQuery);

        if (!valueResult.length || !timeResult.length) {
            return res.status(404).json({ message: "No sensor data found" });
        }

        const apiResponse = await axios.get('https://hciox4.ait.co.th/api/v1/branches', {
            headers: {
                'Content-Type': 'application/json',
                Authorization: `Bearer ${req.token}`,
            },
        });

        const branches = apiResponse.data.branches;

        const now = new Date();
        const sensors = valueResult.map((row, index) => {
            const timeRow = timeResult[index];
            const lastTime = new Date(timeRow.lastTime);
            const diffMinutes = (now - lastTime) / 60000;

            let status = "Offline";
            if (diffMinutes <= 5) status = "Online";
            else if (diffMinutes <= 15) status = "Warning";

            let branchData = null;
            let gatewayData = null;
            let sensorData = null;
            let location = "Unknown";

            for (const branch of branches) {
                for (const gateway of branch.gateways) {
                    const sensor = gateway.sensors.find(s => Number(s.id) === Number(row.sensorId));
                    if (sensor) {
                        branchData = branch;
                        gatewayData = gateway;
                        sensorData = sensor;
                        console.log("Raw sensor location:", sensorData?.location);
                        try {
                            if (sensorData?.location && sensorData.location.trim() !== "") {
                                const parsedLocation = JSON.parse(sensorData.location);
                                location = parsedLocation.address && parsedLocation.address.trim() !== ""
                                    ? parsedLocation.address
                                    : "Unknown";
                            } else {
                                location = "Unknown";
                            }
                        } catch (error) {
                            console.error("Error parsing location JSON for sensor ID", sensorData?.id, ":", error);
                            location = "Unknown";
                        }

                        console.log("Final Location:", location);


                        break;
                    }
                }
                if (branchData) break;
            }

            if (!sensorData) {
                console.warn("Sensor ID not found:", row.sensorId);
            }

            return {
                id: row.sensorId,
                lastValue: row.lastValue,
                lastUpdate: lastTime.toISOString(),
                status,
                branchId: branchData?.branchId || 'N/A',
                tenantId: branchData?.tenantId || 'N/A',
                gatewayId: gatewayData?.id || 'N/A',
                createdAt: sensorData?.createdAt || 'N/A',
                createdBy: sensorData?.createdBy || 'N/A',
                sensorName: sensorData?.name || 'Unknown Sensor',

                branchCreatedBy: branchData?.createdBy || 'N/A',
                gatewayName: gatewayData?.name || 'N/A',
                sensorType: sensorData?.type || 'Unknown Type',
                minValue: sensorData?.minValue || 'N/A',
                maxValue: sensorData?.maxValue || 'N/A',
                timeZone: sensorData?.timeZone || 'N/A',
                updatedBy: sensorData?.updatedBy || 'N/A',
                disabledStatus: sensorData?.disabled || false,
                // deviceState: sensorData?.deviceState?.state || 'Unknown',

                location: location
                
            };
        });

        return res.status(200).json(sensors);
    } catch (error) {
        console.error("Error:", error.message);
        return res.status(500).json({ error: "Failed to fetch data" });
    }
}

export default validateToken(handler);
