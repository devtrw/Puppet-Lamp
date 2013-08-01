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
    file { "/etc/apache2/conf-available/httpd.conf":
        ensure => "file",
        require => Package["apache2"],
        content => template("lamp/apache/httpd.conf.erb")
    }
    -> exec{ "/usr/sbin/a2enconf httpd":
      notify  => Service["apache2"]
    }
    file { "/etc/apache2/ports.conf":
        ensure => "file",
        content => template("lamp/apache/ports.conf.erb"),
        notify  => Service["apache2"],
        require => Package["apache2"]
    }
    file { "/etc/apache2/conf-available/security.conf":
        ensure => "file",
        require => Package["apache2"],
        content => template("lamp/apache/security.conf.erb")
    }
    -> exec{"/usr/sbin/a2enconf security":
        notify  => Service["apache2"]
    }

    # Clean up old config files if they are lying around
    file {["/etc/apache2/httpd.conf"]: ensure => "absent"}

    exec { "disable-vhost-000-default":
        command => "a2dissite 000-default",
        onlyif  => "test -f /etc/apache2/sites-enabled/000-default*",
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
