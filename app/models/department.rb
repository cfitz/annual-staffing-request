# A department within a library division
class Department < ActiveRecord::Base
  belongs_to :division
  validates :code, presence: true
  validates :name, presence: true
  validates :division_id, presence: true
end
