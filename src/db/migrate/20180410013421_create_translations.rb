class CreateTranslations < ActiveRecord::Migration[5.0]
  def change
    create_table :translations do |t|
      t.string :word
      t.string :language
      t.string :translated

      t.timestamps
    end
  end
end
