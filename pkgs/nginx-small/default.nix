# There is stuff in the nixpkgs nginx that's quite difficult to
# disable if you want the smallest possible nginx for a single use, so
# herewith a derivation that allows fine-grained control of all the
# --with and --without options. The patches are from nixpkgs (or from
# openwrt via nixpkgs, it looks like) and at least one of them is
# essential for making the package cross-compilable

{
  stdenv,
  openssl,
  fetchzip,
  fetchpatch,
  pcre,
  zlib,
  lib,
  options ? [ ],
}:
let
  # nginx configure script does not accept a with-foo_module flag for
  # a foo_module that's already included, nor a without-foo_module
  # for a module that isn't. Ho hum
  #  grep -E 'without.+\)' auto/options | sed -e 's/).*$//g' -e 's/.*--without-//g'
  defaultEnabled = [
    "select_module"
    "poll_module"
    "quic_bpf_module"
    "http"
    "http-cache"
    "http_charset_module"
    "http_gzip_module"
    "http_ssi_module"
    "http_userid_module"
    "http_access_module"
    "http_auth_basic_module"
    "http_mirror_module"
    "http_autoindex_module"
    "http_status_module"
    "http_geo_module"
    "http_map_module"
    "http_split_clients_module"
    "http_referer_module"
    "http_rewrite_module"
    "http_proxy_module"
    "http_fastcgi_module"
    "http_uwsgi_module"
    "http_scgi_module"
    "http_grpc_module"
    "http_memcached_module"
    "http_limit_conn_module"
    "http_limit_req_module"
    "http_empty_gif_module"
    "http_browser_module"
    "http_upstream_hash_module"
    "http_upstream_ip_hash_module"
    "http_upstream_least_conn_module"
    "http_upstream_random_module"
    "http_upstream_keepalive_module"
    "http_upstream_zone_module"
    "mail_pop3_module"
    "mail_imap_module"
    "mail_smtp_module"
    "stream_limit_conn_module"
    "stream_access_module"
    "stream_geo_module"
    "stream_map_module"
    "stream_split_clients_module"
    "stream_return_module"
    "stream_pass_module"
    "stream_set_module"
    "stream_upstream_hash_module"
    "stream_upstream_least_conn_module"
    "stream_upstream_random_module"
    "stream_upstream_zone_module"
    "pcre"
    "pcre2"
  ];
  # for each in defaultEnabled that are not in withFlags,
  # add a --without option
  # for each in withFlags that are not in defaultEnabled,
  # add a --with option
  withouts = lib.subtractLists options defaultEnabled;
  withs = lib.subtractLists defaultEnabled options;

in
stdenv.mkDerivation {
  pname = "nginx-small";
  version = "";
  buildInputs = [
    openssl
    pcre
    zlib
  ];
  configureFlags =
    (map (f: "--with-${f}") withs)
    ++ (map (f: "--without-${f}") withouts)
    ++ lib.optional (pcre == null) "--without-http_rewrite_module"
    ++ lib.optional (zlib == null) "--without-http_gzip_module";

  env.NIX_CFLAGS_COMPILE = "-Wno-error=cpp"; # musl

  configurePlatforms = [ ];
  patches = [
    (fetchpatch {
      url = "https://raw.githubusercontent.com/openwrt/packages/c057dfb09c7027287c7862afab965a4cd95293a3/net/nginx/patches/102-sizeof_test_fix.patch";
      sha256 = "0i2k30ac8d7inj9l6bl0684kjglam2f68z8lf3xggcc2i5wzhh8a";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/openwrt/packages/c057dfb09c7027287c7862afab965a4cd95293a3/net/nginx/patches/101-feature_test_fix.patch";
      sha256 = "0v6890a85aqmw60pgj3mm7g8nkaphgq65dj4v9c6h58wdsrc6f0y";
    })
    (fetchpatch {
      url = "https://raw.githubusercontent.com/openwrt/packages/c057dfb09c7027287c7862afab965a4cd95293a3/net/nginx/patches/103-sys_nerr.patch";
      sha256 = "0s497x6mkz947aw29wdy073k8dyjq8j99lax1a1mzpikzr4rxlmd";
    })
  ];

  src = fetchzip {
    url = "https://nginx.org/download/nginx-1.26.2.tar.gz";
    hash = "sha256-CQbvqISgca+LBpmTUuF8IuJZC9GNn8kT0hQwzfz+wH8=";
  };
}
