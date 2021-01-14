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
        schedules = Schedule.where('start_date BETWEEN :start_datetime AND :end_datetime OR repeat_weekly = true', {
            :start_datetime => start_datetime,
            :end_datetime => end_datetime
        })

        events = Array.new

        schedules.each do |schedule|
            if schedule.all_day
                if schedule.repeat_weekly
                    events.push({
                                    "daysOfWeek": [schedule.repeat_day]
                                })
                else
                    events.push({
                                    "title" => schedule.title,
                                    "start" => schedule.start_date,
                                    "end" => schedule.end_date
                                })
                end
            else
                if schedule.repeat_weekly
                    events.push({
                                    "daysOfWeek": [schedule.repeat_day],
                                    "startTime": schedule.start_time.strftime("%H:%M"),
                                    "endTime": schedule.end_time.strftime("%H:%M")
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

    # POST /schedules/store
    def store
        @schedule = Schedule.new(
            user_id: current_user.id,
            title: params[:title],
            description: params[:description],
            notification_type: params[:notification_type],
            notification_minutes: params[:notification_minutes]
        )

        if params[:event_tags].length > 0
            event_tags = params[:event_tags]
            @schedule.events_tag = event_tags.join(",")
        end

        if params[:all_day]
            @schedule.all_day = params[:all_day]
        else
            @schedule.start_time = params[:start_time]
            @schedule.end_time = params[:end_time]
        end

        if params[:repeat_weekly]
            @schedule.repeat_weekly = params[:repeat_weekly]
            @schedule.repeat_day = params[:repeat_day]
        else
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

    private

    def verify_authenticated
        redirect_to root_path unless current_user
    end
end
