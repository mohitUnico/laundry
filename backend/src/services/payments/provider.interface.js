/**
 * Payment provider contract. A real PSP implements the same three methods.
 * @typedef {Object} PaymentProvider
 * @property {(input: { amount: string, orderId: string, attemptId: number }) => Promise<{ providerRef: string, intentPayload: object }>} createIntent
 * @property {(headers: object, rawBody: string) => object} verifyWebhook
 * @property {(ref: string) => Promise<{ status: string }>} fetchStatus
 */

module.exports = {};
