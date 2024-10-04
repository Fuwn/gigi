# 👧️ Gigi

> An honest [Finger](https://www.rfc-editor.org/info/rfc742) protocol server

Gigi is a Finger protocol server with few features–the way a Finger server
should be.

- Gigi can respond to Finger requests statically.
- Gigi can respond to Finger requests dynamically.

<p align="center">
  <br>
  <img src="https://i.imgur.com/RddckKP.png" width="75%" alt="Example screenshot">
</p>

## Usage

A live, production deployment of Gigi exists at
[`finger://fuwn.me`](finger://fuwn.me). Feel free to poke and prod at it as you
wish.

You can use a Finger client like [finger](https://github.com/reiver/finger) to
send requests, or you could use the old reliable `telnet` or `nc` commands.

```bash
finger fuwn.me
telnet fuwn.me
echo | nc fuwn.me 79
```

### Running Locally

To run Gigi from a single command using Nix, execute `nix run github:Fuwn/gigi`;
otherwise, try one of the command combinations below.

```bash
# Clone the repository locally
git clone git@github.com:Fuwn/gigi.git

# Navigate into the local repository
cd gigi

# Build and run Gigi without Nix; requires Go to be locally available
go build gigi.go && ./gigi

# Build and run Gigi with Nix
nix build && ./result/bin/gigi
```

### Running using Docker

This command runs the latest Gigi Docker image with port 79 mapped from inside
the container to port 7979 on the host system. In practice, you'd actually map
port 79 to port 79, but that requires root privileges, so we're using 7979 here.

The command also mounts the `./.gigi` directory from the host system to the `/gigi/.gigi`
directory inside the container. This is where you'd place all your profile
files. In practice, you'd likely make this a named volume or mount from a more collected
volume storage facility, and add files to that mounted volume path itself.

```bash
# Run Gigi using Docker with a local volume directory
docker run -v ./.gigi/:/gigi/.gigi -p 7979:79 fuwn/gigi:latest

# Run Gigi using Docker with a named volume and a remote volume directory
docker run -v gigi-data:/gigi/.gigi -p 79:79 fuwn/gigi:latest
```

The second command is the more practical one, as it uses a named volume to store
the profile files. The named volume is persistent, and can be found at
`/var/lib/docker/volumes/gigi-data/_data` on most semi-FHS compliant systems by default.

Docker also significantly reduces the risk of running Gigi, as it is *sandboxed*
from the host system. In static mode, there is little to no risk, but in dynamic
mode, there is a small risk for arbitrary code execution depending on your
`.gigi/do` file.

### Configuration

Gigi is configured through the `./.gigi` directory.

Dynamic response mode is disabled by default as dynamic code execution can be a
big security risk. If you wish to live on the edge, pass the `GIGI_DYNAMIC`
environment variable with a value greater than `1` to Gigi. Dropping Gigi into a
container is significantly safer than running it on a host machine, so consider
that as your primary deployment option.

Dynamic mode runs any and all executables located at the path `./.gigi/do`, and
passes any arguments from the Finger request to the executable.

Static mode is enabled by default. A Finger request for `test` will return the
contents of `./.gigi/test`. A Finger request of nothing will return the contents
of `./.gigi/default`. The default file is also the fallback file in case the
requested file does not exist.

To emulate dynamic mode, minus the support for arguments, you can setup a
service of some kind to periodically update the contents of one of the static
files.

You can additionally modify the `GIGI_PORT` environment variable to change the
port Gigi listens on. The default port is 79. If you're running Gigi in a
Docker container, you can ignore this variable and map any ports using Docker
directly.

## Licence

Licensed under either of [Apache License, Version 2.0](LICENSE-APACHE) or
[MIT license](LICENSE-MIT) at your option.

Unless you explicitly state otherwise, any contribution intentionally submitted
for inclusion in this crate by you, as defined in the Apache-2.0 license, shall
be dual licensed as above, without any additional terms or conditions.
