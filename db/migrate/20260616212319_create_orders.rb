class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :customer_name
      t.string :customer_email
      t.integer :total_cents
      t.string :status

      t.timestamps
    end
  end
end
