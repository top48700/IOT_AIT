// const axios = require('axios');
// const authConfig = {
//     endpoint: 'https://hciox4.ait.co.th/api/User/Login',
//     username: 'root',
//     password: 'dtSDD@a1t2024',
// };

// const authenticate = async () => {
//     try {
//         const response = await axios.post(authConfig.endpoint, {
//             username: authConfig.username,
//             password: authConfig.password,
//         }, {
//             headers: {
//                 'Content-Type': 'application/json',
//             },
//         });

//         console.log('Authentication successful:', response.data);
//         return response.data;
//     } catch (error) {
//         console.error('Error during authentication:', error.response?.data || error.message);
//         throw error;
//     }
// };

// module.exports = { authenticate };
