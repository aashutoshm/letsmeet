module Api
    class InviteController < ApplicationController
        # GET /api/guests
        def guests
            sql = "select c.*
                    from guests g
                             left join schedules s on g.schedule_id = s.id
                             left join rooms r on s.room_id = r.id
                             left join contacts c on g.contact_id = c.id
                    where r.bbb_id = :uid"
            contacts = Contact.find_by_sql([sql, {:uid => params[:uid]}])
            render json: contacts
        end

        # GET /api/contacts
        def contacts
            sql = "select c.* from contacts c left join users u on c.user_id = u.id where u.uid = :uid and (c.first_name ILIKE :keyword OR c.last_name ILIKE :keyword OR c.email ILIKE :keyword)"
            contacts = Contact.find_by_sql([sql, { :uid => params[:uid], :keyword => "%#{params[:keyword]}%" }])
            render json: contacts
        end

        # GET /api/invite
        def invite
            bbb_id = params[:uid]
            contact_ids = JSON.parse(params[:contact_ids])
            room = Room.find_by(bbb_id: bbb_id)
            contact_ids.each do |contact_id|
                contact = Contact.find_by(id: contact_id)
                schedule = room.schedule
                unless schedule == nil
                    schedule.guests.each do |guest|
                        guest.destroy
                    end
                    Guest.where(schedule_id: schedule.id, contact_id: contact.id).first_or_create
                    if schedule.notification_type == "Email"
                        emails = []
                        emails.push(contact.email)
                        ScheduleMailer.with(schedule: schedule, emails: emails).invite_email.deliver_later
                    elsif schedule.notification_type == "SMS"
                        numbers = []
                        numbers.push(contact.get_phone)
                        NotifySMSJob.perform_later(numbers.join(","), schedule.get_sms_content)
                    end
                end
            end

            render json: {
                invited: true,
            }
        end

        # GET /api/add_contact
        def add_contact
            uid = params[:uid]
            email = params[:email]
            user = User.where(["uid = :uid", {
                uid: uid
            }]).first
            contact = Contact.where("user_id = :user_id AND email = :email", {
                :user_id => user.id,
                :email => email
            }).first
            if contact
                render json: contact
            else
                contact = Contact.new(
                    user_id: user.id,
                    email: email,
                    first_name: email,
                    last_name: '',
                    code1: '+91',
                    code2: '+91'
                )
                if contact.save(validate: false)
                    render json: contact
                else
                    render json: {}, status: 400
                end
            end
        end
    end
end