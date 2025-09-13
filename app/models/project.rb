
class Project < ApplicationRecord
  belongs_to :user
  validates :repo_full_name, presence: true, uniqueness: { scope: :user_id }
  serialize :topics, coder: JSON
end
