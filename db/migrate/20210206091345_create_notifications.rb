class CreateNotifications < ActiveRecord::Migration[5.2]
    def change
        create_table :notifications do |t|
            t.belongs_to :user
            t.string :title, null: false
            t.text :content
            t.string :onclick_url

            t.timestamps
        end
    end
end
