# Development

This project is for fun. For production, please use (lambada)[https://github.com/woodie/lambada].

### Install tools and packages

[mise](https://mise.jdx.dev/) installs the Ruby and Node versions in `mise.toml`.
```
mise install
bundle install
npm install
```

### Install app packages

Specific gem packages will later be configured in the Gemfile.
```
gem install mail actionview rackup puma sinatra
```

### Linting and testing

Ruby (standardrb, rspec) and the browser JS in `public/script.js` (standard,
vitest) each have their own toolchain, wired together with a handful of npm
scripts so there's one place to remember the commands from:

```
bundle install       # Ruby gems (first time only)
npm install          # JS devDependencies (first time only)

npm run lint-js      # standard
npm run test-js      # vitest run (Vitest's own tree output)
npm run lint-rb      # bundle exec standardrb
npm run test-rb      # bundle exec rutidy -fv spec (Vitest-tree output, matching test-js)

npm run check        # all four, in order, stops at the first failure
```

`npm run check` runs the same four checks split across `ci.yml`'s `ruby`
and `javascript` jobs -- run it locally before pushing to catch what CI
would catch. It uses `vitest run --reporter=dot` and `rspec spec` (no
`rutidy`) instead of `test-js`/`test-rb`'s tree output, so running all
four together stays compact -- reach for `test-js`/`test-rb` directly
when you want the full describe/context/it breakdown.

`node_modules` is gitignored (like `Gemfile.lock`) and contains
platform-specific native binaries (Rollup/esbuild, via vitest). If you see
a "Cannot find module @rollup/rollup-\<platform\>" error -- usually after
`npm install` ran on a different OS/architecture against this same
checkout -- `rm -rf node_modules package-lock.json && npm install` to
reinstall for your machine.
