class PhotosProducts < ActiveRecord::Migration[5.0]
  def change
  	   create_table :photos_products, id: false do |t|
	      t.belongs_to :photo, index: true
	      t.belongs_to :product, index: true
	   end
  end
end
