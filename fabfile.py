from fabric.api import *
from fabric.context_managers import *
from fabric.contrib.console import confirm
from datetime import date
from sys import platform
import os, subprocess

BASE_PATH = os.path.dirname(__file__)


@task
def usage():
    print("usage: fab make_note|publish_note")


@task
def md2rst(src, dest=None):
    if not dest:
        dest = src[:-3] + ".rst";
    cmd = "pandoc --to RST --reference-links {} > {}".format(src, dest)
    local(cmd)

@task
def rst2md(src, dest=None):
    if not dest:
        dest = src[:-4] + ".md";
    cmd = "pandoc {} -f rst -t markdown -o {}".format(src, dest)
    local(cmd)

@task
def make_note():
    build_cmd = 'make clean html'
    local(build_cmd)

@task
def publish_note():
    local("touch ./build/html/.nojekyll")
    local("git add source")
    local("git add -f build")
    local('git commit -m "update notes"')
    local("git subtree push --prefix ./build/html origin gh-pages")
