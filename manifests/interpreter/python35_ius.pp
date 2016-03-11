class pythonel::interpreter::python35_ius {

    $interpreter  = 'python35_ius'
    $bindir       = '/usr/bin'
    $packages     = ['python35u', 'python35u-devel', 'python35u-pip']

    #
    # Only change if binaries are not called python, pip or virtualenv
    #
    $python          = "$bindir/python3.5"
    $pip             = "$bindir/pip3.5"
    $virtualenv      = "/usr/local/bin/python35-ius/virtualenv"
    $extra_pip_args  = ""
    $base_script_dir = '/usr/local/bin/python35-ius'

    #
    # Hardly need any changes from here..
    #
    $upgrade_pip            = hiera("pythonel::interpreter::${interpreter}::upgrade_pip", false)
    $upgrade_virtualenv     = hiera("pythonel::interpreter::${interpreter}::upgrade_virtualenv", false)
    $packages_ensure        = hiera("pythonel::interpreter::${interpreter}::packages_ensure", 'present')
    $pip_config_file        = hiera("pythonel::interpreter::${interpreter}::pip_config_file", '')
    $global_pip_config_file = hiera("pythonel::interpreter::pip_config_file", '')

    ################################
    # YumRepo and package handling #
    # Adapt to your needs          #
    ################################
    #
    # sudo yum install https://rhel7.iuscommunity.org/ius-release.rpm
    #
    package { $packages:
        ensure => $packages_ensure
    }
    ####################################
    # Packages should now be installed #
    ####################################

    anchor { "$interpreter":
        require => Package[$packages]
    }

    $_pip_config_file = $pip_config_file ? {
        ''       => $global_pip_config_file,
        default  => $pip_config_file
    }
    $environment = $_pip_config_file ? {
        ''      => [],
        default => [ "PIP_CONFIG_FILE=$_pip_config_file"]
    }


    include pythonel::interpreter::prep # Define pythonel_helper

    $_extra_pip_args = $base_script_dir ? {
        ""      => $extra_pip_args,
        default => "--install-option='--install-scripts=$base_script_dir' $extra_pip_args"
    }

    file { '/usr/local/bin/python35-ius':
        ensure => 'directory'
    }

    exec { "install-virtualenv-$interpreter":
        command     => "/usr/local/bin/pythonel_helper $pip install virtualenv $_extra_pip_args",
        environment => $environment,
        unless      => "/usr/local/bin/pythonel_helper $pip install virtualenv $_extra_pip_args |grep 'Requirement already satisfied (use --upgrade to upgrade): virtualenv'",
        require     => [File['pythonel_helper', '/usr/local/bin/python35-ius'], Package[$packages]]
    }

    if $upgrade_pip {
        exec { "upgrade-pip-$interpreter":
            command     => "/usr/local/bin/pythonel_helper $pip install --upgrade pip",
            environment => $environment,
            unless      => "/usr/local/bin/pythonel_helper $pip install --upgrade pip |grep 'Requirement already up-to-date: pip'",
            require     => [File['pythonel_helper'], Package[$packages]]
        }
    }
    if $upgrade_virtualenv {
        exec { "upgrade-virtualenv-$interpreter":
            command     => "/usr/local/bin/pythonel_helper $pip install --upgrade virtualenv",
            environment => $environment,
            unless      => "/usr/local/bin/pythonel_helper $pip install --upgrade virtualenv |grep 'Requirement already up-to-date: virtualenv'",
            require     => [File['pythonel_helper', '/usr/local/bin/python35-ius'], Package[$packages], Exec["install-virtualenv-$interpreter"]]
        }
    }


}
