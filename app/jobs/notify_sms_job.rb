class NotifySMSJob < ActiveJob::Base
    queue_as :default

    def perform(number, content)
        response = SchedulesHelper.send_sms(0, number, content)
        print("%\n" % response)
    end
end