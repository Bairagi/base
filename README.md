=== Usage
To setup a GoatOS standalone node (i.e. chef server + unprivileged LXC + SSH keys for blender)
- Create a virtual box vm (or ec2 instance) for ubuntu 14.04. Create an user with sudo access.
- Run goatos bootstrap.

```sh
bundle exec ./bin/goatos bootstrap -b standalone -t 192.168.1.49 -u ubuntu

```

GoatOS installer will ask for ssh password. The installer will install chef server on the specified
server. And copy over the keys (admin and vaildation key) to local workstation. Next GoatOS installer
will setup unprvileged LXC capabilities under `goatos` user name. The installer will also set up ssh
keypairs for goatos user.

Once the master (chef server) is bootstrapped, necessary keys will be placed  in `keys/` subdirectory.
Additional hosts (lxc hosts, without chef server) can be added using:

```sh
bundle exec ./bin/goatos bootstrap -b slave -t 192.168.1.49 -u ubuntu
```
