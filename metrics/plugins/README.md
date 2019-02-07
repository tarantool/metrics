# Plugins

Plugins allow to use an unified interface to collect metrics without worrying about the way metrics export performed.
If you want to use another DB to store metrics data, you can use appropriate export plugin just by changing one line of code.


## Avaliable Plugins

- [Graphite](./graphite/README.md)


## How To Write Your Custom Plugin?

If you want to write your custom export plugin you can use `metrics.collect()` function there.
It returns all observations for all collectors registered via metrics client.
