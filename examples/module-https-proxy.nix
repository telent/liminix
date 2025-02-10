# This is "contrib"-level code. This module solves a particular
# problem for my particular setup and is provided as is, as an example
# of how you might write something similar if you had a similar
# problem. Don't expect it to work unmolested in your setup (you will
# at the absolute minimum have to change the domain name), nor even to
# continue to exist without possibly being changed beyond recognition.

# The computers on my LAN have globally unique routable IPv6
# addresses, but I have only one public IPv4 address. I want to expose
# HTTPS services to the Internet _whatever_ machine is hosting them,
# so I publish an AAAA record to the machine itself, and an A record
# to the public v4 address of the router which is running this nginx.
# This nginx checks the SNI in the incoming connection and forwards
# the connection to the (IPv6 address of the) same hostname

# See https://ww.telent.net/2020/12/2/six_into_4_won_t_go for
# the original solution to this problem, which used sniproxy (now
# unmaintained) instead of nginx

{ config, pkgs, ... }:
let
  inherit (pkgs.liminix.services) longrun;
  inherit (pkgs) writeText;
  nginx_uid = 62;
in
{
  config = {
    users.nginx = {
      uid = nginx_uid;
      gid = nginx_uid;
      dir = "/run/";
      shell = "/bin/false";
    };
    groups.nginx = {
      gid = nginx_uid;
      usernames = [ "nginx" ];
    };

    services.sniproxy =
      let
        nginx = pkgs.nginx-small.override {
          pcre = null;
          zlib = null;
          options = [
            "stream"
            "stream_ssl_module"
            "stream_ssl_preread_module"
            "stream_map_module"
          ];
        };
        conf = writeText "nginx.conf" ''
          worker_processes auto;
          error_log /proc/self/fd/1 info;
          pid /dev/null;
          user nginx;
          daemon off;
          events {
              worker_connections 1024;
          }

          stream {
              log_format proxy '$remote_addr -> $ssl_target';
              access_log /proc/self/fd/1 proxy;
              map $ssl_preread_server_name $ssl_target {
                  hostnames;
                  .telent.net    $ssl_preread_server_name:443;
              }

              server {
                  listen 443;
                  resolver 127.0.0.1 ipv6=on ipv4=off;
                  resolver_timeout 1s;
                  proxy_pass $ssl_target;
                  ssl_preread on;
              }
          }
        '';
      in
      longrun {
        name = "sniproxy";
        run = ''
          ${nginx}/bin/nginx -c ${conf}
        '';
      };
  };
}
