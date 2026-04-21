const { ALLOWED_ORIGINS } = require('./config');

module.exports = {
  origin: function (origin, callback) {
    // Allow requests with no origin (Postman, curl, server-to-server)
    if (!origin) return callback(null, true);
    if (ALLOWED_ORIGINS.includes(origin)) return callback(null, true);
    callback(new Error(`CORS: origin "${origin}" not allowed`));
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Auth-Token'],
  exposedHeaders: ['Content-Type'],
  optionsSuccessStatus: 200,  // some old browsers choke on 204
  maxAge: 3600,               // preflight cache: 1 hour
};