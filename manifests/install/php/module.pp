# == Resource lamp::install::php::module
#
#   This resource handles the installation of php modules
#
define lamp::install::php::module {

    anchor{ "lamp::install::php::module::${name}::begin": }

    Exec { path => "/bin:/usr/bin:/usr/sbin" }

    if ( member(["curl", "gd", "intl", "mysql", "xsl"], $name) ) {
        ::php::module { $name:
            before  => Anchor["lamp::install::php::module::${name}::end"],
            require => Anchor["lamp::install::php::module::${name}::begin"]
        }
    } elsif ( member(["imagick"], $name) ) {
        ::php::module { $name:
            before        => Anchor["lamp::install::php::module::${name}::end"],
            require       => Anchor["lamp::install::php::module::${name}::begin"],
            version       => "latest"
        }
    } elsif ( member(["apc", "soap"], $name) ) {
        ::php::module { $name:
            before        => Anchor["lamp::install::php::module::${name}::end"],
            module_prefix => "php-",
            require       => Anchor["lamp::install::php::module::${name}::begin"],
            version       => "latest"
        }
    } elsif ( $name == "phpunit" ) {
          ::php::pear::module { "pear.phpunit.de/PHPUnit":
              before      => Anchor["lamp::install::php::module::${name}::end"],
              alldeps     => true,
              notify      => Service["apache2"],
              require     => Anchor["lamp::install::php::module::${name}::begin"],
              use_package => false
          }
    } elsif ( $name == "dbunit" ) {
        # Make sure Yaml version is below 2.2. PHPUnit fails with Yaml 2.2 as of
        # DBUnit v1.2.1.
        ::php::pear::module { "pear.symfony.com/Yaml-2.1.6":
            alldeps     => true,
            before      => Anchor["lamp::install::php::module::${name}::end"],
            notify      => Service["apache2"],
            require     => Anchor["lamp::install::php::module::${name}::begin"],
            use_package => false
        }
        -> ::php::pear::module { "pear.phpunit.de/DbUnit":
            before      => Anchor["lamp::install::php::module::${name}::end"],
            alldeps     => true,
            notify      => Service["apache2"],
            require     => Anchor["lamp::install::php::module::${name}::begin"],
            use_package => false
        }
    } elsif ( $name == "git" ) {
        ::php::pear::module { "pear/VersionControl_Git":
            before           => Anchor["lamp::install::php::module::${name}::end"],
            notify           => Service["apache2"],
            preferred_state  => "alpha",
            require          => Anchor["lamp::install::php::module::${name}::begin"],
            use_package      => false
        }
    } elsif ( $name == "oauth" ) {
        package { "libpcre3-dev":
            ensure  => "latest"
        }
        -> ::php::pecl::module { "oauth":
            before      => Anchor["lamp::install::php::module::${name}::end"],
            require     => Anchor["lamp::install::php::module::${name}::begin"],
            use_package => false
        }
        -> file { "/etc/php5/conf.d/oauth.ini":
            content => "extension=oauth.so",
            ensure  => file,
            notify  => Service["apache2"]
        }
    } elsif ( $name == "phing" ) {
        ::php::pear::module { "pear.phing.info/phing":
            before      => Anchor["lamp::install::php::module::${name}::end"],
            notify      => Service["apache2"],
            require     => Anchor["lamp::install::php::module::${name}::begin"],
            use_package => false
        }
    } elsif ( $name == "phpcs" ) {
        ::php::pear::module { "pear/PHP_CodeSniffer":
            before           => Anchor["lamp::install::php::module::${name}::end"],
            notify           => Service["apache2"],
            require          => Anchor["lamp::install::php::module::${name}::begin"],
            use_package      => false
        }
    } elsif ( $name == "phpcpd" ) {
        ::php::pear::module { "pear.phpunit.de/phpcpd":
            before           => Anchor["lamp::install::php::module::${name}::end"],
            notify           => Service["apache2"],
            require          => Anchor["lamp::install::php::module::${name}::begin"],
            use_package      => false
        }
    } elsif ( $name == "phpmd" ) {
        ::php::pear::module { "pear.phpmd.org/PHP_PMD":
            before           => Anchor["lamp::install::php::module::${name}::end"],
            notify           => Service["apache2"],
            require          => Anchor["lamp::install::php::module::${name}::begin"],
            use_package      => false
        }
    } elsif ( $name == "xdebug" ) {
        ::php::pecl::module { "xdebug":
            before      => Anchor["lamp::install::php::module::${name}::end"],
            notify      => Service["apache2"],
            require     => Anchor["lamp::install::php::module::${name}::begin"],
            use_package => false
        }
        -> file { "/etc/php5/conf.d/xdebug.ini":
            before  => Anchor["lamp::install::php::module::${name}::end"],
            content => template("lamp/php/xdebug.ini"),
            ensure  => file,
            notify  => Service["apache2"]
        }
    } else {
        fail("PHP module \"${name}\" installation is not yet supported by devtrw-lamp")
    }

    anchor{ "lamp::install::php::module::${name}::end":
        require => Anchor["lamp::install::php::module::${name}::begin"]
    }
}
