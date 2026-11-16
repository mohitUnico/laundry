const CUSTOMER_ID = '11111111-1111-4111-8111-111111111111';
const USED_ADDRESS = '22222222-2222-4222-8222-222222222222';
const UNUSED_ADDRESS = '33333333-3333-4333-8333-333333333333';

const tx = {
    customer: {
        findUnique: jest.fn(),
        update: jest.fn(),
    },
    order: {
        count: jest.fn(),
        updateMany: jest.fn(),
        findMany: jest.fn(),
    },
    cart: {
        deleteMany: jest.fn(),
    },
    customerNotification: {
        deleteMany: jest.fn(),
    },
    customerAddress: {
        findMany: jest.fn(),
        updateMany: jest.fn(),
        deleteMany: jest.fn(),
    },
    refreshToken: {
        updateMany: jest.fn(),
    },
};

jest.mock('../../src/config/database', () => ({
    $transaction: async (fn) => fn(tx),
}));

jest.mock('../../src/utils/logger', () => ({
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
    debug: jest.fn(),
}));

const { ConflictError } = require('../../src/utils/errors');
const { deleteCustomerAccount } = require('../../src/services/customer-info.service');

describe('deleteCustomerAccount', () => {
    beforeEach(() => {
        jest.clearAllMocks();
        tx.customer.findUnique.mockResolvedValue({ customer_id: CUSTOMER_ID });
        tx.customer.update.mockResolvedValue({});
        tx.order.updateMany.mockResolvedValue({ count: 0 });
        tx.cart.deleteMany.mockResolvedValue({ count: 0 });
        tx.customerNotification.deleteMany.mockResolvedValue({ count: 0 });
        tx.customerAddress.findMany.mockResolvedValue([]);
        tx.customerAddress.updateMany.mockResolvedValue({ count: 0 });
        tx.customerAddress.deleteMany.mockResolvedValue({ count: 0 });
        tx.refreshToken.updateMany.mockResolvedValue({ count: 0 });
    });

    it('refuses and changes nothing while an order is still active', async () => {
        tx.order.count.mockResolvedValue(1);

        await expect(deleteCustomerAccount(CUSTOMER_ID)).rejects.toBeInstanceOf(ConflictError);
        expect(tx.customer.update).not.toHaveBeenCalled();
        expect(tx.cart.deleteMany).not.toHaveBeenCalled();
        expect(tx.refreshToken.updateMany).not.toHaveBeenCalled();
    });

    it('anonymizes the customer, keeps referenced addresses, and revokes tokens', async () => {
        tx.order.count.mockResolvedValue(0);
        tx.customerAddress.findMany.mockResolvedValue([
            { address_id: USED_ADDRESS },
            { address_id: UNUSED_ADDRESS },
        ]);
        tx.order.findMany.mockResolvedValue([
            { pickup_address_id: USED_ADDRESS, delivery_address_id: USED_ADDRESS },
        ]);

        await expect(deleteCustomerAccount(CUSTOMER_ID)).resolves.toEqual({ deleted: true });

        expect(tx.customer.update).toHaveBeenCalledWith({
            where: { customer_id: CUSTOMER_ID },
            data: {
                is_active: false,
                email: `deleted+${CUSTOMER_ID}@invalid.local`,
                full_name: 'Deleted user',
                phone: null,
                profile_image_url: null,
                fcm_token: null,
            },
        });
        expect(tx.order.updateMany).toHaveBeenCalledWith({
            where: { customer_id: CUSTOMER_ID, cart_id: { not: null } },
            data: { cart_id: null },
        });
        expect(tx.cart.deleteMany).toHaveBeenCalledWith({
            where: { customer_id: CUSTOMER_ID },
        });
        expect(tx.customerNotification.deleteMany).toHaveBeenCalledWith({
            where: { customer_id: CUSTOMER_ID },
        });
        expect(tx.customerAddress.updateMany).toHaveBeenCalledWith({
            where: { address_id: { in: [USED_ADDRESS] } },
            data: { full_address: 'Deleted', delivery_note: null },
        });
        expect(tx.customerAddress.deleteMany).toHaveBeenCalledWith({
            where: { address_id: { in: [UNUSED_ADDRESS] } },
        });
        expect(tx.refreshToken.updateMany).toHaveBeenCalledWith(
            expect.objectContaining({
                where: {
                    user_id: CUSTOMER_ID,
                    user_type: 'customer',
                    revoked_at: null,
                },
            })
        );
    });
});
