class User < ApplicationRecord
  has_many :exercise_completions, dependent: :destroy

  def self.find_or_create_from_omniauth(auth)
    find_or_create_by!(github_id: auth.uid) do |user|
      user.username = auth.info.nickname
      user.avatar_url = auth.info.image
    end
  end
end
