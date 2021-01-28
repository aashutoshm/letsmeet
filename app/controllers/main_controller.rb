class MainController < ApplicationController
    include Registrar

    before_action :verify_authenticated

    layout "default"

    # GET /
    def index
        # Store invite token
        session[:invite_token] = params[:invite_token] if params[:invite_token] && invite_registration

        @meetings_this_week = Schedule.where("user_id = :user_id AND ((start_date >= :beginning_of_week AND start_date <= :end_of_week) OR (end_date >= :beginning_of_week AND end_date <= :end_of_week) OR (start_date <= :beginning_of_week AND end_date >= :end_of_week) OR (repeat_day >= :week_day))", {
            :user_id => current_user.id,
            :beginning_of_week => Date.today.beginning_of_week,
            :end_of_week => Date.today.end_of_week,
            :week_day => Date.today.wday
        }).count
        @meetings_this_month = Schedule.where("user_id = :user_id AND ((start_date >= :beginning_of_month AND start_date <= :end_of_month) OR (end_date >= :beginning_of_month AND end_date <= :end_of_month) OR (start_date <= :beginning_of_month AND end_date >= :end_of_month) OR (repeat_weekly = true))", {
            :user_id => current_user.id,
            :beginning_of_month => Date.today.beginning_of_month,
            :end_of_month => Date.today.end_of_month
        }).count
        @meetings_this_year = Schedule.where("user_id = :user_id AND ((start_date >= :beginning_of_year AND start_date <= :end_of_year) OR (end_date >= :beginning_of_year AND end_date <= :end_of_year) OR (start_date <= :beginning_of_year AND end_date >= :end_of_year) OR (repeat_weekly = true))", {
            :user_id => current_user.id,
            :beginning_of_year => Date.today.beginning_of_year,
            :end_of_year => Date.today.end_of_year
        }).count

        # redirect_to home_page if current_user
    end

    def verify_authenticated
        redirect_to signin_path unless current_user
    end
end
