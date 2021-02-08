class SchedulesController < ApplicationController
    layout "default"

    before_action :verify_authenticated

    # GET /schedules
    def index
    end

    # GET /schedules/ajax
    def ajax
        start_datetime = params[:start]
        s = Time.parse(start_datetime)
        end_datetime = params[:end]
        e = Time.parse(end_datetime)
        avg = Time.at((s.to_f + e.to_f) / 2)
        avg_date = Date.parse(avg.to_s)

        schedules = Schedule.where('(start_date BETWEEN :start_datetime AND :end_datetime OR is_repeat = true) AND user_id = :user_id', {
            :start_datetime => start_datetime,
            :end_datetime => end_datetime,
            :user_id => current_user.id
        })

        events = Array.new

        schedules.each do |schedule|
            if schedule.all_day
                if schedule.is_repeat
                    case schedule.repeat_type
                    when "d"
                        events.push({
                                        "id" => schedule.id,
                                        "title" => schedule.title,
                                        "start" => start_datetime,
                                        "end" => end_datetime,
                                        "allDay" => true,
                                    })
                    when "w"
                        events.push({
                                        "id" => schedule.id,
                                        "title" => schedule.title,
                                        "allDay" => true,
                                        "daysOfWeek" => [
                                            schedule.repeat_day
                                        ]
                                    })
                    when "m"
                        avg_date = avg_date.change(day: schedule.repeat_day.to_i)

                        events.push({
                                        "id" => schedule.id,
                                        "title" => schedule.title,
                                        "start" => avg_date.strftime("%Y-%m-%d"),
                                        "allDay" => true,
                                    })
                    when "y"
                        m = schedule.repeat_day.split("/")[0]
                        d = schedule.repeat_day.split("/")[1]
                        start = Date.today.change(month: m.to_i, day: d.to_i)
                        events.push({
                                        "id" => schedule.id,
                                        "title" => schedule.title,
                                        "start" => start.strftime("%Y-%m-%d"),
                                        "allDay" => true,
                                    })
                    else
                        # type code here
                    end
                else
                    events.push({
                                    "title" => schedule.title,
                                    "start" => schedule.start_date,
                                    "end" => schedule.end_date,
                                    "id" => schedule.id,
                                    "allDay" => true
                                })
                end
            else
                if schedule.is_repeat
                    case schedule.repeat_type
                    when "d"
                        events.push({
                                        "startTime": schedule.start_time.strftime("%H:%M"),
                                        "endTime": schedule.end_time.strftime("%H:%M"),
                                        "title": schedule.title,
                                        "id" => schedule.id,
                                    })
                    when "w"
                        events.push({
                                        "id" => schedule.id,
                                        "title" => schedule.title,
                                        "startTime" => schedule.start_time.strftime("%H:%M"),
                                        "endTime" => schedule.end_time.strftime("%H:%M"),
                                        "daysOfWeek" => [
                                            schedule.repeat_day
                                        ]
                                    })
                    when "m"
                        avg_date = avg_date.change(day: schedule.repeat_day.to_i)
                        events.push({
                                        "start" => avg_date.strftime("%Y-%m-%d") + "T" + schedule.start_time.strftime("%H:%M") + ":00",
                                        "end" => avg_date.strftime("%Y-%m-%d") + "T" + schedule.end_time.strftime("%H:%M") + ":00",
                                        "title": schedule.title,
                                        "id" => schedule.id,
                                    })
                    when "y"
                        m = schedule.repeat_day.split("/")[0]
                        d = schedule.repeat_day.split("/")[1]
                        start = Date.today.change(month: m.to_i, day: d.to_i)
                        events.push({
                                        "id" => schedule.id,
                                        "title" => schedule.title,
                                        "start" => start.strftime("%Y-%m-%d") + "T" + schedule.start_time.strftime("%H:%M:00"),
                                        "end" => start.strftime("%Y-%m-%d") + "T" + schedule.end_time.strftime("%H:%M:00"),
                                        "allDay" => true,
                                    })
                    else
                        # type code here
                    end
                else
                    a = schedule.start_date
                    b = schedule.end_date
                    c = b.mjd - a.mjd
                    (0..c).each do |i|
                        events.push({
                                        "id" => schedule.id,
                                        "title" => schedule.title,
                                        "start" => (schedule.start_date + i).strftime("%Y-%m-%d") + "T" + schedule.start_time.strftime("%H:%M:00"),
                                        "end" => (schedule.start_date + i).strftime("%Y-%m-%d") + "T" + schedule.end_time.strftime("%H:%M:00")
                                    })
                    end
                end
            end
        end

        render json: events
    end

    # GET /schedules/upcoming
    def upcoming
        start_datetime = DateTime.now
        end_datetime = start_datetime.next_day(7)
        schedules = Schedule.where('start_date BETWEEN :start_datetime AND :end_datetime AND user_id = :user_id', {
            :start_datetime => start_datetime,
            :end_datetime => end_datetime,
            :user_id => current_user.id
        })

        render json: schedules.as_json(
            include: [:room, guests: { include: [contact: { methods: [:avatar_url] }] }, user: { methods: [:avatar_url] }]
        )
    end

    # POST /schedules/store
    def store
        if room_limit_exceeded
            render json: {
                "message": I18n.t("room.room_limit"),
            }, status: 400
        end

        room = Room.new(name: params[:title], access_code: params[:access_code])
        room.owner = current_user
        room.room_settings = create_room_settings_string(
            {
                "recording": params[:record_meeting]
            })
        unless room.save
            render json: {
                "message": I18n.t("room.create_room_error"),
            }, status: 400
        end

        logger.info "Support: #{current_user.email} has created a new room #{room.uid}."

        @schedule = Schedule.new(
            user_id: current_user.id,
            room_id: room.id,
            title: params[:title],
            description: params[:description],
            notification_type: params[:notification_type],
            notification_minutes: params[:notification_minutes],
            mute_video: params[:mute_video],
            mute_audio: params[:mute_audio],
            record_meeting: params[:record_meeting],
            timezone: params[:timezone]
        )

        if params[:event_tags].length > 0
            event_tags = params[:event_tags]
            @schedule.events_tag = event_tags.join(",")
        end

        if params[:all_day]
            @schedule.all_day = params[:all_day]
            @schedule.start_time = nil
            @schedule.end_time = nil
        else
            @schedule.all_day = nil
            @schedule.start_time = params[:start_time]
            @schedule.end_time = params[:end_time]
        end

        if params[:is_repeat]
            @schedule.is_repeat = params[:is_repeat]
            @schedule.repeat_type = params[:repeat_type]
            if params[:repeat_type] == 'd'
                @schedule.repeat_day = nil
            else
                @schedule.repeat_day = params[:repeat_day]
            end
            @schedule.start_date = nil
            @schedule.end_date = nil
        else
            @schedule.is_repeat = false
            @schedule.repeat_type = nil
            @schedule.repeat_day = nil
            @schedule.start_date = params[:start_date]
            @schedule.end_date = params[:end_date]
        end

        if @schedule.save
            guest_permissions = params[:guest_permissions]
            guest_permissions.each do |key, value|
                # print "Key: ", key, " | Value: ", value, "\n"
                GuestPermission.create(
                    schedule_id: @schedule.id,
                    name: key,
                    value: value
                )
            end
            if params[:guests].length > 0
                guests = params[:guests]
                guests.each do |guest|
                    Guest.create(
                        schedule_id: @schedule.id,
                        contact_id: guest[:id],
                    )
                end
            end

            WebNotificationsChannel.broadcast_to(
                @schedule.user,
                title: @schedule.title,
                body: "",
                onclick_url: @schedule.room.invite_url
            )
            Notification.create(title: @schedule.title, user_id: @schedule.user_id, onclick_url: @schedule.room.invite_url)

            if @schedule.notification_type == "Email"
                ScheduleMailer.with(schedule: @schedule).invite_email.deliver_later
            elsif @schedule.notification_type == "SMS"
                numbers = []
                numbers.push(@schedule.user.phone)
                @schedule.guests.each do |guest|
                    numbers.push(guest.contact.get_phone)
                end
                NotifySMSJob.perform_later(numbers.join(","), @schedule.get_sms_content)
            end

            render json: {
                "message": "Success",
                "schedule": @schedule
            }
        else
            render json: {
                "message": "Error",
                "schedule": @schedule
            }, status: 400
        end
    end

    # GET /schedules/:id
    def show
        schedule = current_user.schedules.where("id = ?", params[:id]).first()
        if schedule
            # render json: schedule.to_json(:include => [:guests, :guest_permissions, :room])
            render json: schedule.as_json(
                include: [:guest_permissions, :room, guests: { include: [contact: { methods: [:avatar_url] }] }]
            )
        else
            render json: {
                "message": "Not found"
            }, schedule: 404
        end
    end

    # POST /schedules/:id
    def update
        schedule = current_user.schedules.where("id = ?", params[:id]).first()
        if schedule
            room = schedule.room
            room.access_code = params[:access_code]
            room.room_settings = create_room_settings_string(
                {
                    "recording": params[:record_meeting]
                })
            unless room.save
                render json: {
                    "message": "Room params invalid"
                }, schedule: 400
            end

            schedule.title = params[:title]
            schedule.description = params[:description]
            schedule.notification_type = params[:notification_type]
            schedule.notification_minutes = params[:notification_minutes]
            schedule.mute_video = params[:mute_video]
            schedule.mute_audio = params[:mute_audio]
            schedule.record_meeting = params[:record_meeting]
            schedule.timezone = params[:timezone]
            if params[:event_tags].length > 0
                event_tags = params[:event_tags]
                schedule.events_tag = event_tags.join(",")
            end

            if params[:all_day]
                schedule.all_day = params[:all_day]
                schedule.start_time = nil
                schedule.end_time = nil
            else
                schedule.all_day = nil
                schedule.start_time = params[:start_time]
                schedule.end_time = params[:end_time]
            end

            if params[:is_repeat]
                schedule.is_repeat = params[:is_repeat]
                schedule.repeat_type = params[:repeat_type]
                if params[:repeat_type] == 'd'
                    schedule.repeat_day = nil
                else
                    schedule.repeat_day = params[:repeat_day]
                end
                schedule.start_date = nil
                schedule.end_date = nil
            else
                schedule.is_repeat = false
                schedule.repeat_type = nil
                schedule.repeat_day = nil
                schedule.start_date = params[:start_date]
                schedule.end_date = params[:end_date]
            end

            if schedule.save
                guest_permissions = params[:guest_permissions]
                guest_permissions.each do |key, value|
                    # print "Key: ", key, " | Value: ", value, "\n"
                    permission = GuestPermission.where("schedule_id = ? AND name = ?", schedule.id, key).first()
                    if permission
                        permission.value = value
                        permission.save
                    else
                        GuestPermission.create(
                            schedule_id: schedule.id,
                            name: key,
                            value: value
                        )
                    end
                end

                schedule.guests.destroy_all

                if params[:guests].length > 0
                    guests = params[:guests]
                    guests.each do |guest|
                        # print "Key: ", key, " | Value: ", value, "\n"
                        Guest.create(
                            schedule_id: schedule.id,
                            contact_id: guest[:id]
                        )
                    end
                end

                WebNotificationsChannel.broadcast_to(
                    schedule.user,
                    title: schedule.title,
                    body: "",
                    onclick_url: schedule.room.invite_url
                )
                Notification.create(title: schedule.title, user_id: schedule.user_id, onclick_url: schedule.room.invite_url)

                if schedule.notification_type == "Email"
                    ScheduleMailer.with(schedule: schedule).invite_email.deliver_later
                elsif schedule.notification_type == "SMS"
                    numbers = []
                    numbers.push(schedule.user.phone)
                    schedule.guests.each do |guest|
                        numbers.push(guest.contact.get_phone)
                    end
                    NotifySMSJob.perform_later(numbers.join(","), schedule.get_sms_content)
                end

            end
            render json: schedule.to_json(:include => [:guests, :guest_permissions])
        else
            render json: {
                "message": "Not found"
            }, schedule: 404
        end
    end

    private

    def verify_authenticated
        redirect_to root_path unless current_user
    end

    def room_limit_exceeded
        limit = @settings.get_value("Room Limit").to_i

        # Does not apply to admin or users that aren't signed in
        # 15+ option is used as unlimited
        return false if current_user&.has_role?(:admin) || limit == 15

        current_user.rooms.length >= limit
    end

    def create_room_settings_string(options)
        room_settings = {
            # "muteOnStart": options[:mute_on_join] == "1",
            # "requireModeratorApproval": options[:require_moderator_approval] == "1",
            # "anyoneCanStart": options[:anyone_can_start] == "1",
            # "joinModerator": options[:all_join_moderator] == "1",
            "recording": options[:recording],
        }

        room_settings.to_json
    end
end
