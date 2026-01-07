class AddStatusToEvents < ActiveRecord::Migration[8.1]
  def up
    add_column :events, :status, :string, default: 'draft', null: false

    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE events
          SET status = CASE
            WHEN results_ready = 1 THEN 'finalised'
            ELSE 'draft'
          END
        SQL
      end
    end

    remove_column :events, :results_ready, :boolean
    add_index :events, :status
  end

  def down
    add_column :events, :results_ready, :boolean, default: false, null: false

    reversible do |dir|
      dir.down do
        execute <<-SQL
          UPDATE events
          SET results_ready = CASE WHEN status = 'finalised' THEN 1 ELSE 0 END
        SQL
      end
    end

    remove_column :events, :status, :string
  end
end
