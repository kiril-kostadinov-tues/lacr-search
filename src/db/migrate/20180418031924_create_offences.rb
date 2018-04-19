class CreateOffences < ActiveRecord::Migration[5.0]
  def change
    create_table :offences do |t|
      t.string :name
    end
  end
end