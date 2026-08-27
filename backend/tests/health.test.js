const request = require('supertest');
const app = require('../src/app');

describe('GET /health', () => {
    it('returns 200 and status ok', async () => {
        const res = await request(app).get('/health').expect(200);
        expect(res.body).toMatchObject({ status: 'ok' });
        expect(res.body).toHaveProperty('timestamp');
        expect(res.body).toHaveProperty('environment');
    });
});

describe('GET /api/v1', () => {
    it('returns API metadata', async () => {
        const res = await request(app).get('/api/v1').expect(200);
        expect(res.body).toMatchObject({
            name: 'Laundry App API',
            version: '1.0.0',
        });
        expect(res.body.endpoints).toBeDefined();
    });
});
