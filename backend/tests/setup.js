// Jest setup file
// Add global test setup here

import { config } from 'dotenv'

// Load test environment variables
config({ path: '.env.test' })

// Global test timeout
jest.setTimeout(10000)

// Mock console methods in tests to reduce noise
global.console = {
    ...console,
    error: jest.fn(),
    warn: jest.fn(),
    log: jest.fn(),
    info: jest.fn(),
    debug: jest.fn(),
}

