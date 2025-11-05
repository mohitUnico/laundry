/**
 * Email Service
 * Handles sending emails for OTP verification and notifications
 */

const nodemailer = require('nodemailer');
const logger = require('../utils/logger');

class EmailService {
    constructor() {
        // Initialize email transporter
        this.transporter = this._createTransporter();
    }

    /**
     * Create email transporter based on SMTP configuration
     * If SMTP credentials are provided, real emails will be sent
     * Otherwise, OTPs will be logged to console (development mode)
     * @private
     */
    _createTransporter() {
        // Check if SMTP credentials are configured
        if (process.env.SMTP_HOST && process.env.SMTP_USER && process.env.SMTP_PASSWORD) {
            logger.info('📧 Email service initialized with SMTP (real email sending enabled)');
            logger.info(`   SMTP Host: ${process.env.SMTP_HOST}`);
            logger.info(`   SMTP User: ${process.env.SMTP_USER}`);

            return nodemailer.createTransport({
                host: process.env.SMTP_HOST,
                port: parseInt(process.env.SMTP_PORT) || 587,
                secure: process.env.SMTP_SECURE === 'true', // true for 465, false for 587
                auth: {
                    user: process.env.SMTP_USER,
                    pass: process.env.SMTP_PASSWORD
                }
            });
        } else {
            // No SMTP configured: Log emails to console
            logger.info('📧 Email service initialized in console mode (OTPs will be logged)');
            return null;
        }
    }

