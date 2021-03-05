FROM golang

WORKDIR /go/src/app
COPY . .

RUN go build

CMD ["/go/src/app/pacoloco", "-config", "/etc/pacoloco/config.yaml"]