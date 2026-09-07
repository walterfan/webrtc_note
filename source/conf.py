# Configuration file for the Sphinx documentation builder.
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------

project = 'WebRTC 学习笔记'
copyright = '2021 ~ 2026, Walter Fan, Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License'
author = 'Walter Fan'
release = '3.0'
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

import os
import shutil

plantuml_cmd = os.environ.get('PLANTUML') or shutil.which('plantuml')
plantuml_jar = '/usr/local/bin/plantuml.jar'

if plantuml_cmd:
    plantuml = plantuml_cmd
elif shutil.which('java') and os.path.exists(plantuml_jar):
    plantuml = f'java -jar {plantuml_jar}'
else:
    plantuml = 'plantuml'

mermaid_version = "11"
# Default: mermaid.js in the browser (fast HTML builds).
# Set MERMAID_OUTPUT_FORMAT=svg|png to bake images via mermaid-cli (mmdc).
_mmdc = shutil.which("mmdc")
_fmt = os.environ.get("MERMAID_OUTPUT_FORMAT", "raw").lower()
if _mmdc and _fmt in ("svg", "png"):
    mermaid_cmd = _mmdc
    mermaid_output_format = _fmt
    mermaid_params = ["-b", "transparent"]
    _puppeteer_cfg = os.path.join(os.path.dirname(__file__), "..", "mermaid-puppeteer.json")
    if os.path.isfile(_puppeteer_cfg):
        mermaid_params += ["-p", _puppeteer_cfg]
else:
    mermaid_output_format = "raw"

templates_path = ['_templates']
exclude_patterns = ['_backup']

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
html_short_title = 'AV Handbook'

# -- Copy button configuration -----------------------------------------------

copybutton_prompt_text = r">>> |\.\.\. |\$ |> "
copybutton_prompt_is_regexp = True

def setup(app):
    app.add_css_file('custom.css')
