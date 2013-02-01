name 'devtrw-lamp'
version '0.1.1'

author 'DevTRW'
license ''
project_page 'https://bitbucket.org/devtrw/puppet-lamp'
source 'https://bitbucket.org/devtrw/puppet-returns'
summary 'Installation for a basic LAMP stack running php 5.4'
description 'Provides structure for installing common assets of a LAMP stack
running php 5.4 and Ubuntu 12.04 on AWS.

devtrw/composer 0.0.1 is not public, if using librarian-puppet you can load it
with the following config:
    mod "lamp",
        :git => "git@bitbucket.org:devtrw/puppet-lamp.git"

example42/php v2.0.8 is missing some files on the forge. Load it with librarian
using:

    mod "php",
        :git => "git@github.com:example42/puppet-php.git",
        :ref => "2023c5f" #2.0.8
'

# dependency 'devtrw/composer',  '0.0.1'
# dependency 'example42/php',    '2.0.8'

dependency 'example42/apache',  '2.0.7'
dependency 'example42/mysql',   '2.0.7'
dependency 'example42/puppi',   '>= 2.0.0'
dependency 'puppetlabs/apt',    '1.1.0'
dependency 'puppetlabs/stdlib', '3.2.0'
