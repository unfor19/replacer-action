FROM alpine:3.11
RUN apk --no-cache add util-linux bash perl git
WORKDIR /code
COPY . .
RUN chmod +x **/*.sh
ENTRYPOINT [ "/code/entrypoint.sh" ]
CMD [ "--help" ]
