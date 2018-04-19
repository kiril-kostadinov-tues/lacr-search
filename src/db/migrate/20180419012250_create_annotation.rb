class CreateAnnotation < ActiveRecord::Migration[5.0]
  def change
    create_table :annotations do |t|
      t.string :name
    end
  end
end