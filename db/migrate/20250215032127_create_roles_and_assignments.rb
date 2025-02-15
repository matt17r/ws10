class CreateRolesAndAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :roles, :name, unique: true

    reversible do |direction|
      direction.up do
        Role.create(name: "Administrator")
        Role.create(name: "Organiser")
      end
    end

    create_table :assignments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true

      t.timestamps
    end
  end
end
