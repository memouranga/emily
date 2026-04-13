class CreateEmilyTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :emily_tickets do |t|
      t.references :conversation, null: false, foreign_key: { to_table: :emily_conversations }
      t.string :subject, null: false
      t.text :summary              # AI-generated summary of the conversation
      t.string :status, default: "open", null: false  # open, in_progress, resolved, closed
      t.string :priority, default: "normal"           # low, normal, high, urgent
      t.timestamps
    end
  end
end
