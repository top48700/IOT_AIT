const { queryData } = require('../connectDB/connectdb');

const getDataFromDatabase = async (req, res) => {
    try {
        const query = `SELECT * FROM your_measurement_name ORDER BY time DESC LIMIT 10`;
        const data = await queryData(query);

        res.status(200).json({
            success: true,
            message: 'Data fetched successfully',
            data,
        });
    } catch (error) {
        console.error('Error fetching data:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching data',
            error: error.message,
        });
    }
};

module.exports = { getDataFromDatabase };
