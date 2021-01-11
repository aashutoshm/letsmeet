class ContactsController < ApplicationController
    include Pagy::Backend

    layout "default"

    # GET /:room_id/contacts
    def index
        contacts = Contact.where("room_id = :room_id AND (first_name LIKE :keyword OR last_name LIKE :keyword OR email LIKE :keyword)", {
            :room_id => current_user.main_room.id,
            :keyword => "%#{params[:keyword]}%"
        })
        @pagy, @contacts = pagy_array(contacts, page: params[:page], items: 12)
    end

    # GET /:room_id/contacts/new
    def new
        @contact = Contact.new
    end

    # POST /:room_id/contacts
    def create
        @contact = Contact.new(
            room_id: current_user.main_room.id,
            first_name: params[:contact][:first_name],
            last_name: params[:contact][:last_name],
            email: params[:contact][:email],
            company: params[:contact][:company],
            department: params[:contact][:department],
            phone1: params[:contact][:phone1],
            phone2: params[:contact][:phone2],
            notes: params[:contact][:notes],
            custom_field1: params[:contact][:custom_field1],
            custom_field2: params[:contact][:custom_field2],
        )
        if @contact.save
            redirect_to contacts_path(current_user.main_room), flash: { success: "New contact has been added." }
        else
            render :new
        end
    end

    # GET /:room_id/contacts/:id/edit
    def edit
        @contact = Contact.find_by(id: params[:id])
    end

    # PUT /:room_id/contacts/:id
    def update
        @contact = Contact.find_by(id: params[:id])
        if @contact.update(contact_params)
            redirect_to contacts_path(current_user.main_room), flash: { success: "Information successfully updated." }
        else
            render :edit
        end
    end

    def contact_params
        params.require(:contact).permit(
            :first_name,
            :last_name,
            :email,
            :company,
            :department,
            :phone1,
            :phone2,
            :notes,
            :custom_field1,
            :custom_field2
        )
    end
end
