from fabric import task

from datetime import date
from sys import platform
import os, subprocess

BASE_PATH = os.path.dirname(__file__)
default_hosts = ["localhost"]

@task(hosts=default_hosts)
def usage(c):
    print("usage: fab make_note|publish_note|md2rst|rst2md")


@task(hosts=default_hosts)
def md2rst(c, src, dest=None):
    if not dest:
        dest = src[:-3] + ".rst";
    cmd = "pandoc --to RST --reference-links {} > {}".format(src, dest)
    c.local(cmd)

@task(hosts=default_hosts)
def rst2md(c, src, dest=None):
    if not dest:
        dest = src[:-4] + ".md";
    cmd = "pandoc {} -f rst -t markdown -o {}".format(src, dest)
    c.local(cmd)

@task(hosts=default_hosts)
def make_note(c):
    build_cmd = 'make clean html'
    c.local(build_cmd)

@task(hosts=default_hosts)
def publish_note(c):
    c.local("touch ./build/html/.nojekyll")
    c.local("git add source")
    c.local("git add -f build")
    c.local('git commit -m "update notes"')
    c.local("git subtree push --prefix build/html origin gh-pages")
