class CreateComments < ActiveRecord::Migration[5.0]
  def change
    create_table :comments do |t|
      t.text :content
      t.integer :user_id
      t.integer :search_volume
      t.integer :search_page
      
      t.timestamps
    end
  end
end