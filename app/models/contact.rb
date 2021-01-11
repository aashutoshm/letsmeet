class Contact < ApplicationRecord
    belongs_to :room

    validates :email, length: { maximum: 256 }, format: { with: /\A[\w+\-\'.]+@[a-z\d\-.]+\.[a-z]+\z/i }, presence: true
    validates :first_name, presence: true
    validates :last_name, presence: true
end