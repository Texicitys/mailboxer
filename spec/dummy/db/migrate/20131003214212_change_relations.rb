class ChangeRelations < ActiveRecord::Migration

  def change
    rename_column :receipts, :notification_id, :message_id
  end
end