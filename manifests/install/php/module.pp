# == Resource lamp::install::php::module
#
#   This resource handles the installation of php modules
#
define lamp::install::php::module {

    if ( member(["curl", "dev", "mysql", "intl"], $name) ) {
        ::php::module { $name: }
    }
    elsif ( member(["apc"], $name) ) {
        ::php::module { $name:
            module_prefix => "php-",
            version       => "latest"
        }
    }
    else {
        fail("PHP module \"${name}\" installation is not yet supported by devtrw-lamp")
    }
}