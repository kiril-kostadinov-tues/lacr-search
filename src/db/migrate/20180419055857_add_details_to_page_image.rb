class AddDetailsToPageImage < ActiveRecord::Migration[5.0]
  def change
    add_column :page_images, :collId, :string, default: ""
    add_column :page_images, :docId, :string, default: ""
    add_column :page_images, :tsId, :string, default: ""
  end
end
