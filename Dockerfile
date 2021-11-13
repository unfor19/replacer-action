FROM alpine:3.14
RUN apk --no-cache add util-linux bash perl git
ENV IS_DOCKER="true"
WORKDIR /code
COPY . .
ENTRYPOINT [ "/code/entrypoint.sh" ]
