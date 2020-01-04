# OpenVPN for Docker

[![Build Status](https://travis-ci.org/kylemanna/docker-openvpn.svg)](https://travis-ci.org/kylemanna/docker-openvpn)
[![Docker Stars](https://img.shields.io/docker/stars/kylemanna/openvpn.svg)](https://hub.docker.com/r/kylemanna/openvpn/)
[![Docker Pulls](https://img.shields.io/docker/pulls/kylemanna/openvpn.svg)](https://hub.docker.com/r/kylemanna/openvpn/)
[![ImageLayers](https://images.microbadger.com/badges/image/kylemanna/openvpn.svg)](https://microbadger.com/#/images/kylemanna/openvpn)
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fkylemanna%2Fdocker-openvpn.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fkylemanna%2Fdocker-openvpn?ref=badge_shield)


OpenVPN server in a Docker container complete with an EasyRSA PKI CA.

Extensively tested on [Digital Ocean $5/mo node](http://bit.ly/1C7cKr3) and has
a corresponding [Digital Ocean Community Tutorial](http://bit.ly/1AGUZkq).

___

## Zalgo's OpenVPN Server

#### Instructions

To prepare a fresh server, make sure you export an environment variable for `OVPN_DATA`, regardless if you're adding it as a volume or attaching a local folder:

```bash
export OVPN_DATA="$HOME/ovpn-data-example"
```

Now with Docker Compose, you can create an interactive instance to start configuring the server. The `entrypoint.sh` script will detect whether the needed files are present and run the process of creating them if needed. The `.env` file may help you defining a deployment without having to type in your Public IP and desired custom subnet everytime you need to re-deploy.

```bash
docker-compose run --rm open-vpn
```

After creating all of the keys and your first client, simply launch the service with:

```bash
docker-compose up -d
```


#### Features introduced

1. Reduced number of layers to 9.
1. Added an `entrypoint.sh` script to help with new server and user creation.
1. Moved all copied content into a single `/rootfs` folder.
1. Summarized all actions in a single `docker-compose.yml` file


#### The Dockerfile

The original Dockerfile was modified to squash multiple `RUN`, `ENV` and `ADD` layers.

The added files are placed in a single `rootfs` folder composed of the same structure of the root directory where the files are added.

All `RUN` and `ENV` layers easily combined on the same line.

Added `ENTRYPOINT ["/entrypoint.sh"]` layer.


#### The entrypoint.sh file

In this script, a set of conditionals are looking for certain existing files in the `/etc/openvpn/` directory. If they don't exist, the appropriate `bin` executables will be called.

With a new configuration, the setup will look for the env variables:
+ `OVPN_SERVER` for defining your cloud server's public IP.
+ `OVPN_SUBNET` to set a custom subnet (defaults to 10.8.0.0/24)

If these aren't provided initially with the `.env` file, they will be requested upon execution.

Creating a new client is triggered whenever the `/etc/openvpn/clients` folder is empty __or__ if the environment variable `OVPN_CLIENT` is set. This basically is a function using this variable to create a client and spit out the `.ovpn` file.

#### VPN Server Configuration

I've transposed the best that I could all of the settings I've been using over the years with OpenVPN servers on bare-metal and cloud VMs. 

I don't want the server for privacy reasons such as hiding my traffic from my ISP. Rather, I use it as a secure way to access "nodes" in my localhost regardless where they are and what is their internet connection.

For that reason, the client profiles are configured with split tunelling as opposed to fully encrypted tunels. That's why this is _your localhost in your pocket._

```bash
bash /usr/local/bin/ovpn_genconfig \
     -u udp://${OVPN_SERVER} \
     -p "redirect-gateway def1 bypass-dhcp" \
     -e "sndbuf 0" \
     -e "rcvbuf 0" \
     -e "topology subnet" \
     -e "ifconfig-pool-persist ipp.txt" \
     -E 'pull-filter ignore "route-gateway"' \
     -E "route 0.0.0.0 192.0.0.0 net_gateway" \
     -E "route 64.0.0.0 192.0.0.0 net_gateway" \
     -E "route 128.0.0.0 192.0.0.0 net_gateway" \
     -E "route 192.0.0.0 192.0.0.0 net_gateway" \
     -E "sndbuf 0" \
     -E "rcvbuf 0" \
     -E "resolv-retry infinite" \
     -E "persist-key" \
     -E "persist-tun" \
     -E "setenv opt block-outside-dns" \
     -E "key-direction 1" \
     -E "verb 3" \
     -s "${OVPN_SUBNET}/24" \
     -d \
     -N \
     -z

```

#### Use Cases

I've used this on Linux and Android. It works well under Linux on `network_mode: "bridged"` to allow creating an isolated namespace for the OpenVPN server container. It also works well on Linux on `network_mode: "host"` if you wish for the VPN server host to hold directly the Gateway IP (the Linux host should retrieve the 10.8.0.1 address).

Clients can connect via the Android app for OpenVPN and have full access to the subnet if you didn't set any restrictions.

Clients on Linux can setup a systemd profile _or_ use a Docker container as well.

You can expand your network by creating more clients even if containerized (checkout my docker-nginx-vpn repo) and host your private content _only_ on your custom VPN. Each gets a fixed IP address definable under the IP-Pool (`/etc/openvpn/ipp.txt`).

Still be able to access your machine regardless of enterprise network security.

___




#### Upstream Links

* Docker Registry @ [kylemanna/openvpn](https://hub.docker.com/r/kylemanna/openvpn/)
* GitHub @ [kylemanna/docker-openvpn](https://github.com/kylemanna/docker-openvpn)

## Quick Start

* Pick a name for the `$OVPN_DATA` data volume container. It's recommended to
  use the `ovpn-data-` prefix to operate seamlessly with the reference systemd
  service.  Users are encourage to replace `example` with a descriptive name of
  their choosing.

      OVPN_DATA="ovpn-data-example"

* Initialize the `$OVPN_DATA` container that will hold the configuration files
  and certificates.  The container will prompt for a passphrase to protect the
  private key used by the newly generated certificate authority.

      docker volume create --name $OVPN_DATA
      docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_genconfig -u udp://VPN.SERVERNAME.COM
      docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn ovpn_initpki

* Start OpenVPN server process

      docker run -v $OVPN_DATA:/etc/openvpn -d -p 1194:1194/udp --cap-add=NET_ADMIN kylemanna/openvpn

* Generate a client certificate without a passphrase

      docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm -it kylemanna/openvpn easyrsa build-client-full CLIENTNAME nopass

* Retrieve the client configuration with embedded certificates

      docker run -v $OVPN_DATA:/etc/openvpn --log-driver=none --rm kylemanna/openvpn ovpn_getclient CLIENTNAME > CLIENTNAME.ovpn

## Next Steps

### More Reading

Miscellaneous write-ups for advanced configurations are available in the
[docs](docs) folder.

### Systemd Init Scripts

A `systemd` init script is available to manage the OpenVPN container.  It will
start the container on system boot, restart the container if it exits
unexpectedly, and pull updates from Docker Hub to keep itself up to date.

Please refer to the [systemd documentation](docs/systemd.md) to learn more.

### Docker Compose

If you prefer to use `docker-compose` please refer to the [documentation](docs/docker-compose.md).

## Debugging Tips

* Create an environment variable with the name DEBUG and value of 1 to enable debug output (using "docker -e").

        docker run -v $OVPN_DATA:/etc/openvpn -p 1194:1194/udp --privileged -e DEBUG=1 kylemanna/openvpn

* Test using a client that has openvpn installed correctly

        $ openvpn --config CLIENTNAME.ovpn

* Run through a barrage of debugging checks on the client if things don't just work

        $ ping 8.8.8.8    # checks connectivity without touching name resolution
        $ dig google.com  # won't use the search directives in resolv.conf
        $ nslookup google.com # will use search

* Consider setting up a [systemd service](/docs/systemd.md) for automatic
  start-up at boot time and restart in the event the OpenVPN daemon or Docker
  crashes.

## How Does It Work?

Initialize the volume container using the `kylemanna/openvpn` image with the
included scripts to automatically generate:

- Diffie-Hellman parameters
- a private key
- a self-certificate matching the private key for the OpenVPN server
- an EasyRSA CA key and certificate
- a TLS auth key from HMAC security

The OpenVPN server is started with the default run cmd of `ovpn_run`

The configuration is located in `/etc/openvpn`, and the Dockerfile
declares that directory as a volume. It means that you can start another
container with the `-v` argument, and access the configuration.
The volume also holds the PKI keys and certs so that it could be backed up.

To generate a client certificate, `kylemanna/openvpn` uses EasyRSA via the
`easyrsa` command in the container's path.  The `EASYRSA_*` environmental
variables place the PKI CA under `/etc/openvpn/pki`.

Conveniently, `kylemanna/openvpn` comes with a script called `ovpn_getclient`,
which dumps an inline OpenVPN client configuration file.  This single file can
then be given to a client for access to the VPN.

To enable Two Factor Authentication for clients (a.k.a. OTP) see [this document](/docs/otp.md).

## OpenVPN Details

We use `tun` mode, because it works on the widest range of devices.
`tap` mode, for instance, does not work on Android, except if the device
is rooted.

The topology used is `net30`, because it works on the widest range of OS.
`p2p`, for instance, does not work on Windows.

The UDP server uses`192.168.255.0/24` for dynamic clients by default.

The client profile specifies `redirect-gateway def1`, meaning that after
establishing the VPN connection, all traffic will go through the VPN.
This might cause problems if you use local DNS recursors which are not
directly reachable, since you will try to reach them through the VPN
and they might not answer to you. If that happens, use public DNS
resolvers like those of Google (8.8.4.4 and 8.8.8.8) or OpenDNS
(208.67.222.222 and 208.67.220.220).


## Security Discussion

The Docker container runs its own EasyRSA PKI Certificate Authority.  This was
chosen as a good way to compromise on security and convenience.  The container
runs under the assumption that the OpenVPN container is running on a secure
host, that is to say that an adversary does not have access to the PKI files
under `/etc/openvpn/pki`.  This is a fairly reasonable compromise because if an
adversary had access to these files, the adversary could manipulate the
function of the OpenVPN server itself (sniff packets, create a new PKI CA, MITM
packets, etc).

* The certificate authority key is kept in the container by default for
  simplicity.  It's highly recommended to secure the CA key with some
  passphrase to protect against a filesystem compromise.  A more secure system
  would put the EasyRSA PKI CA on an offline system (can use the same Docker
  image and the script [`ovpn_copy_server_files`](/docs/paranoid.md) to accomplish this).
* It would be impossible for an adversary to sign bad or forged certificates
  without first cracking the key's passphase should the adversary have root
  access to the filesystem.
* The EasyRSA `build-client-full` command will generate and leave keys on the
  server, again possible to compromise and steal the keys.  The keys generated
  need to be signed by the CA which the user hopefully configured with a passphrase
  as described above.
* Assuming the rest of the Docker container's filesystem is secure, TLS + PKI
  security should prevent any malicious host from using the VPN.


## Benefits of Running Inside a Docker Container

### The Entire Daemon and Dependencies are in the Docker Image

This means that it will function correctly (after Docker itself is setup) on
all distributions Linux distributions such as: Ubuntu, Arch, Debian, Fedora,
etc.  Furthermore, an old stable server can run a bleeding edge OpenVPN server
without having to install/muck with library dependencies (i.e. run latest
OpenVPN with latest OpenSSL on Ubuntu 12.04 LTS).

### It Doesn't Stomp All Over the Server's Filesystem

Everything for the Docker container is contained in two images: the ephemeral
run time image (kylemanna/openvpn) and the `$OVPN_DATA` data volume. To remove
it, remove the corresponding containers, `$OVPN_DATA` data volume and Docker
image and it's completely removed.  This also makes it easier to run multiple
servers since each lives in the bubble of the container (of course multiple IPs
or separate ports are needed to communicate with the world).

### Some (arguable) Security Benefits

At the simplest level compromising the container may prevent additional
compromise of the server.  There are many arguments surrounding this, but the
take away is that it certainly makes it more difficult to break out of the
container.  People are actively working on Linux containers to make this more
of a guarantee in the future.

## Differences from jpetazzo/dockvpn

* No longer uses serveconfig to distribute the configuration via https
* Proper PKI support integrated into image
* OpenVPN config files, PKI keys and certs are stored on a storage
  volume for re-use across containers
* Addition of tls-auth for HMAC security

## Originally Tested On

* Docker hosts:
  * server a [Digital Ocean](https://www.digitalocean.com/?refcode=d19f7fe88c94) Droplet with 512 MB RAM running Ubuntu 14.04
* Clients
  * Android App OpenVPN Connect 1.1.14 (built 56)
     * OpenVPN core 3.0 android armv7a thumb2 32-bit
  * OS X Mavericks with Tunnelblick 3.4beta26 (build 3828) using openvpn-2.3.4
  * ArchLinux OpenVPN pkg 2.3.4-1


## License
[![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fkylemanna%2Fdocker-openvpn.svg?type=large)](https://app.fossa.io/projects/git%2Bgithub.com%2Fkylemanna%2Fdocker-openvpn?ref=badge_large)
