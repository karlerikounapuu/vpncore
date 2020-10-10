module Api
  module V1
    class ServersController < ApplicationController
      before_action :set_server, only: %i[show update destroy]

      # GET /servers
      def index
        @servers = Server.all
        servers = []
        @servers.each do |s|
          servers << s.as_presentable_json
        end

        render(json: servers)
      end

      # GET /servers/1
      def show
        render(json: @server)
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

      def server_create_params
        params.require(:server).require([:name, :initiator])
        params.require(:server).permit(:name, :initiator)
      end
      # Only allow a trusted parameter "white list" through.
      def server_params
        params.require(:server).permit(:name)
      end
    end
  end
end