# Development

### Install Ruby

Install ruby with both **apt install** and **rbenv** on the Pi.
```
sudo apt install autoconf bison build-essential curl git \
  libffi-dev libgdbm-dev libncurses5-dev libreadline-dev libssl-dev \
  libyaml-dev rbenv ruby-build ruby-dev ruby-full zlib1g-dev

ruby -v
# ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [arm-linux-gnueabihf]

rbenv install --list # latest 3.1.2
rbenv install 3.1.2 --verbose

ruby -v
# ruby 3.1.2p20 (2022-04-12 revision 4491bb740a) [armv6l-linux-eabihf]
```

### Install app packages

Specific gem packages will later be configured in the Gemfile.
```
gem install mail actionview rackup puma sinatra
```

### Open and map ports

The webserver and mail transfer agent need to run as an unprivileged user.
```
sudo apt install iptables-persistent

# Redirect port 80 to 8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8080

# Redirect port 25 to 2525
sudo iptables -t nat -A PREROUTING -p tcp --dport 25 -j REDIRECT --to-ports 2525

# Save your iptables rules
sudo netfilter-persistent save
```

### Enable and run services

Install the web service
```
sudo cp system/scandalous-web.service /etc/systemd/system/
# Remember to edit the username
sudo chmod a+rwx /etc/systemd/system/scandalous-web.service

sudo systemctl enable scandalous-web
sudo systemctl start scandalous-web
```

Install the mail service
```
sudo cp system/scandalous-mta.service /etc/systemd/system/
# Remember to edit the username
sudo chmod a+rwx /etc/systemd/system/scandalous-mta.service

sudo systemctl enable scandalous-mta
sudo systemctl start scandalous-mta
```
