FROM ghcr.io/void-linux/void-linux:latest-thin-x86_64

RUN --mount=type=tmpfs,target=/var/cache/xbps xbps-install -Suy xbps && xbps-install -uy shadow gnutls-tools catatonit taskd

USER taskd:taskd

ENV TASKDDATA=/var/lib/taskd
ENV TASKDUSER=taskd
ENV TASKDHOSTNAME=localhost
ENV TASKDPORT=53589

VOLUME ${TASKDDATA}
WORKDIR ${TASKDDATA}

COPY ./addtaskduser /usr/local/bin
COPY ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]

CMD ["taskd", "server"]
