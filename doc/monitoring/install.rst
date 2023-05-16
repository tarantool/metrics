.. _install:

Installing the metrics module
=============================

.. hint::
    Does not require installation for Tarantula version 2.11.1 and higher

.. _install-the_usual_way:

The usual way
-------------

Usually, all dependencies are included in the ``*.rockspec`` file of the application
and all dependencies are installed from it.

This is done as follows:

#.  Add the ``metrics`` package to the dependencies in the ``.rockspec`` file.

    .. code-block:: lua

        dependencies = {
            ...
            'metrics == 1.0.0',
            ...
        }

#. To install the missing dependencies, execute the folowing command:

    .. code-block:: shell

        tt rocks make
        # OR #
        tarantoolctl rocks make
        # OR #
        cartridge build

.. _install-the_direct_way:

Direct way
----------

To install only the ``metrics`` module, execute the following commands:

#.
    .. code-block:: shell

        $ cd ${PROJECT_ROOT}

#.
    .. code-block:: shell

        $ tt rocks install metrics <version>
        # OR #
        $ tarantoolctl rocks install metrics <version>

    where ``version`` is the necessary version number. If omitted, then the version from the
    ``master`` branch is installed).
