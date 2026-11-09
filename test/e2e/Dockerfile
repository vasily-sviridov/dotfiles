FROM ubuntu:26.10

ENV DEBIAN_FRONTEND=noninteractive

# Базовые инструменты, необходимые ./install / dependencies/bootstrap.sh
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo curl wget ca-certificates git bash zsh xz-utils tar gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /dotfiles

# Свежая копия репо (аналог fresh clone).
COPY . /dotfiles

RUN chmod +x install dependencies/bootstrap.sh

CMD ["bash"]
