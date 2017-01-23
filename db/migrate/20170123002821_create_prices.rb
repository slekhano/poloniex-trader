class CreatePrices < ActiveRecord::Migration[5.0]
  def change
    create_table :prices do |t|
      t.string :name, null: false
      t.timestamp :timestamp, null: false
      t.decimal :high, precision: 30, scale: 10
      t.decimal :low, precision: 30, scale: 10
      t.decimal :open, precision: 30, scale: 10
      t.decimal :close, precision: 30, scale: 10
      t.decimal :volume, precision: 30, scale: 10
      t.decimal :quote_volume, precision: 30, scale: 10
      t.decimal :weighted_average, precision: 30, scale: 10, null: false

      t.timestamps
    end

    add_index :prices, [:timestamp, :name], unique: true
  end
end
