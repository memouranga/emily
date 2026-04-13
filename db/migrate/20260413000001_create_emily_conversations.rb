class CreateEmilyConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :emily_conversations do |t|
      t.string :session_id, null: false, index: true
      t.references :user, polymorphic: true, index: true # nil = visitor (sales), present = customer (support)
      t.string :status, default: "open", null: false     # open, resolved, escalated
      t.string :phase, default: "sales", null: false      # sales, support
      t.json :metadata                                     # location, page, referrer, etc.
      t.timestamps
    end
  end
end
