class CreateSchedules < ActiveRecord::Migration[5.2]
    def change
        create_table :schedules do |t|
            t.belongs_to :user, index: true
            t.bigint :room_id
            t.string :title, :null => false
            t.date :start_date
            t.date :end_date
            t.time :start_time
            t.time :end_time
            t.string :timezone
            t.string :job_id
            t.boolean :all_day, :default => false
            t.boolean :is_repeat, :default => false
            t.string :repeat_type
            t.string :repeat_day
            t.boolean :mute_video, :default => false
            t.boolean :mute_audio, :default => false
            t.boolean :record_meeting, :default => false
            t.text :description
            t.string :events_tag
            t.string :notification_type
            t.integer :notification_minutes

            t.timestamps

            t.index :room_id, unique: true
            t.foreign_key :rooms, on_delete: :nullify
        end
    end
end
