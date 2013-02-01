# == lamp::install::mysql
#
#   This class installs mysql
#
class lamp::install::mysql (
    $config,
    $rootPassword
) {
    anchor{"lamp::install::mysql::begin": }

    if ($config == {}) {
        $setConfig = "absent"
    } else {
        $setConfig = "file"
    }

    # Install MySQL
    class { "::mysql":
        root_password => $rootPassword,
        require => Anchor["lamp::install::mysql::begin"]
    }
    -> file { "/etc/mysql/conf.d/settings.conf":
        before  => Anchor["lamp::install::mysql::end"],
        content => template("lamp/mysql/settings.conf.erb"),
        ensure  => $setConfig
    }

    anchor{"lamp::install::mysql::end":
        require => Anchor["lamp::install::mysql::begin"]
    }
}