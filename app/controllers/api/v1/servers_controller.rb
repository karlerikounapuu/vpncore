module Api
  module V1
    class ServersController < ApplicationController
      before_action :set_server_by_uuid, only: %i[show update destroy start stop add_client clients]

      # GET /servers
      def index
        if params[:ident].present?
          clients = VpnClient.where(ident: params[:ident])
          @servers = []
          clients.each do |c|
            server_obj = {
              uuid: c.server.uuid,
              name: c.name
            }

            @servers << server_obj unless @servers.include? server_obj
          end
          render(json: @servers)
        else
          @servers = Server.all
          render(json: @servers)
        end
      end

      # GET /servers/1
      def show
        render(json: s.as_presentable_json)
      end

      def start
        @server.start_server
        @server.reload

        render(json: {uuid: @server.uuid, status: @server.server_status})

      end

      def stop
        @server.stop_server
        @server.reload

        render(json: {uuid: @server.uuid, status: @server.server_status})
      end

      def add_client
        client = @server.vpn_clients.new(ident: client_params[:ident])

        if client.save
          render(json: {uuid: client.uuid, ovpn: "#{client.client_work_dir}/#{client.uuid}.ovpn"})
        else
          render(json: client.errors, status: :unprocessable_entity)
        end
      end

      def clients
        clients = @server.vpn_clients
        render(json: clients)
      end

      # POST /servers
      def create
        @server = Server.new(server_create_params)

        if @server.save
          render(json: @server.as_presentable_json, status: :created)
        else
          render(json: @server.errors, status: :unprocessable_entity)
        end
      end

      # PATCH/PUT /servers/1
      def update
        if @server.update(server_params)
          render(json: @server)
        else
          render(json: @server.errors, status: :unprocessable_entity)
        end
      end

      # DELETE /servers/1
      def destroy
        @server.destroy
      end

      private

      # Use callbacks to share common setup or constraints between actions.
      def set_server
        @server = Server.find(params[:id])
      end

      def set_server_by_uuid
        @server = Server.find_by!(uuid: params[:id])
      end

      def server_create_params
        params.require(:server).require([:name, :initiator])
        params.require(:server).permit(:name, :initiator)
      end
      # Only allow a trusted parameter "white list" through.
      def server_params
        params.require(:server).permit(:name)
      end

      def client_params
        params.require(:client).require(:ident)
        params.require(:client).permit(:ident)
      end
    end
  end
end