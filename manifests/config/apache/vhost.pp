# == Resource: lamp::config::apache::vhost
#
#    Defines apache vhosts
#
define lamp::config::apache::vhost (
    $directives,
    $documentRoot,
    $vhostLogLevel,
    $vhostLogRoot,
    $serverAliases,
    $serverName = $name
) {
    file { "/etc/apache2/sites-available/${name}":
        ensure  => "file",
        content => template("lamp/apache/vhost.erb"),
        notify  => Service["apache2"],
        require => Package["apache2"]
    }
    -> exec { "enable-vhost-${serverName}":
        command => "a2ensite ${name}",
        unless  => "test -f /etc/apache2/sites-enabled/${name}",
        path    => "/usr/bin:/usr/sbin",
        notify  => Service["apache2"]
    }
}