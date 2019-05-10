#!/usr/bin/python
# based on https://www.redhat.com/en/blog/container-migration-around-world
import socket
import sys
import select
import time
import os
import shutil
import subprocess
import distutils.util

base_path = '/home/ubuntu/'
xfer_path = '/nfs/home/ubuntu/'

if len(sys.argv) < 2:
  print 'Usage: ' + sys.argv[0] + ' <container id> <dest>'
  sys.exit(1)

container = sys.argv[1]
dest = sys.argv[2]

container_path = base_path + container
xfer_container_path = xfer_path + container

def error():
  print 'Something did not work. Exiting!'
  sys.exit(1)

def real_dump():
  old_cwd = os.getcwd()
  os.chdir(container_path)
  # --tcp-established and --skip-in-flight already specified in the config file
  cmd = 'runc checkpoint ' + container
  start = time.time()
  print cmd
  p = subprocess.Popen(cmd, shell=True)
  ret = p.wait()
  end = time.time()
  print '%s: checkpoint finished after %.2f second(s) with %d' % (container, end - start, ret)
  os.chdir(old_cwd)
  if ret != 0:
    error()

def xfer_dump():
  cmd = 'cp -ruT %s %s' % (container_path, xfer_container_path)
  print 'Transferring DUMP to %s' % (xfer_container_path)
  start = time.time()
  ret = os.system(cmd)
  end = time.time()
  print 'DUMP transfer time %s seconds' % (end - start)
  if ret != 0:
    error()

def touch(fname):
  open(fname, 'a').close()

real_dump()
xfer_dump()

cs = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
cs.connect((dest, 8888))

input = [cs]

cs.send(
  '{ "restore" : { "path" : "' + base_path +
  '", "container" : "' + container + '" } }'
)

while True:
  inputready, outputready, exceptready = select.select(input,[],[], 5)

  if not inputready:
    break

  for s in inputready:
    answer = s.recv(1024)
    print answer

