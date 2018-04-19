class AddPageSemanticsToSearches < ActiveRecord::Migration[5.0]
  def change
    add_column :searches, :offence, :integer, array: true, default: []
    add_column :searches, :verdict, :integer, array: true, default: []
    add_column :searches, :sentence, :integer, array: true, default: []
  end
end