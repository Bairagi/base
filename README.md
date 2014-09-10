### Description
GoatOS is a collection of infrastructure automation tools.
`GoatOS Base` is a provides distributed LXC management for the GoatOS project.
`GoatOS Base` allows user to configure and manage ubuntu 14.04 instances with
Chef and perform distributed tasks using Blender.

### Setup
clone the GoatOS base repo, and run bundle install
```sh
git clone https://github.com/GoatOS/base.git goatos_base
cd goatos_base
bundle install --path .bundle
```

### Usage
Typical GoatOS clusters are composed of one master and multiple slave. Master
hosts chef server, which act as configuration artifact repository and metadata
source, while the slave nodes run unprivileged LXC instances. Master and slave
host customization can be done via chef, while container management is done on
demand via blender.

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
This will create an ubunu 14.04 container. Additional flags can be used to create container
specify other distro, release, archtecture. You can specify network services that you want
to expose from the container using the `--expose` flag.
 
```sh
bundle exec goatos lxc create -N ct01 --expose 22:tcp:2201
```
Above command will save the '22:tcp:2201' as metadata for the container. This metadata is
processed by chef runs that controls the host running container to expose outside using haproxy.
The string `22:tcp:2201` express the intent to expose port 22 (SSH i.e) of container on port
2201 on the host. Following goatos command will propagate these changes via chef.

```sh
bundle exec goatos run-chef -u USER -i key.rsa
```
You should be able to ssh into one of the container directly by `ssh -p 2201 HOST_IP`. Note,
the default container have a prebaked user with name `ubuntu` and password `ubuntu`


For multinode cluster, you can bootstrap the master with `-T master` option,
which will direct goatos to install only chef server specific components
in the target host. While rest of the instanec can be bootstrapped with
`-T slave` option, which will direct goatos to use local knife config (generated
via master bootstrap process) and install only LXC specific tooling.

