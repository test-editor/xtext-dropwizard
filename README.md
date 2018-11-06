# xtext-dropwizard generic project

This project provides a base for any xtext dsl project used in the context of dropwizard rest services. As an example, a simple dsl is provided to show how these blue print projects can be used.

It provides the following sub projects:
- org.testeditor.web.dropwizard
- org.testeditor.web.dropwizard.testing
- org.testeditor.web.dropwizard.xtext
- org.testeditor.web.dropwizard.xtext.testing

## org.testeditor.web.dropwizard

Provides guice injection and authorization.

## org.testeditor.web.dropwizard.testing

Provides testing utilities allowing for unit and integration tests.

## org.testeditor.web.dropwizard.xtext

Provides xtext services with index integration.

## org.testeditor.web.dropwizard.xtext.testing

Provides testing utilities allowing for unit and integration tests of dsls.

# Setup development

Make sure to have a working [nix](https://nixos.org/nix/) installation. Please ensure that the `nixpkgs-unstable` channel is available. It
can be added with `nix-channel --add https://nixos.org/channels/nixpkgs-unstable`.

To enter the development environment, execute `NIXPKGS_ALLOW_UNFREE=1 nix-shell` in this repos root directory. For even more convenience,
please install [direnv](https://github.com/direnv/direnv) which will enter the development environment automatically for you.

Once within the development environment, run `./gradlew test` to resolve all necessary dependencies.

# Release process

* switch to the master branch
* execute `./gradlew release` 
* enter this release version
* enter the next version 

The branch will be tagged accordingly and the travis build will make sure that the released version artifacts are uploaded. 

The next version will be put into `gradle.properties` and this change will be committed.
