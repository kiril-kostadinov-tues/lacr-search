class CreateVerdicts < ActiveRecord::Migration[5.0]
  def change
    create_table :verdicts do |t|
      t.string :name
    end
  end
end