# OpenVPN REST API

Manage (CRUD) OpenVPN servers / clients over REST API. This POC project was created and presented in 48 hours, under project [Riigikaitse Häkaton](https://mil.ee/uudised/noored-insenerid-arendasid-programmeerimismaratonil-kaitsevaldkonna-kuberlahendusi/) of 2020 and is not maintained onwards.

## System dependencies
* Ruby 2.5.5 with bundler
* PostgreSQL database
* OpenVPN server

## Configuration
* Please take a look at config/application.yml to define OpenVPN internal paths.
* Please take a look at db/database.yml to define database connection

## Boot up
- Run bundle in root directory of project
- Run rails db:setup in root directory of project
- Run rails s to start the project at http://localhost:3000

## Runnings tests
![What tests](https://media.tenor.com/images/0b947c56571f6ab0cf219b763ec8fb0d/tenor.gif)

## API map

### GET /api/v1/servers/
Get all servers in openVPN config

### GET /api/v1/servers/1
Show server information for UUID 1

### GET /api/v1/servers/1/clients
Get all VPN clients of server

### GET /api/v1/servers/1/clients/1
Get all data about VPN server's specific client

### POST /api/v1/servers/
Create new server. 

### POST /api/v1/servers/1/clients
Create new client for server

### PUT api/v1/servers/1/start
Start openVPN server

### PUT api/v1/servers/1/stop
Stop openvVPN server

### GET api/v1/vpn_users/1/download_ovpn_profile
Download VPN client .ovpn profile
