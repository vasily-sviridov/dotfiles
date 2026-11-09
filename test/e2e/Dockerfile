ARG UBUNTU_VERSION=26.10
FROM ubuntu:${UBUNTU_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo curl wget ca-certificates git bash zsh xz-utils tar gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /dotfiles
COPY . /dotfiles
RUN chmod +x install dependencies/bootstrap.sh

CMD ["bash"]
