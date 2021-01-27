class ScheduleMailer < ApplicationMailer
    include SchedulesHelper

    default from: Rails.configuration.smtp_sender

    def invite_email
        require 'icalendar/tzinfo'

        @schedule = params[:schedule]

        cal = Icalendar::Calendar.new

        cal.event do |e|
            if @schedule.all_day && !@schedule.repeat_weekly
                e.dtstart = Icalendar::Values::Date.new @schedule.start_date, 'tzid' => @schedule.timezone
                e.dtend = Icalendar::Values::Date.new @schedule.end_date, 'tzid' => @schedule.timezone
            elsif @schedule.all_day && @schedule.repeat_weekly
                case @schedule.repeat_day
                when 0
                    week_day = "SU"
                when 1
                    week_day = "MO"
                when 2
                    week_day = "TU"
                when 3
                    week_day = "WE"
                when 4
                    week_day = "TH"
                when 5
                    week_day = "FR"
                when 6
                    week_day = "SA"
                else
                    week_day = ""
                end
                e.dtstart = Icalendar::Values::Date.new DateTime.now.to_date
                e.rrule = "FREQ=WEEKLY;BYDAY=%s;INTERVAL=1" % week_day
            elsif !@schedule.all_day && @schedule.repeat_weekly
                case @schedule.repeat_day
                when 0
                    week_day = "SU"
                when 1
                    week_day = "MO"
                when 2
                    week_day = "TU"
                when 3
                    week_day = "WE"
                when 4
                    week_day = "TH"
                when 5
                    week_day = "FR"
                when 6
                    week_day = "SA"
                else
                    week_day = ""
                end

                today = DateTime.now
                event_start = DateTime.new(today.year, today.month, today.day, @schedule.start_time.hour, @schedule.start_time.min)
                event_end = DateTime.new(today.year, today.month, today.day, @schedule.end_time.hour, @schedule.end_time.min)

                e.dtstart = Icalendar::Values::DateTime.new event_start, 'tzid' => @schedule.timezone
                e.dtend = Icalendar::Values::DateTime.new event_end, 'tzid' => @schedule.timezone
                e.rrule = "FREQ=WEEKLY;BYDAY=%s;INTERVAL=1" % week_day
            elsif !@schedule.all_day && !@schedule.repeat_weekly
                event_start = DateTime.new(@schedule.start_date.year, @schedule.start_date.month, @schedule.start_date.day,
                                           @schedule.start_time.hour, @schedule.start_time.min)
                event_end = DateTime.new(@schedule.start_date.year, @schedule.start_date.month, @schedule.start_date.day,
                                         @schedule.end_time.hour, @schedule.end_time.min)

                until_date = Date.new(@schedule.end_date.year, @schedule.end_date.month, @schedule.end_date.day)

                e.dtstart = Icalendar::Values::DateTime.new event_start, 'tzid' => @schedule.timezone
                e.dtend = Icalendar::Values::DateTime.new event_end, 'tzid' => @schedule.timezone
                e.rrule = "FREQ=DAILY;UNTIL=%s" % [until_date.strftime("%Y%m%dT000000")]
            end
            e.summary = @schedule.title
            e.description = @schedule.description
            e.organizer = "mailto:%s" % @schedule.user.email
            e.organizer = Icalendar::Values::CalAddress.new("mailto:%s" % @schedule.user.email, cn: '%s %s' % [@schedule.user.first_name, @schedule.user.last_name])
            e.url = @schedule.room.invite_url
            e.ip_class = "PRIVATE"
        end

        mail.attachments['letsmeet_meeting.ics'] = {
            mime_type: 'text/calendar',
            content: cal.to_ical
        }

        mail to: @schedule.user.email, subject: "Letsmeet Meeting"
    end
end
