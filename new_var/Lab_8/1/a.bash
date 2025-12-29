sudo sysctl -w net.ipv4.tcp_tw_reuse=1
sudo sysctl -w net.ipv4.tcp_fin_timeout=30

fasm server.asm server.o
ld server.o -o server.out

fasm client.asm client.o
ld client.o -o client.out