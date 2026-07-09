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

sudo systemctl enable scandalous-web
sudo systemctl start scandalous-web
```

Install the mail service
```
sudo cp system/scandalous-mta.service /etc/systemd/system/
# Remember to edit the username

sudo systemctl enable scandalous-mta
sudo systemctl start scandalous-mta
```

### Linting and testing

Ruby (standardrb, rspec) and the browser JS in `public/script.js` (standard,
vitest) each have their own toolchain, wired together with a handful of npm
scripts so there's one place to remember the commands from:

```
bundle install       # Ruby gems (first time only)
npm install          # JS devDependencies (first time only)

npm run lint-js      # standard
npm run test-js      # vitest run (documentation-style output)
npm run lint-rb      # bundle exec standardrb
npm run test-rb      # bundle exec rspec -fd spec (documentation-style output)

npm run check        # all four, in order, stops at the first failure
```

`npm run check` runs the same four checks split across `ci.yml`'s `ruby`
and `javascript` jobs -- run it locally before pushing to catch what CI
would catch. It uses `vitest run --reporter=dot` and `rspec spec` (no
`-fd`) instead of `test-js`/`test-rb`'s documentation-style output, so
running all four together stays compact -- reach for `test-js`/`test-rb`
directly when you want the full describe/context/it breakdown.

`node_modules` is gitignored (like `Gemfile.lock`) and contains
platform-specific native binaries (Rollup/esbuild, via vitest). If you see
a "Cannot find module @rollup/rollup-\<platform\>" error -- usually after
`npm install` ran on a different OS/architecture against this same
checkout -- `rm -rf node_modules package-lock.json && npm install` to
reinstall for your machine.
