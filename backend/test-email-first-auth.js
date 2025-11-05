/**
 * Email-First OTP Authentication Test Script
 * 
 * This interactive script helps you test the email-first OTP authentication flow
 * for all user types (owner, manager, customer, delivery staff).
 */

const readline = require('readline');

const rl = readline.createInterface({
    input: process.stdin,
    output: process.stdout
});

const BASE_URL = 'http://localhost:3000/api/v1/auth';

// ANSI color codes for better readability
const colors = {
    reset: '\x1b[0m',
    bright: '\x1b[1m',
    green: '\x1b[32m',
    blue: '\x1b[34m',
    yellow: '\x1b[33m',
    red: '\x1b[31m',
    cyan: '\x1b[36m'
};

function log(message, color = 'reset') {
    console.log(`${colors[color]}${message}${colors.reset}`);
}

function question(prompt) {
    return new Promise(resolve => rl.question(prompt, resolve));
}

async function makeRequest(endpoint, method, body) {
    try {
        const response = await fetch(`${BASE_URL}${endpoint}`, {
            method,
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(body)
        });

        const data = await response.json();
        return { success: response.ok, status: response.status, data };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

async function testCustomerFlow() {
    log('\n════════════════════════════════════════════════════════', 'cyan');
    log('           CUSTOMER LOGIN/SIGNUP FLOW TEST', 'bright');
    log('════════════════════════════════════════════════════════\n', 'cyan');

    // Step 1: Get email
    const email = await question('Enter customer email: ');

    log('\n📧 Sending OTP to email...', 'blue');
    const sendResult = await makeRequest('/customer/send-otp', 'POST', { email });

    if (!sendResult.success) {
        log(`❌ Failed to send OTP: ${sendResult.error || sendResult.data.message}`, 'red');
        return;
    }

    log('✅ OTP sent successfully!', 'green');
    log(`⏱️  OTP expires in ${sendResult.data.data.expiresIn} seconds`, 'yellow');
    log('\n📬 Check your email (or console in dev mode) for the OTP code\n', 'yellow');

    // Step 2: Get OTP
    const otp = await question('Enter the 6-digit OTP: ');

    log('\n🔐 Verifying OTP...', 'blue');
    const verifyResult = await makeRequest('/customer/verify-otp', 'POST', { email, otp });

    if (!verifyResult.success) {
        log(`❌ OTP verification failed: ${verifyResult.data.message}`, 'red');
        return;
    }

    const { isNewUser, token, sessionToken } = verifyResult.data.data;

    if (isNewUser) {
        // New customer - complete registration
        log('\n🆕 New customer detected! Please complete your profile.', 'yellow');

        const fullName = await question('Enter full name: ');
        const phone = await question('Enter phone number (optional, press Enter to skip): ');

        log('\n💾 Completing registration...', 'blue');
        const registerResult = await makeRequest('/customer/complete-registration', 'POST', {
            sessionToken,
            customerData: {
                fullName,
                ...(phone && { phone })
            }
        });

        if (!registerResult.success) {
            log(`❌ Registration failed: ${registerResult.data.message}`, 'red');
            return;
        }

        log('\n✅ Registration completed successfully!', 'green');
        log('🎉 Welcome to Laundry App!', 'green');
        log('\n🔑 Your JWT Token:', 'cyan');
        log(registerResult.data.data.token, 'yellow');

    } else {
        // Existing customer - login complete
        log('\n✅ Login successful!', 'green');
        log('👋 Welcome back!', 'green');
        log('\n🔑 Your JWT Token:', 'cyan');
        log(token, 'yellow');
        log('\n👤 User Info:', 'cyan');
        console.log(JSON.stringify(verifyResult.data.data.user, null, 2));
    }
}

async function testOwnerFlow() {
    log('\n════════════════════════════════════════════════════════', 'cyan');
    log('           OWNER LOGIN/SIGNUP FLOW TEST', 'bright');
    log('════════════════════════════════════════════════════════\n', 'cyan');

    // Step 1: Get email
    const email = await question('Enter owner email: ');

    log('\n📧 Sending OTP to email...', 'blue');
    const sendResult = await makeRequest('/owner/send-otp', 'POST', { email });

    if (!sendResult.success) {
        log(`❌ Failed to send OTP: ${sendResult.error || sendResult.data.message}`, 'red');
        return;
    }

    log('✅ OTP sent successfully!', 'green');
    log('\n📬 Check your email (or console in dev mode) for the OTP code\n', 'yellow');

    // Step 2: Get OTP
    const otp = await question('Enter the 6-digit OTP: ');

    log('\n🔐 Verifying OTP...', 'blue');
    const verifyResult = await makeRequest('/owner/verify-otp', 'POST', { email, otp });

    if (!verifyResult.success) {
        log(`❌ OTP verification failed: ${verifyResult.data.message}`, 'red');
        return;
    }

    const { isNewUser, token, sessionToken } = verifyResult.data.data;

    if (isNewUser) {
        // New owner - complete mart registration
        log('\n🆕 New mart owner detected! Please register your laundry mart.', 'yellow');

        log('\n📋 Mart Information:', 'cyan');
        const martName = await question('Mart Name: ');
        const martPhone = await question('Mart Phone (optional): ');
        const address = await question('Mart Address: ');
        const latitude = parseFloat(await question('Latitude: '));
        const longitude = parseFloat(await question('Longitude: '));

        log('\n👤 Owner Information:', 'cyan');
        const ownerName = await question('Your Full Name: ');
        const ownerPhone = await question('Your Phone (optional): ');

        log('\n💾 Creating mart and owner account...', 'blue');
        const registerResult = await makeRequest('/owner/complete-registration', 'POST', {
            sessionToken,
            martData: {
                martName,
                ...(martPhone && { contactPhone: martPhone }),
                address,
                latitude,
                longitude,
                serviceRadiusKm: {}
            },
            ownerData: {
                fullName: ownerName,
                ...(ownerPhone && { phone: ownerPhone })
            }
        });

        if (!registerResult.success) {
            log(`❌ Registration failed: ${registerResult.data.message}`, 'red');
            return;
        }

        log('\n✅ Mart and owner account created successfully!', 'green');
        log('🎉 Welcome to Laundry App!', 'green');
        log('\n🔑 Your JWT Token:', 'cyan');
        log(registerResult.data.data.token, 'yellow');

    } else {
        // Existing owner - login complete
        log('\n✅ Login successful!', 'green');
        log('👋 Welcome back!', 'green');
        log('\n🔑 Your JWT Token:', 'cyan');
        log(token, 'yellow');
        log('\n👤 User Info:', 'cyan');
        console.log(JSON.stringify(verifyResult.data.data.user, null, 2));
    }
}

async function testManagerFlow() {
    log('\n════════════════════════════════════════════════════════', 'cyan');
    log('           MANAGER LOGIN/SIGNUP FLOW TEST', 'bright');
    log('════════════════════════════════════════════════════════\n', 'cyan');

    const email = await question('Enter manager email: ');

    log('\n📧 Sending OTP to email...', 'blue');
    const sendResult = await makeRequest('/manager/send-otp', 'POST', { email });

    if (!sendResult.success) {
        log(`❌ Failed to send OTP: ${sendResult.error || sendResult.data.message}`, 'red');
        return;
    }

    log('✅ OTP sent successfully!', 'green');
    log('\n📬 Check your email (or console in dev mode) for the OTP code\n', 'yellow');

    const otp = await question('Enter the 6-digit OTP: ');

    log('\n🔐 Verifying OTP...', 'blue');
    const verifyResult = await makeRequest('/manager/verify-otp', 'POST', { email, otp });

    if (!verifyResult.success) {
        log(`❌ OTP verification failed: ${verifyResult.data.message}`, 'red');
        return;
    }

    const { isNewUser, token, sessionToken } = verifyResult.data.data;

    if (isNewUser) {
        log('\n🆕 New manager detected! Please complete your profile.', 'yellow');

        const martId = await question('Enter Mart ID: ');
        const fullName = await question('Enter full name: ');
        const phone = await question('Enter phone number (optional): ');

        log('\n💾 Completing registration...', 'blue');
        const registerResult = await makeRequest('/manager/complete-registration', 'POST', {
            sessionToken,
            managerData: {
                martId,
                fullName,
                ...(phone && { phone })
            }
        });

        if (!registerResult.success) {
            log(`❌ Registration failed: ${registerResult.data.message}`, 'red');
            return;
        }

        log('\n✅ Registration completed successfully!', 'green');
        log('\n🔑 Your JWT Token:', 'cyan');
        log(registerResult.data.data.token, 'yellow');

    } else {
        log('\n✅ Login successful!', 'green');
        log('\n🔑 Your JWT Token:', 'cyan');
        log(token, 'yellow');
    }
}

async function testDeliveryFlow() {
    log('\n════════════════════════════════════════════════════════', 'cyan');
    log('         DELIVERY STAFF LOGIN/SIGNUP FLOW TEST', 'bright');
    log('════════════════════════════════════════════════════════\n', 'cyan');

    const email = await question('Enter delivery staff email: ');

    log('\n📧 Sending OTP to email...', 'blue');
    const sendResult = await makeRequest('/delivery/send-otp', 'POST', { email });

    if (!sendResult.success) {
        log(`❌ Failed to send OTP: ${sendResult.error || sendResult.data.message}`, 'red');
        return;
    }

    log('✅ OTP sent successfully!', 'green');
    log('\n📬 Check your email (or console in dev mode) for the OTP code\n', 'yellow');

    const otp = await question('Enter the 6-digit OTP: ');

    log('\n🔐 Verifying OTP...', 'blue');
    const verifyResult = await makeRequest('/delivery/verify-otp', 'POST', { email, otp });

    if (!verifyResult.success) {
        log(`❌ OTP verification failed: ${verifyResult.data.message}`, 'red');
        return;
    }

    const { isNewUser, token, sessionToken } = verifyResult.data.data;

    if (isNewUser) {
        log('\n🆕 New delivery staff detected! Please complete your profile.', 'yellow');

        const martId = await question('Enter Mart ID: ');
        const fullName = await question('Enter full name: ');
        const phone = await question('Enter phone number: ');
        const vehicleType = await question('Vehicle type (bike/car/scooter): ');
        const vehicleNumber = await question('Vehicle number: ');
        const licenseNumber = await question('License number: ');

        log('\n💾 Completing registration...', 'blue');
        const registerResult = await makeRequest('/delivery/complete-registration', 'POST', {
            sessionToken,
            deliveryData: {
                martId,
                fullName,
                phone,
                vehicleType,
                vehicleNumber,
                licenseNumber
            }
        });

        if (!registerResult.success) {
            log(`❌ Registration failed: ${registerResult.data.message}`, 'red');
            return;
        }

        log('\n✅ Registration completed successfully!', 'green');
        log('\n🔑 Your JWT Token:', 'cyan');
        log(registerResult.data.data.token, 'yellow');

    } else {
        log('\n✅ Login successful!', 'green');
        log('\n🔑 Your JWT Token:', 'cyan');
        log(token, 'yellow');
    }
}

async function main() {
    log('\n╔═══════════════════════════════════════════════════════╗', 'bright');
    log('║   EMAIL-FIRST OTP AUTHENTICATION TEST SCRIPT         ║', 'bright');
    log('║   Laundry App Backend API                            ║', 'bright');
    log('╚═══════════════════════════════════════════════════════╝\n', 'bright');

    log('📋 This script helps you test the email-first OTP authentication', 'blue');
    log('   for all user types (owner, manager, customer, delivery staff).\n', 'blue');

    log('⚠️  Make sure the backend server is running on http://localhost:3000\n', 'yellow');

    while (true) {
        log('\n╔═══════════════════════════════════════════════════════╗', 'cyan');
        log('║  SELECT USER TYPE TO TEST                            ║', 'cyan');
        log('╚═══════════════════════════════════════════════════════╝', 'cyan');
        log('  1. Customer (login/signup)', 'white');
        log('  2. Owner (login/signup)', 'white');
        log('  3. Manager (login/signup)', 'white');
        log('  4. Delivery Staff (login/signup)', 'white');
        log('  5. Exit\n', 'white');

        const choice = await question('Enter your choice (1-5): ');

        switch (choice.trim()) {
            case '1':
                await testCustomerFlow();
                break;
            case '2':
                await testOwnerFlow();
                break;
            case '3':
                await testManagerFlow();
                break;
            case '4':
                await testDeliveryFlow();
                break;
            case '5':
                log('\n👋 Thank you for testing! Goodbye.\n', 'green');
                rl.close();
                process.exit(0);
            default:
                log('\n❌ Invalid choice. Please enter 1-5.\n', 'red');
        }

        const continueTest = await question('\nPress Enter to continue or "q" to quit: ');
        if (continueTest.toLowerCase() === 'q') {
            log('\n👋 Thank you for testing! Goodbye.\n', 'green');
            rl.close();
            process.exit(0);
        }
    }
}

// Run the script
main().catch(error => {
    log(`\n❌ Error: ${error.message}`, 'red');
    rl.close();
    process.exit(1);
});

