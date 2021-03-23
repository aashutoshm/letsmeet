require 'bigbluebutton_api'

namespace :schedule do
    desc "Notify to users"
    task :notify => :environment do |task|
        schedules = Schedule.where("(start_date <= :today AND end_date >= :today) OR repeat_day = :week_day", {
            :today => Date.today,
            :week_day => Date.today.wday
        })
        schedules.each do |schedule|
            if schedule.start_time
                notification_time = Time.new(Date.today.year, Date.today.month, Date.today.day, schedule.start_time.hour, schedule.start_time.min, schedule.start_time.sec) - schedule.notification_minutes.minutes
            else
                notification_time = Time.new(Date.today.year, Date.today.month, Date.today.day, 9, 0, 0) - schedule.notification_minutes.minutes
            end
            guests = Guest.where("schedule_id = ?", schedule.id)
            if schedule.notification_type == "Email"
                emails = []
                emails.push(schedule.user.email)
                guests.each do |guest|
                    emails.push(guest.contact.email)
                end
                ScheduleMailer.with(schedule: schedule, emails: emails).invite_email.deliver_later(wait_until: notification_time.in_time_zone(schedule.timezone))
            elsif schedule.notification_type == "SMS"
                numbers = []
                numbers.push(schedule.user.phone)
                guests.each do |guest|
                    numbers.push(guest.contact.get_phone)
                end
                NotifySMSJob.set(wait_until: notification_time.in_time_zone(schedule.timezone)).perform_later(numbers.join(","), schedule.get_sms_content)
            end
        end
    end
end