class ContactsController < ApplicationController
    include Pagy::Backend

    before_action :verify_authenticated
    before_action :verify_contact_owner_valid, only: [:edit, :update, :destroy]

    layout "default"

    # GET /contacts
    def index
        contacts = Contact.where("user_id = :user_id AND (first_name ILIKE :keyword OR last_name ILIKE :keyword OR email ILIKE :keyword)", {
            :user_id => current_user.id,
            :keyword => "%#{params[:keyword]}%"
        })
        @pagy, @contacts = pagy_array(contacts, page: params[:page], items: 12)
    end

    # GET /contacts/ajax
    def ajax
        contacts = Contact.where("user_id = :user_id AND (first_name ILIKE :keyword OR last_name ILIKE :keyword OR email ILIKE :keyword)", {
            :user_id => current_user.id,
            :keyword => "%#{params[:keyword]}%"
        })
        render json: contacts
    end

    def ajax_new
        email = params[:email]
        contact = Contact.where("user_id = :user_id AND email = :email", {
            :user_id => current_user.id,
            :email => email
        }).first
        if contact
            render json: contact
        else
            contact = Contact.new(
                user_id: current_user.id,
                email: email,
                first_name: '',
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

    # GET /contacts/create
    def new
        @contact = Contact.new
    end

    # POST /contacts/create
    def create
        uploaded_io = params[:contact][:image]
        image_param = nil
        if uploaded_io != nil
            extname = File.extname(uploaded_io.original_filename)
            filename = generate_code(32)
            full_filename = filename + extname
            File.open(Rails.root.join('public', 'uploads/avatar', full_filename), 'wb') do |file|
                file.write(uploaded_io.read)
            end
            image_param = request.base_url + '/uploads/avatar/' + full_filename
        end
        @contact = Contact.new(
            user_id: current_user.id,
            first_name: params[:contact][:first_name],
            last_name: params[:contact][:last_name],
            email: params[:contact][:email],
            company: params[:contact][:company],
            department: params[:contact][:department],
            phone1: params[:contact][:phone1],
            code1: params[:contact][:code1],
            phone2: params[:contact][:phone2],
            code2: params[:contact][:code2],
            notes: params[:contact][:notes],
            custom_field1: params[:contact][:custom_field1],
            custom_field2: params[:contact][:custom_field2],
            image: image_param
        )
        if @contact.save
            redirect_to contacts_path, flash: { success: "New contact has been added." }
        else
            render :new
        end
    end

    # GET /contacts/:id/edit
    def edit
    end

    # PUT /contacts/:id/edit
    def update
        form_data = contact_params
        uploaded_io = form_data[:image]
        if uploaded_io != nil
            extname = File.extname(uploaded_io.original_filename)
            filename = generate_code(32)
            full_filename = filename + extname
            File.open(Rails.root.join('public', 'uploads/avatar', full_filename), 'wb') do |file|
                file.write(uploaded_io.read)
            end
            form_data[:image] = request.base_url + '/uploads/avatar/' + full_filename
        end
        if @contact.update(form_data)
            redirect_to contacts_path, flash: { success: "Information successfully updated." }
        else
            render :edit
        end
    end

    # DELETE /contacts/:id
    def destroy
        @contact.destroy

        redirect_to contacts_path
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
            :code1,
            :code2,
            :notes,
            :custom_field1,
            :custom_field2,
            :image
        )
    end

    private

    def verify_authenticated
        redirect_to root_path unless current_user
    end

    def verify_contact_owner_valid
        @contact = Contact.find_by(id: params[:id])
        redirect_to root_path if @contact.user_id != current_user.id
    end
end
