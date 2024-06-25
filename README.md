# 👧️ Gigi

> A Finger protocol server for risk takers

Gigi is a Finger protocol server with few features.

- Gigi can respond to Finger requests statically
- Gigi can respond to Finger requests dynamically

<p align="center">
  <br>
  <img src="https://i.imgur.com/RddckKP.png" width="75%">
</p>

## Usage

### Local

```bash
$ git clone git@github.com:Fuwn/gigi.git
$ cd gigi
$ tup
$ # or
$ ninja
```

### Docker

This command runs the latest Gigi Docker image, with port 79 mapped from inside
the container to port 7979 on the host system. In practice, you'd actually map
port 79 to port 79, but that requires root privileges, so we're using 7979.

It also mounts the ./.gigi directory from the host system to the /gigi/.gigi
directory inside the container. This is where you'd place all your profile
files. In practice, you'd likely make this a named volume, and add files to the
named volume itself.

```bash
$ docker run -v ./.gigi/:/gigi/.gigi -p 7979:79 fuwn/gigi:latest
$ # or
$ docker run -v gigi-data:/gigi/.gigi -p 79:79 fuwn/gigi:latest
```

The second command is the more practical one, as it uses a named volume to store
the profile files. The named volume is persistent, and can be found at
`/var/lib/docker/volumes/gigi-data/_data` on most FHS systems.

Docker also significantly reduces the risk of running Gigi, as it is sandboxed
from the host system. In static mode, there is little to no risk, but in dynamic
mode, there is a significant risk for arbitrary code execution.

### Configuration

Gigi is configured through the `./gigi` directory.

Dynamic response mode is disabled by default in [`gigi.c`](./gigi.c)
because it is very unsafe. If you wish to live on the edge, uncomment the
`GIGI_DYNAMIC` macro. Dropping Gigi into a container is significantly safer
than running it on a host machine, so consider that as an option, too.

Dynamic mode runs any and all executables located at the path `./gigi/do`, and
passes any arguments from the Finger request to the executable.

Static mode is enabled by default. A Finger request for `test` will return the
contents of `./gigi/test`. A Finger request of nothing will return the contents
of `./gigi/default`.

To emulate dynamic mode, minus the arguments you can setup a service of some
kind to periodically update the contents of one of the static files.

## Licence

This project is licensed with the [GNU General Public License v3.0](./LICENSE).
