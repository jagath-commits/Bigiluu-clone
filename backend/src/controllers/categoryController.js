const categoryRepository = require('../repositories/categoryRepository');

class CategoryController {
  async getAllCategories(req, res, next) {
    try {
      const categories = await categoryRepository.findAll();

      return res.status(200).json({
        success: true,
        message: 'Categories fetched successfully',
        data: categories
      });
    } catch (err) {
      next(err);
    }
  }

  async getCategoryById(req, res, next) {
    try {
      const { categoryId } = req.params;
      const category = await categoryRepository.findById(categoryId);

      if (!category) {
        return res.status(404).json({
          success: false,
          message: 'Category not found',
          data: null
        });
      }

      return res.status(200).json({
        success: true,
        message: 'Category fetched successfully',
        data: category
      });
    } catch (err) {
      next(err);
    }
  }
}

module.exports = new CategoryController();
