FROM golang:alpine as builder

WORKDIR /gigi

COPY gigi.go .

RUN go build -ldflags "-s -w" -o gigi gigi.go

FROM alpine

WORKDIR /gigi

COPY --from=builder /gigi/gigi .

ENTRYPOINT ["/gigi/gigi"]
