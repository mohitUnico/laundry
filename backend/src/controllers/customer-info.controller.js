const customerInfoService = require('../services/customer-info.service');
const { AuthorizationError } = require('../utils/errors');

function decimalString(value) {
    if (value == null) return null;
    const num = Number(value);
    return Number.isFinite(num) ? num.toFixed(8) : String(value);
}

function presentAddress(row) {
    return {
        address_id: row.address_id,
        customer_id: row.customer_id,
        address_label: row.address_label,
        full_address: row.full_address,
        latitude: decimalString(row.latitude),
        longitude: decimalString(row.longitude),
        is_default: row.is_default,
        delivery_note: row.delivery_note ?? null,
        created_at: row.created_at,
        updated_at: row.updated_at,
    };
}

exports.createAddress = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can manage addresses');
        }

        const customerId = req.user.user_id;
        const address = await customerInfoService.createCustomerAddress(customerId, req.body);

        res.status(201).json({
            success: true,
            data: presentAddress(address),
            message: 'Address created successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getAddresses = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can view addresses');
        }

        const customerId = req.user.user_id;
        const addresses = await customerInfoService.getCustomerAddresses(customerId);

        res.status(200).json({
            success: true,
            data: addresses.map(presentAddress),
            message: 'Addresses fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getAddressById = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can view addresses');
        }

        const customerId = req.user.user_id;
        const { addressId } = req.params;
        const address = await customerInfoService.getCustomerAddressById(customerId, addressId);

        res.status(200).json({
            success: true,
            data: address,
            message: 'Address fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.updateAddress = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can manage addresses');
        }

        const customerId = req.user.user_id;
        const { addressId } = req.params;
        const updated = await customerInfoService.updateCustomerAddress(customerId, addressId, req.body);

        res.status(200).json({
            success: true,
            data: updated,
            message: 'Address updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.deleteAddress = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can manage addresses');
        }

        const customerId = req.user.user_id;
        const { addressId } = req.params;
        const result = await customerInfoService.deleteCustomerAddress(customerId, addressId);

        res.status(200).json({
            success: true,
            data: result,
            message: 'Address deleted successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.updateProfileImageUrl = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can manage profile');
        }

        const customerId = req.user.user_id;
        const updated = await customerInfoService.updateCustomerProfileImageUrl(customerId, req.body);

        res.status(200).json({
            success: true,
            data: updated,
            message: 'Profile image updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.uploadProfileImage = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can manage profile');
        }

        const customerId = req.user.user_id;
        const updated = await customerInfoService.uploadCustomerProfileImage(customerId, req.file);

        res.status(200).json({
            success: true,
            data: updated,
            message: 'Profile image uploaded successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.getProfile = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can view profile');
        }

        const customerId = req.user.user_id;
        const profile = await customerInfoService.getCustomerProfile(customerId);

        res.status(200).json({
            success: true,
            data: profile,
            message: 'Profile fetched successfully',
        });
    } catch (error) {
        next(error);
    }
};

exports.updateProfile = async (req, res, next) => {
    try {
        if (req.user.role !== 'customer') {
            throw new AuthorizationError('Only customers can manage profile');
        }

        const customerId = req.user.user_id;
        const updated = await customerInfoService.updateCustomerProfile(customerId, req.body);

        res.status(200).json({
            success: true,
            data: updated,
            message: 'Profile updated successfully',
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;


