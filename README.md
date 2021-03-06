# Pacoloco - caching proxy server for pacman
Pacoloco is a web server that acts if it was an Arch/Manjaro Linux pacman repository.
Every time pacoloco server gets a request from user it downloads this file from
real Arch/Manjaro Linux mirror and bypasses it to the user. Additionally pacoloco
saves this file to local filesystem cache and serves it to the future users.

## How does it help?
Fast internet is still a luxury in many parts of the world. There are many places
where access to internet is expensive and slow due to geographical and economical
reasons.

Now think about a situation when multiple pacman users connected via fast local network.
Each of these users needs to download the same set of files. _Pacoloco_ allows to minimize
the Internet workload by caching pacman files content and serving it over
fast local network.

_Pacoloco_ does not mirror the whole Arch/Manjaro repository. It only downloads files needed by local users.
You can think of pacoloco as a lazy Arch/Manjaro mirror.

## Install

Use `docker-compose` with a compose file like in `docker-compose.yml.example`. Before starting it, you should configure the server.

## Configure
The server configuration is located inside the mounted volume in the root-directory with the name docker-compose.yml. Here is an example how the config file looks like:

```
port: 9129
cache_dir: /etc/pacoloco/cache
purge_files_after: 360000 # 360000 seconds or 100 hours
download_timeout: 200 # 200 seconds
repos:
  archlinux:
    urls:
      - http://mirror.lty.me/archlinux
      - http://mirrors.kernel.org/archlinux
  quarry:
    url: http://pkgbuild.com/~anatolik/quarry/x86_64
  sublime:
    url: https://download.sublimetext.com/arch/stable/x86_64
```
* `cache_dir` is the cache directory, this location needs to read/writable by the server process. It is helpful, to have the `cache_dir` pointing to `/etc/pacoloco/cache`, because it is in the volume and therefore portable across multiple versions of the container.
* `purge_files_after` specifies inactivity duration (in seconds) after which the file should be removed from the cache. This functionality uses unix "AccessTime" field to find out inactive files. Default value is `0` that means never run the purging.
* `port` is the server port inside the container.
* `download_timeout` is a timeout (in seconds) for internet->cache downloads. If a remote server gets slow and file download takes longer than this will be terminated. Default value is `0` that means no timeout.
* `repos` is a list of repositories to mirror. Each repo needs `name` and url of its Arch mirrors. Note that url can be specified either with `url` or `urls` properties, one and only one can be used for each repo configuration.

With the example configured above `http://YOURSERVER:9129/repo/archlinux` looks exactly like an Arch pacman mirror.
For example a request to `http://YOURSERVER:9129/repo/archlinux/core/os/x86_64/openssh-8.2p1-3-x86_64.pkg.tar.zst` will be served with file content from `http://mirror.lty.me/archlinux/core/os/x86_64/openssh-8.2p1-3-x86_64.pkg.tar.zst`

Once the pacoloco server is up and running it is time to configure the user host. Modify user's `/etc/pacman.conf` with

```
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

[quarry]
Server = http://yourpacoloco:9129/repo/quarry

[sublime-text]
Server = http://yourpacoloco:9129/repo/sublime
```

And `/etc/pacman.d/mirrorlist` with
```
Server = http://yourpacoloco:9129/repo/archlinux/$repo/os/$arch
```

That's it. Since now pacman requests will be proxied through our pacoloco server.

## Handling multiple architectures
*pacoloco* does not care about the architecture of your repo as it acts as a mere proxy.

Thus it can handle multiple different arches transparently. One way to do it is to add multiple
repositories with names `foobar_$arch` e.g.:

```
repos:
  archlinux_x86_64:
    urls:
      - http://mirror.lty.me/archlinux
      - http://mirrors.kernel.org/archlinux
  archlinux_armv7h:
    url: http://mirror.archlinuxarm.org
  archlinux_x86:
    url: http://mirror.clarkson.edu/archlinux32
```

Then modify user's `/etc/pacman.d/mirrorlist` and add

For x86_64:
```
Server = http://yourpacoloco:9129/repo/archlinux_$arch/$repo/os/$arch
```

For armv7h:
```
Server = http://yourpacoloco:9129/repo/archlinux_$arch/$arch/$repo
```

For x86:
```
Server = http://yourpacoloco:9129/repo/archlinux_$arch/$arch/$repo
```

Please note that `archlinux_$arch` is the repo name in pacoloco.yaml.

## Manjaro
Manjaro offeres multiple branches for the same architecture.
Machines with different branches but the same architecture can use the same repo like this:
```
repos:
  manjaro:
    urls:
    - http://manjaro.moson.eu
    - http://manjaro.re
    - http://www.uex.dk/public/manjaro
```

For stable
```
Server = http://yourpacoloco:9129/repo/manjaro/stable/$repo/$arch
```

For testing
```
Server = http://yourpacoloco:9129/repo/manjaro/testing/$repo/$arch
```

For unstable
```
Server = http://yourpacoloco:9129/repo/manjaro/unstable/$repo/$arch
```