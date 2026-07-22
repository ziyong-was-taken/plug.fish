function plugin_update
    set --local status_code 0
    # iterate by index to allow dynamic allocation
    for i in (seq (count $plugins))
        set --local repo (string split -- @ $plugins[$i])
        set --local plugin_name (path basename $repo[1])
        set --local plugin_dir $_plugins_dir/$plugin_name

        if contains $plugin_name $plugins_pinned
            echo Skipping pinned plugin (_bold_echo $plugin_name)
            continue
        end

        # plugin_commitish is the specified/target version of the plugin. in
        # other words, it represents the goal of the update. it can be a tag, a
        # branch, or a literal commit hash.
        #
        # if unset/if the user does not specify, defaults to HEAD (which means
        # the HEAD of the origin remote)
        set --local plugin_commitish $repo[2]
        if test -z "$plugin_commitish"
            set plugin_commitish HEAD
        end

        echo Checking for update to (_bold_echo $plugin_name)@$plugin_commitish

        # shared git fetch arguments
        set --local fetch_args -C $plugin_dir fetch --quiet --filter blob:none --depth 1

        if test $plugin_commitish = AUTO
            # this branch contains an additional fetch. in the end, that's
            # probably worth it for better/simpler overall control flow
            git $fetch_args --tags
            or { set status_code 1; continue }
            set plugin_commitish (git -C $plugin_dir tag --sort -creatordate \
                                           | head --lines 1)
            or { set status_code 1; continue }
            echo Found update to $plugin_commitish
        end

        # perform the fetch, recording the commits for local HEAD and the remote HEAD
        git $fetch_args origin $plugin_commitish
        or { set status_code 1; continue }

        # current_commit is the hash of the local HEAD
        set --local current_commit (git -C $plugin_dir rev-parse --short HEAD)

        # new_commit is the actual hash pointed to by plugin_commitish on
        # the origin remote
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
