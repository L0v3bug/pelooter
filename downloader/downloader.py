import socket,sys,re
target_host = "127.0.0.1"
target_port = 80
if len(sys.argv) != 3:
    print("Usage: downloader.py <remote-file-to-download> <local-output-path>")
    sys.exit(1)
BUFF_SIZE = 4096
file_to_download = sys.argv[1]
output = sys.argv[2]
header = b''
data = b''
s=socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect((target_host,target_port))
request = "GET /%s HTTP/1.1\r\nHost:%s\r\n\r\n" % (file_to_download, target_host)
s.send(request.encode())
while True:
    partHeader = s.recv(BUFF_SIZE)
    header += partHeader
    if b'\r\n\r\n' in header:
        break
http_header = repr(header)
n = re.search('HTTP\/1\.0 (?P<status_code>[0-9]{3})', http_header)
if n:
    status_code = int(n.group("status_code"))
    if status_code != 200:
        s.close()
        sys.exit(1)
else:
    s.close()
    sys.exit(1)
m = re.search('Content-Length\: (?P<lenght>[0-9]+)', http_header)
if m:
    file_len = int(m.group("lenght"))
    while len(data) < file_len:
        part = s.recv(BUFF_SIZE)
        data += part
else:
    s.close()
    sys.exit(1)
s.close()
f=open(sys.argv[2], "wb")
f.write(data)
f.close()
sys.exit(0)