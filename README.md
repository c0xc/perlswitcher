# Perlswitcher

Perlswitcher - Switch between system Perl + local::lib and user Perl

This is a cheap script to switch between system Perl with local::lib and
user Perl (installed by Perlbrew) without local::lib. Environment
variables are set so that cpanm always knows where to install packages
(local::lib or user Perl).

Nothing will be installed system-wide, no root
permissions are required.
Installing Perl packages manually in the system Perl as root
might create chaos and mess up the system.
Using this script, packages can be installed locally
without ever having to become root
and if some packages are causing trouble in a user Perl,
that Perl installation can simply be deleted.



INSTALLATION
------------

Install Perlbrew (<http://perlbrew.pl/>).

    $ mkdir ~/perl5/userperls

Copy this script to ~/perl5/userperls/bashrc

    $ echo '. ~/perl5/userperls/bashrc' >>~/.bashrc

Add symlinks for directories to be prepended to $PATH. Their names must
begin with "path-".

    $ cd ~/perl5/userperls/
    $ ln -s ~/perl5/bin path-bin
    $ ln -s ~/perl5/perlbrew/bin path-perlbrew-bin



UNINSTALLATION
--------------

Remove this script from your "~/.bashrc".

Delete the "userperls" directory.



USAGE
-----

Switch to a user Perl installed by Perlbrew:

    $ perlswitch perl-5.18.4

Find out if user Perl or system Perl is currently being used:

    $ perlinfo

Switch back to system Perl:

    $ perlswitch

Use perldoc to see some examples:

    $ perldoc ~/perl5/userperls/bashrc



License
-------

Please see the file called LICENSE.



