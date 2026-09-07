class CreateExerciseCompletions < ActiveRecord::Migration[8.1]
  def change
    create_table :exercise_completions do |t|
      t.references :user, null: false, foreign_key: true
      t.string :exercise_key, null: false

      t.timestamps
    end
    add_index :exercise_completions, [ :user_id, :exercise_key ], unique: true
  end
end
