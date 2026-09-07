class ExerciseCompletion < ApplicationRecord
  belongs_to :user
  validates :exercise_key, presence: true, uniqueness: { scope: :user_id }
end
