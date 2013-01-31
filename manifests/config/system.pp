# == lamp::config::system
#
#   This class iconfigures the system
#
class lamp::config::system (
    $timezone
) {
    # Ensure cron daemon is running
    service { "cron":
        ensure     => "running",
        hasrestart => true
    }

    # Set system timezone
    file { "/etc/localtime":
        ensure => link,
        target => $timezone,
        notify => Service["cron"]
    }
}