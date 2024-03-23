FROM golang:1.16 AS builder

WORKDIR /app

COPY golang-webserver/ .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o golang-webserver

FROM alpine:3.19

WORKDIR /app

COPY --from=builder /app/golang-webserver .

EXPOSE 8080

CMD ["./golang-webserver"]