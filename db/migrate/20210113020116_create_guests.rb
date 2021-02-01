class CreateGuests < ActiveRecord::Migration[5.2]
    def change
        create_table :guests do |t|
            t.belongs_to :schedule, index: true
            t.string :username, null: false
            t.string :email, null: false
            t.string :phone
            t.timestamps
        end
    end
end
