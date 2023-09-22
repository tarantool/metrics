..  _install:

Installing the metrics module
=============================

..  note::

    Since Tarantool version `2.11.1 <https://github.com/tarantool/tarantool/releases/tag/2.11.1>`__,
    the installation is not required.

.. _install-rockspec:

Installing metrics using the ``*.rockspec`` file
------------------------------------------------

Usually, all dependencies are included in the ``*.rockspec`` file of the application.
All dependencies are installed from this file. To do this:

#.  Add the ``metrics`` module to the dependencies in the ``.rockspec`` file:

    ..  code-block:: lua

        dependencies = {
            ...
            'metrics == 1.0.0',
            ...
        }

#.  Install the missing dependencies:

    ..  code-block:: shell

        tt rocks make
        # OR #
        tarantoolctl rocks make
        # OR #
        cartridge build

.. _install-metrics_only:

Installing the metrics module only
----------------------------------

To install only the ``metrics`` module, execute the following commands:

#.  Set current folder:

    .. code-block:: shell

        $ cd ${PROJECT_ROOT}

#. Install the missing dependencies:

    .. code-block:: shell

        $ tt rocks install metrics <version>
        # OR #
        $ tarantoolctl rocks install metrics <version>

    where ``version`` -- the necessary version number. If omitted, then the version from the
    ``master`` branch is installed.