    /**
     * Send OTP verification email
     * @param {string} email - Recipient email address
     * @param {string} otp - 6-digit OTP code
     * @param {string} userType - User type (owner, manager, customer, delivery_staff)
     * @returns {Promise<Object>} Send result
     */
    async sendOtpEmail(email, otp, userType = 'user') {
        try {
            const subject = 'Your Laundry App Verification Code';

            // Create user-friendly type name
            const userTypeName = {
                mart: 'Mart',
                owner: 'Mart Owner',
                manager: 'Manager',
                customer: 'Customer',
                delivery_staff: 'Delivery Partner'
            }[userType] || 'User';

            // HTML email content
            const html = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .container {
      background-color: #f9f9f9;
      border-radius: 10px;
      padding: 30px;
      box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
    }
    .header h1 {
      color: #2563eb;
      margin: 0;
      font-size: 28px;
    }
    .otp-box {
      background-color: #2563eb;
      color: white;
      font-size: 36px;
      font-weight: bold;
      letter-spacing: 8px;
      text-align: center;
      padding: 20px;
      border-radius: 8px;
      margin: 30px 0;
    }
    .info {
      background-color: #fff3cd;
      border-left: 4px solid #ffc107;
      padding: 15px;
      margin: 20px 0;
      border-radius: 4px;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      font-size: 12px;
      color: #666;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🧺 Laundry App</h1>
      <p>Verification Code</p>
    </div>
    
    <p>Hello ${userTypeName},</p>
    
    <p>Your verification code for Laundry App is:</p>
    
    <div class="otp-box">${otp}</div>
    
    <div class="info">
      <strong>⏰ This code will expire in 5 minutes</strong>
    </div>
    
    <p>If you didn't request this code, please ignore this email.</p>
    
    <div class="footer">
      <p>This is an automated email. Please do not reply.</p>
      <p>&copy; ${new Date().getFullYear()} Laundry App. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
      `;

            // Plain text version (fallback)
            const text = `
Your Laundry App Verification Code

Hello ${userTypeName},

Your verification code is: ${otp}

This code will expire in 5 minutes.

If you didn't request this code, please ignore this email.

---
This is an automated email. Please do not reply.
© ${new Date().getFullYear()} Laundry App. All rights reserved.
      `.trim();

            if (this.transporter) {
                // Send via SMTP
                const info = await this.transporter.sendMail({
                    from: process.env.SMTP_FROM_EMAIL || '"Laundry App" <noreply@laundryapp.com>',
                    to: email,
                    subject,
                    text,
                    html
                });

                logger.info('OTP email sent successfully', {
                    email,
                    messageId: info.messageId,
                    userType
                });

                return { success: true, messageId: info.messageId };
            } else {
                // Development mode: Log to console
                logger.info('========================================');
                logger.info('📧 OTP EMAIL (Development Mode)');
                logger.info('========================================');
                logger.info(`To: ${email}`);
                logger.info(`Subject: ${subject}`);
                logger.info(`User Type: ${userTypeName}`);
                logger.info(`OTP Code: ${otp}`);
                logger.info(`Expires: 5 minutes`);
                logger.info('========================================');

                return { success: true, messageId: 'dev-mode' };
            }
        } catch (error) {
            logger.error('Failed to send OTP email', {
                error: error.message,
                email,
                userType
            });
            throw new Error('Failed to send OTP email');
        }
    }

    /**
     * Send welcome email after registration
     * @param {string} email - Recipient email address
     * @param {string} userName - User's full name
     * @param {string} userType - User type
     * @returns {Promise<Object>} Send result
     */
    async sendWelcomeEmail(email, userName, userType = 'user') {
        try {
            const subject = 'Welcome to Laundry App!';

            const html = `
<!DOCTYPE html>
<html>
<head>
  <style>
    body {
      font-family: Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 600px;
      margin: 0 auto;
      padding: 20px;
    }
    .container {
      background-color: #f9f9f9;
      border-radius: 10px;
      padding: 30px;
      box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    }
    .header {
      text-align: center;
      margin-bottom: 30px;
    }
    .header h1 {
      color: #2563eb;
      margin: 0;
      font-size: 28px;
    }
    .content {
      background-color: white;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
    }
    .button {
      display: inline-block;
      padding: 12px 30px;
      background-color: #2563eb;
      color: white;
      text-decoration: none;
      border-radius: 5px;
      margin: 20px 0;
    }
    .footer {
      text-align: center;
      margin-top: 30px;
      font-size: 12px;
      color: #666;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🧺 Welcome to Laundry App!</h1>
    </div>
    
    <div class="content">
      <p>Hi ${userName},</p>
      
      <p>Welcome to Laundry App! Your account has been successfully created.</p>
      
      <p>You can now enjoy hassle-free laundry services with:</p>
      <ul>
        <li>✨ Easy order placement</li>
        <li>📍 Real-time tracking</li>
        <li>💳 Multiple payment options</li>
        <li>🚚 Doorstep pickup and delivery</li>
      </ul>
      
      <p>Get started today and experience the convenience of professional laundry care!</p>
    </div>
    
    <div class="footer">
      <p>&copy; ${new Date().getFullYear()} Laundry App. All rights reserved.</p>
    </div>
  </div>
</body>
</html>
      `;

            const text = `
Welcome to Laundry App!

Hi ${userName},

Welcome to Laundry App! Your account has been successfully created.

You can now enjoy hassle-free laundry services with:
- Easy order placement
- Real-time tracking
- Multiple payment options
- Doorstep pickup and delivery

Get started today and experience the convenience of professional laundry care!

---
© ${new Date().getFullYear()} Laundry App. All rights reserved.
      `.trim();

            if (this.transporter) {
                const info = await this.transporter.sendMail({
                    from: process.env.SMTP_FROM_EMAIL || '"Laundry App" <noreply@laundryapp.com>',
                    to: email,
                    subject,
                    text,
                    html
                });

                logger.info('Welcome email sent successfully', {
                    email,
                    messageId: info.messageId
                });

                return { success: true, messageId: info.messageId };
            } else {
                logger.info('📧 Welcome email would be sent to:', email);
                return { success: true, messageId: 'dev-mode' };
            }
        } catch (error) {
            logger.error('Failed to send welcome email', {
                error: error.message,
                email
            });
            // Don't throw - welcome email is not critical
            return { success: false, error: error.message };
        }
    }

    /**
     * Verify email service configuration
     * @returns {Promise<boolean>} Configuration status
     */
    async verifyConfiguration() {
        if (!this.transporter) {
            logger.warn('Email transporter not configured - running in development mode');
            return false;
        }

        try {
            await this.transporter.verify();
            logger.info('Email service configuration verified successfully');
            return true;
        } catch (error) {
            logger.error('Email service configuration verification failed', {
                error: error.message
            });
            return false;
        }
    }
}

module.exports = new EmailService();

