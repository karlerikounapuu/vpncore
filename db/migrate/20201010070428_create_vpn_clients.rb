class CreateVpnClients < ActiveRecord::Migration[6.0]
  def change
    create_table :vpn_clients do |t|
      t.string :ident
      t.string :uuid

      t.timestamps
    end
  end
end
