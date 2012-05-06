# Puppet Shell

### Overview

This module provides a shell utility for traversing the Puppet Resource
Abstraction Layer.

### Disclaimer

Warning! While this software is written in the best interest of quality it has 
not been formally tested by our QA teams. Use at your own risk, but feel free 
to enjoy and perhaps improve it while you do.

Please see the included Apache Software License for more legal details 
regarding warranty.

### Requirements

So this module was predominantly tested on:

* Puppet 2.7.12 or greater (faces supported is required)

Other combinations may work, and we are happy to obviously take patches to 
support other stacks.

# Installation

As with most modules, its best to download this module from the forge:

http://forge.puppetlabs.com/puppetlabs/shell

If you want the bleeding edge (and potentially broken) version from github, 
download the module into your modulepath on your Puppetmaster. If you are not 
sure where your module path is try this command:

    puppet --configprint modulepath

For the shell to work on all the agents, you must enable pluginsync:

    [agent]
    pluginsync = true
    
# Quick Start

To fire up the shell, use it like so:

    # puppet shell
    / > 

At the prompt, the following commands can be used:

* ls - list all types, or instances of a single type
* cd - move around types and instances like a file hierarchy
* cat - view individual resource as puppet code
* cp - copy a resource to a new name
* rm - remove a resource
* edit - convert a resource to text, open it in your editor, and apply the results
 
# Detailed Usage

TBA
