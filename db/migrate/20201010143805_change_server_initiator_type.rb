class ChangeServerInitiatorType < ActiveRecord::Migration[6.0]
  def change
    remove_column :servers, :initiator
    add_column :servers, :initiator, :string
  end
end
