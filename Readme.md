## Description

Simple scripts to configure a wireguard vpn server (Ubuntu 22.04) and to generate the config file of the clients.


1- Copy ad run the first script in the server

```
sudo chmod +x create_wg_server_conf.sh
sudo ./create_wg_server_conf.sh
```
This will generate the `/etc/wireguard/wg0.conf`.


2- Copy and run the second script to generate `client-wg0.conf` to use to configure the client machine.
```
sudo chmod +x add_wg_client.sh
sudo ./add_wg_client.sh
```

This will:
    - generate `client-wg0.conf` that can be used to configure a client machine.
    - update the `/etc/wireguard/wg0.conf` of the wg server.

