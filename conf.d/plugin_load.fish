# helper function
function _bold_echo
    echo (set_color --bold)$argv(set_color normal)
end

set --query _plugins_dir && exit

set --global _plugins_dir $__fish_user_data_dir/plugins
set --local user_conf (path basename $__fish_config_dir/conf.d/*.fish)

for plugin in $plugins
    # plugins are URLs of the form
    # - host.com:user/repo[@commitish] (SSH) or
    # - host.com/user/repo[@commitish] (HTTPS)
    # default commitish is HEAD
    set --local repo (string split -- @ $plugin) || set --local repo[2] HEAD
    set --local plugin_name (path basename $repo[1])
    set --local plugin_dir $_plugins_dir/$plugin_name

    set fish_complete_path \
        $fish_complete_path[1] \
        $plugin_dir/completions \
        $fish_complete_path[2..]
    # functions should be available before emitting events
    set fish_function_path \
        $fish_function_path[1] \
        $plugin_dir/functions \
        $fish_function_path[2..]

    test -e $plugin_dir || set --local install

    if set --query install
        echo Installing (_bold_echo $plugin_name)

        # --filter blob:none -> only download files when needed
        # --revision $repo[2] --depth 1 -> only clone revision (no history)
        set --local clone_args clone \
            --quiet --filter blob:none \
            --revision $repo[2] --depth 1
        switch $repo[1]
            case '*:*' # SSH
                git $clone_args git@$repo[1] $plugin_dir
            case '*' # HTTPS
                git $clone_args https://$repo[1] $plugin_dir
        end
    end

    for conf in $plugin_dir/conf.d/*.fish
        # support masking
        contains (path basename $conf) $user_conf || source $conf
        set --query install && emit (path basename $conf | path change-extension '')_install
    end
end
