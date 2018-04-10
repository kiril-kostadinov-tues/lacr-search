class AddPageSemanticsToSearches < ActiveRecord::Migration[5.0]
  def change
    add_column :searches, :offence, :string
    add_column :searches, :verdict, :string
    add_column :searches, :sentence, :string
  end
end
