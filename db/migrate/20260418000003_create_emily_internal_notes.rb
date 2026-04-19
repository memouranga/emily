class CreateEmilyInternalNotes < ActiveRecord::Migration[7.1]
  def change
    create_table :emily_internal_notes do |t|
      t.references :ticket, null: false, foreign_key: { to_table: :emily_tickets }
      t.references :author, polymorphic: true, null: true, index: true
      t.text :body, null: false
      t.timestamps
    end
  end
end
