# frozen_string_literal: true

class AllowOwnerToBeBlank < ActiveRecord::Migration[6.0]
  def up
    change_column :things, :owner_id, :integer, null: true
  end

  def down
    change_column :things, :owner_id, :integer, null: false
  end
end
