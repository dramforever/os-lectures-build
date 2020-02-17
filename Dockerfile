FROM terrorjack/vanilla:circleci

RUN apk add xz

COPY . /root/workspace
RUN cd /root/workspace && nix-shell --run "echo ok"
