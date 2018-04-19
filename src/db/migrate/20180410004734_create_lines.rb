class CreateLines < ActiveRecord::Migration[5.0]
  def change
    create_table :lines do |t|
      t.integer :volume
      t.integer :page
      t.float :x1
      t.float :y1
      t.float :x2
      t.float :y2
      t.float :x3
      t.float :y3
      t.float :x4
      t.float :y4
      t.text :transcript

      t.timestamps
    end
  end
end
