class CreateCategoriesProducts < ActiveRecord::Migration[5.0]
  def change
    create_table :categories_products , id: false do |t|
      t.references :category, index: true, foreign_key: true
      t.references :product, index: true, foreign_key: true
    end
  end
end
