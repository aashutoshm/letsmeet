class CreateGuests < ActiveRecord::Migration[5.2]
    def change
        create_table :guests do |t|
            t.belongs_to :schedule, index: true
            t.belongs_to :contact, index: true
            t.timestamps
        end
    end
end
