class Guest < ApplicationRecord
    belongs_to :schedule
    belongs_to :contact
end
