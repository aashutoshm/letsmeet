module SchedulesHelper
    def self.send_sms(country, recipients, text)
        params = {
            :authkey => ENV['MSG91_AUTH_KEY'],
            :mobiles => recipients,
            :country => country,
            :message => text,
            :sender => ENV['MSG91_SENDER_ID'],
            :route => 4
        }
        uri = URI("https://api.msg91.com/api/sendhttp.php")
        uri.query = URI.encode_www_form(params)

        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_NONE
        request = Net::HTTP::Get.new(uri)
        response = https.request(request)
        response.read_body
    end
end
