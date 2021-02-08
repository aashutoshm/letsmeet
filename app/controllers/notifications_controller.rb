class NotificationsController < ApplicationController
    def index

    end

    # GET /notifications/recent
    def recent
        render json: current_user.notifications.limit(3).order('created_at desc')
    end
end