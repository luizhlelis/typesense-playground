# Typesense search engine: an easier-to-use alternative to ElasticSearch

In a daily development process, it's common the need to search a specific term in a large amount of data. The search engine tools came to solve this kind of problem and one of the most famous is called [ElasticSearch](https://github.com/elastic/elasticsearch). If you have already worked with ElasticSearch you probably know that it's such a powerful tool, but it's also complex and has a steep learning curve. For example, doing an in-house deployment of ElasticSearch you will face a high production ops overhead dealing with over 3000 configuration parameters.

Built in C++, [Typesense](https://github.com/typesense/typesense) is an easier-to-use alternative to ElasticSearch. The community describes it as an open-source, fast, typo tolerant, and easy-to-use search engine. The current article is a quick introduction to `Typesense` using a search engine example for the `Nobel Prize Winners`.

## Server configuration

Just like most search engine tools, `Typesense` is a NoSql document-oriented database. For the current example, I'll self-host `Typesense` on my local machine using the official [docker image](https://hub.docker.com/r/typesense/typesense/), as you can see in the example [source code](https://github.com/luizhlelis/typesense-playground). There are [few parameters](https://typesense.org/docs/0.21.0/api/server-configuration.html#using-command-line-arguments) to configure the `Typesense` server, but you could let the default values and just configure the `--api-key` (admin API key that allows all operations) and the `--data-dir` (path to the directory where data will be stored on disk) parameters. Take a look at the `typesense` service on `docker-compose`:

```yml
  typesense:
    image: typesense/typesense:0.22.0.rcs11
    container_name: typesense
    environment:
      - TYPESENSE_API_KEY=Hu52dwsas2AdxdE
      - TYPESENSE_DATA_DIR=/typesense-data
    volumes:
      - "./typesense-data:/typesense-data/"
    ports:
      - "8108:8108"
```

> **NOTE**: when using `environment variables`, you need to add the `TYPESENSE_` prefix to the variable name

One important thing to note is: I choose to create a volume for the `typesense-data` folder, so the data stored in the container will be persisted locally. Along with the `typesense` service, I registered a `seed-data` service on `docker-compose.yml` to seed the `Nobel Prize Winners` data in the `Typesense` server:

```yml
  seed-data:
    build:
      context: .
      dockerfile: Dockerfile
    container_name: seed-data
    depends_on:
      - typesense
    environment:
      - TYPESENSE_API_KEY=Hu52dwsas2AdxdE
      - SERVER_HOSTNAME=typesense
    volumes:
      - "./scripts:/app/"
      - "./seed-data:/seed-data/"
    command:
      [
        "/app/wait-for-it.sh",
        "typesense:8108",
        "-s",
        "-t",
        "40",
        "--",
        "/app/batch-import-docs.sh"
      ]
```

The volumes listed above are: a path to the scripts ([wait-for-it.sh](https://github.com/luizhlelis/typesense-playground/blob/main/src/scripts/wait-for-it.sh) that waits for `typesense` to respond on it's `port` and [batch-import-docs.sh](https://github.com/luizhlelis/typesense-playground/blob/main/src/scripts/batch-import-docs.sh) which seed the data) and also a path to the dataset formatted as [JSONLines](https://jsonlines.org/).

## Create collection and import documents

Before starting to import the documents, it's important to create a `collection`. In `Typesense`, a group of related documents is called `collection` and `schema` is the name of the fields from the documents added in a `collection`. It might help to think of a `schema` as the "types" in a strongly-typed programming language. The most important thing that you should keep in mind is: all fields that you mention in a `collection`'s `schema` will be indexed in memory. Take a look at the `prizes` collection created for the current example:

```bash
curl "http://${SERVER_HOSTNAME}:8108/collections" \
       -X POST \
       -H "Content-Type: application/json" \
       -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" \
       -d '{
         "name": "prizes",
         "default_sorting_field": "year",
         "fields": [
           {"name": "id", "type": "string" },
           {"name": "year", "type": "int64" },
           {"name": "category", "type": "string", "facet": true },
           {"name": "laureates_full_name", "type": "string[]" }
         ],
         "default_sorting_field": "year"
       }'
```

>**NOTE**: indexes are gonna improve the execution of queries in terms of performance. If an appropriate index exists for a query, `Typesense` will use it to limit the number of documents to inspect

The `schema` above has four indexed fields: `id`, `year`, `category` and `laureates_full_name`, but if you look at the [dataset to be imported](https://github.com/luizhlelis/typesense-playground/blob/main/src/seed-data/documents.jsonl), you'll notice some extra fields, for example: `laureates.motivation`, `laureates.share`, `laureates.surname`. Those fields will be stored on disk, but will not take up any memory.

For the dataset import, I'm using the [import API](https://typesense.org/docs/0.21.0/api/documents.html#import-documents) to index multiple documents in a batch:

```bash
curl -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" -X POST --data-binary @../seed-data/documents.jsonl \
"http://${SERVER_HOSTNAME}:8108/collections/prizes/documents/import?action=create"
```

Now that all the steps are clear, just type the command below to up the `typesense` server and also seed the data inside it:

```bash
docker-compose up --build
```

# Searching for the Nobel Prize Winners

Now that the `typesense` server is up and running, let's start searching for the Nobel Prize winners. First, export the environment variable `TYPESENSE_API_KEY` to use it locally as a typesense client:

```bash
export TYPESENSE_API_KEY=Hu52dwsas2AdxdE
```

Then, use the [search API](https://typesense.org/docs/0.21.0/api/documents.html#search) to search for documents. For example, imagine that you want to search for the Marie Curie prize, type the command below locally:

```bash
curl -H "X-TYPESENSE-API-KEY: ${TYPESENSE_API_KEY}" \
"http://localhost:8108/collections/prizes/documents/search\
?q=Curii&query_by=laureates_full_name\
&sort_by=year:desc"
```

Did you notice the typo in the query text? Instead of `Curie`, `Curii` was sent in the query. No big deal, `Typesense` handles typographic errors, take a look at the documents returned (the response body has been cut for didactic purposes only):

```json
{
  "facet_counts": [],
  "found": 2,
  "hits": [
    {
      "document": {
        "category": "chemistry",
        "id": "55",
        "laureates": [
          {
            "firstname": "Marie",
            "id": "6",
            "motivation": "\"in recognition of her services to the advancement of chemistry by the discovery of the elements radium and polonium, by the isolation of radium and the study of the nature and compounds of this remarkable element\"",
            "share": "1",
            "surname": "Curie"
          }
        ],
        "laureates_full_name": [
          "Marie Curie"
        ],
        "year": 1911
      }
    },
    {
      "document": {
        "category": "physics",
        "id": "12",
        "laureates": [
          {
            "firstname": "Henri",
            "id": "4",
            "motivation": "\"in recognition of the extraordinary services he has rendered by his discovery of spontaneous radioactivity\"",
            "share": "2",
            "surname": "Becquerel"
          },
          {
            "firstname": "Pierre",
            "id": "5",
            "motivation": "\"in recognition of the extraordinary services they have rendered by their joint researches on the radiation phenomena discovered by Professor Henri Becquerel\"",
            "share": "4",
            "surname": "Curie"
          },
          {
            "firstname": "Marie",
            "id": "6",
            "motivation": "\"in recognition of the extraordinary services they have rendered by their joint researches on the radiation phenomena discovered by Professor Henri Becquerel\"",
            "share": "4",
            "surname": "Curie"
          }
        ],
        "laureates_full_name": [
          "Henri Becquerel",
          "Pierre Curie",
          "Marie Curie"
        ],
        "year": 1903
      }
    }
  ]
}
```

## Conclusion

`Typesense` has been turning into a nice alternative to search engines like Algolia and ElasticSearch. Its simple server setup and intuitive API turns the navigation much easier. For the current example, I used CURL to interact with `Typesense` Server directly, but there are many [clients and integrations](https://github.com/typesense/typesense#api-clients) developed in your favorite language.

Now, I want to know your opinion, if you're using `Typesense` in production [let the community knows](https://github.com/typesense/typesense/issues/140)! If you got here and liked the article content, let me know by reacting to the current post. You can also open a discussion below, I'll try to answer it soon. On the other hand, if you think that I said something wrong, please open an issue in the [article's github repo](https://github.com/luizhlelis/typesense-playground).
