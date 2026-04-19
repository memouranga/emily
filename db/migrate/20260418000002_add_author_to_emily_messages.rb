class AddAuthorToEmilyMessages < ActiveRecord::Migration[7.1]
  def change
    change_table :emily_messages do |t|
      t.references :author, polymorphic: true, index: true, null: true
    end
  end
end
