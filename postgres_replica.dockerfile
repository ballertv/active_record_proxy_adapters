FROM docker.io/postgres:14-alpine

ENV PRIMARY_DATABASE_HOST=localhost
ENV PRIMARY_DATABASE_PORT=5432
ENV PRIMARY_REPLICATION_SLOT=replication_slot

USER root
RUN printf '' > cmd.sh

RUN echo 'until pg_basebackup --pgdata=/var/lib/postgresql/data -R --slot=$PRIMARY_REPLICATION_SLOT --host=$PRIMARY_DATABASE_HOST --port=$PRIMARY_DATABASE_PORT' >> cmd.sh
RUN echo 'do' >> cmd.sh
RUN echo "echo 'Waiting for primary to connect...'" >> cmd.sh
RUN echo 'sleep 1s' >> cmd.sh
RUN echo 'done' >> cmd.sh
RUN echo "echo 'Backup done, starting replica...'" >> cmd.sh
RUN echo 'chmod 0700 /var/lib/postgresql/data' >> cmd.sh
RUN echo 'postgres' >> cmd.sh

RUN chown -R postgres:postgres cmd.sh
USER postgres
RUN chmod u+rwx cmd.sh

CMD [ "./cmd.sh" ]
