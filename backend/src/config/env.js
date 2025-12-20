const path = require('path');
const fs = require('fs');
const EventEmitter = require('events');
const dotenv = require('dotenv');

const DEFAULT_ENV_FILE = path.resolve(process.cwd(), '.env');

class EnvManager extends EventEmitter {
    constructor() {
        super();

        this.envPath = process.env.ENV_FILE ? path.resolve(process.cwd(), process.env.ENV_FILE) : DEFAULT_ENV_FILE;
        this.isWatching = false;

        this.load();
        this.watch();
    }

    load() {
        const result = dotenv.config({ path: this.envPath, override: true });

        if (result.error) {
            if (result.error.code !== 'ENOENT') {
                console.error(`[env] ❌ Failed to load environment file ${this.envPath}: ${result.error.message}`);
            }
        } else {
            console.info(`[env] ✅ Environment variables loaded from ${this.envPath}`);
        }

        this.normalize();
        this.emit('reload', { source: 'load', timestamp: Date.now() });
    }

    normalize() {
        const mockEmailValue = (process.env.MOCK_EMAIL || '').toLowerCase();

        if (mockEmailValue === 'true') {
            console.warn('[env] ⚠️  MOCK_EMAIL=true detected. Forcing real SMTP mode.');
        }

        process.env.MOCK_EMAIL = 'false';
    }

    refresh() {
        this.load();
    }

    watch() {
        if (this.isWatching) {
            return;
        }

        if (!fs.existsSync(this.envPath)) {
            return;
        }

        const interval = parseInt(process.env.ENV_WATCH_INTERVAL_MS || '2000', 10);

        fs.watchFile(this.envPath, { interval }, () => {
            console.info('[env] 🔁 Detected changes in environment file. Reloading...');
            this.load();
        });

        this.isWatching = true;
    }
}

module.exports = new EnvManager();


