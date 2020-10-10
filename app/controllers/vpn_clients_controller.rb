class VpnClientsController < ApplicationController
  before_action :set_vpn_client, only: [:show, :update, :destroy, :download_ovpn_config]

  # GET /vpn_clients
  def index
    @vpn_clients = VpnClient.all

    render json: @vpn_clients
  end

  def download_ovpn_config
    send_file(@vpn_client.ovpn_file_path)
  end

  # GET /vpn_clients/1
  def show
    render json: @vpn_client
  end

  # PATCH/PUT /vpn_clients/1
  def update
    if @vpn_client.update(vpn_client_params)
      render json: @vpn_client
    else
      render json: @vpn_client.errors, status: :unprocessable_entity
    end
  end

  # DELETE /vpn_clients/1
  def destroy
    @vpn_client.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_vpn_client
      @vpn_client = VpnClient.find_by!(uuid: params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def vpn_client_params
      params.require(:vpn_client).permit(:ident, :uuid)
    end
end
