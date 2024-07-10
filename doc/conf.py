# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'Liminix'
copyright = '2023-2024 Daniel Barlow'
author = 'Daniel Barlow'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
#    'sphinx.ext.autosectionlabel'
]
autosectionlabel_prefix_document = True

templates_path = ['_templates']
exclude_patterns = ['*.inc.rst', '_build', 'Thumbs.db', '.DS_Store']



# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'alabaster'
html_static_path = ['_static']

html_theme_options = {
    'logo': '/logo.svg',
    'globaltoc_collapse': 'false',
    'page_width': '90%',
    'body_max_width': '90%',
    'description': 'A Nix-based OpenWrt-style embedded Linux system for consumer wifi routers'
}
