class CreatePrices < ActiveRecord::Migration[5.0]
  def change
    create_table :prices do |t|
      t.string :name, null: false
      t.date :date, null: false
      t.decimal :high
      t.decimal :low
      t.decimal :open
      t.decimal :close
      t.decimal :volume
      t.decimal :quoteVolume
      t.decimal :weightedAverage, null: false

      t.timestamps
    end

    add_index :prices, [:date, :name], unique: true
  end
end
