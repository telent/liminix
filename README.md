# Liminix

Līminis + Nix

* Līminis : Latin, genitive declension of limen. "Of the threshold"
* Nix :  a tool for reproducible and declarative configuration management
* Liminix : a Nix-based system for configuring consumer wifi routers

## What is this?

This is a reboot/restart of NixWRT: a Nix-based collection of software
tailored for domestic wifi router or IoT device devices, of the kind
that OpenWrt or DD-WRT or Gargoyle or Tomato run on.

This is not NixOS-on-your-router: it's aimed at devices that are
underpowered for the full NixOS experience.

## Running tests

Assuming you have nixpkgs checked out in a peer diretory of this one,

    NIX_PATH=nixpkgs=../nixpkgs:$NIX_PATH ./run-tests.sh
