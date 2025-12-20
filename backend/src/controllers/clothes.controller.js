/**
 * Clothes Controller
 * Handles HTTP requests for clothes items
 */

const clothesService = require('../services/clothes.service');

exports.addClothesItem = async (req, res, next) => {
    try {
        const martId = req.user.mart_id;
        const item = await clothesService.addClothesItem(martId, req.body);

        res.status(201).json({
            success: true,
            data: item,
            message: 'Clothes item added successfully'
        });
    } catch (error) {
        next(error);
    }
};

module.exports = exports;


