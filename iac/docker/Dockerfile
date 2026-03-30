

#################################################
# BUILD
#
FROM python:3.6-slim AS builder
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
ENV PATH="/app/bin:$PATH"

WORKDIR /build

RUN apt-get update -y && apt-get install python3-venv -y && \
    rm -rf /var/lib/apt/lists/*


# source code from github kennethreitz/httpbin (master branch)
COPY ./httpbin /build/
RUN python3 -m venv /app
# httpbin dependencies discovered via setup.py
RUN pip install --no-cache-dir --upgrade pip && pip install --no-cache-dir gunicorn gevent /build


#################################################
# RUNTIME
#
# smaller, a bit safer (footprint) image
FROM python:3.6-slim AS runtime

ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
# ENV PYTHONIOENCODING=utf-8
ENV PATH="/app/bin:$PATH"
ENV GUNICORN_CMD_ARGS="--access-logfile - --error-logfile -"

COPY --from=builder /app /app

RUN groupadd --gid 1000 app && \
    useradd --uid 1000 --gid app --no-create-home app

USER app

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen(urllib.request.Request('http://127.0.0.1:8080/status/200', headers={'X-Health-Check': 'true'}), timeout=3)" || exit 1

CMD ["gunicorn", "-b", "0.0.0.0:8080", "httpbin:app", "-k", "gevent"]
