class Schedule < ApplicationRecord
    belongs_to :user
    belongs_to :room

    has_many :guest_permissions
    has_many :guests

    def as_json(options = {})
        super.merge(start_time: start_time ? start_time.strftime("%H:%M") : start_time, end_time: end_time ? end_time.strftime("%H:%M") : end_time)
    end

    def get_week_day
        case repeat_day
        when 0
            "Sun"
        when 1
            "Mon"
        when 2
            "Tue"
        when 3
            "Wed"
        when 4
            "Thu"
        when 5
            "Fri"
        when 6
            "Sat"
        else
            ""
        end
    end

    def get_sms_content
        datetime_string = ""
        if repeat_weekly
            datetime_string += "Every " + get_week_day
        else
            datetime_string += start_date.strftime('%b %d, %Y') + "-" + end_date.strftime('%b %d, %Y')
        end
        if all_day
            datetime_string += ", All day"
        else
            datetime_string += "," + start_time.strftime('%H:%M') + "-" + end_time.strftime('%H:%M')
        end
        datetime_string += "," + timezone

        "Meeting Details:\n%s\n%s\nBy: " % [room.invite_url, datetime_string, user.first_name + user.last_name]
    end
end
