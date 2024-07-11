FROM      python:3.9-slim AS builder
WORKDIR   /wheels
RUN       set -ex \
          && buildDeps=' \
                    patch \
                    gfortran \
                    libblas-dev \
                    libffi-dev \
                    libjpeg-dev \
                    libpq-dev \
                    libreadline6-dev \
                    liblapack-dev \
                    libxml2-dev \
                    libxslt1-dev \
                    ncurses-dev \
                    zlib1g-dev \
                            ' \
            && apt-get update \
            && apt-get install -y $buildDeps --no-install-recommends
COPY      config/requirements.txt /wheels/
RUN       pip wheel -r ./requirements.txt

FROM      python:3.9-slim
WORKDIR   /srv/newsblur
ENV       DOCKERBUILD=True
ENV       PYTHONPATH=/srv/newsblur
RUN       set -ex \
          && rundDeps=' \
                  libpq5 \
                  libjpeg62 \
                  libxslt1.1 \
                            ' \
            && apt-get update \
            && apt-get install -y $rundDeps --no-install-recommends \
            && rm -rf /var/lib/apt/lists/*
COPY      --from=builder /wheels /wheels
RUN       pip install -r /wheels/requirements.txt -f /wheels \
          && rm -rf /wheels \
          && pip cache purge
COPY      . /srv/newsblur/
CMD       ["gunicorn", "-c", "config/gunicorn_conf.py", "newsblur_web.wsgi:application"]
