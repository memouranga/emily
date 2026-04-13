class CreateEmilyMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :emily_messages do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :emily_conversations }
      t.string :role, null: false   # user, assistant
      t.text :content, null: false
      t.timestamps
    end
  end
end
