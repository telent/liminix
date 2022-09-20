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

Assuming you have nixpkgs checked out in a peer directory of this one,

    NIX_PATH=nixpkgs=../nixpkgs:$NIX_PATH ./run-tests.sh



## Articles of interest

* [Build Safety of Software in 28 Popular Home Routers](https://cyber-itl.org/assets/papers/2018/build_safety_of_software_in_28_popular_home_routers.pdf):
   "of the access points and routers we reviewed, not a single one
took full advantage of the basic application armoring features
provided by the operating system. Indeed, only one or two models even
came close, and no brand did well consistently across all models
tested"
