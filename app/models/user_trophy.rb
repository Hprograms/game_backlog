class UserTrophy < ApplicationRecord
  belongs_to :user
  belongs_to :trophy
end
