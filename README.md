# Typesense playground

This is a playground for the [Typesense](https://typesense.io) search engine. This example shows a searching engine for the nobel prize winners of all time.

## Running Commands

First, you need to export the environment variable `TYPESENSE_API_KEY` to use it locally as a `typesense` client:

```bash
export TYPESENSE_API_KEY=Hu52dwsas2AdxdE
```

The command bellow will up two containers: one for the search engine server (typesense) and another one to seed some data to the server.

```bash
docker-compose up --build
```

After that, you can run the following commands to test the search engine:

- to see the just created collection:

```bash
curl -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" "http://localhost:8108/collections"
```

- to search for a nobel prize winner (Einstein in the example below):

```bash
curl -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" \                                              
"http://localhost:8108/collections/prizes/documents/search\
?q=Einstein&query_by=laureates_full_name\
&sort_by=year:desc"
```

## Limitations

[Nested Fields](https://github.com/typesense/typesense/issues/227).
