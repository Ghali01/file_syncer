import threading
from flutter_channel import Host
from flutter_channel.channels import MethodChannel
import os

from pyftpdlib.authorizers import DummyAuthorizer
from pyftpdlib.handlers import FTPHandler
from pyftpdlib.servers import FTPServer
import socket
server=None
def startFtpServer(host,port,directory,user,password):
    # Instantiate a dummy authorizer for managing 'virtual' users
    authorizer = DummyAuthorizer()

    # Define a new user having full r/w permissions and a read-only
    # anonymous user
    authorizer.add_user(user, password, directory, perm='elradfmwMT')
    # authorizer.add_anonymous(os.getcwd())

    # Instantiate FTP handler class
    handler = FTPHandler
    handler.authorizer = authorizer

    # Define a customized banner (string returned when client connects)
    handler.banner = "pyftpdlib based ftpd ready."

    # Specify a masquerade address and the range of ports to use for
    # passive connections.  Decomment in case you're behind a NAT.
    #handler.masquerade_address = '151.25.42.11'
    #handler.passive_ports = range(60000, 65535)

    # host=socket.gethostbyname(socket.gethostname())
    
    # Instantiate FTP server class and listen on 0.0.0.0:2121
    address = (host, port)
    global server
    server = FTPServer(address, handler)

    # set a limit for connections
    server.max_cons = 256
    server.max_cons_per_ip = 5

    # start ftp server
    server.serve_forever()
def stopFtpServer():
    if server:
        server.close_all()
def handler(call,reply):
    print(call.method)
    if call.method=='start':
        threading.Thread(target=startFtpServer,kwargs=call.args).start()
    elif call.method=='stop':
        stopFtpServer()
    reply.reply(None)
def main():
    host=Host()
    channel=MethodChannel('ftp')
    channel.setHandler(handler)
    host.bindChannel(channel)
    host.setOnDisconnect(stopFtpServer)
if __name__ == '__main__':
    main()