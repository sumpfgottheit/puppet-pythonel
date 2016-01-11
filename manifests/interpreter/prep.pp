class pythonel::interpreter::prep {
	file { 'pythonel_helper':
        path   => '/usr/local/bin/pythonel_helper',
		source => 'puppet:///modules/pythonel/pythonel_helper',
		owner  => 'root',
		group  => 'root',
        mode   => '0755'
	}
}
