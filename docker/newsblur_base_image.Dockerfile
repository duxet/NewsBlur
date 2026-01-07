FROM python:3.9-alpine AS builder

WORKDIR /srv/newsblur
ENV PYTHONPATH=/srv/newsblur

RUN apk add --no-cache build-base cargo curl git jpeg-dev libffi-dev libpq-dev pcre2-dev rust uv zlib-dev

# Create virtual environment
RUN uv venv /venv
ENV PATH="/venv/bin:$PATH"
ENV VIRTUAL_ENV="/venv"

COPY config/requirements.txt /srv/newsblur/
RUN --mount=type=cache,target=/root/.cache/uv \
    uv pip install -r requirements.txt

# Build NGINX Unit with Python 3 support
RUN apk add --no-cache pcre2-dev \
    && cd /tmp \
    && git clone --depth 1 -b 1.33.0-1 https://github.com/nginx/unit \
    && cd unit \
    && ./configure \
    && ./configure python --config=/usr/local/bin/python3-config \
    && make python3-install

FROM      python:3.9-alpine

WORKDIR   /srv/newsblur
ENV       DOCKERBUILD=True
ENV       PYTHONPATH=/srv/newsblur
ENV       VIRTUAL_ENV="/venv"

RUN apk add --no-cache curl libjpeg libpq unit

COPY --from=builder /venv /venv
COPY . /srv/newsblur/

COPY --from=builder /usr/local/lib/unit/modules/python3.unit.so /usr/lib/unit/modules/python3.unit.so

ADD https://raw.githubusercontent.com/nginx/unit/1.33.0/pkg/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

RUN ln -sf /dev/stdout /var/log/unit.log

COPY config/unit/config.sh /docker-entrypoint.d/config.sh
RUN chmod +x /docker-entrypoint.d/config.sh

CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]
