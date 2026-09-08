// Set required env before any module that reads config is imported.
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-for-vitest';
process.env.NODE_ENV = 'test';
