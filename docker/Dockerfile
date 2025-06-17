FROM debian:bullseye-slim as builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
            curl \
            ca-certificates \
            gnupg

RUN curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/$(dpkg --print-architecture) stable main" | tee /etc/apt/sources.list.d/1password.list && \
    mkdir -p /etc/debsig/policies/AC2D62742012EA22/ && \
    curl -sS https://downloads.1password.com/linux/debian/debsig/1password.pol | tee /etc/debsig/policies/AC2D62742012EA22/1password.pol && \
    mkdir -p /usr/share/debsig/keyrings/AC2D62742012EA22 && \
    curl -sS https://downloads.1password.com/linux/keys/1password.asc | gpg --dearmor --output /usr/share/debsig/keyrings/AC2D62742012EA22/debsig.gpg && \
    apt-get update && \
    apt-get install -y --no-install-recommends 1password-cli

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl


FROM python:3.13.5-slim-bullseye

COPY --from=builder /usr/bin/op /usr/bin/
COPY --from=builder /usr/local/bin/kubectl /usr/local/bin/

RUN apt-get update && \
    apt-get install -y --no-install-recommends openssh-client && \
    pip3 install ansible

COPY ssh/ /root/.ssh/
RUN chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/config && \
    chmod 600 /root/.ssh/*.pub

WORKDIR /ansible
