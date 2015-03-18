# Lorj

**Lorj** library is a process/controller framework used to build inter-operable process functions against any kind of controllers.

It has been designed to provide cloud agnostics feature to forj command line tool and FORJ maestro gardener.

This framework helps to design any kind of solution which needs to maintain a generic process logic, fully controller independant.

## Implementations examples

### How forj cli implemented Lorj lib

This case was implemented by forj cli to implement services on any kind of cloud solution.

forj cli needs to build a forge (collection of servers) on a cloud.
It requires to ensure that everything is in place (network properly configured
 if not create it, router exists, flavors available, etc.) to create the first server.

For **Lorj**, how to create the forge and ensure that everything is in place is
the **GENERIC process**.<br>
And then how to manipulate the cloud (get the network, create the network,
create the server, etc...) is the **controller**. <br>
Usually, the controller is a wrapper to an API, which do actions, like 'create server'.
But depending on what you defined in your GENERIC process, a controller can define
a controller process, which will deal with the complexity of the controller to execute the
GENERIC process task requested.

Then, at runtime, while changing the controller to aws, hpcloud, openstack, or
even docker or decker, forj cli GENERIC process will be still the same.
It simplifies forj cli extension, by just adding new controller to support more
clouds providers.

Currently, forj cli has implemented *hpcloud* and *openstack* providers, using
*fog*. Docker controller is under development.

### embedded process/controllers

Currently, lorj embed a Cloud process and 3 providers (controllers: hpcloud/openstack/mock)

The cloud process is used by [forj cli|http://www.rubydoc.info/gems/forj] - the DevOps forge builder,
to execute cloud task transparently against hpcloud or openstack.

To support a new cloud provider, you need to write your own cloud controller.
Look in [lib/providers] to clone an existing one and update to use your own cloud.

TODO: Move process and controller to new gem libraries.
TODO: write up cloud controller documentation for contributors.

## Getting started

As playing by example is better than a long discussion, let's start playing with a simple example.

### Installation

Add this line to your application's Gemfile:

```ruby
gem 'lorj'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install lorj


### Write your first Lorj code

#### Student database management example context:

Imagine you have an API code which today manages students database in yaml format.<br>
We have written a small class to illustrate this API. (See examples/yaml_students/yaml_students.rb)

This api has everything to create, query, edit and delete a student in a yaml file.

Using Lorj, you want to propose multiple storage system (not only using the yaml
 format) to your application, by supporting several storage systems, like mysql DB.

next, we will write 3 versions, which will introduce how to deal with process and controllers:

* version 1:
    Writing your first 'do nothing' process, with no controller.

    [Details is explained here](https://github.com/forj-oss/lorj/blob/master/example/students_1/student_v1.md)

* version 2:
    Complete the process to have create/query/get and delete capability, with mock controller.
    The mock controller is basically a controller keeping data in memory.

    [Details is explained here](https://github.com/forj-oss/lorj/blob/master/example/students_2/student_v2.md)

* version 3:
     In this version, we will just create a controller, to replace mock.

    [Details is explained here](https://github.com/forj-oss/lorj/blob/master/example/students_3/student_v3.md)

* version 4:
     In this version, we are going to improve the process, to find way to simplify
     the previous code.

    [Details is explained here](https://github.com/forj-oss/lorj/blob/master/example/students_4/student_v4.md)

* version 5:
     Update the version 4 to fully implement the example of an yaml_student API.
     ie :
     Reproducing what the main `examples/yaml_students/students.rb` is doing.<BR>
     The API is `examples/yaml_students/yaml_students.rb`

    [Details is explained here](https://github.com/forj-oss/lorj/blob/master/example/students_5/student_v5.md)

# What next?

If you want to understand the concept, check [here](https://github.com/forj-oss/lorj/blob/master/lib/concept.md)

If you want to get an overview of functionnalities per context, see [here](https://github.com/forj-oss/lorj/blob/master/lib/overview.md)

For details, [see API documentation](http://www.rubydoc.info/gems/lorj).

# Contributing to Lorj

We welcome all types of contributions.  Checkout our website (http://docs.forj.io/en/latest/dev/contribute.html)
to start hacking on Lorj or Forj.  Also join us in our community (https://www.forj.io/community/) to help grow and foster Lorj and Forj for your development today!


#License:

Lorj lib is licensed under the Apache License, Version 2.0.  See LICENSE for full license text.
