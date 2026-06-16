class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string :name
      t.text :description
      t.integer :price_cents
      t.string :image_url

      t.timestamps
    end
  end
end
