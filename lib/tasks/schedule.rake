require 'bigbluebutton_api'

namespace :schedule do
    desc "test schedule email"
    task :test_email, [:email] => [:environment] do |task, args|
        UserMailer.welcome_email(args.email).deliver_later(wait_until: 2.minutes.from_now)
    end

    desc "test schedule sms"
    task :test_sms, [:number] => [:environment] do |task, args|
        NotifySMSJob.set(wait_until: 2.minutes.from_now).perform_later(args.number)
    end
end