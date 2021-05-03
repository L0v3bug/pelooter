use Socket;
use warnings;
use strict;

my $remote = '127.0.0.1';
my $port = 80;

if ($#ARGV != 1) {
    print "Usage: downloader.py <remote-file-to-download> <local-output-path>\n";
    exit(1);
}

my $buff_size = 4096;
my $proto = getprotobyname('tcp');
my $file_to_download = $ARGV[0];
my $output = $ARGV[1];

my($sock);
socket($sock, AF_INET, SOCK_STREAM, $proto) 
	or exit(1);

my $iaddr = inet_aton($remote) 
	or exit(1);
my $paddr = sockaddr_in($port, $iaddr);

connect($sock , $paddr) 
	or exit(1);

my $req = sprintf("GET /%s HTTP/1.1\r\nHost:%s\r\n\r\n", $file_to_download, $remote);
send($sock, $req, 0) 
	or exit(1);

my $content = "";
my $content_length = 0;
my $line_count = 0;
my $is_content = 0;
while (my $line = <$sock>) 
{
    $line_count += 1;
    if ($line_count > 7) {
        $content .= $line;
        next;
    }

    if ($line =~ m/HTTP\/1\.0 (?<status_code>[0-9]{3})/) {
        if ($+{status_code} != 200) {
            exit(1);
        }
        next;
    }

    if ($line =~ m/Content-Length\: (?<lenght>[0-9]+)/) {
        $content_length = $+{lenght};
        next;
    }
}

if (length($content) != $content_length) {
    exit(1);
}

open(FH, '>', $output) or exit(1);
print FH $content;

close(FH);
close($sock);
exit(0);