class AddTextToCategory < ActiveRecord::Migration[5.0]
  def change
    add_column :categories, :text, :text
  end
end
