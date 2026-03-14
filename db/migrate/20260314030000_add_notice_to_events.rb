class AddNoticeToEvents < ActiveRecord::Migration[8.1]
  def change
    add_column :events, :notice, :string
  end
end
