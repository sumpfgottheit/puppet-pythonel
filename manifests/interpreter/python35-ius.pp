class python::interpreter::python35-ius {

	$interpreter  = 'python35-ius'
	$bindir       = '/usr/bin'
	$packages     = ['python35u', 'python35u-devel', 'python35u-pip']

	#
	# Only change if binaries are not called python, pip or virtualenv
	#
	$python             = "$bindir/python3.5"
	$pip                = "$bindir/pip3.5"
	$virtualenv         = "/usr/local/bin/python35-ius/virtualenv-3.5"

  #
  # Hardly need any changes from here..
  #
  $upgrade_pip        = hiera("python::interpreter::${interpreter}::upgrade_pip", false)
  $upgrade_virtualenv = hiera("python::interpreter::${interpreter}::upgrade_virtualenv", false)
  $packages_ensure    = hiera("python::interpreter::${interpreter}::packages_ensure", 'present')
  $pip_config_file    = hiera("python::interpreter::${interpreter}::pip_config_file", '')
  $global_pip_config_file = hiera("python::interpreter::pip_config_file", '')

  $_pip_config_file = $pip_config_file ? {
    ''       => $global_pip_config_file,
    default  => $pip_config_file
  }
  $environment = $_pip_config_file ? {
    ''      => [],
    default => [ "PIP_CONFIG_FILE=$pip_config_file"]
  }

	include python::interpreter::prep # Define ppyp_helper
	package { $packages:
		ensure => $packages_ensure
	}

  file {'/usr/local/bin/python35-ius':
    ensure => 'directory'
  }
  exec { "install-virtualenv-$interpreter":
    command     => "/usr/local/bin/ppyp_helper $pip install virtualenv --install-option='--install-scripts=/usr/local/bin/python35-ius'",
    environment => $environment,
    unless      => "/usr/local/bin/ppyp_helper $pip install virtualenv --install-option='--install-scripts=/usr/local/bin/python35-ius' |grep 'Requirement already satisfied (use --upgrade to upgrade): virtualenv'",
    require     => [File['ppyp_helper', '/usr/local/bin/python35-ius'], Package[$packages]]
  }

  if $upgrade_pip {
    exec { "upgrade-pip-$interpreter":
      command     => "/usr/local/bin/ppyp_helper $pip install --upgrade pip",
      environment => $environment,
      unless      => "/usr/local/bin/ppyp_helper $pip install --upgrade pip |grep 'Requirement already up-to-date: pip'",
      require     => [File['ppyp_helper'], Package[$packages]]
    }
  }
  if $upgrade_virtualenv {
    exec { "upgrade-virtualenv-$interpreter":
      command => "/usr/local/bin/ppyp_helper $pip install --upgrade virtualenv",
      environment => $environment,
      unless  => "/usr/local/bin/ppyp_helper $pip install --upgrade virtualenv |grep 'Requirement already up-to-date: virtualenv'",
      require => [File['ppyp_helper', '/usr/local/bin/python35-ius'], Package[$packages], Exec["install-virtualenv-$interpreter"]]
    }
  }


}
