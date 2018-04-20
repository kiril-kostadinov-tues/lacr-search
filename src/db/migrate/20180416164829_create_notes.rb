class CreateNotes < ActiveRecord::Migration[5.0]
  def change
    create_table :notes do |t|
      t.integer :search_volume
      t.integer :search_page
      t.integer :search_paragraph
      t.integer :user_id
      t.text :content

      t.timestamps
    end
  end
end
