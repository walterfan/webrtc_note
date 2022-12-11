###################
Sphinx
###################


.. include:: ../links.ref
.. include:: ../tags.ref
.. include:: ../abbrs.ref

============ =============================
**Abstract** Sphinx and restructuredText
**Authors**  Walter Fan
**Status**   WIP
**Updated**  |date|
============ =============================



.. contents::
   :local:

Overview
=====================


Example
=====================

Flow chart
---------------------
.. graphviz::

    digraph {
        start -> a;
        a -> b[label="yes"];
        a -> c[label="no"];
        b -> end;
        c -> end;
    }


* mindmap
  
.. graphviz::

    graph {

        cql[label="CQL"];
        trait[label="Trait: No Joins, No referential integrity, denormalization"];
        cas[label="Cassandra"];
        arch[label="Architecture"];
        mod[label="Data Modeling"];

        cas -- cql;
        cas -- mod;
        cas -- arch;
        mod -- trait;
    }

Class diagram
---------------------

.. uml::

    class task {
        worker_id text,
        time_slot text,
        time timeuuid,
        attributes text,
        PRIMARY KEY ((worker_id, time_slot), time)
    }

    class task_time_slot {
        worker_id text,
        time_slot text,
        PRIMARY KEY (worker_id, time_slot)
    }

State diagram
---------------------
.. uml::

    [*] --> IDLE
    IDLE -> COMPLETE
    IDLE -> COMPLETE_REPEATED
    COMPLETE_REPEATED -> IDLE
    IDLE -> FAILURE
    IDLE -> INTERRUPTED
    FAILURE --> [*]
    INTERRUPTED --> [*]
    COMPLETE --> [*]



.. uml::

   @startuml
   actor "Main Database" as DB << Application >>
   
   note left of DB
      This actor 
      has a "name with spaces",
      an alias
      and a stereotype 
   end note
   
   actor User << Human >>
   actor SpecialisedUser
   actor Administrator
   
   User <|--- SpecialisedUser
   User <|--- Administrator
   
   usecase (Use the application) as (Use) << Main >>
   usecase (Configure the application) as (Config)
   Use ..> Config : <<includes>>
   
   User --> Use
   DB --> Use
   
   Administrator --> Config 
   
   note "This note applies to\nboth actors." as MyNote
   MyNote .. Administrator
   MyNote .. SpecialisedUser
   
   '  this is a text comment and won't be displayed
   AnotherActor ---> (AnotherUseCase)
   
   '  to increase the length of the edges, just add extras dashes, like this:
   ThirdActor ----> (LowerCase)
   
   '  The direction of the edge can also be reversed, like this:
   (UpperCase) <---- FourthActor
   
   @enduml



Reference
====================
* https://en.wikipedia.org/wiki/DOT_(graph_description_language)
* http://www.graphviz.org/pdf/dotguide.pdf
* http://graphs.grevian.org/example.html
* https://build-me-the-docs-please.readthedocs.io/en/latest/Using_Sphinx/UsingGraphicsAndDiagramsInSphinx.html