# BTTI
A project to rescue the BTTI database and turn it into a reliable static site

 - [About this project](#about-this-project)
 - [How to contribute](#how-to-contribute)
 - [How to build the static site](#how-to-build-the-static-site)
## About this project

The widely-used British Book Trade Index database hosted by the Bodleian Libraries
was taken down in 2024, and replaced by a TSV dump of the database tables available
at https://ora.ox.ac.uk/objects/uuid:19b63441-9497-4b07-903b-ec5742c44806 under
a CC Attribution-NonCommercial (CC BY-NC) licence.

This project generates from the db dump a functional static site that 
makes the data once again searchable and browsable. The site is fully 
Endings-compliant (https://endings.uvic.ca/compliance.html), and anyone will 
be able to build it for themselves and host it on their own servers.

The first version of the static site was released at https://hcmc.uvic.ca/project/bbti/ on 2024-12-20.

This project follows the CC Attribution-NonCommercial (CC BY-NC) licence placed
on the original data, and we fully acknowledge and appreciate the work and skill
that went into creating the original database. We do not intend to make substantive 
changes to the data, just to make it once more available in a form that is 
useful for scholars, but we have corrected typographical errors, damaged data, bad character encodings, and other minor issues as we have encountered them.

## How to contribute

At the moment, all contributions in the form of suggestions, bug reports, corrections to data and so on should be submitted in the form of GitHub Issues. Just log into GitHub (register for a free account if you don't have one), then click on Issues and hit the New Issue button. Fill in the form, giving as much detail as possible, and we'll do what we can to address the problem.

## How to build the static site

If you would like to build a working copy of the static  BBTI website for yourself and host it on your own server, you are welcome to do so; as they say, Lots of Copies Keeps Stuff Safe (LOCKSS). You will need to be on a Linux or Mac computer (we don't have access to Windows for development or testing, and we're not planning to provide support for building the site on Windows). You will need the following packages installed:

 - java
 - ant
 - ant-contrib
 
Detailed installation instructions will depend on your platform and distro, so please search the Web for those. You'll need at least 5 or 6 GB of free disk space. Once you're ready, clone the repository, then in a terminal, cd into the repository directory, and run "ant". The process should take about 15 minutes or more, depending your computer, and at the end you should have a new directory, "site", which contains a complete website about 3GB in size. You can copy this content to a web server, and everything should just work; no back-end services are required other than a standard web server.
