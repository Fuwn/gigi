FROM alpine:latest as environment

RUN apk update \
  && apk upgrade \
  && apk add --no-cache libstdc++

FROM environment as build_environment

RUN apk add --no-cache \
  clang \
  ninja \
  alpine-sdk \
  linux-headers

FROM build_environment as builder

WORKDIR /gigi

COPY ./gigi.c ./gigi.c
COPY ./build.ninja  ./build.ninja

RUN sed -i 's/#include <bits\/types\/FILE.h>//g' gigi.c

RUN ninja

RUN strip /gigi/build/gigi

FROM environment

WORKDIR /gigi

COPY --from=builder /gigi/build/gigi ./

EXPOSE 79

ENTRYPOINT ["/gigi/gigi"]
