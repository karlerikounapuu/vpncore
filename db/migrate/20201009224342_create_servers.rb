class CreateServers < ActiveRecord::Migration[6.0]
  def change
    create_table :servers do |t|
      t.string :name
      t.string :uuid
      t.string :ip_addr
      t.string :netmask
      t.integer :ovpn_port

      t.timestamps
    end
  end
end
