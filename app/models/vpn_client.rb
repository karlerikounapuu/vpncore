class VpnClient < ApplicationRecord
  belongs_to :server

  validates :ident, presence: true
  validates :uuid, presence: true
  before_validation :generate_uuid
  after_destroy :delete_client_configuration
  after_create :generate_ovpn_configuration

  def generate_ovpn_configuration
    create_client_work_dir
    generate_client_keys
    initialize_client_keys
  end

  def generate_ovpn_file
    Dir.chdir(client_work_dir) do
      config_file = "#{uuid}.ovpn"
      File.open(config_file, 'a') do |f|
        f.puts 'client'
        f.puts 'dev tun'
        f.puts 'proto udp'
        f.puts "remote #{ENV['server_addr']} #{server.ovpn_port}"
        f.puts 'cipher AES-256-CBC'
        f.puts 'auth SHA512'
        f.puts 'auth-nocache'
        f.puts 'tls-version-min 1.2'
        f.puts 'tls-cipher TLS-DHE-RSA-WITH-AES-256-GCM-SHA384:TLS-DHE-RSA-WITH-AES-256-CBC-SHA256:TLS-DHE-RSA-WITH-AES-128-GCM-SHA256:TLS-DHE-RSA-WITH-AES-128-CBC-SHA256'
        f.puts 'resolv-retry infinite'
        f.puts 'nobind'
        f.puts 'persist-key'
        f.puts 'persist-tun'
        f.puts 'mute-replay-warnings'
        f.puts 'verb 3'
        f.puts '<ca>'
        f.puts ovpn_ca
        f.puts '</ca>'
        f.puts '<cert>'
        f.puts ovpn_cert
        f.puts '</cert>'
        f.puts '<key>'
        f.puts ovpn_key
        f.puts '</key>'
      end
    end

    Rails.logger.info("Successfully generate OVPN for VpnClient (UUID) #{uuid}")
  end

  def initialize_client_keys
    Dir.chdir(server.easyrsa_work_dir) do
      %x(`cp pki/ca.crt #{client_work_dir}/`)
      %x(`cp pki/issued/#{uuid}.crt #{client_work_dir}/`)
      %x(`cp pki/private/#{uuid}.key #{client_work_dir}/`)
    end
  end

  def generate_client_keys
    Dir.chdir(server.easyrsa_work_dir) do
      %x(`EASYRSA_BATCH=1 ./easyrsa gen-req #{uuid} nopass`)
      %x(`EASYRSA_BATCH=1 ./easyrsa sign-req client #{uuid}`)
    end
  end

  def create_client_work_dir
    %x(`mkdir #{client_work_dir}`)
  end

  def client_work_dir
    server_work_dir = server.server_work_dir
    "#{server_work_dir}/clients/#{uuid}"
  end

  def delete_client_configuration
    %x(`rm -rf #{client_work_dir}`)
  end

  def ovpn_ca
    data = OpenSSL::X509::Certificate.new(File.read("#{client_work_dir}/ca.crt"))
    data.to_s
  end

  def ovpn_key
    File.read("#{client_work_dir}/#{uuid}.key")
  end

  def ovpn_cert
    data = OpenSSL::X509::Certificate.new(File.read("#{client_work_dir}/#{uuid}.crt"))
    data.to_s
  end

  def generate_uuid
    return unless uuid.nil?

    new_uuid = SecureRandom.hex.to_s
    self.uuid = new_uuid
  end
end
