/**
 * Email Service
 * Handles sending emails for OTP verification and notifications
 */

const nodemailer = require('nodemailer');
const logger = require('../utils/logger');
const envManager = require('../config/env');

class EmailService {
    constructor() {
        this.transporter = null;
        this.currentConfigSignature = null;

        this._initializeTransporter({ reason: 'startup' });

        envManager.on('reload', () => {
            logger.info('🔁 Environment reload detected. Refreshing email transporter.');
            this._initializeTransporter({ reason: 'env-reload' });
        });
    }

    /**
     * Resolve SMTP configuration from environment variables
     * @returns {{ config: object, meta: object, signature: string }|null}
     * @private
     */
    _resolveSmtpConfig() {
        const emailService = process.env.EMAIL_SERVICE;
        const smtpHost = process.env.SMTP_HOST;
        const smtpUser = process.env.SMTP_USER;
        const smtpPass = process.env.SMTP_PASSWORD || process.env.SMTP_PASS;
        const smtpPort = parseInt(process.env.SMTP_PORT || '587', 10);
        const smtpSecure = smtpPort === 465;

        if (!(smtpUser && smtpPass && (emailService || smtpHost))) {
            return null;
        }

        const transporterConfig = {
            auth: {
                user: smtpUser,
                pass: smtpPass,
            },
        };

        if (emailService) {
            transporterConfig.service = emailService;
        } else {
            transporterConfig.host = smtpHost;
            transporterConfig.port = smtpPort;
            transporterConfig.secure = smtpSecure;
        }

        if (process.env.SMTP_TLS_REJECT_UNAUTHORIZED === 'false') {
            transporterConfig.tls = { rejectUnauthorized: false };
        }

        const signature = JSON.stringify({
            emailService: emailService || null,
            host: smtpHost || null,
            port: transporterConfig.port || null,
            user: smtpUser,
            secure: transporterConfig.secure ?? null,
        });

        return {
            config: transporterConfig,
            meta: {
                mode: emailService ? emailService : 'smtp',
                host: transporterConfig.host || emailService,
                port: transporterConfig.port || (emailService ? 'service-default' : undefined),
                secure: transporterConfig.secure ?? smtpSecure,
                user: smtpUser,
            },
            signature,
        };
    }

    /**
     * Initialize or refresh the SMTP transporter
     * @param {{ reason: string }} options
     * @private
     */
    _initializeTransporter({ reason }) {
        const resolved = this._resolveSmtpConfig();

        if (!resolved) {
            if (this.transporter) {
                this.transporter = null;
            }

            logger.error('❌ SMTP transporter not configured. OTP emails cannot be delivered until SMTP credentials are set.');
            return;
        }

        let shouldCreateTransporter = true;

        if (resolved.signature === this.currentConfigSignature && this.transporter) {
            if (reason === 'env-reload') {
                logger.debug('📧 SMTP configuration unchanged; verifying existing transporter.', { reason });
                shouldCreateTransporter = false;
            } else {
                logger.debug('📧 SMTP configuration unchanged; reusing existing transporter.', { reason });
                return;
            }
        }

        if (shouldCreateTransporter) {
            this.currentConfigSignature = resolved.signature;
            this.transporter = nodemailer.createTransport(resolved.config);
        }

        const transporter = this.transporter;

        transporter
            .verify()
            .then(() => {
                logger.info('✅ SMTP connection verified', resolved.meta);
            })
            .catch((error) => {
                logger.error(`❌ SMTP connection failed: ${error.message}`, {
                    ...resolved.meta,
                });
            });
    }

    /**
     * Ensure transporter exists (attempt reinitialization if needed)
     * @returns {import('nodemailer').Transporter|null}
     * @private
     */
    _ensureTransporter() {
        if (!this.transporter) {
            this._initializeTransporter({ reason: 'lazy-load' });
        }

        return this.transporter;
    }

    /**
     * Send OTP verification email
     * @param {string} email - Recipient email address
     * @param {string} otp - 6-digit OTP code
     * @param {string} userType - User type (owner, manager, customer, delivery_staff)
     * @returns {Promise<Object>} Send result
     */
    async sendOtpEmail(email, otp, userType = 'user') {
        const transporter = this._ensureTransporter();

        if (!transporter) {
            const error = new Error('SMTP transporter not configured');
            logger.error(`❌ Email sending failed: ${error.message}`, {
                email,
                userType,
            });
            throw error;
        }

        const subject = 'Your Laundry App Verification Code';

        const userTypeName = {
            mart: 'Mart',
            owner: 'Mart Owner',
            manager: 'Manager',
            customer: 'Customer',
            delivery_staff: 'Delivery Partner',
            portal: 'Portal User',
        }[userType] || 'User';

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

        try {
            const fromEmail =
                process.env.SMTP_FROM_EMAIL || process.env.FROM_EMAIL || `"Laundry App" <${process.env.SMTP_USER}>`;

            const info = await transporter.sendMail({
                from: fromEmail,
                to: email,
                subject,
                text,
                html,
            });

            logger.info(`✅ Email sent successfully to ${email}`, {
                messageId: info.messageId,
                userType,
                response: info.response,
            });

            return { success: true, messageId: info.messageId };
        } catch (error) {
            logger.error(`❌ Email sending failed: ${error.message}`, {
                email,
                userType,
                stack: error.stack,
            });
            throw new Error(`Failed to send OTP email: ${error.message}`);
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

            const transporter = this._ensureTransporter();

            if (!transporter) {
                logger.warn('📭 Skipping welcome email send because SMTP transporter is not configured', {
                    email,
                    userType,
                });
                return { success: false, error: 'SMTP transporter not configured' };
            }

            const fromEmail =
                process.env.SMTP_FROM_EMAIL || process.env.FROM_EMAIL || `"Laundry App" <${process.env.SMTP_USER}>`;

            const info = await transporter.sendMail({
                from: fromEmail,
                to: email,
                subject,
                text,
                html,
            });

            logger.info(`✅ Email sent successfully to ${email}`, {
                messageId: info.messageId,
                userType,
                context: 'welcome-email',
            });

            return { success: true, messageId: info.messageId };
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
        const transporter = this._ensureTransporter();

        if (!transporter) {
            logger.error('❌ SMTP transporter not configured. Verification failed.');
            return false;
        }

        try {
            await transporter.verify();
            logger.info('✅ SMTP connection verified');
            return true;
        } catch (error) {
            logger.error(`❌ SMTP connection failed: ${error.message}`);
            return false;
        }
    }
}

module.exports = new EmailService();

