class AddReadyAndDescriptionToEvent < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :results_ready, :boolean
    add_column :events, :description, :string
  end
end
