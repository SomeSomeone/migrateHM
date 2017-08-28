class AddCashMethodToOrder < ActiveRecord::Migration[5.0]
  def change
    add_column :orders, :cash_method, :bool
  end
end
