function plugin_update
    set --local status_code 0
    for plugin in $plugins
        set --local repo (string split -- @ $plugin)
        set --local plugin_name (path basename $repo[1])
        set --local plugin_dir $_plugins_dir/$plugin_name

        if contains $plugin_name $plugins_pinned
            echo Skipping pinned plugin (_bold_echo $plugin_name)
            continue
        end

        # plugin_commitish is the target version of the plugin,
        # e.g., a tag, branch, or commit hash.
        set --local plugin_commitish $repo[2]

        # default to HEAD (of the 'origin' remote)
        test -z "$plugin_commitish" || set plugin_commitish HEAD

        echo Checking for update to (_bold_echo $plugin_name)@$plugin_commitish

        # shared git fetch arguments
        set --local fetch_args -C $plugin_dir fetch --quiet --filter blob:none --depth 1

        if test $plugin_commitish = AUTO
            git $fetch_args --tags
            or { set status_code 1; continue }

            # get latest tag (reverse chronological)
            set plugin_commitish (git -C $plugin_dir tag --sort -creatordate \
                                  | head --lines 1)
            or { set status_code 1; continue }
            echo Found update to $plugin_commitish
        end

        # technically redundant fetch for AUTO
        # in that case, set FETCH_HEAD to the the latest tag
        git $fetch_args origin $plugin_commitish
        or { set status_code 1; continue }

        # current_commit is the hash of the local HEAD
        set --local current_commit (git -C $plugin_dir rev-parse --short HEAD)

        # new_commit is the hash of plugin_commitish on the 'origin' remote
        set --local new_commit (git -C $plugin_dir rev-parse --short FETCH_HEAD)

        if test $current_commit != $new_commit
            echo Updating from (git -C $plugin_dir describe --always) to $new_commit

            git -C $plugin_dir checkout --quiet $new_commit
            or { set status_code 1; continue }
        else
            echo Already up to date
        end

        for conf in $plugin_dir/conf.d/*.fish
            # support masking
            contains (path basename $conf) $user_conf || source $conf
            emit (path basename $conf | path change-extension '')_update
        end
    end
    return $status_code
end
