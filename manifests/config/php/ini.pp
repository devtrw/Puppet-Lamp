# == lamp::config::php::ini
#
#   This resource sets an INI file value
#
define lamp::config::php::ini (
    $settings,
    $target = "/etc/php5/apache2/php.ini",
    $ensure = "present"
) {
    anchor{ "lamp::config::php::ini::${name}::begin": }
    -> ::php::augeas { "php-apache-${name}":
        entry   => $name,
        notify  => Service["apache2"],
        require => Package["php5"],
        target  => "/etc/php5/apache2/php.ini",
        value   => $settings[$name]
    }
    -> ::php::augeas { "php-cli-${name}":
        entry   => $name,
        notify  => Service["apache2"],
        require => Package["php5"],
        target  => "/etc/php5/cli/php.ini",
        value   => $settings[$name]
    }
    -> anchor{ "lamp::config::php::ini::${name}::end": }
}