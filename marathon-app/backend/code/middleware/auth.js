const { accessTokenVerifier } = require('../aws/cognito');

async function requireAuth(req, res, next) {
  const [scheme, token] = (req.headers.authorization ?? "").split(" ");
  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({ error: "missing token" });
  }
  try {
    req.user = await accessTokenVerifier.verify(token);   // payload: sub, username, exp...
    req.accessToken = token;
    next();
  } catch {
    res.status(401).json({ error: "invalid or expired token" });
  }
}

module.exports = { requireAuth };
