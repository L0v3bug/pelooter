use Socket;
use warnings;
use strict;

my $remote = '127.0.0.1';
my $port = 8100;
my $file_to_upload = $ARGV[0];

if (!defined($file_to_upload) || ! -e $file_to_upload) {
    print "Usage: uploader.sh <local-file-to-upload>\n";
    exit(1);
}

my $proto = getprotobyname('tcp');

my($sock);
socket($sock, AF_INET, SOCK_STREAM, $proto) 
	or exit(1);

my $iaddr = inet_aton($remote) 
	or exit(1);
my $paddr = sockaddr_in($port, $iaddr);

connect($sock , $paddr) 
	or exit(1);

open(my $fh, '<', $file_to_upload) or exit(1);

while(my $row = <$fh>){
    send($sock, $row, 0)
        or exit(1);
}

close($fh);

close($sock);
exit(0);