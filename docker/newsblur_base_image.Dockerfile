FROM python:3.9-alpine AS builder

WORKDIR /wheels
RUN apk add --no-cache build-base cargo git jpeg-dev libffi-dev libpq-dev pcre2-dev rust zlib-dev
# RUN pip install --upgrade pip==24.0

#         patch \
#         gfortran \
#         libblas-dev \
#         libffi-dev \
#         libjpeg-dev \
#         libpq-dev \
#         libreadline6-dev \
#         liblapack-dev \
#         libxml2-dev \
#         libxslt1-dev \
#         ncurses-dev \
#         zlib1g-dev \

COPY config/requirements.txt /wheels/
RUN pip wheel -r ./requirements.txt

RUN apk add --no-cache pcre2-dev \
    && cd /tmp \
    && git clone --depth 1 -b 1.32.1-1 https://github.com/nginx/unit \
    && cd unit \
    && ./configure \
    && ./configure python --config=/usr/local/bin/python3-config \
    && make python3-install

# pip wheel -r /src/config/requirements.txt

FROM      python:3.9-alpine

WORKDIR   /srv/newsblur
ENV       DOCKERBUILD=True
ENV       PYTHONPATH=/srv/newsblur

RUN apk add --no-cache curl libjpeg libpq unit

#         libpq5 \
#         libjpeg62 \
#         libxslt1.1 \

COPY --from=builder /wheels /wheels
RUN pip install -r /wheels/requirements.txt -f /wheels && \
    rm -rf /wheels && \
    pip cache purge
COPY . /srv/newsblur/

COPY --from=builder /usr/local/lib/unit/modules/python3.unit.so /usr/lib/unit/modules/python3.unit.so

ADD https://raw.githubusercontent.com/nginx/unit/1.32.1/pkg/docker/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

RUN ln -sf /dev/stdout /var/log/unit.log

COPY config/unit/config.sh /docker-entrypoint.d/config.sh
RUN chmod +x /docker-entrypoint.d/config.sh

CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]
