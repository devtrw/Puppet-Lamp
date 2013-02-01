# == Resource: lamp::config::apache::vhost
#
#    Defines apache vhosts
#
define lamp::config::apache::vhost (
    $directives,
    $documentRoot,
    $vhostLogLevel,
    $vhostLogRoot,
    $serverAliases = [],
    $serverName    = "UNSET",
    $sslVhosts     = {},
    $useSsl        = false
) {
    if ($useSsl) {
        if (!has_key($sslVhosts, $name)) {
            fail(
"In order to enable ssl for $name it must have a corresponding entry in \
\$sslVhosts"
            )
        }
        $realServerName = $name
        $siteName = "${name}-443"
    } else {
        $siteName = $name
        if ($serverName == "UNSET") {
            fail("\
\$lamp::config::apache::vhost::serverName is required for non SSL vhosts.")
        }
        $realServerName = $serverName
    }

    file { "/etc/apache2/sites-available/${siteName}":
        ensure  => "file",
        content => template("lamp/apache/vhost.erb"),
        notify  => Service["apache2"],
        require => Package["apache2"]
    }
    -> exec { "enable-vhost-${siteName}":
        command => "a2ensite ${siteName}",
        unless  => "test -f /etc/apache2/sites-enabled/${siteName}",
        path    => "/usr/bin:/usr/sbin",
        notify  => Service["apache2"]
    }
}