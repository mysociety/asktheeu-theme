asktheeu-theme
==============

This is the AskTheEU theme for Alaveteli. The intention is to support
simple overlaying of templates and resources without the need to touch
the core Alaveteli software.


## To install:

In the Alaveteli `general.yml` configuration file change the default
mysociety theme repository to your theme repository in the
[`THEME_URLS`](http://alaveteli.org/docs/customising/config/#theme_urls)
setting:

    THEME_URLS:
      - 'git://github.com/mysociety/asktheeu-theme.git'

You can then switch the theme the application is using:

    bundle exec rake themes:install

