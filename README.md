# 👧️ Gigi

> A Finger protocol server for risk takers

Gigi is a Finger protocol server with few features.

- Gigi can respond to Finger requests statically
- Gigi can respond to Finger requests dynamically

## Usage

### Local

```bash
$ git clone git@github.com:Fuwn/gigi.git
$ cd gigi
$ tup
```

### Configuration

Gigi is configured through the `./gigi` directory.

Dynamic response mode is disabled by default in [`gigi.c`](./gigi.c)
because it is very unsafe. If you wish to live on the edge, uncomment the
`GIGI_DYNAMIC` macro.

Dynamic mode runs any and all executables located at the path `./gigi/do`, and
passes any arguments from the Finger request to the executable.

Static mode is enabled by default. A Finger request for `test` will return the
contents of `./gigi/test`. A Finger request of nothing will return the contents
of `./gigi/default`.

## Licence

This project is licensed with the [GNU General Public License v3.0](./LICENSE).