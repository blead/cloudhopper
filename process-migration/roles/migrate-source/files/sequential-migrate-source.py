#!/usr/bin/python
# based on https://www.redhat.com/en/blog/container-migration-around-world
import socket
import sys
import select
import time
import os
import subprocess
import re
import distutils.util

base_path = '/home/ubuntu/'
precopy_dir = 'predump'
precopy_relative_path = '../' + precopy_dir
precopy_enabled = False
postcopy_enabled = False
postcopy_port_start = 8027
postcopy_pipe_prefix = '/tmp/postcopy-pipe-'
target_port = 8888

if len(sys.argv) < 3:
  print 'Usage: ' + sys.argv[0] + ' <container1>[,<containers2>,...] <target-address> [pre-copy] [post-copy] [post-copy-port-start]'
  sys.exit(1)

containers = sys.argv[1].split(',')
target_address = sys.argv[2]
if len(sys.argv) > 3:
  precopy_enabled = distutils.util.strtobool(sys.argv[3])
if len(sys.argv) > 4:
  postcopy_enabled = distutils.util.strtobool(sys.argv[4])
if len(sys.argv) > 5:
  postcopy_port_start = int(sys.argv[5])
postcopy_ports = [postcopy_port_start + i for i in xrange(len(containers))]

def error(error):
  print 'Error: ' + error
  if error:
    print error
  sys.exit(1)

def predump(container):
  container_path = base_path + container
  old_cwd = os.getcwd()
  os.chdir(container_path)
  cmd = 'runc checkpoint --pre-dump --image-path ' + precopy_dir + ' ' + container
  start = time.time()
  process = subprocess.Popen(cmd, shell=True)
  ret = process.wait()
  end = time.time()
  print '%s: predump finished after %.2f second(s) with exit code %d' % (container, end - start, ret)
  eval_process = subprocess.Popen('du -sh ' + container_path + '/' + precopy_dir, shell=True, stdout=subprocess.PIPE)
  size, stderr = eval_process.communicate()
  print '%s: predump size %s' % (container, size)
  os.chdir(old_cwd)
  if ret != 0 or stderr:
    error(container + ' predump failed.')

def checkpoint(container, postcopy_port):
  container_path = base_path + container
  postcopy_pipe_path = postcopy_pipe_prefix + container
  old_cwd = os.getcwd()
  os.chdir(container_path)
  cmd = 'runc checkpoint'
  if precopy_enabled:
    cmd += ' --parent-path ' + precopy_relative_path
  if postcopy_enabled:
    cmd += ' --lazy-pages --page-server localhost:' + str(postcopy_port)
    try:
      os.unlink(postcopy_pipe_path)
    except:
      pass
    os.mkfifo(postcopy_pipe_path)
    cmd += ' --status-fd ' + postcopy_pipe_path
  cmd += ' ' + container
  start = time.time()
  process = subprocess.Popen(cmd, shell=True)
  if postcopy_enabled:
    pipe = os.open(postcopy_pipe_path, os.O_RDONLY)
    ret = os.read(pipe, 1)
    if ret == '\0':
      print container + ': ready for lazy page transfer'
    ret = 0
  else:
    ret = process.wait()
  end = time.time()
  print '%s: checkpoint finished after %.2f second(s) with exit code %d' % (container, end - start, ret)
  eval_process = subprocess.Popen('du -sh ' + container_path + '/checkpoint', shell=True, stdout=subprocess.PIPE)
  size, stderr = eval_process.communicate()
  print '%s: checkpoint size %s' % (container, size)
  os.chdir(old_cwd)
  if ret != 0 or stderr:
    error(container + ' checkpoint failed.')

def transfer(container):
  container_path = base_path + container
  eval_process = subprocess.Popen('du -sh ' + container_path, shell=True, stdout=subprocess.PIPE)
  size, stderr = eval_process.communicate()
  print '%s: total size (container + predump) %s' % (container, size)
  cmd = 'rsync -aqz %s %s::home' % (container_path, target_address)
  print '%s: transferring predump to %s::%s' % (container, target_address, container_path)
  start = time.time()
  process = subprocess.Popen(cmd, shell=True)
  ret = process.wait()
  end = time.time()
  print '%s: predump transfer time %.2f seconds' % (container, end - start)
  if ret != 0 or stderr:
    error(container + ' transfer failed.')

def calculate_size(container):
  container_path = base_path + container
  cmd = 'rsync -az --dry-run --stats %s %s::home' % (container_path, target_address)
  print container + ': evaluating checkpoint transfer size'
  process = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
  ret, stderr = process.communicate()
  match = re.search('Total transferred file size: ([\d,]+) bytes', ret)
  if match == None or stderr:
    error(container + ' size calculation failed.')
  size = int(match.group(1).replace(',', ''))
  print '%s: total checkpoint transfer size %d bytes' % (container, size)
  return size

def checkpoint_transfer(container):
  container_path = base_path + container
  eval_process = subprocess.Popen('du -sh ' + container_path, shell=True, stdout=subprocess.PIPE)
  size, stderr = eval_process.communicate()
  print '%s: total size (container + predump + checkpoint) %s' % (container, size)
  cmd = 'rsync -aqz %s %s::home' % (container_path, target_address)
  print '%s: transferring checkpoint to %s::%s' % (container, target_address, container_path)
  start = time.time()
  process = subprocess.Popen(cmd, shell=True)
  ret = process.wait()
  end = time.time()
  print '%s: checkpoint transfer time %.2f seconds' % (container, end - start)
  if ret != 0 or stderr:
    error(container + ' transfer failed.')

def notify(container, postcopy_port):
  cs = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
  cs.connect((target_address, target_port))
  input = [cs]
  cs.send(
    '{ "restore" : { "path" : "' + base_path +
    '", "container" : "' + container +
    '", "lazy" : "' + str(postcopy_enabled) +
    '", "port" : "' + str(postcopy_port) + '" } }'
  )
  while True:
    inputready, outputready, exceptready = select.select(input,[],[], 5)
    if not inputready:
      break
    for s in inputready:
      answer = s.recv(1024)
      print container + ': ' + answer

if precopy_enabled:
  print 'PREDUMP'
  for container in containers:
    predump(container)
  print 'PREDUMP TRANSFER'
  for container in containers:
    transfer(container)

print 'CHECKPOINT'
downtime_start = time.time()
## Start our dummy server here
subprocess.call('echo "enable server back1/redir" | \
  socat unix-connect:/var/run/haproxy/admin.sock stdio', shell=True)
subprocess.call('echo "disable server back1/source" | \
  socat unix-connect:/var/run/haproxy/admin.sock stdio', shell=True)
##
for (container, postcopy_port) in zip(containers, postcopy_ports):
  checkpoint(container, postcopy_port)

# Not needed
# print 'CALCULATE'
# container_sizes = [calculate_size(container) for container in containers]
# transfer_tasks = list(reversed(sorted(zip(containers, container_sizes), key=lambda x: x[1])))

print 'CHECKPOINT TRANSFER'
checkpoint_transfer_start = time.time()
for container in containers:
  checkpoint_transfer(container)
checkpoint_transfer_end = time.time()
print 'Total checkpoint transfer time: %.2f second(s)' % (checkpoint_transfer_end - checkpoint_transfer_start)

print 'NOTIFY'
for (container, postcopy_port) in zip(containers, postcopy_ports):
  notify(container, postcopy_port)
downtime_end = time.time()
print 'Total downtime: %.2f second(s)' % (downtime_end - downtime_start)
