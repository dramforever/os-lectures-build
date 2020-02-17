FROM terrorjack/pixie

COPY . /root/workspace

RUN nix-shell -f workspace --run "echo ok"
