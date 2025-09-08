
class Domain < ApplicationRecord
  belongs_to :user
  validates :host, presence: true, uniqueness: true
end
