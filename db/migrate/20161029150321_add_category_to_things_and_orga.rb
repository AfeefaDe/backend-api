class AddCategoryToThingsAndOrga < ActiveRecord::Migration[5.0]
  def change
    add_column :events, :category, :string
    add_column :orgas, :category, :string
  end
end
