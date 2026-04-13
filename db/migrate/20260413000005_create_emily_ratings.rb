class CreateEmilyRatings < ActiveRecord::Migration[7.1]
  def change
    create_table :emily_ratings do |t|
      t.references :message, null: false, foreign_key: { to_table: :emily_messages }
      t.references :conversation, null: false, foreign_key: { to_table: :emily_conversations }
      t.integer :score, null: false  # 1 = thumbs down, 2 = thumbs up
      t.text :feedback               # optional text feedback
      t.timestamps
    end
  end
end
