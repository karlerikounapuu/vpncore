require 'open3'

class Server < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  before_validation :generate_uuid
  before_validation :assign_port_and_subnet
  has_many :vpn_clients, dependent: :destroy

  after_destroy :destroy_assigned_configurations

  after_create :initialize_openvpn_config
  after_create :create_primary_openvpn_client

  def start_server
    stdout, stderr, status = Open3.capture3("systemctl start openvpn@#{uuid}.service")
    server_status
  end

  def stop_server
    stdout, stderr, status = Open3.capture3("systemctl stop openvpn@#{uuid}.service")
    server_status
  end

  def server_status
    stdout, stderr, status = Open3.capture3("systemctl status openvpn@#{uuid}.service")
    return 'running' if stdout.include? 'active (running)'
    return 'stopped' if stdout.include? 'inactive (dead)'
    return 'reloading' if stdout.include? 'activating (auto-restart)'

    return 'error'
  end

  def initiator_client
    vpn_clients.find_by(ident: initiator)
  end

  def as_presentable_json
    {
      uuid: uuid,
      name: name,
      state: server_status,
      initiator: initiator_client.present? ? initiator_client.uuid : nil,
      clients: clients_as_presentable_json,
      connector: {
        hostname: ENV['server_addr'],
        port: ovpn_port
      },
      internal: {
        addr: {
          ip_addr: ip_addr,
          netmask: netmask
        },
        config: {
          server_base_path: server_work_dir,
          server_initializer: "#{ENV['openvpn_base_path']}/#{uuid}.conf"
        }
      }
    }
  end

  def clients_as_presentable_json
    fucked = []
    vpn_clients.each do |client|
      body = {uuid: client.uuid, ovpn: "#{client.client_work_dir}/#{client.uuid}.ovpn"}
      fucked << body
    end

    fucked
  end

  def destroy_assigned_configurations
    stop_server
    %x(`rm -rf #{server_work_dir}`)
    Rails.logger.info("Deleted configuration from #{server_work_dir}")

    %x(`rm #{ENV['openvpn_base_path']}/#{uuid}.conf`)
    Rails.logger.info("Deleted server init file #{ENV['openvpn_base_path']}/#{uuid}.conf")
  end

  def create_primary_openvpn_client
    client = vpn_clients.new(ident: initiator)
    client.save
  end

  def initialize_openvpn_config
    initialize_skeleton
    Rails.logger.info("Assets copied over for server (UUID) #{uuid}")
    generate_server_ca
    Rails.logger.info("Initialized CA for server (UUID) #{uuid}")
    copy_server_ca
    Rails.logger.info("Mounted CA files for server (UUID) #{uuid}")
    compose_server_config
    Rails.logger.info("Composed server.conf for server (UUID) #{uuid}")
    initialize_server_config
  end

  def assign_port_and_subnet
    return if ovpn_port && ip_addr

    unused_port = Server.unused_port
    self.ovpn_port = unused_port
    unused_sub = Server.unused_ip_subnet
    self.ip_addr = unused_sub
    self.netmask = '255.255.255.0'
    Rails.logger.info("Assigning ip_addr #{ip_addr}/24 at port #{ovpn_port} to server (UUID) #{uuid}")
  end

  def initialize_server_config
    config_file = "#{server_work_dir}/#{uuid}.conf"
    %x(`cp #{config_file} #{ENV['openvpn_base_path']}/#{uuid}.conf`)
    Rails.logger.info("Initialized config file for (UUID) #{uuid} to #{ENV['openvpn_base_path']}/#{uuid}.conf")
  end

  def compose_server_config
    config_file = "#{server_work_dir}/#{uuid}.conf"
    File.open(config_file, 'a') do |f|
      f.puts 'local 0.0.0.0'
      f.puts "port #{ovpn_port}"
      f.puts "server #{ip_addr} 255.255.255.0"
      f.puts 'proto udp'
      f.puts 'dev tun'
      f.puts "ca #{server_work_dir}/server/ca.crt"
      f.puts "cert #{server_work_dir}/server/#{uuid}-server.crt"
      f.puts "key #{server_work_dir}/server/#{uuid}-server.key"
      f.puts "dh #{server_work_dir}/server/dh.pem"

      f.puts 'push "redirect-gateway def1 bypass-dhcp"'
      f.puts 'push "dhcp-option DNS 1.1.1.1"'
      f.puts 'push "dhcp-option DNS 1.0.0.1"'
      f.puts 'cipher AES-256-CBC'
      f.puts 'tls-version-min 1.2'
      f.puts 'tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256'
      f.puts 'auth SHA512'
      f.puts 'auth-nocache'
      f.puts "log-append /var/log/openvpn/#{uuid}-openvpn.log"
      f.puts "status /var/log/openvpn/#{uuid}-openvpn-status.log"
      f.puts 'verb 6'
      f.puts 'keepalive 20 60'
      f.puts 'persist-key'
      f.puts 'persist-tun'
      f.puts 'daemon'
      f.puts 'user nobody'
      f.puts 'group nogroup'
    end
  end

  def initialize_skeleton
    return unless uuid

    skeleton = ENV['openvpn_server_skeleton']
    FileUtils.cp_r("#{skeleton}/.", server_work_dir, verbose: true)
  end

  def generate_server_ca
    Dir.chdir(easyrsa_work_dir) do
      %x(`dd if=/dev/urandom of=pki/.rnd bs=256 count=1`)
      %x(`EASYRSA_BATCH=1 ./easyrsa build-ca nopass`)
      %x(`EASYRSA_BATCH=1 ./easyrsa gen-req #{uuid}-server nopass`)
      %x(`EASYRSA_BATCH=1 ./easyrsa sign-req server #{uuid}-server`)
    end
  end

  def copy_server_ca
    Dir.chdir(easyrsa_work_dir) do
      %x(`cp pki/ca.crt #{server_work_dir}/server/`)
      %x(`cp pki/issued/#{uuid}-server.crt #{server_work_dir}/server/`)
      %x(`cp pki/private/#{uuid}-server.key #{server_work_dir}/server/`)
      %x(`cp pki/dh.pem #{server_work_dir}/server/`)
    end
  end

  def server_work_dir
    return unless uuid

    "#{ENV['openvpn_servers_path']}/#{uuid}"
  end

  def self.unused_port
    latest_port = nil
    Server.all.each do |s|
      next unless s.ovpn_port

      latest_port = s.ovpn_port if latest_port.nil?
      latest_port = s.ovpn_port if s.ovpn_port > latest_port
    end

    latest_port.nil? ? 1150 : (latest_port + 1)
  end

  def self.unused_ip_subnet
    latest_subnet = nil
    Server.all.each do |s|
      next unless s.ip_addr

      subn = s.ip_addr.split('.')[2]
      latest_subnet = subn.to_i if latest_subnet.nil?
      latest_subnet = subn.to_i if subn.to_i > latest_subnet.to_i
    end

    if latest_subnet.nil?
      '10.1.1.0'
    else
      "10.1.#{latest_subnet.to_i + 1}.0"
    end
  end

  def easyrsa_work_dir
    "#{server_work_dir}/easy-rsa"
  end

  def validate_server_path
    return unless server_path_exist?

    errors.add(:uuid, 'Path already exists for this uuid')
  end

  def server_path_exist?
    path = "#{ENV['openvpn_servers_path']}/#{uuid}"
    File.directory?(path)
  end

  def generate_uuid
    return unless uuid.nil?

    new_uuid = SecureRandom.hex.to_s
    self.uuid = new_uuid
  end
end
