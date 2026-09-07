class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :github_id
      t.string :username
      t.string :avatar_url

      t.timestamps
    end
    add_index :users, :github_id, unique: true
  end
end
