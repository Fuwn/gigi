name := "gigi"

push tag="latest":
  docker buildx build \
    --platform linux/amd64,linux/arm64 \
    -t fuwn/{{ name }}:{{ tag }} \
    --push \
    .

build:
  go build

run:
  go run {{ name }}.go
