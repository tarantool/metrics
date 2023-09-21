..  _install:

Installing the metrics module
=============================

..  note::

    Since Tarantool version `2.11.1 <https://github.com/tarantool/tarantool/releases/tag/2.11.1>`__,
    the installation is not required.

.. _install-the_usual_way:

The usual way
-------------

Usually, all dependencies are included in the ``*.rockspec`` file of the application.
All dependencies are installed from this file.

This is done as follows:

#.  Add the ``metrics`` package to the dependencies in the ``.rockspec`` file:

    .. code-block:: lua

        dependencies = {
            ...
            'metrics == 1.0.0',
            ...
        }

#. Install the missing dependencies:

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

#. Set current folder:

    .. code-block:: shell

        $ cd ${PROJECT_ROOT}

#. Install the missing dependencies:

    .. code-block:: shell

        $ tt rocks install metrics <version>
        # OR #
        $ tarantoolctl rocks install metrics <version>

    where ``version`` is the necessary version number. If omitted, then the version from the
    ``master`` branch is installed.
