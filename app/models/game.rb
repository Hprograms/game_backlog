class Game < ApplicationRecord
  belongs_to :user

  has_one_attached :image

  validates :title, presence: true
  validates :status, inclusion: { in: %w[未着手 プレイ中 クリア済] }
  validates :rating, numericality: { in: 1..5 }, allow_nil: true
end