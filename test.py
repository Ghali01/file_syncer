import socket
import time
soc=socket.socket(socket.AF_INET,socket.SOCK_STREAM)
soc.connect(('127.0.0.1',48510))
soc.send(bytes([1]))

print(soc.recv(1024))
soc.send(bytes([2,*'ghale'.encode()]))
time.sleep(5)
# soc.send(bytes([5,*'{}'.encode('utf-8'),0,0,0]))