import socket,sys,os
target_host = "127.0.0.1"
target_port = 8100
if len(sys.argv) != 2 or os.path.isfile(sys.argv[1]) == False:
    print("Usage: uploader.sh <local-file-to-upload>")
    sys.exit(1)
file_to_upload = sys.argv[1]
data = b''
s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((target_host,target_port))
f=open(file_to_upload, "rb")
data = f.read()
s.send(data.encode())
f.close()
s.close()
sys.exit(0)