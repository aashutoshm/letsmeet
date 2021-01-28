class SchedulesController < ApplicationController
    layout "default"

    before_action :verify_authenticated

    # GET /schedules
    def index
    end

    # GET /schedules/ajax
    def ajax
        start_datetime = params[:start]
        end_datetime = params[:end]
        schedules = Schedule.where('(start_date BETWEEN :start_datetime AND :end_datetime OR repeat_weekly = true) AND user_id = :user_id', {
            :start_datetime => start_datetime,
            :end_datetime => end_datetime,
            :user_id => current_user.id
        })

        events = Array.new

        schedules.each do |schedule|
            if schedule.all_day
                if schedule.repeat_weekly
                    events.push({
                                    "daysOfWeek": [schedule.repeat_day],
                                    "title": schedule.title,
                                    "id" => schedule.id,
                                })
                else
                    events.push({
                                    "title" => schedule.title,
                                    "start" => schedule.start_date,
                                    "end" => schedule.end_date,
                                    "id" => schedule.id,
                                })
                end
            else
                if schedule.repeat_weekly
                    events.push({
                                    "daysOfWeek": [schedule.repeat_day],
                                    "startTime": schedule.start_time.strftime("%H:%M"),
                                    "endTime": schedule.end_time.strftime("%H:%M"),
                                    "title": schedule.title,
                                    "id" => schedule.id,
                                })
                else
                    a = schedule.start_date
                    b = schedule.end_date
                    c = b.mjd - a.mjd
                    (0..c).each do |i|
                        events.push({
                                        "id" => schedule.id,
                                        "title" => schedule.title,
                                        "start" => (schedule.start_date + i).strftime("%Y-%m-%d") + "T" + schedule.start_time.strftime("%H:%M") + ":00" + "-" + schedule.end_time.strftime("%H:%M"),
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

        render json: schedules.to_json(:include => [:user, :guests])
    end

    # POST /schedules/store
    def store
        if room_limit_exceeded
            render json: {
                "message": I18n.t("room.room_limit"),
            }, status: 400
        end

        room = Room.new(name: params[:title])
        room.owner = current_user
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

        if params[:repeat_weekly]
            @schedule.repeat_weekly = params[:repeat_weekly]
            @schedule.repeat_day = params[:repeat_day]
            @schedule.start_date = nil
            @schedule.end_date = nil
        else
            @schedule.repeat_weekly = nil
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
                guest_names = params[:guests]
                guest_names.each do |guest_name|
                    # print "Key: ", key, " | Value: ", value, "\n"
                    Guest.create(
                        schedule_id: @schedule.id,
                        username: guest_name
                    )
                end
            end

            if @schedule.notification_type == "Email"
                ScheduleMailer.with(schedule: @schedule).invite_email.deliver_later
            elsif @schedule.notification_type == "SMS"
                NotifySMSJob.perform_later(@schedule.user.phone, @schedule.get_sms_content)
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
            render json: schedule.to_json(:include => [:guests, :guest_permissions, :room])
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

            if params[:repeat_weekly]
                schedule.repeat_weekly = params[:repeat_weekly]
                schedule.repeat_day = params[:repeat_day]
                schedule.start_date = nil
                schedule.end_date = nil
            else
                schedule.repeat_weekly = nil
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
                    guest_names = params[:guests]
                    guest_names.each do |guest_name|
                        # print "Key: ", key, " | Value: ", value, "\n"
                        Guest.create(
                            schedule_id: schedule.id,
                            username: guest_name
                        )
                    end
                end

                if schedule.notification_type == "Email"
                    ScheduleMailer.with(schedule: schedule).invite_email.deliver_later
                elsif schedule.notification_type == "SMS"
                    NotifySMSJob.perform_later(schedule.user.phone, schedule.get_sms_content)
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
end
