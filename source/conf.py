# Configuration file for the Sphinx documentation builder.
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------

project = 'WebRTC 学习笔记'
copyright = '2021 ~ 2026, Walter Fan, Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License'
author = 'Walter Fan'
release = '2.0'
language = 'zh_CN'

# -- General configuration ---------------------------------------------------

extensions = [
    'sphinx.ext.graphviz',
    'sphinx.ext.autodoc',
    'sphinx.ext.todo',
    'sphinx.ext.mathjax',
    'sphinxcontrib.plantuml',
    'sphinxcontrib.mermaid',
    'sphinx_copybutton',
]

plantuml = 'java -jar /usr/local/bin/plantuml.jar'
mermaid_version = "11"

templates_path = ['_templates']
exclude_patterns = []

# -- Options for HTML output -------------------------------------------------

html_theme = "sphinx_rtd_theme"
html_theme_path = ["_themes", ]
html_static_path = ['_static']

html_theme_options = {
    'navigation_depth': 3,
    'collapse_navigation': False,
    'sticky_navigation': True,
    'includehidden': True,
    'titles_only': False,
    'logo_only': False,
    'prev_next_buttons_location': 'both',
    'style_external_links': True,
}

html_show_sourcelink = False
html_title = 'WebRTC 学习笔记'
html_short_title = 'WebRTC Notes'

# -- Copy button configuration -----------------------------------------------

copybutton_prompt_text = r">>> |\.\.\. |\$ |> "
copybutton_prompt_is_regexp = True

def setup(app):
    app.add_css_file('custom.css')
