# micro-exchange/docker-taonacoin-core

A Taonacoin Core docker image.

[![microexchange/taonacoin-core][docker-pulls-image]][docker-hub-url] [![microexchange/taonacoin-core][docker-stars-image]][docker-hub-url] [![microexchange/taonacoin-core][docker-size-image]][docker-hub-url] [![microexchange/taonacoin-core][docker-layers-image]][docker-hub-url]

## Tags

- `2.2`, `2.2.2`, `latest` ([2.2/Dockerfile](https://github.com/micro-exchange/docker-taonacoin-core/blob/master/2.2/Dockerfile)) 
- `2.2-alpine`, `2.2.2-alpine` ([2.2/alpine/Dockerfile](https://github.com/micro-exchange/docker-taonacoin-core/blob/master/2.2/alpine/Dockerfile))
- 
**Picking the right tag**

- `microexchange/taonacoin-core:latest`: points to the latest stable release available of Taonacoin Core. Use this only if you know what you're doing as upgrading Taonacoin Core blindly is a risky procedure.
- `microexchange/taonacoin-core:alpine`: same as above but using the Alpine Linux distribution (a resource efficient Linux distribution with security in mind, but not officially supported by the Taonacoin Core team — use at your own risk).
- `microexchange/taonacoin-core:<version>`: based on a Ubuntu image, points to a specific version branch or release of Taonacoin Core. Uses the pre-compiled binaries which are fully tested by the Taonacoin Core team.
- `microexchange/taonacoin-core:<version>-alpine`: same as above but using the Alpine Linux distribution.

## What is Taonacoin Core?

Learn more about [Taonacoin Core](https://github.com/TaonaProject/Taonacoin).

## Usage

### How to use this image

This image contains the main binaries from the Taonacoin Core project - `taonad` and `taona-cli`. It behaves like a binary, so you can pass any arguments to the image and they will be forwarded to the `taonad` binary:

```sh
❯ docker run --rm microexchange/taonacoin-core \
  -printtoconsole \
  -regtest=1 \
  -rpcallowip=172.17.0.0/16 \
  -rpcauth='foo:1e72f95158becf7170f3bac8d9224$957a46166672d61d3218c167a223ed5290389e9990cc57397d24c979b4853f8e'
```

By default, `taonad` will run as user `taonacoin` for security reasons and with its default data dir (`~/.taonacoin`). If you'd like to customize where `taonad` stores its data, you must use the `TAONACOIN_DATA` environment variable. The directory will be automatically created with the correct permissions for the `taonacoin` user and `taonad` automatically configured to use it.

```sh
❯ docker run -e TAONACOIN_DATA=/var/lib/taonad --rm microexchange/taonacoin-core \
  -printtoconsole \
  -regtest=1
```

You can also mount a directory in a volume under `/home/taonacoin/.taonacoin` in case you want to access it on the host:

```sh
❯ docker run -v ${PWD}/data:/home/taonacoin/.taonacoin --rm microexchange/taonacoin-core \
  -printtoconsole \
  -regtest=1
```

You can optionally create a service using `docker-compose`:

```yml
taonacoin-core:
  image: microexchange/taonacoin-core
  command:
    -printtoconsole
    -regtest=1
```

### Using RPC to interact with the daemon

There are two communications methods to interact with a running Taonacoin Core daemon.

The first one is using a cookie-based local authentication. It doesn't require any special authentication information as running a process locally under the same user that was used to launch the Taonacoin Core daemon allows it to read the cookie file previously generated by the daemon for clients. The downside of this method is that it requires local machine access.

The second option is making a remote procedure call using a username and password combination. This has the advantage of not requiring local machine access, but in order to keep your credentials safe you should use the newer `rpcauth` authentication mechanism.

#### Using cookie-based local authentication

Start by launch the Taonacoin Core daemon:

```sh
❯ docker run --rm --name taonacoin-server -it microexchange/taonacoin-core \
  -printtoconsole \
  -regtest=1
```

Then, inside the running `taonacoin-server` container, locally execute the query to the daemon using `taonacoin-cli`:

```sh
❯ docker exec --user taonacoin taonacoin-server taonacoin-cli -regtest getmininginfo

{
  "blocks": 0,
  "currentblocksize": 0,
  "currentblockweight": 0,
  "currentblocktx": 0,
  "difficulty": 4.656542373906925e-10,
  "errors": "",
  "networkhashps": 0,
  "pooledtx": 0,
  "chain": "regtest"
}
```

In the background, `taonacoin-cli` read the information automatically from `/home/taonacoin/.taonacoin/regtest/.cookie`. In production, the path would not contain the regtest part.

#### Using rpcauth for remote authentication

Before setting up remote authentication, you will need to generate the `rpcauth` line that will hold the credentials for the Taonacoin Core daemon. You can either do this yourself by constructing the line with the format `<user>:<salt>$<hash>` or use the official `rpcauth.py` script to generate this line for you, including a random password that is printed to the console.

Example:

```sh
❯ curl -sSL https://raw.githubusercontent.com/TaonaProject/Taonacoin/master/share/rpcauth/rpcauth.py | python - <username>

String to be appended to taonacoin.conf:
rpcauth=foo:1e72f95158becf7170f3bac8d9224$957a46166672d61d3218c167a223ed5290389e9990cc57397d24c979b4853f8e
Your password:
-ngju1uqGUmAJIQDBCgYbatzhcJon_YGU23t313388g=
```

Note that for each run, even if the username remains the same, the output will be always different as a new salt and password are generated.

Now that you have your credentials, you need to start the Taonacoin Core daemon with the `-rpcauth` option. Alternatively, you could append the line to a `taonacoin.conf` file and mount it on the container.

Let's opt for the Docker way:

```sh
❯ docker run --rm --name taonacoin-server -it microexchange/taonacoin-core \
  -printtoconsole \
  -regtest=1 \
  -rpcallowip=172.17.0.0/16 \
  -rpcauth='foo:1e72f95158becf7170f3bac8d9224$957a46166672d61d3218c167a223ed5290389e9990cc57397d24c979b4853f8e'
```

Two important notes:

1. Some shells require escaping the rpcauth line (e.g. zsh), as shown above.
2. It is now perfectly fine to pass the rpcauth line as a command line argument. Unlike `-rpcpassword`, the content is hashed so even if the arguments would be exposed, they would not allow the attacker to get the actual password.

You can now connect via `taonacoin-cli` or any other [compatible client](https://github.com/ruimarinho/bitcoin-core). You will still have to define a username and password when connecting to the Taonacoin Core RPC server.

To avoid any confusion about whether or not a remote call is being made, let's spin up another container to execute `taonacoin-cli` and connect it via the Docker network using the password generated above:

```sh
❯ docker run --link taonacoin-server --rm microexchange/taonacoin-core \
  taonacoin-cli \
  -rpcconnect=taonacoin-server \
  -regtest \
  -rpcuser=foo \
  -rpcpassword='-ngju1uqGUmAJIQDBCgYbatzhcJon_YGU23t313388g=' \
  getmininginfo

{
  "blocks": 0,
  "currentblocksize": 0,
  "currentblockweight": 0,
  "currentblocktx": 0,
  "difficulty": 4.656542373906925e-10,
  "errors": "",
  "networkhashps": 0,
  "pooledtx": 0,
  "chain": "regtest"
}
```

### Exposing Ports

Depending on the network (mode) the Taonacoin Core daemon is running as well as the chosen runtime flags, several default ports may be available for mapping.

Ports can be exposed by mapping all of the available ones (using `-P` and based on what `EXPOSE` documents) or individually by adding `-p`. This mode allows assigning a dynamic port on the host (`-p <port>`) or assigning a fixed port `-p <hostPort>:<containerPort>`.

Example for running a node in `regtest` mode mapping JSON-RPC/REST and P2P ports:

```sh
docker run --rm -it \
  -p 18756:18756 \
  -p 19444:19444 \
  microexchange/taonacoin-core \
  -printtoconsole \
  -regtest=1 \
  -rpcallowip=172.17.0.0/16 \
  -rpcauth='foo:1e72f95158becf7170f3bac8d9224$957a46166672d61d3218c167a223ed5290389e9990cc57397d24c979b4853f8e'
```

To test that mapping worked, you can send a JSON-RPC curl request to the host port:

```
curl --data-binary '{"jsonrpc":"1.0","id":"1","method":"getnetworkinfo","params":[]}' http://foo:-ngju1uqGUmAJIQDBCgYbatzhcJon_YGU23t313388g=@127.0.0.1:18756/
```

#### Mainnet

- JSON-RPC/REST: 8756
- P2P: 8757

#### Testnet

- JSON-RPC: 18756
- P2P: 18757

#### Regtest

- JSON-RPC/REST: 18756
- P2P: 19444

## Supported Docker versions

This image is officially supported on Docker version 17.09, with support for older versions provided on a best-effort basis.

## License

The [microexchange/taonacoin-core][docker-hub-url] docker project is under MIT license.

[docker-hub-url]: https://hub.docker.com/r/microexchange/taonacoin-core
[docker-layers-image]: https://img.shields.io/microbadger/layers/microexchange/taonacoin-core/latest.svg?style=flat-square
[docker-pulls-image]: https://img.shields.io/docker/pulls/microexchange/taonacoin-core.svg?style=flat-square
[docker-size-image]: https://img.shields.io/microbadger/image-size/microexchange/taonacoin-core/latest.svg?style=flat-square
[docker-stars-image]: https://img.shields.io/docker/stars/microexchange/taonacoin-core.svg?style=flat-square
