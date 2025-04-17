export function validateToken(handler) {
    return async (req, res) => {
      const authHeader = req.headers.authorization;
      
      if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'No token provided' });
      }
  
      const token = authHeader.split(' ')[1];
      
      if (!token) {
        return res.status(401).json({ error: 'Invalid token format' });
      }
  
      // Add the token to the request object for use in the handler
      req.token = token;
      
      // Call the original handler
      return handler(req, res);
    };
  }