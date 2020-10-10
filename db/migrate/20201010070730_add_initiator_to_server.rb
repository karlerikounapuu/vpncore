class AddInitiatorToServer < ActiveRecord::Migration[6.0]
  def change
    add_column :servers, :initiator, :integer
  end
end
