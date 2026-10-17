class AddStatusAndSubmittedTimeToCheckIns < ActiveRecord::Migration[8.1]
  def change
    add_column :check_ins, :status, :string, null: false, default: "approved"
    add_column :check_ins, :submitted_time, :integer
    add_check_constraint :check_ins, "status IN ('approved', 'pending')", name: "check_in_status_valid"
  end
end
