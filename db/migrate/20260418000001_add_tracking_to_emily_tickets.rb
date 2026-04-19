class AddTrackingToEmilyTickets < ActiveRecord::Migration[7.1]
  def change
    change_table :emily_tickets do |t|
      t.references :assignee, polymorphic: true, index: true, null: true
      t.references :resolved_by, polymorphic: true, index: true, null: true
      t.datetime :first_response_at
      t.datetime :resolved_at
    end

    add_index :emily_tickets, [:status, :assignee_id]
  end
end
