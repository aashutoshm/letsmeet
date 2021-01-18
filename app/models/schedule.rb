class Schedule < ApplicationRecord
    belongs_to :user

    has_many :guest_permissions
    has_many :guests

    def as_json(options = {})
        super.merge(start_time: start_time ? start_time.strftime("%H:%M") : start_time, end_time: end_time ? end_time.strftime("%H:%M") : end_time)
    end
end
