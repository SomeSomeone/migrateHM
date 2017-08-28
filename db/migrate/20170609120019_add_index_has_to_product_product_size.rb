class AddIndexHasToProductProductSize < ActiveRecord::Migration[5.0]
  def change
    add_index :product_product_sizes, :has
  end
end
