### Description

`GoatOS Base` is a provides distributed LXC management for the GoatOS project.
`GoatOS Base` allows user to configure and manage ubuntu 14.04 instances with
Chef and perform distributed tasks using Blender.

### Usage
Typical GoatOS clusters are composed of one master and multiple slave. Master
hosts chef server, which act as configuration artifact repository and metadata
source, while the slave nodes run unprivileged LXC instances. Master and slave
host customization can be done via chef, while container management is done on
deman via blender.
`GoatOS Base` can be installed in a single host ( standalone mode) as well. For
this create a virtual box vm (or ec2 instance) with ubuntu 14.04. Create an user
with sudo access and bootstrap the instance with following command:

```sh
bundle exec goatos bootstrap -h 192.168.1.49 -u ubuntu -i ssh_key.rsa
```

Note: GoatOS installer will ask for ssh password when `-P` flag is passed, instead of the `-i` flag.

This will install chef server, LXC  and a goatos specific ssh keypair on the
instance. Chef and ssh configuration will be stored locally for downstream automation.
You should have chef's admin and validation key along with goatos specific ssh key on
the `keys` directory in your current directory. This will also generate a knife config
in `etc` directory for chef (you invoke all regular knife commands by passing
-c etc/knife.rb, hence forth).


Next you can check conatiners present on the goatos fleet like this:

```sh
bundle exec goatos lxc ls
```
This will use the ssh credentials (`goatos` user and an rsa key) generate via bootstrap.

To create a container, use the `goatos lxc create` command.
```sh
bundle exec goatos lxc create -N ct01
```
This will create an ubunu 14.04 container.


For multinode cluster, you can bootstrap the master with `-T master` option,
which will direct goatos to install only chef server specific components
in the target host. While rest of the instanec can be bootstrapped with
`-T slave` option, which will direct goatos to use local knife config (generated
via master bootstrap process) and install only LXC specific tooling.

