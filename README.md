# plug.fish

Minimalistic Git-based fish plugin manager.

> [!NOTE]
> plug.fish v3 is a complete rewrite.
> Previous versions are available on other branches.

## Features

- installs plugins into `$__fish_user_data_dir/plugins` instead of
  `$__fish_config_dir`
- flexible plugin management using `$plugins`
- supports
  [Fisher plugins](https://github.com/jorgebucaran/fisher#creating-a-plugin)
- <100 lines of code
- supports installing specific versions (specifically,
  [commitishes](https://git-scm.com/docs/gitglossary#Documentation/gitglossary.txt-commit-ishalsocommittish))
  of plugins
- supports cloning via SSH and/or HTTPS

## Requirements

- fish ≥ 3.5 (earlier versions untested)
- git

## Installation

1. Add the following to `$__fish_config_dir/config.fish`

   ```fish
   set plugins github.com:ziyong-was-taken/plug.fish
   source (path filter $__fish_user_data_dir/plugins/plug.fish/conf.d/plugin_load.fish
           or curl https://raw.githubusercontent.com/ziyong-was-taken/plug.fish/v3/conf.d/plugin_load.fish | psub)
   ```

2. Restart fish

   ```fish
   exec fish
   ```

## Usage

Adding plugins is as easy as setting `$plugins`:

```fish
# missing plugins are downloaded the next shell session
set plugins \
    github.com:ziyong-was-taken/plug.fish \
    github.com/other/plugin \         # HTTPS instead of SSH (cf. / and :)
    codeberg.org:git/repository@1.3.4 # specific version
```

Update plugins by running `plugin_update`.
This updates all unversioned plugins to `origin/HEAD`
and versioned plugins to `origin/version/HEAD`.
The special version `AUTO` will update to the latest annotated tag instead:

```shellsession
$ plugin_update
Skipping pinned plugin foo
Checking for update to bar@HEAD
Already up to date
Checking for update to baz@AUTO
Found update to 1.3.0
Updating from 1.2.0 to 42o1ee7
```

Don't want a plugin to update?
Add it to `$plugins_pinned`:

```fish
set plugins \
    github.com:ziyong-was-taken/plug.fish \
    github.com:plugin/to-be-pinned@v2.0.0
# use plugin name (without versioning) as identifier 
set plugins_pinned to-be-pinned
```

Remove a plugin from `$plugins` to disable it for the next shell session.

> [!WARNING]
> Disabled plugins remained installed in `$__fish_user_data_dir/plugins`.
> Run `plugin_uninstall` to uninstall them:
> 
> ```shellsession
> $ plugin_uninstall
> example-plugin is disabled, uninstall? (y/N)
> ```

## Advanced

### Manage plugins from the command-line

Don't like editing config files?
Make `$plugins` a
[universal variable](https://fishshell.com/docs/current/language.html#variables-universal)
and `set` becomes a plugin manager:

```fish
set --universal plugins \
    github.com:ziyong-was-taken/plug.fish \
    github.com:plugin/foo

# Add plugin bar
set --append plugins github.com:plugin/bar && exec fish

# Remove plugin foo
set --erase plugins[2] && plugin_uninstall
```

### Load plugins dynamically

Edit `$__fish_config_dir/config.fish`:

```diff
- set plugins \
+ set --query plugins || set plugins \
    github.com:ziyong-was-taken/plug.fish \
    github.com:plugin/foo \
    github.com:plugin/bar
```

Now you are able to load plugins however you want:

```fish
# only the first two plugins will be loaded in the new shell!
plugins=$plugins[..2] exec fish
```

### Masking `conf.d` scripts

Creating `$__fish_config_dir/conf.d/foo.fish` prevents loading
`some-plugin/conf.d/foo.fish` (masking).

This is per the behaviour described in
[fish documentation](https://fishshell.com/docs/current/language.html#configuration-files):

> If there are multiple files with the same name in these directories,
> only the first will be executed.
