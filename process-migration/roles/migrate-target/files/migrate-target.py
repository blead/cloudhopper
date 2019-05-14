#!/usr/bin/python
# based on https://www.redhat.com/en/blog/container-migration-around-world
import socket
import sys
from thread import *
import json
import os
import distutils.util
import subprocess

HOST = ''   # Symbolic name meaning all available interfaces
PORT = 8888 # Arbitrary non-privileged port

if len(sys.argv) < 2:
  print 'Usage: ' + sys.argv[0] + ' <source>'
  sys.exit(1)

source_addr = sys.argv[1]

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print 'Socket created'

#Bind socket to local host and port
try:
  s.bind((HOST, PORT))
except socket.error as msg:
  print 'Bind failed. Error Code : ' + str(msg[0]) + ' Message ' + msg[1]
  sys.exit()

print 'Socket bind complete'

#Start listening on socket
s.listen(10)
print 'Socket now listening'

#Function for handling connections. This will be used to create threads
def clientthread(conn, addr):
  #Sending message to connected client

  #infinite loop so that function do not terminate and thread do not end.
  while True:

    reply = ""
    #Receiving from client
    data = conn.recv(1024)
    if not data:
      break
    if data == 'exit':
      break

    try:
      msg = json.loads(data)
      if 'restore' in msg:
        try:
          lazy = bool(distutils.util.strtobool(msg['restore']['lazy']))
        except:
          lazy = False
        old_cwd = os.getcwd()
        container_path = msg['restore']['path'] + msg['restore']['container']
        image_path = container_path + '/checkpoint'
        os.chdir(container_path)
        cmd = 'runc restore -d --image-path' + image_path + ' --work-path ' + image_path
        if lazy:
          cmd += ' --lazy-pages'
        cmd += ' ' + msg['restore']['container']
        print "Running " +  cmd
        p = subprocess.Popen(cmd, shell=True)
        if lazy:
          cmd = "criu lazy-pages --page-server --address " + source_addr
          cmd += " --port " + msg['restore']['port']
          cmd += " -D " + image_path
          cmd += " -W " + image_path
          print "Running lazy-pages server: " + cmd
          lp = subprocess.Popen(cmd, shell=True)
        ret = p.wait()
        if ret == 0:
          reply = "runc restored %s successfully" % msg['restore']['container']
        else:
          reply = "runc failed(%d)" % ret
        os.chdir(old_cwd)
      else:
        print "Unknown request : " + msg
    except:
      continue

    print reply
    conn.sendall(reply)

  #came out of loop
  conn.close()

#now keep talking with the client
while 1:
  #wait to accept a connection - blocking call
  conn, addr = s.accept()
  print 'Connected with ' + addr[0] + ':' + str(addr[1])

  #start new thread takes 1st argument as a function name to be run, second is the tuple of arguments to the function.
  start_new_thread(clientthread, (conn, str(addr[0]),))

s.close()
