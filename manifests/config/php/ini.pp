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
        target  => "/etc/php5/apache2/php.ini",
        entry   => $name,
        value   => $settings[$name],
        require => Package["php5"]
    }
    -> ::php::augeas { "php-cli-${name}":
        target => "/etc/php5/cli/php.ini",
        entry  => $name,
        value  => $settings[$name],
        require => Package["php5"]
    }
    -> anchor{ "lamp::config::php::ini::${name}::end": }
}