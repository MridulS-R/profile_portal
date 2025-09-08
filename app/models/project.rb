
class Project < ApplicationRecord
  belongs_to :user
  validates :repo_full_name, presence: true, uniqueness: true
  serialize :topics, coder: JSON
end
