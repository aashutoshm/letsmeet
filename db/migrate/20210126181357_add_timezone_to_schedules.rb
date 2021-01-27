class AddTimezoneToSchedules < ActiveRecord::Migration[5.2]
    def change
        add_column :schedules, :timezone, :string
        add_column :schedules, :job_id, :string
        add_column :schedules, :room_id, :bigint
        add_index :schedules, :room_id, unique: true
        add_foreign_key :schedules, :rooms, on_delete: :nullify
    end
end
