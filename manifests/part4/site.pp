node 'webserver' {

    package { 'apache2':
        ensure => installed,
    }

    service { 'apache2':
        ensure => running,
        enable => true,
        require => Package['apache2'],
    } 

    exec { 'enable_proxy_http':
        command => '/usr/sbin/a2enmod proxy_http',
        creates => '/etc/apache2/mods-enabled/proxy_http.load',
        require => Package['apache2'],
        notify => Service['apache2'],
    } 

    file { '/etc/apache2/conf-available/reverseproxy.conf':
        source => 'puppet:///files/reverseproxy.conf',
        owner => 'root',
        group => 'root',
        mode => '0644',
        require => [Package['apache2'],Exec['enable_proxy_http']],
		notify => Exec['enable_reverse_proxyconf'],
    }

    exec { 'enable_reverse_proxyconf': 
        command => '/usr/sbin/a2enconf reverseproxy.conf',
        refreshonly => true,
        notify => Service['apache2'],
    }

}

node 'appserver' {

    $requiredtools = ['gunicorn', 'supervisor', 'python-mysqldb', 'python-falcon']
    package { $requiredtools: 
    ensure => installed,
    }

    file { '/opt/testapp':
        ensure => directory,
        owner => nobody,
        group => nogroup,
        mode =>  '0755',
    }  

    file { '/opt/testapp/testapp.py':
        ensure => present,
        owner => nobody,
        group => nogroup,
        mode => '0755',
        require => File['/opt/testapp'],
        source => 'puppet:///files/testapp.py',
    }


    service { 'supervisor':
        enable => true,
        ensure => running,
        require => Package['supervisor'],
    }


    file { '/etc/supervisor/conf.d/testapp.conf':
        source => 'puppet:///files/testapp.conf',
        owner => 'root',
        group => 'root',
        mode => '0644',
        ensure => present,
        require => Package['supervisor'],
    }

    exec { 'reread-config':
        command => '/usr/bin/supervisorctl reread',
        refreshonly => true,
    }

    exec { 'restart-application':
        command => '/usr/bin/supervisorctl restart testapp',
        refreshonly => true,
    }

    File['/etc/supervisor/conf.d/testapp.conf'] ~> Exec['reread-config'] ~> Exec['restart-application']

}

node 'database' {
}
