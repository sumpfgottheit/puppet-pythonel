class python::interpreter::prep {
	file { 'ppyp_helper':
		path => '/usr/local/bin/ppyp_helper',
		ensure => 'file'
	}
}
