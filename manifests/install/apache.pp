# == lamp::install::apache
#
#   This class installs apache
#
class lamp::install::apache (
    $listenPorts,
    $developmentEnvironment,
    $enableModSsl,
    $enableModRewrite,
    $serverName
){
    anchor{"lamp::install::apache::begin": }

    # Add port 443 if ssl is enabled
    $allListenPorts = unique( $enableModSSL ? {
        true    => flatten([$listenPorts, [443]]),
        default => $listenPorts
    } )

    class { "::apache":
        require => Anchor["lamp::install::apache::begin"],
        before  => Anchor["lamp::install::apache::end"]
    }
    file { "/etc/apache2/httpd.conf":
        ensure => "file",
        content => template("lamp/apache/httpd.conf.erb"),
        notify  => Service["apache2"],
        require => Package["apache2"]
    }
    file { "/etc/apache2/ports.conf":
        ensure => "file",
        content => template("lamp/apache/ports.conf.erb"),
        notify  => Service["apache2"],
        require => Package["apache2"]
    }
    file { "/etc/apache2/conf-enabled/security.conf":
        ensure => "file",
        content => template("lamp/apache/security.conf.erb"),
        notify  => Service["apache2"],
        require => Package["apache2"]
    }

    exec { "disable-vhost-000-default":
        command => "a2dissite 000-default",
        onlyif  => "test -f /etc/apache2/sites-enabled/000-default",
        path    => "/usr/bin:/usr/sbin",
        notify  => Service["apache2"],
        require => Package["apache2"]
    }

    # Mod Rewrite
    $ensureApacheModRewrite = $enableModRewrite ? {
        true    => "present",
        default => "absent"
    }
    ::apache::module{ "rewrite":
        ensure => $ensureApacheModRewrite
    }

    # Mod SSL
    $ensureApacheModSsl = $enableModSsl ? {
        true    => "present",
        default => "absent"
    }
    ::apache::module{ "ssl":
        ensure => $ensureApacheModSsl
    }

    anchor{"lamp::install::apache::end":
        require => Anchor["lamp::install::apache::begin"]
    }
}
