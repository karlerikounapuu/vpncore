class AddServerIdToVpnClient < ActiveRecord::Migration[6.0]
  def change
    add_reference :vpn_clients, :server, index: true
  end
end
