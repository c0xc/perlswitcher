# Perlswitcher

Perlswitcher - Switch between system perl + local::lib and user perl

This is a cheap script to switch between system perl with local::lib
and user perl (installed by Perlbrew) without local::lib.  Environment
variables are set so that cpanm always knows where to install
(local::lib or user perl).  Nothing will be installed system-wide, no
root permissions are required.



INSTALLATION
------------

Install Perlbrew (<http://perlbrew.pl/>).

mkdir ~/perl5/userperls

Copy this script to ~/perl5/userperls/bashrc

echo '. ~/perl5/userperls/bashrc' >>~/.bashrc



USAGE
-----

$ perlswitch <perl>

$ perlinfo

$ perldoc ~/perl5/userperls/bashrc



