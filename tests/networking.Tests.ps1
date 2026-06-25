#Requires -Version 5.1
#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.0.0' }

BeforeAll {
  . $PSScriptRoot/../lib/networking.ps1
}

Describe 'Test-IPv4Address' {
  Context 'valid addresses' {
    It 'accepts standard private address' {
      Test-IPv4Address '192.168.1.1' | Should -BeTrue
    }

    It 'accepts loopback address' {
      Test-IPv4Address '127.0.0.1' | Should -BeTrue
    }

    It 'accepts lowest address' {
      Test-IPv4Address '0.0.0.0' | Should -BeTrue
    }

    It 'accepts highest address' {
      Test-IPv4Address '255.255.255.255' | Should -BeTrue
    }

    It 'accepts private network address' {
      Test-IPv4Address '10.0.0.0' | Should -BeTrue
    }
  }

  Context 'invalid addresses' {
    It 'rejects too few octets' {
      Test-IPv4Address '192.168.1' | Should -BeFalse
    }

    It 'rejects too many octets' {
      Test-IPv4Address '192.168.1.1.1' | Should -BeFalse
    }

    It 'rejects octet above 255' {
      Test-IPv4Address '192.168.1.256' | Should -BeFalse
    }

    It 'rejects negative octet' {
      Test-IPv4Address '192.168.-1.1' | Should -BeFalse
    }

    It 'rejects leading zero in octet' {
      Test-IPv4Address '192.168.01.1' | Should -BeFalse
    }

    It 'rejects non-numeric octet' {
      Test-IPv4Address '192.168.abc.1' | Should -BeFalse
    }
  }
}

Describe 'Test-IPv6Address' {
  Context 'valid addresses' {
    It 'accepts full uncompressed form' {
      Test-IPv6Address '2001:0db8:85a3:0000:0000:8a2e:0370:7334' | Should -BeTrue
    }

    It 'accepts compressed middle groups' {
      Test-IPv6Address '2001:db8::ff00:42:8329' | Should -BeTrue
    }

    It 'accepts loopback' {
      Test-IPv6Address '::1' | Should -BeTrue
    }

    It 'accepts unspecified address' {
      Test-IPv6Address '::' | Should -BeTrue
    }

    It 'accepts link-local address' {
      Test-IPv6Address 'fe80::1' | Should -BeTrue
    }

    It 'accepts compressed at end' {
      Test-IPv6Address '2001:db8:1:2:3:4:5::' | Should -BeTrue
    }

    It 'accepts compressed at start' {
      Test-IPv6Address '::ff00:42:8329' | Should -BeTrue
    }

    It 'accepts IPv4-mapped address' {
      Test-IPv6Address '::ffff:192.168.1.1' | Should -BeTrue
    }

    It 'rejects IPv4-mapped with invalid embedded IPv4' {
      Test-IPv6Address '::ffff:192.168.1.256' | Should -BeFalse
    }
  }

  Context 'invalid addresses' {
    It 'rejects multiple :: compressions' {
      Test-IPv6Address '2001::db8::1' | Should -BeFalse
    }

    It 'rejects invalid hex characters' {
      Test-IPv6Address '2001:db8:xxxx::1' | Should -BeFalse
    }

    It 'rejects group longer than 4 hex digits' {
      Test-IPv6Address '2001:db8:12345::1' | Should -BeFalse
    }

    It 'rejects too many groups without compression' {
      Test-IPv6Address '2001:db8:1:2:3:4:5:6:7' | Should -BeFalse
    }
  }
}
