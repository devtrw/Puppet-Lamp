# == lamp::config::apt
#
#   This class iconfigures the system
#
class lamp::config::apt (
    $repositories
) {
    include ::apt

    anchor{"lamp::config::apt::begin": }
    notify{"update - begin":}

    ::apt::ppa { $repositories:
        require => Anchor["lamp::config::apt::begin"],
        before  => Anchor["lamp::config::apt::end"]
    }

    anchor{"update::end": require => Anchor["lamp::config::apt::begin"] }
    notify{"update - end":
        require => Anchor["lamp::config::apt::end"]
    }

}