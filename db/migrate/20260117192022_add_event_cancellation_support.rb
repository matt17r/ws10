class AddEventCancellationSupport < ActiveRecord::Migration[8.1]
  def up
    add_column :events, :cancellation_reason, :text
  end

  def down
    # Revert any abandoned or cancelled events to draft status
    Event.where(status: [ "abandoned", "cancelled" ]).update_all(status: "draft")
    remove_column :events, :cancellation_reason
  end
end
