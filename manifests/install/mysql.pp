# == lamp::install::mysql
#
#   This class installs mysql
#
class lamp::install::mysql (
    $rootPassword
) {
    anchor{"lamp::install::mysql::begin": }

    # Install MySQL
    class { "::mysql":
        root_password => $rootPassword,
        require => Anchor["lamp::install::mysql::begin"],
        before  => Anchor["lamp::install::mysql::end"]
    }

    anchor{"lamp::install::mysql::end":
        require => Anchor["lamp::install::mysql::begin"]
    }
}