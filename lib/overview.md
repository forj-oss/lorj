As described by the [concept](concept_md.html), lorj is a combination of 4 blocks:

* The main of your application
* a Config system
* a Generic process
* a controller

Those blocks communicate through lorj Core, except the config system which can be
accessible from anywhere.


# Lorj configuration
To run your application with lorj, you will certainly need to configure lorj
()Lorj::Core), like the application name, the application path, log file name, etc...

For details about the lorj configuration, please read documentation on PrcLib.


# Config system
About the config system, lorj provides 2 differents predefined configuration classes.

* Lorj::Config  - Basic config systems. Data are retrieved in **application defaults**, then **local config**, then **runtime**.
* Lorj::Account - Based on Lorj::Config, it introduces an **account** file, between **local config** and **runtime**.

Those 2 classes are based on a generic PRC::BaseConfig(or SectionConfig), and PRC::CoreConfig.
PRC::CoreConfig introduce a way to get data from different source, organized by layers.
It automates the notion of, 'if not there here, go to the next one, until default'
A config layer, can be a instant memory data, created on demand, or any kind of
local yaml file, loaded at startup or runtime.

For details, see PRC::CoreConfig

Lorj has implemented some classes, predefining:
For Lorj::Config : 3 layers
* Application defaults (defaults.yaml). The file is loaded thanks to Lorj PrcLib configuration
  This layer is used to predefine lorj data model, to setup the account file.
* local data. Refer to a user local application config file.
* runtime. A lorj process can get/set any data on needs.

Details available from Lorj::Config

For Lorj::Account: 4 layers
* Application defaults (defaults.yaml). The file is loaded thanks to Lorj PrcLib configuration
  This layer is used to predefine lorj data model, to setup the account file.
* local data. Refer to a user local application config file.
* account. Depending on needs, lorj can setup an account file to preload some data
  to help the process or the dedicated controller to do the work.
  Ex: with a cloud process, a cloud controller will need some credentials. lorj setup
      will be able to ask those information to the user, save them to the account file
      and Lorj::Account will be able to load them for process execution.
* runtime. A lorj process can get/set any data on needs.

Details available from Lorj::Account, and BaseDefinition.setup


# Generic process

The generic Process is your application process.

To simplify the vision, imagine a human as an application
Then the application process is the brain.

But to keep the power of lorj, a process must respect some rules:
* A process defines a data model which is known only by it self.
* A process should never have to deal with a controller data model.
  lorj provides a mapping feature to map process data with controller data.
* A process should never deal with how a controller manipulate data.
  A controller can have his own independant process
  Ex: If your process deals with booting a server, the process do not take care on
  how to ensure the network is already configured to access internet.

For details, see Lorj::BaseProcess


# Controller

A controller enhance a generic Process with how to really execute what the
process define to do.

In the simple human application vision, a controller is the human body.
It gives you the way to walk, for example.

You can consider that the 'brain' process can be enhanced in 2 differents areas:
* Do and execute a task:
  This is like, human muscles
* how to do a controller task that the brain do not care of.
  This is like how to automate several muscles to execute a simple task 'walk'

For details, see Lorj::BaseController


# enhanced logger system

There is nothing clever here. Globally, you should be able to redefine the lorj
logging system by any thing, if you redefine PrcLib logging messages.
This said, Lorj has implemented a logging system based on logger. It helps to
save any debug info to a rotated log file system, even if the data is not printed out
to the default output.

This helps in debugging the lorj application.


# Implementation examples

##Students examples:
The main lorj README has a learn by examples documentation. This could help to start.

## Forj cli
forj cli is the first implementation of lorj.

Forj cli is a command line interface to start a DevOps solution in the cloud.
As forj has been developped with cloud agnostics in mind, the cli has implemented
a Cloud process to start the first box called 'Maestro'. And lorj help forj cli
to boot maestro on any kind of cloud, as soon as a controller exists.

It ensures that everything is configured on the cloud provider to boot up a box
with all features needed, like network connected to internet, image available,
NAT preconfigured, with port open, etc...

See [forj cli gem](https://rubygems.org/gems/forj)
